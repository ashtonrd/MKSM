#!/usr/bin/env bash
# PGO do runtime e do IOP (PLANO_DESEMPENHO.md, N22 B1): compila com contadores, treina com o jogo e recompila com o
# perfil. Só o runtime e o IOP mudam; os 13 mil arquivos do código gerado não recompilam.
# Uso: scripts/pgo_runtime.sh [raiz do projeto]   (precisa da sessão gráfica destravada: o treino abre a janela)
set -euo pipefail
RAIZ="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
B="$RAIZ/PS2Recomp/out/build"
ELF="$RAIZ/extraido_full/SLUS_210.87"
BIN="$B/ps2xRuntime/ps2EntryRunner"
PERFIL="$B/pgo"
[[ -f "$ELF" ]] || { echo "ELF não encontrado: $ELF" >&2; exit 1; }

echo "== 1/3: compilando com contadores"
mkdir -p "$PERFIL"
find "$PERFIL" -name '*.gcda' -delete
cmake -S "$RAIZ/PS2Recomp" -B "$B" -DPS2X_PGO=gerar -DPS2X_PGO_DIR="$PERFIL" > /dev/null
cmake --build "$B" --target ps2EntryRunner

echo "== 2/3: treinando (dois roteiros, ~7 min; não mexa no controle)"
treino=$(mktemp -d)
# Cópia do jogo feita de links, com o memory card copiado: o treino nunca grava no mc0 de verdade.
mkdir "$treino/jogo"
for f in "$RAIZ/extraido_full"/*; do
    case "$(basename "$f")" in mc0|mc1) cp -r "$f" "$treino/jogo/" ;; *) ln -s "$f" "$treino/jogo/" ;; esac
done
ELF="$treino/jogo/SLUS_210.87"
cd "$treino"
# Menus, cutscene do Raiden inteira e o começo da gameplay (a R5 do plano).
toques=$(for t in $(seq 45 5 120); do printf 'x@%s-%s.3,' "$t" "$t"; done)
PS2X_PGO_DUMP_AT=200 MKSM_PAD_CLOCK=reads MKSM_SKIP_INTRO=1 MKSM_AUTO_PAD=xs MKSM_AUTO_PAD_UNTIL=40 \
    MKSM_AUTO_HOLD="${toques%,}" timeout 260 "$BIN" "$ELF" > treino1.txt 2>&1 || true
# Luta: pula a cena do Raiden, pega a esfera à direita, pula a cena dela e aperta golpes (ARQUITETURA.md §6).
golpes=$(python3 -I -c "
ev=['x@36-36.2','s@50-50.2','R@53.5-55.5','s@61.8-62']
t=64.0
while t<150:
    ev+=[f'q@{t:.1f}-{t+.15:.2f}',f'q@{t+.4:.1f}-{t+.55:.2f}',f't@{t+.8:.1f}-{t+.95:.2f}',f'L@{t+1.2:.1f}-{t+1.5:.1f}',
         f'o@{t+1.6:.1f}-{t+1.75:.2f}',f'2@{t+2.0:.1f}-{t+2.5:.1f}',f'q@{t+2.15:.2f}-{t+2.3:.2f}',f'R@{t+2.7:.1f}-{t+3.0:.1f}']
    t+=3.2
print(','.join(ev))")
PS2X_PGO_DUMP_AT=170 MKSM_PAD_CLOCK=reads MKSM_SKIP_INTRO=1 MKSM_AUTO_PAD=xs MKSM_AUTO_PAD_UNTIL=24.5 \
    MKSM_AUTO_HOLD="$golpes" timeout 230 "$BIN" "$ELF" > treino2.txt 2>&1 || true
grep -h "\[pgo\]" treino1.txt treino2.txt || { echo "o treino não gravou o perfil (veja $treino)" >&2; exit 1; }
cd - > /dev/null

echo "== 3/3: recompilando com o perfil"
cmake -S "$RAIZ/PS2Recomp" -B "$B" -DPS2X_PGO=usar -DPS2X_PGO_DIR="$PERFIL" > /dev/null
cmake --build "$B" --target ps2EntryRunner
echo "Pronto: $BIN com PGO (perfil em $PERFIL). Para voltar ao build normal: cmake -B $B -DPS2X_PGO="
