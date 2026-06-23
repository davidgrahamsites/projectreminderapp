# Context — the *why*

## The problem
When you juggle many projects, the ones not in front of you fade. Reminders apps nag you with
*tasks*; this app instead **resurfaces the projects themselves**, on the wrist, on a gentle cadence,
so they stay top-of-mind. The act of seeing the project again — not doing a checklist — is the value.

## The core behavior (precise)
- All projects live in one ordered, scrollable list.
- The Watch shows the **head** (top) project most prominently each time the list appears.
- On a repeating interval the Watch fires a **haptic**; tapping opens the list.
- When the list is closed, the shown project moves to the **bottom**, so the next appearance shows
  the next project. Over a full cycle every project resurfaces once, then it repeats. (Round-robin.)

## Why three apps
- **Mac (M1):** comfortable place to set up and edit the project list and the interval.
- **iPhone:** carries the list on the go and is the bridge that relays to the Watch.
- **Watch:** the whole point — ambient, glanceable, haptic resurfacing throughout the day.

## Why local-first sync
You wanted it to work over the **same Wi-Fi or a cable**, without depending on the cloud. So Mac↔
iPhone uses Bonjour/LAN and iPhone↔Watch uses WatchConnectivity. The data layer is structured so
iCloud/CloudKit can be added later (it needs a paid Apple Developer account; we're on a free team).

## Explicitly out of scope (v1)
- No LLM features. ("Suggest next action" is an interesting idea but diverts from the pure
  resurfacing purpose; revisit later.)
- No cloud sync yet, no analytics/history, no attachments.

## Constraints that shaped the design
- **Free personal team:** apps expire weekly; CloudKit unavailable → local-first.
- **watchOS background limits:** no free-running timers → the cadence is delivered via repeating
  local notifications, validated on a real watch.
