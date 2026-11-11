#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
# shellcheck source=test/support/testlib.sh
source "$SCRIPT_DIR/support/testlib.sh"

test_root="$(createTestRoot storage-path)"
mkdir -p "$test_root/bin" "$test_root/mounted" "$test_root/data_pool_01"
# shellcheck disable=SC2016
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$DF_OUTPUT"\n' >"$test_root/bin/df"
printf '#!/usr/bin/env bash\nIFS= read -r _ || :\nprintf "1\\n"\n' >"$test_root/bin/bc"
chmod +x "$test_root/bin/df" "$test_root/bin/bc"
PATH="$test_root/bin:$PATH"
export DF_OUTPUT

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

# Every case clears both results first, so an assertion cannot pass on a value
# left behind by the previous one.
reset() {
	INFO_RESULT=
	MONITOR_RESULT=
}

##==================================================================================================
##	LABELS
##==================================================================================================

DF_OUTPUT=$'Filesystem 1G-blocks Used Available Use% Mounted on\n/dev/sda1 100 40 60 40% /m'

# No label of its own: named after the last component of the path.
reset
printMonitorPath "$test_root/mounted" 'a/b'
assertEqual 'mounted|40|100|GB|a/b|85' "$MONITOR_RESULT"
assertEqual '' "$INFO_RESULT"

# An underscore in a DERIVED label is part of the name: ZFS pools and datasets
# are routinely called things like "data_pool_01", and "data pool 01" would be
# a different name on screen.
reset
printMonitorPath "$test_root/data_pool_01" 'a/b'
assertEqual 'data_pool_01|40|100|GB|a/b|85' "$MONITOR_RESULT"

# A label from the config cannot carry a space, so "_" stands in for one.
reset
printMonitorPath "$test_root/mounted:Project_files" 'a/b'
assertEqual 'Project files|40|100|GB|a/b|85' "$MONITOR_RESULT"

# A trailing slash does not swallow the name, and "/" keeps its own.
reset
printMonitorPath "$test_root/mounted/" 'a/b'
assertEqual 'mounted|40|100|GB|a/b|85' "$MONITOR_RESULT"

reset
printMonitorPath "/" 'a/b'
assertEqual '/|40|100|GB|a/b|85' "$MONITOR_RESULT"

# The pane is printed with printf, so a "%" in a label must reach it doubled
# or it truncates that line and everything after it.
reset
printMonitorPath "$test_root/mounted:Spare_%_free" 'a/b'
assertEqual 'Spare %% free|40|100|GB|a/b|85' "$MONITOR_RESULT"

# Percentage variant.
reset
printMonitorPath "$test_root/mounted:Data" '0/0'
assertEqual 'Data|40|100|GB|0/0|85' "$MONITOR_RESULT"

##==================================================================================================
##	MISSING PATHS
##==================================================================================================

reset
printMonitorPath '' 'a/b'
assertEqual 'HDD_MON|config error: missing path|' "$INFO_RESULT"
assertEqual '' "$MONITOR_RESULT"

reset
printMonitorPath ':Backup_disk' 'a/b'
assertEqual 'HDD_MON|config error: missing path|' "$INFO_RESULT"
assertEqual '' "$MONITOR_RESULT"

reset
printMonitorPath '' '0/0'
assertEqual 'HDD_MON|config error: missing path|' "$INFO_RESULT"
assertEqual '' "$MONITOR_RESULT"

reset
printMonitorPath "$test_root/absent" 'a/b'
assertEqual 'absent|not mounted|' "$INFO_RESULT"
assertEqual '' "$MONITOR_RESULT"

reset
printMonitorPath "$test_root/absent:Backup_disk" 'a/b'
assertEqual 'Backup disk|not mounted|' "$INFO_RESULT"

##==================================================================================================
##	REAL `df` OUTPUT, ONE PER FILESYSTEM SHAPE
##
##	Captured verbatim from Debian 13 hosts, so the parsing is exercised
##	against the column widths and filesystem names that actually occur
##	rather than against a tidy invention. Only the NFS server address is
##	masked.
##==================================================================================================

assertReading() {
	local what="$1" expected="$2"

	[[ "$MONITOR_RESULT" == "$expected" ]] || \
		die "$what: expected '$expected', got '$MONITOR_RESULT'"
}

# XFS on LVM, a root filesystem
reset
DF_OUTPUT=$'Filesystem           1G-blocks  Used Available Use% Mounted on\n/dev/mapper/pve-root        13     9         4  69% /'
printMonitorPath "$test_root/mounted:Root" 'a/b'
assertReading "xfs root on lvm" 'Root|9|13|GB|a/b|85'

# ZFS root filesystem: the device column is a dataset name, not a /dev path
reset
DF_OUTPUT=$'Filesystem       1G-blocks  Used Available Use% Mounted on\nrpool/ROOT/pve-1       458     5       454   1% /'
printMonitorPath "$test_root/mounted:Root" 'a/b'
assertReading "zfs root" 'Root|5|458|GB|a/b|85'

# NFS: the device column carries a host and a colon
reset
DF_OUTPUT=$'Filesystem       1G-blocks  Used Available Use% Mounted on\n10.0.0.5:/export      8432  2548      5885  31% /mnt/share'
printMonitorPath "$test_root/mounted:Share_NFS" 'a/b'
assertReading "nfs export" 'Share NFS|2548|8432|GB|a/b|85'

# ZFS dataset with no quota: reports the whole pool's free space
reset
DF_OUTPUT=$'Filesystem     1G-blocks  Used Available Use% Mounted on\ndata_pool_01       3322     1      3322   1% /data_pool_01'
printMonitorPath "$test_root/mounted:Pool" 'a/b'
assertReading "dataset without quota" 'Pool|1|3322|GB|a/b|85'

# ZFS dataset with a quota: a meter that can actually fill up
reset
DF_OUTPUT=$'Filesystem                 1G-blocks  Used Available Use% Mounted on\ndata_pool_01/lxc-smb-data      2048  1551       498  76% /data_pool_01/lxc-smb-data'
printMonitorPath "$test_root/mounted:Share" 'a/b'
assertReading "dataset with quota" 'Share|1551|2048|GB|a/b|85'

# ZFS subvolume with a refquota, long filesystem name
reset
DF_OUTPUT=$'Filesystem                                 1G-blocks  Used Available Use% Mounted on\ndata_pool_01/lxc-OS-smb/subvol-122-disk-0         4     2         3  50% /data_pool_01/lxc-OS-smb/subvol-122-disk-0'
printMonitorPath "$test_root/mounted:Container" 'a/b'
assertReading "subvolume with refquota" 'Container|2|4|GB|a/b|85'

# ZFS dataset whose content is a zvol: df sees none of it
reset
DF_OUTPUT=$'Filesystem                   1G-blocks  Used Available Use% Mounted on\ndata_pool_01/storage-backup      3322     1      3322   1% /data_pool_01/storage-backup'
printMonitorPath "$test_root/mounted:Backup" 'a/b'
assertReading "dataset holding a zvol" 'Backup|1|3322|GB|a/b|85'

printf 'PASS: storage monitors for arbitrary paths\n'
