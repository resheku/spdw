import { extractDataFromScript } from "./utils.js";

function getMatchData(html) {
	//javascript find and return object from nested object
	const findObject = (obj, needle) => {
		for (const key in obj) {
			if (key === needle) {
				return obj[key];
			}
			if (typeof obj[key] === "object" && obj[key] !== null) {
				const result = findObject(obj[key], needle);
				if (result) {
					return result;
				}
			}
		}
		return "";
	};
	return findObject(extractDataFromScript(html), "data");
}

export { getMatchData };
