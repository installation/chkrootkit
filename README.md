Chkrootkit
==========

Chkrootkit install script

Installs all dependencies using apt or yum

Tested on:
* CentOS 5.8/6.4
* Debian 6.0/7.0
* Fedora 17
* Ubuntu 10.04/12.04/12.10

Default temp dir is ````/tmp/chkrootkit````, this can be changed in install script.

By default, the installer logs into ````$TMP/install.log```` and ````$TMP/error.log````. Check these for further info about the installation process.

## Dependencies
* Package manager (apt or yum)
* HTTP Client (curl, wget or fetch)
* TAR executable
* Make
* GCC
* Mail (Debian/Ubuntu: mailutils, RHEL: mailx)

Dependencies will be installed during the progress, but installing them on your own is advised.

## Installation

Download and run ````install.sh YOUR@EMAIL.COM````

### Offline installation

Clone this repository or download ````install.sh```` and download the following file manually into the install script path:

[Chkrootkit Archive](ftp://ftp.pangeia.com.br/pub/seg/pac/chkrootkit.tar.gz)

Run ````install.sh YOUR@EMAIL.COM````

Create file ````/etc/cron.daily/chkrootkit.sh```` with execute permission, and paste the following content:
````
#!/bin/sh
( /usr/bin/chkrootkit ) | grep 'INFECTED|Vulnerable' | /bin/mail -E -s 'chrootkit Daily Run (HOSTNAME)' YOUR@EMAIL.COM
````

Note: You can run your cron jobs whenever you want.


For further info check [Official website](http://chkrootkit.org)