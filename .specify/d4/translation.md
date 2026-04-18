[📋 D4 TRANSLATION] — 2026-04-17

Heard:     "fix the biggest problem of tracking which documentation is implemented vs not
            vs deprecated — continuous scans so docs are source of truth, generic so it
            applies to all projects. Also: findings from arch-audit should be done in D4
            mode, and if D4 wasn't enforcing that already, fix D4 in D4 mode."

Intent (1): Every project using otherness should have documentation that continuously
            reflects reality — what is shipped, what is coming, what is no longer relevant
            — through a periodic automated audit that prevents docs becoming stale.

Intent (2): The D4 system should be self-enforcing for issue-sourced work (not just
            session-start instructions). If ENG can implement an issue without D4 artifacts,
            that gap needs to be closed, through D4.

D4 layer (1): New design doc — docs/design/04-documentation-health.md
D4 layer (2): Extend docs/design/01-declarative-design-driven-development.md §Future

Artifacts:
  (1) docs/design/04-documentation-health.md — new design doc for doc health scan feature
  (2) docs/design/01-*.md §Future — two new 🔲 items for D4 self-enforcement at issue intake

Proceeding after 60s.
