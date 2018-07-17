#!/usr/bin/env bash
BOOT=${1:-/boot}

cd `mktemp -d`

# extract dsdt
sudo cat /sys/firmware/acpi/tables/DSDT > dsdt.dat
# decompile
iasl -d dsdt.dat

cp dsdt.dsl dsdt.dsl.orig

cat dsdt.dsl |
  tr '\n' '\r' |
  sed -e 's|DefinitionBlock ("", "DSDT", 2, "LENOVO", "SKL     ", 0x00000000)|DefinitionBlock ("", "DSDT", 2, "LENOVO", "SKL     ", 0x00000001)|' \
      -e 's|Name (SS3, One)\r    One\r    Name (SS4, One)\r    One|Name (SS3, One)\r    Name (SS4, One)|' \
      -e 's|\_SB.SGOV (DerefOf (Arg0 \[0x02\]), (DerefOf (Arg0 \[0x03\]) ^ \r                            0x01))|\_SB.SGOV (DerefOf (Arg0 [0x02]), (DerefOf (Arg0 [0x03]) ^ 0x01))|' \
      -e 's|    Name (\\\_S4, Package (0x04)  // _S4_: S4 System State|    Name (\\\_S3, Package (0x04)  // _S3_: S3 System State\r    {\r        0x05,\r        0x05,\r        0x00,\r        0x00\r    })\r    Name (\\\_S4, Package (0x04)  // _S4_: S4 System State|' |
  tr '\r' '\n' > dsdt_patched.dsl

mv dsdt_patched.dsl dsdt.dsl

# compile
iasl -tc -ve dsdt.dsl
# generate override
mkdir -p kernel/firmware/acpi
cp dsdt.aml kernel/firmware/acpi
find kernel | cpio -H newc --create > acpi_override

# copy override file to boot partition
sudo cp acpi_override ${BOOT}

# optimistic check for bootloader configuration
grep -qir acpi_override ${BOOT} || \
    echo "Don't forget to update your bootloader config."
