#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
# shellcheck source=test/support/testlib.sh
source "$SCRIPT_DIR/support/testlib.sh"

test_root="$(createTestRoot gpu-name)"
mkdir -p "$test_root/bin"
# printInfoGPU calls lspci twice: the plain listing, to find the VGA devices,
# and "lspci -v -s <id>" for each of them. The stub answers both and records
# the arguments of every call, so the test also checks which device is asked
# for, not only what is done with the answer.
cat >"$test_root/bin/lspci" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$LSPCI_ARGS"
if [ "$#" -eq 0 ]; then
	printf '%s\n' "$LSPCI_LIST"
else
	printf '%s\n' "$LSPCI_DETAIL"
fi
STUB
chmod +x "$test_root/bin/lspci"
PATH="$test_root/bin:$PATH"
LSPCI_ARGS="$test_root/lspci_args"
LSPCI_LIST=
LSPCI_DETAIL=
export LSPCI_LIST LSPCI_DETAIL LSPCI_ARGS

set +u
# shellcheck disable=SC1091
source "$PROJECT_ROOT/synth-shell-greeter/info.sh"
set -u

printInfoLine() {
	INFO_RESULT="${INFO_RESULT}$1|$2|${3:-};"
}

assertEqual() {
	local expected="$1"
	local actual="$2"

	[[ "$actual" == "$expected" ]] || die "expected '$expected', got '$actual'"
}

# One VGA device per case. Results and the argument log start empty every
# time, so an assertion cannot pass on a value left behind by the previous one.
# The expected arguments are fixed before the call: printInfoGPU loops over a
# variable named "id" that is not local, so the test must not use that name.
checkGPU() {
	local slot="$1"
	local name="$2"
	local detail_tail="$3"
	local expected="$4"
	local expected_args=$'\n'"-v -s $slot"

	INFO_RESULT=
	: >"$LSPCI_ARGS"
	LSPCI_LIST="$slot VGA compatible controller: $name"
	LSPCI_DETAIL="$slot VGA compatible controller: $name$detail_tail"
	printInfoGPU
	assertEqual "GPU|$expected|;" "$INFO_RESULT"
	assertEqual "$expected_args" "$(<"$LSPCI_ARGS")"
}

##==================================================================================================
##	REAL lspci OUTPUT
##==================================================================================================

# The first line of "lspci -v -s <id>" on nine machines (Debian 12 and 13,
# pciutils 3.9 to 3.13). The plain listing carries the same text without the
# "(prog-if ...)" part.
#
# Every expected name keeps the trailing space the trimming leaves behind,
# invisible in the pane: apart from the ASPEED one, the expected values are
# today's output byte for byte, so the only row this changes is ASPEED's.

# Lenovo ThinkSystem SR650 V3. The vendor is "ASPEED Technology, Inc." and the
# device is "ASPEED Graphics Family": once the generic words are trimmed away,
# both leave "ASPEED", and the row used to read "ASPEED ASPEED".
checkGPU '02:00.0' 'ASPEED Technology, Inc. ASPEED Graphics Family (rev 52)' \
	' (prog-if 00 [VGA controller])' 'ASPEED '

# Matrox chips on Lenovo and HPE servers: the vendor is dropped by its own rule.
# Lenovo ThinkSystem ST550. Longer than 30 characters, so the [...] part goes.
checkGPU '02:00.0' 'Matrox Electronics Systems Ltd. MGA G200e [Pilot] ServerEngines (SEP1) (rev 42)' \
	' (prog-if 00 [VGA controller])' 'MGA G200e  ServerEngines '
# Lenovo System x3500 M5.
checkGPU '19:00.0' 'Matrox Electronics Systems Ltd. G200eR2 (rev 01)' \
	' (prog-if 00 [VGA controller])' 'G200eR2 '
# HPE ProLiant ML350 Gen10.
checkGPU '01:00.1' 'Matrox Electronics Systems Ltd. MGA G200eH3 (rev 02)' \
	' (prog-if 00 [VGA controller])' 'MGA G200eH3 '
# HP ProLiant DL380p Gen8: no "(rev ...)" at all.
checkGPU '01:00.1' 'Matrox Electronics Systems Ltd. MGA G200EH' \
	' (prog-if 00 [VGA controller])' 'MGA G200EH '

# NVIDIA. Dell Precision Tower 5810: short enough to keep its [...] part.
checkGPU '04:00.0' 'NVIDIA Corporation GT218 [GeForce 210] (rev a2)' \
	' (prog-if 00 [VGA controller])' 'NVIDIA GT218 [GeForce 210] '
# HP Pavilion Gaming Desktop 690: too long, the [...] part goes.
checkGPU '1d:00.0' 'NVIDIA Corporation GP107 [GeForce GTX 1050 Ti] (rev a1)' \
	' (prog-if 00 [VGA controller])' 'NVIDIA GP107  '

# Intel integrated graphics. Lenovo ThinkStation P3 Tower.
checkGPU '00:02.0' 'Intel Corporation Raptor Lake-S GT1 [UHD Graphics 770] (rev 04)' \
	' (prog-if 00 [VGA controller])' 'Intel Raptor Lake-S GT1  '
# MSI MS-7D46 board.
checkGPU '00:02.0' 'Intel Corporation AlderLake-S GT1 (rev 0c)' \
	' (prog-if 00 [VGA controller])' 'Intel AlderLake-S GT1 '

printf 'PASS: GPU names from real lspci output\n'
