# snapper_setup

## Credit
Sysguide: [Sysguide Website](https://sysguides.com)

Arch Wiki: [Arch Snapper Wiki](https://wiki.archlinux.org/title/Snapper)


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

```
$ lsblk
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
```
unmount them
```bash
sudo umount /.snapshots
```
```bash
sudo umount /home/.snapshots
```
Next, remove the folders
```bash
sudo rm -r /.snapshots
```
```bash
sudo rm -r /home/.snapshots
```
in case you can't, (which rarely happen or due to there are files in them)
```bash
sudo rm -rf /.snapshots
```
```bash
sudo rm -rf /home/.snapshots
```
Create a snapper config for / and/or /home (/home snapshots are optional, it still nice to have them)
```bash
sudo snapper -c root create-config /
```
```bash
sudo snapper -c home -create-config /home
```
> you can change the name root or home to fits you, this name are self explainatory so better use them

check back your subvolume list
```bash
sudo btrfs subvolume list /
```
You may get something like
```
$ sudo btrfs subvolume list /
ID 256 gen 199 top level 5 path @
ID 257 gen 186 top level 5 path @home
ID 258 gen 9 top level 5 path @.snapshots
[...]
ID 265 gen 199 top level 256 path .snapshots
ID 270 gen 3760 top level 257 path @home/.snapshots
```
As observed, there are 2 snapshots subvolume, remove 1 and make sure not the one with @
- @home/.snapshots would not be duplicate though
```bash
sudo btrfs subvolume delete /.snapshots
```
create back the /.snapshots folder
```bash
sudo mkdir /.snapshots
```
remount them
```bash
sudo mount -av
```
You will get something like
```
$ sudo mount -av
/                        : ignored
/boot/efi                : successfully mounted
/media/raid0             : already mounted
/home                    : already mounted
/home/.snapshots         : successfully mounted
/opt                     : already mounted
/.swap                   : already mounted
/.snapshots              : already mounted
/var/log                 : already mounted
/var/cache               : already mounted
/var/crash               : already mounted
/var/spool               : already mounted
/var/lib/libvirt/images  : already mounted
none                     : ignored
```
In case you had error when trying to remount /home/.snapshots, check your /etc/fstab
```bash
vim /etc/fstab
```
```
# /dev/sda2
> UUID=5a201d92-77d0-4e40-a731-2cdb96abdaf5	/home/.snapshots	btrfs     	rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvolid=270,subvol=@home/.snapshots	0 0
```
It is probably due to subvolid in the mount option
> I normally remove those subvolid early during the arch installation arch-chroot

so, remove them, do the same for others while you at it
```
# /dev/sda2
UUID=5a201d92-77d0-4e40-a731-2cdb96abdaf5	/home/.snapshots	btrfs     	rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=@home/.snapshots	0 0
```

reload fstab
```bash
sudo systemctl daemon-reload
```
and run again (normally fix it, if not, a reboot will do them nicely)
```bash
sudo mount -av
```
Now then, let check the newly created snapper config
```
$ sudo snapper list-configs 
Config │ Subvolume
───────┼──────────
home   │ /home
root   │ /
```
```
$ sudo snapper ls
  # │ Type   │ Pre # │ Date                            │ User │ Cleanup  │ Description                                                              │ Userdata
────┼────────┼───────┼─────────────────────────────────┼──────┼──────────┼──────────────────────────────────────────────────────────────────────────┼─────────
 0  │ single │       │                                 │ root │          │ current                                                                  │
```
```
$ sudo snapper -c home list
 # │ Type   │ Pre # │ Date                            │ User │ Cleanup  │ Description │ Userdata
───┼────────┼───────┼─────────────────────────────────┼──────┼──────────┼─────────────┼─────────
 0 │ single │       │                                 │ root │          │ current     │
 ```
 You can avoid typing sudo everytime by
 ```bash
$ sudo snapper -c root set-config ALLOW_USERS=$USER SYNC_ACL=yes
```
```bash
$ sudo snapper -c home set-config ALLOW_USERS=$USER SYNC_ACL=yes
```
Then you check the config list again
```bash
$ snapper list-configs 
Config │ Subvolume
───────┼──────────
home   │ /home
root   │ /
```
Let's create a snapshots
```bash
sudo snapper -c root create --description base_install
```
and
```bash
sudo snapper -c home create --description base_install
```
check if the snapshots created normally
```
$ snapper ls
  # │ Type   │ Pre # │ Date                            │ User │ Cleanup  │ Description                                                              │ Userdata
────┼────────┼───────┼─────────────────────────────────┼──────┼──────────┼──────────────────────────────────────────────────────────────────────────┼─────────
 0  │ single │       │                                 │ root │          │ current                                                                  │
 1  │ single │       │ Sat 16 Nov 2024 09:37:16 AM +08 │ root │          │ base_install                                                             │
 ```
```
$ snapper -c home list
 # │ Type   │ Pre # │ Date                            │ User │ Cleanup  │ Description                                                              │ Userdata
───┼────────┼───────┼─────────────────────────────────┼──────┼──────────┼──────────────────────────────────────────────────────────────────────────┼─────────
 0 │ single │       │                                 │ root │          │ current                                                                  │
 1 │ single │       │ Sat 16 Nov 2024 09:37:24 AM +08 │ root │          │ base_install                                                             │
 ```
## Setting System root snapshots as default
Let's check the root id of our newly created snaphots
```bash
$ sudo btrfs inspect-internal rootid /.snapshots/1/snapshot/
271
```
The return result shows `271`
Now let sets it as default root
```bash
$ sudo btrfs subvolume set-default 271 /
```
Check if the default is set
```bash
$ sudo btrfs subvolume get-default /
ID 271 gen 53 top level 259 path @.snapshots/1/snapshot
```
```bash
$ snapper ls
  # │ Type   │ Pre # │ Date                            │ User │ Cleanup  │ Description                                                              │ Userdata
────┼────────┼───────┼─────────────────────────────────┼──────┼──────────┼──────────────────────────────────────────────────────────────────────────┼─────────
 0  │ single │       │                                 │ root │          │ current                                                                  │
 1+ │ single │       │ Sat 16 Nov 2024 09:37:16 AM +08 │ root │          │ cinn_base                                                                │
 ```
Now you can see `+` in front of 1 which means that snapshots had been set as default

### Setting up for snapshots grub boot
Install the needed packages
```bash
sudo pacman -S grub-btrfs inotify-tools
```
This is optional, you can also install btrfs snapshots gui helper (in my case it will be btrfs-assistant)

lets get it from the AUR
```
git clone https://aur.archlinux.org/btrfs-assistant.git
cd btrfs-assistant
makepkg -si
```
Modifying grub.cfg
Add this line to your /boot/grub/grub.cfg `SUSE_BTRFS_SNAPSHOT_BOOTING="true"`
```
$ sudo vim /etc/default/grub
# GRUB boot loader configuration

GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="Arch"
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=0 quiet intel_iommu=on iommu=pt"
GRUB_CMDLINE_LINUX=""
SUSE_BTRFS_SNAPSHOT_BOOTING="true"  <-- add it here
```
Then, update your grub
```bash
$ sudo grub-mkconfig -o /boot/grub/grub.cfg 
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-linux
Found initrd image: /boot/intel-ucode.img /boot/initramfs-linux.img
Found fallback initrd image(s) in /boot:  intel-ucode.img initramfs-linux-fallback.img
Warning: os-prober will not be executed to detect other bootable partitions.
Systems on them will not be added to the GRUB boot configuration.
Check GRUB_DISABLE_OS_PROBER documentation entry.
Adding boot menu entry for UEFI Firmware Settings ...
Detecting snapshots ...
Found snapshot: 2024-11-17 19:00:09 | @.snapshots/46/snapshot | single | timeline <-- if you see this message, then grub successfully detect your snapshot
```
with that you can boot from the snapshots in case your system have issues in the future

### Touch up Snapper
Let check our snapper config
```bash
$ sudo vim /etc/snapper/configs/root
```
search for these parts and modify as you see fits
```
# limit for number cleanup
NUMBER_MIN_AGE="3600"
NUMBER_LIMIT="20"
NUMBER_LIMIT_IMPORTANT="10"
```
```
# limits for timeline cleanup
TIMELINE_MIN_AGE="3600"
TIMELINE_LIMIT_HOURLY="10"
TIMELINE_LIMIT_DAILY="10"
TIMELINE_LIMIT_WEEKLY="0"
TIMELINE_LIMIT_MONTHLY="0"
TIMELINE_LIMIT_QUARTERLY="0"
TIMELINE_LIMIT_YEARLY="0"
```
Running systemd
```bash
sudo systemctl enable --now grub-btrfsd.service
```
below systemd service sometimes run automatically, nothing wrong to double check
```bash
sudo systemctl enable --now snapper-timeline.service
sudo systemctl enable --now snapper-timeline.timer
```
```bash
sudo systemctl enable --now snapper-cleanup.service
sudo systemctl enable --now snapper-cleanup.timer
```
