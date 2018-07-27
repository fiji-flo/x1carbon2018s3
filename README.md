# Suspend for the "Thinkpad X1 Carbon (6th Gen)" on Linux

Unfortunately the ThinkPad X1 Carbon (6th Gen) aka (X1C6 and X1 Carbon 2018) does not support suspend on Linux. There's an ongoing discussion in
the [Lenovo Support Forums](https://forums.lenovo.com/t5/Linux-Discussion/X1-Carbon-Gen-6-cannot-enter-deep-sleep-S3-state-aka-Suspend-to/td-p/3998182).
With some help from the [Arch Linux Community](https://bbs.archlinux.org/viewtopic.php?id=234913), I was able to create an
[ACPI override for the DSDT](https://wiki.archlinux.org/index.php/DSDT). This enables full support of S3 suspend on Linux.

## Prerequisites

Debian/Ubuntu based distro with initramfs-tools based initramfs generation for fully automated setup apart from the BIOS related things.

For other distros there are some further steps needed. (PRs welcome)

### (Optional) BIOS version

The current BIOS version for the X1C6 is `1.25`. You can download the update ISO from
the [Lenovo Support Site](https://pcsupport.lenovo.com/de/en/products/LAPTOPS-AND-NETBOOKS/THINKPAD-X-SERIES-LAPTOPS/THINKPAD-X1-CARBON-6TH-GEN-TYPE-20KH-20KG/downloads/DS502282).


#### BIOS update

If you wanna update via USB drive use [geteltorito](https://aur.archlinux.org/packages/geteltorito/).

```bash
geteltorito -o x1c2018-125.img n23ur08w.iso
sudo dd if=x1c2018-125.img of=/dev/sdX bs=512K
```

Reboot from USB and follow instructions.

### BIOS settings
* Set `Thunderbolt BIOS Assist Mode` to `Enabled` (via `Config` → `Thunderbolt 3`).
* _(Unconfirmed):_ Disable `Secure Boot`.

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
