#!/bin/sh
###########################################################
# Kage Park
# xCAT Installer
# Re-designed at 10/06/2017 by Kage Park
# Base design Using old libraries(2006/07) of Kage
# License : GPL
###########################################################
set -x

error_exit() {
   echo $*
   exit 1
}
_KXCAT_HOME=$(dirname $(dirname $(readlink -f $0)))

[ -f $_KXCAT_HOME/lib/klib.so ] || error_exit "klib.so file not found"
. $_KXCAT_HOME/lib/klib.so
[ -f $_KXCAT_HOME/etc/kxcat.cfg ] || error_exit "kxcat.cfg file not found"
. $_KXCAT_HOME/etc/kxcat.cfg

MGT_IP=$(_k_net_add_ip $GROUP_NETWORK 1)

# temporary disable
init() {
  hostname $MGMT_HOSTNAME
  domainname $DOMAIN_NAME
  if [ -f /etc/hostname ]; then
      grep "^$MGMT_HOSTNAME$" /etc/hostname >& /dev/null || echo "$MGMT_HOSTNAME" > /etc/hostname
  fi
  if ! grep "^$MGT_IP  $MGMT_HOSTNAME" /etc/hosts >& /dev/null; then
     echo "$MGT_IP  $MGMT_HOSTNAME  ${MGMT_HOSTNAME}.${DOMAIN_NAME}" >> /etc/hosts
  fi
  echo "search $DOMAIN_NAME
nameserver $MGT_IP
$([ -n "$DNS_OUTSIDE" ] && echo nameserver $DNS_OUTSIDE)" > /etc/resolv.conf
  echo "export PATH=\${PATH}:$_KXCAT_HOME/bin" > /etc/profile.d/kxcat.sh
  . /etc/profile.d/kxcat.sh
  systemctl disable firewalld
  systemctl disable libvirtd
  systemctl disable NetworkManager
  if [ -f /etc/sysconfig/selinux ]; then
    grep -v "^#" /etc/sysconfig/selinux  | grep enforcing >& /dev/null && sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux
  fi
  [ "$(getenforce)" == "Disabled" ] || setenforce 0

  #ARP FIX
  echo 512 > /proc/sys/net/ipv4/neigh/default/gc_thresh1
  echo 2048 > /proc/sys/net/ipv4/neigh/default/gc_thresh2
  echo 4096 > /proc/sys/net/ipv4/neigh/default/gc_thresh3
  echo 240 > /proc/sys/net/ipv4/neigh/default/gc_stale_time

  echo 268435456 > /proc/sys/kernel/shmmax
  echo 1048576 > /proc/sys/net/core/wmem_max
  echo 8388608 > /proc/sys/net/core/rmem_max

  if ! grep "^### HPC_KXCAT_ENV ###" /etc/sysctl.conf >& /dev/null; then
     echo "
### HPC_KXCAT_ENV ###
net.ipv4.conf.all.arp_filter = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.neigh.default.gc_thresh1 = 512
net.ipv4.neigh.default.gc_thresh2 = 2048
net.ipv4.neigh.default.gc_thresh3 = 4096
net.ipv4.neigh.default.gc_stale_time = 240
net.core.rmem_max = 524288
net.core.rmem_default = 262144
     " >> /etc/sysctl.conf
   fi

  if ! grep "hard    memlock            unlimited$" /etc/security/limits.conf >& /dev/null; then
     echo '
  *               soft    memlock            unlimited
  *               hard    memlock            unlimited
     ' >> /etc/security/limits.conf
  fi

  echo 524288 > /proc/sys/net/core/rmem_max
  echo 262144 > /proc/sys/net/core/rmem_default

  [ -f /usr/sbin/rsct/bin/rmcctrl ] && /usr/sbin/rsct/bin/rmcctrl -k
  [ -f /usr/sbin/rsct/bin/rmcctrl ] && /usr/sbin/rsct/bin/rmcctrl -s
}


