# Validating hardware and firmware support for Trusted Computing in CoreOS

Trusted Computing requires support in both system hardware and
firmware. This document will allow you to determine whether your sytems
implement the features required to support Trusted Computing under CoreOS.

## Ensure that the system has a Trusted Platform Module

Trusted Computing depends on the presence of a Trusted Platform Module,
commonly referred to as a TPM. The TPM is responsible for storing the state
of the system boot process and providing a secure communication channel in
order to allow this state to be verified. To check for the presence of a
TPM, install the latest Alpha version of CoreOS and run:

`# ls /sys/class/tpm/tpm0`

If this returns an error, your system either does not have a TPM or it is
not enabled in the system firmware. Firmware configuration will vary
depending on system - please consult your vendor documentation for details.

## Check the TPM version

Only version 1.2 TPMs are supported at present. Run

`# cat /sys/class/tpm/tpm0/device/id`

If this returns MSFT0101 then you have a version 2.0 TPM. Support for
version 2.0 devices will be added in future releases of CoreOS.

## Check that the TPM is enabled and active

Run

```sh
# cat /sys/class/tpm/tpm0/device/enabled
# cat /sys/class/tpm/tpm0/device/active
```

If either of these commands prints "0", reconfigure the TPM by running

`# echo 6 >/sys/class/tpm/tpm0/device/ppi/request`

and then reboot the system.

## Ensure that the boot process is being measured

The CoreOS bootloader will record the state of boot components during the
boot process. Verify that this has been successful by running

`# cat /sys/class/tpm/tpm0/device/pcrs`

PCRs 9, 10, 11, 12 and 13 should all contain values that are not either

`00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00`

or

`FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF`

If all these tests pass, your system is compatible with Trusted Computing.