---
name: skill-evaluator
description: Activate when the user wishes to test a agent skill file. provides a JSON test suite and asks to verify a skill's behavioral effects. You run A/B tests on agent skills to confirm they produce intended behavioral changes.
---

## When to use

Use this skill when the user:
- Provides a JSON test suite and asks to evaluate a skill's effectiveness
- Wants to verify a skill produces specific behavioral changes
- Asks to run A/B tests against a SKILL.md file
- Mentions "skill evaluation", "skill test suite", or "verify skill behavior"

Do not use this skill for:
- Evaluating prompts or agents (only skills are in scope)
- Ad-hoc single test case evaluation (test suites are file-based only)
- Configuring model choice, retries, or timeouts (the evaluator has no knobs)

## Input Contract

The user provides a **test suite path** as either:
- The first argument to the skill invocation (e.g., `/skill-evaluator ./evals/foo.test.json`)
- A path referenced in the user's message
- A path the user pastes directly into chat

If no path is provided, ask the user once for the path. Do not auto-scan the working directory.

### Test Suite Format

A JSON array of test cases:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | string | yes | Human-readable name for the test case |
| `skill.name` | string | yes | Short identifier for the skill under test |
| `skill.path` | string | yes | Relative or absolute path to the skill's `SKILL.md` |
| `prompt` | string | yes | Input prompt to run through the agent |
| `expectedChange` | string | yes | Plain English description of the behavioral delta the skill should produce |

**Example:**

```json
[
  {
    "title": "Code review follows structured format",
    "skill": {
      "name": "code-review",
      "skillPath": "./skills/code-review/SKILL.md"
    },
    "prompt": "Review this function for bugs: function add(a,b) { return a+b; }",
    "expectedChange": "The output should include organized sections (Summary, Issues, Suggestions) and avoid informal language"
  }
]
```

The `expectedChange` describes a **behavioral delta** between baseline and with-skill runs, not an exact target output. Judge whether the delta is present, not whether strings match.

## Execution Protocol

For each test case, perform these steps:

1. **Prepare scratch files.** Allocate two paths for this case:
   - Baseline: `/tmp/skill-eval-baseline-<n>.md`
   - With-skill: `/tmp/skill-eval-withskill-<n>.md`
2. **Ensure target skill is NOT active.** Run the `prompt` and write the full output to the baseline scratch file.
3. **Load the target skill** from `skill.path`. Activate it.
4. **Run the same `prompt`** with the target skill active. Write the full output to the with-skill scratch file.
5. **Judge** — compare both scratch files against `expectedChange` (see Judgment Protocol). Determine the result.
6. **Record the result** in the output report.
7. **Unload the target skill** before moving to the next test case. If the host agent has no explicit unload API, assume that starting a fresh sub-task or new context window unloads prior skills. Do not reuse loaded skill state across cases.
8. **Continue** to the next case regardless of pass/fail/error.

Run cases **in order, one at a time**, completing all steps for each before moving to the next. Do not skip cases or short-circuit on failure.

## Judgment Protocol

The agent acts as its own LLM-judge. For each test case, read both scratch files and evaluate whether the with-skill output differs from baseline in the way `expectedChange` describes.

### Outcome definitions

A test result is one of four values:

- **PASS** — the described behavioral change is clearly observable in the with-skill output AND absent from the baseline AND attributable to the skill's influence (not random variation)
- **FAIL** — both outputs are substantially similar (no evidence of the described change) OR the change is unrelated to what `expectedChange` describes OR the change is already present in baseline
- **ERROR** — the test could not be executed (malformed JSON, missing skill file, skill failed to load, etc.). See Error Handling below.
- **INCONCLUSIVE** — outputs differ but the judge cannot confidently attribute the difference to the skill (e.g., the change is ambiguous, baseline is noisy, expectedChange is too vague). Use this when you cannot decide PASS vs FAIL with confidence.

### Reasoning requirement

Every result MUST include reasoning — a concise explanation referencing specific differences (or lack thereof) between the two scratch files. If you cannot confidently determine PASS/FAIL, mark INCONCLUSIVE and explain why rather than guessing.

The `expectedChange` is ground truth. Judge against it exactly as written. Do not reinterpret, soften, or expand its scope.

## Output Format

Emit results as a markdown table in your final response:

```
| # | Test Title | Result | Reasoning |
|---|------------|--------|-----------|
| 1 | Code review follows structured format | PASS | Output with skill has Summary/Issues/Suggestions sections; baseline is unstructured prose |
| 2 | Output stays under 4 lines | FAIL | Both outputs are 2-3 lines; no length difference observable |
| 3 | Skill uses bullet lists | INCONCLUSIVE | With-skill uses bullets but so does baseline on this prompt; cannot attribute to skill |
| 4 | Missing skill file | ERROR | skill.path ./skills/foo/SKILL.md does not exist |

Summary: 1/4 passed (1 PASS, 2 FAIL, 1 INCONCLUSIVE, 0 ERROR)
```

The summary line must enumerate the count of each outcome type. Use INCONCLUSIVE and ERROR as distinct categories — do not collapse them into FAIL.

## Error Handling

When a test case cannot be executed, mark it ERROR and continue to the next case. Do not abort the run.

| Failure mode | Action |
|--------------|--------|
| JSON file malformed or unreadable | Abort the entire run with a clear error message — no cases can run |
| `skill.path` does not exist | Mark that case ERROR, reason: `skill file not found at <path>` |
| Skill fails to load or activate | Mark that case ERROR, reason: `skill failed to load: <error>` |
| Scratch file write fails | Mark that case ERROR, reason: `could not persist output: <error>` |
| Baseline run produces no output | Mark that case ERROR, reason: `baseline run produced empty output` |

When the entire suite cannot start (e.g., malformed JSON), report the error and stop. Do not attempt partial runs.

## Important Rules

- Run tests **in order**, one at a time, completing all steps before moving to the next
- Ensure the target skill is fully unloaded between test cases to avoid cross-contamination
- Do not skip tests or short-circuit on failure — run every case in the suite
- The `expectedChange` is ground truth — judge against it exactly as written, do not reinterpret or soften it
- Use INCONCLUSIVE when you cannot confidently judge — do not force a PASS/FAIL decision when evidence is ambiguous
- Do not abort the run on a single case ERROR — log it and continue
- Do not introduce configuration (model choice, retries, timeouts) — the evaluator is pure procedure
