import { $, expect } from "@wdio/globals";
import {
	type CoreApi,
	type EnrollmentFixture,
	loggedInCoreApi,
} from "../helpers/coreApi.js";
import { completeEnrollment } from "../helpers/enrollment.js";
import { locationCard, waitForInstanceScreen } from "../helpers/instance.js";

describe("biometry enrollment", () => {
	let core: CoreApi;
	let fixture: EnrollmentFixture;

	beforeEach(async () => {
		core = await loggedInCoreApi();
	});

	afterEach(async () => {
		if (fixture?.ephemeral) {
			await core.deleteUser(fixture.username);
		}
	});

	it("registers biometry while adding an instance", async () => {
		fixture = await core.createEnrollmentFixture();

		await completeEnrollment(fixture, { biometry: true });
		await waitForInstanceScreen();

		await expect($(locationCard())).toBeDisplayed();
	});
});
