import { $, driver } from "@wdio/globals";
import { requireEnv } from "./env.js";

const probeGateway = async () => {
	const target = requireEnv("GATEWAY_VPN_IP");
	const result = $("~e2e_ping_result");

	await $("~e2e_ping_target").setValue(target);
	await $("~e2e_ping_button").click();

	await driver.waitUntil(
		async () => ["ok", "fail"].includes(await result.getText()),
		{
			timeout: 30_000,
			interval: 1_000,
			timeoutMsg: `The E2E ping tool did not report a result for ${target}`,
		},
	);

	return (await result.getText()) === "ok";
};

export const expectGatewayReachable = async () => {
	await driver.waitUntil(probeGateway, {
		timeout: 60_000,
		interval: 1_000,
		timeoutMsg: `The gateway ${requireEnv("GATEWAY_VPN_IP")} is not reachable through the tunnel`,
	});
};

export const expectGatewayUnreachable = async () => {
	if (await probeGateway()) {
		throw new Error(
			`The gateway ${requireEnv("GATEWAY_VPN_IP")} is reachable without the tunnel`,
		);
	}
};
