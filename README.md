# OpenSESME
### v0.0.8

OpenSESME is a replacement for the original Simple Extensible Spooler Module (SESME) by Guy Bushnell and Alan Moore.

At present, OpenSESME looks for config files that contain the following variables:
```
ACTION_NAME
INPUT_DIR
ARCHIVE_DIR
OUTPUT_DIR
```
Planned improvements: 
- Support for `TARGET` - to specify filenames to look for
- Support for starting opensesme with flags to specify single configs, etc
- Support for process tracking - linking PIDs with Action Names, for starting and stopping via a control script

*Thanks to Orville Broadbeak, Skyler Bunny, and @YaroKasear for help with this project.*