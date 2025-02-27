# /// script
# requires-python = ">=3.12"
# dependencies = []
# [tool.uv]
# exclude-newer = "2025-01-31T23:59:59Z"
# ///

import argparse
import sys


def add(a: int | None, b: int | None) -> int | None:
    if a is None or b is None:
        return None
    return a + b


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Prints a greeting.")
    parser.add_argument("name", type=str, help="The name to greet.")
    parser.add_argument("--foo", type=str, help="Some named parameter")
    parser.add_argument("--some-flag", type=str, help="Some flag")

    # args: argparse.Namespace = parser.parse_args()
    args, extra_args = parser.parse_known_args()

    name: str = args.name
    foo: str = args.foo
    some_flag: bool = args.some_flag == "true"

    print("Hello from the Python script!")
    print()
    print(f"Python version: {sys.version}")
    print()
    print("Received arguments:")
    print(" ".join(sys.argv[1:]))
    print()
    print("Parsed arguments:")
    print(f"- name='{name}'")
    print(f"  type(name)='{type(name).__name__}'")
    print(f"- foo='{foo}'")
    print(f"  type(foo)='{type(foo).__name__}'")
    print(f"- some_flag='{some_flag}'")
    print(f"  type(some_flag)='{type(some_flag).__name__}'")
    print()
    print("Additional arguments:")
    print(f"- {extra_args}")
    print(f"  type(extra_args)='{type(extra_args).__name__}'")
