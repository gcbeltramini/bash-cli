from pytest import mark
import commands.hello.script as hello_script


@mark.parametrize("a, b, expected", [
    (1, 2, 3),
    (-2, 3, 1),
    (None, 99, None),
    (101, None, None),
    (None, None, None),
])
def test_add(a, b, expected):
    result: int | None = hello_script.add(a, b)
    assert result == expected
