# Quick reference for tools used in environment
## UV commands reference

### init the project
```bash
uv init
```
### sync/update or setup new environment based on existing uv config
```bash
uv sync
```
If we need to update environment without updating lock file
```bash
uv sync --frozen
```

### add/remove new packages
```bash
uv add <package name>
uv remove <package name>
```

### add dev dependencies
```bash
uv add --dev <package name>
```

### custom dependency group
```bash
uv add --group docker <package name>
```

### sync based on various dependency group
```bash
uv sync # syncs default and dev groups
uv sync --no-dev # syncs default
uv sync --all-groups # syncs all groups
uv sync --group <group name> # sync specific dependency group along with default
uv sync --no-group <group name> # exclude certain dependency group
# can include various such combinations based on needs
```

### export to requirements.txt
```bash
uv export --frozen --no-dev --no-hashes --output-file=requirements.txt
uv export --frozen --no-hashes --output-file=dev-requirements.txt
uv export --frozen --group <group name> --output-file=custom-requirements.txt
# can include various such combinations based on need
```

## mise

### mise.toml
- create mise toml and necessary configs
- As of now, we add enter and leave hooks to activate/deactivate virtual env and to sync virtual env with uv.lock
- Also, a configuration to load from .env

For new dirs
```bash
mise trust
mise install
```
