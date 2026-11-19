#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
# shellcheck source=test/support/testlib.sh
source "$SCRIPT_DIR/support/testlib.sh"

test_root="$(createTestRoot zpool-monitor)"
mkdir -p "$test_root/bin" "$test_root/nozfs"
# The stub prints ZFS_OUTPUT and records how it was called, so the command
# line itself is checked and not only what is done with its output. With
# ZFS_RC set it fails the way zfs does for a pool that does not exist.
# shellcheck disable=SC2016
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >"%s/zfs_args"\nif [ -n "${ZFS_RC:-}" ]; then printf "cannot open %%s: dataset does not exist\\n" "${!#}" >&2; exit "$ZFS_RC"; fi\nprintf "%%s\\n" "$ZFS_OUTPUT"\n' "$test_root" >"$test_root/bin/zfs"
printf '#!/usr/bin/env bash\nIFS= read -r _ || :\nprintf "1\\n"\n' >"$test_root/bin/bc"
chmod +x "$test_root/bin/zfs" "$test_root/bin/bc"
PATH="$test_root/bin:$PATH"
export ZFS_OUTPUT ZFS_RC

set +u
# shellcheck disable=SC1091
source "$PROJECT_ROOT/synth-shell-greeter/info.sh"
set -u

bar_hdd_units="GB"
bar_hdd_crit_percent=85

printInfoLine() {
	INFO_RESULT="$1|$2|${3:-}"
}

printResourceMonitor() {
	MONITOR_RESULT="$1|$2|$3|$4|$5|$6"
}

assertEqual() {
	local expected="$1"
	local actual="$2"

	[[ "$actual" == "$expected" ]] || die "expected '$expected', got '$actual'"
}

assertReading() {
	local what="$1" expected="$2"

	[[ "$MONITOR_RESULT" == "$expected" ]] || \
		die "$what: expected '$expected', got '$MONITOR_RESULT'"
}

# Every case clears both results first, so an assertion cannot pass on a value
# left behind by the previous one.
reset() {
	INFO_RESULT=
	MONITOR_RESULT=
	ZFS_RC=
	rm -f "$test_root/zfs_args"
}

##==================================================================================================
##	THE COMMAND
##==================================================================================================

# Exact bytes (-p) and no header (-H): a rounded "1.30T" would have to be
# parsed back, and the rounding would differ from df's.
reset
ZFS_OUTPUT=$'1073741824\t1073741824'
printMonitorZpool 'tank' 'a/b'
assertEqual 'list -H -p -o used,avail tank' "$(cat "$test_root/zfs_args")"
assertEqual 'tank|1|2|GB|a/b|85' "$MONITOR_RESULT"

##==================================================================================================
##	LABELS
##==================================================================================================

# Named after the pool, underscores kept, as HDD_MON keeps them for a path.
reset
ZFS_OUTPUT=$'1073741824\t1073741824'
printMonitorZpool 'data_pool_01' 'a/b'
assertEqual 'data_pool_01|1|2|GB|a/b|85' "$MONITOR_RESULT"

# A label from the config turns "_" into a space, as for HDD_MON.
reset
printMonitorZpool 'data_pool_01:Main_pool' 'a/b'
assertEqual 'Main pool|1|2|GB|a/b|85' "$MONITOR_RESULT"
assertEqual 'list -H -p -o used,avail data_pool_01' "$(cat "$test_root/zfs_args")"

# Percentage variant.
reset
printMonitorZpool 'tank:Data' '0/0'
assertEqual 'Data|1|2|GB|0/0|85' "$MONITOR_RESULT"

##==================================================================================================
##	ROUNDING
##
##	Rounded up, as `df -B1G` rounds for the other storage monitors.
##==================================================================================================

reset
ZFS_OUTPUT=$'1073741825\t0'
printMonitorZpool 'tank' 'a/b'
assertEqual 'tank|2|2|GB|a/b|85' "$MONITOR_RESULT"

reset
ZFS_OUTPUT=$'0\t5368709120'
printMonitorZpool 'tank' 'a/b'
assertEqual 'tank|0|5|GB|a/b|85' "$MONITOR_RESULT"

