import { $ } from "@wdio/globals";
import { fillField } from "./input.js";
import { byId } from "./selectors.js";
import { totpCode } from "./totp.js";

const CODE_ATTEMPTS = 3;

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
