const fs = require("node:fs");
import { describe, expect, test } from "bun:test";
import { processSchedules } from "./schedule.js";
import { extractDataFromScript } from "./utils.js";

describe("Test extracting schedule", () => {
	const cases = [
		["se2024_new", 4804, 70],
		["se2023", 3816, 70],
		["2se2023", 3890, 68],
		["se2024", 4804, 67],
		["2se2024", 4873, 66],
		["2se2024-2", 4873, 66],
		["2se2024-3", 4873, 66],
	];

	test.each(cases)(
		"Schedule %p should have first event id %p and total events %p",
		async (fileName, firstId, noEvents) => {
			const html = fs.readFileSync(
				`tests/data/schedule/${fileName}.html`,
				"utf8",
			);
			const data = processSchedules(html);
			expect(data).toBeInstanceOf(Object);
			expect(data[0].id).toBe(firstId);
			expect(data.length).toBe(noEvents);
		},
	);

	test("Schedule se.html to throw error", () => {
		expect(processSchedules).toThrowError(
			"undefined is not an object (evaluating 'html.match')",
		);
		expect(() => processSchedules("")).toThrowError("Script tags not found!");
	});

	test("error finding key in script tags", () => {
		const html = fs.readFileSync("tests/data/schedule/schedule_x1.html", "utf8");
		expect(() => processSchedules(html)).toThrowError(
			"'card_type_id' not found in script tags!",
		);
	});

	test("Schedule main page", () => {
		const html = fs.readFileSync("tests/data/schedule/se.html", "utf8");
		const data = extractDataFromScript(html);
		expect(data).toBeInstanceOf(Object);
		const { events } = data[7][3];
		expect(events).toBeInstanceOf(Array);
		expect(events.length).toBe(37);
	});
});
