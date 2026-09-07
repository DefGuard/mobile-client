import { $, driver } from "@wdio/globals";

const CONNECT_ATTEMPTS = 3;

const tap = async (selector: string, timeout = 15_000) => {
	const element = $(selector);
	await element.waitForDisplayed({ timeout });
	await element.click();
};

const isVisible = async (selector: string) =>
	await $(selector)
		.isDisplayed()
		.catch(() => false);

export const waitForInstanceScreen = async () => {
	await $("~Locations").waitForDisplayed({ timeout: 30_000 });
};

export const connectFirstLocation = async () => {
	for (let attempt = 1; attempt <= CONNECT_ATTEMPTS; attempt++) {
		if (await isVisible("~Connect VPN")) {
			await tap("~Connect VPN", 15_000);
		} else {
			await tap("~location_connect_button", 45_000);
			await tap("~Connect VPN", 30_000);
		}

		try {
			await driver.waitUntil(
				async () => await isVisible("~location_disconnect_button"),
				{ timeout: 45_000, interval: 1_000 },
			);
			return;
		} catch (error) {
			if (attempt === CONNECT_ATTEMPTS) {
				throw new Error(
					`Could not connect after ${CONNECT_ATTEMPTS} attempts: ${error}`,
				);
			}
		}
	}
};

export const disconnect = async () => {
	await tap("~location_disconnect_button");
	await driver.waitUntil(
		async () => $("~location_connect_button").isDisplayed(),
		{
			timeout: 30_000,
			interval: 1_000,
			timeoutMsg: "The location did not return to the disconnected state",
		},
	);
};
