# CLI configuration validation: scope and safeguards

## Compatibility

Use New Relic CLI **0.115.9 or later** when validating accounts with more than
1,000 ingest keys. This is the minimum release with the paginated LICENSE-key
lookup fix; it is not a minimum for every workflow in this skill set. An older
CLI's incomplete search can falsely report that a configured key is invalid.
Do not rotate a valid key merely to work around an old client's search limit.

## Target and telemetry preflight

- `diagnose validate` checks the effective CLI profile and connectivity, not the
  contents of an agent YAML or XML file. It has no `--config` option.
- Confirm the account, region, profile, and intended hostname disclosure before
  execution. `--profile` selects a stored profile; `NEW_RELIC_API_KEY`,
  `NEW_RELIC_ACCOUNT_ID`, `NEW_RELIC_REGION`, and `NEW_RELIC_LICENSE_KEY` override
  its corresponding fields. Do not print key values or dump the full configuration.
- Obtain explicit approval for the live write. After key validation, the command
  sends an `NrIntegrationError` event containing `hostname`, a generated `guid`,
  and purpose `New Relic CLI configuration validation`, then polls NRQL for that
  hostname/GUID. This intentionally generated event is not itself proof of an
  application ingestion error. A successful run is not an agent-health audit.
- Do not run this command during an offline review or as an implicit prerequisite
  to a read-only query. On failure, preserve a sanitized error and confirm the
  target and CLI version; do not expose, replace, or broaden credentials.

## Key lookup behavior

The shared validator searches account-scoped **LICENSE ingest keys**, following
pagination, and compares the configured key. The installer first searches for an
exact `Installer Ingest License Key` name (using a substring filter followed by
an exact match), then falls back to the full LICENSE-key inventory and existing
key-selection behavior. Search results remain subject to the user's visibility.

Only when the CLI has already auto-fetched the key successfully **in that same
process** does the shared validator skip the redundant key-list comparison. This
is not a bypass of tracer ingestion/read-back and does not let a separate
`diagnose validate` invocation trust a previous install. This skill does not
instruct the agent to run installers or alter the machine to validate credentials.

## Immutable provenance

Behavior checked against official source at commit
`4676e575e0c81a3fae344174d886fe4b3a94f1a0`:

- [Validation command](https://github.com/newrelic/newrelic-cli/blob/4676e575e0c81a3fae344174d886fe4b3a94f1a0/internal/diagnose/command_validate.go)
- [Shared config validator](https://github.com/newrelic/newrelic-cli/blob/4676e575e0c81a3fae344174d886fe4b3a94f1a0/internal/diagnose/config_validator.go)
- [License-key discovery and selection](https://github.com/newrelic/newrelic-cli/blob/4676e575e0c81a3fae344174d886fe4b3a94f1a0/internal/client/client.go)
- [Client dependency with pagination](https://github.com/newrelic/newrelic-client-go/blob/0482d5efa266e8939a8558aa98b44180aead3047/pkg/apiaccess/keys.go)

These are operational findings, not a promise of access to every key or a
replacement for approval. Command examples in the parent skill are authored;
they are not presented as byte-exact binary help captures.
