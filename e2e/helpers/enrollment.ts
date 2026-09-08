import { $, driver, expect } from "@wdio/globals";
import type { EnrollmentFixture } from "./coreApi.js";
import {
	containsText,
	tapLowestMatch,
	textFields,
	waitUntilGone,
} from "./selectors.js";

const openManualForm = async () => {
	await $("~Add instance Manually").click();

	const consent = $("~I Understand");
	if (await consent.isDisplayed().catch(() => false)) {
		await consent.click();
	}

	await expect($(containsText("Add Instance Manually"))).toBeDisplayed();
};

const submitInstanceDetails = async (fixture: EnrollmentFixture) => {
	await driver.waitUntil(async () => (await textFields().length) >= 2, {
		timeout: 15_000,
		timeoutMsg: "The form did not show the URL and token fields",
	});

	const [url, token] = await textFields();
	await url.setValue(fixture.enrollmentUrl);
	await token.setValue(fixture.enrollmentToken);

	await $("~Continue").click();
};

const nameDevice = async (deviceName?: string) => {
	const submit = $("~Submit");
	await submit.waitForDisplayed({ timeout: 30_000 });

	if (deviceName) {
		const [field] = await textFields();
		await field.setValue(deviceName);
	}

	await submit.click();
};

const skipBiometry = async () => {
	const skip = $("~Skip");
	await skip.waitForDisplayed({ timeout: 30_000 });
	await skip.click();

	const confirm = "~Skip biometric configuration";
	await tapLowestMatch(confirm);
	await waitUntilGone(confirm);
};

export const completeEnrollment = async (
	fixture: EnrollmentFixture,
	deviceName?: string,
) => {
	await openManualForm();
	await submitInstanceDetails(fixture);
	await nameDevice(deviceName);
	await skipBiometry();
};
