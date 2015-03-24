
```
start gvim --servername BEAD
FOR /R %%i IN (word list *.lrc) DO gvim --servername BEAD --remote-silent "%%i"
gvim --servername BEAD --remote-send "<Esc>:bufdo! %%s/\[.*\]//ge<CR>"
REM gvim --servername BEAD --remote-send "<Esc>:bufdo! %%s/\(^File:.*JPG\).*/\1/ge<CR>"
rem Write all files and exit
gvim --servername BEAD --remote-send "<Esc>:xall<CR>"
```