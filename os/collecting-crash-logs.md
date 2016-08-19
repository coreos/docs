# Collecting crash logs

In the unfortunate case that an OS crashes, it's often extremely helpful to gather information about the event. There are two popular tools used to accomplished this goal: kdump and pstore. CoreOS relies on pstore, a persistent storage abstraction provided by the Linux kernel, to store logs in the event of a kernel panic. Since this mechanism is just an abstraction, it depends on hardware support to actually persist the data across reboots. If the hardware support is absent, the pstore will remain empty. On AMD64 machines, pstore is typically backed by the ACPI error record serialization table (ERST).

## Using pstore

On CoreOS, the pstore is automatically mounted to `/sys/fs/pstore`. The contents of the store can be explored using standard filesystem tools:

```
$ ls /sys/fs/pstore/
```

On this particular machine, there isn't anything in the pstore yet. In order to test the mechanism, a kernel panic can be triggered:

```
$ echo c > /proc/sysrq-trigger
```

Once the machine boots, the pstore can again be inspected:

```
$ ls /sys/fs/pstore/
dmesg-erst-6319986351055831041  dmesg-erst-6319986351055831044
dmesg-erst-6319986351055831042  dmesg-erst-6319986351055831045
dmesg-erst-6319986351055831043
```

Now there are a series of dmesg logs, stored in the ACPI ERST. Looking at the first file, the cause of the panic can be discovered:

```
$ cat /sys/fs/pstore/dmesg-erst-6319986351055831041
Oops#1 Part1
...
<6>[  201.650687] sysrq: SysRq : Trigger a crash
<1>[  201.654822] BUG: unable to handle kernel NULL pointer dereference at           (null)
<1>[  201.662670] IP: [<ffffffffbd3d1956>] sysrq_handle_crash+0x16/0x20
<4>[  201.668783] PGD 0 
<4>[  201.670809] Oops: 0002 [#1] SMP
<4>[  201.673948] Modules linked in: coretemp sb_edac edac_core x86_pkg_temp_thermal kvm_intel ipmi_ssif kvm mei_me irqbypass i2c_i801 mousedev evdev mei ipmi_si ipmi_msghandler tpm_tis button tpm sch_fq_codel ip_tables hid_generic usbhid hid sd_mod squashfs loop igb ahci xhci_pci ehci_pci i2c_algo_bit libahci xhci_hcd ehci_hcd i2c_core libata i40e hwmon usbcore ptp crc32c_intel scsi_mod usb_common pps_core dm_mirror dm_region_hash dm_log dm_mod autofs4
<4>[  201.714354] CPU: 0 PID: 1899 Comm: bash Not tainted 4.7.0-coreos #1
<4>[  201.720612] Hardware name: Supermicro SYS-F618R3-FT/X10DRFF, BIOS 1.0b 01/07/2015
<4>[  201.728083] task: ffff881fdca79d40 ti: ffff881fd92d0000 task.ti: ffff881fd92d0000
<4>[  201.735553] RIP: 0010:[<ffffffffbd3d1956>]  [<ffffffffbd3d1956>] sysrq_handle_crash+0x16/0x20
<4>[  201.744083] RSP: 0018:ffff881fd92d3d98  EFLAGS: 00010286
<4>[  201.749388] RAX: 000000000000000f RBX: 0000000000000063 RCX: 0000000000000000
<4>[  201.756511] RDX: 0000000000000000 RSI: ffff881fff80dbc8 RDI: 0000000000000063
<4>[  201.763635] RBP: ffff881fd92d3d98 R08: ffff88407ff57b80 R09: 00000000000000c2
<4>[  201.770759] R10: ffff881fe4fab624 R11: 00000000000005dd R12: 0000000000000007
<4>[  201.777885] R13: 0000000000000000 R14: ffffffffbdac37a0 R15: 0000000000000000
<4>[  201.785009] FS:  00007fa68acee700(0000) GS:ffff881fff800000(0000) knlGS:0000000000000000
<4>[  201.793085] CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
<4>[  201.798825] CR2: 0000000000000000 CR3: 0000001fdcc97000 CR4: 00000000001406f0
<4>[  201.805949] Stack:
<4>[  201.807961]  ffff881fd92d3dc8 ffffffffbd3d2146 0000000000000002 fffffffffffffffb
<4>[  201.815413]  00007fa68acf6000 ffff883fe2e46f00 ffff881fd92d3de0 ffffffffbd3d259f
<4>[  201.822866]  ffff881fe4fab5c0 ffff881fd92d3e00 ffffffffbd24fda8 ffff883fe2e46f00
<4>[  201.830320] Call Trace:
<4>[  201.832769]  [<ffffffffbd3d2146>] __handle_sysrq+0xf6/0x150
<4>[  201.838331]  [<ffffffffbd3d259f>] write_sysrq_trigger+0x2f/0x40
<4>[  201.844244]  [<ffffffffbd24fda8>] proc_reg_write+0x48/0x70
<4>[  201.849723]  [<ffffffffbd1e4697>] __vfs_write+0x37/0x140
<4>[  201.855038]  [<ffffffffbd283e0d>] ? security_file_permission+0x3d/0xc0
<4>[  201.861561]  [<ffffffffbd0c1062>] ? percpu_down_read+0x12/0x60
<4>[  201.867383]  [<ffffffffbd1e55b8>] vfs_write+0xb8/0x1a0
<4>[  201.872514]  [<ffffffffbd1e6a25>] SyS_write+0x55/0xc0
<4>[  201.877562]  [<ffffffffbd003c6d>] do_syscall_64+0x5d/0x150
<4>[  201.883047]  [<ffffffffbd58e161>] entry_SYSCALL64_slow_path+0x25/0x25
<4>[  201.889474] Code: df ff 48 c7 c7 f3 a3 7d bd e8 47 c5 d3 ff e9 de fe ff ff 66 90 0f 1f 44 00 00 55 c7 05 48 b4 66 00 01 00 00 00 48 89 e5 0f ae f8 <c6> 04 25 00 00 00 00 01 5d c3 0f 1f 44 00 00 55 31 c0 c7 05 5e 
<1>[  201.909425] RIP  [<ffffffffbd3d1956>] sysrq_handle_crash+0x16/0x20
<4>[  201.915615]  RSP <ffff881fd92d3d98>
<4>[  201.919097] CR2: 0000000000000000
<4>[  201.922450] ---[ end trace 8794939ba0598b91 ]---
```

The cause of the panic was a system request! The remaining files in the pstore contain more of the logs leading up to the panic as well as more context. Each of the files has a small, descriptive header describing the source of the logs. Looking at each of the headers shows the rough structure of the logs:

```
$ head --lines=1 /sys/fs/pstore/dmesg-erst-6319986351055831041
Oops#1 Part1

$ head --lines=1 /sys/fs/pstore/dmesg-erst-6319986351055831042
Oops#1 Part2

$ head --lines=1 /sys/fs/pstore/dmesg-erst-6319986351055831043
Panic#2 Part1

$ head --lines=1 /sys/fs/pstore/dmesg-erst-6319986351055831044
Panic#2 Part2

$ head --lines=1 /sys/fs/pstore/dmesg-erst-6319986351055831045
Panic#2 Part3
```

It is important to note that the pstore typically has very limited storage space (on the order of kilobytes) and will not overwrite entries when out of space. The files in `/sys/fs/pstore` must be removed to free up space. The typical approach is to move the files from the pstore to a more permanent storage location on boot, but CoreOS will not do this automatically for you.
