import json

import duckdb
import polars as pl
import pytest

from sel_telemetry import update_heat_id_in_telemetry


@pytest.fixture
def match_data(request):
    file_path = request.param
    with open(file_path) as f:
        data = json.load(f)
    return data


def save_test_data(data, file_name):
    with open(file_name, "w") as f:
        json.dump(data, f, indent=4)


expected = match_data


@pytest.mark.parametrize(
    "match_data, expected",
    [
        ("sel/2024/match/json/4852.json", "tests/data/4852.json"),
        ("sel/2023/match/json/3855.json", "tests/data/3855.json"),
        ("sel/2021/match/json/2843.json", "tests/data/2843.json"),
        ("sel/2024/match/json/4804.json", "tests/data/4804.json"),
        ("sel/2024/match/json/5520.json", "tests/data/5520.json"),
        ("sel/2024/match/json/5539.json", "tests/data/5539.json"),
        ("sel2/2025/match/json/6560.json", "tests/data/6560.json"),
    ],
    indirect=True,
)
def test_heats_telemetry(match_data, expected, request):
    new_match_data = update_heat_id_in_telemetry(match_data)

    # save_test_data(
    #     new_match_data["telemetry"], request.keywords.node.callspec.params["expected"]
    # )

    assert new_match_data["telemetry"] == expected


def test_stats_query_2025():
    """Test DuckDB query for Season 2025 stats against expected JSON."""
    # Connect to DuckDB database
    conn = duckdb.connect("sel.db", read_only=True)

    # Execute query and get result as Polars DataFrame
    result_df = conn.execute(
        "SELECT * FROM stats WHERE Season = 2025 and League = 'Polish Speedway Extraleague'"
    ).pl()
    result_dicts = result_df.to_dicts()

    # save_test_data(result_dicts, "tests/data/stats_2025.json")

    # Load expected data from file
    with open("tests/data/stats_2025.json") as f:
        expected_data = json.load(f)

    # Compare
    assert result_dicts == expected_data

    conn.close()
