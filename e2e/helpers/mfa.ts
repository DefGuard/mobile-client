import { $ } from "@wdio/globals";
import { textFields } from "./selectors.js";
import { totpCode } from "./totp.js";

const CODE_ATTEMPTS = 3;

export const submitTotpCode = async (secret: string) => {
	const submit = $("~Submit");
	await submit.waitForDisplayed({ timeout: 30_000 });

	for (let attempt = 1; attempt <= CODE_ATTEMPTS; attempt++) {
		const [field] = await textFields();
		await field.setValue(totpCode(secret));
		await submit.click();

		const rejected = await submit
			.waitForDisplayed({ timeout: 10_000 })
			.then(() => true)
			.catch(() => false);

		if (!rejected) {
			return;
		}
	}

	throw new Error(
		`The TOTP code was not accepted after ${CODE_ATTEMPTS} attempts`,
	);
};
