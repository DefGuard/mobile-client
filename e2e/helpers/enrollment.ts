import { $, expect } from "@wdio/globals";
import type { EnrollmentFixture } from "./coreApi.js";
import { containsText } from "./selectors.js";

const openManualForm = async () => {
	await $("~Add instance Manually").click();

	const consent = $("~I Understand");
	if (await consent.isDisplayed()) {
		await consent.click();
	}

	await expect($(containsText("Add Instance Manually"))).toBeDisplayed();
};

const submitInstanceDetails = async (fixture: EnrollmentFixture) => {
	await $("~add_instance_url").setValue(fixture.enrollmentUrl);
	await $("~add_instance_token").setValue(fixture.enrollmentToken);
	await $("~add_instance_submit").click();
};

const nameDevice = async () => {
	const submit = $("~device_name_submit");
	await submit.waitForDisplayed({ timeout: 30_000 });
	await submit.click();
};

const skipBiometry = async () => {
	const skip = $("~Skip");
	await skip.waitForDisplayed({ timeout: 30_000 });
	await skip.click();

	const confirm = $("~skip_biometry_confirm");
	await confirm.waitForDisplayed({ timeout: 15_000 });
	await confirm.click();
	await confirm.waitForExist({ timeout: 15_000, reverse: true });
};

export const completeEnrollment = async (fixture: EnrollmentFixture) => {
	await openManualForm();
	await submitInstanceDetails(fixture);
	await nameDevice();
	await skipBiometry();
};
