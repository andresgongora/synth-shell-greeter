#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

##==================================================================================================
##	`sensors` output from real machines, so a change to getCPUTempLine() or
##	_cpuTempFields() has to keep working on hardware that is not the author's.
##
##	Each sample is verbatim, trimmed to the blocks up to and including the
##	CPU one, with every chip block cut to its first three lines. Hostnames
##	are not in `sensors` output; nothing else is masked.
##
##	⚠ The parsing runs under LC_ALL=C, because that is what the greeter does
##	to itself (see the tail of synth-shell-greeter.sh). Without that, a
##	pattern that is broken in the C locale passes this file.
##==================================================================================================

export LC_ALL=C

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
# shellcheck source=test/support/testlib.sh
source "$SCRIPT_DIR/support/testlib.sh"

test_root="$(createTestRoot cpu-temp-hosts)"
mkdir -p "$test_root/bin"
# shellcheck disable=SC2016
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$SENSORS_OUTPUT"\n' >"$test_root/bin/sensors"
printf '#!/usr/bin/env bash\nIFS= read -r _ || :\nprintf "1\\n"\n' >"$test_root/bin/bc"
chmod +x "$test_root/bin/sensors" "$test_root/bin/bc"
PATH="$test_root/bin:$PATH"
export SENSORS_OUTPUT

set +u
# shellcheck disable=SC1091
source "$PROJECT_ROOT/synth-shell-greeter/info.sh"
set -u

printInfoLine() { INFO_RESULT="$1|$2|${3:-}"; }
printResourceMonitor() { MONITOR_RESULT="$1|$2|$3|$4|$5|$6"; }

##	host <name> <expected printInfoCPUTemp result>, with the sample on stdin
host() {
	local name="$1"
	local expected="$2"

	SENSORS_OUTPUT="$(cat)"
	INFO_RESULT=
	printInfoCPUTemp
	[[ "$INFO_RESULT" == "$expected" ]] || \
		die "$name: expected '$expected', got '$INFO_RESULT'"
}

##	monitor <name> <expected printMonitorCPUTemp result>, with the sample on
##	stdin. The bar goes through printResourceMonitor (current, max, units,
##	crit percentage); "unavailable" goes through printInfoLine instead, so
##	whichever of the two was called is what gets compared.
monitor() {
	local name="$1"
	local expected="$2"

	SENSORS_OUTPUT="$(cat)"
	INFO_RESULT=
	MONITOR_RESULT=
	printMonitorCPUTemp
	local got="${MONITOR_RESULT:-$INFO_RESULT}"
	[[ "$got" == "$expected" ]] || \
		die "$name (monitor): expected '$expected', got '$got'"
}

##==================================================================================================
##	REAL MACHINES
##==================================================================================================

## HP ProLiant ML350 Gen9, Xeon E5-2698 v4. A tg3 NIC is listed first and it
## does carry high and crit, so before 1786471 its 53 C was shown as the CPU
## temperature.
host 'ML350 Gen9, NIC first' 'CPU temp|69.0°C|nominal' <<'EOF'
tg3-pci-0200
Adapter: PCI adapter
temp1:        +53.0°C  (high = +100.0°C, crit = +110.0°C)

power_meter-acpi-0
Adapter: ACPI interface
power1:      182.00 W  (interval = 300.00 s)

be2net-pci-0d00
Adapter: PCI adapter
temp1:        +44.0°C  

coretemp-isa-0000
Adapter: ISA adapter
Package id 0:  +69.0°C  (high = +95.0°C, crit = +105.0°C)
EOF

## The same machine as the greeter sees it: LC_ALL=C, so no degree sign.
host 'ML350 Gen9, C locale' 'CPU temp|33.0°C|nominal' <<'EOF'
tg3-pci-0200
Adapter: PCI adapter
temp1:        +51.0 C  (high = +100.0 C, crit = +110.0 C)

