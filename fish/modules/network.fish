# NETWORK MANAGEMENT MODULE
# Handles IP/MAC scraping and Wake on LAN (WoL)

# Scrape IP and MAC addresses from all online machines into a central inventory
# Usage: mac-scrape-inventory
function mac-scrape-inventory
    set green (set_color green)
    set red (set_color red)
    set normal (set_color normal)

    set inventory_dir "$HOME/.labctl"
    set inventory_file "$inventory_dir/inventory.csv"
    
    echo "📂 Creating inventory directory at $inventory_dir..."
    mkdir -p "$inventory_dir"
    
    # Initialize the CVS with headers
    echo "Hostname,IP,MAC" > "$inventory_file"
    
    echo "📡 Scraping network interfaces lab-wide (parallel execution)..."
    for host in $MACHINES
        # We run a POSIX sh script remotely to grab the active default interface, IP, and MAC.
        # We escape the $ variables meant for the remote shell using \$.
        ssh -o ConnectTimeout=5 -o ConnectionAttempts=1 $LAB_USER@$host.$LAB_DOMAIN "
            iface=\$(route get default | awk '/interface:/ {print \$2}')
            ip=\$(ipconfig getifaddr \$iface)
            mac=\$(ifconfig \$iface | awk '\$1 == \"ether\" {print \$2; exit}')
            echo \"$host,\$ip,\$mac\"
        " > "/tmp/$host.scrape" 2>/dev/null &
    end
    wait

    # Append gathered results sequentially to keep order
    set online 0
    set offline 0
    
    for host in $MACHINES
        if test -s "/tmp/$host.scrape"
            set result (cat "/tmp/$host.scrape")
            echo $result >> "$inventory_file"
            
            set ip (echo $result | cut -d, -f2)
            set mac (echo $result | cut -d, -f3)
            echo "$green✅ $host saved: $ip ($mac)$normal"
            set online (math $online + 1)
        else
            echo "$red❌ $host: OFFLINE (skipped)$normal"
            set offline (math $offline + 1)
        end
        rm -f "/tmp/$host.scrape"
    end
    
    echo "---------------------------------------------"
    echo "📜 Inventory saved to $inventory_file"
    echo "📊 Total Saved: $online | Skipped: $offline"
end

# Wake a single offline machine using its MAC address from the inventory
# Usage: mac-wake <number>
# Example: mac-wake 23
function mac-wake
    set id $argv[1]
    
    if test -z "$id"
        echo "Usage: mac-wake <number>"
        return 1
    end
    
    set num (string pad -w 3 -c 0 $id)
    set host mac-$num
    set inventory_file "$HOME/.labctl/inventory.csv"
    
    if not test -f "$inventory_file"
        echo "❌ Inventory not found. Please run 'mac-scrape-inventory' first."
        return 1
    end
    
    # Find the row for this host. Use awk to extract the MAC address reliably.
    set row (awk -F, -v h="$host" '$1==h {print $0}' "$inventory_file")
    if test -z "$row"
        echo "❌ No MAC address found for $host in inventory. Is it plugged into the LAN?"
        return 1
    end
    
    set mac (echo $row | cut -d, -f3)
    echo "⚡ Sending Wake-on-LAN Magic Packet to $host ($mac)..."
    
    # We use Python 3 (native on macOS) to cleanly construct and broadcast the Wake-on-LAN magic packet.
    python3 -c "
import sys
import socket

mac_str = '$mac'.replace(':', '')
if len(mac_str) != 12:
    print('❌ Error: MAC address length invalid.')
    sys.exit(1)

# Magic packet payload is 6 pairs of 'FF' followed by the MAC address repeated 16 times
data = 'FF' * 6 + (mac_str * 16)
magic_packet = bytes.fromhex(data)

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)

try:
    sock.sendto(magic_packet, ('255.255.255.255', 9))
    print('✅ Magic packet broadcasted successfully!')
except Exception as e:
    print(f'❌ Failed to send broadcast: {e}')
"
end

# Wake all machines in the lab using the inventory
# Usage: mac-all-wake
function mac-all-wake
    echo "⚡ Broadcasting Wake-on-LAN to the entire lab..."
    for host in $MACHINES
        set num (string replace "mac-" "" $host)
        mac-wake $num &
    end
    wait
    echo "🚀 Lab-wide wake signals deployed."
end

# Setup macOS Energy Saver settings to allow Wake on LAN ("Wake for network access")
# Usage: mac-wol-setup <number>
function mac-wol-setup
    set id $argv[1]
    set num (string pad -w 3 -c 0 $id)
    set host mac-$num

    echo "⚙️ Enabling 'Wake for network access' on $host..."
    ssh -o ConnectTimeout=5 $LAB_USER@$host.$LAB_DOMAIN "sudo pmset -a womp 1"
    echo "✅ WoL enabled for $host."
end

# Enable Wake on LAN on ALL machines in the lab
# Usage: mac-all-wol-setup
function mac-all-wol-setup
    echo "⚙️ Enabling 'Wake for network access' lab-wide (parallel)..."
    for host in $MACHINES
        ssh -o ConnectTimeout=5 $LAB_USER@$host.$LAB_DOMAIN "sudo pmset -a womp 1" >/dev/null 2>&1 &
    end
    wait
    echo "✅ Lab-wide WoL enabled."
end

