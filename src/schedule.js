import { extractDataFromScript } from "./utils.js";

function processSchedules(html) {
	const collectEvents = (obj) => {
		return Object.keys(obj).reduce((eventsArray, key) => {
			if (key === "event") {
				eventsArray.push(obj[key]);
			}
			if (typeof obj[key] === "object" && obj[key] !== null) {
				eventsArray.push(...collectEvents(obj[key]));
			}
			return eventsArray;
		}, []);
	};

	return collectEvents(extractDataFromScript(html)).sort((a, b) => a.id - b.id);
}

export { processSchedules };