power_meter-acpi-0
Adapter: ACPI interface
power1:      107.00 W  (interval = 300.00 s)

coretemp-isa-0000
Adapter: ISA adapter
Package id 0:  +33.0 C  (high = +95.0 C, crit = +105.0 C)
EOF

## Lenovo ThinkSystem ST550, Xeon Gold 5218. The chipset comes first and
## carries no thresholds at all.
host 'ThinkSystem ST550, chipset first' 'CPU temp|44.0°C|nominal' <<'EOF'
power_meter-acpi-0
Adapter: ACPI interface
power1:      113.00 W  (interval =   1.00 s)

pch_lewisburg-virtual-0
Adapter: Virtual device
temp1:        +40.0°C  

be2net-pci-0800
Adapter: PCI adapter
temp1:        +51.0°C  

coretemp-isa-0000
Adapter: ISA adapter
Package id 0:  +44.0°C  (high = +88.0°C, crit = +98.0°C)
EOF

## Lenovo ThinkSystem SR650 V3, two Xeon Gold 6430: coretemp is first and
## there are two packages. The first one is the one reported.
host 'SR650 V3, two sockets' 'CPU temp|37.0°C|nominal' <<'EOF'
coretemp-isa-0000
Adapter: ISA adapter
Package id 0:  +37.0°C  (high = +82.0°C, crit = +90.0°C)

nvme-pci-0300
Adapter: PCI adapter
Composite:    +56.9°C  (low  = -273.1°C, high = +95.8°C)

coretemp-isa-0001
Adapter: ISA adapter
Package id 1:  +38.0°C  (high = +82.0°C, crit = +90.0°C)
EOF

## Lenovo System x3500 M5, two Xeon E5-2640 v3.
host 'x3500 M5, two sockets' 'CPU temp|36.0°C|nominal' <<'EOF'
coretemp-isa-0000
Adapter: ISA adapter
Package id 0:  +36.0°C  (high = +77.0°C, crit = +87.0°C)

pch_wellsburg-virtual-0
Adapter: Virtual device
temp1:        +33.5°C  
EOF

## MSI MS-7D46 workstation, Core i7-12700.
host 'Core i7-12700 workstation' 'CPU temp|37.0°C|nominal' <<'EOF'
coretemp-isa-0000
Adapter: ISA adapter
Package id 0:  +37.0°C  (high = +80.0°C, crit = +100.0°C)

acpitz-acpi-0
Adapter: ACPI interface
temp1:        +27.8°C  
EOF

##==================================================================================================
##	MACHINES I DO NOT HAVE
##
##	Shapes taken from `sensors` documentation and bug reports rather than
##	captured, and marked as such.
##==================================================================================================

## A CPU that reports under a plain "temp1": no label to match, so this is
## the chip-block fallback. Raspberry Pi shape.
host 'cpu_thermal, no label' 'CPU temp|45.0°C|nominal' <<'EOF'
cpu_thermal-virtual-0
Adapter: Virtual device
temp1:        +45.0°C  
EOF

## Pre-Zen AMD under k10temp, same situation but with thresholds.
host 'k10temp, no label' 'CPU temp|40.0°C|nominal' <<'EOF'
k10temp-pci-00c3
Adapter: PCI adapter
temp1:        +40.0°C  (high = +70.0°C, crit = +100.0°C)
EOF

## A NIC with full thresholds and no CPU chip anywhere: it must stay
## unavailable rather than be reported as the CPU. This is the case 1786471
## was opened for, and the fallback must not undo it.
host 'NIC only, no CPU chip' 'CPU temp|unavailable|' <<'EOF'
be2net-pci-0400
Adapter: PCI adapter
temp1:        +32.0°C  (high = +80.0°C, crit = +90.0°C)
EOF

