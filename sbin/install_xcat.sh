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

link_name=$1
_KXCAT_HOME=$(dirname $(dirname $(readlink -f $0)))

[ -f $_KXCAT_HOME/lib/klib.so ] || error_exit "klib.so file not found"
. $_KXCAT_HOME/lib/klib.so
[ -f $_KXCAT_HOME/etc/kxcat.cfg ] || error_exit "kxcat.cfg file not found"
. $_KXCAT_HOME/etc/kxcat.cfg

[ ! -n "$OS_ISO" ] && error_exit "OS_ISO not found"
chk_iso=0
while read line; do
     if [ ! -f "$line" ]; then
         echo "$line not found"
         continue
     fi
     chk_iso=1
done < <(echo $OS_ISO | sed "s/,/\n/g")
[ "$chk_iso" == "0" ] && error_exit "OS_ISO file not found"

[ ! -n "$GROUP_NETWORK" ] && error_exit "GROUP_NETWORK not found"
[ ! -n "$GROUP_NETMASK" ] && error_exit "GROUP_NETMASK not found"
[ ! -n "$GROUP_NET_DEV" ] && error_exit "GROUP_NET_DEV not found"
[ ! -n "$DOMAIN_NAME" ] && error_exit "DOMAIN_NAME not found"
[ ! -n "$MGT_HOSTNAME" ] && error_exit "MGT_HOSTNAME not found"
[ ! -n "$MGT_IP" ] && error_exit "MGT_IP not found"
[ ! -n "$MAX_NODES" ] && error_exit "MAX_NODES not found"
[ ! -n "$POWER_MODE" ] && error_exit "POWER_MODE not found"
if [ "$POWER_MODE" == "ipmi" -o "$POWER_MODE" == "xcat" ]; then
   [ ! -n "$BMC_NETWORK" ] && error_exit "BMC_NETWORK not found"
   [ ! -n "$CONSOLE_MODE" ] && error_exit "CONSOLE_MODE not found"
   [ ! -n "$SOL_DEV" ] && error_exit "SOL_DEV not found"
   [ ! -n "$SOL_SPEED" ] && error_exit "SOL_SPEED not found"
fi
[ -d /sys/class/net/$GROUP_NET_DEV ] || error_exit "GROUP_NET_DEV($GROUP_NET_DEV) not found"
MGT_IP_INFO=($(ifconfig $GROUP_NET_DEV | grep "inet " | awk '{printf "%s %s",$2,$4}'))
[ "$MGT_IP" == "${MGT_IP_INFO[0]}" ] || error_exit "MGT_IP and ${GROUP_NET_DEV} IPs are different"
[ "$GROUP_NETMASK" == "${MGT_IP_INFO[1]}" ] || error_exit "GROUP_NETMASK and ${GROUP_NET_DEV} NETMASKs are different"
#MGT_IP=$(_k_net_add_ip $GROUP_NETWORK 1)

