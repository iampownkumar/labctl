# SOFTWARE MANAGEMENT MODULE
# Generic package management using Homebrew (Casks & Formulas)

# Install or manage a package on a single machine
# Usage: mac-pkg <number> <cask|formula> <package>
function mac-pkg
    set id $argv[1]
    set type $argv[2]
    set name $argv[3]

    if test -z "$id" -o -z "$type" -o -z "$name"
        echo "Usage: mac-pkg <number> <cask|formula> <package>"
        return 1
    end

    set num (string pad -w 3 -c 0 $id)
    set host mac-$num

    echo "📦 Installing $name ($type) on $host..."
    ssh $LAB_USER@$host.$LAB_DOMAIN "/opt/homebrew/bin/brew install --$type $name"
end

# Install or manage a package on all machines in parallel
# Usage: mac-pkg-all <cask|formula> <package>
function mac-pkg-all
    set type $argv[1]
    set name $argv[2]

    if test -z "$type" -o -z "$name"
        echo "Usage: mac-pkg-all <cask|formula> <package>"
        return 1
    end

    echo "🚀 Deploying $name ($type) to all machines..."
    for host in $MACHINES
        # Silence SSH errors in lab-wide commands
        ssh $LAB_USER@$host.$LAB_DOMAIN "/opt/homebrew/bin/brew install --$type $name" >/dev/null 2>&1 &
    end
    disown
end

# Uninstall a package from a single machine
# Usage: mac-pkg-remove <number> <cask|formula> <package>
function mac-pkg-remove
    set id $argv[1]
    set type $argv[2]
    set name $argv[3]

    set num (string pad -w 3 -c 0 $id)
    set host mac-$num

    ssh $LAB_USER@$host.$LAB_DOMAIN "/opt/homebrew/bin/brew uninstall --$type $name"
end

# Uninstall a package from all machines in parallel
# Usage: mac-pkg-remove-all <cask|formula> <package>
function mac-pkg-remove-all
    set type $argv[1]
    set name $argv[2]

    for host in $MACHINES
        ssh $LAB_USER@$host.$LAB_DOMAIN "/opt/homebrew/bin/brew uninstall --$type $name" >/dev/null 2>&1 &
    end
    disown
end
