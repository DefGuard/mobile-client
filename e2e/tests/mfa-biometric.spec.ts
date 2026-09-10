import {
	type CoreApi,
	type EnrollmentFixture,
	type LocationMfaMode,
	loggedInCoreApi,
} from "../helpers/coreApi.js";
import { completeEnrollment } from "../helpers/enrollment.js";
import {
	connectWithBiometrics,
	disconnect,
	waitForInstanceScreen,
} from "../helpers/instance.js";
import { expectGatewayReachable, supportsTunnel } from "../helpers/tunnel.js";

describe("biometric mfa", () => {
	let core: CoreApi;
	let networkId: number;
	let previousMfaMode: LocationMfaMode | undefined;
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
		if (previousMfaMode) {
			await core.setLocationMfaMode(networkId, previousMfaMode);
		}
		if (fixture?.ephemeral) {
			await core.deleteUser(fixture.username);
		}
	});

	it("connects to an mfa location with a fingerprint", async () => {
		previousMfaMode = await core.setLocationMfaMode(networkId, "internal");
		fixture = await core.createEnrollmentFixture();

		await completeEnrollment(fixture, { biometry: true });
		await waitForInstanceScreen();

		await connectWithBiometrics();
		await expectGatewayReachable();

		await disconnect();
	});
});
