error_exit() {
   echo $*
   exit 1
}
[ "$(id -u)" == "0" ] || error_exit "it need root account"
echo -n "Are you sure remove xCAT and KxCAT (y/[n])?"
read dx
[ "$dx" == "y" ] || error_exit "stopped uninstall"

dumpxCATdb -p xcat.db
lsdef -z all
lsdef -z -t network -l
nodeset all offline
. /etc/profile.d/kxcat.sh
for ii in $(kxcat groups | awk '{print $1}'); do
   makedhcp -d $ii
done
makedns -n
systemctl stop xcatd 
rpm -e $(echo $(rpm -qa |grep -i xcat))
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
