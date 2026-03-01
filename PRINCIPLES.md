# InnerPearl Engineering Principles

> *The foundation beneath every line of code we ship.*
>
> These principles apply across all InnerPearl repositories — `pearl-app`, `innerpearl`, and `pearl-ios`. They are the "why" behind every technical decision. When in doubt, come back here.

---

## 1. Security First

People trust Pearl with their birth charts, personal reflections, and spiritual journeys. That trust is the product. One breach doesn't just leak data — it destroys the relationship.

- **Never trust client input — validate everything server-side.** Convex mutations and queries must validate arguments with schemas. The iOS app and web client are conveniences, not security boundaries. Anything a client sends can be forged.

- **Secrets belong in environment variables, never in code.** API keys, signing secrets, DSNs — all live in `.env` files (locally) and CI/hosting environment config (in production). The `.env.example` file documents what's needed without exposing values. If a secret touches version control, rotate it immediately.

- **All API endpoints must authenticate before executing.** No anonymous access to user data. Every Convex function that touches personal data checks authentication first. There is no "we'll add auth later."

- **Defense in depth: multiple layers, never just one.** Auth at the edge, validation in the function, constraints in the schema, encryption at rest. If one layer fails, the next catches it. Assume every individual layer will eventually be bypassed.

- **Principle of least privilege: minimum required access.** Service accounts get scoped permissions. Environment variables are segmented per environment. Team members access only what their role requires. Code runs with the narrowest possible scope.

- **Personal data is sacred — encrypt at rest, minimize exposure.** Birth dates, birth locations, conversation histories, and astrological profiles are intimate data. Encrypt at rest. Never include PII in logs, error reports, or analytics. Query only the fields you need, never `SELECT *` on user tables.

- **No security through obscurity — assume attackers have source code.** Our repos are private today, but every security decision must hold up as if they were public. Obfuscation is not protection. Cryptographic guarantees and proper access control are.

---

## 2. Type Safety is Non-Negotiable

Types catch bugs before users do. In a codebase that spans TypeScript, Swift, and a Convex backend, type safety is the connective tissue that keeps everything honest.

- **TypeScript strict mode everywhere.** Strict null checks, strict function types, no implicit `any`. The compiler is our first reviewer — let it do its job. Every tsconfig in every package enforces this.

- **Eliminate `any` types — use `unknown` and narrow with type guards.** `any` is a lie the compiler tells itself. When you don't know a type, use `unknown` and prove the shape at runtime. Each `any` in the codebase is tech debt that hides real bugs. Aim to tighten `noExplicitAny` enforcement as the codebase matures.

- **Convex schema is the single source of truth for data shapes.** The schema defined in `convex/schema.ts` is the canonical definition of our data model. TypeScript types for documents flow from it. If the schema and the code disagree, the schema wins and the code is wrong.

- **Exhaustive pattern matching for union types.** When handling discriminated unions (message types, subscription tiers, AI response states), use exhaustive switches. The compiler should break the build if a new variant is added without handling it everywhere.

- **Runtime validation at system boundaries.** Type safety ends where our code ends. Data from external APIs, user inputs, webhook payloads, and URL parameters must be validated at the boundary before entering typed code. Trust the types inside; verify at the edges.

---

## 3. Fail Gracefully, Recover Automatically

Errors are inevitable. How we handle them defines the user experience. Pearl should never show a white screen, a cryptic stack trace, or silently lose data.

- **Error boundaries at every route level.** The app already wraps the root in an `ErrorBoundary`. Extend this pattern to individual routes and critical UI sections. A crash in the settings page shouldn't take down the chat. On iOS, use Swift's structured error handling to isolate failures per view.

- **Structured error handling — never swallow errors silently.** Every `catch` block must either handle the error meaningfully or re-throw it. Empty `catch {}` blocks are bugs. If you can't handle it, let it propagate to something that can.

- **Sentry captures every unhandled exception.** Sentry is integrated across web and iOS. Unhandled errors surface as alerts, not surprises. Configure proper source maps (web) and dSYMs (iOS) so stack traces are actionable, not cryptic.

- **User-facing errors are helpful, not technical.** "Something went wrong" is better than `TypeError: Cannot read property 'x' of undefined`. But "We couldn't load your chart — try refreshing" is better than both. Error messages should tell users what happened and what to do next.

- **Stack traces in production are security risks.** Internal errors reveal architecture, file paths, and sometimes data. Log the full trace to Sentry for the team; show users a clean, safe message. This applies to both web responses and iOS crash dialogs.

---

## 4. Performance is a Feature

Pearl is a daily companion — something people open in quiet moments. Sluggish load times and janky animations break the spell. Performance isn't optimization; it's respect for the user's time and attention.

- **Lazy load routes and heavy components.** Not every user visits every page. Use React's `lazy()` and `Suspense` for route-level code splitting. On iOS, defer heavy initialization until the view appears. First paint should be fast; the rest loads as needed.

- **Index every query.** Convex queries without proper indexes do full-table scans. As the user base grows, unindexed queries go from "fine" to "minutes." Define indexes in the schema for every query pattern. If you're writing a new query, add the index in the same commit.

- **Paginate data — never `.collect()` unbounded results.** Calling `.collect()` on a Convex query with no limit will eventually return thousands of rows. Use `.paginate()` or `.take(n)` with cursor-based pagination. This applies to chat histories, journal entries, and any growing dataset.

- **Bundle size matters: audit regularly, tree-shake aggressively.** Every kilobyte ships to every user. Audit the bundle with `vite-bundle-visualizer` regularly. Prefer focused imports (`import { Button } from "@radix-ui/react-button"`) over barrel imports. Question every new dependency.

