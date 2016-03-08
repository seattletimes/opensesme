#!/bin/bash
# Spooler Script v0.0.9 - "Save The PIDs!"
# https://github.com/seattletimes/opensesme
# E. A. Griffon - 2016-03-08
# Thanks to StackExchange, Yaro Kasear, Orville Broadbeak, and Skyler Bunny
# http://unix.stackexchange.com/questions/24952/script-to-monitor-folder-for-new-files

# Define where configurations are held
CONFIG_DIR=/usr/local/opensesme/config
#CONFIG_DIR=/etc/opensesme.d/
LOGFILE=/var/log/opensesme.log

echo > /tmp/opensesme.pid

# Check for flags here
# if $flagthingy tells us to read a single config, then
# source $specified_conf_file
# else 
# Bring in config files from directory
for CONF in $(ls $CONFIG_DIR/*.cfg | xargs)
do
echo -e Reading $CONF\n
echo >> $LOGFILE "`date -Is` OpenSESME Main: Reading $CONF"
source $CONF

# Log things about the action
logger -p local2.notice -t OpenSESME -- Starting action $ACTION_NAME
echo >> $LOGFILE "`date -Is` OpenSESME Main: Starting action $ACTION_NAME"
echo >> $LOGFILE "`date -Is` $ACTION_NAME: Input directory is $INPUT_DIR"
#echo >> $LOGFILE "`date -Is` $ACTION_NAME: Target is $TARGET"
echo >> $LOGFILE "`date -Is` $ACTION_NAME: Archive directory is $ARCHIVE_DIR"
echo >> $LOGFILE "`date -Is` $ACTION_NAME: Output directory is $OUTPUT_DIR"

# inotify does the heavy lifting here - it'll monitor and let us know when a file is done being written to (i.e. a FTP transfer stops, move is done, etc)
inotifywait -m $INPUT_DIR -e close_write |

    # Start a loop that pulls variables from inotifywait
    while read path action file; do

        # "Log" that the file has appeared
        echo >> $LOGFILE "`date -Is` $ACTION_NAME: The file $file appeared in directory $path via $action"

		# Archive an unmodified version
		cp $path/$file $ARCHIVE_DIR/$file|| (echo >> $LOGFILE "`date -Is` $ACTION_NAME: archival copy has failed for $path/$file to $ARCHIVE_DIR/$file"; logger -p local2.notice -t OpenSESME -- $ACTION_NAME: archival copy has failed for $path/$file to $ARCHIVE_DIR/$file)
		
		# Let's DO STUFF!
		if [ $MODIFY="true" ]
		then	
			#$PERFORM ||(echo >> $LOGFILE "`date -Is` $ACTION_NAME: Execution of $PERFORM has failed for $path/$file"; logger -p local2.notice -t OpenSESME -- $ACTION_NAME: Execution of $PERFORM has failed for $path/$file)
			echo >> $LOGFILE "`date -Is` $ACTION_NAME: We did $PERFORM!"
		fi

        # Define FILENAME as the filename with timestamp
        FILENAME=$file\_`date -Is`

        # Move the file to the output directory with the new FILENAME, add error checking
        mv $path/$file $OUTPUT_DIR/$FILENAME || (echo >> $LOGFILE "`date -Is` $ACTION_NAME: mv has failed for $path/$file to $OUTPUT_DIR/$FILENAME"; logger -p local2.notice -t OpenSESME -- $ACTION_NAME: mv has failed for $path/$file to $OUTPUT_DIR/$FILENAME)

                # Test to see if file is not actually there, and if it isn't, log errors
                if
                        [ ! -e "$OUTPUT_DIR/$FILENAME" ]
                then
                        echo >> $LOGFILE "`date -Is` $ACTION_NAME: File check has failed for presence of $OUTPUT_DIR/$FILENAME"
                        logger -p local2.notice -t OpenSESME -- $ACTION_NAME: File check has failed for presence of $OUTPUT_DIR/$FILENAME
                else 
					# "Log" the events
					echo >> $LOGFILE "`date -Is` $ACTION_NAME: Moved $file from $path to $OUTPUT_DIR as $FILENAME"
				fi
 
    # Run the loop in the background with '&'
    done &
echo $ACTION_NAME - $! >>/tmp/opensesme.pid
done
exit 0