# InnerPearl Engineering Skills

> Practical handbook for contributing to InnerPearl — a spiritual/wellness AI platform.
> Pick up this file and start shipping.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Development Setup](#2-development-setup)
3. [Code Style & Linting](#3-code-style--linting)
4. [Writing Convex Functions (Backend)](#4-writing-convex-functions-backend)
5. [Writing React Components (Web)](#5-writing-react-components-web)
6. [Writing Swift Code (iOS)](#6-writing-swift-code-ios)
7. [Authentication](#7-authentication)
8. [Testing Strategy](#8-testing-strategy)
9. [Deployment](#9-deployment)
10. [Error Handling](#10-error-handling)
11. [Security Checklist](#11-security-checklist)
12. [Git Workflow](#12-git-workflow)
13. [Monitoring & Observability](#13-monitoring--observability)

---

## 1. Architecture Overview

InnerPearl lives across three repositories:

| Repo | Stack | Purpose |
|------|-------|---------|
| `pearl-app` | React 19 + Vite 7 + Convex + TypeScript | Main web app + backend |
| `innerpearl` | Next.js 14 + Tailwind + Vercel Analytics | Marketing site (innerpearl.ai) |
| `pearl-ios` | Swift 5.9 + SwiftUI + XcodeGen | Native iOS app |

**Core engine pipeline:**
```
Birth Data → Swiss Ephemeris (astronomy-engine) → Natal Chart
  → Life Purpose Engine → Cosmic Fingerprint
  → Oracle AI (Anthropic Claude) → Readings & Conversations
```

**Four spiritual systems:**
1. **Astrology** — real Swiss Ephemeris calculations (astronomy-engine library)
2. **Human Design** — real astronomical calculations (88° solar arc, gate/line)
3. **Kabbalah** — Tree of Life numerological mapping
4. **Numerology** — standard Western numerology

**Database tables (Convex):**
- `users`, `authAccounts`, `authSessions` (Convex Auth)
- `userProfiles` — birth data, onboarding state
- `cosmicProfiles` — unified four-system snapshot
- `natalCharts` — full ephemeris-calculated chart
- `lifePurposeProfiles` — career/purpose engine output
- `readings` — generated readings (daily_brief, life_purpose, weekly, transit)
- `conversations` / `messages` — Oracle chat history
- `featureFlags` — admin-controlled feature flags

---

## 2. Development Setup

### pearl-app (Web + Backend)

```bash
# Clone and install
git clone <pearl-app-repo>
cd pearl-app
bun install

# Start dev server (Vite + Convex)
# Terminal 1: Frontend
bun dev

# Terminal 2: Convex backend (syncs schema + functions)
bunx convex dev
```

**Required environment variables** (set via Convex dashboard or `.env.local`):

```bash
# .env.local (frontend — must be prefixed with VITE_)
VITE_CONVEX_URL=https://your-deployment.convex.cloud
VITE_SENTRY_DSN=https://xxx@sentry.io/xxx
VITE_IS_PREVIEW=false              # "true" enables test user login
VITE_VERCEL_GIT_COMMIT_SHA=dev     # auto-set by Vercel

# Convex environment variables (set via `bunx convex env set KEY VALUE`)
ANTHROPIC_API_KEY=sk-ant-...       # Claude API for Oracle/readings
AUTH_PRIVATE_KEY=...               # Convex Auth signing key
JWT_PRIVATE_KEY=...                # JWT signing key
```

**Key scripts:**

```bash
bun run dev          # Start Vite dev server
bun run check        # Biome check (lint + format)
bun run format       # Biome auto-fix
bun run typecheck    # TypeScript --noEmit
bun run sync         # One-shot Convex schema sync
bun run sync:build   # Sync + Vite build
bun run logs         # Tail Convex function logs
bun run test         # Run test suite
bun run screenshot   # Playwright screenshot tests
```

### innerpearl (Marketing Site)

```bash
git clone <innerpearl-repo>
cd innerpearl
bun install
bun dev              # Next.js dev server on :3000
```

No environment variables required for local dev. Vercel Analytics auto-activates on deploy.

### pearl-ios (iOS App)

```bash
git clone <pearl-ios-repo>
cd pearl-ios

# Generate Xcode project from project.yml
xcodegen generate

# Open in Xcode
open Pearl.xcodeproj

# Or run tests from CLI
bundle install
bundle exec fastlane test
```

**Requirements:** Xcode 15+, iOS 17+ target, Swift 5.9

**Environment variables** (set in Xcode scheme → Arguments → Environment Variables):
```
ANTHROPIC_API_KEY=sk-ant-...
ASTROLOGY_API_KEY=...
SENTRY_DSN=https://...@sentry.io/...
```

> ⚠️ Never commit API keys. In production, keys should come from a secure backend or Keychain.

---

## 3. Code Style & Linting

### Biome (pearl-app)

Biome handles both linting and formatting. Config lives in `biome.json`.

```bash
bun run check        # Check everything (lint + format)
bun run format       # Auto-fix everything
bun run lint         # Lint only (no format fixes)
```

**Key rules:**

| Setting | Value |
|---------|-------|
| Indent | 2 spaces |
| Quote style | Double quotes (`"`) |
| Line width | 80 characters |
| Arrow parens | As needed (`x => x` not `(x) => x`) |
| Import organization | Auto (Biome assist) |
| Unused imports | Warn |
| Exhaustive deps | Warn |
| `noExplicitAny` | Off (pragmatic — use sparingly) |
| `noNonNullAssertion` | Off |
| a11y rules | Mostly off (spiritual UI uses custom interactions) |

**Import order** (auto-organized by Biome):
```typescript
// 1. External packages
import { useQuery } from "convex/react";
import { useState } from "react";

// 2. Internal aliases (@/)
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

// 3. Relative imports
import { api } from "../../convex/_generated/api";
```

### Naming Conventions

| Thing | Convention | Example |
|-------|-----------|---------|
| Files (components) | PascalCase.tsx | `DashboardPage.tsx` |
| Files (utils/hooks) | camelCase.ts | `useSpeechRecognition.ts` |
| Files (Convex) | camelCase.ts | `profiles.ts`, `oracle.ts` |
| Components | PascalCase | `ProtectedRoute`, `OraclePage` |
| Hooks | `use` prefix | `useMobile`, `useComposition` |
| Types/Interfaces | PascalCase | `NatalChart`, `HDChart` |
| Constants | UPPER_SNAKE | `ADMIN_DOMAIN`, `SIGNS` |
| Variables | camelCase | `birthDate`, `sunSign` |
| Convex functions | camelCase | `getUserProfile`, `saveOnboarding` |
| CSS classes | kebab-case | `pearl-void`, `sacred-breathe` |
| Feature flag keys | snake_case | `oracle_v2` |

### Path Aliases

```typescript
// Use @/ for src/ imports
import { Button } from "@/components/ui/button";
import { captureError } from "@/lib/sentry";

// Configured in tsconfig.json:
// "@/*": ["./src/*"]
```

---

## 4. Writing Convex Functions (Backend)

All backend code lives in the `convex/` directory. Convex functions are the API layer — there is no separate REST API.

### Query Pattern (Read Data)

Every query that returns user data MUST check auth and scope by `userId`:

```typescript
import { getAuthUserId } from "@convex-dev/auth/server";
import { v } from "convex/values";
import { query } from "./_generated/server";

export const getUserProfile = query({
  args: {},
  handler: async (ctx) => {
    const userId = await getAuthUserId(ctx);
    if (!userId) return null;

    return await ctx.db
      .query("userProfiles")
      .withIndex("by_userId", (q) => q.eq("userId", userId))
      .first();
  },
});
```

**Rules:**
- Return `null` or `[]` for unauthenticated users (don't throw — queries re-run reactively)
- ALWAYS use `.withIndex()` — NEVER do unbounded `.collect()` on user-facing queries
- Use `.take(N)` to limit results when appropriate
- Queries are cached and reactive — keep them pure (no side effects)

### Mutation Pattern (Write Data)

Mutations MUST validate input, check auth, and throw on failure:

```typescript
export const saveOnboarding = mutation({
  args: {
    displayName: v.string(),
    birthDate: v.string(),       // YYYY-MM-DD
    birthTime: v.optional(v.string()),
    birthTimeKnown: v.boolean(),
    birthCity: v.string(),
    birthCountry: v.string(),
    birthLat: v.optional(v.number()),
    birthLng: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    const userId = await getAuthUserId(ctx);
    if (!userId) throw new Error("Not authenticated");

    // Upsert pattern: check existing, then patch or insert
    const existing = await ctx.db
      .query("userProfiles")
      .withIndex("by_userId", (q) => q.eq("userId", userId))
      .first();

    if (existing) {
      await ctx.db.patch(existing._id, {
        ...args,
        onboardingComplete: true,
      });
      return existing._id;
    }

    return await ctx.db.insert("userProfiles", {
      userId,
      ...args,
      onboardingComplete: true,
      createdAt: Date.now(),
    });
  },
});
```

**Rules:**
- Always `throw new Error("Human-readable message")` on auth failure
- Use Convex validators (`v.string()`, `v.number()`, `v.id("tableName")`, etc.)
- Mutations are transactional — if they throw, nothing is written
- Always use `Date.now()` for timestamps (not `new Date()`)

### Action Pattern (Side Effects)

Actions can call external APIs (AI, geocoding) and schedule internal mutations:

```typescript
import { action, internalMutation } from "./_generated/server";
import { internal } from "./_generated/api";

export const generateReading = action({
  args: { type: v.string() },
  handler: async (ctx, { type }) => {
    const userId = await getAuthUserId(ctx);
    if (!userId) throw new Error("Not authenticated");

    // Read data via internal query
    const profile = await ctx.runQuery(
      internal.profiles.getUserProfileInternal,
      { userId }
    );

    // Call external API (Anthropic Claude)
    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": process.env.ANTHROPIC_API_KEY!,
        "content-type": "application/json",
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({ /* ... */ }),
    });

    const result = await response.json();

    // Write via internal mutation (actions can't write directly)
    await ctx.runMutation(internal.readings.saveReadingInternal, {
      userId,
      type,
      content: result.content[0].text,
    });
  },
});
```

**Rules:**
- Actions CAN'T read/write the database directly — use `ctx.runQuery()` and `ctx.runMutation()`
- Use `internal.*` for system-only functions called from actions
- Actions are NOT transactional — handle errors carefully
- All external API calls (Anthropic, geocoding) go in actions

### Internal Functions (System Tasks)

Internal functions are NOT exposed to clients — only callable from other server-side code:

```typescript
import { internalQuery, internalMutation } from "./_generated/server";

export const getUserProfileInternal = internalQuery({
  args: { userId: v.id("users") },
  handler: async (ctx, { userId }) => {
    return await ctx.db
      .query("userProfiles")
      .withIndex("by_userId", (q) => q.eq("userId", userId))
      .first();
  },
});

export const saveReadingInternal = internalMutation({
  args: {
    userId: v.id("users"),
    type: v.string(),
    content: v.string(),
  },
  handler: async (ctx, args) => {
    await ctx.db.insert("readings", {
      ...args,
      title: args.type,
      date: new Date().toISOString().split("T")[0],
      createdAt: Date.now(),
    });
  },
});
```

**When to use internal vs public:**
- `query` / `mutation` — called from React frontend
- `internalQuery` / `internalMutation` — called from actions or other server code
- `action` — called from frontend when external APIs are needed
- `internalAction` — system tasks (seeding, cleanup, scheduled jobs)

### Admin Pattern

Admin functions check for `@innerpearl.ai` email domain:

```typescript
const ADMIN_DOMAIN = "innerpearl.ai";

async function requireAdmin(ctx: any): Promise<{ userId: any; email: string }> {
  const userId = await getAuthUserId(ctx);
  if (!userId) throw new Error("Not authenticated");

  const user = await ctx.db.get(userId);
  if (!user?.email) throw new Error("No email found");

  const domain = user.email.split("@")[1]?.toLowerCase();
  if (domain !== ADMIN_DOMAIN) throw new Error("Admin access required");

  return { userId, email: user.email };
}

// Usage:
export const getDashboardStats = query({
  args: {},
  handler: async (ctx) => {
    await requireAdmin(ctx); // Throws if not admin
    // ... admin-only logic
  },
});
```

### Schema & Indexes

Every table with user-scoped data MUST have a `by_userId` index:

```typescript
// convex/schema.ts
import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

const schema = defineSchema({
  ...authTables, // Required for @convex-dev/auth

  userProfiles: defineTable({
    userId: v.id("users"),
    displayName: v.string(),
    birthDate: v.string(),
    // ...
  }).index("by_userId", ["userId"]),

  readings: defineTable({
    userId: v.id("users"),
    type: v.string(),
    date: v.string(),
    // ...
  })
    .index("by_userId", ["userId"])
    .index("by_userId_type", ["userId", "type"])
    .index("by_userId_date", ["userId", "date"]),
});
```

**Index rules:**
- Always query with `.withIndex()` — never rely on `.filter()` for large tables
- Compound indexes (like `by_userId_type`) let you query both fields efficiently
- Adding an index requires a schema push (`bunx convex dev`)

---

## 5. Writing React Components (Web)

### Component Structure

All components are functional (except the ErrorBoundary class component). Example page:

```typescript
// src/pages/DashboardPage.tsx
import { useQuery } from "convex/react";
import { api } from "../../convex/_generated/api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";

export function DashboardPage() {
  const profile = useQuery(api.profiles.getUserProfile);
  const cosmic = useQuery(api.profiles.getCosmicProfile);

  if (profile === undefined) {
    return <DashboardSkeleton />;  // Loading state
  }

  return (
    <div className="space-y-6 p-6">
      <h1 className="text-2xl font-display">
        Welcome, {profile?.displayName}
      </h1>
      {cosmic && (
        <Card>
          <CardHeader>
            <CardTitle>Your Cosmic Profile</CardTitle>
          </CardHeader>
          <CardContent>
            <p>Sun: {cosmic.sunSign} | Moon: {cosmic.moonSign}</p>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
```

### Convex Hooks

```typescript
import { useQuery, useMutation, useAction } from "convex/react";
import { useConvexAuth } from "convex/react";
import { api } from "../../convex/_generated/api";

// Reading data (reactive — auto-updates)
const profile = useQuery(api.profiles.getUserProfile);
// Returns: data | undefined (loading) | null (from handler)

// Conditional query (skip when not authenticated)
const { isAuthenticated } = useConvexAuth();
const data = useQuery(api.some.query, isAuthenticated ? {} : "skip");

// Writing data
const saveOnboarding = useMutation(api.profiles.saveOnboarding);
await saveOnboarding({
  displayName: "Alice",
  birthDate: "1990-01-15",
  // ...
});

// Calling external APIs (actions)
const generate = useAction(api.pearl.generateCosmicProfile);
await generate();
```

### UI Components

We use shadcn/ui (New York style) built on Radix primitives. 53 components available in `src/components/ui/`:

```typescript
// DO: Use shadcn primitives
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Dialog, DialogContent, DialogTrigger } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

// Add new shadcn components:
bunx shadcn@latest add [component-name]
```

**Available components:** accordion, alert, alert-dialog, aspect-ratio, avatar, badge, breadcrumb, button, button-group, calendar, card, carousel, chart, checkbox, collapsible, command, context-menu, dialog, drawer, dropdown-menu, empty, field, form, hover-card, input, input-group, input-otp, item, kbd, label, menubar, navigation-menu, pagination, popover, progress, radio-group, resizable, scroll-area, select, separator, sheet, sidebar, skeleton, slider, sonner (toasts), spinner, switch, table, tabs, textarea, toggle, toggle-group, tooltip.

### Route Protection

```typescript
// Protected route (requires auth + onboarding)
<Route element={<ProtectedRoute />}>
  <Route element={<AppLayout />}>
    <Route path="/dashboard" element={<DashboardPage />} />
  </Route>
</Route>

// Admin route (requires @innerpearl.ai email)
<Route element={<AdminRoute />}>
  <Route path="/admin" element={<AdminDashboardPage />} />
</Route>

// Public-only route (redirects if already logged in)
<Route element={<PublicOnlyRoute />}>
  <Route path="/login" element={<LoginPage />} />
</Route>
```

### Forms

Use react-hook-form + zod for form validation:

```typescript
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";

const schema = z.object({
  displayName: z.string().min(2, "Name must be at least 2 characters"),
  birthDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Use YYYY-MM-DD format"),
});

type FormData = z.infer<typeof schema>;

function OnboardingForm() {
  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  const saveOnboarding = useMutation(api.profiles.saveOnboarding);

  const onSubmit = async (data: FormData) => {
    await saveOnboarding(data);
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <Input {...register("displayName")} />
      {errors.displayName && <p>{errors.displayName.message}</p>}
    </form>
  );
}
```

### Animations

Use framer-motion for animations:

```typescript
import { motion, AnimatePresence } from "framer-motion";

<AnimatePresence>
  {isVisible && (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
    >
      Content
    </motion.div>
  )}
</AnimatePresence>
```

### Toasts

Use sonner for toast notifications:

```typescript
import { toast } from "sonner";

toast.success("Profile saved!");
toast.error("Something went wrong");
toast.loading("Generating your reading...");
```

---

## 6. Writing Swift Code (iOS)

### Architecture: MVVM

```
Views/           → SwiftUI views (UI only)
ViewModels/      → @ObservableObject classes (state + logic)
Services/        → Stateless utilities (API calls, calculations)
Models/          → Data structures (Codable structs)
Design/          → Colors, fonts, reusable components
Configuration/   → AppConfig (environment, API keys)
```

### ViewModel Pattern

```swift
@MainActor
class DashboardViewModel: ObservableObject {
    @Published var fingerprint: CosmicFingerprint?
    @Published var isLoading: Bool = false

    func loadData() {
        self.fingerprint = FingerprintStore.shared.currentFingerprint
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // async work...
        } catch {
            CrashReporting.captureError(error)
        }
    }
}
```

**Rules:**
- Always annotate ViewModels with `@MainActor`
- Use `@Published` for observable state
- Use `async/await` for all async work (no completion handlers)
- Catch errors and report via `CrashReporting.captureError()`

### View Pattern

```swift
struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        ScrollView {
            if let fp = viewModel.fingerprint {
                Text("Sun: \(fp.astrology.sunSign.displayName)")
            }
        }
        .task {
            viewModel.loadData()
        }
    }
}
```

### Keychain Storage

**NEVER use UserDefaults for sensitive data.** Always use Keychain:

```swift
// ✅ Correct — Keychain for credentials
func saveToKeychain(key: String, value: String) {
    let data = value.data(using: .utf8)!
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecValueData as String: data
    ]
    SecItemDelete(query as CFDictionary)
    SecItemAdd(query as CFDictionary, nil)
}

// ❌ Wrong — UserDefaults for tokens/keys
UserDefaults.standard.set(token, forKey: "auth_token")
```

### Design System

Pearl has a custom design system in `Pearl/Design/`:

```swift
// Colors (PearlColors.swift)
Color.pearlGold       // Primary accent
Color.pearlVoid       // Dark background
Color.pearlMuted      // Secondary text

// Fonts (PearlFonts.swift)
.font(.pearlHeading)
.font(.pearlBody)

// Components
PearlButton(title: "Continue") { action() }
PearlCard { content }
CosmicBackground()    // Animated star field
```

---

## 7. Authentication

### Web: Convex Auth

The web app uses `@convex-dev/auth` with two providers:

1. **Password** — email/password with email verification (via ViktorSpaces email)
2. **TestCredentials** — `@test.local` / `@innerpearl.ai` emails for dev/preview

```typescript
// Frontend: Sign in
import { useAuthActions } from "@convex-dev/auth/react";

const { signIn } = useAuthActions();
const formData = new FormData();
formData.set("email", email);
formData.set("password", password);
formData.set("flow", "signIn"); // or "signUp"
await signIn("password", formData);

// Frontend: Check auth state
import { useConvexAuth } from "convex/react";
const { isAuthenticated, isLoading } = useConvexAuth();

// Backend: Get current user
import { getAuthUserId } from "@convex-dev/auth/server";
const userId = await getAuthUserId(ctx);
```

### Test Users (Preview Only)

Test login is gated behind the `VITE_IS_PREVIEW` environment variable:

```typescript
// Only shown when VITE_IS_PREVIEW=true
const isPreview = import.meta.env.VITE_IS_PREVIEW === "true";
if (!isPreview) return null;

// Test credentials:
// Email: agent@test.local
// Password: TestAgent123!
```

The `TestCredentials` provider only accepts `@test.local` and `@innerpearl.ai` domains.

### iOS: Sign in with Apple

```swift
// AuthService.swift handles the full flow:
func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
    // 1. Get Apple ID credential
    // 2. Save userId to Keychain
    // 3. Set isAuthenticated = true
}

// Session check on launch:
func checkExistingSession() {
    // Reads from Keychain → verifies credential state with Apple
}
```

### Admin Access

Admin = `@innerpearl.ai` email domain. Checked server-side:

```typescript
// Backend check
const domain = user.email.split("@")[1]?.toLowerCase();
if (domain !== "innerpearl.ai") throw new Error("Admin access required");

// Frontend route guard
<Route element={<AdminRoute />}>
  <Route path="/admin" element={<AdminDashboardPage />} />
</Route>
```

---

## 8. Testing Strategy

### Unit Tests (Pure Functions)

Test ephemeris calculations, numerology, and pure logic:

```bash
bun run test         # Run all tests
bun run test:auth    # Test auth flow
bun run test:demo    # Run demo test
```

Test files live in `scripts/`:
- `test.ts` — main test runner
- `test-hd-engine.ts` — Human Design calculation tests
- `test-full-flow.ts` — end-to-end flow test
- `test-onboarding.ts` — onboarding flow test

### Integration Tests (Convex)

Test backend flows using the seeded test user:

```typescript
// convex/seedTestUser.ts — creates agent@test.local
// Use: bunx convex run seedTestUser:seedTestUser

// Then test a full flow:
// 1. Sign in as test user
// 2. Complete onboarding
// 3. Generate cosmic profile
// 4. Create a reading
```

### Screenshot Tests (Playwright)

Automated visual testing via Playwright:

```bash
bun run screenshot   # scripts/screenshot.ts
```

Screenshots are saved to `screenshots/` directory. Useful for visual regression and PR reviews.

### iOS Tests

```bash
cd pearl-ios
bundle exec fastlane test
```

Tests in `PearlTests/` (unit) and `PearlUITests/` (UI):
- XCTest for unit tests
- XCUITest for UI automation
- Fastlane orchestrates test runs with code coverage

---

## 9. Deployment

### pearl-app (Web + Backend)

**Automatic deployment:**
1. Push to `main` → Vercel auto-deploys frontend
2. Convex syncs automatically (schema + functions)

**Preview deployments:**
- Every PR gets a unique Vercel preview URL
- Preview Convex deployment with `VITE_IS_PREVIEW=true`

**Manual sync:**
```bash
bun run sync         # One-shot Convex push
bun run sync:build   # Sync + build (for CI)
```

**Vercel configuration** (`vercel.json`):
```json
{
  "rewrites": [
    { "source": "/((?!assets/).*)", "destination": "/index.html" }
  ]
}
```

This ensures all routes (SPA) are handled by `index.html` except static assets.

### innerpearl (Marketing Site)

Push to `main` → Vercel auto-deploys. Next.js 14 with static generation.

### pearl-ios

```bash
cd pearl-ios

# Run tests
bundle exec fastlane test

# Build (no signing)
bundle exec fastlane build

# Deploy to TestFlight (when signing is configured)
bundle exec fastlane beta
```

Fastlane lanes:
- `test` — run all tests with code coverage
- `build` — build without signing (CI validation)
- `beta` — archive + upload to TestFlight

---

## 10. Error Handling

### Frontend (React)

```typescript
// Route-level: ErrorBoundary wraps the entire app
<ErrorBoundary>
  <ThemeProvider>
    <Routes>...</Routes>
  </ThemeProvider>
</ErrorBoundary>

// ErrorBoundary catches render errors → reports to Sentry
componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
  Sentry.captureException(error, {
    extra: { componentStack: errorInfo.componentStack },
  });
}

// Manual error capture anywhere:
import { captureError } from "@/lib/sentry";
try {
  await riskyOperation();
} catch (error) {
  captureError(error as Error, { context: "reading_generation" });
  toast.error("Something went wrong. Please try again.");
}
```

### Backend (Convex)

```typescript
// Throw human-readable errors — they surface in the client
handler: async (ctx, args) => {
  const userId = await getAuthUserId(ctx);
  if (!userId) throw new Error("Not authenticated");

  const profile = await ctx.db.query("userProfiles")
    .withIndex("by_userId", q => q.eq("userId", userId))
    .first();
  if (!profile) throw new Error("Please complete onboarding first");

  // Convex automatically rolls back on throw (mutations are transactional)
};
```

### iOS (Swift)

```swift
do {
    let result = try await engine.generate()
    // success
} catch {
    CrashReporting.captureError(error, context: [
        "operation": "generate_fingerprint",
        "user": userId
    ])
    // Show user-friendly error
}
```

**Never expose stack traces to users in production.** Show friendly messages and log details to Sentry.

---

## 11. Security Checklist

Run through this for every PR:

- [ ] **Auth checks** — All new query/mutation/action handlers verify `getAuthUserId(ctx)`
- [ ] **No hardcoded secrets** — No API keys, tokens, or passwords in source code
- [ ] **User data scoped** — Queries filter by `userId`; users can't access other users' data
- [ ] **Input validated** — All args use Convex validators (`v.string()`, `v.number()`, `v.id()`)
- [ ] **No sensitive logs** — No `console.log` with tokens, passwords, or PII
- [ ] **Admin functions** — Use `requireAdmin()` for any admin-only endpoints
- [ ] **Rate limiting** — Consider limiting AI endpoints (Anthropic calls are expensive)
- [ ] **Keychain (iOS)** — Sensitive data stored in Keychain, NEVER UserDefaults
- [ ] **CORS** — Convex handles this automatically; don't add custom CORS headers
- [ ] **Environment separation** — Preview/staging use separate Convex deployments

### Auth Pattern Reference

```typescript
// ✅ Correct: query returns null for unauth
export const getProfile = query({
  handler: async (ctx) => {
    const userId = await getAuthUserId(ctx);
    if (!userId) return null;
    return await ctx.db.query("userProfiles")
      .withIndex("by_userId", q => q.eq("userId", userId))
      .first();
  },
});

// ✅ Correct: mutation throws for unauth
export const saveProfile = mutation({
  handler: async (ctx, args) => {
    const userId = await getAuthUserId(ctx);
    if (!userId) throw new Error("Not authenticated");
    // ...
  },
});

// ❌ Wrong: no auth check
export const getAllProfiles = query({
  handler: async (ctx) => {
    return await ctx.db.query("userProfiles").collect(); // Exposes ALL users!
  },
});

// ❌ Wrong: no userId scope
export const getReading = query({
  args: { readingId: v.id("readings") },
  handler: async (ctx, { readingId }) => {
    return await ctx.db.get(readingId); // Could read ANY user's reading!
  },
});
```

---

## 12. Git Workflow

### Branch Naming

```
feature/oracle-voice-input
fix/natal-chart-calculation
chore/update-dependencies
refactor/auth-flow
```

### Commit Messages

Use conventional commits:

```
feat: add voice input to Oracle chat
fix: correct moon sign calculation for southern hemisphere
chore: update astronomy-engine to 2.1.19
refactor: extract ephemeris helpers into separate module
docs: add SKILLS.md engineering handbook
test: add Human Design engine unit tests
```

### PR Process

1. Create feature branch from `main`
2. Make changes, run checks locally:
   ```bash
   bun run check      # Biome lint + format
   bun run typecheck   # TypeScript
   bun run test        # Tests
   ```
3. Push branch → PR is created → Vercel preview deploys
4. CI must pass (typecheck + lint + build)
5. Request review
6. Squash merge to `main`
7. Vercel auto-deploys production

### Rules

- Never force push to `main`
- Always squash merge PRs (clean history)
- Delete branches after merge
- Keep PRs focused — one feature/fix per PR

---

## 13. Monitoring & Observability

### Sentry (Error Tracking)

**Web (`@sentry/react`):**
- Auto-captures unhandled errors via ErrorBoundary
- Performance monitoring: 100% dev, 20% production
- Session replay: 10% sessions, 100% on error
- Release tagged with git SHA for source map matching

```typescript
// Manual capture
import { captureError, addBreadcrumb } from "@/lib/sentry";
addBreadcrumb("oracle", "User asked question", { length: question.length });
captureError(new Error("AI generation failed"), { model: "claude-3" });
```

**iOS (`sentry-cocoa`):**
- Crash reporting + ANR detection
- Network breadcrumbs (API calls auto-tracked)
- Pearl-specific tracking: onboarding, fingerprint generation, chat messages

```swift
CrashReporting.trackScreen("Dashboard")
CrashReporting.trackAction("chat_message_sent", data: ["voice_input": true])
CrashReporting.captureError(error, context: ["endpoint": "generate"])
```

### Vercel Analytics

- **Web Vitals**: LCP, FID, CLS tracked automatically
- **Speed Insights**: page-level performance data
- Enabled via `@vercel/analytics` (innerpearl marketing site)
- pearl-app uses Sentry browser tracing instead

### Convex Dashboard

- **Function logs**: see every query/mutation/action execution
- **Usage metrics**: database reads, function calls, bandwidth
- **Error logs**: failed function executions with stack traces

```bash
bun run logs         # Tail logs in terminal
# Or visit https://dashboard.convex.dev
```

### Setting Up Alerts

1. **Sentry**: Set alert rules for error spikes (> 10 errors/hour)
2. **Vercel**: Enable deployment failure notifications
3. **Convex**: Monitor function error rates in dashboard

---

## Quick Reference

### File Structure (pearl-app)

```
pearl-app/
├── convex/                  # Backend (Convex functions + schema)
│   ├── schema.ts            # Database schema + indexes
│   ├── auth.ts              # Auth setup (Password + TestCredentials)
│   ├── auth.config.ts       # Auth provider config
│   ├── http.ts              # HTTP routes (auth endpoints)
│   ├── profiles.ts          # User profile queries/mutations
│   ├── pearl.ts             # Core generation engine (actions)
│   ├── oracle.ts            # Conversation queries/mutations
│   ├── readings.ts          # Reading queries
│   ├── admin.ts             # Admin functions (requireAdmin)
│   ├── featureFlags.ts      # Feature flag CRUD
│   ├── ephemeris.ts         # Astronomical calculations
│   ├── humandesign.ts       # Human Design calculations
│   ├── lifePurpose.ts       # Life Purpose engine
│   ├── seedTestUser.ts      # Test user seeder
│   └── _generated/          # Auto-generated (don't edit)
├── src/
│   ├── main.tsx             # Entry point (Sentry init + providers)
│   ├── App.tsx              # Routes + layout
│   ├── index.css            # Tailwind v4 + custom CSS
│   ├── components/
│   │   ├── ui/              # shadcn/ui components (53 components)
│   │   ├── ProtectedRoute.tsx
│   │   ├── AdminRoute.tsx
│   │   ├── ErrorBoundary.tsx
│   │   └── AppLayout.tsx    # Sidebar + main content
│   ├── pages/               # Route pages
│   │   ├── DashboardPage.tsx
│   │   ├── OraclePage.tsx
│   │   ├── BlueprintPage.tsx
│   │   └── admin/           # Admin pages
│   ├── hooks/               # Custom React hooks
│   ├── contexts/            # React contexts (ThemeContext)
│   └── lib/                 # Utilities (sentry, utils, constants)
├── scripts/                 # Test scripts + tooling
├── biome.json               # Linter/formatter config
├── vite.config.ts           # Vite + Sentry + Tailwind
├── components.json          # shadcn/ui config (New York style)
└── package.json             # Dependencies + scripts
```

### File Structure (pearl-ios)

```
pearl-ios/
├── Pearl/
│   ├── PearlApp.swift          # App entry point
│   ├── RootView.swift          # Root navigation
│   ├── Configuration/
│   │   └── AppConfig.swift     # Environment + API keys
│   ├── Models/                 # Data models
│   ├── ViewModels/             # MVVM view models (@MainActor)
│   ├── Views/                  # SwiftUI views
│   │   ├── Chat/
│   │   ├── Dashboard/
│   │   ├── Onboarding/
│   │   ├── Insights/
│   │   └── Profile/
│   ├── Services/               # Business logic
│   │   ├── AuthService.swift
│   │   ├── PearlEngine.swift
│   │   ├── AstrologyService.swift
│   │   ├── CrashReporting.swift
│   │   └── SpeechService.swift
│   └── Design/                 # Design system
│       ├── PearlColors.swift
│       ├── PearlFonts.swift
│       └── Components/
├── PearlTests/                 # Unit tests
├── PearlUITests/               # UI tests
├── fastlane/                   # Fastlane config
├── project.yml                 # XcodeGen project definition
└── Package.swift               # Swift Package Manager
```

### Common Commands Cheat Sheet

```bash
# pearl-app
bun dev                         # Start dev server
bunx convex dev                 # Start Convex backend
bun run check                   # Lint + format check
bun run format                  # Auto-fix lint + format
bun run typecheck               # TypeScript check
bun run test                    # Run tests
bun run screenshot              # Playwright screenshots
bun run sync                    # One-shot Convex sync
bunx convex env list            # List environment variables
bunx convex env set KEY VALUE   # Set environment variable
bunx convex logs                # Tail function logs
bunx shadcn@latest add button   # Add shadcn component

# innerpearl
bun dev                         # Next.js dev server
bun run build                   # Production build
bun run lint                    # Next.js linting

# pearl-ios
xcodegen generate               # Generate Xcode project
bundle exec fastlane test       # Run tests
bundle exec fastlane build      # Build (no signing)
```