## An NVMe block puts "(crit = ...)" on a continuation line with no colon,
## which must not be mistaken for a chip header and must not be read as a
## CPU either.
host 'NVMe continuation line' 'CPU temp|38.0°C|nominal' <<'EOF'
nvme-pci-0100
Adapter: PCI adapter
Composite:    +41.9°C  (low  = -273.1°C, high = +84.8°C)
                       (crit = +89.8°C)

coretemp-isa-0000
Adapter: ISA adapter
Package id 0:  +38.0°C  (high = +84.0°C, crit = +100.0°C)
EOF

## Constructed by the maintainer in the review of this pull request, not
## captured from a machine: the current reading is N/A and the only numbers
## on the line are thresholds. The fallback must not read the high threshold
## as the temperature -- a false reading is worse than "unavailable". Both
## the info line and the monitor bar are checked, because both parse it.
host 'k10temp, current N/A' 'CPU temp|unavailable|' <<'EOF'
k10temp-pci-00c3
Adapter: PCI adapter
temp1: N/A (high = +70.0 C, crit = +100.0 C)
EOF
monitor 'k10temp, current N/A' 'CPU temp|unavailable|' <<'EOF'
k10temp-pci-00c3
Adapter: PCI adapter
temp1: N/A (high = +70.0 C, crit = +100.0 C)
EOF

## Constructed by the maintainer in the second review, not captured: the same
## N/A shape under a known label. The label selector returns before the
## fallback runs, so it needs the same guard. The valid line next to it is
## the control: a labelled reading must still be found.
host 'Package id, valid' 'CPU temp|42.0°C|nominal' <<'EOF'
coretemp-isa-0000
Adapter: ISA adapter
Package id 0: +42.0 C (high = +88.0 C, crit = +98.0 C)
EOF
monitor 'Package id, valid' 'CPU temp|42.0|98.0|°C|a/b|1' <<'EOF'
coretemp-isa-0000
Adapter: ISA adapter
Package id 0: +42.0 C (high = +88.0 C, crit = +98.0 C)
EOF
host 'Package id, current N/A' 'CPU temp|unavailable|' <<'EOF'
coretemp-isa-0000
Adapter: ISA adapter
Package id 0: N/A (high = +80.0 C, crit = +100.0 C)
EOF
monitor 'Package id, current N/A' 'CPU temp|unavailable|' <<'EOF'
coretemp-isa-0000
Adapter: ISA adapter
Package id 0: N/A (high = +80.0 C, crit = +100.0 C)
EOF

##==================================================================================================
##	THE MONITOR BAR UNDER THE C LOCALE
##
##	printMonitorCPUTemp() needs the current value AND both thresholds, so it
##	is the stricter of the two consumers. Captured verbatim under LC_ALL=C,
##	i.e. with no degree sign, as the greeter sees them. The stubbed bc
##	always answers 1, so the last field only proves the bar was built.
##==================================================================================================

## Lenovo ThinkSystem ST550, Xeon Gold 5218: chipset and NIC come first.
monitor 'ST550, C locale' 'CPU temp|42.0|98.0|°C|a/b|1' <<'EOF'
power_meter-acpi-0
Adapter: ACPI interface
power1:      113.00 W  (interval =   1.00 s)

pch_lewisburg-virtual-0
Adapter: Virtual device
temp1:        +40.0 C  

be2net-pci-0800
Adapter: PCI adapter
temp1:        +51.0 C  

coretemp-isa-0000
Adapter: ISA adapter
Package id 0:  +42.0 C  (high = +88.0 C, crit = +98.0 C)
EOF

## MSI MS-7D46 workstation, Core i7-12700: a different crit, so the maximum
## is read from the line rather than assumed.
monitor 'Core i7-12700, C locale' 'CPU temp|37.0|100.0|°C|a/b|1' <<'EOF'
coretemp-isa-0000
Adapter: ISA adapter
Package id 0:  +37.0 C  (high = +80.0 C, crit = +100.0 C)
EOF

printf 'PASS: CPU temperature on real hosts\n'
