# otherness

Personal SDLC agent layer. Autonomous multi-agent (or single-session standalone) team
that runs on top of [speckit](https://github.com/github/spec-kit) and the
[MAQA extension](https://github.com/GenieRobot/spec-kit-maqa-ext).

## What's in here

```
agents/
  coordinator.md      continuous coordinator loop
  engineer.md         feature engineer (TDD, PR, merge)
  qa-watcher.md       continuous PR review loop
  scrum-master.md     one-shot SDLC health review per batch
  product-manager.md  one-shot product review per batch
  standalone.md       single session, all roles sequentially
maqa-config-template.yml   copy to project root as maqa-config.yml
```

## Prerequisites

- [speckit](https://github.com/github/spec-kit): `uv tool install specify-cli`
- MAQA extension: `specify extension add maqa`

## New project setup

```bash
# 1. Clone otherness to your machine (once per machine)
git clone git@github.com:rrroizma/otherness.git ~/.otherness

# 2. In your new project repo:
cp ~/.otherness/maqa-config-template.yml maqa-config.yml
# Edit maqa-config.yml: set mode, test_command
# Edit AGENTS.md: set BUILD_COMMAND, TEST_COMMAND, LINT_COMMAND, VULN_COMMAND,
#                      REPORT_ISSUE, PR_LABEL

# 3. Start
# Team mode:       /speckit.maqa.coordinator  (+ /speckit.maqa.feature per engineer + /speckit.maqa.qa)
# Standalone mode: /speckit.maqa.standalone
```

## Updating agents

Push changes to this repo. Every agent self-updates on next startup:
```bash
git -C ~/.otherness pull
```
or just restart any agent session — it pulls automatically.
