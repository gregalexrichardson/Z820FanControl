#!/usr/bin/env bash
set -euo pipefail

readonly package_name="z820fancontrol"
readonly package_version="0.1.0"
readonly module_name="hp_wmi_sensors"
readonly kernel_version="${KVER:-$(uname -r)}"
readonly repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly dkms_source="/usr/src/${package_name}-${package_version}"

if (( EUID != 0 )); then
	printf 'Run this installer as root, for example: sudo %s\n' "$0" >&2
	exit 1
fi

if ! command -v dkms >/dev/null 2>&1; then
	printf 'DKMS is required. Install DKMS and the headers for %s first.\n' \
		"${kernel_version}" >&2
	exit 1
fi

if [[ ! -e "/lib/modules/${kernel_version}/build" ]]; then
	printf 'Kernel build headers not found for %s.\n' "${kernel_version}" >&2
	exit 1
fi

install -d -m 0755 "${dkms_source}"
install -m 0644 "${repo_root}/dkms.conf" "${dkms_source}/dkms.conf"
install -m 0644 "${repo_root}/src/Makefile" "${dkms_source}/Makefile"
install -m 0644 "${repo_root}/src/hp_wmi_sensors.c" \
	"${dkms_source}/hp_wmi_sensors.c"

if ! dkms status -m "${package_name}" -v "${package_version}" | \
	grep -Fq "${package_name}/${package_version}"; then
	dkms add -m "${package_name}" -v "${package_version}"
fi

dkms build -m "${package_name}" -v "${package_version}" -k "${kernel_version}"
dkms install -m "${package_name}" -v "${package_version}" -k "${kernel_version}"
depmod -a "${kernel_version}"

if lsmod | awk -v name="${module_name}" '$1 == name { found = 1 } END { exit !found }'; then
	if ! modprobe -r "${module_name}"; then
		printf 'The overlay is installed, but %s is busy and could not be reloaded. Reboot to activate it.\n' \
			"${module_name}" >&2
		exit 1
	fi
fi

if ! modprobe "${module_name}"; then
	printf 'The replacement module failed to load; removing the overlay and restoring the stock driver.\n' >&2
	dkms remove -m "${package_name}" -v "${package_version}" -k "${kernel_version}" || true
	depmod -a "${kernel_version}"
	modprobe "${module_name}" || true
	exit 1
fi

printf 'Installed and loaded %s for kernel %s.\n' "${package_name}" "${kernel_version}"
printf 'PWM controls are available as pwm1 through pwm6 on the hp_wmi_sensors hwmon device.\n'
