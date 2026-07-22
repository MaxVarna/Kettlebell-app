---
name: fullstack-team-orchestration
description: Coordinate a full-stack implementation through a system architect, executor, reviewer, and deployer subagent team. Use when a change spans application code, interfaces, data, tests, build, or release work and benefits from architecture design, independent review gates, and evidence-based handoffs; also use when users ask to delegate development among architect, executor, reviewer, and deployer roles.
---

# Full-stack Team Orchestration

Turn a product request into a small, accountable delivery team. The coordinating agent owns scope, sequencing, integration, and user communication. Subagents own only their assigned role and must return evidence at each handoff. The system architect and reviewer operate as a design-assurance pair: one proposes the system shape, the other independently challenges it before implementation and checks conformance afterward.

## Preflight

1. Inspect the repository, current branch, worktree status, instructions, and existing CI/release configuration.
2. Derive acceptance criteria, affected surfaces, architecture decisions, verification commands, and the release target. State assumptions that could materially alter scope.
3. Create a short plan. Keep unrelated dirty-worktree changes out of scope.
4. Separate local build work from external deployment. A deployment requires explicit user authorization for the named target, even when the user asked for a deployer role.

Do not create a team for a trivial one-file change unless the user explicitly requests it. Use the smallest team that still provides independent implementation, review, and release accountability.

## Roles and Boundaries

| Role | Owns | Must not do |
|---|---|---|
| **Coordinator** | Requirements, task split, integration, decisions, final report | Silently broaden scope or bypass a failed gate |
| **System architect** | System blueprint, boundaries, interfaces, data flow, cross-cutting constraints, architectural risks | Implement the feature, self-approve the design, or deploy |
| **Executor** | Implementation, focused tests, local documentation needed for the change | Deploy, push, alter unrelated files, or self-approve |
| **Reviewer** | Independent diff review, validation audit, regression and security checks | Rewrite the solution or approve without evidence |
| **Deployer** | Build/release preparation, CI/release verification, authorized publication | Deploy without a passed review and explicit target authorization |

Use the handoff prompts in [references/handoff-templates.md](references/handoff-templates.md). Give every agent a concrete file or responsibility boundary, acceptance criteria, and the exact evidence it must return.

## Delivery Workflow

### 1. Define the slice and architecture

Write a delivery card before delegating:

- outcome and non-goals;
- affected apps, services, interfaces, and files;
- acceptance criteria and test commands;
- release target, if any;
- known risks or user decisions still required;
- architecture constraints and compatibility requirements.

Split work by independently verifiable vertical slices. Prefer one executor per non-overlapping code area. If tasks overlap, sequence them; do not let multiple agents edit the same files concurrently.

Delegate the system architect before implementation. Require an architecture blueprint that covers only the necessary depth:

- component/service boundaries and responsibilities;
- API, event, and data-model changes, including ownership and validation;
- request and state flows across client, backend, and integrations;
- security, privacy, failure handling, observability, performance, migration, and rollback implications when relevant;
- alternatives rejected and the decision rationale.

Pair the architect with the reviewer for an architecture gate. The reviewer independently checks the blueprint against the repository, requirements, compatibility, and likely failure modes. Resolve disagreements through the coordinator before assigning implementation. The architect's design and review verdict become the source of truth for executors.

### 2. Execute

Delegate each slice to an executor. Require the executor to:

1. inspect relevant code before editing;
2. implement only the assigned scope;
3. run focused tests, formatters, linters, and type checks relevant to the change;
4. report files changed, commands run, results, and unresolved risks.

The deployer may work in parallel only on read-only build/release preparation: inspect CI, identify required secrets, validate versioning, and draft a release checklist. It must not publish anything yet.

### 3. Review

After executor work is complete, reconvene the architect and reviewer as a review pair. The architect checks that the implementation preserves the approved blueprint and flags design drift. The reviewer independently inspects the actual diff and runs proportionate checks; it must not rely only on the executor's summary.

Classify findings by priority:

- **P0**: data loss, security breach, broken production path;
- **P1**: likely user-visible regression or broken acceptance criterion;
- **P2**: correctness, maintainability, or coverage issue worth fixing now;
- **P3**: optional improvement.

P0/P1 findings block release. P2 findings block release when they contradict explicit acceptance criteria, the approved architecture, or a stated quality gate. Return blocking findings to the executor with a narrow remediation task, then repeat the affected architecture and code review checks.

### 4. Verify and release

The coordinator verifies that acceptance criteria are covered by real evidence. The deployer may then:

1. run the clean build and release checks from the repository's CI configuration;
2. validate generated artifacts, version, target environment, and rollback path;
3. stop for explicit user approval before any irreversible external action (store upload, production deployment, release publication, or credential change);
4. after authorization, publish only to the named target and report the URL, version, artifact hashes where relevant, and rollback procedure.

If no deployment was authorized, finish at a verified, release-ready state and say exactly what remains.

## Required Handoff Evidence

Every handoff must include:

- scope completed and explicitly deferred;
- approved architecture blueprint and any intentional implementation deviation;
- changed files or reviewed commit/diff;
- commands run and their results;
- tests not run, with a reason;
- risks, blockers, migrations, configuration changes, and rollback notes;
- source of truth for the next role (branch, commit, artifact, or workspace path).

Do not claim a release is ready just because tests passed. Confirm the tests cover the requested behavior, the reviewer cleared blocking findings, and the deployer validated the actual artifact.

## Final Report

Lead with the delivered outcome. Then summarize:

1. changed behavior and important files;
2. reviewer outcome and any accepted residual risk;
3. verification evidence;
4. deployment status, target, and rollback information; or the exact authorization still needed.

Use concise language. Do not expose secrets, tokens, or personally identifiable data in agent prompts, logs, or the final report.
