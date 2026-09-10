import { $, expect } from "@wdio/globals";
import { approveBiometricPrompt } from "./biometrics.js";
import type { EnrollmentFixture } from "./coreApi.js";
import { fillField } from "./input.js";
import { byId } from "./selectors.js";

const STEP_SETTLE_MS = 2_000;

interface EnrollmentOptions {
	biometry?: boolean;
}

const openManualForm = async () => {
	await $(byId("add_instance_manual_button")).click();

	const consent = $(byId("data_gathering_accept"));
	await consent.waitForDisplayed();
	await consent.click();

	await expect($(byId("add_instance_form_header"))).toBeDisplayed();
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

export const skipBiometry = async () => {
	const skip = $(byId("skip_biometry"));
	await skip.waitForDisplayed();
	await skip.click();

	const confirm = $(byId("skip_biometry_confirm"));
	await confirm.waitForDisplayed();
	await confirm.click();
	await confirm.waitForExist({ reverse: true });
};

const enableBiometry = async () => {
	await $(byId("biometry_state_ready")).waitForDisplayed({
		timeoutMsg:
			"The device reports no usable biometry, the session failed to provision it",
	});

	const enable = $(byId("enable_biometry"));
	await enable.waitForDisplayed();
	await enable.click();

	const proceed = $(byId("biometry_finish_continue"));
	await approveBiometricPrompt(() =>
		proceed
			.waitForDisplayed({ timeout: STEP_SETTLE_MS })
			.then(() => true)
			.catch(() => false),
	);

	await proceed.click();
};

export const reachBiometryStep = async (fixture: EnrollmentFixture) => {
	await openManualForm();
	await submitInstanceDetails(fixture);
	await nameDevice();
};

export const completeEnrollment = async (
	fixture: EnrollmentFixture,
	options: EnrollmentOptions = {},
) => {
	await reachBiometryStep(fixture);

	if (options.biometry) {
		await enableBiometry();
		return;
	}

	await skipBiometry();
};
