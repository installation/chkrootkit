#!/bin/bash

# Script to install Chkrootkit
# Author: Márk Sági-Kazár (sagikazarmark@gmail.com)
# This script installs Chkrootkit on several Linux distributions.
#
# Version: 0.49

# Variable definitions
DIR=$(cd `dirname $0` && pwd)
NAME="Chkrootkit"
SLUG="chkrootkit"
VER="0.49"
DEPENDENCIES=("tar" "make")
TMP="/tmp/$SLUG"
INSTALL_LOG="$TMP/install.log"
ERROR_LOG="$TMP/error.log"

# Cleaning up
rm -rf $TMP
mkdir -p $TMP
cd $TMP
chmod 777 $TMP


# Basic function definitions

## Echo colored text
e()
{
	local color="\033[${2:-34}m"
	local log="${3:-$INSTALL_LOG}"
	echo -e "$color$1\033[0m"
	log "$1" "$log"
}

## Exit error
ee()
{
	local exit_code="${2:-1}"
	local color="${3:-31}"

	clear
	e "$1" "$color" "$ERROR_LOG"
	exit $exit_code
}

## Log messages
log()
{
	local log="${2:-$INSTALL_LOG}"
	echo "$1" >> "$log"
}

## Add dependency
dep()
{
	if [ ! -z "$1" ]; then
		DEPENDENCIES+=("$1")
	fi
}


# Checking root access
if [ $EUID -ne 0 ]; then
	ee "This script has to be ran as root!"
fi

# CTRL_C trap
ctrl_c()
{
	clear
	echo
	echo "Installation aborted by user!"
	cleanup
}
trap ctrl_c INT

# Basic checks

## Check for wget or curl or fetch
e "Checking for HTTP client..."
if [ `which curl 2> /dev/null` ]; then
	download="$(which curl) -s -O"
elif [ `which wget 2> /dev/null` ]; then
	download="$(which wget) --no-certificate"
elif [ `which fetch 2> /dev/null` ]; then
	download="$(which fetch)"
else
	dep "wget"
	download="$(which wget) --no-certificate"
	e "No HTTP client found, wget added to dependencies" 31
fi

## Check for package manager (apt or yum)
e "Checking for package manager..."
if [ `which apt-get 2> /dev/null` ]; then
	install[0]="apt"
	install[1]="$(which apt-get) -y --force-yes install"
elif [ `which yum 2> /dev/null` ]; then
	install[0]="yum"
	install[1]="$(which yum) -y install"
else
	ee "No package manager found."
fi

## Check for package manager (dpkg or rpm)
if [ `which dpkg 2> /dev/null` ]; then
	install[2]="dpkg"
	install[3]="$(which dpkg)"
elif [ `which rpm 2> /dev/null` ]; then
	install[2]="rpm"
	install[3]="$(which rpm)"
else
	ee "No package manager found."
fi


# Function definitions

## Install required packages
install()
{
	[ -z "$1" ] && { e "No package passed" 31; return 1; }

	e "Installing package: $1"
	${install[1]} "$1" >> $INSTALL_LOG 2>> $ERROR_LOG || ee "Installing $1 failed"
	e "Package $1 successfully installed"

	return 0
}

## Check installed package
check()
{
	[ -z "$1" ] && { e "No package passed" 31; return 2; }

	case ${install[2]} in
		dpkg )
			${install[3]} -s "$1" &> /dev/null
			;;
		rpm )
			${install[3]} -qa | grep "$1"  &> /dev/null
			;;
	esac
	return $?
}

## Download required file
download()
{
	[ -z "$1" ] && { e "No package passed" 31; return 1; }

	local text="${2:-files}"
	e "Downloading $text"
	$download "$1" >> $INSTALL_LOG 2>> $ERROR_LOG || ee "Downloading $text failed"
	e "Downloading $text successfull"
	return 0
}

## Cleanup files
cleanup()
{
	cd $TMP 2> /dev/null || return 1
	find * -not -name '*.log' | xargs rm -rf
}


[ -z "$1" ] && ee "Please pass an email address as an argument"


# Adding dependencies
case ${install[2]} in
	dpkg )
		dep "glibc"
		dep "mailutils"
		;;
	rpm )
		dep "glibc-static"
		dep "mailx"
		;;
esac

# Checking dependencies
for dep in ${DEPENDENCIES[@]}; do
	check "$dep"
	[ $? -eq 0 ] || install "$dep"
done


e "Installing $NAME $VER"

if [ -f $DIR/chkrootkit.tar.gz ]; then
	cp $DIR/chkrootkit.tar.gz $TMP
else
	download ftp://ftp.pangeia.com.br/pub/seg/pac/chkrootkit.tar.gz "$NAME $VER files"
fi

tar -xvf chkrootkit.tar.gz >> $INSTALL_LOG 2>> $ERROR_LOG
cp -r chkrootkit-* /usr/src/chkrootkit
cd /usr/src/chkrootkit

make sense >> $INSTALL_LOG 2>> $ERROR_LOG || ee "Installing $NAME $VER failed"
chmod +x chkrootkit

[ -f /usr/bin/chkrootkit ] || ln -s /usr/src/chkrootkit/chkrootkit /usr/bin/chkrootkit

e "Installing cron script"
echo "#!/bin/sh
( /usr/bin/chkrootkit ) | grep 'INFECTED|Vulnerable' | /bin/mail -E -s 'chrootkit Hourly Run ($(hostname))' $1" >> /etc/cron.daily/chkrootkit.sh
chmod 755 /etc/cron.daily/chkrootkit.sh

clear

e "Cleaning up"
cleanup

e "It is recommended to run a scan on the file system by running chkrootkit | grep 'INFECTED|Vulnerable'"

if [ -s $ERROR_LOG ]; then
	e "Error log is not empty. Please check $ERROR_LOG for further details." 31
fi

e "Installation done."
