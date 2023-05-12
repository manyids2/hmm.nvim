# h-m-m (hackers mind map)

**h-m-m** (pronounced like the interjection "hmm") is a simple,
fast, keyboard-centric terminal-based tool for working with mind maps. 

## Key bindings

Adding, removing, and editing nodes:

- `o` or `Enter` - create a new sibling to the active node
- `O` or `Tab` - create a new child for the active node
- `y` - yanks (copies) the active node and its descendants
- `Y` - yanks (copies) the descendants of the active node
- `d` - deletes (cuts) the active node and its descendants
- `D` - deletes (cuts) the descendants of the active node
- `Delete` - deletes the active node and its descendants without putting them in the clipboard
- `p` - pastes as descendants of the active node
- `P` - pastes as siblings of the active node
- `Ctrl+p` - appends the clipboard text at the end of the active node's title
- `e`, `i`, or `a` - edits the active node
- `E`, `I`, or `A` - edits the active node, ignoring the existing text
- `u` - undo
- `Ctrl+r` - redo

Marks:

- `t` - toggles '✓ ', '✗ ', and '' (or your custom symbols) at the beginning of the title
- `#` - adds or removes sequential numbers at the beginning of the titles of a node and its siblings
- `=` - increases the positive ranking
- `+` - decreases the positive ranking
- `-` - increases the negative ranking
- `_` - decreases the negative ranking
- `H` - toggles the hidden flag

Relative navigating and moving:

- `h` or `←` - activates the parent of the previously active node
- `l` or `→` - activates the middle child of the previously active node
- `j` or `↓` - activates the lower sibling (or the nearest lower node if there's no lower sibling)
- `k` or `↑` - activates the higher sibling (or the nearest higher node if there's no higher sibling)
- `J` - moves the current node down among its siblings
- `K` - moves the current node up among its siblings
- `T` - sorts the siblings of the active node

Adjusting the view:

- `c` - centers the active node on the screen
- `C` - locks/unlocks active nodes on the center
- `~` or `m` - activate the root element
- `g` - goes to the highest element
- `G` - goes to the lowest element
- `w` - increases the maximum node width
- `W` - decreases the maximum node width
- `z` - decreases line spacing
- `Z` - increases line spacing
- `|` - enables/disables aligned levels
- `ctrl+h` - hides/views hidden nodes

Collapsing and expanding:

- `Space` - toggles the active node
- `v` - collapses everything other than the first-level nodes
- `V` - collapses all the children of the active node
- `b` - expands all nodes
- `1` to `9` - collapse the nth level and expand those before
- `f` - focuses by collapsing all, but the ancestors and descendants of the active node
- `F` - locks focus as the active node changes (try it with the center lock)
- `r` - collapses all the first level items except for the one that contains the active node
- `R` - collapses the children of the active node

Search:

- `/`, `?`, or `Ctrl+f` - searches for a phrase
- `n` - goes to the next search result
- `N` - goes to the previous search result

Save, export, quit, etc.:

- `s` - saves with the previous file name (or asks for one if there's none)
- `S` - saves with a new file name
- `x` - export as an HTML file
- `X` - export as a text map into clipboard
- `q` - quits (if the changes were already saved)
- `Q` - quits, ignoring the changes
- `Ctrl+o` - open the active node as a file or URL using xdg-open

In the text editor:

- `↓` - moves the cursor to the end of the line
- `↑` - moves the cursor to the beginning of the line
- `←` or `Home` - moves the cursor to the left
- `→` or `End` - moves the cursor to the right
- `Ctrl+Left` or `Shift+Left` - moves cursor to the previous word
- `Ctrl+Right` or `Shift+right` - moves cursor to the next word
- `Delete` - deletes character
- `Ctrl+Delete` - deletes word
- `Backspace` - deletes previous character
- `ctrl+Backspace` - deletes previous word
- `Ctrl+v` or `Ctrl+Shift+v` - paste
- `Esc` - cancels editing
- `Enter` - wanna guess? ;)

## Configuration

The following are the settings in h-m-m:

    max_parent_node_width = 25
    max_leaf_node_width = 55
    line_spacing = 1
    align_levels = 0
    initial_depth = 1
    center_lock = false
    focus_lock = false
    max_undo_steps = 24
    active_node_color = \033[38;5;0m\033[48;5;172m\033[1m
    message_color = \033[38;5;0m\033[48;5;141m\033[1m
    clipboard = os
    clipboard_file = /tmp/h-m-m
    clipboard_in_command = ""
    clipboard_out_command = ""
    post_export_command = ""
    symbol1 = ✓
    symbol2 = ✗

The colors are ASCII escape codes.

You have 3 different ways of setting those values:

1. Pass them as arguments when running the program; e.g., `h-m-m --focus-lock=true --line-spacing=0 filename`
1. Set them as environment variables with `hmm_` as prefix; e.g., `hmm_line_spacing=0`
1. Store them in a config file. You can pass the location of the config file when running the application like `h-m-m --config=/path/file`, or use the default location:
   - Linux: ~/.config/h-m-m/h-m-m.conf
   - Mac: ~/Library/Preferences/h-m-m/h-m-m.conf
   - Windows: an h-m-m.conf file in the same directory as the script

Both underscores and dashes are accepted for the setting keys.

When multiple values exists, the highest priority goes to the command line arguments and the lowest to the config file.

## Clipboard

The normal `os` clipboard works fine for most users, but some users may need other options:

- `--clipboard=os` uses the global clipboard via xclip and similar tools.
- `--clipboard=internal` uses an internal variable as the clipboard (won't exchange text with external applications).
- `--clipboard=file` uses `/tmp/h-m-m` by default, or another file set by the `--clipboard_file=/path/filename` setting as the clipboard.
- `--clipboard=command` uses `--clipboard_in_command="command %text%"` to send content to a shell command and `--clipboard_out_command="command"` to read content.

## Exporting

You can export an HTML version of the map using the `x` key binding. This is useful for sending the file to someone who may not have h-m-m or a similar mind mapping application. To make the process easier, you can set a sell command to run after exporting the map; e.g., upload it to a server and copy the link to clipboard: `--post-export-command="upload.sh %filename% &>/dev/null"`.

## Data format

Mind maps are stored in plain text files (with `hmm` file extension by default) without metadata. The tree structure is represented by tab indentations; e.g.,

    root (level 0)
       item A (level 1)
       item B (level 1)
          item Ba (level 2)
          item Bb (level 2)
          item Bc (level 2)
             item BaX (level 3)
             item BaY (level 3)
          item Bd (level 2)
       item C (level 1)

When you yank (copy) or delete (cut) a subtree, the data will be put into your clipboard with a similar structure, and when pasting, the data will be interpreted as such.

Most mind mapping applications use a similar format for copying and pasting. As a result, if you want to import a map from another application, you can probably select everything in that application, copy it, come to **h-m-m**, and paste it. The same usually works well when copying from HTML/PDF/Doc lists, spreadsheets (e.g., Calc and Excel), etc.
