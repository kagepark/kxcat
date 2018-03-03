#!/bin/bash
###########################################################
# License : GPL
###########################################################
#set +x

error_exit() {
   echo $*
   exit 1
}

if [ "$1" == "force" ]; then
   _KXCAT_HOME=$(dirname $(readlink -f $0))
   git reset --hard HEAD
   git clean -f -d
   git fetch -all
   sed -i "/^_KXC_VERSION=/c \
_KXC_VERSION=$(git describe --tags) " $_KXCAT_HOME/../bin/kxcat
   exit
fi
if [ -f /etc/profile.d/kxcat.sh ]; then
   . /etc/profile.d/kxcat.sh
   cd $_KXCAT_HOME
   git pull
   sed -i "/^_KXC_VERSION=/c \
_KXC_VERSION=$(git describe --tags) " $_KXCAT_HOME/bin/kxcat
else
   echo "/etc/profile.d/kxcat.sh not found"
fi
