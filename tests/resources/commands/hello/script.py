# /// script
# requires-python = ">=3.12"
# dependencies = []
# [tool.uv]
# exclude-newer = "2001-12-31T23:59:59Z"
# ///

import argparse


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Test script.")
    parser.add_argument("--some-int", type=int, help="Some number")
    parser.add_argument("--some-flag", action='store_true', help="Some flag")

    args: argparse.Namespace = parser.parse_args()

    some_int: int = args.some_int
    some_flag: bool = args.some_flag

    print(f"some_int='{some_int}', some_flag='{some_flag}'")
