import {
	type CoreApi,
	type EnrollmentFixture,
	loggedInCoreApi,
} from "../helpers/coreApi.js";
import { completeEnrollment } from "../helpers/enrollment.js";
import { refreshInstance, waitForInstanceScreen } from "../helpers/instance.js";

describe("instance refresh", () => {
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

	it("refreshes the instance configuration", async () => {
		fixture = await core.createEnrollmentFixture();

		await completeEnrollment(fixture);
		await waitForInstanceScreen();

		await refreshInstance(await core.startEnrollment(fixture.username));
		await waitForInstanceScreen();
	});
});
