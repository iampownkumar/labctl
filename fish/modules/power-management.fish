# POWER MANAGEMENT MODULE
# Common control for SSH, Status, Reboot, and Shutdown

# Central control for a single machine
# Usage: mac <number> [status|reboot|down]
function mac
    set id $argv[1]
    set action $argv[2]

    if test -z $id
        echo "Usage: mac <number> [status|reboot|down]"
        return 1
    end

    set num (string pad -w 3 -c 0 $id)
    set host mac-$num

    switch "$action"
        case ""
            ssh $LAB_USER@$host.$LAB_DOMAIN
        case status
            ssh -o ConnectTimeout=5 $LAB_USER@$host.$LAB_DOMAIN uptime
        case reboot
            ssh -t $LAB_USER@$host.$LAB_DOMAIN sudo reboot
        case down
            ssh -t $LAB_USER@$host.$LAB_DOMAIN sudo shutdown -h now
        case '*'
            ssh -t $LAB_USER@$host.$LAB_DOMAIN "$argv[2..-1]"
    end
end

# Parallel lab-wide control
# Usage: mac-all {status|reboot|down}
function mac-all
    set action $argv[1]
    if test -z "$action"
        echo "Usage: mac-all {status|reboot|down}"
        return 1
    end

    set green (set_color green)
    set red (set_color red)
    set normal (set_color normal)

    if test "$action" = "status"
        set online 0
        set offline 0
        echo "📡 Checking lab status (parallel, 5s timeout)..."
        
        for host in $MACHINES
            # 2>/dev/null silences "Could not resolve hostname" noise
            ssh -o ConnectTimeout=5 -o ConnectionAttempts=1 $LAB_USER@$host.$LAB_DOMAIN "uptime" > "/tmp/$host.uptime" 2>/dev/null &
        end
        wait

        for host in $MACHINES
            if test -s "/tmp/$host.uptime"
                set online (math $online + 1)
                echo "$green$host : ONLINE  → "(cat "/tmp/$host.uptime")$normal
            else
                set offline (math $offline + 1)
                echo "$red$host : OFFLINE$normal"
            end
            rm -f "/tmp/$host.uptime"
        end
        echo "---------------------------------------------"
        echo "$green✅ ONLINE : $online$normal | $red❌ OFFLINE: $offline$normal"
        return
    end

    for host in $MACHINES
        switch "$action"
            case reboot
                ssh -o ConnectTimeout=5 $LAB_USER@$host.$LAB_DOMAIN "sudo reboot" >/dev/null 2>&1 &
            case down
                ssh -o ConnectTimeout=5 $LAB_USER@$host.$LAB_DOMAIN "sudo shutdown -h now" >/dev/null 2>&1 &
        end
    end
    disown
    echo "🚀 $action dispatched lab-wide (errors suppressed)."
end

