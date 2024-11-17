# snapper_setup
### Installing Snapper
```bash
sudo pacman -S snapper
```
> Didn't install others due to not wanting to deal with the other services when setting up snapper

### Basic Layout
When installing arch, below are the layout suggested in snapper arch wiki
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

