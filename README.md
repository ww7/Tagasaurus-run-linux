### Run
```sh
wget -qO- https://raw.githubusercontent.com/ww7/Tagasaurus-run-linux/main/tagasaurus-run.sh | bash
```

### Description
The script searching Tagasaurus over all USB drives mounted with FAT filesystem, then check if that USB drive don't allowed to execute and remount with proper permissions for run.

Also if found TagasaurusFiles data folder on USB drive and no Tagasaurus itself – propose to download.

Script can be easily extended for Tagasaurus updating to latest version and for downloading to specified path (as script argument) or to first corresponding USB drive found on system.


### Note
Remounting require a `sudo` (or running from `root`). It will ask a user password.