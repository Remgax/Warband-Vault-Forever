# Account sync protocol (version 3)

The account SavedVariables store a generated account ID, one peer account ID,
the shared code, sharing preferences and the last successful receive time.
Ephemeral character sessions and transfer buffers are never serialized. Pairing
persists across alts; copying the entire SavedVariables file to another account
would clone its identity and is not a supported pairing method.

Clients join a channel whose name is a SHA256-derived identifier. The raw code
is never sent. Hello, acceptance, session, and transfer messages are authenticated
with HMAC-SHA256 (128-bit truncated tag). The creating account approves the
request before sharing records. Both sides then exchange session-targeted addon
whispers. A new character advertises the same account ID and proves possession
of the code. Retired sessions and old sequence numbers are rejected.

The discovery channel is limited by realm/faction reachability. There is no
Battle.net transport, web service, or encryption. Codes use WoW's PRNG plus
session inputs; hashing does not turn that source into an OS-grade random source.
They are scoped to addon inventory sharing, not suitable as passwords.

Each character is encoded as bounded, typed data. No received text is executed.
Messages are under 251 bytes, throttled to one every 150 ms. Transfers have
windows, acknowledgements, checksums, retries and timeouts. Only approved peers
may send records. Authentication work, buffers, nesting, field sizes, item counts,
recipe counts and total payload size are bounded. Unrecognized fields are dropped.
Item links are rebuilt from numeric IDs and display text removes control codes.

Only local records are exported. A peer cannot replace a local character or an
import owned by another peer. Storage snapshots merge by their original scan
times. Newer bank records survive older deliveries. Character gold/identity use
the last-seen time. Unlink removes imported records locally; it does not erase
the other account's copy. Sharing switches stop future sharing; they do not
remotely revoke data already sent.

Known limitations: one paired account, large records may take minutes, and a
single character record over the size limit requires disabling recipe sharing.
Account IDs and saved pairing codes must survive `/reload` or logout to persist.
Changing computers requires moving SavedVariables for that same account or
pairing again. Two-account transport is covered by simulated clients; a real
two-account game session remains unverified.

Dependencies: Egor Skriptunoff's MIT pure_lua_SHA v12, vendored with its license.
Local changes expose the module through the addon namespace and adapt WoW's
bit API, without modifying hash or HMAC algorithms. Known-answer vectors cover
the portable and WoW-bit code paths.
