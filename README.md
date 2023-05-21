# hmm.nvim

h-m-m for neovim, with an infinite pannable canvas, colorschemes, file explorer etc.

Tested for use as standalone program, powered by NVIM_APPNAME from neovim.

Automatically installs needed dependencies ( i.e. plugins ) using lazy.nvim.

## Installation

```bash
git clone https://github.com/manyids2/hmm.nvim
cd hmm.nvim

# Install to XDG_CONFIG_DIR/nvim-apps/hmm.nvim
make install

# Instructions for example run
make run
```

## Main diff compared to h-m-m

- Pan canvas
- Open multiple files
- (planned) Mouse support
- (planned) Toggle each node between list, tree, and `text` views
- (planned) Link to external maps, break off trees, render on infinite canvas, etc.

## Extra for free thanks to neovim

- Search for file
- Search within all files
- Change colorscheme dynamically
- Undo, redo across sessions
- Cross platform
- Blazing fast

## Fails

- Reads and writes a lot - absolutely not performant
- Should save state to some different place
- Horrible code to check if node in view
- Opening file from telescope needs to press `<esc>` before interacting
- Not checking recursion while pasting

## Roadmap

- multiline text
- feature parity
- proper return from telescope
- more navigation, editing options
- list/tree state for each node
- save state somewhere else than in hmm file
- read write lines rather than whole file
- link node to another hmm file, render and save appropriately
- link node to md file, show on canvas, in float
- paste list as children, e.g. from ls or other bash commands

## Key bindings

Checklist for feature parity with original.

Adding, removing, and editing nodes:

- [x] `o` or `Enter` - create a new sibling to the active node
- [x] `O` or `Tab` - create a new child for the active node
- [x] `y` - yanks (copies) the active node and its descendants
- [ ] `Y` - yanks (copies) the descendants of the active node
- [x] `d` - deletes (cuts) the active node and its descendants
- [ ] `D` - deletes (cuts) the descendants of the active node
- [x] `Delete` - deletes the active node and its descendants without putting them in the clipboard
- [-] `p` - pastes as descendants of the active node
- [-] `P` - pastes as siblings of the active node
- [ ] `Ctrl+p` - appends the clipboard text at the end of the active node's title
- [x] `e`, `i`, or `a` - edits the active node
- [x] `E`, `I`, or `A` - edits the active node, ignoring the existing text
- [x] `u` - undo
- [x] `Ctrl+r` - redo

Marks:

- [ ] `t` - toggles '✓ ', '✗ ', and '' (or your custom symbols) at the beginning of the title
- [ ] `#` - adds or removes sequential numbers at the beginning of the titles of a node and its siblings
- [ ] `=` - increases the positive ranking
- [ ] `+` - decreases the positive ranking
- [ ] `-` - increases the negative ranking
- [ ] `_` - decreases the negative ranking
- [ ] `H` - toggles the hidden flag

Relative navigating and moving:

- [x] `h` or `←` - activates the parent of the previously active node
- [x] `l` or `→` - activates the middle child of the previously active node
- [-] `j` or `↓` - activates the lower sibling (or the nearest lower node if there's no lower sibling)
- [-] `k` or `↑` - activates the higher sibling (or the nearest higher node if there's no higher sibling)
- [x] `J` - moves the current node down among its siblings
- [x] `K` - moves the current node up among its siblings
- [ ] `T` - sorts the siblings of the active node

Adjusting the view:

- [x] `c` - centers the active node on the screen
- [x] `C` - locks/unlocks active nodes on the center
- [x] `~` or `m` - activate the root element
- [ ] `g` - goes to the highest element
- [ ] `G` - goes to the lowest element
- [ ] `w` - increases the maximum node width
- [ ] `W` - decreases the maximum node width
- [ ] `z` - decreases line spacing
- [ ] `Z` - increases line spacing
- [-] `|` - enables/disables aligned levels
- [ ] `ctrl+h` - hides/views hidden nodes

Collapsing and expanding:

- [x] `Space` - toggles the active node
- [ ] `v` - collapses everything other than the first-level nodes
- [ ] `V` - collapses all the children of the active node
- [x] `b` - expands all nodes
- [x] `B` - collapses all nodes ( extra )
- [ ] `1` to `9` - collapse the nth level and expand those before
- [ ] `f` - focuses by collapsing all, but the ancestors and descendants of the active node
- [ ] `F` - locks focus as the active node changes (try it with the center lock)
- [ ] `r` - collapses all the first level items except for the one that contains the active node
- [ ] `R` - collapses the children of the active node

Search:

- [-] `/`, `?`, or `Ctrl+f` - searches for a phrase
- [-] `n` - goes to the next search result
- [-] `N` - goes to the previous search result

Save, export, quit, etc.:

- [o] `s` - saves with the previous file name (or asks for one if there's none)
- [o] `S` - saves with a new file name
- [ ] `x` - export as an HTML file
- [ ] `X` - export as a text map into clipboard
- [x] `q` - quits (if the changes were already saved)
- [o] `Q` - quits, ignoring the changes
- [ ] `Ctrl+o` - open the active node as a file or URL using xdg-open

In the text editor:

( We can ignore, as we use `noice` for input )

- [x] `↓` - moves the cursor to the end of the line
- [x] `↑` - moves the cursor to the beginning of the line
- [x] `←` or `Home` - moves the cursor to the left
- [x] `→` or `End` - moves the cursor to the right
- [x] `Ctrl+Left` or `Shift+Left` - moves cursor to the previous word
- [x] `Ctrl+Right` or `Shift+right` - moves cursor to the next word
- [x] `Delete` - deletes character
- [ ] `Ctrl+Delete` - deletes word
- [x] `Backspace` - deletes previous character
- [ ] `ctrl+Backspace` - deletes previous word
- [ ] `Ctrl+v` or `Ctrl+Shift+v` - paste
- [x] `Esc` - cancels editing
- [x] `Enter` - wanna guess? ;)

## Configuration

The following are the settings in h-m-m:

- [-] max_parent_node_width = 25
- [-] max_leaf_node_width = 55
- [x] line_spacing = 1
- [-] align_levels = 0
- [x] initial_depth = 1
- [-] center_lock = false
- [x] focus_lock = false
- [o] max_undo_steps = 24
