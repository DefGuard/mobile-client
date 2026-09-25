import { $, expect } from "@wdio/globals";
import {
	type CoreApi,
	type EnrollmentFixture,
	loggedInCoreApi,
} from "../helpers/coreApi.js";
import { completeEnrollment } from "../helpers/enrollment.js";
import {
	cardButton,
	locationCard,
	waitForInstanceScreen,
} from "../helpers/instance.js";

describe("instance enrollment", () => {
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

	it("adds an instance manually", async () => {
		fixture = await core.createEnrollmentFixture();

		await completeEnrollment(fixture);
		await waitForInstanceScreen();

		await expect($(locationCard())).toBeDisplayed();
		await expect($(cardButton("location_connect_button"))).toBeDisplayed();
	});
});
