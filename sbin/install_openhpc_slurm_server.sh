yum -c aaa install ohpc-slurm-server
perl -pi -e "s/ControlMachin=\S+/ControlMachine=$(hostname)/" /etc/slurm/slurm.conf
