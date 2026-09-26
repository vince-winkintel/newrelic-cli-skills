# Identity and Access Management

Use the `usermanagement` command tree for authentication domains, users, groups, and memberships. Use `accessmanagement` for roles, permissions, and group access grants.

## Safety Contract

Identity and access changes can remove access, grant elevated privileges, or delete identities.

1. Default to read-only discovery.
2. Resolve IDs from current CLI output; do not guess an authentication-domain, user, group, role, or account ID.
3. Before a write, show the exact target, requested change, scope, and command, then require explicit confirmation.
4. Treat user/group deletion, membership removal, grant creation, and grant revocation as high-impact writes.
5. Run the corresponding read command after every write and verify the intended state.
6. Never print, log, or embed `NEW_RELIC_API_KEY` in a command.

## Prerequisites

The API key must have the capabilities required for the requested operation. New Relic documents Organization manager access for administration; read-only discovery requires at least authentication-domain read capability.

```bash
newrelic profile list
newrelic usermanagement --help
newrelic accessmanagement --help
```

Use the narrowest profile and account scope that can complete the task. The commands emit JSON by default; add `--format JSON` when scripts should make that requirement explicit.

## Read-Only Discovery

### Authentication domains

```bash
# List authentication domains
newrelic usermanagement auth-domains get

# Read one authentication domain
newrelic usermanagement auth-domains get --id "$AUTH_DOMAIN_ID"
```

### Users

`--authDomainId` is required for user lookups. Optional filters are `--id`, `--email`, and `--name`.

```bash
newrelic usermanagement users get --authDomainId "$AUTH_DOMAIN_ID"
newrelic usermanagement users get \
  --authDomainId "$AUTH_DOMAIN_ID" \
  --email "$USER_EMAIL"
newrelic usermanagement users get \
  --authDomainId "$AUTH_DOMAIN_ID" \
  --id "$USER_ID"
```

### Groups and membership

`--authDomainId` is required for group lookups. Group results include their members.

```bash
newrelic usermanagement groups get --authDomainId "$AUTH_DOMAIN_ID"
newrelic usermanagement groups get \
  --authDomainId "$AUTH_DOMAIN_ID" \
  --name "$GROUP_NAME"
newrelic usermanagement groups get \
  --authDomainId "$AUTH_DOMAIN_ID" \
  --id "$GROUP_ID"
```

### Roles, permissions, and grants

```bash
# Discover role IDs
newrelic accessmanagement roles get
newrelic accessmanagement roles get --name "$ROLE_NAME"
newrelic accessmanagement roles get --groupId "$GROUP_ID"

# Inspect permissions before granting a role
newrelic accessmanagement permissions get --roleId "$ROLE_ID"
newrelic accessmanagement permissions get --scope account
newrelic accessmanagement permissions get --scope organization

# Inspect current grants
newrelic accessmanagement grants get
newrelic accessmanagement grants get --groupId "$GROUP_ID"
```

Role-name matching is partial. If multiple roles match, stop and select the exact role ID from the returned data before making a grant.

## User Administration

### Create

`--authDomainId`, `--email`, and `--name` are required. Valid user tiers are `BASIC_USER_TIER`, `CORE_USER_TIER`, and `FULL_USER_TIER`.

```bash
newrelic usermanagement users create \
  --authDomainId "$AUTH_DOMAIN_ID" \
  --email "$USER_EMAIL" \
  --name "$USER_NAME" \
  --userType "$USER_TYPE"
```

Verify:

```bash
newrelic usermanagement users get \
  --authDomainId "$AUTH_DOMAIN_ID" \
  --email "$USER_EMAIL"
```

### Update

`--id` is required. Pass only the fields the user intends to change: `--email`, `--name`, `--userType`, or `--timeZone`.

```bash
newrelic usermanagement users update \
  --id "$USER_ID" \
  --timeZone "$TIME_ZONE"
```

Verify with `users get --authDomainId ... --id ...`.

### Delete

Deletion is permanent. Confirm the resolved user ID and email immediately before execution.

```bash
newrelic usermanagement users delete --id "$USER_ID"
```

Verify that `users get --authDomainId ... --id ...` no longer returns the user.

## Group Administration

### Create or rename

```bash
newrelic usermanagement groups create \
  --authDomainId "$AUTH_DOMAIN_ID" \
  --name "$GROUP_NAME"

newrelic usermanagement groups update \
  --id "$GROUP_ID" \
  --name "$NEW_GROUP_NAME"
```

Read the group back by ID after either command.

### Add or remove a member

```bash
newrelic usermanagement groups members add \
  --groupId "$GROUP_ID" \
  --userId "$USER_ID"

newrelic usermanagement groups members remove \
  --groupId "$GROUP_ID" \
  --userId "$USER_ID"
```

After either change, query the group by ID and confirm the membership list. Before removal, also inspect the group's grants because the user will lose access inherited through that group.

### Delete

Deleting a group is permanent and removes access inherited through its grants. Inspect current members and grants first.

```bash
newrelic usermanagement groups get \
  --authDomainId "$AUTH_DOMAIN_ID" \
  --id "$GROUP_ID"
newrelic accessmanagement grants get --groupId "$GROUP_ID"

# Execute only after explicit confirmation
newrelic usermanagement groups delete --id "$GROUP_ID"
```

Verify that the group lookup no longer returns the group.

## Access Grants

A grant assigns a role to a group at either account or organization scope. Inspect the role's permissions and the group's existing grants before changing access.

### Account-scoped grant

```bash
newrelic accessmanagement grants create \
  --groupId "$GROUP_ID" \
  --roleId "$ROLE_ID" \
  --scope account \
  --accountId "$NEW_RELIC_ACCOUNT_ID"
```

### Organization-scoped grant

```bash
newrelic accessmanagement grants create \
  --groupId "$GROUP_ID" \
  --roleId "$ROLE_ID" \
  --scope organization
```

### Revoke a grant

Use the same group, role, scope, and account ID as the existing grant.

```bash
# Account scope
newrelic accessmanagement grants revoke \
  --groupId "$GROUP_ID" \
  --roleId "$ROLE_ID" \
  --scope account \
  --accountId "$NEW_RELIC_ACCOUNT_ID"

# Organization scope
newrelic accessmanagement grants revoke \
  --groupId "$GROUP_ID" \
  --roleId "$ROLE_ID" \
  --scope organization
```

Verify grant creation or revocation with:

```bash
newrelic accessmanagement grants get --groupId "$GROUP_ID"
```

## Safe End-to-End Sequence

1. Run `auth-domains get` and resolve one authentication-domain ID.
2. Read users and groups in that domain; stop on ambiguous matches.
3. For a new identity, create the user and group only after confirmation, then read both back.
4. Add the user to the group after confirmation, then verify membership.
5. Read roles and inspect the chosen role's permissions.
6. Read existing grants for the group.
7. State whether the proposed grant is account- or organization-scoped and identify the account when applicable.
8. Create the grant after confirmation and read the group's grants back.
9. Report the exact IDs and verified final state without exposing credentials.
