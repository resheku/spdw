function extractDataFromScript(html) {
	// Find all script tags using a regular expression
	const scriptTags = html.match(
		/<script>self\.__next_f\.push[\s\S]*?<\/script>/g,
	);

	if (!scriptTags || scriptTags.length === 0) {
		throw new Error("Script tags not found!");
	}

	// Find the script tag that includes "count_attendance"
	const targetScriptTag = scriptTags
		.reverse()
		.find((tag) => tag.includes("count_attendance"));

	if (!targetScriptTag) {
		throw new Error("'count_attendance' not found in script tags!");
	}

	// Extract the script content
	const scriptContent = targetScriptTag.match(
		/<script[^>]*>([\s\S]*?)<\/script>/,
	)[1];

	// Create a mock 'self' object to capture the data pushed to '__next_f'
	const mockSelf = { __next_f: [] };

	// Execute the script content in a safe context
	// sourcery skip: no-new-function
	new Function("self", scriptContent)(mockSelf);

	// Extract the JSON string
	const jsonString = mockSelf.__next_f[0][1];

	if (!jsonString) {
		throw new Error("JSON string not found!");
	}

	// Split the JSON string by newline and parse the first line as JSON
	const jsonStringArray = jsonString.split("\n");
	return JSON.parse(jsonStringArray[0].slice(2));
}

export { extractDataFromScript };
