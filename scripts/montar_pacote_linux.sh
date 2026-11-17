#!/usr/bin/env bash
# Monta dist/ShaolinMonksRPG-Linux.zip: o repositório mais tudo o que o build baixaria (PS2Recomp com os patches
# aplicados e o código das bibliotecas), para o Instalar.sh compilar sem internet. Nada do jogo entra.
# uso: scripts/montar_pacote_linux.sh   (precisa de um build já configurado em PS2Recomp/out/build, para as fontes)
set -euo pipefail
cd "$(dirname "$0")/.."
RAIZ=$PWD
DEPS=$RAIZ/PS2Recomp/out/build/_deps
[ -d "$DEPS" ] || { echo "Falta $DEPS (configure o build uma vez)" >&2; exit 1; }
OBRA=$(mktemp -d)
P=$OBRA/ShaolinMonksRPG

echo "== Repositório (só o que está no git)"
git archive --format=tar --prefix=ShaolinMonksRPG/ HEAD | tar -x -C "$OBRA"

echo "== PS2Recomp no commit fixado, com os patches"
git clone -q "$RAIZ/PS2Recomp" "$OBRA/ps2recomp"
scripts/aplicar_patches.sh "$OBRA/ps2recomp" > /dev/null
mkdir -p "$P/vendor"
rsync -a --exclude=.git --exclude=out "$OBRA/ps2recomp/" "$P/vendor/PS2Recomp/"

echo "== Código das bibliotecas"
mkdir -p "$P/vendor/deps"
for n in elfio toml11 fmt libdwarf rabbitizer raylib imgui rlimgui vulkan_headers; do
    rsync -a --exclude=.git "$DEPS/$n-src/" "$P/vendor/deps/$n/"
done

# Nada do jogo pode ir junto.
if find "$P" \( -iname '*.iso' -o -name 'SLUS_*' -o -iname '*.elf' -o -name '*.gsr' \) | grep -q .; then
    echo "Arquivo do jogo no pacote: abortado" >&2; exit 1
fi
mkdir -p dist
rm -f dist/ShaolinMonksRPG-Linux.zip
(cd "$OBRA" && zip -qr -9 "$RAIZ/dist/ShaolinMonksRPG-Linux.zip" ShaolinMonksRPG)
rm -rf "$OBRA"
ls -la dist/ShaolinMonksRPG-Linux.zip
