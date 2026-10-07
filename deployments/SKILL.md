# Deployment Markers

Record deployment events in New Relic so you can correlate releases with performance changes.

---

## Record a Deployment

```bash
newrelic apm deployment create \
  --applicationId <APP_ID> \
  --revision "v1.2.3" \
  --description "Brief description of what changed" \
  --user "deploy-bot"
```

### Required
- `--applicationId` — numeric APM application ID
- `--revision` — version string (e.g. git SHA, semver, MR number)

### Optional
- `--description` — what changed (show in NR UI on charts)
- `--user` — who/what deployed
- `--change-log` — detailed change notes

---

## Get Application ID

```bash
newrelic entity search --name "my-app" --type APPLICATION --domain APM | \
  jq '.[] | {name, applicationId}'
```

---

## List Recent Deployments

```bash
newrelic apm deployment list --applicationId <APP_ID>
```

---

## GitLab/GitHub CI Integration

Check out this skill repository in the CI job, set `NEW_RELIC_API_KEY` as a masked secret, and invoke the maintained helper after a successful deploy. Keep every CI-provided value in its own quoted argument:

```bash
./scripts/deployment-marker.sh \
  "$NEW_RELIC_APP_ID" \
  "${CI_COMMIT_SHORT_SHA:-${GITHUB_SHA:-unknown-revision}}" \
  "${CI_COMMIT_TITLE:-${GITHUB_COMMIT_MESSAGE:-Deployment}}" \
  "${GITLAB_USER_LOGIN:-${GITHUB_ACTOR:-ci-bot}}"
```

The helper requires a decimal application ID, rejects control characters in all text fields, and forwards each accepted value as a literal argument. Do not generate a script from CI variables and do not pass these values through `eval` or `source`.

---

## Why Deployment Markers Matter

After recording a deployment, the New Relic UI places a vertical line on all APM charts at that timestamp. This makes it immediately obvious if:
- Response times increased after a deploy
- Error rates spiked post-release
- Throughput dropped unexpectedly

You can also query them via NRQL:

```nrql
SELECT *
FROM Deployment
WHERE appId = <APP_ID>
SINCE 1 week ago
```

---

## Automation: Mark on Every Merge

Call the repository helper from a post-merge webhook or CI step rather than copying its implementation into generated source:

```bash
./scripts/deployment-marker.sh \
  "$NEW_RELIC_APP_ID" \
  "$RELEASE_REVISION" \
  "$RELEASE_DESCRIPTION" \
  "$DEPLOY_USER"
```
