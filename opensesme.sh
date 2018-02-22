#!/bin/bash
# OpenSESME v0.4.2 - "Regret is the father of invention."
# https://github.com/seattletimes/opensesme
# E. A. Griffon - 2018-01-03
# Thanks to StackExchange, Yaro Kasear, Orville Broadbeak, and Skyler Bunny

# Define where configurations are held
CONFIG_DIR=/etc/opensesme.d/

# Define where to log to
LOGFILE=/var/log/opensesme.log

# Set our incrementalizers to 0
# Error count
i=0
# Run count
r=0
# Debug level
d=0

# Make a function to be called to check config files
# This needs to be fleshed out more to check for malformed paths, invalid characters, etc
# 2017-10-25 - Like a year and a half later I'm looking at it and it hurts my eyes

configcheck ()
{
        # Check config for ENABLED statement
        if ! grep --quiet "ENABLED\=" $1; then
                echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 is missing ENABLED statement - config invalid!"
                ((i++))
        elif [[ ! "$ENABLED" == "true" ]] && [[ ! "$ENABLED" == "false" ]]; then
                echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 has ENABLED set to something other than 'true' or 'false' - config invalid!"
                ((i++))
        fi

        # Check config for Input Directory statement
        if ! grep --quiet "INPUT_DIR\=" $1; then
                echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 is missing INPUT_DIR statement - config invalid!"
                ((i++))
        elif ! grep --quiet "INPUT_DIR\=\/" $1; then
                echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 has a malformed INPUT_DIR directory path (not absolute/does not start with /)"
                ((i++))
        fi

        # Check for presence of Input Directory
        if [[ ! -d "$INPUT_DIR" ]]; then
                echo >> $LOGFILE "`date -Is` OpenSESME: Input Directory $INPUT_DIR doesn't seem to exist - config invalid!"
                ((i++))
        fi

        # Check config for Archive, Archive Directory, and Archive Filename statements
        if ! grep --quiet "ARCHIVE\=" $1; then
                echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 is missing ARCHIVE statement - config invalid!"
                ((i++))
        elif [[ ! "$ARCHIVE" == "true" ]] && [[ ! "$ARCHIVE" == "false" ]]; then
                echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 has ARCHIVE set to something other than 'true' or 'false' - config invalid!"
                ((i++))
        elif [[ "$ARCHIVE" == "true" ]] && [[ ! "$RECURSIVE" == "true" ]] && ! grep --quiet "ARCHIVE_DIR\=" $1; then
                echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 has ARCHIVE set true but is missing ARCHIVE_DIR - config invalid!"
                ((i++))
        elif [[ "$ARCHIVE" == "true" ]] && [[ ! "$RECURSIVE" == "true" ]] && ! grep --quiet "ARCHIVE_DIR\=\/" $1; then
                echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 has a malformed ARCHIVE_DIR directory path (not absolute/does not start with /)"
                ((i++))
        elif [[ "$ARCHIVE" == "true" ]] && [[ ! "$RECURSIVE" == "true" ]] && ! grep --quiet "ARCHIVE_FILENAME\=" $1; then
                echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 has ARCHIVE set true but is missing ARCHIVE_FILENAME - config invalid!"
                ((i++))
        fi

        # Check for Modify and Perform statements
        if ! grep --quiet "MODIFY\=" $1; then
                echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 is missing MODIFY statement - config invalid!"
                ((i++))
        elif [[ ! "$MODIFY" == "true" ]] && [[ ! "$MODIFY" == "false" ]]; then
                echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 has MODIFY set to something other than 'true' or 'false' - config invalid!"
                ((i++))
        elif [[ "$MODIFY" == "true" ]] && ! grep --quiet "PERFORM\=" $1; then
                echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 has MODIFY set true, but is missing PERFORM statement - config invalid!"
                ((i++))
        fi

        # Check for Output Directory statement
        if ! grep --quiet "OUTPUT_DIR\=" $1; then
                echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 is missing OUTPUT_DIR statement - config invalid!"
                ((i++))
        elif ! grep --quiet "OUTPUT_DIR\=\/" $1; then
                echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 has a malformed OUTPUT_DIR directory path (not absolute/does not start with /)"
                ((i++))
        fi

        # Check for File Name statement
        if ! grep --quiet "FILENAME\=" $1; then
                echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 is missing FILENAME statement - config invalid!"
                ((i++))
        fi

        if [[ ! $i -eq 0 ]]; then
                echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 has $i errors."
                exit 1
        else
                echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 has $i errors."
        fi

}

