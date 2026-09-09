import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { projectRoot, sharedConfig } from "./wdio.shared.conf.js";

const BUNDLE_ID = "net.defguard.mobile";
const APP_BUNDLE = "../client/build/ios/iphonesimulator/Runner.app";

const app = path.resolve(projectRoot, APP_BUNDLE);

type Simulator = {
	udid: string;
	name: string;
	runtime: string;
};

const listSimulators = (scope: "available" | "booted"): Simulator[] => {
	const listed = spawnSync(
		"xcrun",
		["simctl", "list", "devices", scope, "--json"],
		{ encoding: "utf8" },
	);
	if (listed.status !== 0) return [];

	const parsed = JSON.parse(listed.stdout) as {
		devices?: Record<string, Array<{ udid: string; name: string }>>;
	};

	return Object.entries(parsed.devices ?? {}).flatMap(([runtime, devices]) =>
		devices.map((device) => ({
			udid: device.udid,
			name: device.name,
			runtime: runtime.replace("com.apple.CoreSimulator.SimRuntime.", ""),
		})),
	);
};

const describeSimulators = (simulators: Simulator[]): string =>
	simulators
		.map(
			(simulator) =>
				`  ${simulator.name} — ${simulator.runtime} (${simulator.udid})`,
		)
		.join("\n");

const resolveSimulatorUdid = (): string => {
	const simulators = listSimulators("available");
	const preferred = process.env.IOS_SIMULATOR;

	if (!simulators.length) {
		throw new Error(
			"No iOS simulator is available, create one in Xcode > Window > Devices and Simulators",
		);
	}

	if (!preferred) {
		throw new Error(
			`IOS_SIMULATOR is missing from .env, pick one of:\n${describeSimulators(simulators)}`,
		);
	}

	const matches = simulators.filter(
		(simulator) => simulator.name === preferred || simulator.udid === preferred,
	);

	if (matches.length === 0) {
		throw new Error(
			`IOS_SIMULATOR=${preferred} does not exist, pick one of:\n${describeSimulators(simulators)}`,
		);
	}

	if (matches.length > 1) {
		throw new Error(
			`IOS_SIMULATOR=${preferred} matches ${matches.length} simulators, use a udid instead:\n${describeSimulators(matches)}`,
		);
	}

	return matches[0].udid;
};

const assertSimulatorArtifact = () => {
	if (!fs.existsSync(app)) {
		throw new Error(
			`Application artifact not found: ${app}\nRun pnpm build:ios first`,
		);
	}

	const platform = spawnSync(
		"plutil",
		[
			"-extract",
			"DTPlatformName",
			"raw",
			"-o",
			"-",
			path.join(app, "Info.plist"),
		],
		{ encoding: "utf8" },
	);

	if (platform.status !== 0) {
		throw new Error(
			`Could not read DTPlatformName from ${app}: ${platform.stderr.trim()}`,
		);
	}

	const built = platform.stdout.trim();
	if (built !== "iphonesimulator") {
		throw new Error(
			`${app} was built for ${built}, run pnpm build:ios to get a simulator bundle`,
		);
	}
};

const udid = resolveSimulatorUdid();

export const config: WebdriverIO.Config = {
	...sharedConfig,

	capabilities: [
		{
			platformName: "iOS",
			"appium:automationName": "XCUITest",
			"appium:udid": udid,
			"appium:app": app,
			"appium:bundleId": BUNDLE_ID,
			"appium:simulatorStartupTimeout": 300_000,
			"appium:wdaLaunchTimeout": 240_000,
			"appium:autoAcceptAlerts": true,
			"appium:reduceMotion": true,
			"appium:connectHardwareKeyboard": false,
		} as WebdriverIO.Capabilities,
	],

	onPrepare: assertSimulatorArtifact,

	onComplete: () => {
		spawnSync("xcrun", ["simctl", "shutdown", udid]);
		if (listSimulators("booted").length === 0) {
			spawnSync("osascript", ["-e", 'quit app "Simulator"']);
		}
	},
};
