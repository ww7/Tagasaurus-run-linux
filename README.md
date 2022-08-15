## Description
Script to run Tagasaurus on Linux, with remounting storage if it mounted without required permissions.

The script aimed to solve Linux restriction to run (exec) programs from vfat/exfat (Windows) filesystems that mounted automatically.

It doesn't change any system settings, only remounting filesystem (USB drive or local disk) with corresponding permissions (removing `showexec`,`noexec`, set correct ID etc).

Script will found and run Tagasaurus from current or above directory. Also path to Tagasaurus can be passed as script argument.

Version with `http` prefix searching Tagasaurus on all mounted USB storages and can be called without script downloading and storing locally, also asking Tagasaurus downloading if found `TagasaurusFiles` data folder, but not application itself. Can be used for Tagsasaurus updating.

Remounting require a `sudo`. It will ask a user password.

## Script to run from local folder on USB or other storage

```sh
# download script to current folder:
`wget -q https://raw.githubusercontent.com/ww7/Tagasaurus-run-linux/main/tagasaurus-run.sh`
```

Script looking Tagasaurus in the current and above directory. 
If script placed in parent directory - will search all Tagasaurus folders and runs the first valid.

```sh
# if script placed in Tagasaurus or parent folder:
`cp ./tagasaurus-run.sh /tmp && source /tmp/tagasaurus-run.sh $PWD`
```

Using `source` method allows unmount filesystem when it opened, script will change current directory to $HOME and unmount filesystem properly.

Using `$PWD` allows pass initial folder that alongside Tagasaurus to the script, to know where Tagasaurus should be found.

### Passing custom path to Tagasaurus search and run

Script can run Tagasaurus from specified path, USB drive, parent folder, when it passed as argument.

```sh
# if script placed on target filesystem that needs to be remounted
cp ./tagasaurus-run.sh /tmp && source /tmp/tagasaurus-run.sh "path to Tagasaurus"
```

```sh
# If script placed outside of filesystem that should be remounted (vfat/exfat) and current directory (PWD) not on it: 
./tagasaurus-run.sh "path to Tagasaurus"
# or
bash "path of script/"tagasaurus-run.sh "path to Tagasaurus"
```


## "HTTP" script version, that runs script directly from Github
```sh
# script downloading and running
source <(wget -qO- https://raw.githubusercontent.com/ww7/Tagasaurus-run-linux/main/tagasaurus-run-http.sh)
```

"HTTP" script version searching Tagasaurus over all USB drives mounted with FAT filesystem, then check if that USB drive doesn't allow program executing and remount it with proper permissions for run.

Also, if found TagasaurusFiles data folder on USB drive and no Tagasaurus itself – propose to download.

Script can be easily extended for Tagasaurus updating to the latest version and for downloading to specified path.

