#!/bin/ksh

# Function for preventing running another instance of this script
prevent_function() {

    # Lock file path
    LOCK_FILE="/PATH/TO/logger_script.pid"

    # Check if another instance of the script is running
    if [ -f "$LOCK_FILE" ]; then
        # Read the PID from the lock file
        pid=$(cat "$LOCK_FILE")

        # Check if the process corresponding to the PID is running
        if ps -p "$pid" >/dev/null; then
            echo "Script is already running with PID $pid. Exiting..."
            exit 1
        else
            # Remove stale lock file
            rm -f "$LOCK_FILE"
        fi
    fi

    # Get the current process ID
    current_pid=$$

    # Write the current PID to the lock file
    echo "$current_pid" >"$LOCK_FILE"
}

# The script
prevent_function

# Store LOG_FILE variable and get its lines number
LOG_FILE=$(find /PATH/TO/LOG/DIRECTORY -type f -name 'LOGGFILENAME*' -print | xargs ls -ltr | tail -n 1 | awk '{print $9}')
old_lines=$(wc -l <"$LOG_FILE")

# Adding the tag to logger messages
APP_NAME="SOME_TAG"

# Main checking and logger function
main_function() {

    # Get the latest log file and store another NEW_LOG_FILE variable
    NEW_LOG_FILE=$(find /PATH/TO/LOG/DIRECTORY -type f -name 'LOGGFILENAME*' -print | xargs ls -ltr | tail -n 1 | awk '{print $9}')

    if [ "$NEW_LOG_FILE" = "$LOG_FILE" ]; then
        # Get the current lines number of the log file
        new_lines=$(wc -l <"$NEW_LOG_FILE")

        # If the log file has grown since the last check
        if [ "$new_lines" -gt "$old_lines" ]; then
            # Calculate the number of bytes to read
            num_lines=$((new_lines - old_lines))
            # Get new entries and push them to syslogd
            new_entries=$(tail -n "$num_lines" "$LOG_FILE")
            logger "$APP_NAME: $new_entries"
        # If the new_lines are less than old_lines or equals 0
        else
            sleep 1
        fi
    fi

    # This block should process 2 files, the old one and the new one
    if [ "$NEW_LOG_FILE" != "$LOG_FILE" ]; then
        # Get the current number of lines of the old log file
        new_size=$(wc -l <"$LOG_FILE")

        # Get the current number of lines of the new log file
        new_lines_new_file=$(wc -l <"$NEW_LOG_FILE")

        # If the old log file number of lines hasn't changed
        if [ "$new_lines" -eq "$old_lines" ]; then
            # Calculate the number of the new log file bytes to read
            num_lines_new_file=$((new_lines_new_file - 0))

            # Get new entries of a new file and push them to syslogd
            new_entries_new_file=$(tail -l "$num_lines_new_file" "$NEW_LOG_FILE")
            logger "$APP_NAME: $new_entries_new_file"

        # If the old log file has grown since the last check
        elif [ "$new_lines" -gt "$old_lines" ]; then
            # Calculate the number of lines to read
            num_lines=$((new_lines - old_lines))

            # Get new entries and push them to syslogd
            new_entries=$(tail -l "$num_lines" "$LOG_FILE")
            logger "$APP_NAME: $new_entries"

            # Calculate the number of the new log file lines to read
            num_lines_new_file=$((new_lines_new_file - 0))

            # Get new entries of a new file and push them to syslogd
            new_entries_new_file=$(tail -l "$num_lines_new_file" "$NEW_LOG_FILE")
            logger "$APP_NAME: $new_entries_new_file"

        # If the new_lines is less than old_lines or equals 0, process the new file only
        elif [ "$new_lines" -lt "$old_lines" ] || [ "$new_lines" = 0 ]; then
            # Calculate the number of the new log file lines to read
            num_lines_new_file=$((new_lines_new_file - 0))

            # Get new entries of a new file and push them to syslogd
            new_entries_new_file=$(tail -l "$num_lines_new_file" "$NEW_LOG_FILE")
            logger "$APP_NAME: $new_entries_new_file"

        fi
    fi
}

# Performing the main_function while true
while true; do
    main_function

    # Store the LOG_FILE
    LOG_FILE=$NEW_LOG_FILE

    # Store old_lines as a new_lines
    old_lines=$new_lines

    # Pause 10 secs
    sleep 1

    # End of code block
done