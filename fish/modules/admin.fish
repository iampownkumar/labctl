# ADMINISTRATIVE & SECURITY MODULE
# Manage privileged access (sudoers) and security across the lab

# ⚠️ WARNING: 
# This module modifies critical system security files. 
# Improper use could potentially lock you out of admin access on the remote machines.
# We use 'visudo -c' to validate changes, but proceed with caution.

# Safely set up passwordless sudo for the lab user
# Usage: mac-sudo-setup <number>
# Example: mac-sudo-setup 23
function mac-sudo-setup
    set id $argv[1]
    set num (string pad -w 3 -c 0 $id)
    set host mac-$num

    set yellow (set_color yellow)
    set normal (set_color normal)
    set red (set_color red)

    echo "$yellow⚠️ [SECURITY WARNING] $normal: This will enable passwordless sudo for '$LAB_USER' on $host."
    echo "This is required for parallel lab-wide automation (like brew-install-all)."
    
    # Validation-first approach:
    # 1. Create a temporary file with the new rule
    # 2. Use 'visudo -cf' to check if the file is syntactically correct
    # 3. Only if valid, move it into the protected /etc/sudoers.d/ directory
    ssh -t $LAB_USER@$host.$LAB_DOMAIN "
        echo '$LAB_USER ALL=(ALL) NOPASSWD: ALL' > /tmp/sudoer_temp && \
        sudo visudo -cf /tmp/sudoer_temp && \
        sudo mv /tmp/sudoer_temp /etc/sudoers.d/lab-admin && \
        sudo chmod 440 /etc/sudoers.d/lab-admin && \
        echo '✅ Configuration applied safely on $host.'
    "
end

# Setup passwordless sudo for all machines in the lab
# Usage: mac-sudo-setup-all
function mac-sudo-setup-all
    set red (set_color red)
    set normal (set_color normal)
    
    echo "$red🚨 [DANGER] 🚨: You are about to enable passwordless sudo on ALL machines.$normal"
    echo "Press Enter to continue, or Ctrl+C to abort..."
    read discard

    for host in $MACHINES
        set num (string replace "mac-" "" $host)
        mac-sudo-setup $num
    end
end
