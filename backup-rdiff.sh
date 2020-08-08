#!/bin/bash
# Minecraft Backup Script
# usage: backup-rdiff.sh variables-server1.sh
# takes a variables file as a parameter
# if using in a cron, absolute path to variable file is required

source $1

#check if the dependencies exist, else exit
if ! command -v mcrcon &> /dev/null
then
    echo "mcrcon could not be found"
    exit 1
fi
if ! command -v rdiff-backup &> /dev/null
then
    echo "rdiff-backup could not be found"
    exit 1
fi
if ! command -v sshfs &> /dev/null
then
    echo "sshfs could not be found"
    exit 1
fi

#prepared function for rcon connection using mcrcon
function bkrcon {
        mcrcon -H $RCONHOST -p $RCONPASS -P $RCONPORT "$1"
}

#mount remote host as sshfs using fuse
if !( echo $SCPPASS | sshfs -o default_permissions $SCPUSER@$SCPHOST:/ $MNTPATH -p $SCPPORT -o password_stdin -o StrictHostKeyChecking=no )
then
  echo "Mounting $MNTPATH to $SCPUSER@$SCPHOST failed!"
  exit 1
fi

#message server and discord to inform of backup
bkrcon "say §l§4Beginning Backup. World saving temporarily stopped."
bkrcon "discord bcast #backup-log :observer::bangbang:**Beginning $SERVERNAME Backup. World saving temporarily stopped.**"

#turn off world saving so files are not in use, and force an immediate world save
bkrcon "save-off"
bkrcon "save-all"

#backup using RDIFF
if [ -z "$BKEXCLUDE" ]
then
        rdiff-backup -v0 $MNTPATH $BKPATH
else
        rdiff-backup -v0 --exclude $BKEXCLUDE $MNTPATH $BKPATH
fi

#purge old backups
rdiff-backup -v0 --remove-older-than $BKPURGE --force $BKPATH

#re-enable world saving
bkrcon "save-on"

#let ingame and discord know backup is complete
bkrcon "say §l§4Backup complete. World now saving."
bkrcon "discord bcast #backup-log :observer::bangbang:**$SERVERNAME Backup complete. World now saving.*"
bkrcon "discord bcast #backup-log :observer::bangbang:**$SERVERNAME Current Backup size:`du -hd 0 $BKPATH | awk '{print $1}'`"

#unmount remote server
fusermount -u $MNTPATH