# KxCAT

requirement : 
  - MGT node
    + NIC : Minimum Two 1G (Recommend: 1G x 1ea, 10G x 1ea)
    + HDD : Minimum 1TB HDD(SATA) (Recommend: over 4ea HDDs, Raid controller(Raid 5), over 1TB space, XFS)
    + Memory: minimum 2GB (Recommend: over 16GB)
  - compute node (Disk-less)
    + NIC : Minimum 1G x 1ea
    + Memory: minimum 5GB (Recommend: over 8GB)
  - compute node (Diskful)
    + NIC : Minimum 1G x 1ea
    + Memory: minimum 2GB (Recommend: over 8GB)
    + HDD: minimum over 50GB 1ea SATA
  - Packages
    + kgt (Opensource) for tool (Auto install)
      + /opt/kgt
    + OS iso file
  - Main directories
    + /opt/xcat
    + /install
    + /tftpboot
    + /global

Based HPC engine is xCAT
This KxCAT is user friendly interface for xCAT.
KxCAT has enhanced HPC structure based on xCAT design.
 - more user friendly CLI interface
 - more easily usable CLI
   + Simple CLI commands run grouped progress according to simplified HPC structure.
   + reduce user's mistake.
   + anybody can handle whole HPC system without many knowledge.
 - making simple HPC structure from original xCAT structure
 - Support
   + Multi OS (CentOS, RHEL, ...)
   + Multi type of HPC (Diskless, Diskful)



KxCAT environment file : /etc/profile.d/kxcat.sh
command : kxcat
- I changed command from kxcat to sce
- I have a new job in Supermicro Computer and I changed it

Config File:
<KxCAT HOME>/etc/kxcat.cfg

Install:
<KxCAT HOME>/sbin/install_kxcat.sh

Help: 
 - it will keep changing command to grouped function and descriptions
 - This will be initial command and descriptions

Not fully developed yet.
it still has bugs
