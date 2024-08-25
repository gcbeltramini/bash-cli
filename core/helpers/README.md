# Helper files

This folder contains all helper files, which are likely used by many commands in the `commands`
folder. These helper files are `source`'d by the file `helpers.sh`, which is `source`'d by the
commands.

We suggest to `source` only the file `helpers.sh` in the files in the `commands` folder, and avoid
running `source` for these helpers individually there. If there are helper functions that will be
used only be a specific command, the helper file can be created inside the command folder instead of
here.
