# Tech docs registry

When the scaffold scans a referenced codebase (Step 2b), it reads the manifest files (`package.json`, `pyproject.toml`, `Gemfile`, `go.mod`, `Cargo.toml`, `Dockerfile`, etc.) and resolves each detected technology against this registry to produce a documentation link. The links land in the codebase's entry in `pm/codebases.md` and in the **Key References** section of every persona that owns that codebase.

This registry is **deliberately small** and curated. It covers the most common technologies in modern web / cloud projects. Add to it as your team's stack expands — the scaffold reads from this file at run time, so additions take effect on the next invocation.

## Format

Each entry is a markdown table row with:

- **Detector** — the string the scaffold matches against (typically a package name or filename).
- **Technology** — human-readable name.
- **Doc URL** — the canonical official documentation entry point. Prefer the project's own docs over a wiki / blog / aggregator.
- **Notes** *(optional)* — version-pinning advice, deprecated-version warnings, or category tags (e.g. `frontend-framework`, `db`, `ci`).

When two detectors map to the same technology, the scaffold deduplicates by **Technology** name in the output.

## Languages and runtimes

| Detector | Technology | Doc URL | Notes |
| --- | --- | --- | --- |
| Node 20+ in `engines.node` | Node.js | https://nodejs.org/docs/latest-v22.x/api/ | LTS 22 is the current default; 20 still supported through 2026. |
| Python 3.10+ in `pyproject.toml` | Python | https://docs.python.org/3/ | |
| Ruby 3.x in `Gemfile` | Ruby | https://docs.ruby-lang.org/en/3.3/ | |
| Go 1.21+ in `go.mod` | Go | https://pkg.go.dev/std | |
| Rust in `Cargo.toml` | Rust | https://doc.rust-lang.org/std/ | |
| `tsconfig.json` present | TypeScript | https://www.typescriptlang.org/docs/ | |

## Backend frameworks

| Detector | Technology | Doc URL | Notes |
| --- | --- | --- | --- |
| `@nestjs/core` | NestJS | https://docs.nestjs.com/ | |
| `express` | Express | https://expressjs.com/en/4x/api.html | Modern projects often migrate off Express to NestJS / Fastify / Hono. |
| `fastify` | Fastify | https://fastify.dev/docs/latest/ | |
| `hono` | Hono | https://hono.dev/docs/ | |
| `next` | Next.js | https://nextjs.org/docs | App Router is the default since Next 13. |
| `fastapi` | FastAPI | https://fastapi.tiangolo.com/ | |
| `django` | Django | https://docs.djangoproject.com/ | |
| `flask` | Flask | https://flask.palletsprojects.com/ | |
| `rails` | Ruby on Rails | https://guides.rubyonrails.org/ | |
| `gin-gonic/gin` | Gin | https://gin-gonic.com/docs/ | |
| `actix-web` | Actix Web | https://actix.rs/docs/ | |

## Frontend frameworks and libraries

| Detector | Technology | Doc URL | Notes |
| --- | --- | --- | --- |
| `react` | React | https://react.dev/ | |
| `react-router` / `react-router-dom` | React Router | https://reactrouter.com/ | |
| `vue` | Vue | https://vuejs.org/guide/introduction.html | |
| `svelte` | Svelte | https://svelte.dev/docs | |
| `solid-js` | SolidJS | https://www.solidjs.com/docs | |
| `vite` | Vite | https://vite.dev/guide/ | |
| `webpack` | Webpack | https://webpack.js.org/concepts/ | Many projects migrating to Vite or esbuild. |
| `tailwindcss` | Tailwind CSS | https://tailwindcss.com/docs | |
| `@radix-ui/react-*` | Radix UI | https://www.radix-ui.com/primitives | |
| `shadcn` / `shadcn-ui` | shadcn/ui | https://ui.shadcn.com/docs | |

## Testing

| Detector | Technology | Doc URL | Notes |
| --- | --- | --- | --- |
| `vitest` | Vitest | https://vitest.dev/guide/ | |
| `jest` | Jest | https://jestjs.io/docs/getting-started | Many projects migrating to Vitest. |
| `playwright` | Playwright | https://playwright.dev/docs/intro | |
| `cypress` | Cypress | https://docs.cypress.io/ | |
| `pytest` | pytest | https://docs.pytest.org/ | |
| `rspec` | RSpec | https://rspec.info/documentation/ | |

## Databases and queues

