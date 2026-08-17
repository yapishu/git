# `%urgit` development notes

- The source desk is `desk/`; use `zig build -Ddesk=<mounted-desk>` to assemble dependencies and copy it onto a mounted ship desk.
- Keep persisted schemas at `state-0` while this project is greenfield. Change `state-0` in place and nuke/revive agents during development; do not add migrations or compatibility shims.
- Git wire data is binary. Represent it as `octs` (`[length atom]`) across codec boundaries; do not infer lengths with `met` after parsing.
- Object IDs are SHA-1 over canonical Git loose-object bytes: `<type> SP <decimal-size> NUL <content>`. Store canonical content and type, and derive/verify the OID.
- Eyre owns inbound Git Smart HTTP routes. The Gall agent owns repositories, refs, authorization, object validation, and atomic updates. No Git executable or server-side sidecar is part of the design.
- Never advertise a Git capability before its behavior is implemented.
- Rebind `/git` unconditionally in `on-load` so source updates replace stale Eyre bindings.
- Do not create Git commits; repository commits are left to the user.