reset
bar_hdd_units="TB"
ZFS_OUTPUT=$'1427748588480\t4463249416960'
printMonitorZpool 'tank' 'a/b'
assertEqual 'tank|2|6|TB|a/b|85' "$MONITOR_RESULT"
bar_hdd_units="GB"

##==================================================================================================
##	WHAT CANNOT BE SHOWN
##==================================================================================================

reset
printMonitorZpool '' 'a/b'
assertEqual 'ZPOOL_MON|config error: missing pool|' "$INFO_RESULT"
assertEqual '' "$MONITOR_RESULT"

reset
printMonitorZpool ':Main_pool' 'a/b'
assertEqual 'ZPOOL_MON|config error: missing pool|' "$INFO_RESULT"
assertEqual '' "$MONITOR_RESULT"

# A pool that does not exist (exported, renamed, typo in the config): a row
# that says so, and nothing from zfs's own error in the greeting.
reset
ZFS_RC=1
printMonitorZpool 'tank:Backup_pool' 'a/b'
assertEqual 'Backup pool|pool not found|' "$INFO_RESULT"
assertEqual '' "$MONITOR_RESULT"

# Output that is not two numbers is not read as a reading.
reset
ZFS_OUTPUT='-	-'
printMonitorZpool 'tank' 'a/b'
assertEqual 'tank|pool not found|' "$INFO_RESULT"
assertEqual '' "$MONITOR_RESULT"

# No zfs on this machine at all.
reset
result="$(PATH="$test_root/nozfs"; printMonitorZpool 'tank' 'a/b'; printf '%s' "$INFO_RESULT")"
assertEqual 'tank|zfs not available|' "$result"

##==================================================================================================
##	REAL `zfs list -H -p -o used,avail` OUTPUT
##
##	Captured from the root datasets of seven pools on Debian 13 hosts with
##	OpenZFS 2.4. The expected figures were worked out separately from the
##	byte counts, not by running the code under test.
##==================================================================================================

# raidz1 on four HDDs, mostly datasets
reset
ZFS_OUTPUT=$'1427748588480\t4463249416960'
printMonitorZpool 'data_pool_01' 'a/b'
assertReading "data_pool_01" 'data_pool_01|1330|5487|GB|a/b|85'

# raidz1 on three SATA SSDs behind an HBA
reset
ZFS_OUTPUT=$'731702675968\t3402612243184'
printMonitorZpool 'ssd_pool' 'a/b'
assertReading "ssd_pool" 'ssd_pool|682|3851|GB|a/b|85'

# raidz2 on four HDDs, almost all VM zvols: df sees none of them
reset
ZFS_OUTPUT=$'24451911168\t1096350908416'
printMonitorZpool 'vm_pool' 'a/b'
assertReading "vm_pool" 'vm_pool|23|1044|GB|a/b|85'

# raidz2 on six SAS HDDs, mostly VM zvols
reset
ZFS_OUTPUT=$'204367697160\t2112652844808'
printMonitorZpool 'sas_pool' 'a/b'
assertReading "sas_pool" 'sas_pool|191|2158|GB|a/b|85'

# raidz1 on six SATA SSDs, 394 of its 397 GB in VM zvols
reset
ZFS_OUTPUT=$'426319409296\t4033978863840'
printMonitorZpool 'ssd_vm_pool' 'a/b'
assertReading "ssd_vm_pool" 'ssd_vm_pool|398|4154|GB|a/b|85'

# two striped mirrors on four HDDs, the fullest of the set
reset
ZFS_OUTPUT=$'439493672960\t723901173760'
printMonitorZpool 'mirror_pool' 'a/b'
assertReading "mirror_pool" 'mirror_pool|410|1084|GB|a/b|85'

# a root pool
reset
ZFS_OUTPUT=$'13597790208\t225743060992'
printMonitorZpool 'rpool' 'a/b'
assertReading "rpool" 'rpool|13|223|GB|a/b|85'

printf 'PASS: ZFS pool monitor\n'
