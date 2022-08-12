#!/usr/bin/env bash

# set -e
# trap "exit 1" ERR
# set -uo pipefail
set -x

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
  if [[ -n $1 && ! -d "$1" ]]; then mkdir -p "$1" || { echo "Error. Can't create parent directory. Quit." && exit 1; } fi
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
  echo "Remounting $1 to $2 with permission to exec."
  sudo umount -f $2 || exit 1
  sudo mkdir -p $2 || exit 1
  sudo mount -o rw,uid=$(id -u),gid=$(id -g),utf8 $1 $2 || exit 1
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
      if [[ -n $(findmnt -t vfat,exfat -O exec -nr -o target -S "$usbdev" | sed 's/\\x20/ /g') ]]; then
        echo "Drive $usbdev allowed to exec, running $path_ts"
        echo "Running $path_ts"
        $path_ts
        exit
      else 
        # Remount with `rw,uid=$(id -u),gid=$(id -g),utf8` and run Tagasaurus.
        if [[ -n $(findmnt -t vfat,exfat -O noexec -O showexec -nr -o target -S "$usbdev" | sed 's/\\x20/ /g') ]]; then
          if [[ -n $(echo "$PWD" | grep "$usbmnt") ]]; then cd ~; fi
          remount_fat $usbdev $usbmnt 
          (($? != 0)) && { printf '%s\n' "Remount Error. Quit."; exit 1; }
          echo "Running $path_ts"
          $path_ts
          exit
        fi
      fi
    else

      # Find if TagasaurusFiles folder exist on root folder of certain USB drive mount, if yes - ask for Tagasaurus download, then run.
      path_tsfiles=$(find "$usbmnt" -maxdepth 1 -type d -iname "TagasaurusFiles"); [[ -n $path_tsfiles ]] && echo "TagasaurusFiles data folder exist: $path_tsfiles"
      if [[ -n $(findmnt -t vfat,exfat -O exec -nr -o target -S "$usbdev" | sed 's/\\x20/ /g') ]]; then
        echo "Drive $usbdev allowed to exec." 
        ts_download "$usbmnt"
        path_ts=$(find "$usbmnt" -maxdepth 2 -type f -iname "tagasaurus")
        echo "Running $path_ts"
        $path_ts
        exit
      else 
        # Remount with with `rw,uid=$(id -u),gid=$(id -g),utf8`, then ask for download Tagasaurus and run.
        if [[ -n $(findmnt -t vfat,exfat -O noexec -O showexec -nr -o target -S "$usbdev" | sed 's/\\x20/ /g') ]]; then
          echo "Drive $usbmnt not allowed to exec."
          if [[ -n $(echo "$PWD" | grep "$usbmnt") ]]; then cd ~; fi
          remount_fat $usbdev $usbmnt
          (($? != 0)) && { printf '%s\n' "Remount Error. Quit."; exit 1; }
          ts_download "$usbmnt"
          path_ts=$(find "$usbmnt" -maxdepth 2 -type f -iname "tagasaurus")
          echo "Running $path_ts"
          $path_ts
          exit
        fi
      fi
    fi
    mounted=$usbmnt
    if [[ -n $path_ts ]]; then $path_ts; else echo "Tagasaurus on $usbmnt not found."; fi
done

if [[ -z "$mounted" ]]; then echo "No USB drives with FAT/exFAT mounted."; fi