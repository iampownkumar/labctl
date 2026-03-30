# NOTIFICATION & ALERTING MODULE
# Messaging and audible alerts across the lab

# Display a desktop notification on a single machine
# Usage: mac-notify <number> <message>
function mac-notify
    set id $argv[1]
    set msg $argv[2..-1]

    set num (string pad -w 3 -c 0 $id)
    set host mac-$num

    ssh -o ConnectTimeout=5 $LAB_USER@$host.$LAB_DOMAIN \
    "osascript -e 'display notification \"$msg\" with title \"Lab Admin\"' >/dev/null 2>&1" &
    disown
end

# Display a desktop notification on all machines
# Usage: mac-all-notify <message>
function mac-all-notify
    set msg $argv

    for host in $MACHINES
        # Silence output on BOTH the remote machine and the local terminal
        ssh -o ConnectTimeout=5 $LAB_USER@$host.$LAB_DOMAIN \
        "osascript -e 'display notification \"$msg\" with title \"Lab Admin\"' >/dev/null 2>&1" >/dev/null 2>&1 &
    end

    disown
end

# Play a sound and display an alert on a single machine
# Usage: mac-alert <number> <message>
function mac-alert
    set id $argv[1]
    set msg $argv[2..-1]

    set num (string pad -w 3 -c 0 $id)
    set host mac-$num

    ssh -o ConnectTimeout=5 $LAB_USER@$host.$LAB_DOMAIN \
    "afplay /System/Library/Sounds/Glass.aiff >/dev/null 2>&1; \
     osascript -e 'display notification \"$msg\" with title \"Lab Admin\"' >/dev/null 2>&1" &
    disown
end

# Play a sound and display an alert on all machines
# Usage: mac-all-alert <message>
function mac-all-alert
    set msg $argv

    for host in $MACHINES
        # Silence output on BOTH the remote machine and the local terminal
        ssh -o ConnectTimeout=5 $LAB_USER@$host.$LAB_DOMAIN \
        "afplay /System/Library/Sounds/Glass.aiff >/dev/null 2>&1; \
         osascript -e 'display notification \"$msg\" with title \"Lab Admin\"' >/dev/null 2>&1" >/dev/null 2>&1 &
    end

    disown
end