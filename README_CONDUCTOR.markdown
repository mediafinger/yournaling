# How to work with Conductor

> What I think you need to know:

```
bin/makeme "My feature request with requirements... also read this TODO_XXX.md file" 
```

> What Claude thinks you should know about developing Yournaling with Conductor:

## Implementing a Feature with Conductor

Yournaling uses [Conductor](https://github.com/danielmeppiel/conductor) to run a headless,
multi-agent pipeline that turns a written feature request into reviewed, tested code.
The workflow is defined in [`.conductor/agent_routing.yml`](.conductor/agent_routing.yml)
and is called `multi-model-feature-pipeline`. That file is the source of truth — when this
section and the YAML disagree, the YAML wins.

### The pipeline

```text
feature_request
      │
      ▼
   bouncer ──implement_directly──────────────────────────┐
 (skip planning?)                                        │
      │                                                  │
      │ plan_first                                       │
      ▼                                                  ▼
lead_architect ──► human_approver ──approve──► export ──► software_craftsman ──► software_auditor ──► done
 (plans the work)   (you, at the gate)      (writes the    (TDD implementation)   (security & quality
      ▲                   │                  plan to disk)                          verdict)
      └──── revise ───────┤
                          └──reject──► export ──► workflow cancelled
```

| Agent | Type | Model | Does |
| --- | --- | --- | --- |
| `bouncer` | human gate | default | Asks whether to plan first or go straight to implementation. |
| `lead_architect` | agent | `claude-opus-5` | Explores the codebase and produces a phased implementation plan. |
| `human_approver` | human gate | default | You approve, request a revision, or reject the plan. |
| `export` | script | — | Writes the plan to `implementation_plan_<branch>_<timestamp>.md`. |
| `software_craftsman` | agent | `claude-opus-5` | Writes the failing specs first, then the implementation. |
| `software_auditor` | agent | `claude-opus-5` | Reviews for regressions and security, returns `APPROVED` / `APPROVED_WITH_COMMENTS` / `REJECTED`. |
| `terminate_cancelled` | terminate | — | Ends the run after a rejection. |

There are **two** human gates. `bouncer` runs first and is the cheap escape hatch: if you
already have a plan (say, from an interrupted run), choose *Just implement it already...*
and the expensive `lead_architect` step is skipped entirely. Note that this also skips
`export`, so no plan file is written on that path.

The three reasoning agents override the workflow default and run on
`claude-agent-sdk` / `claude-opus-5`; the gates and the export script use the runtime
default (`openai-agents` / `gemini-3.7-flash`) but never actually call a model.

### Prerequisites

* The Conductor CLI on your `PATH` (this repo is used with `v0.1.33`).
* Credentials for the providers named above.
* Longer runs belong on the shared Mac mini rather than your laptop — see
  [Running Conductor on the remote Mac mini](#running-conductor-on-the-remote-mac-mini).
* Check your environment before the first run:

```bash
conductor doctor
conductor validate .conductor/agent_routing.yml
conductor show     .conductor/agent_routing.yml
```

### Running a feature request

Always work on a feature branch — the exported plan is named after the current branch.

```bash
git switch -c feature-my-new-thing

conductor run .conductor/agent_routing.yml \
  --workspace-instructions \
  --log-file auto \
  -i feature_request="Add a rating system to Insights, see TODOs_IDEAs_CONTEXT/RATING_SYSTEM_IDEA.markdown"
```

For a longer specification, keep it in a file and pass it in:

```bash
conductor run .conductor/agent_routing.yml \
  --workspace-instructions \
  -i feature_request="$(cat TODOs_IDEAs_CONTEXT/RATING_SYSTEM_IDEA.markdown)"
```

Useful flags:

* `--workspace-instructions` — prepends `AGENTS.md` and `CLAUDE.md` to every agent prompt.
  **Use this**, otherwise the agents will not know about `bin/mcp_rake_ci`, the TDD rules,
  or the domain hierarchy.
* `--dry-run` — prints the execution plan without calling a model.
* `--web` / `--web-bg` — real-time dashboard; `--web-bg` returns the URL and detaches.
  Pair with `--web-port <port>` to pin the port instead of letting it auto-select.
* `--log-file auto` — full debug transcript in a temp file.
* `--skip-gates` — ⚠️ auto-selects the **first** option at **every** gate. Here that means
  `plan_first` at `bouncer` *and* `approve` at `human_approver`: an unattended run approves
  its own plan and goes straight to writing code. Never use it on `main`.

### The human gates

`bouncer` asks first:

| Choice | Effect |
| --- | --- |
| `plan_first` | Run `lead_architect` to produce a plan. |
| `implement_directly` | Skip planning *and* export, hand the request straight to `software_craftsman`. |

Then, once `lead_architect` is done, the run parks at `human_approver` and prints the plan:

| Choice | Effect |
| --- | --- |
| `approve` | Export the plan, then hand it to `software_craftsman`. |
| `revise` | Prompts for multi-line feedback and sends the plan back to `lead_architect`. |
| `reject` | Runs `export`, then ends the workflow via `terminate_cancelled`. |

Answer in the terminal, or — when running with `--web` / `--web-bg` — from another shell:

```bash
conductor gate respond --port <dashboard-port> --choice approve
conductor gate respond -p <dashboard-port> -c revise --input "Split phase 2 into two migrations"
```

`gate respond` talks HTTP to the dashboard, so it only works for runs started with
`--web` or `--web-bg`. Over SSH the dashboard listens on the *remote* machine — see
[Answering the gate remotely](#answering-the-gate-remotely).

Revision loops are bounded by the workflow's `max_iterations: 15` and
`timeout_seconds: 1800` — a long back-and-forth can hit the 30 minute wall.

### Artifacts

The `export` step writes the plan to the repository root as:

```text
implementation_plan_<branch-name>_<YYYY-MM-DD_HH-MM-SSZ>.md
```

The branch name is sanitised (anything outside `A-Za-z0-9_.-` becomes `-`) and truncated
to 60 characters. These files are **committed** together with the feature they describe.

⚠️ `reject` also routes through `export`, so a rejected plan is written to disk under the
same name pattern as an approved one. Check `git status` after a rejected run and delete
the file — nothing else distinguishes it from a plan you meant to keep.

### Monitoring and recovery

```bash
conductor status                                   # background workflows
conductor stop                                     # stop running workflows
conductor resume .conductor/agent_routing.yml      # continue from the last checkpoint
conductor checkpoint                               # inspect saved checkpoints
conductor fleet                                    # monitor running workflows
```

If a run dies mid-pipeline, `conductor resume` restarts from the agent that failed with all
earlier agent outputs intact — there is no need to re-plan from scratch.

### After the pipeline

Conductor does not replace the project's verification rules. Before opening a PR:

```bash
bin/mcp_rubocop -A <changed_files>
bin/mcp_rake_ci
```

---

## Running Conductor on the remote Mac mini

Pipeline runs happen on the shared Mac mini, not on a laptop. A run regularly takes more than
half an hour and **parks at a human gate for as long as it takes you to read the plan** — so
it has to survive a closed lid, a Wi-Fi change, or a VPN reset. A plain SSH session does not:
when the connection drops, the shell is hung up and the run dies mid-agent.

**Always start a run inside `tmux`.** If a run does die, `conductor resume` picks up from the
last checkpoint, so you lose one agent rather than the whole pipeline.

### Connecting

Ask @mediafinger for the address and your account, then add the machine to your
`~/.ssh/config` once so you never type it again:

```text
Host macmini
  HostName <mac-mini-address>
  User <your-account>
  IdentityFile ~/.ssh/agent
  AddKeysToAgent yes
  UseKeychain yes
  ServerAliveInterval 30
  ServerAliveCountMax 6
```

`ServerAliveInterval` keeps the connection from being dropped by a NAT or firewall while an
agent is thinking with no output for minutes at a time.

```bash
ssh -G macmini    # check the config parses and resolves as you expect
ssh macmini       # connect
```

Remote Login has to be enabled on the Mac mini itself
(System Settings → General → Sharing → Remote Login).

⚠️ `ssh macmini 'conductor run …'` — a command passed on the SSH command line — runs in a
non-login shell that does **not** have `~/.local/bin` on its `PATH`, so it fails with
*command not found* even though the same command works fine once you are logged in. Log in
first, or use the absolute path.

### Working in tmux

```bash
ssh macmini
tmux new -A -s feature-my-new-thing   # attach if it exists, create it if not
```

| Keys / command | Does |
| --- | --- |
| `Ctrl-b d` | Detach — the run keeps going, you can close the laptop. |
| `tmux ls` | List sessions (yours and everyone else's). |
| `tmux attach -t <name>` | Reattach later, from anywhere. |
| `Ctrl-b c` / `Ctrl-b n` / `Ctrl-b p` | New window / next / previous. |
| `tmux kill-session -t <name>` | Clean up when the feature is done. |

A workable layout is window 0 for the `conductor run`, window 1 for `git` and
`bin/mcp_rake_ci`, window 2 for `conductor status`.

Two small things: don't start tmux inside tmux (`echo $TMUX` tells you where you are), and
because the box has `set -g mouse on`, the scroll wheel scrolls the pane but tmux also owns
text selection — hold <kbd>Option</kbd> while dragging to select for a normal copy.

### Answering the gate remotely

Reattach and answer at the prompt — the run waits for you indefinitely.

If you started the run with `--web` / `--web-bg`, the dashboard listens on the *Mac mini*, so
`http://localhost:<port>` in your own browser will not reach it. Start the run with an
explicit `--web-port <dashboard-port>` so you know what to forward, then either forward it:

```bash
ssh -L 8787:localhost:<dashboard-port> macmini
# then open http://localhost:8787 on your machine
```

…or answer from a second tmux window on the box:

```bash
conductor gate respond -p <dashboard-port> -c approve
```

### Keeping the machine awake

tmux survives a dropped connection, but not the Mac mini going to sleep — that kills the
agent process. For long unattended stretches:

```bash
caffeinate -is conductor run .conductor/agent_routing.yml --workspace-instructions -i feature_request="…"
```

`-i` prevents idle sleep and `-s` prevents system sleep; note that `-s` only takes effect
while the machine is on AC power.

### Sharing the machine

* Work in **your own clone** (or a `git worktree`). Two people sharing one checkout will fight
  over the current branch, and the exported plan is named after whatever branch is checked out
  at that moment — an easy way to commit a plan under the wrong feature name.
* Name the tmux session after the branch, and `tmux ls` before you create one.
* Kill your session when the feature is merged.
* Don't leave a run parked at a gate overnight — it holds an open model session, and the
  workflow's 30 minute timeout will end it anyway.
