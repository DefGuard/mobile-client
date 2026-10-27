import {
	type CoreApi,
	type EnrollmentFixture,
	loggedInCoreApi,
} from "../helpers/coreApi.js";
import { completeEnrollment } from "../helpers/enrollment.js";
import {
	connectWithBiometrics,
	disconnect,
	refreshInstance,
	waitForInstanceScreen,
} from "../helpers/instance.js";
import { expectGatewayReachable, supportsTunnel } from "../helpers/tunnel.js";

describe("biometric mfa", () => {
	let core: CoreApi;
	let networkId: number;
	let previousMfaEnabled: boolean | undefined;
	let fixture: EnrollmentFixture;

	before(function () {
		if (!supportsTunnel()) {
			this.skip();
		}
	});

	beforeEach(async () => {
		core = await loggedInCoreApi();
		networkId = await core.testNetworkId();
	});

	afterEach(async () => {
		if (previousMfaEnabled !== undefined) {
			await core.setLocationMfaEnabled(networkId, previousMfaEnabled);
		}
		if (fixture?.ephemeral) {
			await core.deleteUser(fixture.username);
		}
	});

	it("connects to an mfa location with a fingerprint", async () => {
		previousMfaEnabled = await core.setLocationMfaEnabled(networkId, true);
		fixture = await core.createEnrollmentFixture();

		await completeEnrollment(fixture, { biometry: true });
		await waitForInstanceScreen();
		await refreshInstance(
			await core.startDesktopConfiguration(fixture.username),
		);
		await waitForInstanceScreen();

		await connectWithBiometrics();
		await expectGatewayReachable();

		await disconnect();
	});
});
