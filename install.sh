#!/usr/bin/env bash
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
STAMP=$(date +%Y%m%d-%H%M%S)

echo "==> Dependências (Arch)"
echo "    sudo pacman -S hyprland kitty fastfetch networkmanager python rsync jq imagemagick"
echo "    AUR: quickshell (ou quickshell-git), ttf-iosevka-nerd; opcional: inter-font, yazi, btop, cava"
read -rp "Continuar a instalação dos arquivos? [s/N] " r
[[ "$r" =~ ^[sS]$ ]] || exit 0

echo "==> Quickshell -> ~/.config/quickshell"
if [ -d ~/.config/quickshell ]; then
  mv ~/.config/quickshell ~/.config/quickshell.bak-$STAMP
  echo "    backup em ~/.config/quickshell.bak-$STAMP"
fi
mkdir -p ~/.config/quickshell
cp -r "$HERE"/quickshell/. ~/.config/quickshell/

echo "==> Scripts -> ~/.local/bin"
mkdir -p ~/.local/bin
cp "$HERE"/bin/* ~/.local/bin/
chmod +x ~/.local/bin/*

echo "==> Kitty"
mkdir -p ~/.config/kitty
cp "$HERE"/kitty/opacity.conf ~/.config/kitty/ 2>/dev/null || true
grep -q 'include opacity.conf' ~/.config/kitty/kitty.conf 2>/dev/null || echo 'include opacity.conf' >> ~/.config/kitty/kitty.conf

echo "==> Fastfetch"
mkdir -p ~/.config/fastfetch
[ -f "$HERE"/fastfetch/config.jsonc.orig ] && [ ! -f ~/.config/fastfetch/config.jsonc.orig ] && cp "$HERE"/fastfetch/config.jsonc.orig ~/.config/fastfetch/

# waybar-color exige este arquivo
mkdir -p ~/.config/waybar
[ -f ~/.config/waybar/style.css ] || echo '@define-color accent #89b4fa;' > ~/.config/waybar/style.css

echo
echo "Pronto. O hyprland.lua NÃO foi sobrescrito."
echo "Use hypr/hyprland.lua.example como base (ele lê ~/.cache/hypr-appearance.lua e ~/.cache/hypr-res.lua)."
echo "Inicie com: quickshell   (adicione 'exec-once' no Hyprland para iniciar com a sessão)"
