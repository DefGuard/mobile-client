import { $, driver } from "@wdio/globals";

const PING_TIMEOUT = 30_000;

export const gatewayVpnIp = (): string => {
	const value = process.env.GATEWAY_VPN_IP;
	if (!value) {
		throw new Error("Missing required environment variable GATEWAY_VPN_IP");
	}
	return value;
};

export const pingGateway = async (target: string) => {
	await $("~e2e_ping_target").setValue(target);
	await $("~e2e_ping_button").click();

	await driver.waitUntil(
		async () => (await $("~e2e_ping_result").getText()) !== "pinging",
		{
			timeout: PING_TIMEOUT,
			interval: 1_000,
			timeoutMsg: `The E2E ping tool did not report a result for ${target}`,
		},
	);

	return (await $("~e2e_ping_result").getText()) === "ok";
};
