import { $, expect } from "@wdio/globals";
import {
	type CoreApi,
	type EnrollmentFixture,
	loggedInCoreApi,
} from "../helpers/coreApi.js";
import { completeEnrollment } from "../helpers/enrollment.js";
import { deleteInstance, waitForInstanceScreen } from "../helpers/instance.js";
import { byId } from "../helpers/selectors.js";

describe("instance delete", () => {
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

	it("deletes the instance", async () => {
		fixture = await core.createEnrollmentFixture();

		await completeEnrollment(fixture);
		await waitForInstanceScreen();

		await deleteInstance();
		await expect($(byId("add_instance_screen_header"))).toBeDisplayed();
	});
});
