import { $, $$, driver } from "@wdio/globals";
import type { EnrollmentFixture } from "./coreApi.js";
import { requireEnv } from "./env.js";
import { submitTotpCode } from "./mfa.js";
import { containsText, tapLowestMatch, textFields } from "./selectors.js";

const MENU_ATTEMPTS = 3;
const ALL_TRAFFIC = "~All traffic";
const PREDEFINED_TRAFFIC = "~Predefined traffic only";
const CONNECT_BUTTON = "~location_connect_button";
const DISCONNECT_BUTTON = "~location_disconnect_button";
const ACTIONS_MENU = "~instance_actions_menu";
const DELETE_MENU_ITEM = "~Delete Instance";
const DELETE_CONFIRMATION = "~Delete instance";

interface ConnectOptions {
	allTraffic?: boolean;
	totpSecret?: string;
}

const tap = async (selector: string, timeout = 15_000) => {
	const element = $(selector);
	await element.waitForDisplayed({ timeout });
	await element.click();
};

const isVisible = async (selector: string) =>
	await $(selector)
		.isDisplayed()
		.catch(() => false);

const tapViaXcuiTest = async (selector: string, timeout = 15_000) => {
	const element = $(selector);
	await element.waitForDisplayed({ timeout });
	await driver.execute("mobile: tapWithNumberOfTaps", {
		elementId: await element.elementId,
		numberOfTaps: 1,
		numberOfTouches: 1,
	});
};

const locationCard = async (timeout: number) => {
	const card = $(containsText(requireEnv("NETWORK_NAME")));
	await card.waitForDisplayed({ timeout });

	const { y } = await card.getLocation();
	const { height } = await card.getSize();
	return { top: y, bottom: y + height };
};

const cardButton = async (selector: string) => {
	const { top, bottom } = await locationCard(5_000);

	for (const button of await $$(selector)) {
		const { y } = await button.getLocation();
		if (y >= top && y <= bottom) {
			return button;
		}
	}

	return undefined;
};

const waitForCardButton = async (
	selector: string,
	timeout: number,
	timeoutMsg = `The ${requireEnv("NETWORK_NAME")} card does not show ${selector}`,
) => {
	let button: WebdriverIO.Element | undefined;

	await driver.waitUntil(
		async () => {
			button = await cardButton(selector);
			return button !== undefined;
		},
		{ timeout, interval: 1_000, timeoutMsg },
	);

	return button as WebdriverIO.Element;
};

const selectTraffic = async (allTraffic: boolean) => {
	const wanted = allTraffic ? ALL_TRAFFIC : PREDEFINED_TRAFFIC;
	const other = allTraffic ? PREDEFINED_TRAFFIC : ALL_TRAFFIC;

	if (await isVisible(other)) {
		await tap(other);
	}

	await $(wanted).waitForDisplayed({ timeout: 15_000 });
};

const openActionsMenu = async () => {
	for (let attempt = 1; attempt <= MENU_ATTEMPTS; attempt++) {
		if (await isVisible(DELETE_MENU_ITEM)) {
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
	await locationCard(30_000);
};

export const connectLocation = async (options: ConnectOptions = {}) => {
	const connect = await waitForCardButton(CONNECT_BUTTON, 45_000);
	await connect.click();

	await $("~Connect VPN").waitForDisplayed({ timeout: 30_000 });
	await selectTraffic(options.allTraffic ?? false);
	await tap("~Connect VPN");

	if (options.totpSecret) {
		await submitTotpCode(options.totpSecret);
	}

	await waitForCardButton(
		DISCONNECT_BUTTON,
		45_000,
		`The ${requireEnv("NETWORK_NAME")} location did not connect`,
	);
};

export const disconnect = async () => {
	const button = await waitForCardButton(DISCONNECT_BUTTON, 30_000);
	await button.click();

	await waitForCardButton(
		CONNECT_BUTTON,
		30_000,
		`The ${requireEnv("NETWORK_NAME")} location did not disconnect`,
	);
};

export const refreshInstance = async (fixture: EnrollmentFixture) => {
	await openActionsMenu();
	await tap("~Refresh configuration");

	await driver.waitUntil(async () => (await textFields().length) >= 2, {
		timeout: 15_000,
		timeoutMsg: "The refresh form did not show the URL and token fields",
	});

	const [url, token] = await textFields();
	await url.setValue(fixture.enrollmentUrl);
	await token.setValue(fixture.enrollmentToken);

	if (await driver.execute("mobile: isKeyboardShown")) {
		await driver.execute("mobile: hideKeyboard", { keys: ["done", "return"] });
	}

	await tap("~Refresh");
	await $("~Locations").waitForDisplayed({
		timeout: 30_000,
		timeoutMsg: "The refresh dialog stayed open, the proxy rejected the token",
	});
};

export const deleteInstance = async () => {
	await openActionsMenu();
	await tap(DELETE_MENU_ITEM);
	await tapLowestMatch(DELETE_CONFIRMATION);
};
