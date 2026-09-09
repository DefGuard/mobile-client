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
const TEST_TIMEOUT_MS = 180_000;
const WAIT_FOR_TIMEOUT_MS = 30_000;

export const projectRoot = here;

export const sharedConfig: Partial<WebdriverIO.Config> = {
	hostname: "127.0.0.1",
	port: APPIUM_PORT,
	specs: ["./tests/**/*.spec.ts"],
	maxInstances: 1,

	services: [
		[
			"appium",
			{
				logPath: path.resolve(here, "logs"),
				args: {
					port: APPIUM_PORT,
					address: "127.0.0.1",
					allowInsecure: "uiautomator2:adb_shell",
				},
			},
		],
	],

	reporters: ["spec"],
	mochaOpts: { timeout: TEST_TIMEOUT_MS },
	waitforTimeout: WAIT_FOR_TIMEOUT_MS,
	connectionRetryTimeout: 240_000,

	afterTest: async (test, _context, { passed }) => {
		if (passed) return;
		try {
			console.log(`\n===== element tree after "${test.title}" =====`);
			console.log(await driver.getPageSource());
		} catch (error) {
			console.warn(`Could not fetch the element tree: ${error}`);
		}
	},
};
