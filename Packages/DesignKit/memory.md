# DesignKit — memory
- 2026-06-23: Created in the design phase. Tokens code-defined (no asset catalog) for easy light/dark
  + cross-platform. watchOS forced to dark (no UIColor dynamic provider) and low elevation.
- Signature element = the rotating ProjectCard (head "Now") + ProjectRow (Up Next), reused on all 3
  platforms — the A/B/C list from the reference kit repurposed as the app's heartbeat.
- Dual neumorphic shadow = two stacked `.shadow` layers (dark down-right, light up-left) on a filled
  rounded rect; skipped on watchOS in favor of a thin accent stroke.
