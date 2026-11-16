#!/usr/bin/env bash
# Compila o jogo para Windows a partir do Linux (MinGW-w64) e monta portatil/MKSM-windows.
# uso: scripts/build_windows.sh [raiz com PS2Recomp/ e extraido_full/]   (padrão: a raiz deste repositório)
# Precisa de mingw-w64-gcc, cmake, ninja e glslc. O primeiro build baixa o FFmpeg para Windows (GitHub, o
# mesmo pacote que o PS2Recomp usa no Windows, 34 MB). O código gerado vai em lotes de 32 arquivos com cabeçalho
# pré-compilado: ~0,5 GB por job, menos de 1 h com JOBS = número de threads (o padrão).
set -euo pipefail
AQUI=$(cd "$(dirname "$0")/.." && pwd)
RAIZ=$(cd "${1:-$AQUI}" && pwd)
SRC=$RAIZ/PS2Recomp B=$RAIZ/PS2Recomp/out/build-win OUT=$RAIZ/portatil/MKSM-windows DEPS=$RAIZ/PS2Recomp/out/build/_deps
command -v x86_64-w64-mingw32-g++ >/dev/null || { echo "Falta o MinGW: sudo pacman -S mingw-w64-gcc" >&2; exit 1; }
mkdir -p "$B"

# vulkan-1.dll vem com o driver de vídeo; a biblioteca de ligação sai da lista de funções que o runtime chama.
{ echo "LIBRARY vulkan-1.dll"; echo EXPORTS; grep -rhoE '\bvk[A-Z][A-Za-z0-9]+\(' "$SRC/ps2xRuntime/src" | tr -d '(' | sort -u; } > "$B/vulkan-1.def"
x86_64-w64-mingw32-dlltool -d "$B/vulkan-1.def" -l "$B/libvulkan-1.a"

# Reaproveita as fontes que o build do Linux já baixou.
fontes=()
for par in raylib:RAYLIB imgui:IMGUI rlimgui:RLIMGUI vulkan_headers:VULKAN_HEADERS; do
  [[ -d "$DEPS/${par%%:*}-src" ]] && fontes+=("-DFETCHCONTENT_SOURCE_DIR_${par##*:}=$DEPS/${par%%:*}-src")
done
cmake -S "$SRC" -B "$B" -G Ninja -DCMAKE_TOOLCHAIN_FILE="$AQUI/scripts/mingw-w64.cmake" \
  -DCMAKE_CXX_FLAGS="-msse4.1 -O1 -g0" -DCMAKE_EXE_LINKER_FLAGS="-static" \
  -DPS2X_BUILD_RECOMP=OFF -DPS2X_BUILD_ANALYZER=OFF -DPS2X_BUILD_STUDIO=OFF -DPS2X_BUILD_TEST=OFF \
  -DPS2X_NATIVE_ARCH=OFF -DPS2X_OPTIMIZE_RUNTIME_LIB=ON -DPS2X_SHOW_WINDOWS_CONSOLE=OFF \
  -DPS2X_VULKAN_LIBRARY="$B/libvulkan-1.a" "${fontes[@]}"
ninja -C "$B" -j "${JOBS:-$(nproc)}" ps2EntryRunner

