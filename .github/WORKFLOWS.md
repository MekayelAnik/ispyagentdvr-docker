# GitHub Actions Workflow Documentation

## Overview

This repository uses a unified GitHub Actions workflow for:
1. **Automated Docker image building and publishing**
2. **Agent DVR version monitoring and tracking**
3. **Registry synchronization**
4. **5-day stable promotion**

---

## Workflow

| Workflow | File | Purpose |
|----------|------|---------|
| Docker Build & Publish | `docker-build.yml` | Build, publish, version tracking, and image management |

---

## Workflow: Docker Build & Publish

**File:** `.github/workflows/docker-build.yml`

### Features

- **Automatic Release Detection**: Checks for new Agent DVR releases every 30 minutes
- **Multi-Platform Builds**: Supports `linux/amd64`, `linux/arm64`, and `linux/arm/v7`
- **Dual Registry Support**: Publishes to both Docker Hub and GitHub Container Registry (ghcr.io)
- **Registry Synchronization**: Ensures images exist in both registries
- **Manual Version Builds**: Build specific versions (single, comma-separated, or range)
- **Image Promotion**: Promote any version to `latest` or `stable` tags
- **5-Day Stable Rule**: Automatically marks releases as `stable` after 5 days
- **Version Validation**: Warns about missing versions but doesn't fail the build
- **Security Scanning**: Optional Trivy vulnerability scanning (non-blocking)
- **ZSTD Compression**: Optimal image compression for faster pulls
- **Build Provenance & SBOM**: Supply chain security attestations

---

## Required Secrets

Configure these secrets in your repository settings:

| Secret | Description | Required |
|--------|-------------|----------|
| `DOCKERHUB_USERNAME` | Your Docker Hub username | Yes |
| `DOCKERHUB_TOKEN` | Docker Hub access token (with push permissions) | Yes |

> **Note:** `GITHUB_TOKEN` is automatically provided and has `packages:write` scope for ghcr.io.

### Creating Docker Hub Token

