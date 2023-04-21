local native = require('alt-modes.native')
local M = {}

M.misc     = {}
M.mode     = {}
M.mouse    = {}
M.tabs     = {}
M.yank     = {}
M.spell    = {}
M.layout   = {}
M.modify   = {}
M.scroll   = {}
M.folding  = {}
M.buffers  = {}
M.present  = {}
M.windows  = {}
M.movement = {}

local misc    = M.misc
local mode    = M.mode
local mouse   = M.mouse
local move    = M.movement
local folding = M.folding
local spell   = M.spell
local layout  = M.layout
local modify  = M.modify
local scroll  = M.scroll
local buffers = M.buffers
local present = M.present
local windows = M.windows

local internal = {}


-- ==============================================
-- internal commands
--
internal.register = {
  -- ====================================================================
  -- Register type/purpose
  --
  --   "  unnamed reg.
  -- 0-9  numberd regs. (filled automatically)
  -- a-z  named (explicitle put into this reg)
  -- A-Z  named (explicitle append to this reg)
  --   -  small delete (less than one line of delete)
  --   _  black hole (it is lost, does not affec any other reg)
  --   =  expression register (evaluated uppon paste)
  --   :  last command line
  --   %  current file name
  --   .  last inserted text
  --   #  alternate file (CTRL-^ switches to file in reg)
  --   /  last search pattern
  --   +  X11 PRIMARY (last selected text, pasted with middle mouse)
  --   *  X11 CLIPBOARD

  --            |   special   |             |        | black |
  --  command   |  RO  |  RW  |     auto    |  named | hole  |
  -- -----------+------+------+-------------+--------+-------+-------------
  --  d c s x   |      |      |     " 0-9 - | a-zA-Z |   _   |
  --  y         |      |      |     " 0-9   | a-zA-Z |   _   |
  -- -----------+------+------+-------------+--------+-------+-------------
  --  insert    |      |      | .           |        |       |
  --  search    |      |      |   /         |        |       |
  --  script    |      | # =  |   /         |        |       |
  -- -----------+-------------+-------------+--------+-------+-------------
  --  p P       | % :  | # =  | . / " 0-9 - | a-zA-Z |       |

  mark   = '0-9a-zA-Z',          -- valid names of marks (these are not registers)
  macro  = '0-9a-zA-Z',          -- registers which can be filled when macro is recorded
  get    = '0-9a-zA-Z"_',        -- registers which can be filled by x,d,y,c,s ..
  put    = '0-9a-zA-Z"_%:#=./',  -- registers which can be used for paste
}

internal.unused = {
  -- ======================================================================
  -- not used
  --
  '<C-@>',                 -- not used
  '<C-K>',                 -- not used
  '<C-_>',                 -- not used

  '<C-Q>',                 -- not used, or used for terminal control flow
  '<C-S>',                 -- not used, or used for terminal control flow
  '<C-Z>',                 -- suspend program (or start new shell)

  'CTRL-\\{a-z}',          -- reserved for extensions
  'CTRL-\\{others}',       -- not used

  'g<MiddleMouse>',        -- same as <CTRL-MiddleMouse>
}


