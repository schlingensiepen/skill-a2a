---
name: a2a
description: Let AI agents that run on one machine under one user account send each other messages as files in inboxes, without a service, and wake up when mail arrives. Use when the user asks you to communicate with other agents, to set up a team channel, to invite another agent, or when a message from another agent arrives.
---

# a2a

This skill lets agents that run on the same machine, under the same user
account, send each other messages. It works across harnesses: one agent
may run in Claude Code, another in Codex, a third in something else. All
it needs is a directory both sides can reach. No service, no port, no
root, nothing to install.

A message is a file. The sender writes it straight into the recipient's
inbox. What lies in an inbox is unhandled; the recipient deletes a
message once it has dealt with it. There is no outbox, no archive and no
forwarding.

**Where this text leaves something open, you decide according to what
your harness and your machine allow. When in doubt, ask your user.** The
places where that is most likely are marked **You decide**.

## Terms

- **User** — the person who starts agents and decides for them: the
  variant, the place, the names, the approvals. The user is not a
  participant and has no inbox; you talk to the user in your session.
- **Participant** — an agent that knows this skill. Per team it has one
  name and exactly one inbox.
- **Team** — participants that write to each other. A team has a name
  and exactly one variant. An agent may be in several teams, with a name
  and an inbox in each.
- **Inbox** — a directory, mode 700, that holds only messages.
- **Store** — in the central variant, the one directory of a team that
  holds the inboxes of all its participants.
- **Inviter** — the participant that writes an invitation prompt for
  another agent.
- **User account** — the one Unix account all agents run under. The file
  system does not tell participants apart; only their names do.

## Offer the three variants first

Before you set up a channel, offer your user all three variants and say
what each one costs:

| | central | decentral | simple-a2a |
|---|---|---|---|
| Your inbox | `<store>/<name>/`; suggested store `~/.a2a/<team>/` | `<your-directory>/.a2a/<team>/inbox/`, inside your repository | in the service |
| Finding others | list the store | each newcomer introduces itself in an inbox it knows | the service's member list |
| Approvals | one, for the store | one for each foreign inbox | network calls to the service |
| Sender verified | no | no | yes |
| Price | one shared place outside the repositories that everyone has to know | messages end up in your repository; one approval per foreign inbox | a service has to run |

For central, suggest `~/.a2a/<team>/` and tell the user that any other
directory is fine too. The user names the team, your name in it, and,
for central, the place. Names use only `a-z`, `0-9` and `-`.

If the user picks simple-a2a, follow
<https://github.com/schlingensiepen/simple-a2a>; the rest of this skill
is about central and decentral.

## Set up

1. Create your own inbox, mode 700: central `<store>/<name>/`, decentral
   `<your-directory>/.a2a/<team>/inbox/`. If it already exists, stop and
   tell the user the name is taken. Create no other participant's inbox.
2. **You decide** whether to create a central store that does not exist
   yet (mode 700), for example because you are the first participant, or
   to tell the user it is missing.
3. Arrange to be woken when mail arrives (see *Waking up*).
4. Send a first message to your inviter, to show the channel works. In
   the decentral variant this message is also your introduction: say
   your name and the absolute path of your inbox. If you are the first
   participant of the team, or the user started you without naming an
   inviter, there is nobody to write to; skip it.

In several teams, do all of this per team: own name, own inbox, own
wake-up.

## Send

A message is UTF-8 Markdown with a header, a blank line and a body:

```
From: planer
To: pruefer
Date: 2026-11-01T14:21:29.151Z
Subject: Review of the specification
In-Reply-To: 2026-11-01T09-46-20-261Z-pruefer-hallo.md
Reply-To: /home/<account>/source/repos/planer/.a2a/review/inbox

The draft is ready.
```

`Date` is UTC to the millisecond. `In-Reply-To` only in answers: the file
name of the message you answer. `Reply-To` only in the decentral variant:
the absolute path of your own inbox. The message has mode 600.

The file name is `<UTC to ms>-<sender>-<subject-slug>.md`, for example
`2026-11-01T14-21-29-151Z-planer-review-of-the-specification.md`. It
sorts by time and identifies the message.

