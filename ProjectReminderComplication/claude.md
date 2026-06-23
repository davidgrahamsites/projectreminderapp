# ProjectReminderComplication — claude.md
WidgetKit complication (watchOS app-extension) embedded in ProjectReminderWatch. Shows the current
rotation **head** project on the watch face. Reads `ReminderKit.SharedHeadState` (App-Group snapshot
the watch app keeps current) — it does NOT open the SwiftData store (avoids Widget/actor issues).
Families: accessoryInline, accessoryCircular, accessoryRectangular. Owns `ProjectReminderComplication/**`.
