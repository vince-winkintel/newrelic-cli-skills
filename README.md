# newrelic-cli-skills

An [OpenClaw](https://openclaw.ai) agent skill for monitoring, querying, and managing New Relic observability data via the `newrelic` CLI.

## What It Does

- **Performance triage** — identify slow transactions, DB bottlenecks, and error spikes
- **NRQL queries and macros** — run ad-hoc queries and manage reusable organization-scoped expressions; macro writes require explicit approval and impact review
- **AI Monitoring** — find AI-enabled applications and inspect LLM token, error, tool, embedding, and message telemetry; discover datasets and versions, with explicit approval required for irreversible deletion
- **Deployment markers** — record releases so you can correlate deploys with performance changes
- **Alert and incident inspection** — query incident telemetry and inspect entity alert severity without mutating alert configuration
- **Infrastructure monitoring** — host CPU, memory, disk, and process metrics
- **CLI and agent diagnostics** — check CLI profile/connectivity and agent reporting; live validation telemetry and nrdiag download/execution require explicit approval, with separate authorization for diagnostic-data uploads
- **Identity and access management** — inspect and administer authentication domains, users, groups, memberships, roles, permissions, and access grants

## Requirements

- [`newrelic` CLI](https://github.com/newrelic/newrelic-cli) installed
- `NEW_RELIC_API_KEY` — User key (starts with `NRAK-`)
- `NEW_RELIC_ACCOUNT_ID` — Numeric account ID

Dataset commands require CLI **>=v0.117.0**. See the self-contained
[dataset reference](aimonitoring/references/datasets.md) for flags, scope, limits,
and deletion safeguards. This feature minimum does not replace earlier workflow minima.

## Install CLI

Use Homebrew on macOS or a checksum-verified archive from the official New Relic CLI releases page.

### Option 1: Homebrew (macOS)

```bash
brew install newrelic-cli
```

### Option 2: Scoop (Windows) — blocked by archive checksum mismatch

The official Scoop manifest hash does not match the published Windows archive in
three checked releases, including the default-branch manifest reviewed on 2026-11-24.
The mismatch persists after the manifest version bump; the tag's older manifest is
not itself the defect. Treat this route as blocked; do not skip or disable checksum
checks. See the [installation reference](references/installation.md) for immutable
manifest revisions, archive hashes, and the evidence needed to re-evaluate this block.

### Option 3: Manual install from official releases

1. Open https://github.com/newrelic/newrelic-cli/releases and select an explicit release.
2. Download the archive for your OS/architecture and that same release's official checksum manifest.
3. Compute the archive's SHA-256 and compare it with the manifest entry for the exact filename
   (for example, PowerShell `Get-FileHash -Algorithm SHA256 <archive>` or macOS `shasum -a 256 <archive>`).
   Compare hexadecimal hashes case-insensitively: PowerShell prints uppercase while
   the release manifests use lowercase. Stop if the checksum is missing or differs;
   never bypass verification. A match detects corruption and manifest drift, not
   release authenticity: an attacker able to replace both files can preserve the match.
4. Only after a match, extract it and move `newrelic` (Windows: `newrelic.exe`) into a directory on your `PATH`.
5. Run `newrelic --version` and confirm it reports the release you selected before configuring credentials.

The [installation reference](references/installation.md) records the verified Windows
archive alternative and the limits of that verification.

## Setup

```bash
newrelic profile add \
  --profile default \
  --apiKey $NEW_RELIC_API_KEY \
  --accountId $NEW_RELIC_ACCOUNT_ID \
  --region US  # US, EU, JP, GOV, or FEDRAMP (alias for GOV)

newrelic profile default --profile default
```

## Sub-skills

| Sub-skill | Purpose |
|---|---|
| `apm/` | Performance triage — slow transactions, DB analysis, error rates |
| `nrql/` | NRQL queries and organization-scoped macros (create/get/list/update/delete) |
| `aimonitoring/` | AI/LLM telemetry, dataset discovery/version inventory, and approval-gated deletion |
| `deployments/` | Deployment markers and release tracking |
| `alerts/` | Read-only incident telemetry and entity alert severity |
| `infrastructure/` | Host metrics — CPU, memory, disk, processes |
| `diagnostics/` | CLI profile/connectivity validation, agent reporting, and approval-gated nrdiag suites |
| `iam/` | Identity and access administration — users, groups, roles, permissions, grants |

## Scripts

| Script | Purpose |
|---|---|
| `check-performance.sh` | Health check across all apps |
| `deployment-marker.sh` | Record a deployment event |
| `top-slow-transactions.sh` | Find the 10 slowest transactions |
| `error-report.sh` | Recent errors with messages and counts |

## License

MIT
