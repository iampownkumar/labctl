# HOMEBREW MANAGEMENT MODULE
# Manage the Homebrew tool installation itself


# Install Homebrew on a single machine
# Usage: mac-brew-install <number>
function mac-brew-install
    set id $argv[1]
    set num (string pad -w 3 -c 0 $id)
    set host mac-$num

    echo "🍺 Installing Homebrew on $host..."
    # -t for interactive sudo password
    ssh -t $LAB_USER@$host.$LAB_DOMAIN \
    'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
end

# Install Homebrew on all machines in parallel
# Usage: mac-brew-install-all
function mac-brew-install-all
    echo "🚀 Installing Homebrew lab-wide (parallel, errors suppressed)..."
    for host in $MACHINES
        # Silence SSH errors in lab-wide commands
        ssh $LAB_USER@$host.$LAB_DOMAIN \
        'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' >/dev/null 2>&1 &
    end
    disown
end

# Check Homebrew installation status on a single machine
# Usage: mac-brew-check <number>
# Example: mac-brew-check 23
function mac-brew-check
    set id $argv[1]
    set num (string pad -w 3 -c 0 $id)
    set host mac-$num

    ssh -o ConnectTimeout=5 $LAB_USER@$host.$LAB_DOMAIN \
    'if [ -x /opt/homebrew/bin/brew ]; then /opt/homebrew/bin/brew --version | head -n 1; else echo "MISSING"; fi'
end

# Check Homebrew installation status on all machines in parallel
# Usage: mac-brew-check-all
function mac-brew-check-all
    set green (set_color green)
    set red (set_color red)
    set normal (set_color normal)

    echo "📡 Checking Homebrew status lab-wide (parallel execution, ordered output)..."
    for host in $MACHINES
        # Run in parallel and write result to temp file
        ssh -o ConnectTimeout=5 -o ConnectionAttempts=1 $LAB_USER@$host.$LAB_DOMAIN \
        "if [ -x /opt/homebrew/bin/brew ]; then echo 'INSTALLED'; else echo 'MISSING'; fi" > "/tmp/$host.brew" 2>/dev/null &
    end
    wait

    # Iterate through $MACHINES sequentially to ensure ordered output
    for host in $MACHINES
        if test -s "/tmp/$host.brew"
            set brew_status (cat "/tmp/$host.brew")
            if test "$brew_status" = "INSTALLED"
                echo "$green$host : INSTALLED$normal"
            else
                echo "$red$host : MISSING (Homebrew not found)$normal"
            end
        else
            echo "$red$host : OFFLINE$normal"
        end
        rm -f "/tmp/$host.brew"
    end
end

# Uninstall Homebrew from a single machine
# Usage: mac-brew-uninstall <number>
function mac-brew-uninstall
    set id $argv[1]
    set num (string pad -w 3 -c 0 $id)
    set host mac-$num

    echo "🗑  Uninstalling Homebrew from $host..."
    ssh -t $LAB_USER@$host.$LAB_DOMAIN \
    '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh) -- --force"'
end

# Uninstall Homebrew from all machines in parallel
# Usage: mac-brew-uninstall-all
function mac-brew-uninstall-all
    echo "🚨 Force-uninstalling Homebrew lab-wide..."
    for host in $MACHINES
        ssh $LAB_USER@$host.$LAB_DOMAIN \
        '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh) -- --force"' >/dev/null 2>&1 &
    end
    disown
end