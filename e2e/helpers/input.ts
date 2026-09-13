import { $, driver } from "@wdio/globals";

const typedValue = (field: ReturnType<typeof $>) =>
	driver.isAndroid ? field.getAttribute("text") : field.getValue();

export const fillField = async (selector: string, value: string) => {
	const field = $(selector);
	await field.waitForDisplayed();
	await field.click();
	await field.setValue(value);
	await field.waitUntil(async () => (await typedValue(field)) === value, {
		timeout: 10_000,
		interval: 250,
		timeoutMsg: `The ${selector} field did not accept the typed value`,
	});
};

export const hideKeyboard = async () => {
	if (!(await driver.isKeyboardShown())) {
		return;
	}

	if (driver.isAndroid) {
		await driver.execute("mobile: performEditorAction", { action: "done" });
	} else {
		await driver.execute("mobile: hideKeyboard", { keys: ["done", "return"] });
	}

	await driver
		.waitUntil(async () => !(await driver.isKeyboardShown()), {
			timeout: 5_000,
			interval: 250,
		})
		.catch(() => undefined);
};
