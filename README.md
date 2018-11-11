Simple scripts to setup machines/vms remotely.

They to not depend on user input and should be suitable for using in
automation.
They work on debian stretch.

- box-untaint.sh Some dedicated servers provider don't let you control the
  partition configuration and add their reporitory in the trusted setup. This
  scripts reinstall using debootstrap to another partition.
  Typical usecase, where the provider install script had your root on /dev/sda1
  and /home on /dev/sda2 and maybe swap or other partitions:
  ```shell
  umount /home
  ./box-untaint.sh init /dev/sda2
  ```
  reboot. Not root is /dev/sda2
  ```shell
  cd /root
  ./box-untaint.sh init /dev/sda1
  reboot
  ```
  Note that this script will install a 'testing' release.
- box-essential.sh Installs a iptables based basic firewall and makes it
  persistent across reboots.
- box-volume.sh Creates and encrypted volume and thows away the key. To use
  with rebuildable VMs.
- box-wireguard.sh Install sid's wireguard on a testing machine.
