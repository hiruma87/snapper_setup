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

```
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
> you can change then name root or home to fits you, this name are self explainatory so better use them

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
- @home/.snapshots would be duplicate though
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
$ sudo snapper ls
  # │ Type   │ Pre # │ Date                            │ User │ Cleanup  │ Description                                                              │ Userdata
────┼────────┼───────┼─────────────────────────────────┼──────┼──────────┼──────────────────────────────────────────────────────────────────────────┼─────────
 0  │ single │       │                                 │ root │          │ current                                                                  │
 1  │ single │       │ Sat 16 Nov 2024 09:37:16 AM +08 │ root │          │ base_install                                                             │
 ```
```
$ sudo snapper -c home list
 # │ Type   │ Pre # │ Date                            │ User │ Cleanup  │ Description                                                              │ Userdata
───┼────────┼───────┼─────────────────────────────────┼──────┼──────────┼──────────────────────────────────────────────────────────────────────────┼─────────
 0 │ single │       │                                 │ root │          │ current                                                                  │
 1 │ single │       │ Sat 16 Nov 2024 09:37:24 AM +08 │ root │          │ base_install                                                             │
 ```
## Settingg System root snapshots as default
