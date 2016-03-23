#!/bin/bash
# Spooler Script v0.0.11
# https://github.com/seattletimes/opensesme
# E. A. Griffon - 2016-03-23
# Thanks to StackExchange, Yaro Kasear, Orville Broadbeak, and Skyler Bunny
# http://unix.stackexchange.com/questions/24952/script-to-monitor-folder-for-new-files

# Define where configurations are held
CONFIG_DIR=/etc/opensesme.d/

# Define where to log to
LOGFILE=/var/log/opensesme.log

echo > /tmp/opensesme.pid

# Make a function to check config files
configcheck () {
:
#check $1
# check for  #ACTO
}

# Check for flags here (testing!)
while getopts ":f:" opt; do
        case $opt in
                f)
                        echo "you chose the file $OPTARG!";exit 0
                        # Do a thing with a single file specified
						# configcheck $OPTARG
                ;;
                \?)
                        echo "Invalid option: -$OPTARG" >&2;exit 1
                ;;
                :)
                        echo "Option -$OPTARG requires an argument."
                ;;
        esac
done

for CONF in $(ls $CONFIG_DIR/*.conf | xargs)
    do
		echo -e "Reading $CONF \n"
        echo >> $LOGFILE "`date -Is` OpenSESME Main: Reading $CONF"

        # Use function to check config file
		# configcheck $CONF

		source $CONF

        # Exit if the config is disabled
        if [ $ENABLED == false ]
        then
            echo >> $LOGFILE "`date -Is` OpenSESME Main: $CONF is disabled."
            break
        fi
	
	# Log things about the action
	logger -p local2.notice -t OpenSESME -- Starting action $ACTION_NAME
	echo >> $LOGFILE "`date -Is` OpenSESME Main: Starting action $ACTION_NAME"
	echo >> $LOGFILE "`date -Is` $ACTION_NAME: Input directory is $INPUT_DIR"
	#echo >> $LOGFILE "`date -Is` $ACTION_NAME: Target is $TARGET"
	echo >> $LOGFILE "`date -Is` $ACTION_NAME: Archive directory is $ARCHIVE_DIR"
	echo >> $LOGFILE "`date -Is` $ACTION_NAME: Output directory is $OUTPUT_DIR"
	echo >> $LOGFILE "`date -Is` $ACTION_NAME: Archiving set to $ARCHIVE"
	echo >> $LOGFILE "`date -Is` $ACTION_NAME: Modifications set to $MODIFY"

	# inotify does the heavy lifting here - it'll monitor and let us know when a file is done being written to (i.e. a FTP transfer stops, move is done, etc)
	inotifywait -m $INPUT_DIR -e close_write |

		# Start a loop that pulls variables from inotifywait
		while read path action file; do

			# Log that the file has appeared
			echo >> $LOGFILE "`date -Is` $ACTION_NAME: The file $file appeared in directory $path via $action"

			# Archive an unmodified version
			if [ $ARCHIVE == true ]
			then
				cp $path/$file $ARCHIVE_DIR/$file|| (echo >> $LOGFILE "`date -Is` $ACTION_NAME: archival copy has failed for $path/$file to $ARCHIVE_DIR/$file"; logger -p local2.notice -t OpenSESME -- $ACTION_NAME: archival copy has failed for $path/$file to $ARCHIVE_DIR/$file)
			
				# Test to see if archive file is not actually there, and if it isn't, log errors
				if
					[ ! -e "$ARCHIVE_DIR/$file" ]
				then
					echo >> $LOGFILE "`date -Is` $ACTION_NAME: File check has failed for presence of archived file in $ARCHIVE_DIR/$file"
							logger -p local2.notice -t OpenSESME -- $ACTION_NAME: File check has failed for presence of archived file in $ARCHIVE_DIR/$file
				else 
					# "Log" the events
					echo >> $LOGFILE "`date -Is` $ACTION_NAME: Archived $file from $path to $ARCHIVE_DIR/$file"
				fi
			fi
			
			# Let's DO STUFF!
			if [ $MODIFY == true ]
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
	echo $! - $ACTION_NAME >>/tmp/opensesme.pid
done
exit 0
