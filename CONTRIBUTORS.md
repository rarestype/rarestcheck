## Testing the `sync` action

To perform a dry run of the repo `sync` action, use:

```bash
swift run -c release rarestcheck sync Templates/Repositories -t autosync
```

This is very heavy on the GitHub API, as it clones dozens of repositories, so you should run this sparingly, only when you have a near-complete implementation that is ready for a pull request. In most cases, `swift build` is sufficient for intermediate verification.

The `sync` command requires GitHub App credentials. Before running it, load the credentials from `local.env`:

```bash
set -a
source local.env
set +a
```

The `local.env` file contains:
- `AUTOMATION_APP_CLIENT` — GitHub App client ID
- `AUTOMATION_APP_SECRET` — GitHub App client secret
- `AUTOMATION_APP_KEY` — GitHub App private key (PEM format)

This file is gitignored and must be created locally. Contact the repository maintainer if you need access to these credentials.

Never run `sync` locally with the `-f` or `--push` flags.