| Detector | Technology | Doc URL | Notes |
| --- | --- | --- | --- |
| `pg` / `postgres` (npm) / `psycopg` | PostgreSQL | https://www.postgresql.org/docs/current/ | |
| `postgis` | PostGIS | https://postgis.net/documentation/ | |
| `mongodb` / `mongoose` / `pymongo` | MongoDB | https://www.mongodb.com/docs/ | |
| `mysql2` / `mysqlclient` | MySQL | https://dev.mysql.com/doc/ | |
| `ioredis` / `redis` (npm) / `redis-py` | Redis | https://redis.io/docs/ | |
| `valkey-glide` | Valkey | https://valkey.io/docs/ | BSD-3 fork of Redis. |
| `kafka-node` / `kafkajs` / `confluent-kafka-go` | Apache Kafka | https://kafka.apache.org/documentation/ | |
| `bullmq` | BullMQ | https://docs.bullmq.io/ | |

## Cloud / infra

| Detector | Technology | Doc URL | Notes |
| --- | --- | --- | --- |
| `terraform` files in `infra/` | Terraform | https://developer.hashicorp.com/terraform/docs | |
| `pulumi` | Pulumi | https://www.pulumi.com/docs/ | |
| `@google-cloud/*` | Google Cloud SDK (Node) | https://cloud.google.com/nodejs/docs/reference | |
| `aws-sdk` / `boto3` | AWS SDK | https://docs.aws.amazon.com/sdk-for-javascript/ | Pin to v3 (modular) — v2 reached EOL Sep 2025. |
| `@azure/*` | Azure SDK | https://learn.microsoft.com/azure/developer/javascript/ | |
| `kubernetes` / `helm` files | Kubernetes / Helm | https://kubernetes.io/docs/home/ | |
| `Dockerfile` present | Docker | https://docs.docker.com/ | |
| `docker-compose.yml` present | Docker Compose | https://docs.docker.com/compose/ | |

## Auth and identity

| Detector | Technology | Doc URL | Notes |
| --- | --- | --- | --- |
| `jose` | jose (JWT/JWE/JWKS) | https://github.com/panva/jose | Modern; ESM-first. |
| `jsonwebtoken` | jsonwebtoken | https://github.com/auth0/node-jsonwebtoken | Older; many projects migrating to `jose`. |
| `passport` | Passport.js | https://www.passportjs.org/docs/ | |
| `auth0` | Auth0 | https://auth0.com/docs | |
| `clerk-sdk-*` | Clerk | https://clerk.com/docs | |

## Schema validation / serialization

| Detector | Technology | Doc URL | Notes |
| --- | --- | --- | --- |
| `zod` | Zod | https://zod.dev/ | |
| `nestjs-zod` | nestjs-zod | https://github.com/risen228/nestjs-zod | OpenAPI bridge for `@nestjs/swagger`. |
| `joi` | Joi | https://joi.dev/api/ | |
| `yup` | Yup | https://github.com/jquense/yup | |
| `pydantic` | Pydantic | https://docs.pydantic.dev/ | |
| `marshmallow` | Marshmallow | https://marshmallow.readthedocs.io/ | |

## Specialty

| Detector | Technology | Doc URL | Notes |
| --- | --- | --- | --- |
| `@8thwall/*` or `8thwall` references | 8th Wall (WebAR / SLAM) | https://www.8thwall.com/docs/ | |
| `three` | Three.js | https://threejs.org/docs/ | |
| `@anthropic-ai/sdk` | Anthropic SDK | https://docs.anthropic.com/en/api/getting-started | Triggers the `claude-api` skill. |
| `openai` | OpenAI SDK | https://platform.openai.com/docs/api-reference | |
| `stripe` | Stripe API | https://docs.stripe.com/api | |
| `@figma/code-connect` | Figma Code Connect | https://www.figma.com/developers/code-connect | Triggers `figma:figma-code-connect` skill. |

## How to add a new entry

1. Identify the **Detector** — the most reliable string the scaffold can match against. Prefer package names over filename heuristics; filename heuristics are fine when a package isn't involved (Dockerfile, `tsconfig.json`).
2. Add a row to the most appropriate section (or create a new section if no existing one fits).
3. Add the canonical Doc URL — official project docs first, vendor docs second, never aggregator sites.
4. Optionally add a Notes column describing version-pin advice or deprecation context.
5. Re-run the scaffold against any codebase whose stack should pick up the new entry; the persona's Key References will update.
