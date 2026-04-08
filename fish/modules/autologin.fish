# AUTO-LOGIN MANAGEMENT MODULE
# Remotely configure automatic login for lab machines
# Requires FileVault to be DISABLED on target machines.

# Enable automatic login for the $LAB_USER
# Usage: mac-autologin-on <number> <password>
function mac-autologin-on
    set id $argv[1]
    set pass $argv[2]
    
    if test -z "$id"; or test -z "$pass"
        echo "Usage: mac-autologin-on <number> <password>"
        return 1
    end

    set num (string pad -w 3 -c 0 $id)
    set host mac-$num

    echo "🔐 Enabling auto-login for '$LAB_USER' on $host using legacy method..."
    
    # Base64 encoded Perl script to generate /tmp/kcpassword
    set b64_script "IyEvdXNyL2Jpbi9wZXJsCnVzZSBzdHJpY3Q7Cm15ICRrZXkgPSBbMTI1LDEzNyw4MiwzNSwyMTAsMTg4LDIyMSwyMzQsMTYzLDE4NSwzMV07Cm15ICRrZXlfbGVuID0gc2NhbGFyKEAka2V5KTsKbXkgJHBhc3MgPSAkQVJHVlswXSB8fCAiIjsKbXkgQHAgPSB1bnBhY2soIkMqIiwgJHBhc3MpOwpwdXNoIEBwLCAwIHggKCRrZXlfbGVuIC0gKHNjYWxhcihAcCkgJSAka2V5X2xlbikpOwpteSBAbWFnaWM7CmZvciBteSAkaSAoMCAuLiAkI3ApIHsKICAgIHB1c2ggQG1hZ2ljLCAkcFskaV0gXiAka2V5LT5bJGkgJSAka2V5X2xlbl07Cn0Kb3BlbiBteSAkZmgsICI+IiwgIi90bXAva2NwYXNzd29yZCIgb3IgZGllICQhOwpiaW5tb2RlICRmaDsKcHJpbnQgJGZoIHBhY2soIkMqIiwgQG1hZ2ljKTsKY2xvc2UgJGZoOwo="

    ssh -o ConnectTimeout=5 -t $LAB_USER@$host.$LAB_DOMAIN "
        echo \"$b64_script\" | base64 --decode > /tmp/gen_kc.pl && \\
        perl /tmp/gen_kc.pl \"$pass\" && \\
        sudo mv /tmp/kcpassword /etc/kcpassword && \\
        sudo chmod 600 /etc/kcpassword && \\
        sudo chown root:wheel /etc/kcpassword && \\
        sudo defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser \"$LAB_USER\" && \\
        sudo rm -f /tmp/gen_kc.pl
    "
    
    if test $status -eq 0
        echo "✅ Auto-login enabled for $host."
    else
        echo "❌ Failed to enable auto-login for $host."
    end
end

# Disable automatic login
# Usage: mac-autologin-off <number>
function mac-autologin-off
    set id $argv[1]
    if test -z "$id"
        echo "Usage: mac-autologin-off <number>"
        return 1
    end

    set num (string pad -w 3 -c 0 $id)
    set host mac-$num

    echo "🔓 Disabling auto-login on $host..."
    ssh -o ConnectTimeout=5 -t $LAB_USER@$host.$LAB_DOMAIN "
        sudo rm -f /etc/kcpassword && \\
        sudo defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null || true
    "
    echo "✅ Auto-login disabled for $host."
end



# Check auto-login status
# Usage: mac-autologin-status <number>
function mac-autologin-status
    set id $argv[1]
    if test -z "$id"
        echo "Usage: mac-autologin-status <number>"
        return 1
    end

    set num (string pad -w 3 -c 0 $id)
    set host mac-$num

    ssh -o ConnectTimeout=5 $LAB_USER@$host.$LAB_DOMAIN \
        "sudo sysadminctl -autologin status"
end

