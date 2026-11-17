#!/usr/bin/env bash
# Monta portatil/MKSM-linux: executável, bibliotecas (glibc inclusa, via o ld-linux da pasta) e os arquivos
# do jogo, numa pasta que roda em outro Linux x86-64 sem instalar nada.
# uso: scripts/empacotar_linux.sh [raiz com PS2Recomp/ e extraido_full/]   (padrão: a raiz deste repositório)
# O build precisa ser sem -march=native (cmake -DPS2X_NATIVE_ARCH=OFF), senão só roda em CPUs iguais a esta.
set -euo pipefail
AQUI=$(cd "$(dirname "$0")/.." && pwd)
RAIZ=$(cd "${1:-$AQUI}" && pwd)
BIN=$RAIZ/PS2Recomp/out/build/ps2xRuntime/ps2EntryRunner
OUT=$RAIZ/portatil/MKSM-linux
grep -q '^PS2X_NATIVE_ARCH:BOOL=OFF' "$RAIZ/PS2Recomp/out/build/CMakeCache.txt" ||
  { echo "O build usa -march=native: reconfigure com -DPS2X_NATIVE_ARCH=OFF e compile de novo." >&2; exit 1; }

mkdir -p "$OUT/bin" "$OUT/lib" "$OUT/jogo"
cp "$BIN" "$OUT/bin/"
# Arch lista o ld-linux com "=>", Debian/Ubuntu sem.
ldd "$BIN" | awk '$2 == "=>" && $3 ~ /^\// {print $3} $1 ~ /ld-linux/ && $2 != "=>" {print $1}' |
  while read -r so; do cp -L "$so" "$OUT/lib/"; done
# rsync refaz arquivo de tamanho diferente (cópia cortada); os memory cards só entram na primeira vez.
rsync -a --exclude=mc0 --exclude=mc1 "$RAIZ/extraido_full/" "$OUT/jogo/"
cp -rn "$RAIZ/extraido_full/mc0" "$RAIZ/extraido_full/mc1" "$OUT/jogo/" 2>/dev/null || true

