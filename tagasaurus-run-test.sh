#!/usr/bin/env bash

# The script searches for Tagasaurus and runs it
# If Tagasaurus is found on a USB drive that is not allowed to run, will remount it with the appropriate permissions
# Path to Tagasaurus can be provided as argument

# set -e
set -x

mount_to="/mnt/Tagasaurus"

# Using path of script if path not passed as argument
if [[ -z $1 ]]; then ts_path_input=$(dirname "$0"); else 
  if [[ -d $1 ]]; then ts_path_input="$1"; else echo "Input path is \"$1\" and doesn't exist. Exit."; return; fi 
fi

# Function for remount
remount_fat () {
  echo "Remounting $1 ($2) to $3 with permission to exec."
  if [[ "$EUID" != 0 ]]; then
    cd $HOME;
    umount -l "$1"
    mkdir -p "$3"
    mount -o rw,uid=$(id -u),gid=$(id -g),utf8 "$2" "$3"
  else
    echo "Please enter the password."
    if [[ -n $(sudo -v 2>&1 | grep "not") ]]; then echo "User \"$(whoami)\" not allowed for this operation. Remount required a 'sudo' or running from 'root'"; return; fi
    cd $HOME;
    sudo umount -l "$1"
    sudo mkdir -p "$3"
    sudo mount -o rw,uid=$(id -u),gid=$(id -g),utf8 "$2" "$3"
    (($? != 0)) && { echo "Remount Error. Quit."; return; }
  fi
}

ts_exec () {
  nohup $1  &>/dev/null & disown
  return
  # exit
}


# Searching Tagasaurus in current directory.
if [[ -f ./tagasaurus && "application" == $(file -b --mime-type ./tagasaurus | sed 's|/.*||') ]]; then 
  # Runs Tagasaurus if drive not USB or mount point already has `exec` permission and application in current directory.
  if [[ -n $(findmnt -O exec -nr -o TARGET --target ./tagasaurus) ]]; then echo "Tagasaurus found, run."; ts_exec ./tagasaurus; fi
  if [[ -z $(ls /dev/$(ls -lR /dev/disk/by-id/ | grep ^l | grep 'usb' | awk '{print $NF}' | cut -d '/' -f 3 | awk 'NR == 1') \
          | grep $(findmnt -nr -o SOURCE --target ./tagasaurus)) ]]; then echo "Tagasaurus found, run."; ts_exec ./tagasaurus; fi

else

  # Serching Tagasaurus application folders
  if ! ts_found=$(find "$ts_path_input" -maxdepth 2 -type f -iname "tagasaurus"); then echo "Searching error. Exit."; return; fi
  
  if [[ -z "$ts_found" ]]; then echo "Tagasaurus not found. Exit"; return; fi

  # Checking if only one Tagasaurus application folders found, selecting first if more than one
  if [[ $(echo "$ts_found" | wc -l) -gt 0 ]]; then
    # Filtering applications
    for ts_path in $ts_found; do
      if [[ -f $ts_path && "application" == $(file -b --mime-type tagasaurus | sed 's|/.*||') ]]; then ts_path_checked+="$ts_path"$'\n'; fi
    done
  fi

  if [[ $(echo "$ts_path_checked" | wc -l) -gt 0 ]]; then 
    echo -e "Found multiple Tagasaurus folders:\n $ts_path_checked"
    ts_path_selected=$(head -n 1)
  fi

  echo "Running first: $ts_path_selected"
  # Runs Tagasaurus if mount point has `exec` permission
  if [[ -n $(findmnt -O exec -nr -o TARGET --target "$ts_path_selected") ]]; then ts_exec "$ts_path_selected"; fi

  # If mount point has not `exec` permission: remount and runs Tagasaurus
  noexec_mnt=$(findmnt -O noexec -nr -o TARGET --target "$ts_path_selected")
  if [[ -n $noexec_mnt ]]; then
    echo "Storage mounted without 'exec' permissions. Trying to remount."
    noexec_blk=$(findmnt -O noexec -nr -o SOURCE --target "$ts_path_selected")
    remount_fat "$noexec_mnt" "$noexec_blk" "$mount_to"
    echo "Remounted to $mount_to. Tagasaurus running."; 
    ts_exec "$ts_path_selected"
  fi

fi


