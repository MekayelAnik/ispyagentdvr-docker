# GitHub Actions Workflow Documentation

## Overview

This repository uses a unified GitHub Actions workflow for:
1. **Automated Docker image building and publishing**
2. **Agent DVR version monitoring and tracking**
3. **Registry synchronization**
4. **5-day stable promotion**
5. **Smart pipeline skip** (avoids redundant runs)
6. **Docker Hub description sync**

---

## Workflow

| Workflow | File | Purpose |
|----------|------|---------|
| Docker Build & Publish | `docker-build.yml` | Build, publish, version tracking, and image management |

---

## Workflow: Docker Build & Publish

**File:** `.github/workflows/docker-build.yml`

### Pipeline Jobs (11 total)

| # | Job | Purpose |
|---|-----|---------|
| 0 | `quick-check` | Reads `pipeline-state` orphan branch; skips pipeline when upstream version unchanged |
| 1 | `check-releases` | Fetches upstream releases, validates versions, generates build matrix |
| 2 | `build-platform` | Per-version+platform Docker builds (max-parallel: 6) |
| 3 | `merge-manifest` | Creates multi-arch manifests via `docker buildx imagetools create` |
| 4 | `sync-registries` | One-way sync GHCR -> Docker Hub with inspect caching |
| 5 | `promote-image` | Promotes version to `:latest` (runs on every auto-check) |
| 6 | `mark-stable` | 5-day stable promotion with pipeline-state tracking |
| 7 | `update-metadata` | Commits build metadata to main branch |
| 8 | `update-state` | Writes `last-built-version` and `latest-version-since` to orphan branch |
| 9 | `update-readme-version` | Auto-updates version in README after promote |
| 10 | `update-dockerhub-description` | Syncs README to Docker Hub description |

### Features

- **Smart Pipeline Skip**: `quick-check` reads `pipeline-state` orphan branch; skips entire pipeline in ~15s when no new upstream version
- **Automatic Release Detection**: Checks for new Agent DVR releases (via external cron trigger)
- **Multi-Platform Builds**: Supports `linux/amd64`, `linux/arm64`, and `linux/arm/v7`
- **Dual Registry Support**: Publishes to both Docker Hub and GitHub Container Registry (ghcr.io)
- **Registry Synchronization**: GHCR-primary one-way sync with inspect caching and rate-limit tolerance
- **Manual Version Builds**: Build specific versions (single, comma-separated, or range)
- **Image Promotion**: Promote any version to `latest` or `stable` tags
- **5-Day Stable Rule**: Tracks `latest-version-since` on pipeline-state branch; promotes after 5 days
- **Rate-Limit Tolerance**: All Docker Hub API calls detect 429/toomanyrequests with progressive backoff
- **Inspect Caching**: `declare -A _INSPECT_CACHE` ensures each registry ref is inspected at most once
- **Version Validation**: Warns about missing versions but doesn't fail the build
- **Security Scanning**: Optional Trivy vulnerability scanning (non-blocking)
- **ZSTD Compression**: Optimal image compression for faster pulls
- **Build Provenance & SBOM**: Supply chain security attestations
- **BuildKit Tuning**: `EXPORT_CACHE_CONCURRENCY=4`, `EXPORT_LAYERS_CONCURRENCY=4`
- **Docker Hub Description Sync**: Automatically syncs README to Docker Hub after promotion
- **README Version Auto-Update**: Updates version tag in README after successful promotion

---

## Required Secrets

Configure these secrets in your repository settings:

| Secret | Description | Required |
|--------|-------------|----------|
| `DOCKERHUB_USERNAME` | Your Docker Hub username | Yes |
| `DOCKERHUB_TOKEN` | Docker Hub access token (Read, Write, Delete + Admin for description sync) | Yes |

> **Note:** `GITHUB_TOKEN` is automatically provided and has `packages:write` scope for ghcr.io.
> **Note:** Docker Hub description sync requires Admin or Read & Write scope on the token. Without it, the sync step silently skips (non-blocking).

---

## Trigger Types

### 1. External Trigger (repository_dispatch)

