# X1 Carbon 6th Discontinued; fixed by Lenovo in new firmware release

Lenovo released a new firmware 1.30 which is available on [LVFS](https://fwupd.org/lvfs/component/1023/all)
and also available via [Lenovo Support Site](https://pcsupport.lenovo.com/us/en/products/LAPTOPS-AND-NETBOOKS/THINKPAD-X-SERIES-LAPTOPS/THINKPAD-X1-CARBON-6TH-GEN-TYPE-20KH-20KG/downloads/DS502282)

After flashing you will need to enable it under Setup → Config → Power then select Linux.

**But don't forget** to reverse this scripts effects and manual changes in your [bootloader config](#loading-the-override-on-boot) before rebooting.

```bash
# remove the patch
rm /boot/acpi_override

# on ubuntu / debian based system
rm /etc/initramfs-tools/hooks/acpi_override.sh
```

## BIOS Update

### Via LVFS

Many modern distros automatically install the updates from LVFS but you can check manually via:

If you have a device with firmware supported by fwupd, this is how you will check for updates and apply them using fwupd's command line tools.

```bash

# fwupdmgr get-devices

This will display all devices detected by fwupd.

# fwupdmgr refresh

This will download the latest metadata from LVFS.

# fwupdmgr get-updates

If updates are available for any devices on the system, they'll be displayed.

# fwupdmgr update

This will download and apply all updates for your system.

    Updates that can be applied live will be done immediately.
    Updates that run at bootup will be staged for the next reboot.
```

### Manual

You can manually check your BIOS version like this:

```bash
sudo dmidecode | grep "BIOS Revision:"
```

To update your BIOS via USB drive use [geteltorito](https://aur.archlinux.org/packages/geteltorito/).

```bash
curl -O https://download.lenovo.com/pccbbs/mobiles/n23ur11w.iso
geteltorito -o x1c2018-130.img n23ur11w.iso
sudo dd if=x1c2018-130.img of=/dev/sdX bs=512K
```

---

## Suspend for the "Thinkpad X1 Yoga (3rd Gen)" on Linux (previously also X1 Carbon 6th Gen)

Unfortunately the ThinkPad X1 Yoga (3rd Gen) aka (X1Y3 and X1 Yoga 2018) does not support suspend on Linux. There's an ongoing discussion in
the [Lenovo Support Forums](https://forums.lenovo.com/t5/Linux-Discussion/X1-Carbon-Gen-6-cannot-enter-deep-sleep-S3-state-aka-Suspend-to/td-p/3998182).
With some help from the [Arch Linux Community](https://bbs.archlinux.org/viewtopic.php?id=234913), I was able to create an
[ACPI override for the DSDT](https://wiki.archlinux.org/index.php/DSDT). This enables full support of S3 suspend on Linux.

## Prerequisites

Debian/Ubuntu based distro with initramfs-tools based initramfs generation for fully automated setup apart from the BIOS related things.

For other distros there are some further steps needed. (PRs welcome)
Reboot from USB and follow instructions.

### BIOS settings
* Ensure that `Boot Mode` is set to `Quick` and not `Diagnostic`
* Set `Thunderbolt BIOS Assist Mode` to `Enabled` (via `Config` → `Thunderbolt 3`).
* Disable `Secure Boot`.

If you see all three lines in `dmesg | grep -A3 'DSDT ACPI'`

```
[    0.000000] ACPI: DSDT ACPI table found in initrd [kernel/firmware/acpi/dsdt.aml][0x2338b]
[    0.000000] Lockdown: ACPI table override is restricted; see man kernel_lockdown.7
[    0.000000] ACPI: kernel is locked down, ignoring table override

```

rather than just the first line, disable `Secure Boot`

### Tools

Make sure that you have `iasl` (via [acpica](https://www.archlinux.org/packages/community/x86_64/acpica/)) and `cpio`
(via [cpio](https://www.archlinux.org/packages/extra/x86_64/cpio/)) installed.

Installed automatically on distros with apt such as Debian/Ubuntu

## Generating the override

```bash
curl -O https://raw.githubusercontent.com/fiji-flo/x1carbon2018s3/master/generate_and_apply_patch.sh
chmod +x generate_and_apply_patch.sh
./generate_and_apply_patch.sh
```

## Loading the override on boot

Edit your boot loader configuration and add `/acpi_override` to the `initrd` line.
To ensure `S3` is used as sleep default add `mem_sleep_default=deep` to you kernel parameters.

If you're using [systemd-boot](https://wiki.archlinux.org/index.php/Systemd-boot) your
`/boot/loader/entries/arch.conf` might look like this:

```text
title		Arch Linux ACPI
linux		/vmlinuz-linux
initrd		/intel-ucode.img
initrd		/acpi_override
initrd		/initramfs-linux.img
options		root=/dev/nvme0n1p2 rw i915.enable_guc=3 mem_sleep_default=deep
```

If you're using [grub](https://wiki.archlinux.org/index.php/GRUB) edit `/etc/default/grub`
and add the following:

```
GRUB_EARLY_INITRD_LINUX_CUSTOM=acpi_override
GRUB_CMDLINE_LINUX_DEFAULT="quiet mem_sleep_default=deep"
```

Then run `sudo update-grub`. To verify the setting has been applied correctly run
`sudo cat /boot/grub/grub.cfg | grep initrd` and you should see:

```
initrd  /boot/intel-ucode.img /boot/acpi_override /boot/initramfs-4.19-x86_64.img
```

### Other boot loaders

If you made it work with other boot loaders please help out (PRs are most welcome).

#### Some notes

- `/acpi_override` must be specified before `/initramfs…`.
- When using a single partiion try using `/boot/acpi_override` instead of `acpi_override`.
  Use the same prefix (if any) used by the existing `/prefix/initramfs-linux.img` parameter.

## Verify that it's working

After rebooting check the output of:
```bash
dmesg | grep -i "acpi: (supports"
```
should look like this:
```bash
[    0.230796] ACPI: (supports S0 S3 S4 S5)
```

## See also

Esonn did an initial [blog post](https://delta-xi.net/#056) about my patch with
some more detailed explanation.
