#!/usr/bin/env bash

# The script searches for Tagasaurus and runs it
# If Tagasaurus is found on a USB drive that is not allowed to run, will remount it with the appropriate permissions

# set -e
set -x

mount_to="/mnt/Tagasaurus"

if [[ -z "$1" ]]; then ts_path_input=$(dirname "$0"); else 
  if [[ -d $1 ]]; then ts_path_input="$1"; else echo "Inptut path don't exit. Quit."; exit 1; fi 
fi

# Function for remount
remount_fat () {
  #if [ "$EUID" -ne 0 ]; then echo "Remount require 'root' premissions. Please run the script as 'root' or with 'sudo'";fi
  echo "Re-mounting $1 ($2) to $3 with permission to exec."
  sudo umount -l "$1"
  sudo mkdir -p "$3"
  sudo mount -o rw,uid=$(id -u),gid=$(id -g),utf8 "$2" "$3"
}

ts_exec () {
  nohup $1  &>/dev/null & disown
}


# Check if Tagasaurus applicatgion in current folder
if [[ -f ./tagasaurus && "application" == $(file -b --mime-type tagasaurus | sed 's|/.*||') ]]; then 
  
  # Runs Tagasaurus if mount point has `exec` permission
  if [[ -n $(findmnt -O exec -nr -o TARGET --target ./tagasaurus) ]]; then echo "Tagasaurus binary found, run."; ts_exec ./tagasaurus; fi
  
  # If mount point has not `exec` permission: re-mount and runs Tagasaurus
  noexec_mnt=$(findmnt -O noexec -nr -o TARGET --target ./tagasaurus)
  if [[ -n $noexec_mnt ]]; then
    echo "Storage mounted without 'exec' permissions. Trying to re-mount."
    noexec_blk=$(findmnt -O noexec -nr -o SOURCE --target ./tagasaurus)
    remount_fat "$noexec_mnt" "$noexec_blk" "$mount_to"
    (($? != 0)) && { printf '%s\n' "Remount Error. Quit."; }
    echo "Re-mounted to $mount_to. Tagasaurus run."; 
    ts_exec ./tagasaurus
  fi

else

  # If ./tagasaurus not in current folder: serching Tagasaurus folders
  # ts_blk=$(findmnt -O noexec -nr -o SOURCE --target "$(dirname "$ts_path_input")")
  ts_found=$(find "$(dirname "$ts_path_input")" -maxdepth 2 -type f -iname "tagasaurus")
  
  # Checking if only one Tagasaurus found, selecting first if more then 1
  if [[ $(echo "$ts_found" | wc -l) -gt 1 ]]; then 
    for ts_path in $ts_found; do
      if [[ -f $ts_path && "application" == $(file -b --mime-type tagasaurus | sed 's|/.*||') ]]; then 
      ts_path_checked+="$ts_path"$'\n'
      fi
    done
   else echo "Tagasaurus not found. Quit";   fi
  if [[ $(echo "$ts_path_checked" | wc -l) -gt 1 ]]; then 
    echo -e "Found multiple Tagasaurus folders:\n $ts_path_checked"
    ts_path_checked=$(head -n 1)
    echo "Running first found: $ts_path_checked"
  fi
        
  # Runs Tagasaurus if mount point has `exec` permission
  if [[ -n $(findmnt -O exec -nr -o TARGET --target "$ts_path_checked") ]]; then echo "Tagasaurus binary found, run."; ts_exec "$ts_path_checked"; fi
  
  # If mount point has not `exec` permission: re-mount and runs Tagasaurus
  noexec_mnt=$(findmnt -O noexec -nr -o TARGET --target "$ts_path_checked")
  if [[ -n $noexec_mnt ]]; then
    echo "Storage mounted without 'exec' permissions. Trying to re-mount."
    noexec_blk=$(findmnt -O noexec -nr -o SOURCE --target "$ts_path_checked")
    remount_fat "$noexec_mnt" "$noexec_blk" "$mount_to"
    # (($? != 0)) && { printf '%s\n' "Remount Error. Quit.";; }
    echo "Re-mounted to $mount_to. Tagasaurus run."; 
    ts_exec ./tagasaurus
  fi

fi
