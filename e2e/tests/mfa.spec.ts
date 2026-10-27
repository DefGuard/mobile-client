import {
	type CoreApi,
	type EnrollmentFixture,
	loggedInCoreApi,
} from "../helpers/coreApi.js";
import { completeEnrollment } from "../helpers/enrollment.js";
import {
	connectLocation,
	disconnect,
	refreshInstance,
	waitForInstanceScreen,
} from "../helpers/instance.js";
import { expectGatewayReachable, supportsTunnel } from "../helpers/tunnel.js";

describe("mfa connection", () => {
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

	it("connects to an mfa location with a totp code", async () => {
		previousMfaEnabled = await core.setLocationMfaEnabled(networkId, true);
		fixture = await core.createEnrollmentFixture();

		await completeEnrollment(fixture);
		await waitForInstanceScreen();

		const totpSecret = await core.enableTotp(fixture.username);
		await refreshInstance(
			await core.startDesktopConfiguration(fixture.username),
		);
		await waitForInstanceScreen();

		await connectLocation({ totpSecret });
		await expectGatewayReachable();

		await disconnect();
	});
});
