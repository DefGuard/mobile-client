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
import {
	expectGatewayReachable,
	expectGatewayUnreachable,
	supportsTunnel,
} from "../helpers/tunnel.js";

describe("vpn connection", () => {
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

	it("connects to a location with predefined and all traffic", async () => {
		previousMfaMode = await core.setLocationMfaMode(networkId, "disabled");
		fixture = await core.createEnrollmentFixture();

		await completeEnrollment(fixture);
		await waitForInstanceScreen();

		await connectLocation();
		await expectGatewayReachable();

		await disconnect();
		await expectGatewayUnreachable();

		await connectLocation({ allTraffic: true });
		await expectGatewayReachable();

		await disconnect();
	});
});
