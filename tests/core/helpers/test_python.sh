#!/usr/bin/env bash
set -euo pipefail

test_run_python_script() {
  local result expected

  result=$(
    run_python_script \
      "tests/resources/commands/hello/script.py" \
      "--some-int=42" "--some-flag"
  )
  expected="some_int='42', some_flag='True'"
  assertEquals "$expected" "$result"

  result=$(
    run_python_script \
      "tests/python/read_script_metadata.py" \
      "tests/resources/commands/hello/script.py"
  )
  expected="{'requires-python': '>=3.12', 'dependencies': [], 'tool': {'uv': {'exclude-newer': '2001-12-31T23:59:59Z'}}}"
  assertEquals \
    "Test the behavior of the script 'read_script_metadata.py'" \
    "$expected" \
    "$result"
}

test_ipynb_cleanmetadata() {
  local result tmp_file ipynb_content expected input_content

  # In-place modification (default: output-file = input-file)
  tmp_file="$(mktemp /tmp/test-XXXXXX)"
  mv "$tmp_file" "${tmp_file}.ipynb"
  tmp_file="${tmp_file}.ipynb"
  ipynb_content=$(
    cat <<'JSON'
{
 "cells": [
  {
   "cell_type": "code",
   "execution_count": 1,
   "id": "55e70ed3-c163-46a2-bb49-64630540509a",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2026-03-17T19:49:31.502657Z",
     "iopub.status.busy": "2026-03-17T19:49:31.502260Z",
     "iopub.status.idle": "2026-03-17T19:49:31.507312Z",
     "shell.execute_reply": "2026-03-17T19:49:31.506518Z",
     "shell.execute_reply.started": "2026-03-17T19:49:31.502609Z"
    }
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "Hello world\n"
     ]
    }
   ],
   "source": [
    "print(\"Hello world\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "7d629de3-f26f-409c-8772-b303fa3bae7b",
   "metadata": {"foo": "bar"},
   "outputs": [],
   "source": []
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python [conda env:base] *",
   "language": "python",
   "name": "conda-base-py"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.13.12"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
JSON
  )
  expected=$(
    cat <<'JSON'
{
 "cells": [
  {
   "cell_type": "code",
   "execution_count": 1,
   "id": "55e70ed3-c163-46a2-bb49-64630540509a",
   "metadata": {},
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "Hello world\n"
     ]
    }
   ],
   "source": [
    "print(\"Hello world\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "7d629de3-f26f-409c-8772-b303fa3bae7b",
   "metadata": {},
   "outputs": [],
   "source": []
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python [conda env:base] *",
   "language": "python",
   "name": "conda-base-py"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.13.12"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
JSON
  )
  echo "$ipynb_content" >"$tmp_file"
  ipynb_cleanmetadata "$tmp_file"
  result=$(cat "$tmp_file")
  rm -f "$tmp_file"
  assertEquals "$expected" "$result"

  # Writing to a separate output file leaves the input unchanged
  local tmp_input tmp_output
  tmp_input="$(mktemp /tmp/test-input-XXXXXX.ipynb)"
  tmp_output="$(mktemp /tmp/test-output-XXXXXX.ipynb)"
  echo "$ipynb_content" >"$tmp_input"
  ipynb_cleanmetadata "$tmp_input" "$tmp_output"
  input_content=$(cat "$tmp_input")
  result=$(cat "$tmp_output")
  rm -f "$tmp_input" "$tmp_output"
  assertEquals "$input_content" "$ipynb_content"
  assertNotEquals "$input_content" "$result"
  assertEquals "$expected" "$result"
}

oneTimeSetUp() {
  . core/helpers/python.sh
}

. scripts/shunit2
