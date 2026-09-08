import { $$, driver } from "@wdio/globals";

export const textFields = () =>
	$$("-ios class chain:**/XCUIElementTypeTextField");

export const containsText = (text: string) =>
	`-ios predicate string:name CONTAINS "${text}"`;

export const tapLowestMatch = async (selector: string, timeout = 15_000) => {
	await driver.waitUntil(async () => (await $$(selector).length) > 0, {
		timeout,
		interval: 500,
		timeoutMsg: `Element not found: ${selector}`,
	});

	const positions = await $$(selector).map(async (element) => ({
		element,
		y: (await element.getLocation()).y,
	}));
	positions.sort((first, second) => second.y - first.y);

	await positions[0].element.click();
};

export const waitUntilGone = async (selector: string, timeout = 15_000) => {
	await driver.waitUntil(async () => (await $$(selector).length) === 0, {
		timeout,
		interval: 500,
		timeoutMsg: `Element did not disappear: ${selector}`,
	});
};
