import { $, expect } from "@wdio/globals";
import { containsText } from "../helpers/selectors.js";

describe("smoke", () => {
	it("launches and asks for the data gathering consent", async () => {
		const title = $("~Add instance");
		await title.waitForDisplayed({ timeout: 30_000 });

		await $("~Add instance Manually").click();

		const dialog = $(containsText("Data gathering"));
		await dialog.waitForDisplayed({ timeout: 10_000 });
		await expect(dialog).toBeDisplayed();
	});
});
