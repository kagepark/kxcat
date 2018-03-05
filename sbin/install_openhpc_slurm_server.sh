echo "[OpenHPC]
name=OpenHPC Pakages
baseurl=/install/post/otherpkgs/centos7.4/OpenHPC
enabled=1
gpgcheck=0" > /tmp/openhpc.repo


yum -c /tmp/openhpc.repo install ohpc-slurm-server
perl -pi -e "s/ControlMachin=\S+/ControlMachine=$(hostname)/" /etc/slurm/slurm.conf
rm -f /tmp/openhpc.repo

