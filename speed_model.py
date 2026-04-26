"""
Mixed-effects speed model (Option 4).
Fits: max_speed ~ 1 + (1 | track_id)
Produces per-rider speed estimates adjusted for track difficulty.
Output: sel/speed_model.json
"""
import argparse
import json
import sys

try:
    import polars as pl
    import statsmodels.formula.api as smf
except ImportError:
    print("polars and statsmodels are required: uv sync", file=sys.stderr)
    sys.exit(1)


def load_matches(path: str) -> pl.DataFrame:
    records = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            match = json.loads(line)
            track_id = str(match["match"]["track_id"])
            track_city = match["match"]["track"]["city"] or track_id
            season = match["match"]["season"]
            league = match["match"].get("match_type", {}).get("shortname", {}).get("en", "")
            for tm in match.get("telemetry", []):
                rider_id = str(tm["general"]["rider_id"])
                rider_name = tm["general"]["name"] + " " + tm["general"]["surname"]
                for detail in tm.get("details", []):
                    spd = detail.get("max_speed")
                    if spd is None:
                        continue
                    try:
                        spd = float(spd)
                    except (TypeError, ValueError):
                        continue
                    if spd <= 0:
                        continue
                    records.append({
                        "track_id": track_id,
                        "track_city": track_city,
                        "season": season,
                        "league": league,
                        "rider_id": rider_id,
                        "rider_name": rider_name,
                        "max_speed": spd,
                    })
    return pl.DataFrame(records)


def fit_model(df: pl.DataFrame):
    """
    Fit mixed-effects model: max_speed ~ 1, random intercept for track_id.
    statsmodels requires a pandas DataFrame — convert only for fitting.
    """
    if df["track_id"].n_unique() < 2:
        raise ValueError("Need data from at least 2 different tracks to fit model")

    pdf = df.select(["max_speed", "track_id"]).to_pandas()
    md = smf.mixedlm("max_speed ~ 1", pdf, groups=pdf["track_id"])
    result = md.fit(reml=True, method="lbfgs")
    return result


def summarise_riders(df: pl.DataFrame, result) -> list[dict]:
    """
    For each rider compute track-adjusted average speed:
      adjusted_speed = speed - track_random_effect
    """
    random_effects = {str(k): float(v["Group"]) for k, v in result.random_effects.items()}

    # Add track random effect column
    df = df.with_columns(
        pl.col("track_id")
        .map_elements(lambda t: random_effects.get(str(t), 0.0), return_dtype=pl.Float64)
        .alias("track_re")
    ).with_columns(
        (pl.col("max_speed") - pl.col("track_re")).alias("adjusted_speed")
    )

    rows = (
        df.group_by(["rider_id", "rider_name"])
        .agg([
            pl.len().alias("heats"),
            pl.col("track_id").n_unique().alias("tracks"),
            pl.col("max_speed").mean().round(3).alias("avg_raw_speed"),
            pl.col("max_speed").max().round(3).alias("max_raw_speed"),
            pl.col("adjusted_speed").mean().round(3).alias("avg_adjusted_speed"),
        ])
        .filter(pl.col("heats") >= 3)
        .sort("avg_adjusted_speed", descending=True)
    )

    result_list = []
    for i, row in enumerate(rows.iter_rows(named=True)):
        result_list.append({
            "rank": i + 1,
            "rider_id": row["rider_id"],
            "name": row["rider_name"],
            "heats": row["heats"],
            "tracks": row["tracks"],
            "avg_raw_speed": row["avg_raw_speed"],
            "avg_adjusted_speed": row["avg_adjusted_speed"],
            "max_raw_speed": row["max_raw_speed"],
        })
    return result_list


def main():
    parser = argparse.ArgumentParser(description="Mixed-effects speed model")
    parser.add_argument("input", nargs="?", default="sel/matches.jsonl")
    parser.add_argument("output", nargs="?", default="sel/speed_model.json")
    args = parser.parse_args()

    print(f"Loading data from {args.input}...")
    df = load_matches(args.input)
    print(f"  {len(df)} observations, {df['rider_id'].n_unique()} riders, {df['track_id'].n_unique()} tracks")

    if df.is_empty():
        print("No data found, exiting.")
        sys.exit(1)

    print("Fitting mixed-effects model (max_speed ~ 1 | track_id)...")
    model_result = fit_model(df)
    print(f"  Grand intercept: {model_result.fe_params['Intercept']:.3f} km/h")
    print(f"  Log-likelihood:  {model_result.llf:.2f}")

    track_effects = []
    for track_id, re in model_result.random_effects.items():
        subset = df.filter(pl.col("track_id") == str(track_id))
        track_effects.append({
            "track_id": str(track_id),
            "track_city": subset["track_city"][0] if len(subset) > 0 else str(track_id),
            "random_effect": round(float(re["Group"]), 3),
            "observation_count": len(subset),
        })
    track_effects.sort(key=lambda x: x["random_effect"], reverse=True)

    riders = summarise_riders(df, model_result)

    output = {
        "model": {
            "formula": "max_speed ~ 1 + (1 | track_id)",
            "method": "REML",
            "grand_intercept": round(float(model_result.fe_params["Intercept"]), 3),
            "log_likelihood": round(float(model_result.llf), 3),
            "n_observations": len(df),
            "n_riders": df["rider_id"].n_unique(),
            "n_tracks": df["track_id"].n_unique(),
        },
        "track_effects": track_effects,
        "riders": riders,
    }

    with open(args.output, "w") as f:
        json.dump(output, f, indent=2, ensure_ascii=False)
    print(f"Written to {args.output} — {len(riders)} riders ranked")


if __name__ == "__main__":
    main()

