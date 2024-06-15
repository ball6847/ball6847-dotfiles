# My Personal NVChad Config

This is my personal NVChad config. I have made some changes to the original config to suit my needs. I have also added some plugins that I use.

## Installation

After linking the `nvim` folder to `~/.config`, open nvim and run the following nvim command

- `Lazy` then press (I) to install the plugins
- `MasonInstallAll` then press (I) to install the LSP servers

## LSP Servers and Formatter

The following command install all dependencies for the LSP servers and formatters

Note that, `npm` and `go` are required to install the LSP servers and formatters

```bash
npm install -g typescript typescript-language-server svelte-language-server @fsouza/prettierd nodemon
asdf reshim
```

I might need to run this command from time to time to update the LSP servers and formatters
