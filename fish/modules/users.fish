# USER MANAGEMENT MODULE
# Remotely create, delete, and list macOS user accounts across the lab.
# Uses sysadminctl (macOS native) for account operations.
# Passwords are base64-encoded for safe transport over SSH.

# ========================
# CREATE USER — SINGLE
# ========================

# Create a standard user on a single machine
# Usage: mac-user-create <number> <username> <password>
# Example: mac-user-create 23 student pass123
function mac-user-create
    set id $argv[1]
    set username $argv[2]
    set pass $argv[3]

    if test -z "$id"; or test -z "$username"; or test -z "$pass"
        echo "Usage: mac-user-create <number> <username> <password>"
        return 1
    end

    set num (string pad -w 3 -c 0 $id)
    set host mac-$num
    set pass_b64 (printf "%s" "$pass" | base64)

    echo "👤 Creating standard user '$username' on $host..."
    ssh -o ConnectTimeout=5 $LAB_USER@$host.$LAB_DOMAIN "
        clear_pass=\$(echo \"$pass_b64\" | base64 --decode) && \\
        sudo sysadminctl -addUser \"$username\" -password \"\$clear_pass\" -fullName \"$username\" 2>&1
    "

    if test $status -eq 0
        echo "✅ User '$username' created on $host."
    else
        echo "❌ Failed to create user '$username' on $host."
    end
end

# Create an admin user on a single machine
# Usage: mac-user-create-admin <number> <username> <password>
# Example: mac-user-create-admin 23 labadmin pass123
function mac-user-create-admin
    set id $argv[1]
    set username $argv[2]
    set pass $argv[3]

    if test -z "$id"; or test -z "$username"; or test -z "$pass"
        echo "Usage: mac-user-create-admin <number> <username> <password>"
        return 1
    end

    set num (string pad -w 3 -c 0 $id)
    set host mac-$num
    set pass_b64 (printf "%s" "$pass" | base64)

    echo "👤🔑 Creating admin user '$username' on $host..."
    ssh -o ConnectTimeout=5 $LAB_USER@$host.$LAB_DOMAIN "
        clear_pass=\$(echo \"$pass_b64\" | base64 --decode) && \\
        sudo sysadminctl -addUser \"$username\" -password \"\$clear_pass\" -fullName \"$username\" -admin 2>&1
    "

    if test $status -eq 0
        echo "✅ Admin user '$username' created on $host."
    else
        echo "❌ Failed to create admin user '$username' on $host."
    end
end

# ========================
# CREATE USER — ALL
# ========================

# Create a standard user on ALL machines (parallel)
# Usage: mac-all-user-create <username> <password>
function mac-all-user-create
    set username $argv[1]
    set pass $argv[2]

    if test -z "$username"; or test -z "$pass"
        echo "Usage: mac-all-user-create <username> <password>"
        return 1
    end

    set pass_b64 (printf "%s" "$pass" | base64)

    echo "👤 Creating standard user '$username' on ALL machines (parallel)..."
    for host in $MACHINES
        ssh -o ConnectTimeout=5 $LAB_USER@$host.$LAB_DOMAIN "
            clear_pass=\$(echo \"$pass_b64\" | base64 --decode) && \\
            sudo sysadminctl -addUser \"$username\" -password \"\$clear_pass\" -fullName \"$username\" 2>&1
        " >/dev/null 2>&1 &
    end
    wait
    echo "✅ User '$username' created lab-wide."
end

# Create an admin user on ALL machines (parallel)
# Usage: mac-all-user-create-admin <username> <password>
function mac-all-user-create-admin
    set username $argv[1]
    set pass $argv[2]

    if test -z "$username"; or test -z "$pass"
        echo "Usage: mac-all-user-create-admin <username> <password>"
        return 1
    end

    set pass_b64 (printf "%s" "$pass" | base64)

    echo "👤🔑 Creating admin user '$username' on ALL machines (parallel)..."
    for host in $MACHINES
        ssh -o ConnectTimeout=5 $LAB_USER@$host.$LAB_DOMAIN "
            clear_pass=\$(echo \"$pass_b64\" | base64 --decode) && \\
            sudo sysadminctl -addUser \"$username\" -password \"\$clear_pass\" -fullName \"$username\" -admin 2>&1
        " >/dev/null 2>&1 &
    end
    wait
    echo "✅ Admin user '$username' created lab-wide."
end

# ========================
# DELETE USER — SINGLE
# ========================

# Delete a user from a single machine (with secure home directory wipe)
# Usage: mac-user-delete <number> <username>
# Example: mac-user-delete 23 student
function mac-user-delete
    set id $argv[1]
    set username $argv[2]

    if test -z "$id"; or test -z "$username"
        echo "Usage: mac-user-delete <number> <username>"
        return 1
    end

    set num (string pad -w 3 -c 0 $id)
    set host mac-$num

    echo "🗑️  Deleting user '$username' from $host (with home directory wipe)..."
    ssh -o ConnectTimeout=5 $LAB_USER@$host.$LAB_DOMAIN "
        sudo sysadminctl -deleteUser \"$username\" -secure 2>&1
    "

    if test $status -eq 0
        echo "✅ User '$username' deleted from $host."
    else
        echo "❌ Failed to delete user '$username' from $host."
    end
end

# ========================
# DELETE USER — ALL
# ========================

# Delete a user from ALL machines (parallel, with secure home directory wipe)
# Usage: mac-all-user-delete <username>
function mac-all-user-delete
    set username $argv[1]

    if test -z "$username"
        echo "Usage: mac-all-user-delete <username>"
        return 1
    end

    echo "🗑️  Deleting user '$username' from ALL machines (parallel, secure wipe)..."
    for host in $MACHINES
        ssh -o ConnectTimeout=5 $LAB_USER@$host.$LAB_DOMAIN "
            sudo sysadminctl -deleteUser \"$username\" -secure 2>&1
        " >/dev/null 2>&1 &
    end
    wait
    echo "✅ User '$username' deleted lab-wide."
end

# ========================
# LIST USERS — SINGLE
# ========================

# List all non-system users on a single machine
# Usage: mac-user-list <number>
# Example: mac-user-list 23
function mac-user-list
    set id $argv[1]

    if test -z "$id"
        echo "Usage: mac-user-list <number>"
        return 1
    end

    set num (string pad -w 3 -c 0 $id)
    set host mac-$num

    echo "📋 Users on $host:"
    ssh -o ConnectTimeout=5 $LAB_USER@$host.$LAB_DOMAIN "
        dscl . list /Users | grep -v '^_' | grep -v '^daemon\$' | grep -v '^nobody\$' | grep -v '^root\$' | sort
    "
end

# ========================
# LIST USERS — ALL
# ========================

# List users on ALL machines (parallel)
# Usage: mac-all-user-list
function mac-all-user-list
    echo "📋 Listing users on ALL machines (parallel)..."
    set green (set_color green)
    set normal (set_color normal)

    for host in $MACHINES
        ssh -o ConnectTimeout=5 $LAB_USER@$host.$LAB_DOMAIN "
            dscl . list /Users | grep -v '^_' | grep -v '^daemon\$' | grep -v '^nobody\$' | grep -v '^root\$' | sort
        " > "/tmp/$host.users" 2>/dev/null &
    end
    wait

    for host in $MACHINES
        if test -s "/tmp/$host.users"
            set users (cat "/tmp/$host.users" | string join ", ")
            echo "$green$host$normal : $users"
        else
            echo "$host : ERROR - No response"
        end
        rm -f "/tmp/$host.users"
    end
end
