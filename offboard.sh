#!/bin/bash
# Set the path to the GAM you want to use
GAM=/home/s_larsen/bin/gamadv-xtd/gam
GAMFILEPATH=~/gam-data

# Capture the leavers email address
get_leaver () {
echo -n "Enter email of user to deprovision & press Enter: "
read -r leaver
}

# Capture the manager email for drive, calendar and inbox delegation
get_manager () {
echo ""
echo "Enter the default Email to migrate Drive, Calendar, Inbox to"
echo -n "(Can be changed at each step) then press Enter: "
read -r manager
}

# Remove the user from the google address list (contacts)
remove_gal () {
$GAM update user ${leaver} gal off
}

# Remove the user from all groups they are a member of, saving a list in case
remove_groups () {
$GAM print user ${leaver} groups > ${leaver}_group_membership.csv
$GAM user ${leaver} delete groups
}

# Revoked all App Passwords, 2 Factor, and OAuth tokens
# Wipe Account from All Mobile Devices
deprovision () {
$GAM user ${leaver} deprovision
$GAM print mobile query "email:${leaver}" >> $GAMFILEPATH/tmp.mobile-data.csv
$GAM csv $GAMFILEPATH/tmp.mobile-data.csv gam update mobile ~resourceId action account_wipe
rm $GAMFILEPATH/tmp.mobile-data.csv
}

# Set the vacaction messaage
set_ooo () {
$GAM user ${leaver} vacation on subject "Left the Company" message "I have now left the Company. Please contact for all queries.\nn\nThank You" 
}

# Give access of the inbox to the manager
set_delegation () {
$GAM user ${leaver} delegate to ${manager}
}

# Set any forwading at the user level. This stops working when the account is deleted or suspended
set_forwarding () {
$GAM user ${leaver} add forwardingaddress ${manager}
$GAM user ${leaver} forward on ${manager} archive
}

transfer_drive () {
# transfers all drive files from leaver to manager 
$GAM create datatransfer ${leaver} gdrive ${manager} privacy_level shared,private
}

transfer_calendar () {
# transfers calendar entries from leaver to manager and releases calendar resources booked by leaver
$GAM create datatransfer ${leaver} calendar ${manager} release_resources true
}

PS3='Select your deprovisioning preference: '
options=('Standard User' 'VIP User' 'Quit')
select opt in "${options[@]}"
do
  case $opt in
    'Standard User')
      get_leaver
      get_manager
      remove_gal


      echo $manager
      echo -n "Enter new email of Manager (default for no change) & press Enter: "
      read -r newManager
        if [[ $newManager = "" ]]; then 
        newManager="$manager"
        fi
      
      echo "Please log into Admin Console and reset sign in cookies for ${leaver}"

      break
      ;;
    'VIP User')
      get_leaver
      remove_gal

      break
      ;;
    'Quit')
      break
      ;;
    *) echo invalid option;;
  esac
done