# A function used to archive a file with parameters from a sourced conf file
# Called in the runconfig function
archive ()
{
        # If a datestamp is wanted, do that - and if the ARCHIVE_FILENAME is blank, use $file as the name.
        if [[ $ARCHIVE_DATESTAMP == "true" ]]; then
                if [[ -z "$ARCHIVE_FILENAME" ]]; then
                        WORKING_ARCHIVE_FILENAME=`date +%Y%m%d_%H%M%S`_$file
                else
                        WORKING_ARCHIVE_FILENAME=`date +%Y%m%d_%H%M%S`_$ARCHIVE_FILENAME
                fi
        else
                if [[ -z "$ARCHIVE_FILENAME" ]]; then
                        WORKING_ARCHIVE_FILENAME=$file
                else
                        WORKING_ARCHIVE_FILENAME=$ARCHIVE_FILENAME
                fi
        fi

        # Do the actual archiving with this cool kludged together string
        # Oh man this hurts
        # I'm sorry, and I take full responsibility
        # -Eris A Griffon
        cp $path/$file $ARCHIVE_DIR/$WORKING_ARCHIVE_FILENAME && chown $OWNER.$GROUP $ARCHIVE_DIR/$WORKING_ARCHIVE_FILENAME && chmod $PERMS $ARCHIVE_DIR/$WORKING_ARCHIVE_FILENAME || (echo >> $LOGFILE "`date -Is` $ACTION_NAME: archival copy has failed for $path/$file to $ARCHIVE_DIR/$WORKING_ARCHIVE_FILENAME"; logger -p local2.notice -t OpenSESME -- $ACTION_NAME: archival copy has failed for $path/$file to $ARCHIVE_DIR/$WORKING_ARCHIVE_FILENAME)

        # Test to see if archive file is not actually there, and if it isn't, log errors
        if [[ ! -e "$ARCHIVE_DIR/$WORKING_ARCHIVE_FILENAME" ]]; then
                echo >> $LOGFILE "`date -Is` $ACTION_NAME: File check has failed for presence of archived file $ARCHIVE_DIR/$WORKING_ARCHIVE_FILENAME"
                logger -p local2.notice -t OpenSESME -- $ACTION_NAME: File check has failed for presence of archived file $ARCHIVE_DIR/$WORKING_ARCHIVE_FILENAME
        else
                # "Log" the events
                echo >> $LOGFILE "`date -Is` $ACTION_NAME: Archived $file from $path to $ARCHIVE_DIR/$WORKING_ARCHIVE_FILENAME"
        fi
}

# For when inotifywait is used recursively ($RECURSIVE == true)
# A function used to archive a file with parameters from a sourced conf file
# Called in the runconfig function
archive_recursive ()
{
        # Define WORKING_ARCHIVE_FILENAME as the archive filename with timestamp, if requested
        if [[ $ARCHIVE_DATESTAMP == true ]]; then
                WORKING_ARCHIVE_FILENAME=`date +%Y%m%d_%H%M%S`_$file
        else
                WORKING_ARCHIVE_FILENAME=$file
        fi

        # It's bad here too. Sorry again. - Eris
        cp $path/$file $path/$ARCHIVE_DIR/$WORKING_ARCHIVE_FILENAME && chown $OWNER.$GROUP $path/$ARCHIVE_DIR/$WORKING_ARCHIVE_FILENAME && chmod $PERMS $path/$ARCHIVE_DIR/$WORKING_ARCHIVE_FILENAME || (echo >> $LOGFILE "`date -Is` $ACTION_NAME: archival copy has failed for $path/$file to $path/$ARCHIVE_DIR/$WORKING_ARCHIVE_FILENAME"; logger -p local2.notice -t OpenSESME -- $ACTION_NAME: archival copy has failed for $path/$file to $path/$ARCHIVE_DIR/$WORKING_ARCHIVE_FILENAME)

        # Test to see if archive file is not actually there, and if it isn't, log errors
        if [[ ! -e "$path/$ARCHIVE_DIR/$WORKING_ARCHIVE_FILENAME" ]]; then
                echo >> $LOGFILE "`date -Is` $ACTION_NAME: File check has failed for presence of archived file $path/$ARCHIVE_DIR/$WORKING_ARCHIVE_FILENAME"
                logger -p local2.notice -t OpenSESME -- $ACTION_NAME: File check has failed for presence of archived file $path/$ARCHIVE_DIR/$WORKING_ARCHIVE_FILENAME
        else
                # "Log" the events
                echo >> $LOGFILE "`date -Is` $ACTION_NAME: Archived $file from $path to $path/$ARCHIVE_DIR/$WORKING_ARCHIVE_FILENAME"
        fi
}

