import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const here = import.meta.dirname;

const envFile = path.resolve(here, ".env");
if (fs.existsSync(envFile)) {
	process.loadEnvFile(envFile);
}

process.env.APPIUM_HOME ??= path.join(os.homedir(), ".appium");

const APPIUM_PORT = 4723;
const ACCEPT_ALERT_BUTTON =
	'**/XCUIElementTypeButton[`label == "Allow" OR label == "Zezwól"`]';
const TEST_TIMEOUT_MS = 180_000;
const WAIT_FOR_TIMEOUT_MS = 20_000;

const teamId = process.env.APPLE_TEAM_ID;
const bundleId = process.env.IOS_BUNDLE_ID ?? "net.defguard.mobile";
const app = process.env.IOS_APP
	? path.resolve(here, process.env.IOS_APP)
	: undefined;

type PairedDevice = {
	udid: string;
	name: string;
	transport: string;
};

const listPairedDevices = (): PairedDevice[] => {
	const tmp = path.join(os.tmpdir(), `devicectl-${process.pid}.json`);
	const listed = spawnSync("xcrun", [
		"devicectl",
		"list",
		"devices",
		"--json-output",
		tmp,
	]);
	if (listed.status !== 0 || !fs.existsSync(tmp)) return [];

	try {
		const parsed = JSON.parse(fs.readFileSync(tmp, "utf8")) as {
			result?: {
				devices?: Array<{
					hardwareProperties?: { udid?: string };
					connectionProperties?: { transportType?: string };
					deviceProperties?: { name?: string };
				}>;
			};
		};
		return (parsed.result?.devices ?? [])
			.filter((device) => device.hardwareProperties?.udid)
			.map((device) => ({
				udid: device.hardwareProperties?.udid as string,
				name: device.deviceProperties?.name ?? "(unnamed)",
				transport: device.connectionProperties?.transportType ?? "unknown",
			}));
	} finally {
		fs.rmSync(tmp, { force: true });
	}
};

const describeDevices = (devices: PairedDevice[]): string =>
	devices
		.map((device) => `  ${device.name} — ${device.udid} (${device.transport})`)
		.join("\n");

const resolveDeviceUdid = (): string => {
	const devices = listPairedDevices();
	const wired = devices.filter((device) => device.transport !== "localNetwork");
	const preferred = process.env.IOS_UDID;

	if (preferred) {
		const match = devices.find((device) => device.udid === preferred);
		if (!match) {
			throw new Error(
				`IOS_UDID=${preferred} is not paired with this Mac.` +
					(devices.length
						? `\nPaired devices:\n${describeDevices(devices)}`
						: " No devices found."),
			);
		}
		if (match.transport === "localNetwork") {
			throw new Error(
				`${match.name} (${preferred}) is only reachable over the network. ` +
					"Appium requires a cable, check `system_profiler SPUSBDataType`.",
			);
		}
		return preferred;
	}

	if (wired.length === 1) return wired[0].udid;

	if (wired.length === 0) {
		throw new Error(
			"No cabled device found. Connect a phone or set IOS_UDID in .env." +
				(devices.length
					? `\nPaired devices:\n${describeDevices(devices)}`
					: ""),
		);
	}

	throw new Error(
		`${wired.length} devices are cabled, pick one with IOS_UDID in .env:\n` +
			describeDevices(wired),
	);
};

const udid = resolveDeviceUdid();

export const config: WebdriverIO.Config = {
	hostname: "127.0.0.1",
	port: APPIUM_PORT,
	specs: ["./tests/**/*.spec.ts"],
	maxInstances: 1,

	services: [
		[
			"appium",
			{
				logPath: path.resolve(here, "logs"),
				args: { port: APPIUM_PORT, address: "127.0.0.1" },
			},
		],
	],

	capabilities: [
		{
			platformName: "iOS",
			"appium:automationName": "XCUITest",
			"appium:udid": udid,
			...(app ? { "appium:app": app } : { "appium:bundleId": bundleId }),
			"appium:xcodeOrgId": teamId,
			"appium:xcodeSigningId": "Apple Development",
			"appium:updatedWDABundleId": `${bundleId}.WebDriverAgentRunner`,
			"appium:allowProvisioningDeviceRegistration": true,
			"appium:wdaLaunchTimeout": 240_000,
			"appium:fullReset": true,
			"appium:autoAcceptAlerts": true,
		} as WebdriverIO.Capabilities,
	],

	reporters: ["spec"],
	mochaOpts: { timeout: TEST_TIMEOUT_MS },
	waitforTimeout: WAIT_FOR_TIMEOUT_MS,
	connectionRetryTimeout: 240_000,

	onPrepare: async () => {
		if (!teamId) {
			throw new Error("APPLE_TEAM_ID is missing from .env");
		}
		if (app && !fs.existsSync(app)) {
			throw new Error(`Application artifact not found: ${app}`);
		}
	},

	afterTest: async (test, _context, { passed }) => {
		if (passed) return;
		try {
			console.log(`\n===== element tree after "${test.title}" =====`);
			console.log(await driver.getPageSource());
		} catch (error) {
			console.warn(`Could not fetch the element tree: ${error}`);
		}
	},

	before: async () => {
		if (await driver.isLocked()) {
			await driver.unlock();
		}
		await driver.updateSettings({
			acceptAlertButtonSelector: ACCEPT_ALERT_BUTTON,
		});
	},

	after: async () => {
		try {
			await driver.terminateApp(bundleId);
			await driver.removeApp(bundleId);
		} catch (error) {
			console.warn(`Could not remove the application from the phone: ${error}`);
		}
	},
};
