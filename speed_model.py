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
    import statsmodels.formula.api as smf
    import pandas as pd
except ImportError:
    print("statsmodels and pandas are required: pip install statsmodels pandas", file=sys.stderr)
    sys.exit(1)


def load_matches(path: str) -> "pd.DataFrame":
    records = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            match = json.loads(line)
            match_id = match["match"]["id"]
            track_id = str(match["match"]["track_id"])
            track_city = match["match"]["track"]["city"]
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
                        "match_id": match_id,
                        "track_id": track_id,
                        "track_city": track_city,
                        "season": season,
                        "league": league,
                        "rider_id": rider_id,
                        "rider_name": rider_name,
                        "max_speed": spd,
                    })
    return pd.DataFrame(records)


def fit_model(df: "pd.DataFrame") -> "statsmodels.regression.mixed_linear_model.MixedLMResultsWrapper":
    """
    Fit mixed-effects model: max_speed ~ 1, random intercept for track_id.
    Returns fitted model result.
    """
    # Need at least 2 tracks with data
    if df["track_id"].nunique() < 2:
        raise ValueError("Need data from at least 2 different tracks to fit model")

    md = smf.mixedlm("max_speed ~ 1", df, groups=df["track_id"])
    result = md.fit(reml=True, method="lbfgs")
    return result


def summarise_riders(df: "pd.DataFrame", result, min_heats: int = 3) -> list[dict]:
    """
    For each rider, compute:
    - raw average max speed
    - track-adjusted speed (residual from track random effect + grand intercept)
    - number of heats / tracks
    """
    grand_intercept = result.fe_params["Intercept"]
    # Random effects: {track_id: intercept_offset}
    random_effects = {str(k): v["Group"] for k, v in result.random_effects.items()}

    rows = []
    for (rider_id, rider_name), grp in df.groupby(["rider_id", "rider_name"]):
        if len(grp) < min_heats:
            continue
        # Compute track-adjusted speed per observation: speed - track_re
        adjusted = []
        for _, obs in grp.iterrows():
            track_re = random_effects.get(str(obs["track_id"]), 0.0)
            adjusted.append(obs["max_speed"] - track_re)

        avg_adjusted = sum(adjusted) / len(adjusted)
        rows.append({
            "rider_id": rider_id,
            "name": rider_name,
            "heats": len(grp),
            "tracks": int(grp["track_id"].nunique()),
            "avg_raw_speed": round(float(grp["max_speed"].mean()), 3),
            "avg_adjusted_speed": round(avg_adjusted, 3),
            "max_raw_speed": round(float(grp["max_speed"].max()), 3),
        })

    rows.sort(key=lambda x: x["avg_adjusted_speed"], reverse=True)
    for i, r in enumerate(rows):
        r["rank"] = i + 1
    return rows


def main():
    parser = argparse.ArgumentParser(description="Mixed-effects speed model")
    parser.add_argument("input", nargs="?", default="sel/matches.jsonl",
                        help="Path to matches.jsonl (default: sel/matches.jsonl)")
    parser.add_argument("output", nargs="?", default="sel/speed_model.json",
                        help="Output path (default: sel/speed_model.json)")
    parser.add_argument("--min-heats", type=int, default=3,
                        help="Minimum heats for a rider to be included (default: 3)")
    args = parser.parse_args()

    print(f"Loading data from {args.input}...")
    df = load_matches(args.input)
    print(f"  {len(df)} heat observations, {df['rider_id'].nunique()} riders, {df['track_id'].nunique()} tracks")

    if df.empty:
        print("No data found, exiting.")
        sys.exit(1)

    print("Fitting mixed-effects model (max_speed ~ 1 | track_id)...")
    result = fit_model(df)
    print(f"  Grand intercept: {result.fe_params['Intercept']:.3f} km/h")
    print(f"  Log-likelihood: {result.llf:.2f}")

    # Track random effects (track difficulty)
    track_effects = []
    for track_id, re in result.random_effects.items():
        subset = df[df["track_id"] == track_id]
        track_effects.append({
            "track_id": track_id,
            "track_city": subset["track_city"].iloc[0],
            "random_effect": round(float(re["Group"]), 3),
            "observation_count": len(subset),
        })
    track_effects.sort(key=lambda x: x["random_effect"], reverse=True)

    riders = summarise_riders(df, result, min_heats=args.min_heats)

    output = {
        "model": {
            "formula": "max_speed ~ 1 + (1 | track_id)",
            "method": "REML",
            "grand_intercept": round(float(result.fe_params["Intercept"]), 3),
            "log_likelihood": round(float(result.llf), 3),
            "n_observations": len(df),
            "n_riders": df["rider_id"].nunique(),
            "n_tracks": df["track_id"].nunique(),
        },
        "track_effects": track_effects,
        "riders": riders,
    }

    with open(args.output, "w") as f:
        json.dump(output, f, indent=2, ensure_ascii=False)
    print(f"Written to {args.output}")
    print(f"  {len(riders)} riders ranked by track-adjusted speed")


if __name__ == "__main__":
    main()
