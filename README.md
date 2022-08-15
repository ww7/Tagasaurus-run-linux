# How to run

## From locall folder on USB or other storage
```sh
# cd to folder where script placed, then run:
cp ./tagasaurus-run.sh /tmp && source /tmp/tagasaurus-run.sh $PWD

# download script to current folder:
wget -q https://raw.githubusercontent.com/ww7/Tagasaurus-run-linux/main/tagasaurus-run.sh
```




## "HTTP" script version, that run script directly from Github
```sh
# script downloading and running
source <(wget -qO- https://raw.githubusercontent.com/ww7/Tagasaurus-run-linux/main/tagasaurus-run-http.sh)
```

"HTTP" script version searching Tagasaurus over all USB drives mounted with FAT filesystem, then check if that USB drive doesn't allow program executing and remount with proper permissions for run.

Also, if found TagasaurusFiles data folder on USB drive and no Tagasaurus itself – propose to download.

Script can be easily extended for Tagasaurus updating to the latest version and for downloading to specified path (as script argument) or to first corresponding USB drive found on system.

# Note
Remounting require a `sudo`. It will ask a user password.