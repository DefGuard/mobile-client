import {
	type CoreApi,
	type EnrollmentFixture,
	type LocationMfaMode,
	loggedInCoreApi,
} from "../helpers/coreApi.js";
import { completeEnrollment } from "../helpers/enrollment.js";
import {
	connectLocation,
	disconnect,
	waitForInstanceScreen,
} from "../helpers/instance.js";
import { expectGatewayReachable, supportsTunnel } from "../helpers/tunnel.js";

describe("mfa connection", () => {
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

	it("connects to an mfa location with a totp code", async () => {
		previousMfaMode = await core.setLocationMfaMode(networkId, "internal");
		fixture = await core.createEnrollmentFixture();

		await completeEnrollment(fixture);
		await waitForInstanceScreen();

		const totpSecret = await core.enableTotp(fixture.username);

		await connectLocation({ totpSecret });
		await expectGatewayReachable();

		await disconnect();
	});
});
