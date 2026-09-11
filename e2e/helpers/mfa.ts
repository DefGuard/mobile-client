import { $ } from "@wdio/globals";
import { approveBiometricPrompt } from "./biometrics.js";
import { fillField } from "./input.js";
import { byId } from "./selectors.js";
import { totpCode } from "./totp.js";

const CODE_ATTEMPTS = 3;
const PROBE_TIMEOUT_MS = 1_000;

export const submitTotpCode = async (secret: string) => {
	const submit = $(byId("mfa_code_submit"));
	await submit.waitForDisplayed();

	for (let attempt = 1; attempt <= CODE_ATTEMPTS; attempt++) {
		await fillField(byId("mfa_code_input"), totpCode(secret));
		await submit.click();

		const accepted = await submit
			.waitForDisplayed({ timeout: 20_000, reverse: true })
			.then(() => true)
			.catch(() => false);

		if (accepted) {
			return;
		}
	}

	throw new Error(
		`The TOTP code was not accepted after ${CODE_ATTEMPTS} attempts`,
	);
};

export const submitBiometricProof = async () => {
	const verify = $(byId("mfa_biometric_verify"));
	await verify.waitForDisplayed();
	await verify.click();

	await approveBiometricPrompt(() =>
		$(byId("mfa_biometric_verify"))
			.waitForDisplayed({ timeout: PROBE_TIMEOUT_MS, reverse: true })
			.then(() => true)
			.catch(() => false),
	);
};
