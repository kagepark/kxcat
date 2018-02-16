#!/bin/bash
###########################################################
# Kage Park
# xCAT Installer
# Re-designed at 10/06/2017 by Kage Park
# Base design Using old libraries(2006/07) of Kage
# License : GPL
###########################################################
#set +x

error_exit() {
   echo $*
   exit 1
}

if [ -f /etc/profile.d/kxcat.sh ]; then
   cd $_KXCAT_HOME
   git pull
   sed -i "/^_KXC_VERSION=/c \
_KXC_VERSION=$(git describe --tags) " $_KXCAT_HOME/bin/kxcat
else
   echo "/etc/profile.d/kxcat.sh not found"
fi
