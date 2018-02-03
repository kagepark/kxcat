error_exit() {
   echo $*
   exit 1
}
[ "$(id -u)" == "0" ] || error_exit "it need root account"
echo -n "Are you sure remove xCAT and KxCAT (y/[n])?"
read dx
[ "$dx" == "y" ] || error_exit "stopped uninstall"
xcat_profile=$(dirname $(dirname $0))/etc/xcat.sh
kxcat_profile=/etc/profile.d/kxcat.sh
[ -f $xcat_profile ] || error_exit "xcat profile not found"
[ -f $kxcat_profile ] || error_exit "kxcat profile not found"
. $xcat_profile
. $kxcat_profile

#echo "Backup DB"
#dumpxCATdb -p xcat.db
#lsdef -z all > xcat.db.log
#lsdef -z -t site >> xcat.db.log
#lsdef -z -t network -l >> xcat.db.log
echo "Power off whole nodes"
nodeset all offline 
echo "Remove nodes"
for ii in $(kxcat groups | awk '{print $1}'); do
   makedhcp -d $ii
   makehosts -d $ii
done
makedns -n
echo "Stop daemons"
systemctl stop xcatd 
systemctl stop dhcpd
systemctl stop nfs
systemctl stop httpd
echo "Uninstall xCAT"
rpm -e $(echo $(rpm -qa |grep -i xcat)) xnba-undi
echo "clean up"
rm -fr ~/.xcat
rm -fr /install
rm -fr /tftpboot
rm -fr /etc/xcat
rm -fr /etc/sysconfig/xcat
rm -f /etc/profile.d/xcat.*
rm -fr /tmp/genimage*
rm -fr /tmp/packimage*
rm -fr /tmp/mknb*
rm -f /etc/profile.d/kxcat.sh
rm -fr /opt/xcat
rm -f /var/lib/dhcpd/dhcpd.leases
touch /var/lib/dhcpd/dhcpd.leases
