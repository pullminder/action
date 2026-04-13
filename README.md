# Pullminder Action

GitHub Action for validating [Pullminder](https://pullminder.com) custom rule registries.

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
| `command` | Command to run | `validate` |
| `strict` | Enable strict validation | `true` |
| `comment` | Post results as PR comment | `true` |
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
    working-directory: ./my-registry
```

### Pin to a specific CLI version

```yaml
- uses: pullminder/action@v1
  with:
    version: "1.2.3"
```

### Disable PR comments

```yaml
- uses: pullminder/action@v1
  with:
    comment: "false"
```

## License

Apache-2.0
