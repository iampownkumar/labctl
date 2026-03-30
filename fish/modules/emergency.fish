# EMERGENCY & CLEANUP MODULE

# Force-kill all background lab tasks (SSH and Brew installers)
# This prevents "zombie" or hanging processes from piling up.
# Usage: mac-kill-all
function mac-kill-all
    echo "🛑 Force-killing all lab-related SSH processes..."
    
    # Kill SSH processes targeting mac-XXX
    pkill -9 -f "$LAB_USER@mac-"
    
    # Kill any potentially hanging brew install scripts
    pkill -9 -f "brew install"
    
    echo "✅ Cleanup complete."
end
