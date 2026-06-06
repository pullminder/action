# Pullminder GitHub Action

> Validate Pullminder rule registries in CI and post results as a PR comment.

[![GitHub Marketplace](https://img.shields.io/badge/Marketplace-Pullminder-blue)](https://github.com/marketplace/actions/pullminder)
[![License](https://img.shields.io/github/license/pullminder/action)](LICENSE)

## Quick start

```yaml
# .github/workflows/pullminder.yml
name: Validate registry
on:
  pull_request:
    paths:
      - "packs/**"
      - "registry.yml"

permissions:
  contents: read
  pull-requests: write

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pullminder/action@v1
```

## Overview

The official **Pullminder GitHub Action** ([`pullminder/action`](https://github.com/pullminder/action)) wraps the [Pullminder CLI](https://docs.pullminder.com/cli/installation/) so you can validate Pullminder rule registries directly from a GitHub workflow without writing any glue code.

> **Current scope:** the action is currently focused on **registry validation** — running `pullminder registry validate` (or `lint`) against a registry checkout, then posting the result as a PR comment. If you want PR risk scoring or general CI annotations on a consumer repository today, run the [Pullminder CLI](https://docs.pullminder.com/cli/ci-integration/) directly. Expanded modes (`pr-review`, `ci`) are tracked on the [action repository](https://github.com/pullminder/action).

## What it does

When invoked from a workflow, the action:

1. Detects the runner OS and architecture (`linux/amd64`, `linux/arm64`, `darwin/amd64`, `darwin/arm64`).
2. Resolves the requested CLI version (`latest` or a pinned `vX.Y.Z`).
3. Downloads the matching release artifact from `pullminder/cli` **and verifies its SHA256** against the published `checksums.txt`. A mismatch fails the run before the binary is made executable.
4. Caches the binary across runs keyed by version + platform.
5. Runs `pullminder registry validate` (default) or `pullminder registry lint` against the configured `working-directory`.
6. Posts the CLI output as a PR comment when `comment: "true"` (the default) and the trigger is `pull_request`.
7. Exits with the CLI's status code so a failed validation fails the job.

## When to use it

| Use case                                              | Pick this                                               |
| ----------------------------------------------------- | ------------------------------------------------------- |
| Maintaining a Pullminder rule registry                | `pullminder/action@v1` with `command: validate --strict` |
| Linting a registry before publishing                  | `pullminder/action@v1` with `command: lint`              |
| Running risk scoring on a consumer repo's PRs         | [`pullminder ci`](https://docs.pullminder.com/cli/ci-integration/) directly        |
| Producing SARIF / JUnit / annotations from CLI output | [`pullminder ci`](https://docs.pullminder.com/cli/ci-integration/) directly        |

If you maintain a registry, the action is the shortest path from clone to comment. For everything else, the CLI is more flexible today.

## Versioning

Pin the action to a major version in production:

```yaml
- uses: pullminder/action@v1
```

Or pin to an exact CLI version through the `version` input — useful if you want bit-for-bit reproducibility across runs. See [Advanced](https://docs.pullminder.com/action/advanced/).

## Source

- Action: [`pullminder/action`](https://github.com/pullminder/action)
- CLI: [`pullminder/cli`](https://github.com/pullminder/cli)
- Issues, feature requests, discussions: please file them against the [action repository](https://github.com/pullminder/action/issues).

## Usage

The action is designed to drop into a registry repository's `pull_request` workflow with no shell scripting.

## Minimum viable workflow

```yaml
# .github/workflows/pullminder.yml
name: Validate registry

on:
  pull_request:
    paths:
      - "packs/**"
      - "registry.yml"

permissions:
  contents: read
  pull-requests: write

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pullminder/action@v1
```

This runs `pullminder registry validate --strict` against the repository root and posts the output as a comment on the PR. Failures (missing required fields, schema violations, slug collisions, etc.) cause the job to exit non-zero.

`pull-requests: write` is only required when `comment: "true"` (the default). Drop it if you set `comment: "false"`.

## Validating a registry that lives in a subdirectory

```yaml
- uses: pullminder/action@v1
  with:
    working-directory: ./registry
```

`working-directory` is resolved relative to the repository root.

## Linting instead of validating

`lint` is non-strict by default — it warns on style issues but does not fail the build:

```yaml
- uses: pullminder/action@v1
  with:
    command: lint
    strict: "false"
```

Set `strict: "true"` to convert lint warnings into hard failures.

## Pinning the CLI version

Reproducible builds: pin the CLI version explicitly rather than tracking `latest`.

```yaml
- uses: pullminder/action@v1
  with:
    version: "0.1.15"
```

The action will download `pullminder-<os>-<arch>` from the matching `pullminder/cli` release and verify its SHA256 before running.

## Disabling the PR comment

Useful when you only care about the job exit status (for example, in a required-check workflow):

```yaml
- uses: pullminder/action@v1
  with:
    comment: "false"
```

## Reading outputs in subsequent steps

```yaml
- id: pm
  uses: pullminder/action@v1
  with:
    command: validate
    comment: "false"

- name: Show CLI output
  if: always()
  run: |
    echo "exit code: ${{ steps.pm.outputs.exit_code }}"
    echo "${{ steps.pm.outputs.output }}"
```

See [Outputs](https://docs.pullminder.com/action/outputs/) for the full list.

## Inputs

All inputs are optional. Defaults match the most common case (latest CLI, strict registry validation, comment on the PR).

| Input               | Default     | Description                                                                                                                                |
| ------------------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `version`           | `latest`    | CLI version to download. Either `latest` or a release tag without the `v` prefix (e.g. `0.1.15`). Resolved against `pullminder/cli` releases. |
| `command`           | `validate`  | Registry subcommand to run. One of `validate` or `lint`.                                                                                   |
| `strict`            | `true`      | When `true` and `command: validate`, appends `--strict` to the CLI invocation. Has no effect on `lint`.                                    |
| `comment`           | `true`      | When `true` and the workflow trigger is `pull_request`, posts the CLI output as a PR comment.                                              |
| `working-directory` | `.`         | Directory the CLI is invoked in. Resolved relative to the repository root.                                                                 |

## Notes per input

### `version`

- `latest` resolves to whatever `pullminder/cli` has as its newest GitHub release at the time the action runs.
- Pin to an exact version for reproducibility:
  ```yaml
  with:
    version: "0.1.15"
  ```
- Whatever you pick, the action verifies the binary's SHA256 against the `checksums.txt` published with the same release before running it. A mismatch fails the run.

### `command`

- `validate` (default) — fails on any registry error.
- `lint` — surfaces style warnings; combine with `strict: "true"` to fail on warnings.
- Other CLI commands are not supported by this action today. For broader CI use cases, run [`pullminder ci`](https://docs.pullminder.com/cli/ci-integration/) directly.

### `strict`

- Only meaningful when `command: validate`. Maps to the CLI's `--strict` flag.

### `comment`

- Comments are posted using the workflow's `GITHUB_TOKEN`. Your job needs `permissions.pull-requests: write` for this to succeed.
- Set to `"false"` for repositories that prefer status checks over PR chatter.
- The action only attempts to comment when `github.event_name == 'pull_request'`. Manual `workflow_dispatch` runs never comment, regardless of this setting.

### `working-directory`

- Use this when the registry sits in a subdirectory of a larger repo:
  ```yaml
  with:
    working-directory: ./registry
  ```
- The path is resolved by the runner shell, so relative paths must be relative to `${{ github.workspace }}`.

## Source of truth

These inputs are defined in [`action.yml`](https://github.com/pullminder/action/blob/main/action.yml). If this page disagrees with `action.yml`, treat `action.yml` as authoritative and please file an issue against [`pullminder/action`](https://github.com/pullminder/action/issues).

## Outputs

The action exposes the CLI's exit code and combined output so subsequent workflow steps can react to either.

| Output      | Description                                                                                                                |
| ----------- | -------------------------------------------------------------------------------------------------------------------------- |
| `exit_code` | The CLI's exit code as a string. `0` means the registry passed validation; non-zero indicates findings or a runtime error. |
| `output`    | The full combined `stdout` + `stderr` produced by the CLI. The same text the action posts as a PR comment when enabled.    |

## Job exit status

If the CLI exits non-zero, the action's final step re-exits with the same code, so the job fails. There is no need to read `exit_code` to fail the build — that is the default behaviour. Use `exit_code` only when you want to **conditionally** continue past a failure (for example, to upload an artifact before the job dies).

## Reading outputs

```yaml
- id: pm
  uses: pullminder/action@v1
  with:
    command: validate

- name: Save raw CLI output as artifact
  if: always()
  run: |
    cat <<'OUT' > pullminder-output.txt
    ${{ steps.pm.outputs.output }}
    OUT
- uses: actions/upload-artifact@v4
  if: always()
  with:
    name: pullminder-output
    path: pullminder-output.txt
```

`if: always()` is required to capture output on a failed validation, since the CLI exit status fails the job by default.

## Reading the exit code

```yaml
- id: pm
  uses: pullminder/action@v1
  continue-on-error: true
  with:
    command: validate

- name: Open issue on failure
  if: steps.pm.outputs.exit_code != '0'
  run: gh issue create --title "Registry validation failed" --body "$OUTPUT"
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    OUTPUT: ${{ steps.pm.outputs.output }}
```

`continue-on-error: true` is required because the action re-exits with the CLI status code; without it, the workflow would short-circuit before the follow-up step runs.

## Advanced

## Version pinning

Two independent versions are involved when running the action:

1. **The action itself** — pinned via the `uses:` ref.
2. **The CLI binary the action downloads** — pinned via the `version` input.

For most teams, `pullminder/action@v1` (action) plus `version: latest` (CLI) is fine. For audit-sensitive repositories or rule registries that publish to the official Pullminder registry, pin both:

```yaml
- uses: pullminder/action@v1.0.0
  with:
    version: "0.1.15"
```

The action repository ships a floating `v1` tag that is moved forward to the latest `v1.x.y`. Pinning to the major (`@v1`) keeps you on the latest non-breaking release.

## Monorepo layouts

If your registry is a subdirectory of a larger monorepo, set `working-directory` and scope the workflow `paths` so the job only runs on relevant changes:

```yaml
on:
  pull_request:
    paths:
      - "registry/**"

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pullminder/action@v1
        with:
          working-directory: ./registry
```

## Self-hosted runners

The action runs on any GitHub-hosted or self-hosted runner that satisfies all of:

- POSIX shell (`bash`).
- `curl` available on the `PATH`.
- Either `sha256sum` (Linux) or `shasum` (macOS) available on the `PATH`.
- `sudo` available **without a password** for moving the binary to `/usr/local/bin`. On most ephemeral runners this is the default; on a long-lived runner, allowlist the action user via `/etc/sudoers.d/`.

If your self-hosted runners do not provide passwordless `sudo`, [open an issue](https://github.com/pullminder/action/issues) — we are tracking a `bin-path` input that would let the action install the binary into a per-runner `$HOME/.local/bin` instead.

## Matrix runs

Validate against multiple CLI versions in a single PR check (useful while bumping a registry to a newer schema):

```yaml
jobs:
  validate:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        cli: ["0.1.14", "0.1.15"]
    steps:
      - uses: actions/checkout@v4
      - uses: pullminder/action@v1
        with:
          version: ${{ matrix.cli }}
          comment: "false"
```

`comment: "false"` avoids posting one PR comment per matrix leg.

## Platform support

The action downloads CLI binaries published by `pullminder/cli` for these targets:

| Runner             | Supported |
| ------------------ | --------- |
| `ubuntu-latest`    | yes       |
| `ubuntu-22.04`     | yes       |
| `macos-latest`     | yes       |
| `macos-13` / `-14` | yes       |
| `windows-*`        | not yet   |

Windows runners are not supported today because the action's installation step assumes `/usr/local/bin` and `sudo`. Track [the action issue tracker](https://github.com/pullminder/action/issues) for progress.

## Security: SHA256 verification

Before the action makes the downloaded CLI binary executable, it:

1. Downloads `pullminder-<os>-<arch>` from the requested `pullminder/cli` release.
2. Downloads the matching `checksums.txt` from the same release.
3. Computes the SHA256 of the downloaded binary using `sha256sum` (or `shasum -a 256` on macOS).
4. Looks up the expected hash in `checksums.txt`.
5. Refuses to run if the hash is missing or does not match.

This guards against tampering with the GitHub release artifacts (or with any caching layer in front of them). If your organisation requires a stricter chain of custody, mirror the binaries to your own CDN, publish a `checksums.txt` next to them, and either fork the action or fall back to running the CLI directly from a curl-pipe in your workflow.

## Caching

The action caches the verified binary at `/usr/local/bin/pullminder` keyed by `version + os + arch`. The cache is restored from [GitHub Actions cache](https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows), so cold runs incur one download per platform per version, and warm runs skip the download entirely. The cache **does not** skip the SHA256 check — that runs only when the cache misses.

## Documentation

Full documentation is available at [docs.pullminder.com/action/overview/](https://docs.pullminder.com/action/overview/).

## Security

To report a vulnerability, please email **security@pullminder.com**. See [SECURITY.md](https://github.com/pullminder/.github/blob/main/SECURITY.md) for the full policy.

## License

[Apache-2.0](LICENSE)

---

_This README is auto-generated from the pullminder.com monorepo. Last synced: 2026-06-05._