-- ==============================================
-- MISC commands
--
misc.macro = {
  'q{reg.macro}',          -- record typed characters into named register {0-9a-zA-Z"} (uppercase to append)
  'q',                     -- (while recording) stops recording
  'Q',                     -- replay last recorded macro

  '@{reg.macro}',          -- execute the contents of register {a-z} N times
  '@@',                    -- repeat the previous @{a-z} N times
}

misc.mark = {
  'm{mark}'                -- set mark {A-Za-z} at cursor position
}

misc.misc = {
  '{count}<Del>',          -- remove the last digit from {count}
  '<F1>',                  -- same as <Help>
  '<Help>',                -- open a help window

  '<C-C>',                 -- interrupt current (search) command

  '<C-L>',                 -- redraw screen
  '<C-^>',                 -- edit Nth alternate file (equivalent to ":e #N")

  'gs',                    -- go to sleep for N seconds (default 1)
  'gx',                    -- execute application for file name under the cursor (only with netrw plugin)

  'gV',                    --   -  don't reselect the previous Visual area when executing a mapping or menu in Select mode
}

misc.filter = {
  '!{motion}{filter}',     -- filter N-move text through the {filter} command
  '!!{filter}',            -- filter N lines through the {filter} command

  '={motion}',             -- filter N-move lines through "indent"
  '==',                    -- filter N lines through "indent"
}

misc.operator = {
  -- ==================================================
  -- operators are commands which will carry action on
  -- text selected by "{motion}" i.e. after command has
  -- been entered keypressing will move cursors arrond,
  -- and selecting the text. operator action will be
  -- applied to selected text.
  --

  '!{motion}{filter}',     -- filter N-move text through the {filter} command
  '={motion}',             -- filter N-move lines through "indent"

  '<{motion}',             -- shift N-move lines one 'shiftwidth' leftwards
  '>{motion}',             -- shift N-move lines one 'shiftwidth' rightwards

  '~{motion}',             -- 'tildeop' on: switch case of N-move text
  'g~{motion}',            -- swap case for N-move text

  'gU{motion}',            -- make N-move text uppercase
  'gu{motion}',            -- make N-move text lowercase

  '{reg.get}c{motion}',    -- delete N-move text [into register x] and start insert
  '{reg.get}d{motion}',    -- delete N-move text [into register x]
  '{reg.get}y{motion}',    -- yank N-move text [into register x]

  'gq{motion}',            -- format N-move text
  'gw{motion}',            -- format N-move text and keep cursor

  'zf{motion}',            -- create a fold for N-move text

  -- ======================================================
  -- This is special operator. When used, function defined
  -- with "operatorfunc" option (value of the variable)
  -- will be applied. It can be also used to define custom
  -- operator commands (via "nmap"). Trick is to call the
  -- function, which will set value for "operatorfunc"
  -- and return 'g@'. Nvim will "execute" 'g@' command,
  -- transition into "operator pending" mode, and after
  -- text is selected bia "{motion}", function defined
  -- in "operatorfunc" will be applied to selected text.
  --
  'g@{motion}',            -- call 'operatorfunc' (user defined function on motion)
}

misc.mode = {
  '<C-bslash><C-N>',              -- go to Normal mode (no-op)
  '<C-bslash><C-G>',              -- go to Normal mode (no-op)
}


-- ==============================================
-- MODE changing commands
--
mode.cmdline = {
  '@:',                    --    repeat the previous ":" command N times

  'q:',                    --    edit : command-line in command-line window
  'q/',                    --    edit / command-line in command-line window
  'q?',                    --    edit ? command-line in command-line window
}

mode.ex = {
  -- ======================================================================
  -- cmd line
  --
  ':',                     -- 1  start entering an Ex command
  '{count}:',              --    start entering an Ex command with range from current line to N-1 lines down
  'gQ',                    --    switch to "Ex" mode with Vim editing
}

mode.visual = {
  -- ======================================================================
  -- command that enter "visual" mode
  --
  'v',                     --    start charwise Visual mode
  'V',                     --    start linewise Visual mode
  '<C-V>',                 --    start blockwise Visual mode
  '<RightMouse>',          --    start Visual mode, move cursor to the mouse click position

  'gN',                    -- 1,2  find the previous match with the last used search pattern and Visually select it
  'gn',                    -- 1,2  find the next match with the last used search pattern and Visually select it

  'gv',                    --   -  reselect the previous Visual area
}

mode.select = {
  'g<C-H>',              --   -  start Select block mode
  'gH',                    --   -  start Select line mode
  'gh',                    --   -  start Select mode
}

mode.replace = {
  -- ======================================================================
  -- commands that enter "replace" mode
  --
  'R',                     -- 2  enter replace mode: overtype existing characters, repeat the entered text N-1 times
  'gR',                    --   2  enter Virtual Replace mode
}

mode.insert = {
  -- ======================================================================
  -- commands that enter "insert" mode
  --
  '<Insert>',              -- 2  same as "i"
  'i',                     -- 2  insert text before the cursor N times
  'I',                     -- 2  insert text before the first CHAR on the line N times
  'a',                     -- 2  append text after the cursor N times
  'A',                     -- 2  append text after the end of the line N times
  'o',                     -- 2  begin a new line below the cursor and insert text, repeat N times
  'O',                     -- 2  begin a new line above the cursor and insert text, repeat N times

  'gI',                    -- 2  like "I", but always start in column 1
}

mode.change = {
  -- ======================================================================
  -- change = delete + insert
  --
  '{reg.get}C',                -- 2  change from the cursor position to the end of the line, and N-1 more lines [into register x]; synonym for "c$"
  '{reg.get}s',                -- 2  (substitute) delete N characters [into register x] and start insert
  '{reg.get}S',                -- 2  delete N lines [into register x] and start insert; synonym for "cc".

  '{reg.get}c{motion}',        -- 2  delete N-move text [into register x] and start insert
  '{reg.get}cc',               -- 2  delete N lines [into register x] and start insert
}

mode.search = {
  '/',                 -- 1  search forward for {pattern} of last search
  '?',                 -- 1  search backward for {pattern} of last search
}


-- ==============================================
-- Mouse / clicking commands
--
mouse.double = {
  '<2-LeftMouse>',         --    left double click
  '<2-RightMouse>',        --    left double click
  '<2-MiddleMouse>',       --    left double click
}

mouse.wheel = {
  '<ScrollWheelDown>',
  '<S-ScrollWheelDow>',
  '<ScrollWheelUp>',
  '<S-ScrollWheelUp>',
  '<ScrollWheelLeft>',
  '<S-ScrollWheelLeft>',
  '<ScrollWheelRight>',
  '<S-ScrollWheelRight>',
}

-- ==============================================
-- commands which MODIFY buffer
--
modify.undo = {
  -- ======================================================================
  -- undo/redo
  --
  '<C-R>',                 -- 2  redo changes which were undone with 'u'
  '<Undo>',                -- 2  same as "u"
  'U',                     -- 2  undo all latest changes on one line
  'u',                     -- 2  undo changes

  'g+',                    -- -  go to newer text state N times
  'g-',                    -- -  go to older text state N times

}

modify.diff = {
  'do',                    -- same as ":diffget"
  'dp',                    -- same as ":diffput"
}

modify.shift = {
  '<{motion}',             -- 2  shift N-move lines one 'shiftwidth' leftwards
  '<<',                    -- 2  shift N lines one 'shiftwidth' leftwards
  '>{motion}',             -- 2  shift N-move lines one 'shiftwidth' rightwards
  '>>',                    -- 2  shift N lines one 'shiftwidth' rightwards
}

modify.add = {
'<C-A>',                 -- 2  add N to number at/after cursor
'<C-X>',                 -- 2  subtract N from number at/after cursor
}

modify.case = {
  '~',                    --  2 'tildeop' off: switch case of N characters under cursor and move the cursor N characters to the right
  '~{motion}',            --    'tildeop' on: switch case of N-move text
  'g~{motion}',            -- 2  swap case for N-move text

  'gU{motion}',            -- 2  make N-move text uppercase
  'gu{motion}',            -- 2  make N-move text lowercase
}

modify.paste = {
  '{reg.put}P',              -- 2  put the text [from register x] before the cursor N times
  '{reg.put}p',              -- 2  put the text [from register x] after the cursor N times
  '{reg.put}gP',             -- 2  put the text [from register x] before the cursor N times, leave the cursor after it
  '{reg.put}gp',             -- 2  put the text [from register x] after the cursor N times, leave the cursor after it

  '<MiddleMouse>',         -- 2  same as "gP" at the mouse click position


  '[P',                    -- 2  same as "[p"
  ']P',                    -- 2  same as "[p"
  '[<MiddleMouse>',        -- 2  same as "[p"
  '[p',                    -- 2  like "P", but adjust indent to current line

  ']<MiddleMouse>',        -- 2  same as "]p"
  ']p',                    -- 2  like "p", but adjust indent to current line

  'zp',                    --    paste in block-mode without trailing spaces
  'zP',                    --    paste in block-mode without trailing spaces
}

modify.delete = {
  -- ======================================================================
  -- delete
  --
  '{reg.get}d{motion}',        -- 2  delete N-move text [into register x]
  '{reg.get}dd',               -- 2  delete N lines [into register x]
  '{reg.get}D',                -- 2  delete the characters under the cursor until the end of the line and N-1 more lines [into register x]; synonym for "d$"
  '{reg.get}X',                -- 2  delete N characters before the cursor [into register x]
  '{reg.get}x',                -- 2  delete N characters under and after the cursor [into register x]
  '{reg.get}<Del>',            -- 2  same as "x"
}

modify.replace = {
  'r{char}',               -- 2  replace N chars with {char}
  'gr{char}',              -- 2  virtual replace N chars with {char}
}

modify.uncategorized = {
  '&',                     -- 2  repeat last :s
  'g&',                    -- 2  repeat last ":s" on all lines

  '.',                     -- 2  repeat last change with count replaced with N

  'J',                     -- 2  Join N lines; default is 2
  'gJ',                    --   2  join lines without inserting space
}

modify.encode = {
  'g?',                    -- 2  Rot13 encoding operator
  'g??',                   -- 2  Rot13 encode current line
  'g?g?',                  -- 2  Rot13 encode current line
}

modify.format = {
  'gq{motion}',            --   2  format N-move text
  'gw{motion}',            --   2  format N-move text and keep cursor
}


-- ==============================================
-- MOVEMENT commands
--
move.cursor = {
  -- ======================================================================
  -- cursor movement
  --
  '{count}%',              -- 1  go to N percentage in the file

  '<LeftMouse>',           -- 1  cursor to the mouse click position
  '(',                     -- 1  cursor N sentences backward
  ')',                     -- 1  cursor N sentences forward
  '-',                     -- 1  cursor to the first CHAR N lines higher
  'B',                     -- 1  cursor N WORDS backward
  'E',                     -- 1  cursor forward to the end of WORD N
  'H',                     -- 1  cursor to line N from top of screen
  'L',                     -- 1  cursor to line N from bottom of screen
  'M',                     -- 1  cursor to middle line of screen
  'W',                     -- 1  cursor N WORDS forward
  '^',                     -- 1  cursor to the first CHAR of the line
  '_',                     -- 1  cursor to the first CHAR N - 1 lines lower
  'e',                     -- 1  cursor forward to the end of word N
  '{',                     -- 1  cursor N paragraphs backward
  '|',                     -- 1  cursor to column N
  '}',                     -- 1  cursor N paragraphs forward

  '<CR>',                  -- 1  cursor to the first CHAR N lines lower
  '<C-M>',                 -- 1  same as <CR>
  '+',                     -- 1  same as <CR>

  'G',                     -- 1  cursor to line N, default last line
  'b',                     -- 1  cursor N words backward
  'w',                     -- 1  cursor N words forward

  '<C-End>',               -- 1  same as "G"
  '<C-Home>',              -- 1  same as "gg"
  '<C-Right>',             -- 1  same as "w"
  '<S-Right>',             -- 1  same as "w"
  '<C-Left>',              -- 1  same as "b"
  '<S-Left>',              -- 1  same as "b"

  '$',                     -- 1  cursor to the end of Nth next line
  '0',                     -- 1  cursor to the first char of the line
  'l',                     -- 1  cursor N chars to the right
  'h',                     -- 1  cursor N chars to the left
  'j',                     -- 1  cursor N lines downward
  'k',                     -- 1  cursor N lines upward
  '<Space>',               -- 1  same as "l"

  '<End>',                 -- 1  same as "$"
  '<Home>',                -- 1  same as "0"
  '<Right>',               -- 1  same as "l"
  '<Left>',                -- 1  same as "h"
  '<BS>',                  -- 1  same as "h"
  '<C-H>',                 -- 1  same as "h"
  '<Down>',                -- 1  same as "j"
  '<NL>',                  -- 1  same as "j"
  '<C-J>',                 -- 1  same as "j"
  '<C-N>',                 -- 1  same as "j"
  '<C-P>',                 -- 1  same as "k"
  '<Up>',                  -- 1  same as "k"

  'f{char}',               -- 1  cursor to Nth occurrence of {char} to the right
  'F{char}',               -- 1  cursor to the Nth occurrence of {char} to the left
  't{char}',               -- 1  cursor till before Nth occurrence of {char} to the right
  'T{char}',               -- 1  cursor till after Nth occurrence of {char} to the left

  ',',                     -- 1  repeat latest f, t, F or T in opposite direction N times
  ';',                     -- 1  repeat latest f, t, F or T N times
-- ============================================================================
  "'{mark}",               -- 1  cursor to the first CHAR on the line with mark {a-zA-Z0-9}
  '`{mark}',               -- 1  cursor to the mark {a-zA-Z0-9}
  "g'{mark}",             -- 1  like "'" but without changing the jumplist
  'g`{mark}',              -- 1  like "`" but without changing the jumplist

  "''",                    -- 1  cursor to the first CHAR of the line where the cursor was before the latest jump.
  "'(",                    -- 1  cursor to the first CHAR on the line of the start of the current sentence
  "')",                    -- 1  cursor to the first CHAR on the line of the end of the current sentence
  "'<",                    -- 1  cursor to the first CHAR of the line where highlighted area starts/started in the current buffer.
  "'>",                    -- 1  cursor to the first CHAR of the line where highlighted area ends/ended in the current buffer.
  "'[",                    -- 1  cursor to the first CHAR on the line of the start of last operated text or start of put text
  "']",                    -- 1  cursor to the first CHAR on the line of the end of last operated text or end of put text
  "'{",                    -- 1  cursor to the first CHAR on the line of the start of the current paragraph
  "'}",                    -- 1  cursor to the first CHAR on the line of the end of the current paragraph


  '`(',                    -- 1  cursor to the start of the current sentence
  '`)',                    -- 1  cursor to the end of the current sentence
  '`<',                    -- 1  cursor to the start of the highlighted area
  '`>',                    -- 1  cursor to the end of the highlighted area
  '`[',                    -- 1  cursor to the start of last operated text or start of putted text
  '`]',                    -- 1  cursor to the end of last operated text or end of putted text
  '``',                    -- 1  cursor to the position before latest jump
  '`{',                    -- 1  cursor to the start of the current paragraph
  '`}',                    -- 1  cursor to the end of the current paragraph
-- ============================================================================
  '[<C-D>',                -- -  jump to first #define found in current and included files matching the word under the cursor, start searching at beginning of current file
  '[<C-I>',                -- -  jump to first line in current and included files that contains the word under the cursor, start searching at beginning of current file
  ']<C-D>',                -- -  jump to first #define found in current and included files matching the word under the cursor, start searching at cursor position
  ']<C-I>',                -- -  jump to first line in current and included files that contains the word under the cursor, start searching at cursor position

  '[#',                    -- 1  cursor to N previous unmatched #if, #else or #ifdef
  '[(',                    -- 1  cursor N times back to unmatched '('
  "['",                    -- 1  cursor to previous lowercase mark, on first non-blank
  '[`',                    -- 1  cursor to previous lowercase mark
  '[*',                    -- 1  same as "[/"
  '[/',                    -- 1  cursor to N previous start of a C comment
  '[[',                    -- 1  cursor N sections backward
  '[]',                    -- 1  cursor N SECTIONS backward
  '[c',                    -- 1  cursor N times backwards to start of change
  '[m',                    -- 1  cursor N times back to start of member function
  '[{',                    -- 1  cursor N times back to unmatched '{'
  ']#',                    -- 1  cursor to N next unmatched #endif or #else
  '])',                    -- 1  cursor N times forward to unmatched ')'
  "]'",                    -- 1  cursor to next lowercase mark, on first non-blank
  ']`',                    -- 1  cursor to next lowercase mark
  ']*',                    -- 1  same as "]/"
  ']/',                    -- 1  cursor to N next end of a C comment
  '][',                    -- 1  cursor N SECTIONS forward
  ']]',                    -- 1  cursor N sections forward
  ']c',                    -- 1  cursor N times forward to start of change
  ']}',                    -- 1  cursor N times forward to unmatched '}'
  ']m',                    -- 1  cursor N times forward to end of member function
-- ============================================================================
  'g$',                    -- 1  when 'wrap' off go to rightmost character of the current line that is on the screen; when 'wrap' on go to the rightmost character of the current screen line
  'g0',                    -- 1  when 'wrap' off go to leftmost character of the current line that is on the screen; when 'wrap' on go to the leftmost character of the current screen line
  'g^',                    -- 1  when 'wrap' off go to leftmost non-white character of the current line that is on the screen; when 'wrap' on go to the leftmost non-white character of the current screen line

  'g<End>',                -- 1  same as "g$"
  'g<Home>',               -- 1  same as "g0"

  'g<Down>',               -- 1  same as "gj"
  'g<Up>',                 -- 1  same as "gk"

  'gi',                    -- 2  like "i", but first move to the '^ mark
  'gj',                    -- 1  like "j", but when 'wrap' on go N screen lines down
  'gk',                    -- 1  like "k", but when 'wrap' on go N screen lines up

  'gE',                    -- 1  go backwards to the end of the previous WORD
  'ge',                    -- 1  go backwards to the end of the previous word

  'g_',                    -- 1  cursor to the last CHAR N - 1 lines lower
  'go',                    -- 1  cursor to byte N in the buffer

  'gm',                    -- 1  go to character at middle of the screenline
  'gM',                    -- 1  go to character at middle of the text line

  'gg',                    -- 1  cursor to line N, default first line
  'g,',                    -- 1  go to N newer position in change list
  'g;',                    -- 1  go to N older position in change list

  'gD',                    --   1  go to definition of word under the cursor in current file
  'gd',                    --   1  go to definition of word under the cursor in current function
-- ============================================================================
  'z+',                    --    cursor on line N (default line below window), otherwise like "z<CR>"
  'z^',                    --    cursor on line N (default line above window), otherwise like "z-"
-- ============================================================================
  folding.move,
  spell.move,
}

move.search = {
  -- ======================================================================
  -- search
  --
  '#',                     -- 1  search backward for the Nth occurrence of the ident under the cursor
  '*',                     -- 1  search forward  for the Nth occurrence of the ident under the cursor

  'g#',                    -- 1  like "#", but without using "\<" and "\>"
  'g*',                    -- 1  like "*", but without using "\<" and "\>"

  '<S-LeftMouse>',         --    same as "*" at the mouse click position
  '<S-RightMouse>',        --    same as "#" at the mouse click position

  'n',                     -- 1  repeat the latest '/' or '?' N times
  'N',                     -- 1  repeat the latest '/' or '?' N times in opposite direction


  '%',                     -- 1  find the next (curly/square) bracket on
}

move.jumps = {
  -- ======================================================================
  -- jumps
  --
  '<Tab>',                 -- 1  go to N newer entry in jump list
  '<C-O>',                 -- 1  go to N older entry in jump list
  '<C-I>',                 -- 1  same as <Tab>

}

move.tags = {
  -- ======================================================================
  -- jumps to tags
  --
  '<C-T>',                 --    jump to N older Tag in tag list
  '<C-]>',                 --    :ta to ident under cursor

  '<C-RightMouse>',        --    same as "CTRL-T"
  '<C-LeftMouse>',         --    :ta to the keyword at the mouse click

  'g<RightMouse>',         --    same as <CTRL-RightMouse>
  'g<LeftMouse>',          --    same as <CTRL-LeftMouse>

  '<C-W>g<C-]>',              --    :tjump to the tag under the cursor

  'g]',                    --    :tselect on the tag under the cursor

  '<C-W>g}',               --    do a :ptjump to the tag under the cursor
}


-- ==============================================
-- TABS commands
--
M.tabs = {
  -- ======================================================================
  -- tabs
  --
  'gt',                    --   -  go to the next tab page
  'gT',                    --   -  go to the previous tab page
  'g<Tab>',                --   -  go to last accessed tab page

  '<C-Tab>',               --   -  same as "g<Tab>"

  '<C-W>gt',               --   -  same as gt: go to next tab page
  '<C-W>gT',               --   -  same as gT: go to previous tab page
  '<C-W>g<Tab>',           --   -  same as g<Tab>: go to last accessed tab page

  '<C-W>T',                --    move current window to a new tab page
}


-- ==============================================
-- WINDOWS commands
--
windows.same_as = {
  '<C-W><C-B>',            --   same as "CTRL-W b"
  '<C-W><C-C>',            --   same as "CTRL-W c"
  '<C-W><C-D>',            --   same as "CTRL-W d"
  '<C-W><C-F>',            --   same as "CTRL-W f"
  '<C-W><C-G>',            --   same as "CTRL-W g .."
  '<C-W><C-H>',            --   same as "CTRL-W h"
  '<C-W><C-I>',            --   same as "CTRL-W i"
  '<C-W><C-J>',            --   same as "CTRL-W j"
  '<C-W><C-K>',            --   same as "CTRL-W k"
  '<C-W><C-L>',            --   same as "CTRL-W l"
  '<C-W><C-N>',            --   same as "CTRL-W n"
  '<C-W><C-O>',            --   same as "CTRL-W o"
  '<C-W><C-P>',            --   same as "CTRL-W p"
  '<C-W><C-Q>',            --   same as "CTRL-W q"
  '<C-W><C-R>',            --   same as "CTRL-W r"
  '<C-W><C-S>',            --   same as "CTRL-W s"
  '<C-W><C-T>',            --   same as "CTRL-W t"
  '<C-W><C-V>',            --   same as "CTRL-W v"
  '<C-W><C-W>',            --   same as "CTRL-W w"
  '<C-W><C-X>',            --   same as "CTRL-W x"
  '<C-W><C-Z>',            --   same as "CTRL-W z"
  '<C-W><C-]>',            --   same as "CTRL-W ]"
  '<C-W><C-^>',            --   same as "CTRL-W ^"
  '<C-W><C-_>',            --   same as "CTRL-W _"
}

windows.jump_to = {
  '<C-W>b',                --    go to bottom window
  '<C-W>t',                --    Go to top window
  '<C-W><C-B>',            --    same as "CTRL-W b"
  '<C-W><C-T>',            --    same as "CTRL-W t"

  '<C-W>h',                --    Go to Nth left window (stop at first window)
  '<C-W>j',                --    Go N windows down (stop at last window)
  '<C-W>k',                --    Go N windows up (stop at first window)
  '<C-W>l',                --    Go to Nth right window (stop at last window)

  '<C-W><C-H>',            --    same as "CTRL-W h"
  '<C-W><C-J>',            --    same as "CTRL-W j"
  '<C-W><C-K>',            --    same as "CTRL-W k"
  '<C-W><C-L>',            --    same as "CTRL-W l"

  '<C-W><Down>',           --    same as "CTRL-W j"
  '<C-W><Up>',             --    same as "CTRL-W k"
  '<C-W><Left>',           --    same as "CTRL-W h"
  '<C-W><Right>',          --    same as "CTRL-W l"


  '<C-W>p',                --    Go to previous (last accessed) window
  '<C-W>w',                --    Go to N next window (wrap around)
  '<C-W>W',                --    go to N previous window (wrap around)
  '<C-W><C-P>',            --    same as "CTRL-W p"
  '<C-W><C-W>',            --    same as "CTRL-W w"
}

windows.preview = {
  '<C-W>P',                --    go to preview window
  '<C-W>z',                --    Close preview window
  '<C-W>}',                --    Show tag under cursor in preview window
  '<C-W><C-Z>',            --    same as "CTRL-W z"
}

windows.reorder = {
  '<C-W>H',                --    move current window to the far left
  '<C-W>J',                --    move current window to the very bottom
  '<C-W>K',                --    move current window to the very top
  '<C-W>L',                --    move current window to the far right

  '<C-W>R',                --    rotate windows upwards N times
  '<C-W>r',                --    Rotate windows downwards N times
  '<C-W>T',                --    move current window to a new tab page
  '<C-W><C-R>',            --    same as "CTRL-W r"

  '<C-W>x',                --    Exchange current window with window N (default: next window)
  '<C-W><C-X>',            --    same as "CTRL-W x"
}

windows.resize = {
  '<C-W>+',                --    increase current window height N lines
  '<C-W>-',                --    decrease current window height N lines

  '<C-W><',                --    decrease current window width N columns
  '<C-W>>',                --    increase current window width N columns

  '<C-W>=',                --    make all windows the same height & width

  '<C-W>_',                --    set current window height to N (default: very high)
  '<C-W><C-_>',            --    same as "CTRL-W _"

  '<C-W>|',                --    Set window width to N columns
}

windows.close = {
  'ZZ',                    --    write if buffer changed and close window
  'ZQ',                    --    close window without writing

  '<C-W>c',                --    close current window (like :close)
  '<C-W>q',                --    Quit current window (like :quit)
  '<C-W>o',                --    Close all but current window (like :only)
  '<C-W><C-C>',            --    same as "CTRL-W c"
  '<C-W><C-Q>',            --    same as "CTRL-W q"
  '<C-W><C-O>',            --    same as "CTRL-W o"
}

windows.open = {
  '<C-W>n',                --    Open new window, N lines high
}

windows.split = {
  '<C-W>f',                --    split window and edit file name under the cursor
  '<C-W>F',                --    split window and edit file name under the cursor and jump to the line number following the file name.
  '<C-W><C-F>',            --    same as "CTRL-W f"

  '<C-W>]',                --    split window and jump to tag under cursor
  '<C-W>d',                --    split window and jump to definition under the cursor
  '<C-W>i',                --    Split window and jump to declaration of identifier under the cursor
  '<C-W><C-]>',            --    same as "CTRL-W ]"
  '<C-W><C-D>',            --    same as "CTRL-W d"
  '<C-W><C-I>',            --    same as "CTRL-W i"

  '<C-W>g<C-]>',           --    split window and do :tjump to tag under cursor
  '<C-W>g]',               --    split window and do :tselect for tag under cursor

  '<C-W>^',                --    split current window and edit alternate file N
  '<C-W><C-^>',            --    same as "CTRL-W ^"

  '<C-W>s',                --    Split current window in two parts, new window N lines high
  '<C-W>v',                --    Split current window vertically, new window N columns wide
  '<C-W>S',                --    same as "CTRL-W s"
  '<C-W><C-S>',            --    same as "CTRL-W s"
  '<C-W><C-V>',            --    same as "CTRL-W v"
  '<C-W><C-N>',            --    same as "CTRL-W n"
}


-- ==============================================
-- LAYOUT commands
--
layout.tabs = M.tabs
layout.windows = windows

-- ==============================================
-- SCROLL commands
--

scroll.vertical = {
  -- ======================================================================
  -- scrolling
  --
  '<C-F>',                 -- 1  scroll N screens Forward
  '<C-B>',                 -- 1  scroll N screens Backwards

  '<C-E>',                 --    scroll N lines upwards   (N lines Extra)
  '<C-Y>',                 --    scroll N lines downwards (N lines Extra)

  '<C-D>',                 --    scroll Down N lines (default: half a screen)
  '<C-U>',                 --    scroll Up N lines   (default: half a screen)

  '<PageDown>',            --    same as CTRL-F
  '<S-Down>',              -- 1  same as CTRL-F

  '<PageUp>',              --    same as CTRL-B
  '<S-Up>',                -- 1  same as CTRL-B
}

scroll.redraw = {
  'z<CR>',                 --    redraw, cursor line to top of window, cursor on first non-blank
  'z-',                    --    redraw, cursor line at bottom of window, cursor on first non-blank
  'z.',                    --    redraw, cursor line to center of window, cursor on first non-blank

  'zt',                    --    redraw, cursor line at top of window
  'zz',                    --    redraw, cursor line at center of window
  'zb',                    --    redraw, cursor line at bottom of window

  'z{height}<CR>',         --    redraw, make window {height} lines high
}

scroll.horizontal = {
  'zH',                    --    when 'wrap' off scroll half a screenwidth to the right
  'zL',                    --    when 'wrap' off scroll half a screenwidth to the left

  'zh',                    --    when 'wrap' off scroll screen N characters to the right
  'zl',                    --    when 'wrap' off scroll screen N characters to the left

  'z<Left>',               --    same as "zh"
  'z<Right>',              --    same as "zl"


  'ze',                    --    when 'wrap' off scroll horizontally to position the cursor at the end (right side) of the screen
  'zs',                    --    when 'wrap' off scroll horizontally to position the cursor at the start (left side) of the screen
}


-- ==============================================
-- FOLDS commands
--
folding.move = {
  '[z',                    -- 1  move to start of open fold
  ']z',                    -- 1  move to end of open fold
  'zj',                    -- 1  move to the start of the next fold
  'zk',                    -- 1  move to the end of the previous fold
}

folding.open = {
  'zo',                    --    open fold
  'zO',                    --    open folds recursively
}

folding.close = {
  'zC',                    --    close folds recursively
  'zc',                    --    close a fold
  'zv',                    --    open enough folds to view the cursor line
}

folding.toggle = {
  'zA',                    --    open a closed fold or close an open fold recursively
  'za',                    --    open a closed fold, close an open fold
}

folding.enable = {
  'zn',                    --    reset 'foldenable'
  'zN',                    --    set 'foldenable'
  'zi',                    --    toggle 'foldenable'
}

folding.level = {
  'zM',                    --    set 'foldlevel' to zero
  'zR',                    --    set 'foldlevel' to the deepest fold

  'zm',                    --    subtract one from 'foldlevel'
  'zr',                    --    add one to 'foldlevel'

  'zX',                    --    re-apply 'foldlevel'
  'zx',                    --    re-apply 'foldlevel' and do "zv"
}

folding.create = {
  -- only if foldmethod is "manual"
  --
  'zF',                    --    create a fold for N lines
  'zf{motion}',            --    create a fold for N-move text
}

folding.delete = {
  -- only if foldmethod is "manual"
  --
  'zE',                    --    eliminate all folds
  'zD',                    --    delete folds recursively
  'zd',                    --    delete a fold
}


-- ==============================================
-- SPELLING commands
--
spell.move = {
  '[s',                    -- 1  move to previous misspelled word
  ']s',                    -- 1  move to next misspelled word
}

spell.mark = {
  'zG',                    --    temporarily mark word as correctly spelled
  'zW',                    --    temporarily mark word as incorrectly spelled
  'zuW',                   --    undo zW
  'zuG',                   --    undo zG

  'zg',                    --    permanently mark word as correctly spelled
  'zw',                    --    permanently mark word as incorrectly spelled
  'zuw',                   --    undo zw
  'zug',                   --    undo zg
}

spell.suggest = {
  'z=',                    --    give spelling suggestions
}


-- ==============================================
-- YANK commands
--
M.yank = {
  -- ======================================================================
  -- yanking/pasting commands
  --
  '{reg.get}Y',                --    yank N lines [into register x]; synonym for "yy" Note: Mapped to "y$" by default. default-mappings
  '{reg.get}y{motion}',        --    yank N-move text [into register x]
  '{reg.get}yy',               --    yank N lines [into register x]

  'zy',                      --    yank without trailing spaces                
}


-- ==============================================
-- commands which DISPLAYS data/info
--
present.list = {
  '[D',                    -- -  list all defines found in current and included files matching the word under the cursor, start searching at beginning of current file
  '[I',                    -- -  list all lines found in current and included files that contain the word under the cursor, start searching at beginning of current file
  ']D',                    -- -  list all #defines found in current and included files matching the word under the cursor, start searching at cursor position
  ']I',                    -- -  list all lines found in current and included files that contain the word under the cursor, start searching at cursor position
}

present.show = {
  '[d',                    -- show first #define found in current and included files matching the word under the cursor, start searching at beginning of current file
  '[i',                    -- show first line found in current and included files that contains the word under the cursor, start searching at beginning of current file
  ']d',                    -- show first #define found in current and included files matching the word under the cursor, start searching at cursor position
  ']i',                    -- show first line found in current and included files that contains the word under the cursor, start searching at cursor position

  'g<C-A>',                -- dump a memory profile
  'g<C-G>',                -- show information about current cursor position
  '<C-G>',                 -- display current file name and position
  'g8',                    -- print hex value of bytes used in UTF-8 character under the cursor
  'ga',                    -- print ascii value of character under the cursor
  'g<',                    -- display previous command output

  'K',                     -- lookup Keyword under the cursor with 'keywordprg'
}


-- ==============================================
-- BUFFER commands
--
buffers.open = {
  '[f',                    --   same as "gf"
  ']f',                    --   same as "gf"
  'gf',                    --   start editing the file whose name is under the cursor
  'gF',                    --   start editing the file whose name is under 'the cursor and jump to the line number 'following the filename.

  '<C-W>gf',               --   edit file name under the cursor in a new tab page
  '<C-W>gF',               --   edit file name under the cursor in a new tab page and jump to the line number following the file name.
}

buffers.write = {
  'ZZ',                    --    write if buffer changed and close window
}


M = native.filter(M)

native.combos(native.flatten(M))

return M
