# SCREEN & PRESENTATION MODULE
# Monitor student screens and push presentations

# One-time setup: Enable Screen Sharing/Remote Desktop on a target Mac silently.
# Usage: mac-screen-setup <number>
function mac-screen-setup
    set id $argv[1]
    set num (string pad -w 3 -c 0 $id)
    set host mac-$num

    echo "⚙️ Enabling Screen Sharing & ARD on $host..."
    ssh -o ConnectTimeout=5 $LAB_USER@$host.$LAB_DOMAIN \
    "sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -access -on -users $LAB_USER -privs -all -restart -agent -menu"
    echo "✅ Screen Sharing enabled for $host."
end

# Enable Screen Sharing on ALL machines
# Usage: mac-all-screen-setup
function mac-all-screen-setup
    echo "⚙️ Enabling Screen Sharing lab-wide (parallel)..."
    for host in $MACHINES
        ssh -o ConnectTimeout=5 $LAB_USER@$host.$LAB_DOMAIN \
        "sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -access -on -users $LAB_USER -privs -all -restart -agent -menu" >/dev/null 2>&1 &
    end
    wait
    echo "✅ Lab-wide Screen Sharing enabled."
end

# Silently monitor a single student's screen (Pulls their screen to Admin PC)
# Usage: mac-monitor <number>
# Example: mac-monitor 23
function mac-monitor
    set id $argv[1]
    
    if test -z "$id"
        echo "Usage: mac-monitor <number>"
        return 1
    end
    
    set num (string pad -w 3 -c 0 $id)
    set host mac-$num
    
    echo "👀 Pulling screen for $host..."
    # 'open' command launches the native macOS Screen Sharing app connected securely via VNC.
    open "vnc://$LAB_USER@$host.$LAB_DOMAIN"
end

# Force all student Macs to open a view to the Admin's Screen (Presentation Mode)
# Usage: mac-present
function mac-present
    echo "⚠️ Presentation Mode requires Screen Sharing to be enabled on THIS Admin PC."
    echo "Students will be prompted to authenticate or ask for permission."
    
    # Try to grab the Admin PC's primary IP address
    set admin_ip (ipconfig getifaddr en0)
    if test -z "$admin_ip"
        set admin_ip (ipconfig getifaddr en1)
    end
    
    echo "🚀 Pushing Admin Screen ($admin_ip) to all students..."
    
    for host in $MACHINES
        ssh -o ConnectTimeout=5 $LAB_USER@$host.$LAB_DOMAIN \
        "open vnc://$admin_ip" >/dev/null 2>&1 &
    end
    wait
    echo "✅ Presentation pushed!"
end

# Force a single student Mac to open a view to the Admin's Screen (Presentation Mode)
# Usage: mac-present-host <number>
function mac-present-host
    set id $argv[1]
    if test -z "$id"
        echo "Usage: mac-present-host <number>"
        return 1
    end
    
    set num (string pad -w 3 -c 0 $id)
    set host mac-$num

    set admin_ip (ipconfig getifaddr en0)
    if test -z "$admin_ip"
        set admin_ip (ipconfig getifaddr en1)
    end
    
    echo "🚀 Pushing Admin Screen ($admin_ip) to $host..."
    ssh -o ConnectTimeout=5 $LAB_USER@$host.$LAB_DOMAIN \
    "open vnc://$admin_ip" >/dev/null 2>&1 &
    wait
    echo "✅ Presentation pushed to $host!"
end

# Stop the Presentation Mode on all student Macs by closing their Screen Sharing app.
# Usage: mac-stop-present
function mac-stop-present
    echo "🛑 Stopping Presentation on all students..."
    for host in $MACHINES
        ssh -o ConnectTimeout=5 $LAB_USER@$host.$LAB_DOMAIN \
        "killall 'Screen Sharing' 2>/dev/null" >/dev/null 2>&1 &
    end
    wait
    echo "✅ Presentation stopped!"
end

# Stop the Presentation Mode on a single student Mac
# Usage: mac-stop-present-host <number>
function mac-stop-present-host
    set id $argv[1]
    if test -z "$id"
        echo "Usage: mac-stop-present-host <number>"
        return 1
    end
    set num (string pad -w 3 -c 0 $id)
    set host mac-$num

    echo "🛑 Stopping Presentation on $host..."
    ssh -o ConnectTimeout=5 $LAB_USER@$host.$LAB_DOMAIN \
    "killall 'Screen Sharing' 2>/dev/null" >/dev/null 2>&1 &
    wait
    echo "✅ Presentation stopped on $host!"
end