# temporary disable
init() {
  hostname $MGT_HOSTNAME
  domainname $DOMAIN_NAME
  sed -i "/^_KXC_VERSION=/c \
_KXC_VERSION=$(git describe --tags) " $_KXCAT_HOME/bin/kxcat
#  rm -fr $_KXCAT_HOME/.git

  if [ -f /etc/hostname ]; then
      grep "^$MGT_HOSTNAME$" /etc/hostname >& /dev/null || echo "$MGT_HOSTNAME" > /etc/hostname
  fi
  if ! grep "^$MGT_IP  $MGT_HOSTNAME" /etc/hosts >& /dev/null; then
     echo "$MGT_IP  $MGT_HOSTNAME  ${MGT_HOSTNAME}.${DOMAIN_NAME}" >> /etc/hosts
  fi

  if [ -n "$MPI_NETWORK" -a -n "$MPI_DEV" ]; then
     [ -d /sys/class/net/${MPI_DEV} ] || error_exit "Please Install OFED/OPA and setup device first"
     [ -f /etc/sysconfig/network-scripts/ifcfg-${MPI_DEV} ] || error_exit "not found ifcfg-${MPI_DEV} config file"
     echo "CONNECTED_MODE=no
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=static
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
NAME=${MPI_DEV}
DEVICE=${MPI_DEV}
ONBOOT=no
IPADDR=${MPI_MGT_IP}
NETMASK=${GROUP_NETMASK} " > /etc/sysconfig/network-scripts/ifcfg-${MPI_DEV}
  fi



if ! grep "^search $DOMAIN_NAME" /etc/resolv.conf >& /dev/null; then
  echo "search $DOMAIN_NAME
nameserver $MGT_IP" > /etc/resolv.conf
  if [ -n "$DNS_OUTSIDE" ]; then
    for ii in $(echo $DNS_OUTSIDE | sed "s/,/ /g"); do
       echo "nameserver $ii" >> /etc/resolv.conf
    done
  fi
fi

  echo "_KXCAT_HOME=$_KXCAT_HOME
PATH=\${PATH}:\$_KXCAT_HOME/bin
export _KXCAT_HOME PATH" > /etc/profile.d/kxcat.sh

  cat << EOF > $_KXCAT_HOME/bin/kxcat_service
#!/bin/sh
### BEGIN INIT INFO
# Provides: xcatd
# Required-Start:
# Required-Stop: 
# Should-Start: 
# Default-Start: 3 5
# Default-stop: 0 1 2 6
# Short-Description: xcatd
# Description: xCAT management service
### END INIT INFO


# This avoids the perl locale warnings
if [ -z \$LC_ALL ]; then
  export LC_ALL=C
fi

case \$1 in
restart)
  echo -n "Restarting xcatd "
  stop
  start
  ;;
status)
  echo "dhcpd: \$(systemctl status dhcpd | grep Active)"
  echo "httpd: \$(systemctl status httpd | grep Active)"
  echo "nfs: \$(systemctl status nfs | grep Active)"
  echo "rpcbind: \$(systemctl status rpcbind | grep Active)"
  echo "ntpd: \$(systemctl status ntpd | grep Active)"
  /etc/init.d/xcatd status
  ;;
stop)
  echo -n "Stopping xcatd "
  [ -f /var/run/kxcat/kxcat_sw.pid ] && kill -9 \$(cat /var/run/kxcat/kxcat_sw.pid)
  /etc/init.d/xcatd stop
  systemctl stop dhcpd
  systemctl stop httpd
  systemctl stop nfs
  systemctl stop rpcbind
  systemctl stop ntpd
  ;;
start)
  echo -n "Starting xcatd "
  systemctl start ntpdate
  systemctl start ntpd
  systemctl start dhcpd
  systemctl start httpd
  systemctl start nfs
  systemctl start rpcbind
  /etc/init.d/xcatd start
  source /etc/profile.d/kxcat.sh
  nohup \$_KXCAT_HOME/bin/kxcat_sw &
  ;;
esac
EOF
  chmod +x $_KXCAT_HOME/bin/kxcat_service

  cat << EOF > /lib/systemd/system/kxcat.service
[Unit]
Description=xCAT service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=$_KXCAT_HOME/bin/kxcat_service start
ExecStop=$_KXCAT_HOME/bin/kxcat_service stop
ExecReload=-$_KXCAT_HOME/bin/kxcat_service restart

