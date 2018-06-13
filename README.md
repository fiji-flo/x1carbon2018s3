# Suspend for the X1 Carbon 2018

Unfortunately the X1 Carbon 2018 does not support suspend on Linux. There's an ongoing discussion in
the [Lenovo Support Forums](https://forums.lenovo.com/t5/Linux-Discussion/X1-Carbon-Gen-6-cannot-enter-deep-sleep-S3-state-aka-Suspend-to/td-p/3998182).
With some help from the [Arch Linux Community](https://bbs.archlinux.org/viewtopic.php?id=234913), I was able to create an
[ACPI override for the DSDT](https://wiki.archlinux.org/index.php/DSDT). This enables full support of S3 suspend on Linux.

## Prerequisites

This guide is written for Arch Linux but should work with any distribution out there.

### BIOS version

The current BIOS version for the X1 Carbon 2018 is `1.22`. You can download the update ISO from
the [Lenovo Support Site](https://pcsupport.lenovo.com/de/en/products/LAPTOPS-AND-NETBOOKS/THINKPAD-X-SERIES-LAPTOPS/THINKPAD-X1-CARBON-6TH-GEN-TYPE-20KH-20KG/downloads/DS502282).


#### BIOS update

If you wanna update via USB drive use [geteltorito](https://aur.archlinux.org/packages/geteltorito/).

```bash
geteltorito -o x1c2018-122.img bios_g6/n23ur06w.iso
sudo dd if=x1c2018-122.img of=/dev/sdX bs=512K
```

Reboot from USB and follow instructions.


### Tools
Make sure that you have `iasl` (via [acpica](https://www.archlinux.org/packages/community/x86_64/acpica/)) and `cpio`
(via [cpio](https://www.archlinux.org/packages/extra/x86_64/cpio/)) installed.

### BIOS settings
* Set `Thunderbolt BIOS Assist Mode` to `Enabled` (via `Config` → `Thunderbolt 3`).
* _(Unconfirmed):_ Disable `Secure Boot`


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
