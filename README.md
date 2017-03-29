# Sya

Sya is a very basic frontend to [`borg`][1]. Its goal is to
provide easy management of multiple independant backup tasks.

 [1]: https://borgbackup.readthedocs.io/

## Overview

`borg` is a deduplicating backup program supporting encryption. A repository
contains archives which may refer to multiple machine being backed up or
multiple backups going back in time of the same machine, or a mix of both.

`sya` is a script aimed at easing the management of backup jobs. It is a basic
frontend to the `borg` command line. It consists of the main script and a
configuration directory containing a main config file and additional elements.

## Configuration

### General

The configuration directory (default is `/etc/sya`) contains the main
configuration file `config`. IT follows an INI-style syntax.

### `sya` section

This section makes it easy to configure general runtime items.

    [sya]
    verbose = True

### Backup task section

The backup task section contains a backup task definition. The following
configuration values are accepted in a task file :

* `run_this` : This globally enables or disables the task.
* `repository` : the path to the repository to backup to. Prefix with `host:`
  to backup over SSH.
* `include_file` : a full path (or relative to the configuration directory)
  to a file that lists what paths to include in the backup.
* `exclude_file` : files to exclude from the backup. See `borg` patterns.
* `pre` : execute this in the `bash` shell before executing the backup task.
* `post` : execute this after the backup task.
* `keep-daily` : how many daily archives to keep when pruning.
* `keep-weekly` : how many weekly archoves to keep when pruning.
* `keep-monthly` : how many monthly archives to keep when pruning.
* `passphrase_file` : a file containing on the first line the passphrase used
  to encrypt the backup repository (`borg init -e repokey`)
* `remote-path` : the path to the borg executable on the remote machine.

Example task section :

    [example]
    run_this = yes # enable this task
    #pre = mount -o remount,rw /backup
    #post = mount -o remount,ro /backup
    remote-path = /usr/local/bin/borg1/borg
    keep-daily = 30 # keep 30 daily archives
    keep-weekly = 8 # keep 8 weekly archives
    keep-monthly = 8 # keep 8 monthly archives
    repository = /tmp/local.borg
    include_file = tobackup.include
    passphrase_file = example.passphrase
    #exclude_file = local.exclude

Example exclude file `/etc/sya/local.exclude` :

    /var
    /proc
    /bin
    *.log

## Global pre and post scripts

There is also the possibility of running global pre and post scripts, i.e.
scripts that run before and after the task batch. Those are to put in the
configuration directory under the names of `pre.sh` and `post.sh`.

Example `pre.sh` :

    #!/bin/bash
    # This script is run before the backup task batch begins.
    # Feel free to customize it

    # Dump mysql data to a file
    mysqldump --user root --password=pass --all-databases > /var/backups/mysqldata base.dump

## Usage

`sya` accepts the following command-line options :

    -h, --help            show this help message and exit
    -v, --verbose         Be verbose and print stats.
    -p, --progress        Show progress.
    -c, --check           Perform a repository check for consistency.
    -d CONFDIR, --config-dir=CONFDIR
                            Configuration directory, default is /etc/sya.
    -t TASK, --task=TASK  Task to run, default is all.
    -n, --dry-run         Do not run backup, don't act.

## Installation (short)

`sya` may run in any directory, but it was made to be run in the following
way :

* Create the directory `/etc/sya` and config files.
* Drop the `sya` script in a `cron` directory if applicable, for example on
  Debian, I dropped it in `/etc/cron.daily` to make it run once a day. After
  a couple of days, you may want to put `verbose = False` in the config file
  to stop getting cron report emails.

## Installation (my setup)

This section describes my setup. The goal is to backup from `ripley` to
`backup1` and `backup2`.

### Password-less SSH logins

The first thing to do is to setup password-less SSH logins for the `root`
user to the hosts you want to backup to (or the hosts you want to backup
from, but I'll describe here how to use remote backup hosts to backup
*to*). First create a key pair for this purpose.

    # cd
    # mkdir .ssh
    # chmod 700 .ssh
    # ssh-keygen
    (no passphrase)

If, like me, you have aliases for your hosts and special ports, you may
want to use a `.ssh/config` file :

    Host backup1
    User backupuser
    Port 400
    HostName backupfool.foo1.org

    Host backup2
    User backupuser
    Port 400
    HostName backupguy.foo2.org

Now, copy your IDs to the remote hosts (repeat for `backup2`) :

    # ssh-copy-id -i ~/.ssh/id_rsa.pub backupuser@backup1
    Password:

Now you should be able to login with the local `root` user on `localhost`:

    # ssh backup1
    (no password prompted)
    backupuser@backupfool.foo1.org $

You can also make this key restricted to borg backups using an SSH forced
command, see borg documentation.

### sya configuration

So, here is the plan : I want to backup several selected directories
to a dedicated `/backup` partition and I want to backup only a part of
those selected directories to the remote hosts.

I run a mySQL server on `ripley`. Thus, I use `/etc/sya/pre.sh`
to dump the database contents to a file :

    #!/bin/bash
    mysqldump --user root --password=unbreakable_password --all-databases > /var/backups/mysqldatabase.dump

Then I described `/etc/sya/local.include` which is a list of
the things on `ripley` that I want to backup :

    /etc
    - **tmp
    /home/niol
    /root

