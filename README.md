# Reviving Vector

Public archival snapshot of a customized Anki Vector and Wire-Pod installation. The project adds Claude-powered exploration, vision, custom intent handling, SDK endpoints, performance scripts, and operational notes to the upstream Wire-Pod stack.

## Start here

- [`Readme1st.md`](Readme1st.md) — operating guide and voice commands
- [`Getting_to_Know_Vector.md`](Getting_to_Know_Vector.md) — system overview
- [`Vector-Reference.md`](Vector-Reference.md) — implementation reference
- [`New-Vector-Actions.md`](New-Vector-Actions.md) — added behaviors
- [`ARCHIVE-NOTES.md`](ARCHIVE-NOTES.md) — snapshot provenance and public-safety exclusions

The top-level helper scripts read the robot ESN from `VECTOR_SERIAL` and optionally the server URL from `WIREPOD_URL`:

```bash
export VECTOR_SERIAL="YOUR_VECTOR_ESN"
export WIREPOD_URL="http://localhost:8080"
./vector-control.sh status
```

## Upstream

The `wire-pod/` directory is a vendored working snapshot based on [`kercre123/wire-pod`](https://github.com/kercre123/wire-pod), with local modifications preserved directly as files. Its upstream license is retained at [`wire-pod/LICENSE`](wire-pod/LICENSE).

This is an archival project, not an official Anki, Digital Dream Labs, Wire-Pod, Anthropic, or OpenAI repository.
