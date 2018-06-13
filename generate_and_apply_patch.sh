#!/usr/bin/env bash
BIOS_REVISION=1.22
BOOT=${1:-/boot}

sudo dmidecode | grep "BIOS Revision: ${BIOS_REVISION}" \
    || (echo "This patch only work with BIOS REVISION ${BIOS_REVISION}" \
             && exit 1)

mkdir -p /tmp/x1carbon2018s3
cd /tmp/x1carbon2018s3

# extract dsdt
sudo sh -c 'cat /sys/firmware/acpi/tables/DSDT' > dsdt.dat
# decompile
iasl -d dsdt.dat
# download patch
if [ ! -f X1C2018_S3_DSDT.patch ]; then
    curl -O https://raw.githubusercontent.com/fiji-flo/x1carbon2018s3/master/X1C2018_S3_DSDT.patch
fi
# apply patch
patch -p0 < X1C2018_S3_DSDT.patch
# compile
iasl -tc -ve dsdt.dsl
# genereate override
mkdir -p kernel/firmware/acpi
find kernel | cpio -H newc --create > acpi_override

# copy override file to boot partition
sudo cp acpi_override ${BOOT}

# optimistic check for bootloader configuration
grep -qir acpi_override ${BOOT} || \
    echo "Don't forget up update your bootloader config."
