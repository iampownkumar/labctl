# MAC LAB ADMIN INIT
# Central entry point for lab control logic

set BASE (dirname (status --current-filename))

# Load modules in logical order
source $BASE/modules/config.fish
source $BASE/modules/hostnames.fish
source $BASE/modules/power-management.fish
source $BASE/modules/brew-management.fish
source $BASE/modules/software.fish
source $BASE/modules/notify.fish
source $BASE/modules/admin.fish
source $BASE/modules/autologin.fish
source $BASE/modules/emergency.fish
source $BASE/modules/network.fish
source $BASE/modules/screens.fish




