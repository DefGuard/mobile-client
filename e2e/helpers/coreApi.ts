import { randomBytes } from "node:crypto";
import { requireEnv } from "./env.js";
import { totpCode } from "./totp.js";

const MIN_PEER_DISCONNECT_THRESHOLD = 120;

const generatePassword = (): string =>
	`${randomBytes(24).toString("base64url")}aA1!`;

const coreUrl = (): string => requireEnv("CORE_URL");

export type LocationMfaMode = "disabled" | "internal" | "external";

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

	async setLocationMfaMode(
		networkId: number,
		mode: LocationMfaMode,
	): Promise<LocationMfaMode> {
		const current = (await (
			await this.request("GET", `/api/v1/network/${networkId}`)
		).json()) as Record<string, unknown>;
		const previous = current.location_mfa_mode as LocationMfaMode;
		if (previous === mode) {
			return previous;
		}
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
			allow_all_groups: current.allow_all_groups,
			allowed_groups: current.allowed_groups ?? [],
			keepalive_interval: current.keepalive_interval,
			peer_disconnect_threshold: Math.max(
				Number(current.peer_disconnect_threshold ?? 0),
				MIN_PEER_DISCONNECT_THRESHOLD,
			),
			acl_enabled: current.acl_enabled,
			acl_default_allow: current.acl_default_allow,
			location_mfa_mode: mode,
			service_location_mode: current.service_location_mode ?? "disabled",
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

	async startEnrollment(
		username: string,
		ephemeral = false,
	): Promise<EnrollmentFixture> {
		const response = await this.request(
			"POST",
			`/api/v1/user/${username}/start_enrollment`,
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
		return this.startEnrollment(username, !pinned);
	}
}

export const loggedInCoreApi = async (): Promise<CoreApi> => {
	const api = new CoreApi();
	await api.login();
	return api;
};
