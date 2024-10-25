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

## Help commands

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

## Debugging

- Use: `MYCLI_DEBUG=1 mycli ...`
- Or call the command directly: `CLI_DIR="path/to/bash-cli" ./commands/...`
  - For example: `CLI_DIR="path/to/bash-cli" ./commands/hello/world.sh 'John Doe'`

## Troubleshooting

### Check the version of `bash`

The output of `/usr/bin/env bash --version` must return at least version 5.

If it is different, follow the instructions from [the setup section](#setup).

### `zsh: command not found: mycli`

Check if the environment variable `PATH` contains the path to where the file `mycli` is:

```shell
echo "$PATH" | tr ':' "\n"
```

If it doesn't contain, follow the instructions from [the setup section](#setup).
