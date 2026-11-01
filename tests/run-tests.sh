#!/bin/sh
# Automated tests for a2a-send and a2a-watch.
#
# Part of the a2a skill. Licensed under the Apache License, Version 2.0;
# see LICENSE-APACHE-2.0 in the repository root.
#
# Usage: sh tests/run-tests.sh [SHELL]
# Runs every case with SHELL (default: sh) as the interpreter of the scripts,
# so the same suite checks dash, bash or any other POSIX shell.

set -u

here=$(cd "$(dirname "$0")" && pwd)
scripts=$(cd "$here/../src/a2a/scripts" 2>/dev/null && pwd) ||
	scripts=$(cd "$here/../skills/a2a/scripts" && pwd)
shell=${1:-sh}
send() { "$shell" "$scripts/a2a-send" "$@"; }
watch() { "$shell" "$scripts/a2a-watch" "$@"; }

work=$(mktemp -d "${TMPDIR:-/tmp}/a2a-tests.XXXXXX")
trap 'rm -rf "$work"' EXIT INT TERM
passed=0 failed=0

check() { # check NAME CONDITION...
	name=$1
	shift
	if "$@"; then
		passed=$((passed + 1))
		printf 'ok   %s\n' "$name"
	else
		failed=$((failed + 1))
		printf 'FAIL %s\n' "$name"
	fi
}

not() { ! "$@"; }

fresh() { # fresh NAME -> path of a new empty inbox
	d="$work/$1"
	mkdir -p "$d" && chmod 700 "$d"
	printf '%s\n' "$d"
}

# A fake date that always prints the same instant, to force name clashes and
# to imitate a date without fractions of a second.
mkdir "$work/fixed-date" "$work/no-ms-date"
cat >"$work/fixed-date/date" <<'EOF'
#!/bin/sh
case "$*" in *%3N*) echo 2026-01-02T03:04:05.678Z ;; *%s*) command -p date "$@" ;; *) echo 2026-01-02T03:04:05 ;; esac
EOF
cat >"$work/no-ms-date/date" <<'EOF'
#!/bin/sh
case "$*" in *%3N*) echo 2026-01-02T03:04:05.NZ ;; *%s*) command -p date "$@" ;; *) echo 2026-01-02T03:04:05 ;; esac
EOF
chmod 755 "$work/fixed-date/date" "$work/no-ms-date/date"

# --- a2a-send ---------------------------------------------------------------

box=$(fresh send-basic)
out=$(printf 'Hello.\n' | send "$box" planer pruefer 'Review the spec'); rc=$?
check 'send: exit 0' [ "$rc" -eq 0 ]
check 'send: prints the delivered path' [ -f "$out" ]
case $(basename "$out") in
[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9]Z-planer-review-the-spec.md) ok=0 ;;
*) ok=1 ;;
esac
check 'send: file name <UTC ms>-<from>-<slug>.md' [ "$ok" -eq 0 ]
check 'send: mode 600' [ -n "$(find "$out" -perm 600)" ]
check 'send: From line' grep -qx 'From: planer' "$out"
check 'send: To line' grep -qx 'To: pruefer' "$out"
check 'send: Date line in UTC ms' grep -Eqx 'Date: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}Z' "$out"
check 'send: Subject line' grep -qx 'Subject: Review the spec' "$out"
check 'send: no In-Reply-To without -r' not grep -q '^In-Reply-To:' "$out"
check 'send: no Reply-To without -R' not grep -q '^Reply-To:' "$out"
check 'send: body after a blank line' [ "$(sed -n '5,$p' "$out")" = "$(printf '\nHello.')" ]
check 'send: no dot file left behind' [ -z "$(find "$box" -name '.*' -type f)" ]

box=$(fresh send-reply)
out=$(printf 'x\n' | send -r 2026-01-01T00-00-00-000Z-pruefer-hi.md -R /srv/repo/.a2a/team/inbox "$box" planer pruefer 'Re: hi')
check 'send: In-Reply-To line' grep -qx 'In-Reply-To: 2026-01-01T00-00-00-000Z-pruefer-hi.md' "$out"
check 'send: Reply-To line' grep -qx 'Reply-To: /srv/repo/.a2a/team/inbox' "$out"

printf 'x\n' | send "$work/nowhere" planer pruefer hi 2>/dev/null
check 'send: missing inbox exits 2' [ $? -eq 2 ]
check 'send: missing inbox is not created' [ ! -e "$work/nowhere" ]

box=$(fresh send-invalid)
printf 'x\n' | send "$box" Planer pruefer hi 2>/dev/null
check 'send: upper-case name exits 1' [ $? -eq 1 ]
printf 'x\n' | send "$box" planer 'prue fer' hi 2>/dev/null
check 'send: name with space exits 1' [ $? -eq 1 ]
printf 'x\n' | send -R relative/inbox "$box" planer pruefer hi 2>/dev/null
check 'send: relative Reply-To exits 1' [ $? -eq 1 ]
printf 'x\n' | send -r ../x.md "$box" planer pruefer hi 2>/dev/null
check 'send: In-Reply-To with a slash exits 1' [ $? -eq 1 ]
printf 'x\n' | send "$box" planer pruefer "$(printf 'two\nlines')" 2>/dev/null
check 'send: two-line subject exits 1' [ $? -eq 1 ]
printf 'x\n' | send "$box" planer pruefer 2>/dev/null
check 'send: missing argument exits 1' [ $? -eq 1 ]
printf 'x\n' | send "$box" planer pruefer "$(printf 'hi\rIn-Reply-To: evil')" 2>/dev/null
check 'send: control character in subject exits 1' [ $? -eq 1 ]
send -h 2>/dev/null
check 'send: -h exits 0' [ $? -eq 0 ]
check 'send: nothing delivered on errors' [ -z "$(ls -A "$box")" ]

