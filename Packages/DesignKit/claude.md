# DesignKit — claude.md
Shared SwiftUI design system for all three apps (Mac/iOS/watchOS). The single source of the
neumorphic-purple look. See repo-root `design.md` for the direction.

## Owns
`Packages/DesignKit/**` only. Pure SwiftUI; no ReminderKit/business logic. Apps depend on both
DesignKit (style) and ReminderKit (logic).

## Key files
- `Theme.swift` — color tokens (light/dark; watchOS always dark), `.rounded` fonts, `cardCornerRadius`.
- `Components.swift` — `NeumorphicSurface` (`.raised()`/`.sunken()`), `AccentButtonStyle` (`.accent`),
  `InitialBadge`, `ProjectRow` (Up Next), `ProjectCard` (the head "Now" card), `screenBackground()`.

## Rules
- Cross-platform: guard watchOS (no UIColor dynamic provider; dial elevation down to a subtle stroke).
- Keep it presentational. Don't import ReminderKit. Don't bake in copy/strings beyond labels.
