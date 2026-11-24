# CLI installation and checksum verification

Use an explicit release from the [official release list](https://github.com/newrelic/newrelic-cli/releases).
Download its archive for your OS/architecture and its official checksum manifest.
Compute SHA-256 locally (PowerShell: `Get-FileHash -Algorithm SHA256 <archive>`;
macOS: `shasum -a 256 <archive>`; Linux: `sha256sum <archive>`). Compare against the
entry for that exact filename in the same release's manifest. If absent or different,
stop. Never skip or disable checksum checks. Only after a match, extract the archive,
place `newrelic` (`newrelic.exe` on Windows) on `PATH`, and run `newrelic --version`.
Confirm the selected release before configuring credentials or using commands.
Dataset and dataset-version commands require CLI >=v0.117.0.

## Pinned Scoop mismatch

At v0.117.1 commit `68884ea61cd53b328e3bf391dc61995173ed8dd6`, the
[official Scoop manifest](https://github.com/newrelic/newrelic-cli/blob/68884ea61cd53b328e3bf391dc61995173ed8dd6/newrelic-cli.json)
identifies version **0.117.0**, with this exact archive:

https://github.com/newrelic/newrelic-cli/releases/download/v0.117.0/newrelic-cli_0.117.0_Windows_x86_64.zip

- Manifest SHA-256: `dbe3ae9b440e15ae0f46715bf96828c520c4423307c133724f091162abf2d3c0`
- Preserved archive SHA-256: `bebf021ebfa17a2119d510981c560abce7671bb96deb98ff85c6b7ceb316908d`

The archive hash matches the official checksum manifest for the
[v0.117.0 release](https://github.com/newrelic/newrelic-cli/releases/tag/v0.117.0).
The supplied verification also reports a matching GitHub asset digest. Treat the
Scoop route at this revision as blocked. A later fix has not been verified.
The archive above is a manual Windows x86_64 alternative, subject to the checksum
and version checks above; it is v0.117.0, not a v0.117.1 binary.

## Scope of evidence

The supplied [immutable source comparison](https://github.com/newrelic/newrelic-cli/compare/05ba094109ac9db08c72c6e13f213ee8c58f0959...68884ea61cd53b328e3bf391dc61995173ed8dd6)
and full-source verification of 574 Git blobs show changes only to CHANGELOG.md
and newrelic-cli.json. Runtime, commands, help, and dependencies are unchanged.
This refresh did not execute any release binary or installer. The Windows archive
checksum observation does not validate every OS artifact or establish installer
safety. Existing activation, diagnostic, security, and publication blockers remain
separate and unresolved. Raw verification evidence is retained outside this repository.
