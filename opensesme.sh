#!/bin/bash
# OpenSESME v0.1.2
# https://github.com/seattletimes/opensesme
# E. A. Griffon - 2016-04-12
# Thanks to StackExchange, Yaro Kasear, Orville Broadbeak, and Skyler Bunny
# http://unix.stackexchange.com/questions/24952/script-to-monitor-folder-for-new-files

# Define where configurations are held
CONFIG_DIR=/etc/opensesme.d/

# Define where to log to
LOGFILE=/var/log/opensesme.log

# Empty the pid file (still in testing)
echo > /tmp/opensesme.pid

# Set our incrementalizers to 0
# Error count
i=0
# Run count
r=0
# Debug level
d=0

# Make a function for logging
logit ()
{
:
}

# Make a function to be called to check config files
# This needs to be fleshed out more to check for malformed paths, invalid characters, etc
configcheck () 
{
	# Check config for ENABLED statement
	if ! grep --quiet "ENABLED\=" $1; then
		echo "Config $1 is missing ENABLED statement - config invalid!"
		echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 is missing ENABLED statement - config invalid!"
		((i++))
	elif [ ! "$ENABLED" == "true" ] && [ ! "$ENABLED" == "false" ]; then
		echo "Config $1 has ENABLED set to something other than 'true' or 'false' - config invalid!"
		echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 has ENABLED set to something other than 'true' or 'false' - config invalid!"
		((i++))
	fi

	# Check config for Input Directory statement
	if ! grep --quiet "INPUT_DIR\=" $1; then
		echo "Config $1 is missing INPUT_DIR statement - config invalid!"
		echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 is missing INPUT_DIR statement - config invalid!"
		((i++))
	elif ! grep --quiet "INPUT_DIR\=\/" $1; then
		echo "Config $1 has a malformed INPUT_DIR directory path (not absolute/does not start with /)"
		echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 has a malformed INPUT_DIR directory path (not absolute/does not start with /)"
		((i++))
	fi

	# Check config for Archive and Archive Directory statements
	if ! grep --quiet "ARCHIVE\=" $1; then
		echo "Config $1 is missing ARCHIVE statement - config invalid!"
		echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 is missing ARCHIVE statement - config invalid!"
		((i++))
	elif [ ! "$ARCHIVE" == "true" ] && [ ! "$ARCHIVE" == "false" ]; then
		echo "Config $1 has ARCHIVE set to something other than 'true' or 'false' - config invalid!"
		echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 has ARCHIVE set to something other than 'true' or 'false' - config invalid!"
		((i++))
	elif [ "$ARCHIVE" == "true" ] && ! grep --quiet "ARCHIVE_DIR\=" $1; then
		echo "Config $1 has ARCHIVE set true but is missing ARCHIVE_DIR - config invalid!"
		echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 has ARCHIVE set true but is missing ARCHIVE_DIR - config invalid!"
		((i++))
	elif [ "$ARCHIVE" == "true" ] && ! grep --quiet "ARCHIVE_DIR\=\/" $1; then
		echo "Config $1 has a malformed ARCHIVE_DIR directory path (not absolute/does not start with /)"
		echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 has a malformed ARCHIVE_DIR directory path (not absolute/does not start with /)"
		((i++))
	fi


	# Check for Modify and Perform statements
	if ! grep --quiet "MODIFY\=" $1; then
		echo "Config $1 is missing MODIFY statement - config invalid!"
		echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 is missing MODIFY statement - config invalid!"
		((i++))
	elif [ ! "$MODIFY" == "true" ] && [ ! "$MODIFY" == "false" ]; then
		echo "Config $1 has MODIFY set to something other than 'true' or 'false' - config invalid!"
		echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 has MODIFY set to something other than 'true' or 'false' - config invalid!"
		((i++))
	elif [ "$MODIFY" == "true" ] && ! grep --quiet "PERFORM\=" $1; then
		echo "Config $1 has MODIFY set true, but is missing PERFORM statement - config invalid!"
		echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 has MODIFY set true, but is missing PERFORM statement - config invalid!"
		((i++))
	fi

	# Check for Output Directory statement
	if ! grep --quiet "OUTPUT_DIR\=" $1; then
		echo "Config $1 is missing OUTPUT_DIR statement - config invalid!"
		echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 is missing OUTPUT_DIR statement - config invalid!"
		((i++))
	elif ! grep --quiet "OUTPUT_DIR\=\/" $1; then
		echo "Config $1 has a malformed OUTPUT_DIR directory path (not absolute/does not start with /)"
		echo >> $LOGFILE "`date -Is` OpenSESME: Config $1 has a malformed OUTPUT_DIR directory path (not absolute/does not start with /)"
		((i++))
	fi

	if [ ! $i -eq 0 ]; then
		echo "The config has $i errors."
		exit 1
	else
		echo "Congratulations, the config has $i errors."
	fi		
}


# Main function to run a given CONF file
runconfig ()
{
	echo -e "Reading $CONF"
        echo >> $LOGFILE "`date -Is` OpenSESME Main: Reading $CONF"
   
		source $CONF

		# Use function to check config file
		
		configcheck $CONF
		
        # Exit if the config is disabled
        if [ $ENABLED == false ]
        then
			echo "`date -Is` OpenSESME Main: $CONF is disabled."
            echo >> $LOGFILE "`date -Is` OpenSESME Main: $CONF is disabled."
            exit 0
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
				$PERFORM $path/$file ||(echo >> $LOGFILE "`date -Is` $ACTION_NAME: Execution of $PERFORM has failed for $path/$file"; logger -p local2.notice -t OpenSESME -- $ACTION_NAME: Execution of $PERFORM has failed for $path/$file)
				#echo >> $LOGFILE "`date -Is` $ACTION_NAME: We did $PERFORM!"
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
	# Record the pid of the last run program (not... quite working in a useful way)
	echo $! - $ACTION_NAME >>/tmp/opensesme.pid
	
	# If this was called with an option, exit, otherwise continue to parse config files
	if [ ! $r -eq 0 ]; then
		exit 0
	fi
}

# Check for flags here (under construction!)
while getopts ":f:c:d:" opt; do
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
		# Set debug level
		d)
			echo Setting debug level to $OPTARG
			#LOGLEVEL=$OPTARG
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
