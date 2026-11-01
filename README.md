# HP Z820 Fan Control for Linux

This project adds software fan controls to the HP Z820 Workstation on Linux. It
packages a modified version of the Linux `hp_wmi_sensors` hardware-monitoring
driver as a DKMS module. On a supported Z820, the existing WMI temperatures and
fan tachometers remain available, and six writable `pwm1`–`pwm6` controls are
added to the same hwmon device.

The controls set the fans' BIOS-style idle floor. They do not provide a
temperature curve or stop a fan. Use a userspace controller such as
[CoolerControl](https://docs.coolercontrol.org/) to apply a curve.

## Quick start

### Requirements

- An HP Z820 Workstation. The driver checks the system's DMI identity and does
  not expose these controls on other models.
- Linux kernel headers for the running kernel, DKMS, `make`, and a C compiler.
- Root access to install and reload the kernel module.

Install the requirements using your distribution's package manager, then run
these commands from the project directory:

```sh
sudo ./scripts/install.sh
```

The installer builds and installs the module for the running kernel, then
reloads `hp_wmi_sensors`. To check that the controls appeared and see their
current values:

```sh
for h in /sys/class/hwmon/hwmon*; do
  [ "$(cat "$h/name" 2>/dev/null)" = hp_wmi_sensors ] || continue
  printf 'Device: %s\n' "$h"
  for f in "$h"/pwm[1-6] "$h"/fan*_input; do
    [ -r "$f" ] && printf '%s: %s\n' "${f##*/}" "$(cat "$f")"
  done
done
```

In CoolerControl, select the `hp_wmi_sensors` device and configure a
conservative curve for a mapped channel. On the tested machine, `pwm3` raises
the CPU0 fan and `pwm5` raises both front fans together. The other four
channels do not yet have a confirmed fan mapping. Change settings gradually
and watch the fan tachometers and temperatures.

To remove the DKMS module and return to the distribution driver:

```sh
sudo ./scripts/uninstall.sh
```

## How the controls work

Linux presents each control on the standard
[hwmon sysfs interface](https://docs.kernel.org/hwmon/sysfs-interface.html).
The interface range is 0–255, mapped by the driver to the Z820 BIOS Fan Idle
Mode register range `0x2b`–`0x94`. These values are not literal duty-cycle
percentages: `pwmN=0` means the lowest observed BIOS fan floor, not fan stop.
The driver verifies register writes and does not create `pwmN_enable`, because
no automatic/manual mode bit has been identified for these outputs.

| Control | Register | Finding on the tested Z820 |
| --- | --- | --- |
| `pwm1` | `0x198` | No clear, repeatable fan response identified |
| `pwm2` | `0x199` | No clear, repeatable fan response identified |
| `pwm3` | `0x19a` | CPU0 fan speed rises with the setting |
| `pwm4` | `0x19b` | No clear, repeatable fan response identified |
| `pwm5` | `0x19c` | Both front fan speeds rise together |
| `pwm6` | `0x19d` | No clear, repeatable fan response identified |

The driver saves all six register values when it loads and restores them when
it unloads. If the I/O range `0x800`–`0x8ff` is already owned by another
driver, the WMI sensors remain available but the PWM controls are omitted.
Firmware access and unrelated raw port-I/O programs are not synchronized with
this driver.

These register mappings and fan responses were examined on one Z820 and have
not been verified across every hardware or firmware revision. Begin with
small changes and avoid assigning curves to unmapped channels. See the
[hardware mapping notes](docs/hardware-mapping.md) for test details and
limitations.

## Build without installing

To build against the running kernel, with its headers installed:

```sh
./scripts/build.sh
```

To select another installed kernel, pass its release string:

```sh
./scripts/build.sh <kernel-release>
```

## Source and license

The driver is based on upstream Linux [`hp_wmi_sensors.c`](https://github.com/torvalds/linux/blob/v7.2/drivers/hwmon/hp-wmi-sensors.c)
from v7.2. See [source provenance](SOURCE.md) and the [GPL-2.0-or-later
license](LICENSE).
