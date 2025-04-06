# Source:
# https://packaging.python.org/en/latest/specifications/inline-script-metadata/#reference-implementation

import re
import sys

import tomllib

REGEX: str = r'(?m)^# /// (?P<type>[a-zA-Z0-9-]+)$\s(?P<content>(^#(| .*)$\s)+)^# ///$'


def read(script: str) -> dict | None:
    name: str = 'script'
    matches = list(filter(lambda m: m.group('type') == name, re.finditer(REGEX, script)))
    if len(matches) > 1:
        # raise ValueError(f'Multiple {name:s} blocks found: {matches}')
        # To avoid showing the full stack trace:
        print(f'Multiple {name:s} blocks found: {matches}', file=sys.stderr)
        sys.exit(1)
    elif len(matches) == 1:
        content: str = ''.join(
            line[2:] if line.startswith('# ') else line[1:]
            for line in matches[0].group('content').splitlines(keepends=True)
        )
        return tomllib.loads(content)
    else:
        return None


if __name__ == '__main__':
    filename: str = sys.argv[1]
    with open(filename) as file:
        script: str = file.read()
    metadata: dict | None = read(script)
    if metadata is not None:
        print(metadata)
    else:
        print('No metadata found.')
