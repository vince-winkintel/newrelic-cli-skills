# Agent Diagnostics

Validate New Relic agent configuration, connectivity, and reporting status.

---

## Run Full Diagnostics

```bash
newrelic diagnose run
```

Checks: API key validity, account connectivity, agent config files, log paths, proxy settings.

---

## Validate CLI Configuration and Connectivity

This is a **live telemetry write**, not a local agent-configuration-file check.
Obtain explicit approval before running it. Confirm the intended account, region,
profile, and effective environment overrides without printing credentials; the
tracer includes the machine hostname. The command validates the configured LICENSE
ingest key, sends a tracer event, then queries New Relic to confirm receipt.

```bash
# Only after explicit approval for the verified target and hostname disclosure
newrelic diagnose validate --profile "staging.us"
```

There is no `diagnose validate --config` flag. Do not pass an agent YAML/XML file
to this command or use it as an offline lint. A successful run confirms tracer
ingestion, not that every application agent is healthy. Read
[configuration-validation safeguards and compatibility](references/config-validation.md)
before using this workflow, especially for accounts with many ingest keys. If it
fails, report the failure; do not rotate keys, run installers, or bypass validation
without separate authorization.

---

## Check Agent is Reporting

```bash
# Verify an app is actively sending data
newrelic nrql query --accountId $NEW_RELIC_ACCOUNT_ID --query "
  SELECT count(*)
  FROM Transaction
  WHERE appName = 'my-app'
  SINCE 10 minutes ago
"
# count = 0 means agent is not reporting

# Check entity reporting status
newrelic entity search --name "my-app" --type APPLICATION --domain APM | \
  jq '.[] | {name, reporting}'
```

---

## Check Agent Version

```bash
newrelic entity search --name "my-app" --type APPLICATION --domain APM | \
  jq '.[] | {name, tags: (.tags[] | select(.key == "agentVersion"))}'
```

---

## Connectivity Test

```bash
# Test API key and account access
newrelic profile list --format JSON
newrelic nrql query --accountId $NEW_RELIC_ACCOUNT_ID \
  --query "SELECT count(*) FROM NrIntegrationError SINCE 1 hour ago"
```

Inspect event details and purpose before diagnosing an ingestion issue. CLI
configuration validation intentionally emits an `NrIntegrationError` tracer with
purpose `New Relic CLI configuration validation`; a nonzero count alone is not
proof of an application ingestion failure.

---

## Common Issues

| Symptom | Likely Cause | Fix |
|---|---|---|
| App shows `reporting: false` | Agent stopped or config missing | Restart app pool / check agent logs |
| Transaction count = 0 | IIS app pool recycled without agent init | Ensure agent auto-instruments on startup |
| High `NrIntegrationError` | Data too large or malformed | Check agent logs for serialization errors |
| `alertSeverity: NOT_CONFIGURED` | No alert conditions on the entity | Add NRQL or APM metric conditions |

---

## .NET Agent Specific (Windows/IIS)

```bash
# Check which apps are instrumented on a host
newrelic entity search --name "my-host" --type HOST | \
  jq '.[] | .tags[] | select(.key == "apmApplicationNames")'

# Agent logs location (Windows)
# C:\ProgramData\New Relic\.NET Agent\Logs\
```

---

## Profile Management

```bash
# Machine-readable profile inventory; do not parse decorated table text
newrelic profile list --format JSON

# Print the persisted default profile name (the JSON key is capitalized `Name`)
newrelic profile list --format JSON | jq -r '.[] | select(.isDefault) | .Name'

# Switch profile; shell-quote the exact profile name
newrelic profile default --profile "production.us"

# Add a new profile
newrelic profile add \
  --profile "staging.us" \
  --apiKey $NEW_RELIC_API_KEY \
  --accountId $NEW_RELIC_ACCOUNT_ID \
  --region US  # US, EU, JP, GOV, or FEDRAMP (alias for GOV)

# Confirm an exact profile name before deleting it
PROFILE_NAME='production.us'
if newrelic profile list --format JSON | \
  jq -e --arg p "$PROFILE_NAME" 'any(.[]; .Name == $p)' >/dev/null; then
  newrelic profile delete --profile "$PROFILE_NAME"
else
  printf 'Profile %s not found; refusing to delete.\n' "$PROFILE_NAME" >&2
fi
```

Profile names may contain dots and other punctuation. Preserve the exact identifier
and always shell-quote it for `add`, `default`, and `delete`. If the exact-name lookup
fails, stop without deleting a profile.
