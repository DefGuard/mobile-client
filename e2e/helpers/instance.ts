import { $, driver } from "@wdio/globals";
import type { EnrollmentFixture } from "./coreApi.js";
import { requireEnv } from "./env.js";
import { fillField, hideKeyboard } from "./input.js";
import { submitTotpCode } from "./mfa.js";
import { byId, containsLabel } from "./selectors.js";

const MENU_ATTEMPTS = 3;
const MENU_TIMEOUT_MS = 5_000;
const ALL_TRAFFIC = "~All traffic";
const PREDEFINED_TRAFFIC = "~Predefined traffic only";
const ACTIONS_MENU = "instance_actions_menu";
const REFRESH_ITEM = "instance_actions_refresh";
const DELETE_ITEM = "instance_actions_delete";

interface ConnectOptions {
	allTraffic?: boolean;
	totpSecret?: string;
}

const locationName = () => requireEnv("NETWORK_NAME");

export const locationCard = () => containsLabel(locationName());

export const cardButton = (name: string) => byId(`${name}_${locationName()}`);

const boundsOf = async (selector: string) => {
	const element = $(selector);
	await element.waitForExist();
	const { x, y } = await element.getLocation();
	const { width, height } = await element.getSize();
	return { x, y, width, height };
};

const tap = async (selector: string, frameScale = 1) => {
	const element = $(selector);
	await element.waitForDisplayed();

	if (driver.isAndroid) {
		await element.click();
		return;
	}

	const { x, y, width, height } = await boundsOf(selector);

	await driver
		.action("pointer", { parameters: { pointerType: "touch" } })
		.move({
			x: Math.round((x + width / 2) * frameScale),
			y: Math.round((y + height / 2) * frameScale),
		})
		.down()
		.pause(60)
		.up()
		.perform();
};

const selectTraffic = async (allTraffic: boolean) => {
	const wanted = allTraffic ? ALL_TRAFFIC : PREDEFINED_TRAFFIC;
	const opposite = allTraffic ? PREDEFINED_TRAFFIC : ALL_TRAFFIC;

	if (await $(wanted).isDisplayed()) {
		return;
	}

	await tap(opposite);
	await $(wanted).waitForDisplayed({
		timeoutMsg: `The traffic mode did not switch to ${wanted}`,
	});
};

const tapMenuItem = async (item: string) => {
	const menuButton = byId(ACTIONS_MENU);
	const trueWidth = (await boundsOf(menuButton)).width;

	for (let attempt = 1; attempt <= MENU_ATTEMPTS; attempt++) {
		await tap(menuButton);

		const opened = await $(byId(item))
			.waitForDisplayed({ timeout: MENU_TIMEOUT_MS })
			.then(() => true)
			.catch(() => false);

		if (opened) {
			const shrunkWidth = (await boundsOf(menuButton)).width;
			await tap(byId(item), Math.round(trueWidth / shrunkWidth));
			return;
		}
	}

	throw new Error(
		`The instance actions menu did not open after ${MENU_ATTEMPTS} taps`,
	);
};

export const waitForInstanceScreen = async () => {
	await $("~Locations").waitForDisplayed();
	await $(locationCard()).waitForDisplayed({
		timeoutMsg: `The instance screen does not list the ${locationName()} location`,
	});
};

export const connectLocation = async (options: ConnectOptions = {}) => {
	await tap(cardButton("location_connect_button"));

	await $("~Connect VPN").waitForDisplayed();
	await selectTraffic(options.allTraffic ?? false);
	await tap("~Connect VPN");

	if (options.totpSecret) {
		await submitTotpCode(options.totpSecret);
	}

	await $(cardButton("location_disconnect_button")).waitForDisplayed({
		timeout: 45_000,
		timeoutMsg: `The ${locationName()} location did not connect`,
	});
};

export const disconnect = async () => {
	await tap(cardButton("location_disconnect_button"));
	await $(cardButton("location_connect_button")).waitForDisplayed({
		timeoutMsg: `The ${locationName()} location did not disconnect`,
	});
};

export const refreshInstance = async (fixture: EnrollmentFixture) => {
	await tapMenuItem(REFRESH_ITEM);

	const submit = $(byId("refresh_instance_submit"));
	await submit.waitForDisplayed();

	await fillField(byId("refresh_instance_url"), fixture.enrollmentUrl);
	await fillField(byId("refresh_instance_token"), fixture.enrollmentToken);

	await hideKeyboard();

	await submit.click();
	await submit.waitForDisplayed({
		reverse: true,
		timeoutMsg: "The refresh dialog stayed open, the proxy rejected the token",
	});
};

export const deleteInstance = async () => {
	await tapMenuItem(DELETE_ITEM);
	await tap(byId("delete_instance_confirm"));
};
