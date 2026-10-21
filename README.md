# ✦ nvim-dotfiles

A dark, animated, full-IDE Neovim setup: a near-black "void" theme, a cursor that burns like fire, an animated dashboard that greets you by name, and file history that's always one key away.

## Install

```sh
git clone https://github.com/Dhruvch1244/nvim-dotfiles ~/dotfiles
cd ~/dotfiles && ./install.sh
nvim
```

`install.sh` installs the tools below for your system (Arch, Debian/Ubuntu, Fedora or macOS/Homebrew; it asks first), backs up any existing `~/.config/nvim`, links this config in its place and installs the plugins at the exact versions in `lazy-lock.json`. Run `./install.sh --no-deps` to only link the config.

**On first start it asks your name.** Your name is drawn in big letters on the dashboard. Change it any time with `:SetName`.

### Requirements

| | |
|---|---|
| **Neovim ≥ 0.11** | the script can download the official release if your distro's is older |
| git, ripgrep, fd, gcc, make, unzip, curl | search, plugins and parsers |
| node + npm | language servers (TypeScript, HTML/CSS, JSON, YAML, Bash, …) |
| tree-sitter CLI | builds syntax parsers |
| A [Nerd Font](https://www.nerdfonts.com) | icons (e.g. JetBrainsMono Nerd Font) |
| *optional:* lazygit, a JDK, python3, the `claude` CLI | git UI, Java, Python debugging, AI commit messages |

Anything optional that's missing is skipped instead of throwing errors.

## Features

**Look & feel**
- **Void theme:** [cyberdream](https://github.com/scottmckendry/cyberdream.nvim) pushed to near-black, with violet borders and dimmed separators.
- **Fire cursor:** a flickering flame trail with rising embers. Each mode burns its own color: orange (normal), blue (insert), purple (visual), red (replace) and green (command). `<leader>uF` switches to a calmer "cosmic" style.
- **Animated dashboard:** your name in a flowing neon gradient, a time-of-day greeting, a two-column layout ("Continue where you left off", recent files, projects), and a random tip.
- **Smooth everything:** smooth scrolling, animated indent guides, and a pulse on the line you land on when you open a file.
- **Hold mode:** effects lighten automatically while you hold a key (`j`, `<C-d>`…), so nothing stutters.

**Getting around**
- File tree (neo-tree): files you've opened stay highlighted.
- The statusline shows the file you came from; `<leader>bb` jumps back to it.
- `<leader>fh` shows your file trail for this session.

**IDE**
- LSP, completion (blink.cmp), formatting (conform), treesitter, debugging (DAP), tests (neotest), git (gitsigns, diffview, lazygit), Java (jdtls), Rust (rustaceanvim), HTTP client (hurl) and a database UI (dadbod).
- `<leader>rr` detects and runs project tasks: npm/pnpm/yarn/bun, Cargo, Maven, Gradle, Make, just, Python, Go and Docker Compose.
- Claude Code integration, and `<leader>gc` writes commit messages with the `claude` CLI.

## Keys

Leader is `Space`. Press it and wait to see every key.

| Key | Action |
|---|---|
| `<leader><space>` / `<leader>ff` | Find files (smart / all) |
| `<leader>/` | Grep the project |
| `<leader>fr` / `<leader>fR` | Recent files (everywhere / this project) |
| `<leader>fh` | File trail (this session) |
| `<leader>bb` | Previous file |
| `<leader>e` | File tree |
| `<leader>;` | Dashboard |
| `<leader>gg` | Lazygit |
| `<leader>gc` | AI commit message |
| `<leader>rr` / `<leader>rf` | Run a project task / the current file |
| `<leader>D` | Database UI |
| `<leader>tt` / `<C-/>` | Terminal |
| `s` | Flash-jump anywhere on screen |
| `<leader>uF` | Fire ↔ cosmic cursor |
| `<leader>ua` | All animations on/off |
| `<leader>uS` | Cursor trail on/off |

On the dashboard: `.` reopens your last file, `1`–`9` open recent files, and `p` lists your projects.

## Customize

| What | Where |
|---|---|
| Your name | `:SetName`. It's stored in `~/.local/share/nvim/user.json`, not in this repo |
| Colors, flame colors, mode colors | `nvim/lua/config/fx.lua` (top of the file) |
| Cursor trail and ember physics | `nvim/lua/plugins/ui.lua` → `smear-cursor.nvim` |
| Dashboard menu, sections, tips | `nvim/lua/plugins/snacks.lua` |
| Plugins | one file per area in `nvim/lua/plugins/` |

## Update / uninstall

```sh
cd ~/dotfiles && git pull && nvim "+Lazy! restore" +qa   # update
rm ~/.config/nvim                                       # uninstall (then restore your ~/.config/nvim.backup-* if you had one)
```

## Credits

[lazy.nvim](https://github.com/folke/lazy.nvim), [snacks.nvim](https://github.com/folke/snacks.nvim), [smear-cursor.nvim](https://github.com/sphamba/smear-cursor.nvim), [cyberdream.nvim](https://github.com/scottmckendry/cyberdream.nvim), and every other plugin listed in `nvim/lua/plugins/`.
