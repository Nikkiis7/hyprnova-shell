# Hyprnova Shell

Uma shell para **Hyprland** feita em **Quickshell**, foi um projeto feito apenas por diversão, demorou bastante, mas valeu a pena, creio eu... Vale lembrar que essa é a minha primeira shell, portanto ela será bem simples comparada a outras shells, além de que pode conter alguns bugs.

## Dependências necessárias para a shell funcionar:

**- Hyprland** (Obrigatório);

**- Quickshell** (Obrigatório);

**- Fonte Iosevka**;

**- Python 3**;

**Starship + zshell** (Opcional, apenas se você quer ter o terminal igual o meu)

**Yazi e Nvim** (Opcional, se você quer ter um tema personalizado do Nvim e do Gerenciador de arquivos)



## Instalação

```bash
git clone https://github.com/Nikkiis7/hyprnova-shell.git
cd hyprnova-shell
./install.sh
quickshell
```

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

## SDDM (tela de login)

Tema usado: [sddm-astronaut-theme](https://github.com/Keyitdev/sddm-astronaut-theme).

```bash
yay -S sddm-astronaut-theme            # ou clone o repositório do tema em /usr/share/sddm/themes/
sudo mkdir -p /etc/sddm.conf.d
sudo cp sddm/conf.d/*.conf /etc/sddm.conf.d/
sudo cp sddm/theme-config/metadata.desktop /usr/share/sddm/themes/sddm-astronaut-theme/
sudo cp sddm/theme-config/Themes/*.conf /usr/share/sddm/themes/sddm-astronaut-theme/Themes/
sudo systemctl enable sddm
```
