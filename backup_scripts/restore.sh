#!/bin/bash

deps="rsync"

function setup_toolbox()
{
	if toolbox list | grep -q "running"
	then
		return
	fi
	toolbox create -y
}

function run_cmd()
{
	if [ -z "$CMD_PREFIX" ]
	then
		$@
	else
		$CMD_PREFIX $@
	fi
}
BACKUP_PROMPT="yes"
while getopts p opt
do
	case $opt in
		e)
			BACKUP_PROMPT=""
			;;
		\?)
			echo "fuck you doing???"
			exit 1
			;;
	esac
done

VARIANT_ID=$(grep VARIANT_ID /etc/os-release | sed 's/VARIANT_ID=//')
if [ $VARIANT_ID = "silverblue" ]
then
	echo "System is using silverblue"
	CMD_PREFIX="toolbox run"
	setup_toolbox
fi
installed_deps=$(run_cmd dnf list installed | grep -E ${deps// /|})
to_be_installed=""
for d in $deps
do
	if echo $installed_deps | grep -q $d
	then
		continue
	fi
	echo "Missing $d, installing"
	to_be_installed="$to_be_installed $d"
done

if [ -z to_be_instaleld ]
then
	run_cmd sudo dnf install to_be_installed
else
	echo "All deps met!"
fi

ERR=""

if [ -z $BACKUP_LOCAL_DIR ]
then
	if [ -z $BACKUP_PROMPT ]
	then
		echo "Please set BACKUP_LOCAL_DIR variable"
		ERR="yes"
	else
		echo "Input local dir:"
		read BACKUP_LOCAL_DIR
	fi
fi

if [ -z $BACKUP_REMOTE_DIR ]
then
	if [ -z $BACKUP_PROMPT ]
	then
		echo "Please set BACKUP_REMOTE_DIR variable"
		ERR="yes"
	else
		echo "Input remote dir:"
		read BACKUP_REMOTE_DIR
	fi
fi

if [ -z $BACKUP_REMOTE_HOST ]
then
	if [ -z $BACKUP_PROMPT ]
	then
		echo "Please set BACKUP_REMOTE_HOST variable"
		ERR="yes"
	else
		echo "Input remote host:"
		read BACKUP_REMOTE_HOST
	fi
fi

if [ -z $BACKUP_REMOTE_USER ]
then
	if [ -z $BACKUP_PROMPT ]
	then
		echo "Please set BACKUP_REMOTE_USER variable"
		ERR="yes"
	else
		echo "Input remote user:"
		read BACKUP_REMOTE_USER
	fi
fi

if [ ! -z $ERR ]
then
	exit 0
fi
echo "All deps are met, starting restore"
run_cmd "rsync -a --info=progress2 $BACKUP_REMOTE_USER@$BACKUP_REMOTE_HOST:$BACKUP_REMOTE_DIR $BACKUP_LOCAL_DIR"