1. Go to [Docker Hub Account Settings](https://hub.docker.com/settings/security)
2. Click "New Access Token"
3. Name: `GitHub Actions - ispyagentdvr`
4. Permissions: Read, Write, Delete
5. Copy the token and add it as `DOCKERHUB_TOKEN` secret

---

## Trigger Types

### 1. Scheduled (Automatic)

Runs every 30 minutes to check for new Agent DVR releases.

```
Schedule: */30 * * * * (every 30 minutes)
```

When a new version is detected:
1. Builds the image for all platforms
2. Pushes to both registries with version tag and `latest` tag
3. Syncs registries if needed
4. Checks if 5-day stable promotion is needed

### 2. Manual Trigger (workflow_dispatch)

Trigger manually from the Actions tab with various options.

#### Actions Available

| Action | Description |
|--------|-------------|
| `auto-check` | Check for new releases (same as scheduled) |
| `build-versions` | Build specific version(s) |
| `promote-image` | Promote a version to `latest` or `stable` |
| `sync-registries` | Synchronize images between registries |
| `mark-stable` | Force mark a version as `stable` |

---

## Manual Build Examples

### Build a Single Version

1. Go to Actions → Docker Build & Publish → Run workflow
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

---

## Checkbox Options

| Option | Default | Description |
|--------|---------|-------------|
| `force_build` | `false` | Rebuild even if image exists |
| `skip_existing` | `true` | Skip versions already in registries |
| `tag_as_latest` | `false` | Also tag as `latest` |
| `run_security_scan` | `true` | Run Trivy vulnerability scan |
| `push_to_dockerhub` | `true` | Push to Docker Hub |
| `push_to_ghcr` | `true` | Push to GitHub Container Registry |

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

> **Note:** Level 22 produces the smallest images but takes longer to build. For quick test builds, use level 3-5.

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

The workflow creates the following tags:

| Tag | Description |
|-----|-------------|
| `7.0.9.0` | Specific version (multi-arch manifest) |
| `latest` | Most recent release |
| `stable` | Release that's been out for 5+ days |
| `7.1.8.0-29012026` | Version with build date (DDMMYYYY, Bangladesh Time UTC+6) |

---

## Registry Synchronization

The workflow ensures images exist in both registries:

- If image exists in Docker Hub but not ghcr.io → Copy to ghcr.io
- If image exists in ghcr.io but not Docker Hub → Copy to Docker Hub
- Uses `skopeo copy --all` to preserve all architectures

---

## Version Validation

When building specific versions:

1. Workflow fetches the release history from iSpy website
2. Validates requested versions against available versions
3. **Missing versions generate warnings but don't fail the build**
4. Only valid versions are built

Example warning:
```
⚠️ Version 7.0.99.0 not found in release history - will be skipped
```

---

## Build Optimizations

| Feature | Description |
|---------|-------------|
| ZSTD Compression | **Level 22 by default** (maximum compression, configurable 1-22) |
| OCI Media Types | Maximum registry compatibility |
| Dual Cache | GitHub Actions cache + Registry cache for fastest builds |
| Inline Cache | `BUILDKIT_INLINE_CACHE=1` for pulling cache from images |
| BuildKit Config | `max-parallelism=4`, optimized GC policies |
| Provenance | SLSA build provenance attestation (`mode=max`) |
| SBOM | Software Bill of Materials generation |
| Parallel Builds | Up to 3 versions built simultaneously |
| Docker Hub Mirror | Uses `mirror.gcr.io` for faster base image pulls |
| Force Compression | Ensures consistent layer sizes across platforms |
| Disk Cleanup | Frees space before builds |

---

## Renovate

Renovate is configured with best practices for automated dependency updates.

### Configuration Highlights

| Feature | Description |
|---------|-------------|
| **Preset** | `config:best-practices` (includes recommended + security hardening) |
| **Digest Pinning** | `docker:pinDigests`, `helpers:pinGitHubActionDigests` |
| **Schedule** | Weekly on Mondays before 06:00 AM (Bangladesh Time) |
| **Minimum Release Age** | 3 days (wait for potential hotfixes) |
| **Automerge** | Minor/patch updates for stable packages (version >= 1.0.0) |
| **OSV Alerts** | Vulnerability alerts via Open Source Vulnerabilities database |

### Package Rule Priority

| Priority | Group | Packages |
|----------|-------|----------|
| **10** (Highest) | Security Actions | `aquasecurity/*`, `securego/*`, `github/codeql*` |
| **5** | Core GitHub Actions | `actions/*` |
| **3** | Docker Ecosystem | `docker/*` |
| **1** | Other Actions | Everything else |

### Automerge Rules

- Automerges `minor`, `patch`, `pin`, and `digest` updates automatically
- Only for packages with current version >= 1.0.0 (stable semver)
- Squash merge strategy for clean commit history

> **Note:** Docker base images are managed dynamically through the workflow inputs, not Renovate.

---

## Reusable Components

### Composite Actions

The workflow uses local composite actions to reduce code duplication:

| Action | Path | Purpose |
|--------|------|---------|
| Registry Login | `.github/actions/registry-login` | Login to Docker Hub + GHCR |
| Registry Sync | `.github/actions/registry-sync` | Bidirectional image sync |

### Utility Scripts

| Script | Path | Purpose |
|--------|------|---------|
| Version Utils | `.github/scripts/version-utils.sh` | Version parsing, validation, date generation |

---

## Troubleshooting

### Build Fails with "No space left on device"

The workflow already cleans up disk space, but for very large builds:
- Reduce platforms to `linux/amd64` only
- Build fewer versions at once

### Image Not Found in Registry

1. Check if the version exists: Go to Actions → find the build run
2. Look at the "Check Releases" job summary
3. Verify the version is in the iSpy release history

### Registry Sync Issues

Run the workflow manually with action: `sync-registries`

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
- View at: Security → Code scanning alerts
- Filtered by severity: CRITICAL, HIGH
