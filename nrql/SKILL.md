# NRQL Queries and Macros

Run ad-hoc NRQL queries against your New Relic account and manage reusable,
organization-scoped NRQL macros.

## Organization-Scoped Macros

A macro is a named expression fragment referenced as `$macroName` in NRQL. Macros
are shared across accounts in an organization; they are not limited to the account
selected by `--accountId`. Use the authenticated organization's intended profile
and a User API key with the necessary access. Never print or paste the key.

**Safety:** Read the current macro before proposing changes. Require explicit
authorization before creating, updating, or deleting an organization macro. An
expression update takes effect on the next execution of every referencing query,
dashboard widget, and alert condition. Deletion is permanent and breaks expansion
for those references. Inspect downstream use and agree on the exact target GUID,
expression, and parameter count before writing; do not run a delete as a test.

| Command | Flags and behavior |
|---|---|
| `newrelic nrql macros list` | No command-specific flags; organization is inferred from the API key. No `--org-id` or pagination flag. |
| `newrelic nrql macros get --id "$MACRO_ID"` | Required entity GUID, not the macro name; read-only. |
| `newrelic nrql macros create --name NAME --expression EXPRESSION` | Required `--name`/`-n` and `--expression`/`-e`; name is immutable. Optional `--org-id` overrides automatic organization lookup for creation only; it does not grant access. |
| `newrelic nrql macros update --id "$MACRO_ID"` | Required GUID and at least one of `--expression`/`-e` or `--parameter-count`. An explicitly empty expression is rejected. The name cannot be changed. |
| `newrelic nrql macros delete --id "$MACRO_ID"` | Required GUID; permanent write, with no command-specific confirmation flag. Obtain approval first. |

For positional tokens such as `$1` and `$2`, supply `--parameter-count` with the
number of distinct tokens in the expression. On update, omitting the flag leaves
the count unchanged; passing `0` explicitly clears it. Keep the expression and
count consistent. The CLI passes these values to the API rather than validating
the token count locally.

**Shell quoting matters:** single-quote expressions containing literal `$N` or
`$macroName` tokens. The upstream help's double-quoted positional example would
allow a POSIX shell to substitute `$1`/`$2` before the CLI receives the expression.
The following are authored examples, not captured API responses or help output:

```bash
# Read-only inventory and exact-target inspection
newrelic nrql macros list --format JSON
newrelic nrql macros get --id "$MACRO_ID" --format JSON

# Only after approval: preserve the literal parameter tokens
newrelic nrql macros create \
  --name filterStatusRegion \
  --expression 'status = $1 AND region = $2' \
  --parameter-count 2

# Only after approval: update the chosen GUID, then read it back
newrelic nrql macros update --id "$MACRO_ID" \
  --expression 'status = $1' --parameter-count 1
newrelic nrql macros get --id "$MACRO_ID" --format JSON
```

After creation, use the returned entity GUID for `get` and verify the name,
expression, scope, and count. After an authorized deletion, read the same GUID back
and confirm a not-found result rather than treating a transport/authentication error
as proof of deletion. Do not automatically retry an uncertain write.

Create/get/update return entity objects; list returns an array when results are
present. Empty inventory and deletion use info-log messages, not JSON entity data.
Use global `--format JSON` (default), `--format YAML`, or `--plain` as appropriate;
do not assume every successful command emits parseable JSON. The list implementation
issues one entity-search request without a cursor loop; do not treat a returned
page as a proven exhaustive inventory for destructive decisions.

Official implementation and command reference:
[`internal/nrql/command_macros.go`](https://github.com/newrelic/newrelic-cli/blob/91d426a0d1c19cd1127d60081323ff6e88ff83eb/internal/nrql/command_macros.go),
[`internal/nrql/README.md`](https://github.com/newrelic/newrelic-cli/blob/91d426a0d1c19cd1127d60081323ff6e88ff83eb/internal/nrql/README.md).

---

## Basic Syntax

```bash
newrelic nrql query \
  --accountId $NEW_RELIC_ACCOUNT_ID \
  --query "YOUR NRQL HERE"
```

---

## Key Event Types

| Event Type | What it tracks |
|---|---|
| `Transaction` | Web/non-web request timings |
| `TransactionError` | Exceptions and errors |
| `DatabaseTrace` | Individual DB query timings |
| `ExternalTrace` | Outbound HTTP calls |
| `SystemSample` | Host CPU, memory, disk |
| `ProcessSample` | Per-process metrics |
| `Log` | Log lines (if log forwarding enabled) |
| `PageView` | Browser page load events |
| `JavaScriptError` | Front-end JS errors |

---

## Common Patterns

### Response Time

```nrql
SELECT average(duration), percentile(duration, 95, 99)
FROM Transaction
WHERE appName = 'my-app'
TIMESERIES 5 minutes
SINCE 1 hour ago
```

### Error Rate

```nrql
SELECT percentage(count(*), WHERE error IS true) AS 'Error %'
FROM Transaction
WHERE appName = 'my-app'
TIMESERIES 5 minutes
SINCE 1 hour ago
```

### Throughput (RPM)

```nrql
SELECT rate(count(*), 1 minute) AS 'RPM'
FROM Transaction
WHERE appName = 'my-app'
TIMESERIES
SINCE 1 hour ago
```

### Slowest Endpoints

```nrql
SELECT average(duration)
FROM Transaction
WHERE appName = 'my-app'
FACET name
SINCE 1 hour ago
LIMIT 10
ORDER BY average(duration) DESC
```

### DB Bottlenecks

```nrql
SELECT average(duration), count(*)
FROM DatabaseTrace
WHERE appName = 'my-app'
FACET statement
SINCE 1 hour ago
LIMIT 10
ORDER BY average(duration) DESC
```

### Compare Two Time Windows

```nrql
SELECT average(duration)
FROM Transaction
WHERE appName = 'my-app'
SINCE 1 hour ago
COMPARE WITH 1 day ago
```

### Count Errors by Type

```nrql
SELECT count(*)
FROM TransactionError
WHERE appName = 'my-app'
FACET error.class
SINCE 1 hour ago
```

### Host CPU

```nrql
SELECT average(cpuPercent)
FROM SystemSample
FACET hostname
TIMESERIES 5 minutes
SINCE 1 hour ago
```

### Host Memory

```nrql
SELECT average(memoryUsedPercent)
FROM SystemSample
FACET hostname
TIMESERIES 5 minutes
SINCE 1 hour ago
```

---

## Time Range Shortcuts

```
SINCE 30 minutes ago
SINCE 1 hour ago
SINCE 3 hours ago
SINCE 1 day ago
SINCE 1 week ago
SINCE '2026-02-01 00:00:00' UNTIL '2026-02-02 00:00:00'
```

---

## Useful Clauses

```nrql
FACET name          -- group by field
TIMESERIES 5 min    -- time series chart
LIMIT 20            -- max results
ORDER BY count() DESC
COMPARE WITH 1 day ago
WHERE appName = 'x' AND duration > 1
```

---

## Output Formatting

```bash
# Raw JSON
newrelic nrql query --accountId $NEW_RELIC_ACCOUNT_ID \
  --query "SELECT count(*) FROM Transaction SINCE 1 hour ago" \
  --format JSON

# JSON is the default; --plain emits compact text
newrelic nrql query --accountId $NEW_RELIC_ACCOUNT_ID \
  --query "SELECT count(*) FROM Transaction SINCE 1 hour ago"
```
