# Design — Project Reminder (shared look across Mac / iOS / watchOS)

The whole app should feel like one product. Adopt the **overall look** of the reference UI kit
(neumorphic, purple-accented, soft) — NOT every widget in it. Calm, tactile, friendly. The rotating
project list is the hero; everything else stays quiet.

## Aesthetic in one line
Soft neumorphism: off-white raised surfaces in light mode, deep navy-charcoal cards in dark mode, a
single vivid **purple** accent, generous rounding, gentle dual shadows, rounded SF type.

## Color tokens (code-defined, light/dark aware — no asset catalog needed)
| Token | Light | Dark |
|---|---|---|
| `accent` (primary purple) | `#7C3AED` | `#9D6BFF` |
| `accentDeep` | `#5B21B6` | `#7C3AED` |
| `background` | `#ECEDF3` | `#16161E` |
| `surface` (raised card) | `#F1F2F8` | `#23232F` |
| `surfaceSunken` (inset) | `#E4E5EE` | `#1B1B24` |
| `shadowLight` (top-left) | `#FFFFFF` | `#2C2C3A` |
| `shadowDark` (bottom-right) | `#C9CBD8` | `#0C0C12` |
| `textPrimary` | `#2A2A35` | `#ECEDF2` |
| `textSecondary` | `#8A8A99` | `#9A9AAB` |

## Typography
- **Display / titles:** SF Pro **Rounded**, semibold — the rounded face matches the soft surfaces
  (use `.system(..., design: .rounded)`). Big, confident project titles; large numerals for the
  interval (like the "26°" in the kit).
- **Body / rows:** system, regular/medium.
- **Caption / meta:** system, small, `textSecondary`, slightly tracked.

## Shape & elevation
- Corner radius: cards `20`, controls/chips `capsule`, badges `circle`.
- **Raised** surfaces: dual shadow — light shadow up-left, dark shadow down-right (neumorphic).
- **Sunken/inset** for pressed/selected states (invert the shadows).
- Keep shadows soft and low-contrast; never harsh. On **watchOS** dial elevation WAY down (tiny
  screen, OLED black bg) — use subtle borders/fills instead of big shadows; keep the purple accent
  and rounding so it still reads as the same family.

## Signature element (the one memorable thing)
The **rotating project row**: a circular purple-tinted badge with the project's initial, the title
in rounded semibold, a quiet meta line, on a raised pill/card. The current **head** project sits in
a larger, accent-bordered "Now" card; the rest follow as smaller rows ("Up Next"). This is the A/B/C
list from the kit, repurposed as the app's heartbeat. Same component on all three platforms, scaled.

## Components to provide in DesignKit (SwiftUI, cross-platform)
- `Theme` / `Color` tokens + a `.rounded` font helper.
- `NeumorphicSurface` view modifier (`.raised` / `.sunken`).
- `AccentButtonStyle` (capsule, purple fill, soft press).
- `ProjectCard` (the head "Now" card) and `ProjectRow` (Up Next rows).
- `IntervalChip` / picker styling for Settings.
- Honor light/dark via the environment; respect reduce-motion and keyboard focus.

## Copy voice
Plain, encouraging, sentence case. Empty state is an invitation: "No projects yet — add one on your
Mac." Buttons say what they do ("Add project", "Save").
