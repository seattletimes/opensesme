# OpenSESME
### v0.1.0 - 2016-03-25

#####NAME

opensesme.sh - a spooler module to watch for files to appear, then trigger actions on them

#####SYNOPSIS

openseseme.sh [OPTION]...

#####DESCRIPTION

OpenSESME is a replacement for the original Simple Extensible Spooler Module (SESME) by Guy Bushnell and Alan Moore.

At its core, OpenSESME is a realtively simple program for moving files from one place to another, utilizing inotifywait with simple bash scripting. 

There's error-checking, logging of actions and errors, support for configuration files, and (soon) support for modifying files.

At present, OpenSESME looks for (`*.conf`) config files in `/etc/opensesme.d/` (changeable via the `$CONFIG_DIR` variable) that contain the following variables:

- `ENABLED` - Boolean to indicate whether or not the config is to be used
- `ACTION_NAME` - A unique name for the config/action being performed
- `INPUT_DIR` - Where OpenSESME will watch for files to appear
- `ARCHIVE` - Boolean to indicate whether or not a 'clean' copy of the file is to be archived
- `ARCHIVE_DIR` - Where OpenSESME will place unaltered copies of incoming files if `ARCHIVE` is `true`
- `MODIFY` - Boolean to indicate whether or not the file is to be modified (i.e. `sed`, `tr`, etc)
- `OUTPUT_DIR` - Destination for moved files

There is also a `$LOGFILE` variable that is set to `/var/log/opensesme.log` by default.

There is a function `configcheck` that is used to do a (currently very basic) check on requested config files.


#####OPTIONS
`-c [filename]` 
	use the `configcheck` function to check the given configuration file, then exit 

`-f [filename]` 
	run opensesme with the given configuration file, then exit


#####PLANNED IMPROVEMENTS

- Support for `PERFORM` - to specify modifications to be performed to a file (i.e. `sed`, `tr`, etc) if `MODIFY` is `true`
- Support for `TARGET` - to specify filenames to look for
- Support for process tracking - linking PIDs with Action Names, for starting, status, and stopping via a control script, preventing multiple instances of the same action, etc

*Thanks to Orville Broadbeak, Skyler Bunny, and Yaro Kasear for their help with and contributions to this project.*