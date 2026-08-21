# Canvas Automation

This repository provides a local setup for automating Canvas LMS work
with the [`canvas` CLI](https://jjuanrivvera.github.io/canvas-cli/) and
coding agents such as Codex.

The setup supports multiple Canvas instances. Each instance is given a
short local name (for example, `csuf`) and is configured with its Canvas
URL and a personal Canvas access token.

## Prerequisites

You need:

- Git
- Python 3
- macOS or Linux with a POSIX shell
- A Canvas account with permission to create a personal access token

The setup script checks its prerequisites and installs the Canvas CLI if
necessary.

If you plan to use Codex through its graphical interface, install the
[ChatGPT desktop app](https://help.openai.com/en/articles/20001276).
Codex is included in the desktop app; it is no longer a separate
application.

## Getting started

### 1. Clone the repository

Clone recursively so any Git submodules are initialized at the same
time:

```sh
git clone --recurse-submodules https://github.com/ProfAvery/canvas-automation.git
cd canvas-automation
```

If you already cloned the repository without its submodules, initialize
them with:

```sh
git submodule update --init --recursive
```

### 2. Create a Canvas access token

For each Canvas instance you want to use:

1. Log in to Canvas.
2. Open **Account -> Settings**.
3. Find **Approved Integrations**.
4. Choose **+ New Access Token**.
5. Give the token a useful purpose and expiration date.
6. Generate the token and copy it immediately. Canvas will not show the
   complete token again.

Treat the token like a password. It grants API access with your Canvas
permissions.

See the
[Canvas API authentication documentation](https://developerdocs.instructure.com/services/canvas/oauth2/file.oauth)
for more information about manually generated access tokens.

### 3. Configure your Canvas instances

Copy the example configuration:

```sh
cp etc/canvas-instances.example etc/canvas-instances
chmod 600 etc/canvas-instances
```

Edit `etc/canvas-instances`. Each non-comment line contains three
whitespace-separated fields:

```text
name    url     token
```

Add one line for each Canvas instance you use.

`etc/canvas-instances` contains credentials and is intentionally
excluded from Git. Do **not** commit it to your repository. The setup
script will refuse to finish the configuration if other groups or users
are able to access it.

### 4. Run the setup

```sh
./bin/setup-canvas-cli
```

The setup script:

- Verifies the required local tools;
- Installs or verifies the Canvas CLI;
- Ensures the Canvas CLI configuration directory is private;
- Creates or verifies each named Canvas instance;
- Stores the configured API token for each instance;
- Verifies that each token authenticates successfully;
- Runs `canvas doctor` to check the Canvas CLI configuration and
  connectivity;
- Checks that the repository's Codex configuration is present and warns
  if it has been locally modified; and
- Displays your Canvas identity and Dashboard courses for each
  configured instance.

If you run into an error or need to reconfigure, this script is safe to
run again.

### 5. Verify the result

At the end of setup, verify that the output shows:

1. Your Canvas identity for each configured instance; and
2. The courses you expect to see on that instance's Canvas Dashboard.

If both are correct, the Canvas CLI is ready to use.

### 6. Open the repository in Codex

If you are using Codex in the ChatGPT desktop app, create a local
project with the `canvas-automation` repository as its
**primary folder**.

You may want to keep course materials and files for upload outside the
repository. For example:

```text
Canvas Workspace/
├── canvas-automation/
└── files/
    ├── course-materials/
    └── uploads/
```

Add any folders Codex needs to work with as additional project folders.
Keep `canvas-automation` as the primary folder so Codex uses the
repository for Git operations and automatically discovers its
`AGENTS.md`, skills, and Codex configuration.

There is no need to add both the parent folder (`Canvas Workspace` in
this example) and `canvas-automation`. Instead, add the repository as
the primary folder and add only the separate folders containing material
Codex needs to access.

Files used to configure or upload course content do not need to be
stored in the `canvas-automation` repository.


### 7. Start Codex with a read-only review

Before asking Codex to modify a real Canvas course for the first time,
begin with a read-only review. Have it identify the courses you intend
to work on, discover their Canvas IDs, inspect their existing
course-level content and configuration, and propose a setup plan without
making any changes.

This provides a simple check that Codex is using the expected Canvas
instance and courses before you begin approving write operations. It
also gives you an opportunity to review the existing course state and
the proposed changes before anything is modified.

For an example, see
[`docs/ai-prompts/first-course-review.md`](docs/ai-prompts/first-course-review.md).

Once you have reviewed the inventory and plan, you can continue the same
Codex session and explicitly ask it to carry out the changes you want.

## Using Canvas CLI

After setup, you can use the `canvas` command. You do not need a wrapper
for ordinary interactive use.

Specify the instance you want with `--instance` when more than one
Canvas installation is configured:

```sh
canvas courses list --instance csuf
```

For course-specific commands, use the Canvas course ID shown by the CLI:

```sh
canvas assignments list --instance csuf --course-id 1234567
```

For available commands and options:

```sh
canvas --help
canvas assignments --help
```

Full Canvas CLI documentation is available at
<https://jjuanrivvera.github.io/canvas-cli/>.

## Multiple Canvas instances

To add another institution or Canvas installation, add another line to
`etc/canvas-instances` and rerun setup:

```text
# name      url                             token
school1     https://canvas.example.edu      7~first-token
school2     https://canvas.other.edu        7~second-token
```

Each name is a local alias used with `--instance`:

```sh
canvas courses list --instance school1
canvas courses list --instance school2
```

## Rotating an access token

When a token expires or you replace it:

1. Generate a new access token in Canvas.
2. Replace the token in the third field of the corresponding
   `etc/canvas-instances` line.
3. Run setup again:

```sh
./bin/setup-canvas-cli
```

The new token becomes the configured credential for that instance.

## Running third-party Canvas scripts

Some Canvas scripts expect authentication through the `CANVAS_URL` and
`CANVAS_TOKEN` environment variables rather than through the `canvas`
CLI configuration.

Use `bin/canvas-env` to run those scripts with the credentials for one
of the instances configured in `etc/canvas-instances`:

```sh
bin/canvas-env csuf ./path/to/script
```

You can run any command this way, including Python or shell scripts:

```sh
bin/canvas-env school1 python3 ~/Downloads/canvas-report.py
bin/canvas-env school2 sh ~/Downloads/update-course.sh
```

`canvas-env` looks up the named instance in `etc/canvas-instances`,
exports its URL and access token as `CANVAS_URL` and `CANVAS_TOKEN`, and
then runs the requested command. The variables are provided only to that
command and its child processes; they are not added to your current
shell environment.

This wrapper is intended mainly for scripts that do not use the `canvas`
CLI directly. For normal interactive use and scripts in this repository,
use the regular `canvas` command with a named instance.

## Security notes

- Use `--instance` explicitly when working with multiple Canvas
  installations.
- `etc/canvas-instances` contains access tokens in plaintext and must
  remain out of version control.
- Keep it accessible only by your user; `chmod 600 etc/canvas-instances`
  is the recommended setting.
- Treat Canvas access tokens as password-equivalent credentials.
- If a token is exposed, revoke it in Canvas immediately, generate a new
  one, update `etc/canvas-instances`, and rerun `bin/setup-canvas-cli`.
- This repository includes a checked-in Codex configuration intended to
  provide an appropriate approval boundary for Canvas operations. The
  recommended Codex configuration may change as Codex and Canvas CLI
  evolve; consult the output of `canvas agent guard --host codex` when
  reviewing or updating it.
- If you need to configure another coding agent, see
  <https://jjuanrivvera.github.io/canvas-cli/user-guide/agent-safety/>.
- `canvas-env` passes `CANVAS_URL` and `CANVAS_TOKEN` to the launched
  process and its children.
- Review third-party scripts before running them with `canvas-env`. They
  will have your Canvas token and all of its API permissions.
- Avoid printing or logging `CANVAS_TOKEN`, especially in shell
  debugging (`set -x`), CI logs, or copied command output.

## License

Licensed under the Apache License, Version 2.0. See `LICENSE`.

See `NOTICE` for attribution information.