Triggered by external cron services (e.g., cron-job.org) for reliable scheduling.

```
Event type: "Docker Build & Publish - Cron Scheduled"
```

### 2. Manual Trigger (workflow_dispatch)

Trigger manually from the Actions tab with various options.

#### Actions Available

| Action | Description |
|--------|-------------|
| `auto-check` | Check for new releases (same as scheduled) |
| `build-versions` | Build specific version(s) |
| `promote-image` | Promote a version to `latest` or `stable` |
| `force-promote-latest` | Force re-tag `:latest` (skips digest check, accepts custom version via `versions` input) |
| `promote-stable` | Promote current latest to `:stable` (respects 5-day rule) |
| `force-promote-stable` | Force promote to `:stable` (bypasses 5-day rule) |
| `sync-registries` | Synchronize images between registries |

---

## Manual Build Examples

### Build a Single Version

1. Go to Actions -> Docker Build & Publish -> Run workflow
2. Select action: `build-versions`
3. Enter version: `7.0.9.0`
4. Click "Run workflow"

### Build Multiple Versions

**Comma-separated:**
```
versions: 7.0.5.0,7.0.6.0,7.0.7.0
```

**Range format:**
```
versions: 7.0.5.0-7.0.9.0
```

> **Note:** Range expands to all versions found in the iSpy release history between start and end.

### Build with Custom Base Image

1. Select base_image: `custom`
2. Enter custom_base_image: `your-registry/your-base:tag`

### Promote Image to Latest/Stable

1. Select action: `promote-image`
2. Enter promote_version: `7.0.8.0`
3. Select promote_tag: `latest` or `stable`

### Force Re-Tag Latest

1. Select action: `force-promote-latest`
2. Optionally enter versions: `7.3.3.0` (defaults to current latest if empty)

### Force Promote to Stable

1. Select action: `force-promote-stable`

---

## Checkbox Options

| Option | Default | Description |
|--------|---------|-------------|
| `force_build` | `false` | Rebuild even if image exists |
| `skip_existing` | `true` | Skip versions already in registries |
| `tag_as_latest` | `true` | Also tag as `latest` |
| `run_security_scan` | `true` | Run Trivy vulnerability scan |
| `push_to_dockerhub` | `true` | Push to Docker Hub |
| `push_to_ghcr` | `true` | Push to GitHub Container Registry |
| `update_base_image` | `false` | Rebuild if base image has updates (checks digest) |

---

## Compression Options

ZSTD compression is used for both layer compression and cache.

| Level | Default | Description |
|-------|---------|-------------|
| `22` | **Yes** | Maximum compression (smallest size, slowest build) |
| `19` | | High compression |
| `15` | | Medium-high compression |
| `10` | | Medium compression |
| `5` | | Low compression |
| `3` | | Minimal compression (fastest build) |

---

## Platform Options

| Option | Platforms |
|--------|-----------|
| Default | `linux/amd64,linux/arm64,linux/arm/v7` |
| 64-bit only | `linux/amd64,linux/arm64` |
| x86_64 only | `linux/amd64` |

---

## Base Image Options

| Option | Image |
|--------|-------|
| Default | `mekayelanik/ispyagentdvr-base-image:latest` |
| trixie-slim-default-ffmpeg | `mekayelanik/ispyagentdvr-base-image:ispyagentdvr-trixie-slim-default-ffmpeg` |
| bookworm-slim-vlc-jellyfin-ffmpeg | `mekayelanik/ispyagentdvr-base-image:ispyagentdvr-bookworm-slim-vlc-jellyfin-ffmpeg` |
| custom | User-specified base image URL |

---

## Image Tags

| Tag | Description |
|-----|-------------|
| `7.3.3.0` | Specific version (multi-arch manifest) |
| `latest` | Most recent non-beta release |
| `stable` | Release that's been `:latest` for 5+ continuous days |
| `beta` | Rolling tag for latest beta release |
| `7.3.3.0-31032026` | Version with build date (DDMMYYYY, Bangladesh Time UTC+6) |
| `7.2.4.0-beta` | Specific beta version |

---

