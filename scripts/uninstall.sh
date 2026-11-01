#!/usr/bin/env bash
set -euo pipefail

readonly package_name="z820fancontrol"
readonly package_version="0.1.0"
readonly module_name="hp_wmi_sensors"
readonly kernel_version="${KVER:-$(uname -r)}"
readonly dkms_source="/usr/src/${package_name}-${package_version}"

if (( EUID != 0 )); then
	printf 'Run this uninstaller as root, for example: sudo %s\n' "$0" >&2
	exit 1
fi

if ! command -v dkms >/dev/null 2>&1; then
	printf 'DKMS is required to remove this installation.\n' >&2
	exit 1
fi

dkms remove -m "${package_name}" -v "${package_version}" --all
depmod -a "${kernel_version}"

# Unloading the overlay restores the fan register values captured at load time.
if lsmod | awk -v name="${module_name}" '$1 == name { found = 1 } END { exit !found }'; then
	modprobe -r "${module_name}"
fi

# With the DKMS copy removed, module resolution falls back to the distribution driver.
modprobe "${module_name}"
rm -rf -- "${dkms_source}"

printf 'Removed %s and loaded the distribution %s driver.\n' \
	"${package_name}" "${module_name}"
