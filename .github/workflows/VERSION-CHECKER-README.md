# Agent DVR Version Checker

Automatically check for new Agent DVR versions from the iSpy Connect product history page and integrate with your GitHub workflows.

## Features

- **Version scraping** - Extracts version, date, and changelog from iSpy Connect
- **Stability detection** - Marks versions as "stable" only after 5 days (configurable)
- **Multiple output formats** - JSON, GitHub Actions, environment variables, plain text
- **GitHub Actions integration** - Ready-to-use workflow with stability-aware updates

## Files

| File | Description |
|------|-------------|
| `scrape_agentdvr_version.py` | Python script to scrape version info |
| `check-agentdvr-version.yml` | Full-featured GitHub Actions workflow |
| `check-agentdvr-simple.yml` | Simplified single-job workflow |

## Stability Feature

A version is considered **stable** only if it has been the latest release for at least 5 days. This helps avoid:
- Catching versions that get quickly patched
- Updating to potentially buggy releases
- Unnecessary rebuilds from rapid release cycles

### Example Output

```json
{
  "latest": {
    "version": "7.0.0.0",
    "date": "12/05/2025",
    "stable": false,           // Only 2 days old
    "days_since_release": 2
  },
  "stable_version": {
    "version": "6.9.9.0",      // This is the stable one
    "date": "12/01/2025"
  },
  "stable_days_threshold": 5
}
```

## Quick Start

### Option 1: Simple Workflow (Recommended)

1. Copy `check-agentdvr-simple.yml` to `.github/workflows/` in your repo
2. The workflow will:
   - Run daily at 6 AM UTC
   - Check for new versions
   - Update `.agentdvr-version` file when a new version is found
   - Commit and push the changes

### Option 2: Python Script

```bash
# Get latest version as JSON (includes stability info)
python scrape_agentdvr_version.py

# Get just the version number
python scrape_agentdvr_version.py --format version

# Get only stable versions
python scrape_agentdvr_version.py --stable-only

# Custom stability threshold (e.g., 7 days)
python scrape_agentdvr_version.py --stable-days 7

# Get last 5 versions with stability indicators
python scrape_agentdvr_version.py --count 5 --format text

# GitHub Actions output format
python scrape_agentdvr_version.py --format github
```

## Output Formats

### JSON (default)
```json
{
  "new_versions": true,
  "latest": {
    "version": "7.0.0.0",
    "changes": "UI view bug fix...",
    "date": "12/05/2025",
    "stable": false,
    "days_since_release": 2
  },
  "stable_version": {
    "version": "6.9.9.0",
    "date": "12/01/2025"
  },
  "stable_days_threshold": 5,
  "scraped_at": "2025-12-07T00:38:07Z"
}
```

### GitHub Actions (`--format github`)
```
new_version=true
version=7.0.0.0
date=12/05/2025
stable=false
days_since_release=2
stable_version=6.9.9.0
changes<<CHANGES_EOF
UI view bug fix...
CHANGES_EOF
```

### Text (`--format text`)
```
Version: 7.0.0.0 [2 days old]
Date: 12/05/2025
Changes: Latest version...
--------------------------------------------------
Version: 6.9.9.0 [STABLE]
Date: 12/01/2025
Changes: Previous version...
```

### Environment (`--format env`)
```
AGENTDVR_VERSION=7.0.0.0
AGENTDVR_DATE=12/05/2025
AGENTDVR_STABLE=false
AGENTDVR_DAYS_SINCE=2
AGENTDVR_STABLE_VERSION=6.9.9.0
```

## Workflow Options

The full workflow (`check-agentdvr-version.yml`) supports these inputs when triggered manually:

| Input | Description | Default |
|-------|-------------|---------|
| `force_update` | Update even if no new version | `false` |
| `stable_only` | Only update if version is stable (5+ days old) | `false` |

### Using stable_only

When `stable_only` is enabled:
- Workflow waits until a version has been out for 5+ days before updating
- Helps ensure you're using tested, stable releases
- Perfect for production environments

## Integration Examples

### Trigger build only on stable versions

```yaml
name: Build on Stable Version

on:
  push:
    paths:
      - '.agentdvr-version'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Get version
        id: ver
        run: echo "version=$(cat .agentdvr-version)" >> $GITHUB_OUTPUT
      
      - name: Build Docker image
        run: |
          docker build \
            --build-arg AGENTDVR_VERSION=${{ steps.ver.outputs.version }} \
            -t myapp:${{ steps.ver.outputs.version }} .
```

### Check stability in a script

```bash
#!/bin/bash
RESULT=$(python scrape_agentdvr_version.py --format json)
STABLE=$(echo "$RESULT" | jq -r '.latest.stable')
VERSION=$(echo "$RESULT" | jq -r '.latest.version')

if [ "$STABLE" = "true" ]; then
    echo "Version $VERSION is stable, updating..."
    echo "$VERSION" > .agentdvr-version
else
    STABLE_VER=$(echo "$RESULT" | jq -r '.stable_version.version')
    echo "Latest $VERSION is not stable yet."
    echo "Stable version: $STABLE_VER"
fi
```

## Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| Schedule | `0 6 * * *` | Daily at 6 AM UTC |
| URL | ispyconnect.com/... | Product history page |
| Version file | `.agentdvr-version` | File to track current version |
| Stable days | 5 | Days before version is considered stable |

## License

MIT
