#!/usr/bin/env python3
import sys
from docopt_ng import docopt


if __name__ == "__main__":
    # sys.argv[0] is this file name when it's called as a script
    arguments = docopt(docstring=sys.argv[1], argv=sys.argv[2:])
    print(arguments)