# A function to modify a file with parameters passed from a sourced conf file
# Called in the runconfig function
modify ()
{
        # Define TEMPFILE as the filename with _tmp extension
        TEMPFILE=$file\_tmp

        # Move the file to /tmp for modification
        echo >> $LOGFILE "`date -Is` $ACTION_NAME: Moving $path/$file to temporary directory for modification"
        mv $path/$file /tmp/$TEMPFILE || (echo >> $LOGFILE "`date -Is` $ACTION_NAME: mv has failed for $path/$file to /tmp/$TEMPFILE"; logger -p local2.notice -t OpenSESME -- $ACTION_NAME: mv has failed for $path/$file to /tmp/$TEMPFILE)

        # Perform the modification
        echo >> $LOGFILE "`date -Is` $ACTION_NAME: Performing $PERFORM on /tmp/$TEMPFILE"
        $PERFORM /tmp/$TEMPFILE ||(echo >> $LOGFILE "`date -Is` $ACTION_NAME: Execution of $PERFORM has failed on /tmp/$TEMPFILE"; logger -p local2.notice -t OpenSESME -- $ACTION_NAME: Execution of $PERFORM has failed on /tmp/$TEMPFILE)

        # Move the modified file to the output directory
        echo >> $LOGFILE "`date -Is` $ACTION_NAME: Moving /tmp/$TEMPFILE to $OUTPUT_DIR as $WORKING_FILENAME"
        mv /tmp/$TEMPFILE $OUTPUT_DIR/$WORKING_FILENAME && chown $OWNER.$GROUP $OUTPUT_DIR/$WORKING_FILENAME && chmod $PERMS $OUTPUT_DIR/$WORKING_FILENAME || (echo >> $LOGFILE "`date -Is` $ACTION_NAME: mv has failed for /tmp/$TEMPFILE to $OUTPUT_DIR/$WORKING_FILENAME"; logger -p local2.notice -t OpenSESME -- $ACTION_NAME: mv has failed for /tmp/$TEMPFILE to $OUTPUT_DIR/$WORKING_FILENAME)
        }

# A function to unset variables
unset_vars ()
{
        unset ENABLED
        unset ACTION_NAME
        unset MODIFY
        unset ARCHIVE
        unset ARCHIVE_DIR
        unset ARCHIVE_FILENAME
        unset ARCHIVE_DATESTAMP
        unset INPUT_DIR
        unset TARGET
        unset PERFORM
        unset OUTPUT_DIR
        unset FILENAME
        unset OWNER
        unset GROUP
        unset PERMS
        unset DATESTAMP
        unset RECURSIVE
        unset EXCLUDE_DIR
        unset EXCLUDE_FILE
        unset INO
}

