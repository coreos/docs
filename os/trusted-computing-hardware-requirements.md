# Checking hardware and firmware support for CoreOS Container Linux Trusted Computing

Trusted Computing requires support in both system hardware and firmware. This document specifies the required support and explains how to determine if a physical machine has the features needed to enable Trusted Computing in Container Linux.

## 1. Check for Trusted Platform Module

Trusted Computing depends on the presence of a Trusted Platform Module (TPM). The TPM is a motherboard component responsible for storing the state of the system boot process, and providing a secure communication channel over which this state can be verified. To check for the presence of a TPM, install the latest Alpha version of Container Linux and try to list the TPM device file in the `/sys` system control filesystem:

`# ls /sys/class/tpm/tpm0`

If this returns an error, the system either does not have a TPM, or it is not enabled in the system firmware. Firmware configuration varies by system. Consult vendor documentation for details.

## 2. Check TPM version

Version 1.2 TPMs are currently supported. Read the TPM device ID file to discover the TPM version:

`# cat /sys/class/tpm/tpm0/device/id`

The contents of the `id` file vary for supported version 1.2 TPMs. It is simplest to check that the file does *not* contain the known string for unsupported version 2.0 TPMs, `MSFT0101`. Almost any other non-zero, non-error output from reading the `id` file indicates a supported version 1.2 TPM.

Support for version 2.0 TPMs identified with the `MSFT0101` string will be added in a future Container Linux release.

## 3. Check TPM is enabled and active

The TPM device provides control files in the `/sys` filesystem, as seen above. Read the `enabled` and `active` files to check TPM status:

```sh
# cat /sys/class/tpm/tpm0/device/enabled
# cat /sys/class/tpm/tpm0/device/active
```

If either of these commands prints "0", reconfigure the TPM by writing a code for TPM activation at the next system boot to the PPI `request` file:

`# echo 6 > /sys/class/tpm/tpm0/device/ppi/request`

Reboot the system and check TPM status again, as in Step 3.

## 4. Check boot measurement

The Container Linux bootloader will record the state of boot components during the boot process &mdash; *measuring* each part, in TPM parlance, and storing the result in its Platform Configuration Registers (PCR). Verify that this measurement has been successful by reading the TPM device's `pcrs` file, a textual representation of the contents of all PCRs:

`# cat /sys/class/tpm/tpm0/device/pcrs`

Boot component measurements are recorded in PCRs 9 through 13. These positions in `pcrs` should all contain meaningful values; that is, values that are neither `0`:

`00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00`

nor *max*:

`FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF`

## Trusted

A system that passes each of the above tests supports Container Linux Trusted Computing and is actively measuring the boot process over the secure TPM channel.
