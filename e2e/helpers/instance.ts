import { $, driver } from "@wdio/globals";
import type { EnrollmentFixture } from "./coreApi.js";
import { requireEnv } from "./env.js";
import { submitTotpCode } from "./mfa.js";
import { containsText } from "./selectors.js";

const MENU_ATTEMPTS = 3;
const ALL_TRAFFIC = "~All traffic";
const PREDEFINED_TRAFFIC = "~Predefined traffic only";
const CONNECT_BUTTON = "location_connect_button";
const DISCONNECT_BUTTON = "location_disconnect_button";
const ACTIONS_MENU = "~instance_actions_menu";
const DELETE_MENU_ITEM = "~Delete Instance";
const DELETE_CONFIRMATION = "~delete_instance_confirm";

interface ConnectOptions {
	allTraffic?: boolean;
	totpSecret?: string;
}

const locationName = () => requireEnv("NETWORK_NAME");

const locationCard = () => containsText(locationName());

const cardButton = (name: string) => `~${name}_${locationName()}`;

const tap = async (selector: string, timeout = 15_000) => {
	const element = $(selector);
	await element.waitForDisplayed({ timeout });
	await element.click();
};

const tapViaXcuiTest = async (selector: string, timeout = 15_000) => {
	const element = $(selector);
	await element.waitForDisplayed({ timeout });
	await driver.execute("mobile: tapWithNumberOfTaps", {
		elementId: await element.elementId,
		numberOfTaps: 1,
		numberOfTouches: 1,
	});
};

const selectTraffic = async (allTraffic: boolean) => {
	const wanted = allTraffic ? ALL_TRAFFIC : PREDEFINED_TRAFFIC;
	const opposite = allTraffic ? PREDEFINED_TRAFFIC : ALL_TRAFFIC;

	if (await $(opposite).isDisplayed()) {
		await tap(opposite);
	}

	await $(wanted).waitForDisplayed({ timeout: 15_000 });
};

const openActionsMenu = async () => {
	for (let attempt = 1; attempt <= MENU_ATTEMPTS; attempt++) {
		if (await $(DELETE_MENU_ITEM).isDisplayed()) {
			return;
		}

		await tapViaXcuiTest(ACTIONS_MENU, 30_000);

		const opened = await $(DELETE_MENU_ITEM)
			.waitForDisplayed({ timeout: 5_000 })
			.then(() => true)
			.catch(() => false);

		if (opened) {
			return;
		}
	}

	throw new Error(
		`The instance actions menu did not open after ${MENU_ATTEMPTS} taps`,
	);
};

export const waitForInstanceScreen = async () => {
	await $("~Locations").waitForDisplayed({ timeout: 30_000 });
	await $(locationCard()).waitForDisplayed({
		timeout: 30_000,
		timeoutMsg: `The instance screen does not list the ${locationName()} location`,
	});
};

export const connectLocation = async (options: ConnectOptions = {}) => {
	await tap(cardButton(CONNECT_BUTTON), 45_000);

	await $("~Connect VPN").waitForDisplayed({ timeout: 30_000 });
	await selectTraffic(options.allTraffic ?? false);
	await tap("~Connect VPN");

	if (options.totpSecret) {
		await submitTotpCode(options.totpSecret);
	}

	await $(cardButton(DISCONNECT_BUTTON)).waitForDisplayed({
		timeout: 45_000,
		timeoutMsg: `The ${locationName()} location did not connect`,
	});
};

export const disconnect = async () => {
	await tap(cardButton(DISCONNECT_BUTTON), 30_000);
	await $(cardButton(CONNECT_BUTTON)).waitForDisplayed({
		timeout: 30_000,
		timeoutMsg: `The ${locationName()} location did not disconnect`,
	});
};

export const refreshInstance = async (fixture: EnrollmentFixture) => {
	await openActionsMenu();
	await tap("~Refresh configuration");

	const submit = $("~refresh_instance_submit");
	await submit.waitForDisplayed({ timeout: 15_000 });

	const url = $("~refresh_instance_url");
	await url.clearValue();
	await url.setValue(fixture.enrollmentUrl);
	await $("~refresh_instance_token").setValue(fixture.enrollmentToken);

	if (await driver.execute("mobile: isKeyboardShown")) {
		await driver.execute("mobile: hideKeyboard", { keys: ["done", "return"] });
	}

	await submit.click();
	await submit.waitForDisplayed({
		timeout: 30_000,
		reverse: true,
		timeoutMsg: "The refresh dialog stayed open, the proxy rejected the token",
	});
};

export const deleteInstance = async () => {
	await openActionsMenu();
	await tap(DELETE_MENU_ITEM);
	await tap(DELETE_CONFIRMATION);
};
