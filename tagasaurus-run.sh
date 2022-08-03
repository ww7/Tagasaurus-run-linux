#!/usr/bin/env bash

set -e
# set -uo pipefail
# set -x

mounted=""

# Function for downloading latest Tagasaurus, path can be specified as argument
ts_download () {
  read -p "Do you want to download and unpack Tagasaurus to $1 (y/n)? " choice
  case "$choice" in 
    y|Y ) echo "Answer: $choice. Processing...";;
    n|N ) exit;;
    * ) exit;;
  esac
  latest_info=$(wget -qO- https://api.github.com/repos/mantzaris/Tagasaurus/releases/latest)
  latest_tag=$(echo "$latest_info" | awk -F\" '/tag_name/{print $(NF-1)}')
  latest_targz=$( echo "$latest_info" | awk -F\" '/browser_download_url.*.tar.gz/{print $(NF-1)}')
  #latest_zip=$( echo "$latest_info" | awk -F\" '/browser_download_url.*.zip/{print $(NF-1)}')
  if [[ -n $1 && ! -d "$1" ]]; then mkdir -p "$1" || { echo "Error. Quit." && exit 1; } fi
  if [[ -n $1 ]]; then cd "$1" || { echo "Error. Input path not exist. Quit." && exit 1; }; fi
  if [[ -d tagasaurus-$latest_tag  ]]; then { echo "Folder $PWD/tagasaurus-$latest_tag exist (latest version). Quit." && return; } fi
  echo "Donwloading and unpacking: $latest_targz"
  wget -qO- "$latest_targz" | tar xz #tar zxf - --strip=1 -C "$PWD/tagasaurus-$latest_tag
  chmod +x "tagasaurus-$latest_tag/tagasaurus"
  test -d "$PWD/tagasaurus-$latest_tag" && echo "Unpacked to $PWD/tagasaurus-$latest_tag"
}

# Function for remount
remount_fat () {
  #if [ "$EUID" -ne 0 ]; then echo "Remount require 'root' premissions. Please run the script as 'root' or with 'sudo'"; exit; fi
  echo "Remounting $1 to $2 with permission to execute."
  sudo umount $2
  sudo mkdir -p $2
  sudo mount -o umask=000,utf8 $1 $2
}

# Find corresponding USB drives and process it
for devidusb in /dev/disk/by-id/usb*; do 
    usbdev=$(readlink -f "${devidusb}")
    usbmnt=$(findmnt -t vfat,exfat -nr -o target -S "$usbdev" | sed 's/\\x20/ /g') #lsblk -o MOUNTPOINT -nr "$devusb"
    [[ -z $usbmnt ]] && continue

    # Find tagasaurus binary on root folder of certain USB drive mount
    path_ts=$(find "$usbmnt" -maxdepth 2 -type f -iname "tagasaurus")
    if [[ -n $path_ts ]]; then 
      echo "Found Tagasaurus at path: $path_ts"; 
      # Check if 'exec' allowed and run Tagasaurus.
      if [[ -n $(findmnt -t vfat,exfat -O exec -O fmask=0000 -nr -o target -S "$usbdev" | sed 's/\\x20/ /g') ]]; then
        echo "Drive $usbdev allowed to execute, running $path_ts"
        nohup $path_ts  &>/dev/null & disown
        exit
      else 
        # Remount with 'umask=000' if 'exec' not allowed and run Tagasaurus.
        if [[ -n $(findmnt -t vfat,exfat -O noexec -O showexec -O fmask=0022 -nr -o target -S "$usbdev" | sed 's/\\x20/ /g') ]]; then
          remount_fat $usbdev $usbmnt
          echo "Running $path_ts"
          nohup $path_ts  &>/dev/null & disown
          exit
        fi
      fi
    else

      # Find if TagasaurusFiles folder exist on root folder of certain USB drive mount, if yes - ask for Tagasaurus download, then run.
      path_tsfiles=$(find "$usbmnt" -maxdepth 1 -type d -iname "TagasaurusFiles"); [[ -n $path_tsfiles ]] && echo "TagasaurusFiles data folder exist: $path_tsfiles"
      if [[ -n $(findmnt -t vfat,exfat -O exec -O fmask=0000 -nr -o target -S "$usbdev" | sed 's/\\x20/ /g') ]]; then
        echo "Drive $usbdev allowed to execute" 
        ts_download "$usbmnt"
        path_ts=$(find "$usbmnt" -maxdepth 2 -type f -iname "tagasaurus")
        echo "Running $path_ts"
        nohup $path_ts  &>/dev/null & disown
        exit
      else 
        # Remount with 'umask=000' if 'exec' not allowed, then ask for download Tagasaurus and run.
        if [[ -n $(findmnt -t vfat,exfat -O noexec -O showexec -O fmask=0022 -nr -o target -S "$usbdev" | sed 's/\\x20/ /g') ]]; then
          echo "Drive $usbmnt not allowed to exec."
          remount_fat $usbdev $usbmnt
          ts_download "$usbmnt"
          path_ts=$(find "$usbmnt" -maxdepth 2 -type f -iname "tagasaurus")
          echo "Running $path_ts"
          nohup $path_ts  &>/dev/null & disown
          exit
        fi
      fi
    fi
    mounted=$usbmnt
done

if [[ -z $mounted ]]; then echo "No USB drives with FAT/exFAT mounted."; fi