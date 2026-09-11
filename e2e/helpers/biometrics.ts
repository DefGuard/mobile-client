import { $, $$, driver } from "@wdio/globals";
import { byId } from "./selectors.js";

export const DEVICE_PIN = "1234";

const SETTINGS = "com.android.settings";
const SYSTEM_UI = "com.android.systemui";
const FOOTER_BUTTONS = `//*[@resource-id="${SETTINGS}:id/suc_footer_button_bar"]//*[@clickable="true"]`;
const FINGER_ID = 1;
const ENROLL_STEPS = 20;
const SCAN_INTERVAL_MS = 300;
const PROMPT_TIMEOUT_MS = 20_000;
const ACCEPT_TIMEOUT_MS = 20_000;
const ACCEPT_POLL_MS = 500;
const KEYCODE_ENTER = 66;
const MATCH_ATTEMPTS = 5;
const RELOAD_SECONDS = 1;
const DEVICE_OWNER = 0;

const shell = async (command: string, args: string[]) =>
	String(await driver.execute("mobile: shell", { command, args }));

const countPrints = (dump: string) => {
	const state = dump
		.split("\n")
		.find((line) => line.trimStart().startsWith("{"));

	if (!state) {
		return 0;
	}

	const { prints } = JSON.parse(state) as {
		prints?: { id: number; count: number }[];
	};

	return prints?.find((user) => user.id === DEVICE_OWNER)?.count ?? 0;
};

const fingerprintDump = () => shell("dumpsys", ["fingerprint"]);

const enrolledPrints = async () => countPrints(await fingerprintDump());

export const assertLockCleared = (dump: string) => {
	if (countPrints(dump) > 0) {
		throw new Error(
			"The emulator kept an enrolled fingerprint after its screen lock was cleared",
		);
	}
};

const focusedWindow = async () => {
	const output = await shell("sh", [
		"-c",
		"\"dumpsys window | grep -E 'mCurrentFocus|mFocusedApp'\"",
	]);

	return output.trim().split("\n").join(" | ");
};

const setDevicePin = async () => {
	const output = await shell("sh", [
		"-c",
		`"locksettings set-pin ${DEVICE_PIN}; locksettings set-pin --old ${DEVICE_PIN} ${DEVICE_PIN}"`,
	]);

	if (!output.includes(`Pin set to '${DEVICE_PIN}'`)) {
		throw new Error(
			`The emulator refused to set a device PIN: ${output.trim().split("\n").join(" | ")}`,
		);
	}
};

const enterPinIfAsked = async () => {
	const field = $(byId(`${SETTINGS}:id/password_entry`));

	if (!(await field.isExisting())) {
		return false;
	}

	await field.setValue(DEVICE_PIN);
	await driver.pressKeyCode(KEYCODE_ENTER);
	await driver.pause(SCAN_INTERVAL_MS);

	return true;
};

const forwardButton = async () => {
	const buttons = [...(await $$(FOOTER_BUTTONS))];
	const { width } = await driver.getWindowSize();

	for (const button of buttons) {
		if ((await button.getLocation()).x > width / 2) {
			return button;
		}
	}

	return undefined;
};

const enrollFingerprint = async () => {
	if ((await enrolledPrints()) > 0) {
		return;
	}

	await setDevicePin();
	await shell("am", ["start", "-a", "android.settings.FINGERPRINT_ENROLL"]);

	try {
		for (let step = 1; step <= ENROLL_STEPS; step++) {
			if ((await enrolledPrints()) > 0) {
				return;
			}

			if (await enterPinIfAsked()) {
				continue;
			}

			const forward = await forwardButton();

			if (forward) {
				await forward.click();
				continue;
			}

			await driver.execute("mobile: fingerprint", { fingerprintId: FINGER_ID });
			await driver.pause(SCAN_INTERVAL_MS);
		}

		throw new Error(
			`The fingerprint wizard enrolled no print in ${ENROLL_STEPS} steps, it stopped on ${await focusedWindow()}`,
		);
	} finally {
		await shell("am", ["force-stop", SETTINGS]);
	}
};

const answerFingerprintPrompt = async () => {
	const prompt = $(byId(`${SYSTEM_UI}:id/biometric_prompt_constraint_layout`));

	await prompt.waitForExist({
		timeout: PROMPT_TIMEOUT_MS,
		timeoutMsg: "The system biometric prompt did not open",
	});

	await driver.execute("mobile: fingerprint", { fingerprintId: FINGER_ID });

	await prompt.waitForExist({
		reverse: true,
		timeout: PROMPT_TIMEOUT_MS,
		timeoutMsg: "The system biometric prompt rejected the fingerprint",
	});
};

const removeFingerprint = async () => {
	await shell("sh", ["-c", `"locksettings clear --old ${DEVICE_PIN} || true"`]);

	assertLockCleared(await fingerprintDump());

	await setDevicePin();
};

const reloadCapabilities = () =>
	driver.execute("mobile: backgroundApp", { seconds: RELOAD_SECONDS });

const enrollFaceId = async () => {
	await driver.execute("mobile: enrollBiometric", { isEnabled: true });
	await reloadCapabilities();
};

const matchFaceId = () =>
	driver.execute("mobile: sendBiometricMatch", {
		type: "faceId",
		match: true,
	});

export const resetFaceId = () =>
	driver.execute("mobile: enrollBiometric", { isEnabled: false });

export const prepareBiometrics = () =>
	driver.isAndroid ? enrollFingerprint() : enrollFaceId();

export const revokeBiometrics = async () => {
	if (driver.isAndroid) {
		await removeFingerprint();
	} else {
		await resetFaceId();
	}

	await reloadCapabilities();
};

export const approveBiometricPrompt = async (
	accepted: () => Promise<boolean>,
) => {
	const waitForAccepted = async (timeoutMs = ACCEPT_TIMEOUT_MS) => {
		const deadline = Date.now() + timeoutMs;
		for (;;) {
			try {
				if (await accepted()) {
					return true;
				}
			} catch {
				// Stale / detached element during Flutter rebuild = not settled yet.
			}
			if (Date.now() >= deadline) {
				return false;
			}
			await driver.pause(ACCEPT_POLL_MS);
		}
	};

	if (driver.isAndroid) {
		await answerFingerprintPrompt();

		if (await waitForAccepted()) {
			return;
		}

		throw new Error("The app did not continue past the biometric prompt");
	}

	for (let attempt = 1; attempt <= MATCH_ATTEMPTS; attempt++) {
		await matchFaceId();

		if (await waitForAccepted(ACCEPT_TIMEOUT_MS / MATCH_ATTEMPTS)) {
			return;
		}
	}

	throw new Error(
		`The biometric prompt was not accepted after ${MATCH_ATTEMPTS} matches`,
	);
};
