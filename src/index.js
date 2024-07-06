import { readFile } from "node:fs";
import url from "node:url";
import { processSchedules } from "./schedule.js";
import { getMatchData } from "./match.js";

const __filename = url.fileURLToPath(import.meta.url);
const action = process.argv[2];
const fileName = process.argv[3];

if (!fileName || !action) {
	console.log("Please provide a file name and type (schedule or match) as arguments.");
	process.exit(1);
}

if (!['schedule', 'match'].includes(action)) {
	console.log("Type must be either 'schedule' or 'match'.");
	process.exit(1);
}

if (process.argv[1] === __filename) {
	readFile(fileName, "utf8", (err, html) => {
		if (err) {
			console.error("File not found:", fileName);
			process.exit(1);
		}

		if (action === 'schedule') {
			const schedules = processSchedules(html);
			for (const schedule of schedules) {
				console.log(JSON.stringify(schedule));
			}
		} else if (action === 'match') {
			const result = getMatchData(html);
			if (result) {
				console.log(JSON.stringify(result));
			} else {
				console.error("Match data not found:", fileName);
			}
		}

	});
}
