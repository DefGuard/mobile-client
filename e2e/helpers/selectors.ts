import { driver } from "@wdio/globals";

export const byId = (identifier: string) =>
	driver.isAndroid
		? `-android uiautomator:new UiSelector().resourceId("${identifier}")`
		: `~${identifier}`;

export const containsLabel = (text: string) =>
	driver.isAndroid
		? `-android uiautomator:new UiSelector().descriptionContains("${text}")`
		: `-ios predicate string:name CONTAINS "${text}"`;
