#!/usr/bin/env bash
# Chamado pelo Instalar.bat dentro do WSL (Ubuntu): compila o jogo para Windows (MinGW) e devolve a pasta
# portatil/MKSM-windows ao lado do Instalar.bat. O jogo resultante é nativo do Windows; o WSL só compila.
# uso: scripts/instalar_wsl.sh <pasta do repositório no Windows, caminho /mnt/...>
set -euo pipefail
ORIGEM=$(cd "$1" && pwd)
OBRA="$HOME/ShaolinMonksRPG" # compilar em /mnt/c é muito lento; a obra fica no disco do WSL

iso=$(find "$ORIGEM/coloque_o_jogo_aqui" -maxdepth 1 -iname '*.iso' 2>/dev/null | head -1)
[[ -n "$iso" || -f "$OBRA/extraido_full/SLUS_210.87" ]] ||
    { echo "Coloque a ISO do seu jogo (PS2, USA, SLUS-210.87) na pasta coloque_o_jogo_aqui e rode de novo."; exit 1; }

echo "== Instalando as ferramentas no WSL (pode pedir a senha do Ubuntu)"
sudo apt-get update
sudo apt-get install -y git cmake ninja-build p7zip-full g++ glslc libvulkan-dev rsync python3 \
    mingw-w64 libx11-dev libxrandr-dev libxinerama-dev libxcursor-dev libxi-dev libgl1-mesa-dev
# O runtime usa std::thread: o MinGW do Ubuntu precisa da variante posix (a padrão é win32).
for c in gcc g++; do
    sudo update-alternatives --set "x86_64-w64-mingw32-$c" "/usr/bin/x86_64-w64-mingw32-$c-posix" 2>/dev/null || true
done

echo "== Copiando o repositório para o disco do WSL"
mkdir -p "$OBRA"
rsync -a --delete --exclude=coloque_o_jogo_aqui --exclude=portatil --exclude=PS2Recomp --exclude=extraido \
    --exclude=extraido_full --exclude=output "$ORIGEM/" "$OBRA/"
mkdir -p "$OBRA/coloque_o_jogo_aqui"
[[ -n "$iso" ]] && cp -u "$iso" "$OBRA/coloque_o_jogo_aqui/"

cd "$OBRA"
echo "== Gerando o C++ do jogo"
ATE_RECOMPILAR=1 scripts/instalar.sh
echo "== Compilando para Windows (a primeira vez leva algumas horas; pode deixar rodando)"
scripts/build_windows.sh "$OBRA"

echo "== Copiando a pasta do jogo para o Windows"
mkdir -p "$ORIGEM/portatil"
rsync -rt --copy-links --exclude='mc0' --exclude='mc1' "$OBRA/portatil/MKSM-windows/" "$ORIGEM/portatil/MKSM-windows/"
for mc in mc0 mc1; do # memory cards: só na primeira vez, para não apagar os saves de quem já joga
    [[ -d "$ORIGEM/portatil/MKSM-windows/jogo/$mc" ]] || cp -r "$OBRA/portatil/MKSM-windows/jogo/$mc" "$ORIGEM/portatil/MKSM-windows/jogo/" 2>/dev/null || true
done
echo
echo "Pronto! A pasta portatil\\MKSM-windows está ao lado do Instalar.bat: dois cliques em Jogar.bat."