box=$(fresh send-slug)
out=$(printf 'x\n' | send "$box" planer pruefer "$(printf '  Hello, World! -- \303\204rger \303\274ber 100 %% ')")
case $(basename "$out") in *-planer-hello-world-rger-ber-100.md) ok=0 ;; *) ok=1 ;; esac
check 'send: subject becomes a [a-z0-9-] slug' [ "$ok" -eq 0 ]
out=$(printf 'x\n' | send "$box" planer pruefer '!!!')
case $(basename "$out") in *-planer-message.md) ok=0 ;; *) ok=1 ;; esac
check 'send: empty slug becomes message' [ "$ok" -eq 0 ]
out=$(printf 'x\n' | send "$box" planer pruefer "$(printf 'a%.0s' 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45)")
slug=${out##*-planer-}
check 'send: slug at most 40 characters' [ "${#slug}" -le 43 ]

box=$(fresh send-clash)
a=$(printf 'one\n' | PATH="$work/fixed-date:$PATH" send "$box" planer pruefer same)
b=$(printf 'two\n' | PATH="$work/fixed-date:$PATH" send "$box" planer pruefer same)
check 'send: first of a clash keeps the plain name' [ "$(basename "$a")" = 2026-01-02T03-04-05-678Z-planer-same.md ]
check 'send: second of a clash gets -2' [ "$(basename "$b")" = 2026-01-02T03-04-05-678Z-planer-same-2.md ]
check 'send: clash does not overwrite' grep -qx one "$a"

box=$(fresh send-no-ms)
out=$(printf 'x\n' | PATH="$work/no-ms-date:$PATH" send "$box" planer pruefer hi)
check 'send: date without ms falls back to .000' grep -qx 'Date: 2026-01-02T03:04:05.000Z' "$out"

# --- a2a-watch --------------------------------------------------------------

export A2A_WATCH_NO_INOTIFY=1 A2A_WATCH_POLL=1

box=$(fresh watch-ready)
printf 'x\n' | send "$box" planer pruefer hi >/dev/null
out=$(A2A_WATCH_SECONDS=5 watch "$box"); rc=$?
check 'watch: mail present exits 0' [ "$rc" -eq 0 ]
check 'watch: last line names the inbox' [ "$out" = "a2a-watch: mail in $box" ]

box=$(fresh watch-dot)
: >"$box/.half-written.tmp"
out=$(A2A_WATCH_SECONDS=1 watch "$box"); rc=$?
check 'watch: dot file is not mail, deadline exits 3' [ "$rc" -eq 3 ]
case $out in 'a2a-watch: deadline passed after '*' s, no mail') ok=0 ;; *) ok=1 ;; esac
check 'watch: deadline has its own last line' [ "$ok" -eq 0 ]

box=$(fresh watch-later)
(sleep 2 && printf 'x\n' | send "$box" planer pruefer later >/dev/null) &
out=$(A2A_WATCH_SECONDS=20 watch "$box"); rc=$?
wait
check 'watch: wakes on mail that arrives later' [ "$rc" -eq 0 ]

a=$(fresh watch-two-a) b=$(fresh watch-two-b)
printf 'x\n' | send "$b" planer pruefer hi >/dev/null
out=$(A2A_WATCH_SECONDS=5 watch "$a" "$b")
check 'watch: names the inbox that has mail' [ "$out" = "a2a-watch: mail in $b" ]

# An inotifywait that never sees an event, the worst case of mail arriving
# before the watches are set: the watcher must still notice within a poll.
mkdir "$work/blind-inotify"
cat >"$work/blind-inotify/inotifywait" <<'END'
#!/bin/sh
while [ $# -gt 0 ]; do [ "$1" = -t ] && { sleep "$2"; exit 2; }; shift; done
exit 1
END
chmod 755 "$work/blind-inotify/inotifywait"
box=$(fresh watch-blind)
(sleep 2 && printf 'x\n' | send "$box" planer pruefer later >/dev/null) &
t0=$(date +%s)
out=$(A2A_WATCH_NO_INOTIFY=0 A2A_WATCH_SECONDS=30 PATH="$work/blind-inotify:$PATH" watch "$box"); rc=$?
t1=$(date +%s)
wait
check 'watch: with inotifywait, a missed event still ends with mail' [ "$rc" -eq 0 ]
check 'watch: with inotifywait, a missed event is found within a poll' [ $((t1 - t0)) -le 6 ]

watch "$work/nowhere" 2>/dev/null
check 'watch: missing inbox exits 2' [ $? -eq 2 ]
A2A_WATCH_MINUTES=soon watch "$a" 2>/dev/null
check 'watch: non-numeric deadline exits 1' [ $? -eq 1 ]
watch 2>/dev/null
check 'watch: no inbox given exits 1' [ $? -eq 1 ]

printf '\n%s passed, %s failed (shell: %s)\n' "$passed" "$failed" "$shell"
[ "$failed" -eq 0 ]
