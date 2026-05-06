# Feature-overlap registry

When the scaffold scans a referenced codebase (Step 2b), it cross-references the detected libraries against this registry to find pairs (or sets) with significant feature overlap — multiple test runners, multiple bundlers, multiple JWT libraries, etc. For each overlapping set found, the scaffold compares **install dates** from lock files. If the gap between the oldest and newest installation exceeds **one year**, the scaffold asks the user whether the older library is deprecated in this project. On confirmation, a deprecation note lands in:

1. The codebase's entry in `pm/codebases.md` (Deprecation notes section).
2. The Working patterns section of the relevant persona file ("Use `<newer>`; `<older>` is deprecated in this project — do not extend it").

This registry is intentionally narrow — it covers high-confidence overlap pairs where having both is almost always a migration in progress. Don't list pairs that legitimately coexist (e.g. Vitest + Playwright cover unit and e2e respectively; that's not overlap).

## Format

Each entry is a markdown section listing two or more libraries that fill the same role.

```
### <Role description>

- `<lib-a>` — <one line on what it is>
- `<lib-b>` — <one line on what it is>
- `<lib-c>` — <one line on what it is>
```

When the scaffold detects more than one library from a section in the same codebase, it computes the install-date gap and may surface a deprecation question.

## Test runners (JavaScript / TypeScript)

- `vitest` — modern (since 2021), Vite-native.
- `jest` — older (since 2014), historically the default.
- `mocha` — older (since 2011); often paired with `chai`.
- `ava` — concurrent test runner; smaller user base.

## Bundlers and dev servers (JavaScript / TypeScript)

- `vite` — modern (since 2020), ESM-native.
- `webpack` — older (since 2012), historically the default for SPAs.
- `rollup` — library bundler; library projects typically pick this over webpack.
- `parcel` — zero-config bundler; smaller user base.
- `esbuild` — fastest pure bundler; often a transitive dep of vite/tsx.

## JWT libraries (Node)

- `jose` — modern, actively maintained, ESM-first; supports JWT/JWE/JWKS.
- `jsonwebtoken` — older, CJS-first; widely deployed.

## Cloud SDK majors (AWS — Node)

- `aws-sdk` — v2; reached **EOL September 2025**. Any active install is a migration target.
- `@aws-sdk/*` — v3; modular (per-service packages).

## HTTP frameworks (Node)

- `express` — historically dominant (since 2010).
- `nestjs` (`@nestjs/core`) — opinionated framework; modern.
- `fastify` — performant, schema-first; modern.
- `hono` — edge-runtime-friendly; modern.
- `koa` — Express's successor by the same authors; smaller user base.

## CSS frameworks / libraries

- `tailwindcss` — utility-first; v4 is the modern default.
- `bootstrap` — older (since 2011); component-first; declining usage.
- `emotion` / `styled-components` — CSS-in-JS; both predate Tailwind v4.

## Component libraries (React)

- `shadcn` (`shadcn/ui`) — copy-paste, primitives-based; modern.
- `@radix-ui/*` — primitive layer (often a peer dep of shadcn); compatible with shadcn.
- `@mui/material` — Material UI; older, opinionated.
- `@chakra-ui/*` — Chakra; older, opinionated.
- `antd` — Ant Design; older.

## State management (React)

- `zustand` — modern, minimal; widespread in 2024+.
- `redux` / `@reduxjs/toolkit` — older, more boilerplate; still common.
- `mobx` — observable-based; smaller user base.
- `jotai` / `recoil` — atomic state; modern but smaller user base.

## ORM / data access (Node)

- `prisma` — schema-first; modern.
- `drizzle-orm` — TypeScript-native; modern.
- `typeorm` — older decorator-style; declining momentum.
- `sequelize` — older callback-style historically; still in maintenance.

## Linting (JavaScript / TypeScript)

- `eslint` — historically dominant.
- `biome` — modern, all-in-one (linter + formatter); smaller user base but growing.
- `oxlint` — newer Rust-based linter; experimental.

## Formatters (JavaScript / TypeScript)

- `prettier` — historically dominant.
- `biome` — see above; covers formatting too.

## Schema validators (JavaScript / TypeScript)

- `zod` — modern, TypeScript-native.
- `joi` — older.
- `yup` — older.
- `valibot` — modern alternative to zod; smaller user base.

## Python — package / dep managers

- `poetry` — older modern (since 2018).
- `uv` — newer (since 2024); much faster.
- `pdm` — modern PEP-582-aware.
- `pip` + `requirements.txt` — original; legacy.
- `pipenv` — older modern; declining momentum.

## Python — test runners

- `pytest` — dominant.
- `unittest` (stdlib) — older; often coexists with pytest in transitional projects.

## Python — async frameworks

- `fastapi` — modern.
- `flask` — older synchronous; `flask + flask-async` is a transitional shape.
- `django` — older synchronous; `django + django-async` is a transitional shape.

## Adding a new section

When you encounter a recurring overlap pair in your project (or across projects), add a section here following the format above. The scaffold reads this file at run time, so additions take effect on the next invocation.

**Don't add pairs that legitimately coexist.** A unit-test runner (Vitest) and an e2e runner (Playwright) are not overlap. A schema validator (Zod) and an ORM (Prisma) are not overlap. The signal this registry watches for is "two libraries that do the same thing where keeping both is technical debt."