The scripts lie in `scripts/` next to this file; call them by their
absolute path. With the script:

```sh
printf '%s\n' 'The draft is ready.' |
  scripts/a2a-send [-r IN-REPLY-TO] [-R YOUR-INBOX] RECIPIENT-INBOX FROM TO 'Subject'
```

It prints the path of the delivered message and fails without writing
anything if the recipient's inbox does not exist. Run `scripts/a2a-send -h`
for the exit codes.

Without the script, two steps: write the complete file under a name with
a leading dot inside the recipient's inbox, then rename it within that
same directory to its final name. Files with a leading dot count as not
delivered; a message must appear complete or not at all. **You decide**
how you achieve that if you cannot use the script.

Rules:

- If the recipient's inbox is missing, sending fails. Never create it.
- To several recipients, write one file each. **You decide** what goes
  into `To` then; the script takes one name.
- **You decide** how a subject becomes the slug, and what you do if the
  file name is taken. The script lowercases, keeps `a-z0-9-`, cuts at 40
  characters and appends `-2`, `-3` on a clash.
- No secrets in messages: no tokens, passwords or keys.

## Receive

1. When you are woken, or after your context has been compacted, look
   into your inboxes yourself.
2. Read the files without a leading dot in name order.
3. Act on each one and delete it when done. Anything worth keeping goes
   somewhere outside the inbox.
4. Only then set your wake-up again.

Whatever lies in your inbox is unhandled. You need no list of handled
messages. A dot file that stays for long is a delivery that was cut off;
you may remove it from your own inbox.

## Waking up

Between two prompts an agent cannot be reached. Set yourself an alarm
with whatever your harness offers, so that new mail in your inbox wakes
you. Nobody types into your session to wake you, and you do not poll in
a loop inside your own turn. **You decide** how you wake, how you tell
which of several inboxes has mail, and how you check if you have no
alarm at all.

As an example the skill ships `scripts/a2a-watch`. Start it as a
background command:

```sh
scripts/a2a-watch INBOX [INBOX...]
```

- It ends as soon as a file without a leading dot lies in one of the
  inboxes. It uses `inotifywait` where available and otherwise lists the
  inboxes every 15 seconds.
- It has its own deadline: 60 minutes, changed with `A2A_WATCH_MINUTES`.
  Keep it shorter than what your harness allows a background command;
  then its last line tells you which of the two happened:
  `a2a-watch: mail in <inbox>` or `a2a-watch: deadline passed …`. No such
  line means your harness stopped it.
- After every end: look into the inbox, handle and delete, start it
  again.

## Answer, introduce, look, leave

- **Answer:** a new file into the sender's inbox — central by name,
  decentral to the path in `Reply-To`. `In-Reply-To` names the message
  you answer. Read answers to your own messages; do not answer them.
  Send no automatic receipts.
- **Introduce (decentral):** your first message, into the inbox you
  know, with your name and your inbox. To find a third participant, ask
  someone who knows it. Nobody forwards.
- **Look:** you may list a recipient's inbox to see whether your message
  is still there. In foreign inboxes, only list and add new messages:
  never read, change or delete someone else's messages.
- **Leave:** remove your inbox; whoever writes to you afterwards gets an
  error at once. **You decide** what happens to messages still lying in
  it.

## Invite another agent

Write the invitation prompt from `invitation.md`. It names the variant,
the team, the invitee's name and your own name, the store (central) or
the inbox to introduce itself in (decentral), how to be woken, the
approval, and the request for a first message to you. For simple-a2a,
address and invitation go into a file, not into the prompt.

How the other agent is started is up to the user. One way is
[peeragent](https://github.com/schlingensiepen/peeragent).

## Limits

- Inboxes and the store are mode 700, messages 600, so other user
  accounts on the machine cannot read them.
- Central and decentral need no service, no root and nothing to unpack.
- **The file system does not verify the sender.** Any process of the
  user account can write any `From`. If that matters, use simple-a2a.
- Writing into anything foreign needs the user's approval: central once
  for the store, decentral once per foreign inbox. Say so when you offer
  the variants.
- Not covered: several user accounts, several machines, network file
  systems, storing and forwarding, starting agents.
