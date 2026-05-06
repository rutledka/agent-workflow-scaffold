---
name: {{SKILL_NAME}}
description: {{SKILL_DESCRIPTION}}
---

# {{SKILL_NAME}} — project-local skill

This skill encodes **niche knowledge for the {{CODEBASE_NAME}} codebase** at `{{LOCAL_PATH}}`. It is a project-local skill (lives under `skills/`) and is loaded automatically by Claude Code when its trigger description matches the task at hand. Personas configured under `agents/` are also instructed to check `skills/` for matching local skills before starting work — see the **Before starting work** section in each persona file.

This file was scaffolded by `agent-workflow-scaffold` based on the codebase scan. It contains what the scaffold could *infer*; the human-only knowledge (recurring bugs, quirky requirements, "the thing that broke prod last quarter") needs your direct input below.

---

## Niche tech overview

{{NICHE_TECH_OVERVIEW}}

*(Edit this section to add or correct anything the scan got wrong. The point is to give an agent enough context to avoid the most common mistakes a newcomer would make.)*

---

## Project conventions specific to this codebase

{{CONVENTIONS_BULLETS}}

*(Edit this list to add conventions that are specific to this codebase and not just generic "good practice." Examples: file-naming patterns, commit-message tags, branching for risky changes, where deferred work goes, what "feature complete" means here.)*

---

## Common gotchas

{{COMMON_GOTCHAS_BULLETS}}

*(Edit this list to add the recurring bugs / surprises any contributor should know about. Aim for non-obvious things — if a senior engineer in this codebase would say "oh yeah, watch out for that," it belongs here. Skip generic advice like "test before pushing" — `AGENTS.md` covers that.)*

---

## Internal documentation

{{INTERNAL_DOCS_LINKS}}

*(Edit this list to point at in-repo docs, ADRs, design memos, runbooks, postmortems, or anything else an agent should read before doing substantive work in this codebase. Format: `- [<title>](<relative-path-or-URL>) — <one line on what it covers>`.)*

---

## When to load this skill

Claude Code loads project-local skills when their **description** in the frontmatter above matches the user's prompt or the task context. For codebase-specific skills, the description should:

1. Name the codebase explicitly (so the loader can match against the path).
2. Mention the specific tech / domain that's distinct (so the loader matches against tech-specific prompts).
3. Tell the agent to load the skill before *any* task touching the codebase — not just tasks that name the niche tech, because most contributors won't know to mention it.

The default description above does all three. Refine it as you discover patterns of when the skill *should* have loaded but didn't, or *did* load when it shouldn't have.

---

## How to extend or correct this skill

This is a regular Claude Code skill file. Add additional sections, supporting files (gotcha catalogs, decision tables, command cheatsheets), or per-area sub-skills as they prove useful. The skill loader will pick them up on the next session.

When the underlying codebase changes substantially (new framework, major refactor, new gotchas), edit this file directly — the scaffold's re-run path won't overwrite a skill the user has customized. To regenerate from scratch, delete the directory and re-run the scaffold; it'll re-scan and produce a fresh draft.
