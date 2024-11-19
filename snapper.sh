# snap additional subvolume
echo '##############################################################'
echo '########## Create related folder'
echo '##############################################################'

sudo mkdir -vp /var/lib/libvirt
sleep 3
sudo mkdir -vp /home/$USER/.config/
sleep 3

echo '##############################################################'
echo '########## Getting UUID and options from existing fstab'
echo '##############################################################'

ROOT_UUID="$(sudo grub-probe --target=fs_uuid /)" ; echo $ROOT_UUID
sleep 3

OPTIONS="$(grep '/home' /etc/fstab \
    | awk '{print $4}' \
    | cut -d, -f2-)" \
    ; echo $OPTIONS
sleep 3

echo '##############################################################'
echo '########## Create root folders subvolume'
echo '##############################################################'

SUBVOLUMES=(
    "opt"
    "var/cache"
    "var/crash"
    "var/lib/AccountsService"
    # select your greeter
    #"var/lib/gdm"
    "var/lib/sddm"
    #"var/lib/lightdm"
    #"var/lib/lightdm-data"
    "var/lib/libvirt/images"
    "var/log"
    "var/spool"
    "var/tmp"
)
sleep 3

printf '%s\n' "${SUBVOLUMES[@]}"
sleep 3

MAX_LEN="$(printf '/%s\n' "${SUBVOLUMES[@]}" | wc -L)" ; echo $MAX_LEN
sleep 3

echo '##############################################################'
echo '########## Mounting the root folders subvolume'
echo '##############################################################'

for dir in "${SUBVOLUMES[@]}" ; do
    if [[ -d "/${dir}" ]] ; then
        sudo mv -v "/${dir}" "/${dir}-old"
        sudo btrfs subvolume create "/${dir}"
        sudo cp -ar "/${dir}-old/." "/${dir}/"
    else
        sudo btrfs subvolume create "/${dir}"
    fi
    printf "%-41s %-${MAX_LEN}s %-5s %-s %-s\n" \
        "UUID=${ROOT_UUID}" \
        "/${dir}" \
        "btrfs" \
        "subvol=@/${dir},${OPTIONS}" \
        "0 0" | \
        sudo tee -a /etc/fstab
done
sleep 3
cat /etc/fstab
sleep 1
sudo systemctl daemon-reload
sleep 1
sudo btrfs subvolume list /
sleep 1

echo '##############################################################'
echo '########## Removing old folders of the subvolumes'
echo '##############################################################'

for dir in "${SUBVOLUMES[@]}" ; do
    if [[ -d "/${dir}-old" ]] ; then
        sudo rm -rvf "/${dir}-old"
    fi
done

sleep 3

echo '##############################################################'
echo '########## Start setting up snapper configs'
echo '##############################################################'

sudo umount /.snapshots
sleep 1
sudo rm -rvf /.snapshots
sleep 1
sudo snapper -c root create-config /
sleep 3
sudo snapper -c home create-config /home
sleep 3
sudo btrfs subvolume delete /.snapshots
sleep 3
sudo mkdir /.snapshots
sleep 3

echo '##############################################################'
echo '########## Getting UUID and options from existing fstab'
echo '##############################################################'

ROOT_UUID="$(sudo grub-probe --target=fs_uuid /)"
sleep 3
MAX_LEN="$(cat /etc/fstab | awk '{print $2}' | wc -L)"
sleep 3

OPTIONS="$(grep '/opt' /etc/fstab \
    | awk '{print $4}' \
    | cut -d, -f2-)"
sleep 3

echo '##############################################################'
echo '########## Create home folders subvolume'
echo '##############################################################'

SUBVOLUMES=(
    "home/$USER/.mozilla"
    "home/$USER/.thunderbird"
    "home/$USER/.config/opera"
)
sleep 3

printf '%s\n' "${SUBVOLUMES[@]}"
sleep 3

MAX_LEN="$(printf '/%s\n' "${SUBVOLUMES[@]}" | wc -L)" ; echo $MAX_LEN
sleep 3


echo '##############################################################'
echo '########## Mounting the home folders subvolume'
echo '##############################################################'

for dir in "${SUBVOLUMES[@]}" ; do
    if [[ -d "/${dir}" ]] ; then
        sudo mv -v "/${dir}" "/${dir}-old"
        sudo btrfs subvolume create "/${dir}"
        sudo cp -ar "/${dir}-old/." "/${dir}/"
    else
        sudo btrfs subvolume create "/${dir}"
    fi
    printf "%-41s %-${MAX_LEN}s %-5s %-s %-s\n" \
        "UUID=${ROOT_UUID}" \
        "/${dir}" \
        "btrfs" \
        "subvol=@${dir},${OPTIONS}" \
        "0 0" | \
        sudo tee -a /etc/fstab
done
sleep 3

for dir in 'home/.snapshots' ; do
    printf "%-41s %-${MAX_LEN}s %-5s %-s %-s\n" \
        "UUID=${ROOT_UUID}" \
        "/${dir}" \
        "btrfs" \
        "subvol=@${dir},${OPTIONS}" \
        "0 0" | \
        sudo tee -a /etc/fstab
done
sleep 3
cat /etc/fstab
sleep 3
sudo systemctl daemon-reload
sleep 3
sudo mount -va
sleep 3


echo '##############################################################'
echo '########## Setting grub for grub support'
echo '##############################################################'

sudo snapper -c root set-config ALLOW_USERS=$USER SYNC_ACL=yes
sleep 3
sudo snapper -c home set-config ALLOW_USERS=$USER SYNC_ACL=yes
sleep 3
sudo snapper -c root create --description base_install
sleep 3
sudo snapper -c home create --description base_install
sleep 3
SNAP_1_ID="$(sudo btrfs inspect-internal rootid /.snapshots/1/snapshot)"
sleep 3
echo ${SNAP_1_ID}
sleep 3
sudo btrfs subvolume set-default ${SNAP_1_ID} /
sleep 3
sudo btrfs subvolume get-default /
sleep 3
sudo sed -i 's/GRUB_CMDLINE_LINUX=.*/&\nSUSE_BTRFS_SNAPSHOT_BOOTING="true"/' /etc/default/grub
sleep 3
sudo grub-mkconfig -o /boot/grub/grub.cfg
sleep 3
sudo setfacl -R -b /home/$USER/.mozilla
sleep 3
sudo setfacl -R -b /home/$USER/.thunderbird
sleep 3
sudo setfacl -R -b /home/$USER/.config/opera
sleep 3
sudo setfacl -R -m u:$USER:rwX /home/$USER/.mozilla
sleep 3
sudo setfacl -R -m u:$USER:rwX /home/$USER/.thunderbird
sleep 3
sudo setfacl -R -m u:$USER:rwX /home/$USER/.config/opera
sleep 3
sudo setfacl -m d:u:$USER:rwx /home/$USER/.mozilla
sleep 3
getfacl /home/$USER/.mozilla
sleep 1
sudo setfacl -m d:u:$USER:rwx /home/$USER/.thunderbird
sleep 3
getfacl /home/$USER/.thunderbird
sleep 1
sudo setfacl -m d:u:$USER:rwx /home/$USER/.config/opera
sleep 1
getfacl /home/$USER/.thunderbird
