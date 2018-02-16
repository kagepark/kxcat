error_exit() {
   echo $*
   exit 1
}
_KXCAT_HOME=$(dirname $(dirname $(readlink -f $0)))
[ "$(id -u)" == "0" ] || error_exit "it need root account"
echo -n "Are you sure remove xCAT and KxCAT (y/[n])?"
read dx
[ "$dx" == "y" ] || error_exit "stopped uninstall"
xcat_profile=$_KXCAT_HOME/etc/xcat.sh
[ -f $xcat_profile ] || xcat_profile=/etc/profile.d/xcat.sh
[ -f $xcat_profile ] || error_exit "xcat profile not found"
. $xcat_profile
kxcat_profile=/etc/profile.d/kxcat.sh

echo "Backup DB"
backup_dir=$_KXCAT_HOME/backup
[ -d $backup_dir ] || mkdir $backup_dir
dumpxCATdb -p $backup_dir/xcat.db

echo "==site=="
lsdef -z -t site >> $backup_dir/xcat.info.log
echo "==network=="
lsdef -z -t network -l >> $backup_dir/xcat.info.log
if [ -f $kxcat_profile ]; then
  . $kxcat_profile
  echo "==nodes=="
  kxcat nodes >> $backup_dir/xcat.info.log
  echo "==hosts=="
  kxcat hosts >> $backup_dir/xcat.info.log
  echo "==Groups=="
  kxcat groups >> $backup_dir/xcat.info.log
  for ii in $(kxcat groups | awk '{print $2}'); do
     echo "==Group $ii=="
     kxcat groups $ii >> $backup_dir/xcat.info.log
  done
fi
echo "==all=="
lsdef -z all > $backup_dir/xcat.info.log

echo "Power off whole nodes"
nodeset all offline 
if [ -f $kxcat_profile ]; then
  . $kxcat_profile
  echo "Remove nodes"
  for ii in $(kxcat groups | awk '{print $1}'); do
     makedhcp -d $ii
     makehosts -d $ii
  done
fi
makedns -n
echo "Stop daemons"
systemctl stop xcatd 
systemctl stop dhcpd
systemctl stop nfs
systemctl stop httpd
echo "Uninstall xCAT"
rpm -e $(echo $(rpm -qa |grep -e xCAT -e "-xcat-" -e "-xCAT-" )) xnba-undi
echo "clean up"
rm -fr ~/.xcat
if [ -d /install ]; then
   mountpoint /install >& /dev/null && rm -fr /install/* || rm -fr /install
fi
if [ -d /tftpboot ]; then
   mountpoint /tftpboot >& /dev/null && rm -fr /tftpboot/* || rm -fr /tftpboot
fi
rm -fr /etc/xcat
rm -fr /etc/sysconfig/xcat
rm -f /etc/profile.d/xcat.*
rm -fr /tmp/genimage*
rm -fr /tmp/packimage*
rm -fr /tmp/mknb*
rm -f /etc/profile.d/kxcat.sh
rm -fr /opt/xcat
rm -fr /opt/kgt
rm -f /var/lib/dhcpd/dhcpd.leases
touch /var/lib/dhcpd/dhcpd.leases
