% SYA(1)
% Alexandre Rossi

# NAME

sya - basic frontend to borgbackup

# SYNOPSIS

**sya** [**-h**] [**-d**] **SUBCOMMAND**

# DESCRIPTION

`sya` is a script aimed at easing the management of backup jobs. It is a basic
frontend to the `borg` command line. It consists of the main script and a
configuration directory containing a main config file and additional elements.

# OPTIONS

These programs follow the usual GNU command line syntax, with long
options starting with two dashes (\`-\'). A summary of options is
included below. For a complete description, see the `-h` switch.

`-d`

: Enable DEBUG level logging.

`-h` `--help`

: Show summary of options.

# CONFIGURATION FILE

See /usr/share/doc/sya/README.md.gz

# FILES

`/lib/systemd/system/sya.service`

: SystemD service file.

`/etc/sya/config`

: Configuration file

`$XDG_CONFIG_HOME/sya/config`

: User configuration file

# SEE ALSO

More information is available on the program website:
`https://sml.zincube.net/~niol/repositories.git/sya/about/`.

# AUTHOR

This manual page was written for the DEBIAN system (but may be used by
others). Permission is granted to copy, distribute and/or modify this
document under the terms of the GNU General Public License, Version 2
any later version published by the Free Software Foundation.

On Debian systems, the complete text of the GNU General Public License
can be found in /usr/share/common-licenses/GPL.
