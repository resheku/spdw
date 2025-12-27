import glob
import json
from collections import Counter, OrderedDict


def heats_count(match_data) -> Counter:
    heat_count = Counter(
        heat["no"] for heat in match_data["heats"] for _ in heat["results"]
    )
    telemetry_count = Counter(
        detail["heat_no"] for tm in match_data["telemetry"] for detail in tm["details"]
    )

    heat_count.subtract(telemetry_count)
    return heat_count


def remove_duplicate_telemetry_details(match_data):
    for telemetry in match_data["telemetry"]:
        unique_details = list(
            OrderedDict(
                (tuple(detail.items()), detail) for detail in telemetry["details"]
            ).values()
        )
        telemetry["details"] = unique_details


def find_telemetry_for_rider(match_data, rider_id, heat):
    rider_telemetry = {tm["general"]["rider_id"]: tm for tm in match_data["telemetry"]}
    if telemetry := rider_telemetry.get(rider_id):
        for detail in reversed(telemetry["details"]):
            if detail["heat_no"] == heat["no"] and "heat_id" not in detail:
                detail["heat_id"] = heat["id"]
                return detail
    return None


def check_for_bad_data(details, match_data, heat_count):
    removed = False
    if all(
        detail["reaction"] == "0.000"
        and detail["distance"] is None
        and detail["time"] is None
        and detail["max_speed"] is None
        and detail["l1_time"] is None
        and detail["l2_time"] is None
        and detail["l3_time"] is None
        and detail["l4_time"] is None
        for detail in details
    ):
        # find and remove matching detail from telemetry
        for detail in details:
            if telemetry := next(
                (
                    tm
                    for tm in match_data["telemetry"]
                    if tm["general"]["rider_id"] == detail["rider_id"]
                ),
                None,
            ):
                for d in reversed(telemetry["details"]):
                    if d["heat_id"] == detail["heat_id"]:
                        if heat_count[detail["heat_no"]] < 0:
                            telemetry["details"].remove(d)
                            removed = True
                        d["reaction"] = None
                        break
        return removed


def process_heat_results(heat, match_data):
    return [
        detail
        for result in heat["results"]
        if (
            detail := find_telemetry_for_rider(
                match_data, result["substitute_id"] or result["rider_id"], heat
            )
        )
    ]


def update_heat_id_in_telemetry(match_data):
    remove_duplicate_telemetry_details(match_data)
    heat_count = heats_count(match_data)
    for heat in reversed(match_data["heats"]):
        details = process_heat_results(heat, match_data)
        if details and check_for_bad_data(details, match_data, heat_count):
            process_heat_results(heat, match_data)

    # Remove telemetry details that don't have a heat_id (unmatched/duplicate data)
    for telemetry in match_data["telemetry"]:
        if discarded := [
            d for d in telemetry["details"] if "heat_id" not in d
        ]:
            rider_id = telemetry["general"]["rider_id"]
            print(f"Discarding {len(discarded)} unmatched telemetry detail(s) for rider {rider_id}:")
            for d in discarded:
                print(f"  {d}")
        telemetry["details"] = [d for d in telemetry["details"] if "heat_id" in d]

    return match_data


if __name__ == "__main__":
    # take input and output path from command line
    import argparse
    import os

    parser = argparse.ArgumentParser(description="Process telemetry data.")
    parser.add_argument(
        "input_path",
        type=str,
        nargs="?",
        default="sel/*/match/json/*.json",
        help="Path to input JSON files (default: sel/*/match/json/*.json)",
    )
    parser.add_argument(
        "output_path",
        type=str,
        nargs="?",
        default=os.path.join(os.getcwd(), "sel/matches.jsonl"),
        help="Path to output JSONL file (default: sel/matches.jsonl)",
    )
    args = parser.parse_args()
    # read all json files in sel/*/match/json/*.json

    data = []

    files = glob.glob(args.input_path)
    for file in files:
        print(file)
        with open(file, "r") as f:
            match_data = json.load(f)
            new_match_data = update_heat_id_in_telemetry(match_data)
            for item in new_match_data["telemetry"]:
                for detail in item["details"]:
                    assert "heat_id" in detail, f"Missing heat_id in detail: {detail}"
                    assert isinstance(detail["heat_id"], int)
            data.append(new_match_data)

    with open(args.output_path, "w") as f:
        for new_match_data in data:
            json.dump(new_match_data, f)
            f.write("\n")
