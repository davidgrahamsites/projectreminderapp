# ProjectReminderWatch — Context

The Watch is the *main point* of the app. The whole value proposition:
- At a user-set interval, a haptic fires on the wrist.
- Tapping it opens the Watch to a scrollable list of all projects.
- The head project (index 0) is shown prominently on top.
- When the user closes the app, the head rotates to the bottom → next open shows next project.
- Round-robin: every project resurfaces exactly once per full cycle.

## Why haptics use local notifications
watchOS prohibits free-running background timers. `UNTimeIntervalNotificationTrigger(repeats: true)`
is the only reliable cadence mechanism and is validated to work on real hardware.

## Why scenePhase → .background for advance-on-dismiss
`onDisappear` on `RotatingListView` fires when navigating to `SettingsView` (a sub-screen in the
same app), which would incorrectly advance the rotation. `scenePhase → .background` fires only when
the user actually leaves the app (Digital Crown, swipe up, wrist-down), matching the spec's intent.
