const fs = require("node:fs");
import { describe, expect, test } from "bun:test";
import { getMatchData } from "./match";

describe("Test extracting match", () => {
	const cases = [
		["5400.html", 5400, 2024, 18],
		["4906.html", 4906, 2024, 15],
		["5445.html", 5445, 2024, 15],
	];

	test.each(cases)(
		"Match %p should have id %p season %p and total heats %p",
		async (fileName, matchId, season, noHeats) => {
			const html = fs.readFileSync(`tests/data/match/${fileName}`, "utf8");
			const data = getMatchData(html);
			// write to json file
			fs.writeFileSync(
				`tests/data/match/${matchId}.json`,
				JSON.stringify(data, null, 2),
			);
			expect(data).toBeInstanceOf(Object);
			expect(data.match.id).toBe(matchId);
			expect(data.match.season).toBe(season);
			expect(data.heats.length).toBe(noHeats);
		},
	);
});
