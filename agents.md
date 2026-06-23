# Agents — Multi-Agent Build Protocol (the "Karpathy Loop")

This build follows `~/brain/multi-agent-coordination-plan.md`: a shared filesystem contract plus a
read-before / write-after loop and a Monitor watcher, so three agents editing three connected apps
never silently diverge.

## Roles
- **Team Lead** (orchestrator): owns `project.yml` + `shared/SCHEMA.md`, resolves conflicts, spawns
  the team. Did Phase 0 (scaffold + frozen contract).
- **Agent A — Shared Core + Mac:** owns `Packages/ReminderKit/**` and `ProjectReminderMac/**`.
- **Agent B — iOS:** owns `ProjectReminder/**`.
- **Agent C — watchOS:** owns `ProjectReminderWatch/**`.
- **Monitor (read-only):** watches `shared/HANDOFF.md`, writes `shared/STATUS.md` CLEAR/CONFLICT.
  Never edits code.
- **Agent D — Design (final phase):** owns `Packages/DesignKit/**` and the UI/design layer across
  all three apps. Runs AFTER A/B/C are idle (no concurrent owners), so it may edit app view files to
  apply the shared look. Builds the Mac authoring UI (A left it a stub) with DesignKit. Follows
  `design.md`. Does not touch `ReminderKit` logic, `project.yml`, or `SCHEMA.md`.

Disjoint file domains → no two agents edit the same file. Only the Lead touches `project.yml`/`SCHEMA.md`.

## The loop (every agent, every task)
**Before claiming a task**
1. Read `shared/STATUS.md` — if `CONFLICT`, stop and report to the Lead.
2. Read the last 10 entries of `shared/HANDOFF.md`; if any affect your domain, adapt first.

**After every meaningful change**
1. Append a `shared/HANDOFF.md` entry (Changed / Affects / SCHEMA updated / Others must).
2. If you think `SCHEMA.md` must change: do NOT edit it — message the Lead.
3. Run `xcodegen generate` if you added/removed files; build your target to verify.

**Never**: edit `SCHEMA.md` or `project.yml` (A/B/C); claim a new task while STATUS shows CONFLICT;
make a breaking interface change silently.

## Conflict resolution
Monitor flags CONFLICT → all agents pause → Lead reads the conflicting HANDOFF entries → Lead
decides who wins / updates SCHEMA.md → Lead writes a resolution HANDOFF entry → Lead clears STATUS
(`CLEAR: resolved — …`) → agents resume.

## Definition of done (per agent)
- Your target builds (`xcodebuild … build`) and ReminderKit tests stay green.
- Your six module docs exist (`claude.md, context.md, memory.md, restart.md, references.md,
  agents.md`) in your directory.
- Final HANDOFF entry written.

## Contract
The frozen API + ownership map lives in `shared/SCHEMA.md`. Read it before writing any code.
