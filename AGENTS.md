# AGENTS.md

This file is the instruction sheet for an AI agent that wants to acquire
the a2a capability for itself: install the skill, anchor it in its own
harness, verify it, and know where the limits are. If a user told you
"load the skill from github.com/schlingensiepen/skill-a2a", this is
where you start.

**What you get:** a way to exchange messages with other agents that run
on the same machine under the same user account, in whatever harness
they run. Messages are files in inboxes; there is no service to start.

## 1. Get the repository

```sh
git clone https://github.com/schlingensiepen/skill-a2a.git
```

Without git, download the archive of the latest release from the
repository page and unpack it. Everything you need is in `skills/a2a/`.

## 2. Install the skill into your harness

The skill is the directory `skills/a2a/`: `SKILL.md`, `invitation.md`
and `scripts/`. Copy it as a whole, so the scripts stay next to the text.

- **Claude Code:** copy it to `~/.claude/skills/a2a/` (all projects) or
  to `.claude/skills/a2a/` inside one project.

  ```sh
  mkdir -p ~/.claude/skills
  cp -R skill-a2a/skills/a2a ~/.claude/skills/a2a
  ```

- **Other harnesses:** if your harness has a skill or instruction
  directory, install it there as its documentation describes. If it has
  none, copy the directory to a place you will find again and make sure
  you read `SKILL.md` whenever communication with other agents comes up,
  for example by naming its absolute path in the instruction file your
  harness reads at start.

To update an installed copy, remove the old directory first; otherwise
`cp -R` puts the new one inside it as `a2a/a2a`.

Then make the scripts executable and note their absolute path; the skill
calls them by it:

```sh
chmod 755 ~/.claude/skills/a2a/scripts/a2a-send ~/.claude/skills/a2a/scripts/a2a-watch
```

Ask your user before you install into a directory that applies to all of
their projects.

## 3. Verify

From the cloned repository:

```sh
sh tests/run-tests.sh
```

It ends with `… passed, 0 failed`. The scripts need a POSIX shell and
the usual tools (`date`, `tr`, `sed`, `cut`, `ln`, `sleep`);
`inotifywait` is optional. The tests also use `find` and `mktemp`.

## 4. Use it

Read `SKILL.md` in full before the first use. When your user asks you to
communicate with other agents, it tells you to offer three variants —
central, decentral, or the service simple-a2a — with what each one
costs, and to let the user name the team, your name and the place.

## 5. Know the limits

- Only agents under **one user account on one machine**. Several
  accounts, several machines and network file systems are out of scope.
- **The file system does not verify the sender.** Any process of the
  account can write any name. If that matters, use
  [simple-a2a](https://github.com/schlingensiepen/simple-a2a).
- The skill does not start agents. One way to start them is
  [peeragent](https://github.com/schlingensiepen/peeragent).
- No secrets in messages.
