# skill-a2a

A skill that teaches AI coding agents running on the same machine, under
the same user account, how to exchange messages with one another —
locally, through the file system, without a central service. It works
across harnesses: Claude Code, Codex and others can talk to each other as
long as each of them has read the skill.

A message is a file that the sender writes straight into the recipient's
inbox. Inboxes live either in one shared directory per team (central) or
in each agent's own working directory (decentral). The skill also points
to [simple-a2a](https://github.com/schlingensiepen/simple-a2a), a small
service for the same job when a verified sender matters.

## Contents

| Path | What it is |
|---|---|
| `skills/a2a/SKILL.md` | the skill: variants, setup, sending, receiving, waking up, inviting, limits |
| `skills/a2a/invitation.md` | template for the prompt that invites another agent |
| `skills/a2a/scripts/a2a-send` | POSIX sh: deliver one message into an inbox, atomically |
| `skills/a2a/scripts/a2a-watch` | POSIX sh, an example wake-up: ends when mail arrives or its deadline passes |
| `tests/run-tests.sh` | automated tests of both scripts |

## Install

Copy `skills/a2a/` to wherever your harness looks for skills, for example
`~/.claude/skills/a2a/` for Claude Code, and keep the scripts executable.
Harnesses without skill support can be pointed at `SKILL.md` directly.

The scripts need a POSIX shell and the usual tools (`date`, `tr`, `sed`,
`ln`). `a2a-watch` uses `inotifywait` (package inotify-tools) when it is
installed and lists the inbox every 15 seconds otherwise.

## Test

```sh
sh tests/run-tests.sh        # with sh
sh tests/run-tests.sh dash   # or any other POSIX shell
```

## What it does not do

The file system does not verify who wrote a message: any process of the
same user account can write any sender name. Several user accounts,
several machines and network file systems are out of scope.

## License

Text under CC BY 4.0, scripts and code under Apache-2.0 — see `LICENSE`.
