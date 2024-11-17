# snapper_setup
## Installing Snapper
```bash
sudo pacman -S snapper
```
> Didn't install others due to not wanting to deal with the other services when setting up snapper

## Basic Layout
When installing arch, below are the layout suggested in snapper arch wiki
> Sure you can add more like /var/tmp, /var/cache .etc as you suit

File System Layout
|  Subvolume | Mountpoint |
|:----------:|:----------:|
|@           |/           |
|@home       |/home       |
|@.snapshots |/.snapshots |
|@log        |/var/log    |
> In case you're like me, using swapfile as swap, make sure to create a swap subvolume too

|  Subvolume | Mountpoint |
|:----------:|:----------:|
|@swap       |/swap       |

## Setting up snapper
If you create a subvolume for /.snapshots or /home/.snapshots
> as an example, here's mine

'''
NAME      MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINTS
sda         8:0    0 894.3G  0 disk  
├─sda1      8:1    0     1G  0 part  /boot/efi
└─sda2      8:2    0 893.3G  0 part  /home/.snapshots
                                     /var/log
                                     /var/spool
                                     /var/crash
                                     /var/cache
                                     /home
                                     /var/lib/libvirt/images
                                     /opt
                                     /.swap
                                     /.snapshots
                                     /
'''
unmount them
```bash
sudo umount /.snapshots
sudo umount /home/.snapshots
```
Next, remove the folders
```bash
sudo rm -r /.snapshots
sudo rm -r /home/.snapshots
```
in case you can't, (which rarely happen or due to there are files in them)
```bash
sudo rm -rf /.snapshots
sudo rm -rf /home/.snapshots
```
