# KxCAT
it will be changed name from KxCAT to kix.
(Kage Interface for xCAT)
Short name will be easy use.

requirement : 
  - MGT node
    + NIC : Minimum Two 1G (Recommend: 1G x 1ea, 10G x 1ea)
    + HDD : Minimum 1TB HDD(SATA) (Recommend: over 4ea HDDs, Raid controller(Raid 5), over 1TB space, XFS)
    + Memory: minimum 2GB (Recommend: over 16GB)
  - compute node (Disk-less)
    + NIC : Minimum 1G x 1ea (not recommend device model: virtio)
    + Memory: minimum 6GB (Recommend: over 8GB)
    + boot optioin : (1.Network PXE Boot)
  - compute node (Diskful)
    + NIC : Minimum 1G x 1ea (not recommend device model: virtio)
    + Memory: minimum 3GB (Recommend: over 8GB)
    + HDD: minimum over 50GB 1ea SATA (Support Disk bus : SATA or SCSI, not support Disk bus : VirtIO)
    + boot optioin : (1.Network PXE Boot, 2.Disk Boot)
  - Packages
    + kgt (Opensource) for tool (Auto install)
      + /opt/kgt
    + OS iso file
  - Main directories
    + /opt/xcat
    + /install
    + /tftpboot
    + /global

Base HPC software is xCAT(https://xcat.org/)
This KxCAT made shell scripts for user friendly interface from xCAT original CLI.
KxCAT has enhanced HPC structure based on xCAT function.
 - more user friendly CLI interface
 - more easily usable CLI
   + Simple CLI commands run grouped progress according to simplified HPC structure.
   + reduce user's mistake.
   + anybody can handle whole HPC system without many knowledge.
 - making simple HPC structure from original xCAT structure
 - Support Managed Ethernet switch w/ SNMP
 - Support
   + Multi OS (CentOS, RHEL, ...)
   + Multi type of HPC (Diskless, Diskful)

KxCAT profile file : /etc/profile.d/kxcat.sh
command : kix

Config File:
<KxCAT HOME>/etc/kxcat.cfg
<KxCAT HOME>/etc/kxcat_sw.cfg

Install:
<KxCAT HOME>/sbin/install_kxcat.sh

Help: 
 - it will keep changing command to grouped function and descriptions
 - This will be initial command and descriptions

Not fully developed yet.
it still has bugs

version:
0.1 : Testing functions
1.4 : Adding handle on CentOS 7.x service
2.0 : Adding SNMP function
2.1 : Adding export/import kxcat image function

 
Personal use or tesing purposes.
(It is not used for purpose of Company Profit Creation.)
