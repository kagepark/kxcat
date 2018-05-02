#!/bin/bash
###########################################################
# License : GPL
###########################################################
#set +x

error_exit() {
   echo $*
   exit 1
}

update_scripts() {
   local home_path
   home_path=$1
   for ii in state_update kxcatboot syslog;do
       [ -f $home_path/share/$ii ] && cp -a $home_path/share/$ii /install/postscripts/$ii
   done
   for ii in 0000_update_state 0001_bmc_set  0001_cleanyum  0002_mpi_net  0003_ntp; do
       [ -f $home_path/share/$ii ] && cp -a $home_path/share/$ii /install/postscripts/xcat_boot.d/$ii
   done
   for ii in 0000_home_mount;do
       [ -f $home_path/share/$ii ] && cp -a $home_path/share/$ii /global/xcat_boot.d/global/$ii
   done
}

if [ "$1" == "force" ]; then
   _KXCAT_HOME=$(dirname $(readlink -f $0))
   git reset --hard HEAD
   git clean -f -d
   git fetch -all
   sed -i "/^_KXC_VERSION=/c \
_KXC_VERSION=$(git describe --tags) " $_KXCAT_HOME/../bin/kxcat
   update_scripts $_KXCAT_HOME
   exit
fi
if [ -f /etc/profile.d/kxcat.sh ]; then
   . /etc/profile.d/kxcat.sh
   cd $_KXCAT_HOME
   git pull
   sed -i "/^_KXC_VERSION=/c \
_KXC_VERSION=$(git describe --tags) " $_KXCAT_HOME/bin/kxcat
   update_scripts $_KXCAT_HOME
else
   echo "/etc/profile.d/kxcat.sh not found"
fi