[Install]
WantedBy=multi-user.target
EOF
  sleep 3
  systemctl daemon-reload

  _k_servicectl kxcat on
  . /etc/profile.d/kxcat.sh
  _k_servicectl firewalld off
  _k_servicectl libvirtd off
  _k_servicectl NetworkManager off
  if [ -f /etc/sysconfig/selinux ]; then
    grep -v "^#" /etc/sysconfig/selinux  | grep enforcing >& /dev/null && sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux
  fi
  [ "$(getenforce)" == "Disabled" ] || setenforce 0

  #SSH password-less
  if ! ssh -q -o ConnectTimeout=5 -o CheckHostIP=no -o StrictHostKeychecking=no -o PasswordAuthentication=no localhost hostname >& /dev/null; then
      ssh-keygen -t rsa 
      cp -a ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys
      chmod 644 ~/.ssh/authorized_keys
      chmod 600 ~/.ssh/id_rsa
  fi
  if [ -f /root/.ssh/config ]; then
    grep -w CheckHostIP /root/.ssh/config >& /dev/null || ( echo ' host *
    StrictHostKeyChecking no
    CheckHostIP no
    ForwardX11 no
    ForwardAgent yes'  > /root/.ssh/config
   chmod 644 /root/.ssh/config )
  else
    echo ' host *
    StrictHostKeyChecking no
    CheckHostIP no
    ForwardX11 no
    ForwardAgent yes'  > /root/.ssh/config
    chmod 644 /root/.ssh/config
  fi
  if [ ! -f /etc/ssh/sshd_config.ORIG ]; then
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.ORIG
    sed -i '/X11Forwarding /'d /etc/ssh/sshd_config
    echo "X11Forwarding yes" >>/etc/ssh/sshd_config
    sed -i '/KeyRegenerationInterval /'d /etc/ssh/sshd_config
    echo "KeyRegenerationInterval 0" >>/etc/ssh/sshd_config
    sed -i '/MaxStartups /'d /etc/ssh/sshd_config
    echo "MaxStartups 1024" >>/etc/ssh/sshd_config
    sed -i '/StrictHostKeyChecking /'d /etc/ssh/ssh_config
    echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config
    sed -i '/CheckHostIP /'d /etc/ssh/ssh_config
    echo "CheckHostIP no" >> /etc/ssh/ssh_config
  fi
  [ -d /install/postscripts/hostkeys ] || mkdir -p /install/postscripts/hostkeys
  cp -a ~/.ssh/authorized_keys /install/postscripts/hostkeys/

  #ARP & NFS FIX
  echo 512 > /proc/sys/net/ipv4/neigh/default/gc_thresh1
  echo 2048 > /proc/sys/net/ipv4/neigh/default/gc_thresh2
  echo 4096 > /proc/sys/net/ipv4/neigh/default/gc_thresh3
  echo 240 > /proc/sys/net/ipv4/neigh/default/gc_stale_time

  echo 268435456 > /proc/sys/kernel/shmmax
  echo 1048576 > /proc/sys/net/core/wmem_max
  echo 8388608 > /proc/sys/net/core/rmem_default
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
  yum -y install dhcp dhcp-common dhcp-libs ntp nfs httpd tftp bind screen rpcbind bind-utils wget git openssl openssl-libs sqlite
  _k_servicectl dhcpd stop
  rpm -qa |grep libvirt-client >& /dev/null && yum erase libvirt-client
  [ -f ./go-xcat ] && rm -f go-xcat
  wget https://raw.githubusercontent.com/xcat2/xcat-core/master/xCAT-server/share/xcat/tools/go-xcat -O - > /tmp/go-xcat
  chmod +x /tmp/go-xcat
  /tmp/go-xcat install
  rm -f /tmp/go-xcat
  [ -f /etc/profile.d/xcat.sh ] || error_exit "/etc/profile.d/xcat.sh file not found"
  #mv /etc/profile.d/xcat.* $_KXCAT_HOME/etc
  [ ! -f /tftpboot/xcat/xnba.efi -o ! -f /tftpboot/xcat/xnba.kpxe ] && (rpm -e --nodeps $(rpm -qa | grep xnba-undi); yum -y install xnba-undi)
  (cd /opt && git clone https://github.com/kagepark/kgt.git)
  rm -fr /opt/kgt/.git
  rm -f /opt/kgt/README.md
  /opt/kgt/bin/kgt setup
  source /etc/profile.d/kgt.sh
}