Basically, I want to backup `/etc`, no files that end with `tmp`, my
personal directory.

But when backing up to a remot host, I want to omit some
files (some content that is too big) which I described in
`/etc/sya/remote.exclude`:

    /var/fileserv/

This was the most difficult part because you need to know what is
on your computer. But now, the only remaining thing is to describe
sya tasks.

`/etc/sya/config` :

    [sya]
    verbose = yes

    [local]
    run_this = yes
    keep-daily = 30
    keep-weekly = 8
    keep-monthly = 8
    repository = /backup/local.borg
    include_file = tobackup.include
    exclude_file = local.exclude

    [backup1]
    run_this = yes
    keep-daily = 10
    keep-weekly = 2
    keep-monthly = 1
    repository = backup1:/home/niol/fromripley.borg/
    include_file = tobackup.include
    passphrase_file = backup1.passphrase

    [backup2]
    run_this = yes
    keep-daily = 10
    keep-weekly = 2
    keep-monthly = 1
    repository = backup2:/home/niol/fromripley.borg/
    include_file = tobackup.include
    passphrase_file = backup2.passphrase

This should be self explainatory and this should show what `sya` is about.

### Setting up the repositories

`borg` needs the repositories to be initialized:

    # borg init -e none /backup/local.borg
    # borg init -e repokey backup1:/home/niol/fromripley.borg
    # borg init -e repokey backup2:/home/niol/fromripley.borg

### Running the script

The first run should be a bit long :

    # /etc/cron.daily/sya -v -p

From now on, you can check on the remote hosts which archives are available:

    # borg list backup1:/home/niol/fromripley.borg
    ripley-2016-09-25_05:11:26           Sun, 2016-09-25 05:11:28
    ripley-2016-09-29_04:31:02           Thu, 2016-09-29 04:31:05
    ripley-2016-09-30_04:29:02           Fri, 2016-09-30 04:29:04
    ripley-2016-10-01_10:30:38           Sat, 2016-10-01 10:30:39
    ripley-2016-10-02_04:28:56           Sun, 2016-10-02 04:28:58
    ripley-2016-10-03_04:45:06           Mon, 2016-10-03 04:45:08
    ripley-2016-10-04_04:30:18           Tue, 2016-10-04 04:30:21
    ripley-2016-10-05_04:30:20           Wed, 2016-10-05 04:30:23
    ripley-2016-10-06_04:36:09           Thu, 2016-10-06 04:36:13
    ripley-2016-10-07_04:32:25           Fri, 2016-10-07 04:32:29
    ripley-2016-10-08_04:34:33           Sat, 2016-10-08 04:34:36

And which files are available in thos archives:

    # borg list backup1:/home/niol/fromripley.borg::ripley-2016-09-25_05:11:26 | less

And recover an old file:

    # borg extract backup1:/home/niol/fromripley.borg::ripley-2016-09-25_05:11:26 etc/hosts

### Tips: migrating a remote backup by taking advantage of deduplication

If you want to migrate a remote backup to this solution, deduplication
can really help, for instance from an rdiff-backup backup located in
`fromripley` to a borg repository located in `fromripley.borg/`:

    (if not done before) $ borg init -e repokey fromripley.borg
    user@backup1$ borg create -v -s -p fromripley.borg/::1stbackup fromripley/* --exclude fromripley/rdiff-backup-data

    Synchronizing chunks cache...
    Archives: 0, w/ cached Idx: 0, w/ outdated Idx: 0, w/o cached Idx: 0.
    Done.
    ------------------------------------------------------------------------------  
    Archive name: 1stbackup
    Archive fingerprint: 6457fd3b13f37b9803c615f9cd4a96e43389d615ec2bfe292ea38d39a25c36c9
    Time (start): Sat, 2016-09-24 20:52:04
    Time (end):   Sat, 2016-09-24 21:36:26
    Duration: 44 minutes 21.45 seconds
    Number of files: 56608
    ------------------------------------------------------------------------------
                           Original size      Compressed size    Deduplicated size
    This archive:               42.82 GB             42.82 GB             41.18 GB
    All archives:               42.82 GB             42.82 GB             41.18 GB

                           Unique chunks         Total chunks
    Chunk index:                   58201                69187
    ------------------------------------------------------------------------------
    user@backup1$ rm -r .cache/borg
    user@backup1$ rm -r fromripley 

Then, you won't need to transfer those 40Gib on the WAN because known chunks
from your import of the rdiff-backup data will be deduplicated:

    root@ripley # /etc/cron.daily/sya -t backup1 -v
    ------------------------------------------------------------------------------
    Archive name: ripley-2016-09-25_04:28:12
    Archive fingerprint: d0e1a9ce562fa90f34e68a2d8a0c78fb34a94626fe1f6569dc0f00e35c58c59b
    Time (start): Sun, 2016-09-25 04:28:30
    Time (end):   Sun, 2016-09-25 05:10:58
    Duration: 42 minutes 28.58 seconds
    Number of files: 62390
    ------------------------------------------------------------------------------
                        Original size      Compressed size    Deduplicated size
    This archive:               43.10 GB             43.10 GB            313.95 MB
    All archives:               85.92 GB             85.93 GB             41.50 GB

                        Unique chunks         Total chunks
    Chunk index:                   63868               144211
    ------------------------------------------------------------------------------