# Main function to run a given CONF file
runconfig ()
{

        # First, unset any variables that may be lingering from a previous run/config file
        unset_vars

        echo -e "Reading $CONF"

        echo >> $LOGFILE "`date -Is` OpenSESME Main: Reading $CONF"

        source $CONF

        # Use function to check config file
        configcheck $CONF

        # Exit if the config is disabled
        if [[ ! $ENABLED == "true" ]]; then
                echo "`date -Is` OpenSESME Main: $CONF is disabled." | tee -a $LOGFILE
                exit 0
        fi

        # Check for archive directories if config is set RECURSIVE=true and ARCHIVE=true
        # Will create archive directories if they don't exist
        if [[ $RECURSIVE == "true" ]] && [[ $ARCHIVE == "true" ]]; then
                echo "Config is set to Recursive and Archive, checking for presence of archive directories and creating if missing."
                for folder in $( ls $INPUT_DIR ); do
                        if [[ ! -d $INPUT_DIR/$folder/archive ]]; then
                                mkdir $INPUT_DIR/$folder/archive
                        fi
                done
        fi

        # Log things about the action/config
        logger -p local2.notice -t OpenSESME -- Starting action $ACTION_NAME
        echo >> $LOGFILE "`date -Is` OpenSESME Main: Starting action $ACTION_NAME"
        if [[ $RECURSIVE == "true" ]]; then
                logger -p local2.notice -t OpenSESME -- $ACTION_NAME: Configured for recursive monitoring.
                echo >> $LOGFILE "`date -Is` $ACTION_NAME: Configured for recursive monitoring."
        fi
        echo >> $LOGFILE "`date -Is` $ACTION_NAME: Input directory is $INPUT_DIR"
        echo >> $LOGFILE "`date -Is` $ACTION_NAME: Target is $TARGET"
        echo >> $LOGFILE "`date -Is` $ACTION_NAME: Output directory is $OUTPUT_DIR"
        echo >> $LOGFILE "`date -Is` $ACTION_NAME: Archiving set to $ARCHIVE"
        if [[ $ARCHIVE == "true" ]]; then
                echo >> $LOGFILE "`date -Is` $ACTION_NAME: Archive directory is $ARCHIVE_DIR"
        fi
        echo >> $LOGFILE "`date -Is` $ACTION_NAME: Modifications set to $MODIFY"

        # If an inotifywait target isn't specified, use close_write.
        if [[ -z "$INOTIFY_TARGET" ]]; then
                INOTIFY_TARGET=close_write
        fi

        # inotify does the heavy lifting here - it'll monitor and let us know when a file is done being written to (i.e. a FTP transfer stops, move is done, etc)
        if [[ $RECURSIVE == "true" ]]; then
                INO="inotifywait -m -r $INPUT_DIR -e $INOTIFY_TARGET"
        else
                INO="inotifywait -m $INPUT_DIR -e $INOTIFY_TARGET"
        fi

        $INO |

        # Start a loop that pulls variables from inotifywait
        while read path action file; do

                # Check to see if these are the droids we're looking for
                if [[ $file != $TARGET ]]; then
                        continue
                fi

                # If it's in an archive directory or the output directory, ignore it
                if [[ $path == *"$ARCHIVE_DIR"* ]] || [[ $path == *"$OUTPUT_DIR"* ]]; then
                        continue
                fi

                # If it's an excluded directory
                if [[ $path ==  *"$EXCLUDE_DIR"* ]] && [[ -n "$EXCLUDE_DIR" ]]; then
                        echo >> $LOGFILE "`date -Is` $ACTION_NAME: Exclude Debug: Path is $path and Exclude dir is $EXCLUDE_DIR"
                        echo >> $LOGFILE "`date -Is` $ACTION_NAME: "$path""$file" fits directory exclusion criteria and will not be processed."
                        continue
                fi

                # If it's an excluded file
                if [[ $file ==  *"$EXCLUDE_FILE"* ]] && [[ -n "$EXCLUDE_FILE" ]]; then
                        echo >> $LOGFILE "`date -Is` $ACTION_NAME: Exclude Debug: File is $file and exclude file is $EXCLUDE_FILENAME"
                        echo >> $LOGFILE "`date -Is` $ACTION_NAME: "$path""$file" fits file exclusion criteria and will not be processed."
                        continue
                fi

                # If a datestamp is wanted, do that - and if the FILENAME is blank, use $file as the name.
                if [[ $DATESTAMP == "true" ]]; then
                        if [[ -z "$FILENAME" ]]; then
                                WORKING_FILENAME=`date +%Y%m%d_%H%M%S`_$file
                        else
                                WORKING_FILENAME=`date +%Y%m%d_%H%M%S`_$FILENAME
                        fi
                else
                        if [[ -z "$FILENAME" ]]; then
                                WORKING_FILENAME=$file
                        else
                                WORKING_FILENAME=$FILENAME
                        fi
                fi

                # Log that the file has appeared
                echo >> $LOGFILE "`date -Is` $ACTION_NAME: The file $file appeared in directory $path via $action"

                # Archive an unmodified version
                if [[ $ARCHIVE == "true" ]] && [[ $RECURSIVE == "true" ]] && [[ ! $path == *"$ARCHIVE_DIR"* ]]; then
                        archive_recursive
                elif  [[ $ARCHIVE == "true" ]] && [[ ! $RECURSIVE == "true" ]]; then
                        archive
                fi



                # Doin' work, movin the file
                if [[ $MODIFY == "true" ]]; then
                        modify
                elif [[ ! $RECURSIVE == "true" ]]; then
                        # If no modification, just move the file to the output directory
                        echo >> $LOGFILE "`date -Is` $ACTION_NAME: Moving $path/$file to $OUTPUT_DIR as $WORKING_FILENAME"
                        mv $path/$file $OUTPUT_DIR/$WORKING_FILENAME && chown $OWNER.$GROUP $OUTPUT_DIR/$WORKING_FILENAME && chmod $PERMS $OUTPUT_DIR/$WORKING_FILENAME || (echo >> $LOGFILE "`date -Is` $ACTION_NAME: mv has failed for $path/$file to $OUTPUT_DIR/$WORKING_FILENAME"; logger -p local2.notice -t OpenSESME -- $ACTION_NAME: mv has failed for $path/$file to $OUTPUT_DIR/$WORKING_FILENAME)
                elif [[ $RECURSIVE == "true" ]]; then
                        # If no modification, just move the file to the output directory
                        echo >> $LOGFILE "`date -Is` $ACTION_NAME: Moving $path/$file to $OUTPUT_DIR as $WORKING_FILENAME"
                        mv $path/$file $OUTPUT_DIR/$WORKING_FILENAME && chown $OWNER.$GROUP $OUTPUT_DIR/$WORKING_FILENAME && chmod $PERMS $OUTPUT_DIR/$WORKING_FILENAME || (echo >> $LOGFILE "`date -Is` $ACTION_NAME: mv has failed for $path/$file to $OUTPUT_DIR/$WORKING_FILENAME"; logger -p local2.notice -t OpenSESME -- $ACTION_NAME: mv has failed for $path/$file to $OUTPUT_DIR/$WORKING_FILENAME)
                fi

                # Test to see if file is not actually there, and if it isn't, log errors
                if [[ ! $RECURSIVE == "true" ]] && [[ ! -e "$OUTPUT_DIR/$WORKING_FILENAME" ]]; then
                        echo >> $LOGFILE "`date -Is` $ACTION_NAME: File check has failed for presence of $OUTPUT_DIR/$WORKING_FILENAME"
                        logger -p local2.notice -t OpenSESME -- $ACTION_NAME: File check has failed for presence of $OUTPUT_DIR/$WORKING_FILENAME
                elif [[ ! $RECURSIVE == "true" ]] && [[ -e "$OUTPUT_DIR/$WORKING_FILENAME" ]]; then
                        #Log Event
                        echo >> $LOGFILE "`date -Is` $ACTION_NAME: Moved $file from $path to $OUTPUT_DIR as $WORKING_FILENAME"
                elif [[ $RECURSIVE == "true" ]] && [[ ! -e "$OUTPUT_DIR/$WORKING_FILENAME" ]]; then
                        echo >> $LOGFILE "`date -Is` $ACTION_NAME: File check has failed for presence of $OUTPUT_DIR/$WORKING_FILENAME"
                        logger -p local2.notice -t OpenSESME -- $ACTION_NAME: File check has failed for presence of $OUTPUT_DIR/$WORKING_FILENAME
                elif [[ $RECURSIVE == "true" ]] && [[ -e "$OUTPUT_DIR/$WORKING_FILENAME" ]]; then
                        #Log Event
                        echo >> $LOGFILE "`date -Is` $ACTION_NAME: Moved $file from $path to $OUTPUT_DIR as $WORKING_FILENAME"
                fi

                if [[ $RECURSIVE == "true" ]]; then
                        FILENAME=""
                        WORKING_FILENAME=""
                fi

        # Run the loop in the background with '&'
        done &

        # If this was called with an option, exit, otherwise continue to parse config files
        if [[ ! $r -eq 0 ]]; then
                exit 0
        fi
}



# Check for flags here
while getopts ":f:c:" opt; do
        case $opt in
                # Run one specified config file
                f)
                        echo "Running config $OPTARG"
                        CONF=$OPTARG
                        runconfig
                        ((r++))
                        exit 0
                ;;
                # Check one specified config file
                c)
                        echo "Checking config file $OPTARG for integrity"
                        source $OPTARG
                        configcheck $OPTARG
                        ((r++))
                        exit 0
                ;;
                # Invalid switch handling
                \?)
                        echo "Invalid option: -$OPTARG" >&2
                        exit 1
                ;;
                # Error/missing argument handling
                :)
                        echo "Option -$OPTARG requires an argument." >&2
                        exit 1
                ;;

        esac
done

for CONF in $(ls $CONFIG_DIR/*.conf | xargs); do
        runconfig
done
exit 0