xcat_install() {
  ping -c 2 www.google.com  >& /dev/null || error_exit "Please setup outside network for auto installation for xCAT"
  yum -y install dhcp dhcp-common dhcp-libs ntp nfs 
  systemctl stop dhcpd
  yum erase libvirt-client
  [ -f ./go-xcat ] && rm -f go-xcat
  wget https://raw.githubusercontent.com/xcat2/xcat-core/master/xCAT-server/share/xcat/tools/go-xcat -O - > /tmp/go-xcat
  chmod +x /tmp/go-xcat
  /tmp/go-xcat install
  rm -f /tmp/go-xcat
  [ -f /etc/profile.d/xcat.sh ] || error_exit "/etc/profile.d/xcat.sh file not found"
  mv /etc/profile.d/xcat.* $_KXCAT_HOME/etc
}

xcat_env() {
  # Patch post.xcat file
echo "/opt/xcat/share/xcat/install/scripts/post.xcat debug"
read x
  if [ -f /opt/xcat/share/xcat/install/scripts/post.xcat ]; then
     if ! grep "^#KG post fix" /opt/xcat/share/xcat/install/scripts/post.xcat >&/dev/null; then
        mv /opt/xcat/share/xcat/install/scripts/post.xcat /opt/xcat/share/xcat/install/scripts/post.xcat.orig
        echo "#KG post fix
if [ -d /etc/systemd/system ]; then 
  for ii in initial-setup.service initial-setup-text.service initial-setup-graphical.service firewalld.service libvirtd.service; do
    for jj in multi-user.target.wants graphical.target.wants; do
      if [ -f /etc/systemd/system/\$jj/\$ii ]; then
         rm -f /etc/systemd/system/\$jj/\$ii && echo \"rm /etc/systemd/system/\$jj/\$ii\" >> /tmp/ks.postinstall.log
      fi
    done
  done
fi
        " > /opt/xcat/share/xcat/install/scripts/post.xcat
        cat /opt/xcat/share/xcat/install/scripts/post.xcat.orig >> /opt/xcat/share/xcat/install/scripts/post.xcat
        chmod +x /opt/xcat/share/xcat/install/scripts/post.xcat
     fi
   else
     echo "/opt/xcat/share/xcat/install/scripts/post.xcat file not found"
     read x
   fi

  if ! grep "^#KG Added boot feature." /install/postscripts/xcatpostinit1.install >&/dev/null; then
     nn=$(($(grep -n "^esac$" /install/postscripts/xcatpostinit1.install | awk -F: '{print $1}') - 1))
     sed -i "${nn}i\
\
\
#KG Added boot feature. \n\
if [ -f \/xcatpost\/kxcatboot \]\; then\n\
   chmod +x \/xcatpost\/kxcatboot\n\
   \/xcatpost\/kxcatboot \> \/tmp\/kxcatboot.log \n\
fi\
     " /install/postscripts/xcatpostinit1.install
  fi
  if ! grep "^#KG Added boot feature." /install/postscripts/xcatpostinit1.netboot >&/dev/null; then
     nn=$(($(grep -n "^esac$" /install/postscripts/xcatpostinit1.netboot | awk -F: '{print $1}') - 1))
     sed -i "${nn}i\
\
\
#KG Added boot feature. \n\
if [ -f \/xcatpost\/kxcatboot \]\; then\n\
   chmod +x \/xcatpost\/kxcatboot\n\
   \/xcatpost\/kxcatboot \> \/tmp\/kxcatboot.log \n\
fi\
     " /install/postscripts/xcatpostinit1.netboot
  fi
  if ! grep "^#KG disable mypostscript.<node>" /install/postscripts/xcatdsklspost >& /dev/null; then
      sed -i "/# try short hostname first/a\
#KG disable mypostscript.<node> \n\
node_short=" /install/postscripts/xcatdsklspost
  fi

  source $_KXCAT_HOME/etc/xcat.sh
  cp -a $_KXCAT_HOME/share/kxcatboot /install/postscripts
  [ -d /install/postscripts/kxcat_boot.d ] || mkdir -p /install/postscripts/kxcat_boot.d
  cp -a $_KXCAT_HOME/share/0000_update_state /install/postscripts/kxcat_boot.d
  cp -a $_KXCAT_HOME/share/0001_cleanyum /install/postscripts/kxcat_boot.d
  [ -d /global/kxcat_boot.d/global ] || mkdir -p /global/kxcat_boot.d/global
  if ! grep "^/global" /etc/exports >& /dev/null; then
     echo "/global *(rw,no_root_squash,sync,no_subtree_check)" >> /etc/exports
     exportfs -ra
  fi
  lsxcatd -a

  root_pass=$(awk -F: '{if($1=="root") print $2}' /etc/shadow)
  tabch key=system passwd.username=root passwd.password=$root_pass

  tabdump site
  chdef -t site -o clustersite domain=$DOMAIN_NAME
  chdef -t site forwarders=$MGT_IP
  makedns all 2>/dev/null

  chtab key=master site.value=$MGT_IP
  chtab key=dhcpinterfaces site.value=$GROUP_NET_DEV
  network_name=$(tabdump networks | grep $GROUP_NET_DEV | awk -F\" '{print $2}')
  [ -n "$network_name" ] || error_exit "network_name not found for $GROUP_NET_DEV device"
  DHCP_IP_RANGE=$(_k_net_add_ip $GROUP_NETWORK $((65279-$(($MAX_NODES * 2)))))-$(_k_net_add_ip $GROUP_NETWORK 65279)
  chtab netname=$network_name networks.net=$GROUP_NETWORK networks.mask=$GROUP_NETMASK networks.mgtifname=$GROUP_NET_DEV networks.dhcpserver=$MGT_IP networks.tftpserver=$MGT_IP networks.nameservers=$MGT_IP networks.dynamicrange=$DHCP_IP_RANGE
  tabdump networks
  grep "^DHCPDARGS=" /etc/sysconfig/dhcpd >& /dev/null || echo "DHCPDARGS=\"$GROUP_NET_DEV\"" >> /etc/sysconfig/dhcpd

  makedhcp -n
  systemctl start dhcpd
  systemctl enable dhcpd
}

xcat_image() {
# OS Image
  source $_KXCAT_HOME/etc/xcat.sh
  source /etc/profile.d/kxcat.sh
  [ -f "$OS_ISO" ] || error_exit "$OS_ISO file not found"
  copycds $OS_ISO
  lsdef -t osimage
  base_image_str=$(tabdump osimage | sed "s/\"//g" | awk -F, '{if($6=="install") printf "%s,%s", $1,$13}')
  base_image=$(echo $base_image_str | awk -F, '{print $1}')
  base_arch=$(echo $base_image_str | awk -F, '{print $2}')
  kxcat create sys $base_image install
} 

init
xcat_install
xcat_env
xcat_image


# Add Nodes
for ((srv_snum=1; srv_snum<=$MAX_NODES; srv_snum++)); do
   srv_name=node-$(printf "%05d" $srv_snum)
   echo "Setup $srv_name"
   srv_mac="00:00:00:00:00:00"
   srv_info=$([ -f server_list.cfg ] && grep "^${srv_snum}|" server_list.cfg | awk -F\| '{print $2}') 
   [ -n "$srv_info" ] && srv_mac=$srv_info
   mkdef -t node $srv_name groups=all,nodes id=$srv_snum arch=$base_arch bmc=$(_k_net_add_ip $BMC_NETWORK $srv_snum) bmcusername=$BMC_USER bmcpassword=$BMC_PASS mac=$srv_mac mgt=ipmi netboot=xnba provmethod=$base_image
done

makehosts all 2>/dev/null