# Enable automatic login on ALL machines
# Usage: mac-all-autologin-on <password>
function mac-all-autologin-on
    set pass $argv[1]
    if test -z "$pass"
        echo "Usage: mac-all-autologin-on <password>"
        return 1
    end

    echo "🔐 Enabling auto-login lab-wide (parallel) using legacy method..."
    set b64_script "IyEvdXNyL2Jpbi9wZXJsCnVzZSBzdHJpY3Q7Cm15ICRrZXkgPSBbMTI1LDEzNyw4MiwzNSwyMTAsMTg4LDIyMSwyMzQsMTYzLDE4NSwzMV07Cm15ICRrZXlfbGVuID0gc2NhbGFyKEAka2V5KTsKbXkgJHBhc3MgPSAkQVJHVlswXSB8fCAiIjsKbXkgQHAgPSB1bnBhY2soIkMqIiwgJHBhc3MpOwpwdXNoIEBwLCAwIHggKCRrZXlfbGVuIC0gKHNjYWxhcihAcCkgJSAka2V5X2xlbikpOwpteSBAbWFnaWM7CmZvciBteSAkaSAoMCAuLiAkI3ApIHsKICAgIHB1c2ggQG1hZ2ljLCAkcFskaV0gXiAka2V5LT5bJGkgJSAka2V5X2xlbl07Cn0Kb3BlbiBteSAkZmgsICI+IiwgIi90bXAva2NwYXNzd29yZCIgb3IgZGllICQhOwpiaW5tb2RlICRmaDsKcHJpbnQgJGZoIHBhY2soIkMqIiwgQG1hZ2ljKTsKY2xvc2UgJGZoOwo="

    for host in $MACHINES
        ssh -o ConnectTimeout=5 -t $LAB_USER@$host.$LAB_DOMAIN "
            echo \"$b64_script\" | base64 --decode > /tmp/gen_kc.pl && \\
            perl /tmp/gen_kc.pl \"$pass\" && \\
            sudo mv /tmp/kcpassword /etc/kcpassword && \\
            sudo chmod 600 /etc/kcpassword && \\
            sudo chown root:wheel /etc/kcpassword && \\
            sudo defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser \"$LAB_USER\" && \\
            sudo rm -f /tmp/gen_kc.pl
        " >/dev/null 2>&1 &
    end
    wait
    echo "✅ Lab-wide auto-login setup complete."
end

# Disable automatic login on ALL machines
# Usage: mac-all-autologin-off
function mac-all-autologin-off
    echo "🔓 Disabling auto-login lab-wide (parallel)..."
    for host in $MACHINES
        ssh -o ConnectTimeout=5 -t $LAB_USER@$host.$LAB_DOMAIN "
            sudo rm -f /etc/kcpassword && \\
            sudo defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null || true
        " >/dev/null 2>&1 &
    end
    wait
    echo "✅ Lab-wide auto-login disabled."
end

# Check auto-login status on ALL machines
# Usage: mac-all-autologin-status
function mac-all-autologin-status
    echo "📡 Checking auto-login status lab-wide (parallel)..."
    set green (set_color green)
    set red (set_color red)
    set normal (set_color normal)

    for host in $MACHINES
        ssh -o ConnectTimeout=5 $LAB_USER@$host.$LAB_DOMAIN "sudo sysadminctl -autologin status 2>&1" > "/tmp/$host.autologin" &
    end
    wait

    for host in $MACHINES
        if test -s "/tmp/$host.autologin"
            set result (cat "/tmp/$host.autologin")
            if string match -q "*Automatic login is OFF*" "$result"
                echo "$red$host : OFF$normal"
            else
                # Extract the username securely using grep/awk or just print it if found
                echo "$green$host : ON ($result)$normal"
            end
        else
            echo "$red$host : ERROR - No response$normal"
        end
        rm -f "/tmp/$host.autologin"
    end
end
