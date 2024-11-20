## Automated Snapper setup
# umount .snapshots if exist
sudo umount /.snapshots
# sudo umount /home/.snapshots

# remove the folder
sudo rm -r /.snapshots
#sudo rm -r /home/.snapshots

# get mount OPTIONS from a unique subvolume name
OPTIONS="$(grep '/home' /etc/fstab \
    | awk '{print $4}' \
    | cut -d, -f2-)" \
    ; echo $OPTIONS
    
# create a snapper config
sudo snapper -c root create-config / # root folder
sleep 1
sudo snapper -c home create-config /home # home folder
sleep 1

# checking existing config
sudo snapper list-config
sleep 1

# remove created subvolume
sudo btrfs subvolume delete /.snapshots

#create back the folder
sudo mkdir /.snapshots

# set so user can use snapper
sudo snapper -c root set-config ALLOW_USERS=$USER SYNC_ACL=yes  # root config
sleep 1
sudo snapper -c home set-config ALLOW_USERS=$USER SYNC_ACL=yes # home config
sleep 1

# see if it working
snapper ls
sleep 1
snapper -c home list
sleep 1

# modify /etc/fstab and mounting
ROOT_UUID="$(sudo grub2-probe --target=fs_uuid /)" # get the existing UUID
sleep 1
MAX_LEN="$(cat /etc/fstab | awk '{print $2}' | wc -L)"
sleep 1
# since I created a /.snapshots subvolume during isntallation, only 1 subvol listed
# if not
#for dir in '/.snapshots' 'home/.snapshots' ; do
for dir in 'home/.snapshots' ; do
    printf "%-41s %-${MAX_LEN}s %-5s %-s %-s\n" \
        "UUID=${ROOT_UUID}" \
        "/${dir}" \
        "btrfs" \
        "subvol=${dir},${OPTIONS}" \
        "0 0" | \
        sudo tee -a /etc/fstab
done
sleep 1
cat /etc/fstab
sleep 1
sudo systemctl daemon-reload
sleep 1
sudo mount -va
sleep 1

#setting grub
# adding to /etc/default/grub
sudo sed -i 's/GRUB_CMDLINE_LINUX=.*/&\nSUSE_BTRFS_SNAPSHOT_BOOTING="true"/' /etc/default/grub
sleep 1
sudo grub-mkconfig -o /boot/grub/grub.cfg
sleep 1

#create a snapshot
sudo snapper -c root create --description base
sleep 1
sudo snapper -c home create --description base
sleep 1

# check if they create properly
snapper ls
sleep 1
snapper -c home list
sleep 1

#set created subvolume as default
SNAP_1_ID="$(sudo btrfs inspect-internal rootid /.snapshots/1/snapshot)"
sleep 1
echo ${SNAP_1_ID}
sleep 1
sudo btrfs subvolume set-default ${SNAP_1_ID} /
sleep 1
sudo btrfs subvolume get-default /
sleep 1

# lastly reboot