- **Measure before optimizing — no premature optimization.** Gut feelings about performance are usually wrong. Use Lighthouse, React DevTools Profiler, and Xcode Instruments to identify actual bottlenecks. Optimize what's measured, not what's assumed.

---

## 5. Code Clarity Over Cleverness

This codebase will be read far more than it's written. Every abstraction, every pattern, every name should make the next reader's job easier — whether that reader is a teammate, a new hire, or you in three months.

- **Self-documenting code with clear naming conventions.** `getUserBirthChart` is better than `fetchData`. `isSubscriptionActive` is better than `check`. Names should reveal intent. If you need a comment to explain what a function does, rename the function.

- **One function, one job — small, composable units.** Functions should do one thing well. A Convex mutation that validates input, transforms data, writes to three tables, and sends a notification is four functions pretending to be one. Break it apart. Compose the pieces.

- **Comments explain "why", not "what".** `// increment counter` above `counter++` is noise. `// We retry 3 times because the astrology API has transient 503s during peak hours` is valuable context that the code alone can't convey.

- **Consistent patterns across all repos.** The web app, marketing site, and iOS app should feel like they were written by one team with shared standards. Consistent file naming, consistent error handling patterns, consistent approaches to state management. When a developer switches repos, the patterns should feel familiar.

- **If it's hard to understand, it's wrong.** Clever one-liners, deeply nested ternaries, and "elegant" abstractions that require a PhD to parse — these aren't signs of skill, they're signs of self-indulgence. Write code that a tired developer at 2am can read, understand, and safely modify.

---

## 6. Ship Fast, Ship Safe

We're early-stage. Speed matters. But shipping broken code doesn't save time — it costs more in hotfixes, user trust, and team morale. The goal is sustainable velocity: ship quickly *because* the guardrails are strong.

- **CI must pass before merge — no exceptions.** Lint checks (Biome), type checks, and tests all run in CI. A red build means the PR waits. "It works on my machine" is not a valid merge criterion. This is the one gate that never gets bypassed.

- **Feature flags for risky changes.** Big features, new AI behaviors, and pricing changes should ship behind flags. Deploy the code, enable for the team, validate, then roll out to users. This decouples deployment from release and gives us instant rollback.

- **Preview deployments for every PR.** Vercel preview deploys (marketing site) and equivalent staging environments (app) let the team see changes in a real environment before merge. Code review alone can't catch layout issues, broken flows, or integration failures.

- **Rollback plans for every production deploy.** Before deploying, know exactly how to undo it. For Convex, this means understanding migration reversibility. For the iOS app, this means respecting App Store review timelines. If you can't roll back, you can't ship safely.

- **Test the critical path.** We're not chasing 100% coverage. We're protecting the paths that matter: authentication, data integrity, AI response handling, payment flows, and user data operations. A bug in a tooltip is annoying; a bug in auth is catastrophic.

---

## 7. Privacy by Design

Pearl is an app people use for self-reflection, spiritual exploration, and personal growth. The conversations and data they share are deeply personal. Privacy isn't a compliance checkbox — it's a core product promise.

- **Collect only what's needed.** Every field in the database should justify its existence. We need birth date and location for chart calculations — we don't need to store them in five different places. Minimize data surface area.

- **Delete user data completely on account deletion.** When a user says "delete my account," we mean it. All personal data — conversations, charts, preferences, everything — gets purged. Not soft-deleted, not archived. Gone. Build deletion into the data model from the start, not as an afterthought.

- **Never log PII.** Emails, birth dates, birth locations, conversation content — none of it belongs in log files, Sentry breadcrumbs, or analytics events. Scrub before logging. If you need to debug a user issue, use anonymized identifiers, not personal data.

- **GDPR/CCPA compliance from day one.** Don't wait until we have European users to care about data rights. Build the infrastructure now: data export, consent management, clear privacy policies, and documented data flows. Retrofitting compliance is ten times harder than building it in.

- **User owns their data — export must be possible.** Users should be able to request a complete export of everything we store about them. This isn't just legal compliance; it's the right relationship to have with the people who trust us.

---

## 8. AI Safety

Pearl is an AI companion that guides people through personal and spiritual topics. That's a profound responsibility. The AI's behavior directly impacts people's wellbeing, and guardrails aren't limitations — they're how we earn and keep trust.

- **Pearl must stay in character and within its boundaries.** The AI has a defined persona, tone, and scope. It should never pretend to be a therapist, give medical advice, or stray into areas where it could cause harm. Character boundaries are product decisions, enforced in code.

- **Never expose raw model outputs without guardrails.** LLM outputs are unpredictable. Every response passes through validation before reaching the user. This includes checking for off-topic content, harmful suggestions, and prompt injection artifacts. The model is a tool; our code is the product.

- **Rate limit AI calls to prevent abuse and cost overruns.** AI API calls are expensive and exploitable. Per-user rate limits prevent both abuse and runaway costs. Set hard ceilings on daily token usage per user. Alert when spending patterns change unexpectedly.

- **Monitor AI costs and usage daily.** Track token usage, cost per conversation, and total spend as core operational metrics. Set up alerts for anomalies. A prompt change that doubles token usage should be caught in hours, not at end-of-month billing.

- **Prompt injection protection on all user inputs to AI.** Users will — accidentally or deliberately — try to manipulate the AI through crafted inputs. Sanitize user content before it enters prompts. Use system-level instructions that resist override. Test adversarial inputs regularly. Assume every user message is potentially hostile.

---

## Living Document

These principles aren't static. As InnerPearl grows, our understanding deepens. When you encounter a situation these principles don't cover, or when a principle needs revision, open a PR. The best engineering cultures evolve their standards as they learn.

*What matters most: the people who use Pearl trust us with something personal. Every principle here serves that trust.*
