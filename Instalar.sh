#!/usr/bin/env bash
# ShaolinMonks RPG, instalador do Linux: ponha a sua ISO em coloque_o_jogo_aqui/ e dê dois cliques aqui (ou rode
# ./Instalar.sh num terminal). Instala o que faltar (pede a senha uma vez), compila e monta portatil/MKSM-linux.
# A primeira compilação leva algumas horas. Se parar no meio, rode de novo: as etapas prontas são puladas.
set -euo pipefail
cd "$(dirname "$0")"

# Aberto com dois cliques, sem terminal: abre um, para mostrar o andamento e pedir a senha.
if [[ ! -t 1 && -z "${MKSM_NO_TERMINAL:-}" ]]; then
    export MKSM_NO_TERMINAL=1
    for t in konsole gnome-terminal xfce4-terminal kitty alacritty x-terminal-emulator xterm; do
        command -v "$t" >/dev/null || continue
        case "$t" in
            gnome-terminal) exec gnome-terminal -- bash "$0" ;;
            *) exec "$t" -e bash "$0" ;;
        esac
    done
    echo "Abra um terminal nesta pasta e rode ./Instalar.sh" >&2
    exit 1
fi
trap 'echo; read -rp "Aperte Enter para fechar." _' EXIT

iso=$(find coloque_o_jogo_aqui -maxdepth 1 -iname '*.iso' 2>/dev/null | head -1)
if [[ -z "$iso" && ! -f extraido_full/SLUS_210.87 ]]; then
    echo "Coloque a ISO do seu jogo (PS2, USA, SLUS-210.87) na pasta coloque_o_jogo_aqui/ e rode de novo."
    exit 1
fi

echo "== Conferindo as ferramentas"
falta=()
for c in cmake ninja 7z g++ glslc rsync python3 pkg-config; do command -v "$c" >/dev/null || falta+=("$c"); done
pkg-config --exists libavcodec libavformat libswscale 2>/dev/null || falta+=(ffmpeg)
if ((${#falta[@]})); then
    echo "Faltam: ${falta[*]}. Instalando (pede a senha)."
    if command -v pacman >/dev/null; then
        sudo pacman -S --needed --noconfirm git cmake ninja p7zip gcc shaderc vulkan-icd-loader vulkan-headers \
            ffmpeg pkgconf rsync python libx11 libxrandr libxinerama libxcursor libxi mesa
    elif command -v apt-get >/dev/null; then
        sudo apt-get update
        sudo apt-get install -y git cmake ninja-build p7zip-full g++ glslc libvulkan-dev rsync python3 pkg-config \
            libavcodec-dev libavformat-dev libavutil-dev libswresample-dev libswscale-dev libx11-dev libxrandr-dev libxinerama-dev libxcursor-dev libxi-dev libgl1-mesa-dev
    elif command -v dnf >/dev/null; then
        sudo dnf install -y git cmake ninja-build p7zip p7zip-plugins gcc-c++ glslc vulkan-loader-devel rsync python3 pkgconf \
            ffmpeg-free-devel libX11-devel libXrandr-devel libXinerama-devel libXcursor-devel libXi-devel mesa-libGL-devel
    else
        echo "Não reconheci o gerenciador de pacotes. Instale: ${falta[*]} (e as bibliotecas de desenvolvimento do X11 e do Vulkan)."
        exit 1
    fi
fi

echo "== Compilando (a primeira vez leva algumas horas; pode deixar rodando)"
scripts/instalar.sh ${iso:+"$iso"}

echo "== Montando a pasta do jogo"
scripts/empacotar_linux.sh

echo
echo "Pronto! Para jogar: dois cliques em portatil/MKSM-linux/jogar.sh (ou rode ./jogar.sh dentro dela)."
echo "A pasta portatil/MKSM-linux leva o seu jogo: copie-a para onde quiser, mas não a publique."
