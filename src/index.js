import { readFile } from "node:fs";
import url from "node:url";
import { processSchedules } from "./schedule.js";

const __filename = url.fileURLToPath(import.meta.url);
// Get the filename from command-line arguments
const fileName = process.argv[2];

if (!fileName) {
	console.log("Please provide a file name as an argument.");
	process.exit(1);
}

if (process.argv[1] === __filename) {
	readFile(fileName, "utf8", (err, html) => {
		if (err) {
			console.error("File not found:", fileName);
			process.exit(1);
		}

		const schedules = processSchedules(html);
		for (const schedule of schedules) {
			console.log(JSON.stringify(schedule));
		}
	});
}
