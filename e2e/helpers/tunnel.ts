import { driver } from "@wdio/globals";
import { requireEnv } from "./env.js";

export const supportsTunnel = () => driver.isAndroid;

const probeGateway = async () => {
	const target = requireEnv("GATEWAY_VPN_IP");
	const script = `ping -c 1 -W 2 ${target} >/dev/null 2>&1 && echo reachable || echo unreachable`;
	const output = await driver.execute("mobile: shell", {
		command: "sh",
		args: ["-c", `"${script}"`],
		timeout: 15_000,
	});

	const result = String(output).trim();
	if (result !== "reachable" && result !== "unreachable") {
		throw new Error(`The gateway probe returned unexpected output: ${result}`);
	}
	return result === "reachable";
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
