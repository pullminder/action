# Pullminder Action

GitHub Action for validating [Pullminder](https://pullminder.com) custom rule registries in CI. Downloads the CLI, runs validation, and optionally posts results as a PR comment.

## Usage

```yaml
name: Validate Registry
on: [push, pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pullminder/action@v1
```

## Inputs

| Input | Description | Default |
|-------|-------------|---------|
| `version` | CLI version to use | `latest` |
| `command` | Registry command to run | `validate` |
| `strict` | Enable strict validation (exit 1 on any warning) | `true` |
| `comment` | Post results as a PR comment | `true` |
| `working-directory` | Path to registry root | `.` |

## Examples

### Basic validation

```yaml
- uses: pullminder/action@v1
```

### Custom registry path

```yaml
- uses: pullminder/action@v1
  with:
    working-directory: rules/
```

### Pin a specific CLI version

```yaml
- uses: pullminder/action@v1
  with:
    version: "0.8.0"
```

### Disable PR comments

```yaml
- uses: pullminder/action@v1
  with:
    comment: "false"
```

### Validation without strict mode

```yaml
- uses: pullminder/action@v1
  with:
    strict: "false"
```

### Use with a registry submodule

```yaml
steps:
  - uses: actions/checkout@v4
    with:
      submodules: true
  - uses: pullminder/action@v1
    with:
      working-directory: pullminder-registry/
```

## How it works

1. Detects your runner platform (Linux/macOS, x64/arm64)
2. Downloads the Pullminder CLI binary from [pullminder/cli](https://github.com/pullminder/cli) releases (cached between runs)
3. Runs `pullminder registry <command>` with the specified options
4. Posts a formatted summary as a PR comment (if enabled and triggered by a pull request)
5. Exits with the CLI's exit code (non-zero on validation failure)

## Badge

Add a registry validation badge to your README:

```markdown
[![Registry Valid](https://github.com/<owner>/<repo>/actions/workflows/validate.yml/badge.svg)](https://github.com/<owner>/<repo>/actions/workflows/validate.yml)
```

## Links

- [Pullminder](https://pullminder.com) — AI-powered PR review platform
- [CLI](https://github.com/pullminder/cli) — Full CLI reference and releases
- [Registry](https://github.com/pullminder/registry) — Official rule pack registry
- [npm](https://github.com/pullminder/npm) — npm wrapper

## License

Apache-2.0
