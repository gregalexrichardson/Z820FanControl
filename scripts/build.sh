#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
kernel_version="${1:-$(uname -r)}"
kernel_build="/lib/modules/${kernel_version}/build"

if [[ ! -e "${kernel_build}" ]]; then
	printf 'Kernel build headers not found: %s\n' "${kernel_build}" >&2
	exit 1
fi

make -C "${repo_root}/src" KVER="${kernel_version}"
