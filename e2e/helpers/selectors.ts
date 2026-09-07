import { $$, driver } from "@wdio/globals";

export const containsText = (text: string) =>
	`-ios predicate string:name CONTAINS "${text}"`;

export const tapLowestMatch = async (selector: string, timeout = 15_000) => {
	await driver.waitUntil(async () => (await $$(selector).length) > 0, {
		timeout,
		interval: 500,
		timeoutMsg: `Element not found: ${selector}`,
	});

	const elements = [...(await $$(selector))];
	let target = elements[0];
	let lowest = (await target.getLocation()).y;

	for (const element of elements.slice(1)) {
		const { y } = await element.getLocation();
		if (y > lowest) {
			lowest = y;
			target = element;
		}
	}

	await target.click();
};

export const waitUntilGone = async (selector: string, timeout = 15_000) => {
	await driver.waitUntil(async () => (await $$(selector).length) === 0, {
		timeout,
		interval: 500,
		timeoutMsg: `Element did not disappear: ${selector}`,
	});
};
