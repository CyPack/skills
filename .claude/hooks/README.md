# Claude Code Hooks

This folder contains the Claude Code hook scaffold for this project.

## Managed Layer

- Settings target: `.claude/settings.json`
- Managed hook root: `.claude/hooks/generated`
- Every current official Claude Code hook event has a bash stub in the managed event folder.
- Only events listed in the current plan are wired into the settings file.
- Re-run the scaffold after re-checking the live official Claude Code hook docs.

## Event Map

| Event | Enabled | Async When Enabled | Managed Script | Purpose |
|------|---------|--------------------|----------------|---------|
| `SessionStart` | No | n/a | `.claude/hooks/generated/events/session-start.sh` | Runs when a session begins or resumes. |
| `InstructionsLoaded` | No | n/a | `.claude/hooks/generated/events/instructions-loaded.sh` | Runs when a CLAUDE.md file or .claude/rules markdown file is loaded into context. |
| `UserPromptSubmit` | No | n/a | `.claude/hooks/generated/events/user-prompt-submit.sh` | Runs when the user submits a prompt, before Claude processes it. |
| `PreToolUse` | Yes | false | `.claude/hooks/generated/events/pre-tool-use.sh` | Runs before a tool call executes and can block it. |
| `PermissionRequest` | No | n/a | `.claude/hooks/generated/events/permission-request.sh` | Runs when a permission dialog appears. |
| `PermissionDenied` | No | n/a | `.claude/hooks/generated/events/permission-denied.sh` | Runs when a tool call is denied by the auto mode classifier. |
| `PostToolUse` | Yes | true | `.claude/hooks/generated/events/post-tool-use.sh` | Runs after a tool call succeeds. |
| `PostToolUseFailure` | No | n/a | `.claude/hooks/generated/events/post-tool-use-failure.sh` | Runs after a tool call fails. |
| `Notification` | Yes | true | `.claude/hooks/generated/events/notification.sh` | Runs when Claude Code sends a notification. |
| `SubagentStart` | No | n/a | `.claude/hooks/generated/events/subagent-start.sh` | Runs when a subagent is spawned. |
| `SubagentStop` | No | n/a | `.claude/hooks/generated/events/subagent-stop.sh` | Runs when a subagent finishes. |
| `TaskCreated` | No | n/a | `.claude/hooks/generated/events/task-created.sh` | Runs when a task is being created via TaskCreate. |
| `TaskCompleted` | No | n/a | `.claude/hooks/generated/events/task-completed.sh` | Runs when a task is being marked as completed. |
| `Stop` | Yes | false | `.claude/hooks/generated/events/stop.sh` | Runs when Claude finishes responding. |
| `StopFailure` | No | n/a | `.claude/hooks/generated/events/stop-failure.sh` | Runs when a turn ends because of an API error. |
| `TeammateIdle` | No | n/a | `.claude/hooks/generated/events/teammate-idle.sh` | Runs when an agent-team teammate is about to go idle. |
| `ConfigChange` | No | n/a | `.claude/hooks/generated/events/config-change.sh` | Runs when a configuration file changes during a session. |
| `CwdChanged` | No | n/a | `.claude/hooks/generated/events/cwd-changed.sh` | Runs when the working directory changes. |
| `FileChanged` | No | n/a | `.claude/hooks/generated/events/file-changed.sh` | Runs when a watched file changes on disk. |
| `WorktreeCreate` | No | n/a | `.claude/hooks/generated/events/worktree-create.sh` | Runs when a worktree is being created. |
| `WorktreeRemove` | No | n/a | `.claude/hooks/generated/events/worktree-remove.sh` | Runs when a worktree is being removed. |
| `PreCompact` | No | n/a | `.claude/hooks/generated/events/pre-compact.sh` | Runs before context compaction. |
| `PostCompact` | No | n/a | `.claude/hooks/generated/events/post-compact.sh` | Runs after context compaction completes. |
| `SessionEnd` | No | n/a | `.claude/hooks/generated/events/session-end.sh` | Runs when a session terminates. |
| `Elicitation` | No | n/a | `.claude/hooks/generated/events/elicitation.sh` | Runs when an MCP server requests user input during a tool call. |
| `ElicitationResult` | No | n/a | `.claude/hooks/generated/events/elicitation-result.sh` | Runs after a user responds to an MCP elicitation, before the response is sent back. |

## Notes

- Use sync hooks for blocking gates, permission decisions, and environment changes that must land before the next action.
- Use async hooks for logging, notifications, metrics, and background test or formatting work that should not slow Claude down.
- Keep unrelated custom hooks outside the managed folder if you do not want future scaffold refreshes to replace them.