mkdir -p "$OUT/bin" "$OUT/jogo"
cp "$B/ps2xRuntime/ps2EntryRunner.exe" "$OUT/bin/MKSM.exe"
cp "$B"/ThirdParty/ffmpeg-prefix/src/ffmpeg_external/bin/*.dll "$OUT/bin/" # FFmpeg e o que ele usa
# Os arquivos do jogo viram links para extraido_full (o jogo só os lê; copiar a pasta para um pendrive copia o
# conteúdo). Os memory cards são cópias de verdade, só na primeira vez, e vêm da pasta Linux se você já jogou nela.
rsync -a --exclude=mc0 --exclude=mc1 --link-dest="$RAIZ/extraido_full/" "$RAIZ/extraido_full/" "$OUT/jogo/"
saves=$RAIZ/extraido_full
[[ -d "$RAIZ/portatil/MKSM-linux/jogo/mc0" ]] && saves=$RAIZ/portatil/MKSM-linux/jogo
cp -rn "$saves/mc0" "$saves/mc1" "$OUT/jogo/" 2>/dev/null || true

crlf() { sed 's/$/\r/'; }
crlf > "$OUT/Jogar.bat" <<'EOF'
@echo off
rem Roda o jogo. Configuracao em mksm.ini (ao lado deste arquivo).
setlocal
set "D=%~dp0"
if exist "%D%mksm.ini" for /f "usebackq eol=# tokens=1,* delims==" %%a in ("%D%mksm.ini") do set "%%a=%%b"
if not defined PS2X_CAPTURE_DIR set "PS2X_CAPTURE_DIR=%D%capturas"
if not defined PS2X_GS_RECORD_DIR set "PS2X_GS_RECORD_DIR=%D%gsrec"
set "MKSM_INI=%D%mksm.ini"
if not exist "%PS2X_CAPTURE_DIR%" mkdir "%PS2X_CAPTURE_DIR%"
if not exist "%PS2X_GS_RECORD_DIR%" mkdir "%PS2X_GS_RECORD_DIR%"
rem O runtime cria mc0\ na pasta atual antes de saber onde esta o ELF.
cd /d "%D%jogo"
start "" "%D%bin\MKSM.exe" "%D%jogo\SLUS_210.87"
EOF

if [[ ! -f "$OUT/mksm.ini" ]]; then  # o jogo regrava as chaves gráficas e mantém o resto
  { echo "# Configuração do jogo: tire o # da frente de uma linha VAR=valor para usar."
    sed -n '3,/^set -euo/{/^#/p}' "$AQUI/scripts/jogar.sh"; } | crlf > "$OUT/mksm.ini"
fi
grep -q 'RPG_' "$OUT/mksm.ini" || # pasta de antes do modo RPG: só acrescenta as chaves dele
  sed -n '/^# Modo RPG/,/^# Cada slot RPG/p' "$AQUI/scripts/jogar.sh" | crlf >> "$OUT/mksm.ini"

crlf > "$OUT/LEIA-ME.txt" <<'EOF'
Mortal Kombat: Shaolin Monks (recompilado para PC), versão Windows portátil

COMO JOGAR
  Dê dois cliques em Jogar.bat. Não precisa instalar nada.
  Se o Windows mostrar "O Windows protegeu o computador", clique em "Mais informações" e
  "Executar assim mesmo" (o programa não tem assinatura digital).

PRECISA
  Windows 10 ou 11, 64 bits, com driver de vídeo atualizado (Vulkan e OpenGL: NVIDIA, AMD ou Intel).
  Sem Vulkan, ponha PS2X_GS_HW=0 no mksm.ini (renderizador antigo, só na resolução do PS2).

CONTROLES
  Controle (gamepad): funciona direto; um segundo controle joga como jogador 2.
  Teclado (só jogador 1):
    Setas ou WASD = direcional        Enter = Start       Tab = Select
    X ou Espaço = X                   C ou Esc = Círculo
    Z = Quadrado                      V = Triângulo
    Q/E = L1/R1, Shift esquerdo/direito = L2/R2
  Para trocar os botões: F1 (ou R3 nos menus), L1/R1 até a aba Controles.
  F1 = menu Gráfico    F11 = tela cheia    F10 = salva a tela em capturas\

CONFIGURAÇÃO
  mksm.ini (abra no Bloco de Notas) tem todas as opções comentadas (volume, tela 16:9,
  resolução interna, pular os filmes...). O menu Gráfico (F1, ou R3 nos menus) grava as escolhas ali.
  PC com placa de vídeo fraca: no menu Gráfico, ponha a Predefinição em "Mínimo".

MODO RPG (opcional, só em jogo novo)
  Single Player ou Ko-op -> personagem -> na escolha de dificuldade, cursor no HARD e aperte L3
  (F2 no teclado): aparece "RPG" ao lado do Hard. O jogo fica sempre no Hard, com inimigos mais fortes.
  Matar inimigos dá XP: o nível aparece acima do "EXP" (no Ko-op, um para cada jogador).
  Subiu de nível: pausa (Select) e R3 (ou F1), aba RPG, X gasta o ponto. Esquerda/Direita troca o
  jogador no Ko-op. "Redistribuir pontos" (X duas vezes) devolve todos.
  Na tela Load Game, os saves RPG mostram "RPG · Nv N". Um save RPG continua RPG; gravar um jogo normal
  por cima tira o RPG daquele slot. Os números (XP por nível, força dos atributos) estão no mksm.ini.

SAVES
  Ficam em jogo\mc0 (memory card 1) e jogo\mc1 (memory card 2). Copie essas pastas, e os arquivos rpg_mc0_slot*.ini se jogar no modo RPG, para fazer backup.
EOF
echo "Pronto: $OUT ($(du -sh "$OUT" | cut -f1))"
