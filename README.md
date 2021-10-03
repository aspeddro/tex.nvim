# tex.nvim

A Neovim plugin for TeX written in Lua.

## Requirements

- `Neovim >= 0.5.0`

## Features

- Switch between engines, `pdflatex`, `xelatex`, `lualatex`, `latexmk` and `tectonic`
- Watch multiple files
- Compile in specific events
- PDF viewers

## Recomendations

- Install Language Server Protocol (LSP), [nvim-lsp-installer](https://github.com/williamboman/nvim-lsp-installer)

- Install TreeSitter for better syntax highlight, [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)

## Installation

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'aspeddro/tex.nvim',
  config = function()
    require'tex'.setup{
      engine = 'tectonic',
      viewer = 'evince' -- your pdf viewer or 'xdg-open' to open default viewer
    }
  end
}
```

### [paq-nvim](https://github.com/savq/paq-nvim)

```lua
require "paq" {
  'aspeddro/tex.nvim';
}
require'tex'.setup{
  engine = 'tectonic',
  viewer = 'evince' -- your pdf viewer or 'xdg-open' to open default viewer
}
```

### [vim-plug](https://github.com/junegunn/vim-plug)

```lua
Plug 'aspeddro/tex.nvim'
```

## Configuration

```lua
-- default config
require'tex'.setup{
  engine = 'latexmk', -- tex engine
  compile = {
    events = { 'BufWritePost' }, -- compile when buffer is saved
    watchlist = true -- enable feature to compile the index file when any file from watch list is changed
  },
  viewer = nil,
  engines = { -- engines config
    tectonic = {},
    latexmk = {
      args = {
        '-pdf',
        ['-interaction'] = 'nonstopmode'
      }
    },
    pdflatex = {
      args = {
        ['-interaction'] = 'nonstopmode'
      }
    },
    xelatex = {
      args = {
        ['-interaction'] = 'nonstopmode'
      }
    },
    lualatex = {
      args = {
        ['-interaction'] = 'nonstopmode'
      }
    }
  }

}
```

## Usage

Make the current file the index:

```
:TexSwitchIndex
```

Switch TeX engine:

```
:TexSwitchEngine
```

Add file to watch list:

```
:TexAdd
```

Remove file from watch list:

```
:TexRemove
```

Compile the index file or current file:

```
:TexCompile
```

Kill job:

```
:TexKill
```

Open PDF viewer:

```
:TexViewer
```

## Keymapping

```lua
vim.api.nvim_set_keymap('n', '<leader>rr', ':TexCompile<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>aa', ':TexAdd<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>dd', ':TexRemove<CR>', { noremap = true, silent = true })
```

## TODO

- [ ] Open log file
