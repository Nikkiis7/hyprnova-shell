# Hyprnova Shell

Uma shell para **Hyprland** feita em **Quickshell**: barra, dock, lançador, painéis, notificações e um painel de configurações completo. As cores vêm do wallpaper.

## Recursos

- **Barra** horizontal ou vertical, modo Padrão ou Mínimo, flutuante ou colada, com autohide
- **Dock** com autohide
- **Lançador de aplicativos** (modo Padrão ou Mínimo, posição configurável)
- **Painéis**: dashboard, sistema, janelas, calendário, volume, música, energia, wallpapers, cores
- **Gerenciador de rede** pelo ícone do tray (NetworkManager)
- **Notificações** próprias (duração e quantidade máxima configuráveis)
- **Tema pelo wallpaper**: Quickshell, kitty, yazi, btop, cava e bordas do Hyprland
- **Painel de configurações** com abas:
  Aparência, Barra, Notificações, Hyprland, Binds, Widgets, Fastfetch e Sobre
  - Hyprland: layout, bordas, arredondamento, gaps, blur, animações, transparência do kitty, resolução e taxa de atualização
  - Binds: lista e edita os atalhos do Hyprland
  - Fastfetch: escolha dos módulos
  - Sobre: especificações do sistema e idioma (Português/English)

## Instalação

```bash
git clone https://github.com/Nikkiis7/hyprnova-shell.git
cd hyprnova-shell
./install.sh
quickshell
```

Requisitos: Arch Linux, Hyprland 0.5x (config em Lua), Quickshell, kitty, NetworkManager, Python 3 e uma Nerd Font (Iosevka Nerd Font recomendada).

O instalador faz backup do seu `~/.config/quickshell` e **não** sobrescreve o `hyprland.lua`. Use `hypr/hyprland.lua.example` como referência.

## Atalhos e IPC

```bash
quickshell ipc call launcher toggle   # lançador (SUPER + SPACE)
quickshell ipc call network toggle    # gerenciador de rede
```

## Estrutura

| Pasta | Conteúdo |
|---|---|
| `quickshell/` | Todos os arquivos QML da shell |
| `bin/` | Scripts auxiliares (`hypr-appearance`, `hypr-res`, `fastfetch-apply`, `wall-theme`...) |
| `hypr/` | `hyprland.lua` de exemplo |
| `kitty/`, `fastfetch/` | Configs de apoio |
| `yazi/` | Config do gerenciador de arquivos yazi |
| `nvim/` | Config do Neovim (tema catppuccin) |

## Como as configurações funcionam

As escolhas do painel ficam em `settings.json` (criado ao usar). O painel Hyprland grava em `~/.cache/hypr-appearance.lua` e `~/.cache/hypr-res.lua`, que o `hyprland.lua` carrega.

## Licença

MIT
