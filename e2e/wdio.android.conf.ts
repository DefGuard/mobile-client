import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import {
	assertLockCleared,
	DEVICE_PIN,
	prepareBiometrics,
} from "./helpers/biometrics.js";
import { projectRoot, sharedConfig } from "./wdio.shared.conf.js";

const APP_PACKAGE = "net.defguard.mobile";
const APP_ACTIVITY = ".MainActivity";
const APK_PATH = "../client/build/app/outputs/flutter-apk/app-debug.apk";

const resolveSdkRoot = (): string => {
	const candidates = [
		process.env.ANDROID_HOME,
		process.env.ANDROID_SDK_ROOT,
		path.join(os.homedir(), "Library", "Android", "sdk"),
		path.join(os.homedir(), "Android", "Sdk"),
	];
	const found = candidates.find(
		(dir) => dir && fs.existsSync(path.join(dir, "platform-tools", "adb")),
	);
	if (!found) {
		throw new Error(
			"Android SDK not found, set ANDROID_HOME in .env to the directory that contains platform-tools/adb",
		);
	}
	return found;
};

const listAvds = (): string[] => {
	const avdHome = path.join(os.homedir(), ".android", "avd");
	if (!fs.existsSync(avdHome)) return [];
	return fs
		.readdirSync(avdHome)
		.filter((entry) => entry.endsWith(".ini"))
		.map((entry) => entry.replace(/\.ini$/, ""));
};

const resolveAvd = (): string => {
	const avds = listAvds();
	const preferred = process.env.ANDROID_AVD;

	if (preferred) {
		if (!avds.includes(preferred)) {
			throw new Error(
				`ANDROID_AVD=${preferred} does not exist.` +
					(avds.length
						? `\nAvailable virtual devices:\n  ${avds.join("\n  ")}`
						: " No virtual devices found."),
			);
		}
		return preferred;
	}

	if (avds.length === 1) return avds[0];

	if (avds.length === 0) {
		throw new Error(
			"No Android virtual device found, create one with avdmanager or Android Studio",
		);
	}

	throw new Error(
		`${avds.length} virtual devices exist, pick one with ANDROID_AVD in .env:\n  ${avds.join("\n  ")}`,
	);
};

const sdkRoot = resolveSdkRoot();
process.env.ANDROID_HOME = sdkRoot;
process.env.ANDROID_SDK_ROOT = sdkRoot;

const avd = resolveAvd();
const apk = path.resolve(projectRoot, APK_PATH);
const adbPath = path.join(sdkRoot, "platform-tools", "adb");

const adb = (...args: string[]) =>
	spawnSync(adbPath, args, { encoding: "utf8" }).stdout ?? "";

const resetDeviceLock = () => {
	adb("shell", "locksettings", "clear", "--old", DEVICE_PIN);
	adb("shell", "locksettings", "clear");

	assertLockCleared(adb("shell", "dumpsys", "fingerprint"));
};

export const config: WebdriverIO.Config = {
	...sharedConfig,

	capabilities: [
		{
			platformName: "Android",
			"appium:automationName": "UiAutomator2",
			"appium:avd": avd,
			"appium:avdLaunchTimeout": 300_000,
			"appium:avdReadyTimeout": 300_000,
			"appium:app": apk,
			"appium:appPackage": APP_PACKAGE,
			"appium:appActivity": APP_ACTIVITY,
			"appium:autoLaunch": false,
			"appium:unlockType": "pin",
			"appium:unlockKey": DEVICE_PIN,
			"appium:autoGrantPermissions": true,
			"appium:disableWindowAnimation": true,
			"appium:uiautomator2ServerInstallTimeout": 120_000,
			"appium:fullReset": true,
		} as WebdriverIO.Capabilities,
	],

	onPrepare: () => {
		if (!fs.existsSync(apk)) {
			throw new Error(
				`Application artifact not found: ${apk}\nRun pnpm build:android first`,
			);
		}

		resetDeviceLock();
	},

	before: async () => {
		await driver.execute("mobile: changePermissions", {
			permissions: "ACTIVATE_VPN",
			appPackage: APP_PACKAGE,
			target: "appops",
			action: "allow",
		});

		try {
			await prepareBiometrics();
		} finally {
			await driver.execute("mobile: activateApp", { appId: APP_PACKAGE });
		}
	},

	onComplete: resetDeviceLock,
};