## Pipeline State Branch

The `pipeline-state` orphan branch stores:

| File | Purpose |
|------|---------|
| `last-built-version` | Last successfully built upstream version (used by quick-check) |
| `last-built-time` | Timestamp of last successful build |
| `latest-version-since` | When the current latest version was first seen (5-day rule timer) |

This enables:
- **Smart skip**: `quick-check` compares upstream version against `last-built-version`
- **5-day rule**: `mark-stable` reads `latest-version-since` to determine eligibility
- Timer resets when version changes

---

## Registry Synchronization

GHCR is the primary registry. Docker Hub is synced from GHCR.

- Tag in GHCR only -> copy GHCR -> Docker Hub
- Tag in both, digest mismatch -> re-sync GHCR -> Docker Hub
- Tag in Docker Hub only -> warning (primary missing)
- Tag in neither -> skip
- Uses `skopeo copy --all` to preserve all architectures
- Inspect caching avoids redundant API calls
- Rate-limit detection with progressive backoff (60s per attempt on 429)

---

## Build Optimizations

| Feature | Description |
|---------|-------------|
| Smart Pipeline Skip | Skips entire pipeline in ~15s when upstream version unchanged |
| Inspect Caching | `declare -A _INSPECT_CACHE` - each ref inspected at most once |
| Rate-Limit Tolerance | 429/toomanyrequests detection with progressive backoff |
| ZSTD Compression | Level 22 by default (configurable 1-22) |
| OCI Media Types | Maximum registry compatibility |
| Dual Cache | GitHub Actions cache + Registry cache for fastest builds |
| BuildKit Tuning | `max-parallelism=4`, `EXPORT_CACHE_CONCURRENCY=4`, optimized GC |
| Provenance | SLSA build provenance attestation (`mode=max`) |
| SBOM | Software Bill of Materials generation |
| Parallel Builds | Up to 6 platform builds simultaneously |
| Docker Hub Mirror | Uses `mirror.gcr.io` for faster base image pulls |
| Force Compression | Ensures consistent layer sizes across platforms |
| Disk Cleanup | Frees space before builds |

---

## Reusable Components

### Composite Actions

| Action | Path | Purpose |
|--------|------|---------|
| Registry Login | `.github/actions/registry-login` | Login to Docker Hub + GHCR |
| Registry Sync | `.github/actions/registry-sync` | GHCR-primary sync with inspect caching and rate-limit handling |

### Shared Scripts

| Script | Path | Purpose |
|--------|------|---------|
| lib-retry.sh | `.github/scripts/lib-retry.sh` | Retry helpers with exponential backoff and 429 detection |

---

## Troubleshooting

### Build Fails with "No space left on device"

The workflow already cleans up disk space, but for very large builds:
- Reduce platforms to `linux/amd64` only
- Build fewer versions at once

### Image Not Found in Registry

1. Check if the version exists: Go to Actions -> find the build run
2. Look at the "Check Releases" job summary
3. Verify the version is in the iSpy release history

### Registry Sync Issues

Run the workflow manually with action: `sync-registries`

### Docker Hub Description Sync Fails

The `DOCKERHUB_TOKEN` needs Admin or Read & Write scope for the Docker Hub API PATCH endpoint. Update the token at [Docker Hub Account Settings](https://hub.docker.com/settings/security).

### Pipeline Always Skips (quick-check)

The `pipeline-state` branch may have a stale `last-built-version`. Either:
- Use `force_build: true` to bypass
- Delete the `pipeline-state` branch to reset state

### Version Marked as Missing

The version might:
- Be too old (only last 20 versions are checked)
- Not exist in iSpy's release history
- Have been removed by iSpy

---

## Monitoring

### Job Summary

Each workflow run generates a summary with:
- Versions to build
- Missing versions
- Build results
- Image digests and tags

### Artifacts

Build artifacts are retained for 30 days:
- Trivy security scan results (SARIF format)
- Build information

### Security Alerts

Trivy scan results are uploaded to GitHub Security tab:
- View at: Security -> Code scanning alerts
- Filtered by severity: CRITICAL, HIGH
