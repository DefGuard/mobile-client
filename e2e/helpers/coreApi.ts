import { randomBytes } from "node:crypto";
import { requireEnv } from "./env.js";
import { totpCode } from "./totp.js";

const PEER_DISCONNECT_THRESHOLD = 300;

const generatePassword = (): string =>
	`${randomBytes(24).toString("base64url")}aA1!`;

const coreUrl = (): string => requireEnv("CORE_URL");

export interface EnrollmentFixture {
	username: string;
	enrollmentToken: string;
	enrollmentUrl: string;
	ephemeral: boolean;
}

export class CoreApi {
	private cookie = "";

	private async request(
		method: string,
		apiPath: string,
		body?: unknown,
	): Promise<Response> {
		const response = await fetch(`${coreUrl()}${apiPath}`, {
			method,
			redirect: "manual",
			headers: {
				"Content-Type": "application/json",
				...(this.cookie ? { Cookie: this.cookie } : {}),
			},
			body: body !== undefined ? JSON.stringify(body) : undefined,
		});
		if (response.status >= 300 && response.status < 400) {
			throw new Error(
				`Core API ${method} ${apiPath} redirected — check CORE_URL`,
			);
		}
		if (!response.ok) {
			throw new Error(
				`Core API ${method} ${apiPath} failed: ${response.status} ${await response.text()}`,
			);
		}
		return response;
	}

	async login(username?: string, password?: string): Promise<void> {
		const response = await this.request("POST", "/api/v1/auth", {
			username: username ?? process.env.CORE_ADMIN_USER ?? "admin",
			password: password ?? requireEnv("CORE_ADMIN_PASSWORD"),
		});
		const setCookie = response.headers.get("set-cookie");
		if (!setCookie) {
			throw new Error("Core API login did not return a session cookie");
		}
		this.cookie = setCookie.split(";")[0];
	}

	async userExists(username: string): Promise<boolean> {
		const response = await fetch(`${coreUrl()}/api/v1/user/${username}`, {
			redirect: "manual",
			headers: this.cookie ? { Cookie: this.cookie } : {},
		});
		return response.ok;
	}

	async createUser(username: string): Promise<void> {
		await this.request("POST", "/api/v1/user", {
			username,
			first_name: "E2E",
			last_name: "Test",
			email: `${username}@e2e.test`,
			password: generatePassword(),
		});
	}

	async deleteUser(username: string): Promise<void> {
		await this.request("DELETE", `/api/v1/user/${username}`);
	}

	async testNetworkId(): Promise<number> {
		const name = requireEnv("NETWORK_NAME");
		const response = await this.request("GET", "/api/v1/network");
		const networks = (await response.json()) as Array<{
			id: number;
			name: string;
		}>;
		const network = networks.find((candidate) => candidate.name === name);
		if (!network) {
			throw new Error(`The core has no location named ${name}`);
		}
		return network.id;
	}

	async setLocationMfaEnabled(
		networkId: number,
		enabled: boolean,
	): Promise<boolean> {
		const current = (await (
			await this.request("GET", `/api/v1/network/${networkId}`)
		).json()) as Record<string, unknown>;
		const previous = current.mfa_enabled === true;
		if (previous === enabled) {
			return previous;
		}
		const assignedFlows = (
			(await (
				await this.request("GET", `/api/v1/location/${networkId}/mfa-flows`)
			).json()) as Array<{
				id: number;
				is_default: boolean;
				groups: Array<{ id: number }>;
			}>
		).map((flow) => ({
			flow_id: flow.id,
			is_default: flow.is_default,
			group_ids: flow.groups.map((group) => group.id),
		}));
		const firstMfaFlowId = async (): Promise<number> => {
			const [flow] = (await (
				await this.request("GET", "/api/v1/mfa-flow")
			).json()) as Array<{ id: number }>;
			if (!flow) {
				throw new Error("The core has no MFA flow to assign to the location");
			}
			return flow.id;
		};
		const mfaFlows =
			enabled && assignedFlows.length === 0
				? [{ flow_id: await firstMfaFlowId(), is_default: true, group_ids: [] }]
				: assignedFlows;
		const joinList = (value: unknown): string =>
			Array.isArray(value) ? value.join(",") : ((value as string | null) ?? "");
		await this.request("PUT", `/api/v1/network/${networkId}`, {
			name: current.name,
			address: joinList(current.address),
			endpoint: current.endpoint,
			port: current.port,
			allowed_ips: joinList(current.allowed_ips) || null,
			dns: (current.dns as string | null) ?? null,
			mtu: current.mtu,
			fwmark: current.fwmark,
			client_mtu: current.client_mtu ?? null,
			allow_all_groups: current.allow_all_groups,
			allowed_groups: current.allowed_groups ?? [],
			keepalive_interval: current.keepalive_interval,
			peer_disconnect_threshold: PEER_DISCONNECT_THRESHOLD,
			acl_enabled: current.acl_enabled,
			acl_default_allow: current.acl_default_allow,
			allowed_ips_from_acl: current.allowed_ips_from_acl === true,
			mfa_enabled: enabled,
			service_location_mode: current.service_location_mode ?? "disabled",
			posture_checks: current.posture_checks ?? [],
			mfa_flows: mfaFlows,
		});
		return previous;
	}

	async enableTotp(username: string): Promise<string> {
		const password = generatePassword();
		await this.request("PUT", `/api/v1/user/${username}/password`, {
			new_password: password,
		});

		const user = new CoreApi();
		await user.login(username, password);
		const response = await user.request("POST", "/api/v1/auth/totp/init");
		const { secret } = (await response.json()) as { secret: string };
		await user.request("POST", "/api/v1/auth/totp", {
			code: totpCode(secret),
		});
		return secret;
	}

	async startDesktopConfiguration(
		username: string,
		ephemeral = false,
	): Promise<EnrollmentFixture> {
		const response = await this.request(
			"POST",
			`/api/v1/user/${username}/start_desktop`,
			{
				send_enrollment_notification: false,
			},
		);
		const data = (await response.json()) as { enrollment_token: string };
		return {
			username,
			enrollmentToken: data.enrollment_token,
			enrollmentUrl: requireEnv("PROXY_URL"),
			ephemeral,
		};
	}

	async createEnrollmentFixture(): Promise<EnrollmentFixture> {
		const pinned = process.env.TEST_USERNAME;
		const username = pinned ?? `e2e${Math.floor(Math.random() * 1_000_000)}`;
		if (await this.userExists(username)) {
			await this.deleteUser(username);
		}
		await this.createUser(username);
		return this.startDesktopConfiguration(username, !pinned);
	}
}

export const loggedInCoreApi = async (): Promise<CoreApi> => {
	const api = new CoreApi();
	await api.login();
	return api;
};