cat > "$OUT/jogar.sh" <<'EOF'
#!/usr/bin/env bash
# Roda o jogo com as bibliotecas desta pasta. Configuração em mksm.ini (ao lado deste arquivo).
set -euo pipefail
d="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "$d/mksm.ini" ]]; then
    while IFS='=' read -r chave valor; do
        chave=${chave%$'\r'} valor=${valor%$'\r'}
        [[ -z "$chave" || "$chave" == \#* ]] && continue
        export "$chave=$valor"
    done < "$d/mksm.ini"
fi
export PS2X_GS_RECORD_DIR="${PS2X_GS_RECORD_DIR:-$d/gsrec}" PS2X_CAPTURE_DIR="${PS2X_CAPTURE_DIR:-$d/capturas}"
export MKSM_INI="$d/mksm.ini" # o menu Gráfico grava aqui
mkdir -p "$PS2X_GS_RECORD_DIR" "$PS2X_CAPTURE_DIR"
cd "$d/jogo" # o runtime cria mc0/ na pasta atual antes de saber onde está o ELF
exec "$d/lib/ld-linux-x86-64.so.2" --library-path "$d/lib" "$d/bin/ps2EntryRunner" "$d/jogo/SLUS_210.87" "$@"
EOF
chmod +x "$OUT/jogar.sh"
# Igual ao jogar.sh, com a medição ligada (N22, A1): a cada 2 s, quadros do jogo, imagens novas e o pior intervalo.
cat > "$OUT/jogar-medindo.sh" <<'EOF'
#!/usr/bin/env bash
# Igual ao jogar.sh, mas grava a medida de desempenho em medida.txt (nesta pasta). Jogue onde engasga e feche o jogo.
d="$(cd "$(dirname "$0")" && pwd)"
echo "Medindo. Jogue onde engasga e feche o jogo; a medida fica em $d/medida.txt"
PS2X_PERF=1 "$d/jogar.sh" "$@" > "$d/medida.txt" 2>&1
EOF
chmod +x "$OUT/jogar-medindo.sh"

if [[ ! -f "$OUT/mksm.ini" ]]; then  # o jogo regrava as chaves gráficas e mantém o resto
  { echo "# Configuração do jogo: tire o # da frente de uma linha VAR=valor para usar."
    sed -n '3,/^set -euo/{/^#/p}' "$AQUI/scripts/jogar.sh"; } > "$OUT/mksm.ini"
fi
grep -q 'RPG_' "$OUT/mksm.ini" || # pasta de antes do modo RPG: só acrescenta as chaves dele
  sed -n '/^# Modo RPG/,/^# Cada slot RPG/p' "$AQUI/scripts/jogar.sh" >> "$OUT/mksm.ini"

cat > "$OUT/LEIA-ME.txt" <<'EOF'
ShaolinMonks RPG: Mortal Kombat: Shaolin Monks recompilado para PC, versão Linux portátil

COMO JOGAR
  Abra um terminal nesta pasta e rode ./jogar.sh (ou dê dois cliques nele, se o gerenciador de arquivos
  oferecer "executar"). Não precisa instalar nada: as bibliotecas estão na pasta lib/.

PRECISA
  Linux x86-64 com driver de vídeo com Vulkan (Mesa ou NVIDIA). Sem Vulkan, ponha PS2X_GS_HW=0 no mksm.ini
  (renderizador antigo, só na resolução do PS2).

CONTROLES
  Controle (gamepad): funciona direto; um segundo controle joga como jogador 2.
  Teclado (só jogador 1):
    Setas ou WASD = direcional        Enter = Start       Tab = Select
    X ou Espaço = X                   C ou Esc = Círculo
    Z = Quadrado                      V = Triângulo
    Q/E = L1/R1, Shift esquerdo/direito = L2/R2
  Para trocar os botões: F1 (ou R3 nos menus), L1/R1 até a aba Controles.
  Jogador 2 (controle genérico com botões trocados): aperte o R3 do controle 2 nos menus ou na pausa,
  a janela abre nos botões dele. Controle 2, direcional para cima: liga/desliga a defesa contínua
  (como segurar L2), para jogar o Ko-op com um controle só.
  F1 = menu Gráfico    F11 = tela cheia    F10 = salva a tela em capturas/

CONFIGURAÇÃO
  mksm.ini tem todas as opções comentadas (volume, tela 16:9, resolução interna, pular os filmes...).
  O menu Gráfico (F1, ou R3 nos menus) grava as escolhas ali.
  PC com placa de vídeo fraca: no menu Gráfico, ponha a Predefinição em "Mínimo".

MODO RPG (opcional, só em jogo novo)
  Single Player ou Ko-op -> personagem -> na escolha de dificuldade, cursor no HARD e aperte L3
  (F2 no teclado): aparece "RPG" ao lado do Hard. O jogo fica sempre no Hard, com inimigos mais fortes.
  Matar inimigos dá XP: o nível aparece acima do "EXP" (no Ko-op, um para cada jogador).
  Subiu de nível: pausa (Select) e R3 (ou F1), aba RPG, X gasta o ponto. No Ko-op, cada jogador
  abre a janela com o R3 do próprio controle e vê só o próprio RPG. "Redistribuir pontos" (X duas vezes) devolve todos.
  Na tela Load Game, os saves RPG mostram "RPG · Nível N". Um save RPG continua RPG; gravar um jogo normal
  por cima tira o RPG daquele slot. Os números (XP por nível, força dos atributos) estão no mksm.ini.

  Lutadores: no Versus todos vêm liberados, e Sub-Zero e Scorpion na seleção da história. Para jogar a história ou o Ko-op com outro
  lutador: num jogo novo, na escolha de dificuldade, L2/R2 no controle de cada jogador (Shift esq./dir. no teclado; segurado, passa
  sozinho). Fica no save. São 67, nesta ordem: monges e Versus (os únicos com fatality); com especiais (Shao Kahn, Goro, Kano,
  Shang Tsung, Inferno Scorpion, Ermac chefe, Kintaro); só golpes normais (Mileena, Jade, Jax, as versões
  de história do Versus como "Scorpion Boss", Shadow Priest, Orochi, inimigos...);
  golpes com animação bugada; e os que só andam (Noob Saibot, Smoke, Raiden, Kabal, Sonya...). Embaixo do nome aparece a situação.
  Fora dos monges e do Versus não há defesa de verdade: com L2 levam 20% do dano, mas trechos que pedem defender não avançam.
  No Ko-op, recomendado que um dos jogadores use um dos 4 clássicos (Liu Kang, Kung Lao, Sub-Zero ou Scorpion): alguns trechos
  da história pedem Brutality ou Multality, que só esses quatro fazem com certeza.

SAVES
  Ficam em jogo/mc0 (memory card 1) e jogo/mc1 (memory card 2). Copie essas pastas, e os arquivos rpg_mc0_slot*.ini se jogar no modo RPG, para fazer backup.
EOF
echo "Pronto: $OUT ($(du -sh "$OUT" | cut -f1))"
