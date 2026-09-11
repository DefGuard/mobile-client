import { $, expect } from "@wdio/globals";
import { revokeBiometrics } from "../helpers/biometrics.js";
import {
	type CoreApi,
	type EnrollmentFixture,
	loggedInCoreApi,
} from "../helpers/coreApi.js";
import { reachBiometryStep, skipBiometry } from "../helpers/enrollment.js";
import { locationCard, waitForInstanceScreen } from "../helpers/instance.js";
import { byId } from "../helpers/selectors.js";

describe("missing biometry", () => {
	let core: CoreApi;
	let fixture: EnrollmentFixture;

	beforeEach(async () => {
		core = await loggedInCoreApi();
		await revokeBiometrics();
	});

	afterEach(async () => {
		if (fixture?.ephemeral) {
			await core.deleteUser(fixture.username);
		}
	});

	it("reports that the device has no registered biometry", async () => {
		fixture = await core.createEnrollmentFixture();

		await reachBiometryStep(fixture);

		await expect($(byId("biometry_state_not_registered"))).toBeDisplayed();

		await skipBiometry();
		await waitForInstanceScreen();

		await expect($(locationCard())).toBeDisplayed();
	});
});
