# Source provenance

`src/hp_wmi_sensors.c` is derived from the Linux kernel's
`drivers/hwmon/hp-wmi-sensors.c`, upstream tag [`v7.2`](https://github.com/torvalds/linux/blob/v7.2/drivers/hwmon/hp-wmi-sensors.c).
The Z820 changes add DMI-gated access to HWM page 1 offsets `0x98`–`0x9d`,
standard hwmon PWM attributes, BIOS-range normalization, and restore-on-unload
of the values captured when the module loads.

The upstream driver's author/copyright notice and SPDX identifier are retained
in the source. The derivative is distributed under GPL-2.0-or-later; see
[LICENSE](LICENSE).
