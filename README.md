# nb.nvim

[![CI](https://github.com/mozumasu/nb.nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/mozumasu/nb.nvim/actions/workflows/ci.yml)

Neovim integration for [`nb`](https://github.com/xwmx/nb) — the CLI plain-text
note-taking, bookmarking, and knowledge base tool.

Browse, create, link, and organize your nb notes without leaving Neovim, with
automatic git commit & remote sync when you close a note.

## Features

- **Pick & grep** — fuzzy-find notes by title across all notebooks (with
  preview), or live-grep their contents
- **Add** — create a timestamped note in the current (or any) notebook and
  start writing immediately
- **Auto commit & sync** — when you save a note and close its buffer (or quit
  Neovim), the note is committed and synced with the remote
  (`pull --rebase` + `push`) in a detached background process
- **Link** — insert `[[wiki-style]]` links to any note, including
  cross-notebook `[[notebook:note]]` links and image links served via
  `nb browse`
- **Import images** — import an image from the clipboard (via
  [img-clip.nvim](https://github.com/HakonHarnes/img-clip.nvim)) or a file
  path, and insert its markdown link
- **Move / delete / adopt** — move notes between notebooks, delete them from
  the picker, or adopt any external file into a notebook — every operation is
  git-committed automatically

## Requirements

- Neovim >= 0.10
- [`nb`](https://github.com/xwmx/nb)
- [snacks.nvim](https://github.com/folke/snacks.nvim) (picker UI)
- [img-clip.nvim](https://github.com/HakonHarnes/img-clip.nvim) *(optional,
  clipboard image import)*

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "mozumasu/nb.nvim",
  dependencies = { "folke/snacks.nvim" },
  lazy = false, -- load at startup so autosync autocmds are registered
  opts = {},
  -- stylua: ignore
  keys = {
    { "<leader>na", function() require("nb").add() end, desc = "nb add" },
    { "<leader>nA", function() require("nb").add_select() end, desc = "nb add (select notebook)" },
    { "<leader>ni", function() require("nb").import_image() end, desc = "nb import image" },
    { "<leader>nl", function() require("nb").link() end, desc = "nb link" },
    { "<leader>nm", function() require("nb").move() end, desc = "nb move to notebook" },
    { "<leader>nM", function() require("nb").adopt_buffer() end, desc = "nb adopt current buffer" },
    { "<leader>np", function() require("nb").pick() end, desc = "nb picker" },
    { "<leader>ng", function() require("nb").grep() end, desc = "nb grep" },
  },
}
```

## Configuration

Defaults:

```lua
require("nb").setup({
  -- nb data directory (nil resolves $NB_DIR, then ~/.nb)
  dir = nil,
  -- `nb browse` port, used to build/resolve cross-notebook image links
  browse_port = 6789,
  -- commit & sync notes with the remote when a saved buffer is closed
  autosync = true,
  -- timestamp format for generated note filenames
  timestamp_format = "%Y%m%d%H%M%S",
  -- custom picker preview: function(ctx) (nil uses snacks' file preview)
  preview = nil,
})
```

## API

UI (used by the keymaps above):

| Function | Description |
| --- | --- |
| `require("nb").pick()` | Fuzzy-find notes across all notebooks (`<C-d>` deletes) |
| `require("nb").grep()` | Live-grep note contents |
| `require("nb").add()` | Add a note to the current notebook |
| `require("nb").add_select()` | Pick a notebook, then add a note |
| `require("nb").import_image()` | Import clipboard image / file and insert a link |
| `require("nb").link()` | Insert a `[[link]]` to any note or image |
| `require("nb").move()` | Move the current note to another notebook |
| `require("nb").adopt_buffer()` | Move the current (external) file into a notebook |

Core helpers for building your own integrations:

| Function | Description |
| --- | --- |
| `get_title(path)` | Note title (H1 / frontmatter) for files under the nb dir — handy for bufferline labels |
| `resolve_browse_url(src)` | Resolve an `nb browse --original` URL to a local file path |
| `get_note_path(id)` | Resolve `notebook:note` to a file path via the nb CLI |
| `commit_and_sync(path)` | Commit a note and sync its notebook with the remote |

### Example: render nb images with snacks.nvim

Cross-notebook image links use `nb browse` URLs; teach `snacks.image` to
resolve them to local files:

```lua
-- in your snacks.nvim opts
image = {
  resolve = function(file, src)
    return require("nb").resolve_browse_url(src)
  end,
}
```

### Example: note titles in bufferline

```lua
-- in your bufferline.nvim opts
options = {
  name_formatter = function(buf)
    return require("nb").get_title(buf.path) or buf.name
  end,
}
```

## License

MIT
