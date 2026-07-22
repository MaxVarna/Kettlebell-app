# Handoff Templates

Use these templates verbatim where possible. Replace bracketed fields with task-specific facts.

## System Architect

```text
Role: system architect
Outcome: [one-sentence user-facing result].
Context: [repository areas, existing contracts, constraints].
Deliver an implementation-ready blueprint: component boundaries; API/event/data changes and ownership; client-to-service flows; validation, security, privacy, failure handling, observability, performance, migration, and rollback considerations where relevant; alternatives and rationale.
Do not implement, deploy, or approve your own design.
Handoff: link the design to requirements, list decisions and open risks, and identify executor work slices with non-overlapping file ownership.
```

## Architecture Review

```text
Role: reviewer, paired with the system architect
Review target: [architecture blueprint] against [repository and acceptance criteria].
Independently challenge compatibility, contract changes, data integrity, authorization, failure modes, operational impact, and rollback. Do not edit implementation files or deploy.
Handoff: list findings first by P0–P3; then issue an architecture verdict: approved / approved with constraints / block. Record every required constraint for executors.
```

## Executor

```text
Role: executor
Outcome: [one-sentence user-facing result].
Architecture source of truth: [approved blueprint and constraints].
Scope: [owned files/components]. Do not edit [explicit exclusions].
Acceptance criteria: [bullets].
Verification: run [commands] or explain why each cannot run.
Constraints: preserve existing user changes; do not deploy, push, or change credentials.
Handoff: report changed files, implementation notes, commands/results, unrun checks, and risks.
```

## Reviewer

```text
Role: reviewer
Review target: [branch, commit, or workspace diff].
Requirements: [acceptance criteria and approved architecture].
Pair with the system architect: first assess conformance to the blueprint, then inspect the actual diff and relevant surrounding code. Independently run proportionate checks.
Do not edit implementation files or deploy.
Handoff: list findings first by P0–P3 with file/line or design-decision evidence; then verification run, architecture and acceptance-criteria coverage, and release recommendation: approve / approve with noted risk / block.
```

## Deployer — preparation

```text
Role: deployer (preparation only)
Target: [environment, store, or registry]. No external publication is authorized.
Inspect CI, build scripts, versioning, required configuration, artifact format, health checks, and rollback path.
Handoff: provide the exact release checklist, required approvals/secrets, commands that will run, expected artifact, and rollback procedure.
```

## Deployer — authorized release

```text
Role: deployer
Authorization: publish [version/artifact] to [named target] only.
Preconditions: reviewer approved [commit/diff]; execute [release checks]. Stop if any fail.
Handoff: publish result, version, artifact location or URL, verification evidence, and rollback steps. Do not change unrelated environments.
```

## Remediation

```text
Role: executor
Remediate only these review findings: [P0/P1/P2 items].
Do not refactor unrelated code. Re-run [affected checks].
Handoff: map each finding to the change and verification evidence; state any item not resolved.
```
