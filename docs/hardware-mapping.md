# Z820 HWM output mapping

## Channel order

The six controls retain the HWM register order:

| hwmon file | Page 1 offset | Probe address | Result on the tested machine |
| --- | ---: | ---: | --- |
| `pwm1` | `0x98` | `0x198` | No repeatable single-fan response established |
| `pwm2` | `0x99` | `0x199` | No repeatable single-fan response established |
| `pwm3` | `0x9a` | `0x19a` | CPU0 fan RPM increased by about 250 RPM for `0x2b` → `0x33` |
| `pwm4` | `0x9b` | `0x19b` | No clear fan response in the limited test |
| `pwm5` | `0x9c` | `0x19c` | Both front fan RPMs increased by about 46–48 RPM for `0x2b` → `0x33` |
| `pwm6` | `0x9d` | `0x19d` | No clear fan response in the limited test |

The two `pwm5` front-fan tach readings returned near baseline after restoring
`0x2b`, and remained elevated while `0x33` was held. This identifies a front
fan pair, not separate outputs for the top and bottom fans. HP's service guide
lists Front Fan 1 (top) and Front Fan 2 (bottom) separately, and lists their
separate board headers, but the measured control response is shared.

## BIOS range normalization

The tested firmware maps the BIOS idle profiles to these register values:

| Fan Idle Mode | Value written to each register |
| --- | ---: |
| `+-----` | `0x2b` (43) |
| `++----` | `0x34` (52) |
| `+++---` | `0x43` (67) |
| `++++--` | `0x58` (88) |
| `+++++-` | `0x73` (115) |
| `++++++` | `0x94` (148) |

The driver linearly maps the hwmon range 0–255 onto register range `0x2b`–
`0x94`. This is only an interface conversion. The available evidence does not
show that actual fan RPM varies linearly with the register or that each of the
six outputs controls a separate fan.

## HWM protocol and serialization

The control bytes are in page 1 of the Nuvoton HWM window at I/O base `0x800`;
the selector is at `0x8ff`. A write reads page 0 offset `0x04`, clears bit 0,
writes the selected page 1 output, restores bit 0, then verifies the byte. The
driver returns the selector to page 0 after each operation.

The WMI sensor polling path and PWM operations use the same driver mutex, so
they do not race each other on the shared page selector. This does not lock
firmware SMM accesses or raw I/O by unrelated software; avoid running another
program that changes the HWM selector or these registers while the driver is
active.

## Evidence limits

The mapping tests used `+-----` as the common `0x2b` baseline and raised one
register by eight. This verified `0x19a` and `0x19c` behavior and the verified
write/restore sequence. It did not establish the full continuous fan response
curve. The driver does not use the Z840 NCT7491 mailbox mapping: the Z820's
NCT7491-style controller probe did not find the Z840 controller at the tested
address, and that route did not identify the front fan outputs.

HP's service guide describes Fan Idle Mode as setting system-fan rate while the
CPU is idle and identifies the Z820 front fans separately. See the [service
guide](https://h10032.www1.hp.com/ctg/Manual/c04205252.pdf), especially its
system-board component and Fan Idle Mode sections. Firmware register mapping
and live RPM observations above come from the tested machine, not HP's public
register documentation.
