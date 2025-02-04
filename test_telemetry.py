import json

import pytest

from telemetry import update_heat_id_in_telemetry


@pytest.fixture
def match_data(request):
    file_path = request.param
    with open(file_path) as f:
        data = json.load(f)
    return data


def save_test_data(telemetry, file_name):
    with open(file_name, "w") as f:
        json.dump(telemetry, f, indent=4)


expected = match_data


@pytest.mark.parametrize(
    "match_data, expected",
    [
        ("data/sel/2024/match/json/4852.json", "tests/data/4852.json"),
        ("data/sel/2023/match/json/3855.json", "tests/data/3855.json"),
        ("data/sel/2021/match/json/2843.json", "tests/data/2843.json"),
        ("data/sel/2024/match/json/4804.json", "tests/data/4804.json"),
        ("data/sel/2024/match/json/5520.json", "tests/data/5520.json"),
        ("data/sel/2024/match/json/5539.json", "tests/data/5539.json"),
    ],
    indirect=True,
)
def test_heats_telemetry(match_data, expected, request):
    new_match_data = update_heat_id_in_telemetry(match_data)

    # save_test_data(
    #     new_match_data["telemetry"], request.keywords.node.callspec.params["expected"]
    # )

    assert new_match_data["telemetry"] == expected


# TODO: import the file to database and run query to compare the data
