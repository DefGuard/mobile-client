import { $, driver, expect } from "@wdio/globals";
import type { EnrollmentFixture } from "./coreApi.js";
import { fillField } from "./input.js";
import { byId, containsLabel } from "./selectors.js";

const confirmsBiometrySkip = () => driver.isIOS;

const openManualForm = async () => {
	await $("~Add instance Manually").click();

	const consent = $("~I Understand");
	await consent.waitForDisplayed();
	await consent.click();

	await expect($(containsLabel("Add Instance Manually"))).toBeDisplayed();
};

const submitInstanceDetails = async (fixture: EnrollmentFixture) => {
	await fillField(byId("add_instance_url"), fixture.enrollmentUrl);
	await fillField(byId("add_instance_token"), fixture.enrollmentToken);
	await $(byId("add_instance_submit")).click();
};

const nameDevice = async () => {
	const submit = $(byId("device_name_submit"));
	await submit.waitForDisplayed();
	await submit.click();
};

const skipBiometry = async () => {
	const skip = $("~Skip");
	await skip.waitForDisplayed();
	await skip.click();

	if (!confirmsBiometrySkip()) {
		return;
	}

	const confirm = $(byId("skip_biometry_confirm"));
	await confirm.waitForDisplayed();
	await confirm.click();
	await confirm.waitForExist({ reverse: true });
};

export const completeEnrollment = async (fixture: EnrollmentFixture) => {
	await openManualForm();
	await submitInstanceDetails(fixture);
	await nameDevice();
	await skipBiometry();
};
