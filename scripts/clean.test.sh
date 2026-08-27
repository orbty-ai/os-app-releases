#!/bin/sh
set -eu

root=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd -P)
outside=$(mktemp -d "${TMPDIR:-/tmp}/releases-clean-outside.XXXXXX")
fixture=$(mktemp -d "${TMPDIR:-/tmp}/releases-clean-fixture.XXXXXX")
trap 'rm -rf "$outside" "$fixture"' EXIT HUP INT TERM

mkdir "$outside/.cache"
output=$(cd "$outside" && make -f "$root/Makefile" clean-dry-run)
[ -d "$outside/.cache" ] || { printf '%s\n' 'cleanup escaped repository root' >&2; exit 1; }
printf '%s\n' "$output" | grep -F "$outside" >/dev/null && {
  printf '%s\n' 'dry-run inspected the caller directory' >&2
  exit 1
}
if make -C "$root" clean DRY_RUN=tru >/dev/null 2>&1; then
  printf '%s\n' 'cleanup accepted an invalid dry-run value' >&2
  exit 1
fi
if make -f "$root/Makefile" clean-dry-run MAKEFILE_LIST="$outside/attacker" >/dev/null 2>&1; then
  printf '%s\n' 'cleanup accepted an overridden MAKEFILE_LIST' >&2
  exit 1
fi

mkdir -p "$outside/override-sentinel" "$outside/env-sentinel" "$outside/symlink-sentinel"
: >"$outside/override-sentinel/.DS_Store"
: >"$outside/env-sentinel/.DS_Store"
: >"$outside/symlink-sentinel/.DS_Store"
override_output=$(make -f "$root/Makefile" clean DRY_RUN=1 ROOT="$outside")
printf '%s\n' "$override_output" | grep -F 'override-sentinel' >/dev/null && {
  printf '%s\n' 'command-line ROOT override redirected cleanup' >&2
  exit 1
}
env_output=$(ROOT="$outside" make -f "$root/Makefile" clean DRY_RUN=1)
printf '%s\n' "$env_output" | grep -F 'env-sentinel' >/dev/null && {
  printf '%s\n' 'environment ROOT override redirected cleanup' >&2
  exit 1
}
ln -s "$root/Makefile" "$outside/linked-Makefile"
symlink_output=$(make -f "$outside/linked-Makefile" clean DRY_RUN=1)
printf '%s\n' "$symlink_output" | grep -F 'symlink-sentinel' >/dev/null && {
  printf '%s\n' 'symlinked Makefile redirected cleanup' >&2
  exit 1
}

cp "$root/Makefile" "$fixture/Makefile"
mkdir -p "$fixture/.cache" "$fixture/nested" "$fixture/Logs"
: >"$fixture/nested/.DS_Store"
: >"$fixture/Logs/keep"
git -C "$fixture" init --quiet
git -C "$fixture" add Logs/keep
mv "$fixture/Logs" "$fixture/case-logs-tmp"
mv "$fixture/case-logs-tmp" "$fixture/logs"
alternate_index="$fixture/alternate.index"
GIT_INDEX_FILE="$alternate_index" git -C "$fixture" read-tree --empty
if GIT_INDEX_FILE="$alternate_index" GIT_DIR="$fixture/alternate-git" \
  GIT_WORK_TREE="$outside" make -C "$fixture" clean DRY_RUN=1 >/dev/null 2>&1; then
  printf '%s\n' 'cleanup accepted a case-variant tracked logs path' >&2
  exit 1
fi
[ -f "$fixture/logs/keep" ] || { printf '%s\n' 'case-variant tracked file was removed' >&2; exit 1; }
git -C "$fixture" update-index --force-remove Logs/keep
rm -f "$fixture/logs/keep"
rmdir "$fixture/logs"
git -C "$fixture" add nested/.DS_Store
if GIT_INDEX_FILE="$alternate_index" GIT_DIR="$fixture/alternate-git" \
  GIT_WORK_TREE="$outside" make -C "$fixture" clean DRY_RUN=1 >/dev/null 2>&1; then
  printf '%s\n' 'cleanup accepted a tracked .DS_Store' >&2
  exit 1
fi
[ -d "$fixture/.cache" ] && [ -f "$fixture/nested/.DS_Store" ] || {
  printf '%s\n' 'cleanup was partial before tracked-file refusal' >&2
  exit 1
}

printf '%s\n' 'cleanup containment and tracked-file guards: PASS'
