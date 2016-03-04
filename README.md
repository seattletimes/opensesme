# OpenSESME
### v0.0.8

OpenSESME is a replacement for the original Simple Extensible Spooler Module (SESME) by Guy Bushnell and Alan Moore.

At its core, OpenSESME is a realtively simple program for moving files from one place to another. There's error-checking, logging of actions and errors, support for configuration files, and (soon) support for modifying files.

At present, OpenSESME looks for config files that contain the following variables:

- `ACTION_NAME` - A unique name for the config/action being performed
- `INPUT_DIR` - Where OpenSESME will watch for files to appear
- `ARCHIVE_DIR` - Where OpenSESME will place unaltered copies of incoming files
- `OUTPUT_DIR` - Destination for moved files

Planned improvements: 
- Support for `PERFORM` - to specify modifications to be performed to a file (i.e. `sed`, `tr`, etc)
- Support for `TARGET` - to specify filenames to look for
- Support for starting opensesme with flags to specify single configs, etc
- Support for process tracking - linking PIDs with Action Names, for starting and stopping via a control script

*Thanks to Orville Broadbeak, Skyler Bunny, and Yaro Kasear for help with this project.*