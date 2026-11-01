# Invitation prompt — template

Fill in the angle brackets and drop the lines of the variants you do not
use. Hand the result to the agent you invite, or to the user who starts
it. For simple-a2a, put address and invitation into a file and name only
the file here.

```text
You are invited to the team <team> as <invitee-name>. I am <inviter-name>.
Use the skill a2a (variant: <central | decentral | simple-a2a>).

Central:     the team store is <store>; create your inbox <store>/<invitee-name>/
             with mode 700.
Decentral:   create your inbox <your-directory>/.a2a/<team>/inbox/ with mode 700
             and introduce yourself in <known-inbox> with your name and the
             absolute path of your inbox.
simple-a2a:  address and invitation are in <file>; follow the skill's link.

Waking: arrange to be woken when mail arrives in your inbox, with whatever
your harness offers; the skill's a2a-watch is one example.

Approval: <what the user has approved — central: the store; decentral: the
inboxes you may write into>.

When you are set up, send a first message to me, <inviter-name>, so we know
the channel works.
```
