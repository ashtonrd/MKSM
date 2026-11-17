#!/usr/bin/env bash
# PGO do .exe do Windows (PLANO_DESEMPENHO.md, N22 B1): compila o runtime e o IOP do build MinGW com contadores,
# treina rodando o .exe no Wine e recompila com o perfil. O perfil precisa sair do mesmo compilador (MinGW), por isso
# não serve o do Linux. Depois, scripts/build_windows.sh monta a pasta com o .exe otimizado (o cache guarda PS2X_PGO).
# uso: scripts/pgo_windows.sh [raiz com PS2Recomp/ e extraido_full/] <winlibs.zip>   (precisa do wine e de um build_windows.sh já feito)
# A libgcov do MinGW do sistema pode não gravar o perfil (a do Arch é reduzida); a do WinLibs (mesmo GCC 16.2) grava.
set -euo pipefail
AQUI=$(cd "$(dirname "$0")/.." && pwd)
RAIZ=$(cd "${1:-$AQUI}" && pwd)
WINLIBS=$(realpath "${2:?passe o zip do WinLibs (o mesmo do kit do Windows)}")
B=$RAIZ/PS2Recomp/out/build-win
PERFIL=$B/pgo
command -v wine >/dev/null || { echo "Falta o wine" >&2; exit 1; }
[ -f "$B/build.ninja" ] || { echo "Rode scripts/build_windows.sh uma vez antes" >&2; exit 1; }

echo "== 1/3: compilando com contadores"
mkdir -p "$PERFIL" "$B/pgo_gcov"
find "$PERFIL" -name '*.gcda' -delete
unzip -o -j -q "$WINLIBS" 'mingw64/lib/gcc/x86_64-w64-mingw32/*/libgcov.a' -d "$B/pgo_gcov"
cmake -S "$RAIZ/PS2Recomp" -B "$B" -DPS2X_PGO=gerar -DPS2X_PGO_DIR="$PERFIL" -DPS2X_PGO_GCOV_LIB="$B/pgo_gcov/libgcov.a" > /dev/null
ninja -C "$B" -j "${JOBS:-$(nproc)}" ps2EntryRunner

echo "== 2/3: treinando no Wine (dois roteiros; não mexa no controle)"
treino=$(mktemp -d)
mkdir -p "$treino/bin" "$treino/jogo"
cp "$B/ps2xRuntime/ps2EntryRunner.exe" "$treino/bin/MKSM.exe"
cp "$B"/ThirdParty/ffmpeg-prefix/src/ffmpeg_external/bin/*.dll "$treino/bin/"
for f in "$RAIZ/extraido_full"/*; do # memory card copiado: o treino nunca grava no de verdade
    case "$(basename "$f")" in mc0|mc1) cp -r "$f" "$treino/jogo/" ;; *) ln -s "$f" "$treino/jogo/" ;; esac
done
cd "$treino/jogo"
export WINEDEBUG=-all
toques=$(for t in $(seq 45 5 120); do printf 'x@%s-%s.3,' "$t" "$t"; done)
PS2X_PGO_DUMP_AT=230 MKSM_PAD_CLOCK=reads MKSM_SKIP_INTRO=1 MKSM_AUTO_PAD=xs MKSM_AUTO_PAD_UNTIL=40 \
    MKSM_AUTO_HOLD="${toques%,}" timeout 300 wine "$treino/bin/MKSM.exe" "$treino/jogo/SLUS_210.87" > ../treino1.txt 2>&1 || true
golpes=$(python3 -I -c "
ev=['x@36-36.2','s@50-50.2','R@53.5-55.5','s@61.8-62']
t=64.0
while t<150:
    ev+=[f'q@{t:.1f}-{t+.15:.2f}',f'q@{t+.4:.1f}-{t+.55:.2f}',f't@{t+.8:.1f}-{t+.95:.2f}',f'L@{t+1.2:.1f}-{t+1.5:.1f}',
         f'o@{t+1.6:.1f}-{t+1.75:.2f}',f'2@{t+2.0:.1f}-{t+2.5:.1f}',f'q@{t+2.15:.2f}-{t+2.3:.2f}',f'R@{t+2.7:.1f}-{t+3.0:.1f}']
    t+=3.2
print(','.join(ev))")
PS2X_PGO_DUMP_AT=200 MKSM_PAD_CLOCK=reads MKSM_SKIP_INTRO=1 MKSM_AUTO_PAD=xs MKSM_AUTO_PAD_UNTIL=24.5 \
    MKSM_AUTO_HOLD="$golpes" timeout 270 wine "$treino/bin/MKSM.exe" "$treino/jogo/SLUS_210.87" > ../treino2.txt 2>&1 || true
cd - > /dev/null
grep -h "\[pgo\]" "$treino/treino1.txt" "$treino/treino2.txt" || { echo "o treino não gravou o perfil (veja $treino)" >&2; exit 1; }
n=$(find "$PERFIL" -name '*.gcda' | wc -l)
echo "perfil: $n arquivos"
[ "$n" -gt 0 ] || { echo "o treino não gravou nenhum .gcda (a libgcov grava arquivo?)" >&2; exit 1; }

echo "== 3/3: recompilando com o perfil"
cmake -S "$RAIZ/PS2Recomp" -B "$B" -DPS2X_PGO=usar -DPS2X_PGO_DIR="$PERFIL" > /dev/null
ninja -C "$B" -j "${JOBS:-$(nproc)}" ps2EntryRunner
echo "Pronto. Agora: scripts/build_windows.sh $RAIZ  (monta a pasta com o .exe otimizado)"
