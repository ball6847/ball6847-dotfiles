# My Personal NVChad Config

This is my personal NVChad config. I have made some changes to the original config to suit my needs. I have also added some plugins that I use.

## Installation

After linking the `nvim` folder to `~/.config`, open nvim and run the following nvim command

- `Lazy` then press (I) to install the plugins
- `MasonInstallAll` then press (I) to install the LSP servers

## LSP Servers and Formatter

The following command install all dependencies for the LSP servers and formatters

Note that, `npm`, `go` and `gem` are required to install the LSP servers and formatters.

> My dotfiles has `asdf` installed, so I can install `nodejs`, `ruby` and `golang` using `asdf install`

If you have everything installed, you can run the following command to install the LSP servers and formatters.
I might need to run this command from time to time to update the LSP servers and formatters

```bash
npm install -g typescript typescript-language-server svelte-language-server @fsouza/prettierd nodemon
asdf reshim
```

Note about ruby, some dev dependencies is required to install ruby using asdf. You can install the dependencies using the following command

```bash
sudo apt update
sudo apt install -y build-essential zlib1g-dev libssl-dev libreadline-dev libyaml-dev libncurses5-dev libffi-dev libgdbm-dev

# my dotfiles has asdf installed, so I can install ruby using asdf
asdf install ruby
```

## Mapping worth remembering

- `<C-N>` to toggle NvimTree
- `<leader>e` to focus on NvimTree
- `<leader>ff` to find files
- `<leader>fw` to find word across files (requires ripgrep, `apt install ripgrep` if you use ubuntu)
- `<leader>S` to trigger Spectre (search and replace)
- `<leader>fg` to trigger hop (jump to any word)
- `<leader>ca` to trigger code action (actionable item for the current file)
- `<leader>cai` to trigger organize import
- `<leader>ra` to trigger rename symbol
- `<leader>gd` to trigger go to definition
- `<leader>gr` to trigger go to references
- `<leader>gi` to trigger go to implementation
- `<leader>ds` to open diagnostic list
- `<leader>tw` to toggle nvim-tree width between 30 and 40 as sometimes the width is too small (adjust the width in `lua/mappings.lua`)
- `<leader>ba` to close all buffers except nvim-tree
- `<C-L>` to accept github copilot suggestion
- `<C-X>` on nvim-tree to open file in horizontal split
- `<C-V>` on nvim-tree to open file in vertical split
- `W` on nvim-tree to collapse all folders

## Github Copilot

Run `:Copilot setup` to setup github copilot and follow the instructions. Use `<C-L>` to accept the suggestion

## Windows terminal user

You might need to remove `C-V` binding in Windows Terminal for pasting to allow `C-V` to open file in vertical split in NvimTree (You still can use Ctrl+Shift+V to paste)
