# OS Orbty-mi — Releases

Public distribution point for **OS Orbty-mi** (macOS).

This repository holds the signed, notarized build artifacts and the auto-update
manifest (`latest.json`) consumed by the in-app updater. **Build outputs only —
the application source lives in a separate repository.**

Releases here are published automatically by CI. Do not push by hand.

## Local cleanup

Run `make clean` to remove only local caches, temporary directories, logs, and
macOS metadata. Preview the operation with `make clean DRY_RUN=1`. Signed
release artifacts, update manifests, Git metadata, and repository files are
never cleanup targets.
