I see a lot of questions in different discord channels about how people handle their Minecraft backups, so I thought I would take a moment to share my solution which is fully host agnostic (so long as the host provide SFTP, which most), a can take backups without taking your server offline. Backups are done as differentials (only what has changed), so they are quick, and you can restore any single file from any point in time (as far back as you keep backups) without restoring the entire backup.

To begin, my solution is a shell script that runs in linux and can be run from a home computer, or cloud vps so long as they have enough storage for your backup. I am using my digital ocean droplet where my webserver lives and I bought their attached storage solution, so if the vps goes down, my backups aren't lost, I also take weekly backups of the droplet and the attached storage through digital oceans provided backup solutions for an additional level of redundancy. On to the actual script.

The script itself relies on three dependencies: 

* rdiff-backup - the actual backup tool
* sshfs - mount SFTP as a folder locally
* mcrcon - talk to your server over rcon

Without any one of these, this solution will not work. Lets start with rdiff-backup, this tool what actually takes the differential backups. However, unlike most differential, rdiff uses reverse differentials, meaning it stores the newest copy of the file, and keeps diffs of the changes going backwards in time. This makes restoring the most recent copy of a file faster, as you don't have to restore the original, and apply all the differentials to get the most recent. If you want to restore a file further back in time, it will automatically apply those differentials and present you with the file from that point in time. Next we have sshfs, which is exactly what is on the tin. It allows you to mount a remount SFTP or SCP connection as a local file share so that other commands can treat them as local files. Once mounted local, rdiff-backup can make a backup of those files to the folder you want. Technically speaking, rdiff-backup does offer the ability to connect to remote hosts it self, however, most Minecraft hosts do not support those, as they do not provide full ssh shells. Last is mcrcon, which is a commandline rcon utility that is used in the script to turn off world saving, initiate a world save, and then run the backup. This is done so the the world files are not being actively written to during the backup. Once the backup is complete, world saving is re-enabled.

Now for the script. There are two parts to the script, the actual backup script, and a variables file for each server you want to backup.

Backup Script: [backup-rdiff.sh](https://backup-rdiff.sh)



The variable file: [variables-server1.sh](https://variables-server1.sh)


Usage of the command is simple. First create/update your variables file with your host/server information. In the above example, every line is commented so that what goes there should make sense. Then simply execute the backup script and pass the variables file to it as a parameter:

    ./backup-rdiff.sh variables-server1.sh

In it's current form, the script sends an in game message to the server being backed up, and a message to a channel named #backup-log in discord via discordsrv. Any of those messages can be disabled by commenting out the associated bkrcon lines.