xcat_env() {
  # NTP config
  if ! grep "^fudge 127.127.1.0" /etc/ntp.conf >& /dev/null; then
      echo "fudge 127.127.1.0 stratum 10" >> /etc/ntp.conf
  fi
  if [ -n "$NTP_IP" ]; then
     if ! grep "^server $NTP_IP" /etc/ntp.conf >& /dev/null ; then
        echo "server $NTP_IP" >> /etc/ntp.conf
     fi
  else
     if ! grep "^server $MGT_IP" /etc/ntp.conf >& /dev/null ; then
        echo "server $MGT_IP" >> /etc/ntp.conf
     fi
  fi
  _k_servicectl ntpd stop
  _k_servicectl ntpdate start
  _k_servicectl ntpd start
#  _k_servicectl ntpd on 35

  # NFS patch
  if ! grep "^RPCNFSDCOUNT=" /etc/sysconfig/nfs >&/dev/null; then
      echo "RPCNFSDCOUNT=128" >> /etc/sysconfig/nfs
  fi
  _k_servicectl nfs restart
#  _k_servicectl nfs on 35
  # APACHE
  if ! grep "^<IfModule mpm_worker_module>" /etc/httpd/conf/httpd.conf >& /dev/null; then
      echo "<IfModule mpm_worker_module>
    ServerLimit              250
    StartServers              10
    MinSpareThreads           75
    MaxSpareThreads          250
    ThreadLimit               64
    ThreadsPerChild           32
    MaxRequestWorkers       8000
    MaxConnectionsPerChild 10000
</IfModule>" >> /etc/httpd/conf/httpd.conf
  fi
  _k_servicectl httpd restart
#  _k_servicectl httpd on 35

  # Patch post.xcat file
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
     echo " anykey to continue"
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
   \/xcatpost\/kxcatboot \> \/tmp\/xcat_boot.log \n\
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
  #if [ ! -f /install/postscripts/remoteshell.orig ]; then
  #    cp -a /install/postscripts/remoteshell /install/postscripts/remoteshell.orig
  #    cp -a ${_KXCAT_HOME}/share/remoteshell /install/postscripts/remoteshell
  #    chmod +x /install/postscripts/remoteshell
  #fi
  if [ ! -f /install/postscripts/syslog.orig ]; then
      cp -a /install/postscripts/syslog /install/postscripts/syslog.orig
      cp -a ${_KXCAT_HOME}/share/syslog /install/postscripts/syslog
      chmod +x /install/postscripts/syslog
  fi
  

#  source $_KXCAT_HOME/etc/xcat.sh
  source /etc/profile.d/xcat.sh
  cp -a $_KXCAT_HOME/share/kxcatboot /install/postscripts
  [ -d /install/postscripts/xcat_boot.d ] || mkdir -p /install/postscripts/xcat_boot.d
  cp -a $_KXCAT_HOME/share/0000_update_state /install/postscripts/xcat_boot.d
  cp -a $_KXCAT_HOME/share/0001_cleanyum /install/postscripts/xcat_boot.d
  cp -a $_KXCAT_HOME/share/0002_mpi_net /install/postscripts/xcat_boot.d
  cp -a $_KXCAT_HOME/share/0003_ntp /install/postscripts/xcat_boot.d
  [ -d /global/xcat_boot.d/global ] || mkdir -p /global/xcat_boot.d/global
  if ! grep "^/global" /etc/exports >& /dev/null; then
     echo "/global *(rw,no_root_squash,sync,no_subtree_check)" >> /etc/exports
     exportfs -ra
  fi
  lsxcatd -a

  root_pass=$(awk -F: '{if($1=="root") print $2}' /etc/shadow)
  tabch key=system passwd.username=root passwd.password=$root_pass

#  tabdump site
  chdef -t site -o clustersite domain=$DOMAIN_NAME
  chdef -t site forwarders=$MGT_IP
  makedns all 2>/dev/null

  chtab key=master site.value=$MGT_IP
  chtab key=dhcpinterfaces site.value=$GROUP_NET_DEV
  network_name=$(tabdump networks | grep $GROUP_NET_DEV | awk -F\" '{print $2}')
  [ -n "$network_name" ] || error_exit "network_name not found for $GROUP_NET_DEV device"
  DHCP_IP_RANGE=$(_k_net_add_ip $GROUP_NETWORK $((65279-$(($MAX_NODES * 2)))))-$(_k_net_add_ip $GROUP_NETWORK 65279)
  chtab netname=$network_name networks.net=$GROUP_NETWORK networks.mask=$GROUP_NETMASK networks.mgtifname=$GROUP_NET_DEV networks.dhcpserver=$MGT_IP networks.tftpserver=$MGT_IP networks.nameservers=$MGT_IP networks.dynamicrange=$DHCP_IP_RANGE
  if [ -n "$MPI_NETWORK" ]; then
      chtab netname=MPI networks.net=$MPI_NETWORK networks.mask=$GROUP_NETMASK networks.mgtifname=$MPI_DEV
  fi
#  tabdump networks
  grep "^DHCPDARGS=" /etc/sysconfig/dhcpd >& /dev/null || echo "DHCPDARGS=\"$GROUP_NET_DEV\"" >> /etc/sysconfig/dhcpd

  _k_servicectl dhcpd start
#  _k_servicectl dhcpd on 35
  makedhcp -n
}

xcat_image() {
# OS Image
  #source $_KXCAT_HOME/etc/xcat.sh
  source /etc/profile.d/xcat.sh
  source /etc/profile.d/kxcat.sh
  echo $OS_ISO | sed "s/,/\n/g" | while read line; do
     if [ ! -f "$line" ]; then
         echo "$line not found"
         continue
     fi
     echo "Make base name from $line"
     copycds "$line"
  done
  lsdef -t osimage
  base_image_str=$(tabdump osimage | sed "s/\"//g" | awk -F, '{if($6=="install") printf "%s,%s", $1,$13}')
  base_image=$(echo $base_image_str | awk -F, '{print $1}')
  base_arch=$(echo $base_image_str | awk -F, '{print $2}')
} 

init
xcat_install
xcat_env
xcat_image


# Add Nodes
for ((node_snum=1; node_snum<=$MAX_NODES; node_snum++)); do
   node_name=n$(printf "%05d" $node_snum)
   echo "Setup $node_name"
   node_info=$([ -f server_list.cfg ] && awk -F\| -v num=$node_snum '{if($1==num) print}' server_list.cfg)
   node_mac=$(echo $node_info | awk -F\| '{print $2}')
   node_bmc_IP=$(echo $node_info | awk -F\| '{print $3}')
   [ -n "$node_mac" ] || node_mac="00:00:00:00:00:00"
   [ -n "$POWER_MODE" ] || POWER_MODE=xcat
   if [ "$POWER_MODE" == "ipmi" -o "$POWER_MODE" == "xcat" ]; then
       BMC_STR="bmc=$node_bmc_IP bmcusername=$BMC_USER bmcpassword=$BMC_PASS cons=ipmi"
       [ -n "$node_bmc_IP" ] || node_bmc_IP=$(_k_net_add_ip $BMC_NETWORK $node_snum)
       CONSOLE_STR="serialflow=none serialport=$(echo $SOL_DEV| sed "s/ttyS//g") serialspeed=${SOL_SPEED}"
   fi
   mkdef -t node $node_name groups=all,n id=$node_snum arch=$base_arch mac=$node_mac mgt=$BMC_MODE $BMC_STR netboot=xnba provmethod= $CONSOLE_STR xcatmaster=${MGT_IP}
done

#makehosts all 2>/dev/null
echo
echo "Restart service"
$_KXCAT_HOME/bin/kxcat_service stop
$_KXCAT_HOME/bin/kxcat_service stop
sleep 5
_k_servicectl kxcat stop
sleep 5
_k_servicectl kxcat start
if [ -n "$link_name" ]; then
    (cd $_KXCAT_HOME/bin && ln -s kxcat $linke_name)
fi

echo
echo "Please run \"source /etc/profile.d/kxcat.sh\""
echo "Please run \"source /etc/profile.d/xcat.sh\""
echo "KxCAT Install done"
