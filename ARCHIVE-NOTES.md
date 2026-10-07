# Archive notes

Snapshot prepared on 2026-10-07 from the local `REVIVING VECTOR` working directory.

## Provenance

- Vendored Wire-Pod origin: `https://github.com/kercre123/wire-pod.git`
- Local Wire-Pod base commit: `85868c693261088d8b27e7b245b4bc6772459bd6`
- Vendored whisper.cpp origin: `https://github.com/ggerganov/whisper.cpp.git`
- Local uncommitted Wire-Pod modifications and untracked source files are included in the snapshot.
- Nested Git metadata was intentionally flattened so GitHub contains the actual files rather than unusable embedded-repository pointers.

## Deliberately omitted or sanitized

The following local-only material is not published because it contains live credentials, device identity/state, workstation policy, or reproducible build output:

- `.claude/settings.local.json`
- `wire-pod/chipper/apiConfig.json` (included a live weather-service key)
- `wire-pod/chipper/jdocs/botSdkInfo.json`
- `wire-pod/chipper/jdocs/jdocs.json`
- `wire-pod/chipper/source.sh`
- `wire-pod/certs/`
- `wire-pod/chipper/session-certs/`
- `wire-pod/whisper.cpp/build_go/`
- `wire-pod/vector-cloud/packagesGotten`
- nested `.git/` directories and macOS `.DS_Store` files

The robot ESN, private LAN addresses, and Wi-Fi SSID were replaced with placeholders in public scripts and documentation. Export `VECTOR_SERIAL` and, if needed, `WIREPOD_URL` before using the top-level scripts.

The large Whisper model is stored with Git LFS. It remains part of the archive but requires Git LFS when cloning.
