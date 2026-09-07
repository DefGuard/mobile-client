import { $, expect } from "@wdio/globals";
import {
	type CoreApi,
	type EnrollmentFixture,
	type LocationMfaMode,
	loggedInCoreApi,
} from "../helpers/coreApi.js";
import { completeEnrollment } from "../helpers/enrollment.js";
import {
	connectFirstLocation,
	disconnect,
	waitForInstanceScreen,
} from "../helpers/instance.js";
import { gatewayVpnIp, pingGateway } from "../helpers/tunnel.js";

describe("vpn connection", () => {
	let core: CoreApi;
	let networkId: number;
	let previousMfaMode: LocationMfaMode;
	let fixture: EnrollmentFixture;

	beforeEach(async () => {
		core = await loggedInCoreApi();
		networkId = (await core.listNetworks())[0].id;
	});

	afterEach(async () => {
		await core.setLocationMfaMode(networkId, previousMfaMode);
		if (fixture?.ephemeral) {
			await core.deleteUser(fixture.username);
		}
	});

	it("connects to a location and reaches the gateway through the tunnel", async () => {
		const gateway = gatewayVpnIp();
		previousMfaMode = await core.setLocationMfaMode(networkId, "disabled");
		fixture = await core.createEnrollmentFixture();

		await completeEnrollment(fixture);
		await waitForInstanceScreen();

		await connectFirstLocation();
		await expect($("~location_disconnect_button")).toBeDisplayed();
		await expect(await pingGateway(gateway)).toBe(true);

		await disconnect();
		await expect($("~location_connect_button")).toBeDisplayed();
		await expect(await pingGateway(gateway)).toBe(false);
	});
});
