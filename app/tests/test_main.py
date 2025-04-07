import pytest
from app.main import hello, add


class TestHello:
    def test_hello_returns_string(self):
        result = hello()
        assert isinstance(result, str)
        assert result == "Hello World"


class TestAdd:
    @pytest.mark.parametrize("a,b,expected", [
        (2, 3, 5),
        (0, 0, 0),
        (-1, 5, 4)
    ])
    def test_add_positive(self, a, b, expected):
        assert add(a, b) == expected

    def test_add_type_error(self):
        with pytest.raises(TypeError):
            add("2", 3)
