# Replace Instance Screen with Next Design

This plan outlines the steps to create a new `NextInstanceScreen` which will replace the current `InstanceScreen` for the `/instance/:id` route. The new screen will use the `NextLocationCard` widget and follow the "Next" design system, while keeping the original `InstanceScreen` intact for reference.

## User Review Required

> [!IMPORTANT]
> The `InstanceScreenRoute` will be updated to point to `NextInstanceScreen`. This means all navigations to `/instance/:id` will now show the new screen. The old `InstanceScreen` remains in the codebase but will no longer be reachable via the standard route.

## Proposed Changes

### Next Instance Screen Component

#### [NEW] [next_instance_screen.dart](file:///G:/work/mobile-client/client/lib/open/screens/instance/next_instance_screen.dart)
- Implement `NextInstanceScreen` as a `HookConsumerWidget`.
- Adapt `_screenDataProvider` and `_ScreenData` from `instance_screen.dart` to provide data for the new screen.
- Business Logic:
    - Watch `_screenDataProvider(id)` for instance and locations data.
    - Watch `pluginActiveTunnelStateProvider` and `wireguardPluginProvider` for connection management.
    - Implement `onConnectTap` and `onDisconnectTap` logic, handling permissions and tunnel operations.
- UI:
    - Basic `Scaffold` with a themed "Next" background.
    - Split locations into two lists: `Connected` and `Available` (not connected).
    - Use `NextLocationCard` to display each location.
    - Include basic instance info (name) in the header.

### Routing

#### [MODIFY] [routes.dart](file:///G:/work/mobile-client/client/lib/router/routes.dart)
- Import `NextInstanceScreen`.
- Update `InstanceScreenRoute` to return `NextInstanceScreen(id: id)` instead of `InstanceScreen(id: id)`.

---

## Verification Plan

### Automated Tests
- N/A (Currently focusing on UI replacement and basic functionality)

### Manual Verification
1.  **Navigation**: Launch the app and navigate to an instance screen. Confirm `NextInstanceScreen` is displayed.
2.  **Data Display**: Verify that the instance name and locations are correctly shown.
3.  **List Splitting**:
    - When no location is connected, all should appear in the "Available" list.
    - When a location is connected, it should move to the "Connected" list.
4.  **Connectivity**:
    - Tap "Connect" on an available location and verify it connects (and moves to the "Connected" list).
    - Tap "Disconnect" on a connected location and verify it disconnects (and moves back to "Available").
    - Verify that connecting to a different location handles the conflict (disconnects the current one first, if implemented in logic).
