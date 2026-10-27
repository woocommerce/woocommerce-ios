# AI dev and testing tools

AI tools and testing helpers for WooCommerce iOS development. When adding, changing, or removing a tool, update its entry or discovery guidance in the same PR. Skill descriptions belong in `SKILL.md`.

`Repo` means the files ship with the checkout; build and runtime prerequisites still apply. `MCP` needs a configured, connected server. `CI` runs in GitHub or Buildkite with team credentials. Before using an MCP tool, check that it is available and authorized. Report missing access and use the listed fallback.

## Skills

Repository skills live in [`.agents/skills/`](../.agents/skills/). Agents discover their names and descriptions and load the instructions when a task matches. Each `SKILL.md` defines its purpose and trigger.

## Agents

Shared task definitions live in `.agents/agents/`. Read the relevant definition before delegating a review, debugging, or test-writing task. Native subagent registration depends on the client.

| Name | What it does | When to use | Example | Owner | Availability |
|---|---|---|---|---|---|
| [`code-reviewer`](../.agents/agents/code-reviewer/code-reviewer.md) | Reviews changes against iOS conventions | Reviewing a diff or PR | "Use the code-reviewer agent on this diff" | Woo Mobile | Repo |
| [`debugger`](../.agents/agents/debugger/debugger.md) | Diagnoses build and test failures | A failure has an unclear cause | "Use the debugger agent on this test failure" | Woo Mobile | Repo. Uses `/build` and `/test` for execution and diagnostic logs |
| [`test-writer`](../.agents/agents/test-writer/test-writer.md) | Writes tests using the repository conventions | Adding unit test coverage | "Use the test-writer agent for this ViewModel" | Woo Mobile | Repo |

## Testing helpers

| Name | What it does | When to use | Example | Owner | Availability |
|---|---|---|---|---|---|
| [Auto-login](../.agents/skills/auto-login/SKILL.md) | Logs a DEBUG app into a live store or explicit WireMock fixtures | Simulator checks that need a logged-in store | "Log in to a test store on the simulator" or "auto-login with mocks" | Woo Mobile | Repo. Signed DEBUG build with its runtime frameworks; authorized store access or mock server. Read the skill before using its launch script |
| [Simulator finder](../Scripts/find-simulator.sh) | Finds a booted simulator or boots an available one | Selecting a device for testing | `bash Scripts/find-simulator.sh ipad` | Woo Mobile | Repo. Xcode and an installed simulator runtime |
| [Simulator diagnostics comparison](../.buildkite/commands/compare-simulator-diagnostics.rb) | Compares bounded pipe and PTY diagnostic collection after CI unit tests | Temporary investigation of the 600-second diagnostics timeout; remove after the comparison | Runs from the Unit Tests job | Woo Mobile | CI. Existing result bundle; no test or diagnostic settings changed |
| [WireMock scripts](../API-Mocks/README.md) | Starts and stops the local API fixture server | UI tests or checks using mocked responses | `./API-Mocks/scripts/start.sh` | Woo Mobile | Repo. Java; follow the mocks skill for setup |
| [Maestro smoke suite](../.maestro/README.md) | Runs repeatable simulator flows against live test stores and writes reports | Checking core app flows or rerunning failures | `.maestro/scripts/run-smoke-tests.sh --plan --profile core` | Woo Mobile | Repo. Pinned toolchain, built app, English simulator, and authorized test-store configuration; see linked setup |
| [Maestro doctor](../.maestro/scripts/doctor.sh) and [environment linter](../.maestro/scripts/lint-env.py) | Checks the app, device, and local store configuration before a smoke run | Finding missing setup before installing or launching the app | `.maestro/scripts/doctor.sh --app /path/to/WooCommerce.app --profile core` | Woo Mobile | Repo. See [local setup](../.maestro/README.md#local-setup); checks do not boot a simulator or print credential values |
| [Maestro lab-store setup](../.maestro/scripts/setup-jn-store.sh) | Prepares a Jurassic Ninja store and local configuration for the smoke suite | Setting up or replacing a disposable lab store | `.maestro/scripts/setup-jn-store.sh --site your-site.jurassic.ninja` | Woo Mobile | Repo. Authorized site and SSH access, WordPress.com test account, and local app credentials; see [provisioning](../.maestro/README.md#provisioning-a-lab-store) |
| [UI navigation references](../.agents/references/screen-identifiers.md) and [feature map](../.agents/references/feature-map.json) | Maps screens and changed files to verification flows | Planning simulator checks | Used by the verify skill | Woo Mobile | Repo. Follow [verification guidance](../.agents/rules/verification.md) for device setup |
| [View snapshots](../.agents/skills/snapshot/SKILL.md) | Renders SwiftUI states for design comparison | Layout and styling iteration | `/snapshot <view-name>` | Woo Mobile | Repo. Compatible SnapshotTesting dependency and simulator; follow the skill for temporary fixtures and capture paths |

## MCP servers

| Name | What it does | When to use | Example | Owner | Availability |
|---|---|---|---|---|---|
| [`mobile-mcp`](../.mcp.json) | Reads UI elements, takes screenshots, and interacts with the simulator | Driving the app during agent verification | Used by the verify and auto-login skills | mobile-next, third party | MCP. Project config for compatible clients; Node.js and simulator device helper. See [setup](../.agents/rules/verification.md). Fallback: `xcrun simctl` for lifecycle/screenshots and manual UI checks |
| [ContextA8C](../.agents/rules/context-a8c.md) | Reads Linear, Slack, P2, and GitHub context; loads optional providers | Investigating an issue or discovering a test-site provider | "Read WOOMOB-4290" | Automattic | MCP. Optional per-user setup and connected accounts; not in project `.mcp.json`. Fallback: available GitHub tools/CLI for public resources; ask for internal content |

## CI automation

| Name | What it does | When to use | Example | Owner | Availability |
|---|---|---|---|---|---|
| [AI Code Review](../.github/workflows/ai-code-review.yml) | Runs the shared AI PR review workflow | PR opened, reopened, ready for review, or a `@claude review` PR comment | Comment `@claude review` on a PR | Woo Mobile | CI |
| [Claude Review Recommendation](../.github/workflows/claude-review-recommendation.yml) | Runs the shared reviewer recommendation workflow | PR opened or updated | Automatic | Woo Mobile | CI |
| [Claude Build Analysis](../.buildkite/claude-analysis.yml) | Explains failed builds and comments on the PR | A Buildkite build fails | Automatic | Woo Mobile | CI |

## Configuration

| Name | What it does | When to use | Example | Owner | Availability |
|---|---|---|---|---|---|
| [Module test guide](../Modules/Tests/AGENTS.md) | Shared test conventions and async patterns | Writing or updating module tests | Read before editing module tests | Woo Mobile | Repo |
| [`AGENTS.md`](../AGENTS.md) | Shared repository instructions | Changing repository agent guidance | Edit the shared instructions | Woo Mobile | Repo |
| [`.claude/settings.json`](../.claude/settings.json) | Team Claude Code command permissions | Changing permitted local commands | Update `permissions.allow` or `permissions.deny` | Woo Mobile | Repo. Claude Code |
| [`.agents/rules/`](../.agents/rules/) | Shared architecture, testing, and setup guidance | Looking up detailed repository conventions | Read the rule relevant to the task | Woo Mobile | Repo. Follow the pointers in `AGENTS.md` or read the relevant rule |
