# Building images manually

Stable and beta images build automatically every hour. Use the manual workflow when you
need a **specific version**, want to **backport an older major**, or need to rerun the
latest stable and beta release build.

## How to run

In GitHub, go to **Actions → CI → Run workflow** on branch `main`. Choose a `target`,
provide its `value` when required, and select **Run workflow**.

| Target | Value | Result |
| --- | --- | --- |
| `release` | Leave empty. | Builds the latest stable and beta releases. |
| `version` | Full version, such as `516.1659`. | Builds one exact release. |
| `major` | Major version, such as `515`. | Builds the newest published minor for that major. |

## Build a specific version

Choose `version` and set `value` to the full BYOND version:

| Input | Value |
| --- | --- |
| `target` | `version` |
| `value` | `516.1659` |

Pushes `ghcr.io/neurekadev/byond:516.1659` and `:516`.

If that version already exists it fails on purpose. Enable `force_overwrite` to rebuild it.

## Backport an older major

Choose `major` and set `value` to the BYOND major version:

| Input | Value |
| --- | --- |
| `target` | `major` |
| `value` | `515` |

It finds the newest published build for that major, then pushes `:<full>` (e.g. `:515.1647`)
and `:515`. Versions that already exist are skipped.

To build an exact older build instead of the newest, use the `version` target (see "Build
a specific version" above).

## Inputs

| Input | Target | Description | Example |
| --- | --- | --- | --- |
| `target` | all | Build mode: `release`, `version`, or `major`. | `version` |
| `value` | `version` or `major` | Full version or major number to build. | `516.1659` |
| `force_overwrite` | all | Rebuild and overwrite a tag that already exists. | `true` |

> [!NOTE]
> Exact-version and major builds never move the `latest` or `beta` tags. Every newly
> built image receives a GitHub build-provenance attestation.
