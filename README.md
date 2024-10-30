# bash-cli

Command-line interface (CLI) written in `bash`. This repository contains the minimal content for the
CLI. You can create your own CLI by copying the content, and replacing `mycli` and `bash-cli` with
your command name.

## Why bash?

`bash` was chosen because it requires almost no setup, has a good ecosystem of commands, is good for
text processing (with tools like `grep`, `sed`, `awk`, `cut`), allows quick prototyping (e.g., copy
commands directly from the terminal), is portable across platforms (operating system and computer
architecture), allows calling commands in other programming languages.

The cons are that `bash` is not a very popular or beloved language, the readability may not be good
specially when using complex programming logic, error handling is weak (e.g., the script may
continue running when there are errors, the command may stop without error message).

## Design

1. The environment variable `PATH` must be edited to include the directory where `mycli` is.
2. When running `mycli <cmd1> <cmd2>`, the bash file `mycli` defines the global variable `CLI_DIR`
   and runs the bash script `commands/<cmd1>/<cmd2>.sh`.
3. Every bash script in the `commands` folder:
   1. Follows the pattern `commands/<cmd1>/<cmd2>.sh`.
   2. Loads all helper functions from `<CLI_DIR>/core/helpers.sh`.
   3. Defines the usage and options with comments starting with `##?` and following the `docopt`
   syntax, explained at <http://docopt.org/>.
   4. Internal functions call a Python script to parse the documentation and return the arguments as
   a Python `dict`, which is then converted into a Python string compatible with `bash`, so that the
   variables can be exported to be used by the `bash` script.

## Setup

Run: `scripts/mycli_setup.sh`

This script will:

- Install [Homebrew](https://brew.sh/)
- Install commands with Homebrew
- Edit the shell profile files to:
  - Add the CLI to the `PATH` variable
  - Enable autocomplete for the CLI
- Make the required scripts executable

## Using the CLI

```shell
mycli [<cmd1> <cmd2>]
```

Examples:

- Show all available commands: `mycli`
- Show all commands under `my-command`: `mycli my-command`
  - Example: `mycli hello`
- Run a command without parameters: `mycli my-command my-subcommand`
- Run a command with parameters:

  `mycli my-command my-subcommand my-positional-param --my-flag --my-named-param="my-value"`
  - Example: `mycli hello world John`

### Autocomplete

```shell
mycli + TAB
mycli <cmd1> + TAB
```

Autocomplete is **not available** for the arguments of `mycli <cmd1> <cmd2>`.

### Help commands

```shell
mycli help
mycli --help
mycli -h

mycli help <cmd1>
mycli <cmd1> --help
mycli <cmd1> -h

mycli <cmd1> <cmd2> --help
mycli <cmd1> <cmd2> -h
```

## Debug

- Use: `MYCLI_DEBUG=1 mycli ...`
  - This will enable debugging mode in bash, which makes the shell print each command and its
  arguments to the standard error (`stderr`) as they are executed. This is helpful for tracing the
  execution of the CLI and understanding its flow.
- Or call the script directly, skipping the CLI: `CLI_DIR="path/to/bash-cli" ./commands/...`
  - For example: `CLI_DIR="path/to/bash-cli" ./commands/hello/world.sh 'John Doe'`

## Troubleshoot

### Check the version of `bash`

The output of `/usr/bin/env bash --version` must return at least version 5.

If it is different, follow the instructions from [the setup section](#setup).

### `zsh: command not found: mycli`

Check if the environment variable `PATH` contains the path to where the file `mycli` is:

```shell
echo "$PATH" | tr ':' "\n"
```

If it doesn't contain, follow the instructions from [the setup section](#setup).
