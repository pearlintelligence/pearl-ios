# DESIGN.md — InnerPearl Architecture & Design Decisions

> How the code is organized, why we made these choices, and how to extend it.
>
> Last updated: 2026-03-01

---

## Table of Contents

1. [System Architecture Overview](#1-system-architecture-overview)
2. [Repository Structure](#2-repository-structure)
3. [Frontend Architecture (pearl-app)](#3-frontend-architecture-pearl-app)
4. [Backend Architecture (Convex)](#4-backend-architecture-convex)
5. [iOS Architecture (pearl-ios)](#5-ios-architecture-pearl-ios)
6. [Data Flow Patterns](#6-data-flow-patterns)
7. [Security Architecture](#7-security-architecture)
8. [Naming Conventions](#8-naming-conventions)
9. [Design System](#9-design-system)
10. [Key Design Decisions](#10-key-design-decisions)

---

## 1. System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENTS                                  │
│                                                                 │
│  ┌─────────────────────┐       ┌──────────────────────────┐    │
│  │    pearl-app (Web)   │       │    pearl-ios (Native)     │    │
│  │                      │       │                           │    │
│  │  React 19 + Vite     │       │  SwiftUI + SwiftData      │    │
│  │  Tailwind v4         │       │  Sign in with Apple       │    │
│  │  Radix/shadcn UI     │       │  MVVM architecture        │    │
│  │  @convex-dev/auth    │       │                           │    │
│  └──────────┬───────────┘       └─────────┬─────────────────┘    │
│             │ WebSocket (real-time)        │ Direct API calls    │
└─────────────┼─────────────────────────────┼─────────────────────┘
              │                             │
              ▼                             │
┌─────────────────────────────┐             │
│      Convex Backend         │             │
│                             │             │
│  ┌───────────────────────┐  │             │
│  │  Auth (Password +     │  │             │
│  │  TestCredentials)     │  │             │
│  └───────────────────────┘  │             │
│  ┌───────────────────────┐  │             │
│  │  pearl.ts (AI Engine) │◄─┼─────────────┘ (future: migrate iOS here)
│  │  ├─ ephemeris.ts      │  │
│  │  ├─ humandesign.ts    │  │
│  │  ├─ lifePurpose.ts    │  │
│  │  └─ oracle.ts         │  │
│  └───────────┬───────────┘  │
│  ┌───────────────────────┐  │
│  │  Admin / Feature Flags │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │  Database (Convex DB) │  │
│  └───────────────────────┘  │
└─────────────┬───────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    EXTERNAL SERVICES                            │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐ │
│  │  astronomy-   │  │   Geocoding  │  │   Anthropic Claude    │ │
│  │  engine       │  │   (timezone  │  │   (iOS only, direct)  │ │
│  │  (VSOP87 /   │  │    + coords) │  │                       │ │
│  │   ELP2000)   │  │              │  │   ⚠️ Should migrate   │ │
│  │              │  │              │  │   to Convex backend    │ │
│  └──────────────┘  └──────────────┘  └───────────────────────┘ │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐                            │
│  │   Sentry     │  │   Vercel     │                            │
│  │  (errors +   │  │  (hosting +  │                            │
│  │   replays)   │  │   analytics) │                            │
│  └──────────────┘  └──────────────┘                            │
└─────────────────────────────────────────────────────────────────┘

Marketing Site (innerpearl) — separate Next.js app on Vercel
```

### Data Flow Summary

```
User Birth Data → Swiss Ephemeris Calculations → Natal Chart
                                                      │
                   ┌──────────────────────────────────┤
                   ▼                ▼                  ▼
             Astrology        Human Design       Life Purpose
            (Sun, Moon,      (Type, Auth,       (North Node +
             Rising, etc.)    Profile, Gates)    MC + Saturn)
                   │                │                  │
                   └────────┬───────┘──────────────────┘
                            ▼
                   Kabbalah + Numerology
                   (birth-date mappings)
                            │
                            ▼
                  Cosmic Fingerprint (unified)
                            │
               ┌────────────┼────────────────┐
               ▼            ▼                ▼
          Dashboard     Oracle Chat     Daily Briefs
         (Blueprint)   (contextual)    (transit-aware)
```

---

## 2. Repository Structure

### pearl-app (Primary — Web Application)

| What | Details |
|------|---------|
| **Purpose** | Main product: AI-powered spiritual wellness app |
| **Stack** | React 19 + Vite + Convex + TypeScript (strict) |
| **UI** | Radix primitives + shadcn/ui + Tailwind v4 |
| **Linting** | Biome (replaces ESLint + Prettier) |
| **Deploy** | Vercel (frontend) + Convex Cloud (backend) |
| **Monitoring** | Sentry (errors, performance, session replays) |

```
pearl-app/
├── src/
│   ├── App.tsx              # Route definitions (single file)
│   ├── main.tsx             # Entry point: Sentry → Convex → BrowserRouter
│   ├── pages/               # Route-level components (one per route)
│   │   ├── index.ts         # Barrel export for all pages
│   │   ├── DashboardPage.tsx
│   │   ├── OraclePage.tsx
│   │   ├── BlueprintPage.tsx
│   │   └── admin/           # Admin-only pages
│   ├── components/          # Shared application components
│   │   ├── ProtectedRoute.tsx
│   │   ├── AdminRoute.tsx
│   │   ├── ErrorBoundary.tsx
│   │   ├── AppLayout.tsx    # Sidebar + Outlet wrapper
│   │   └── ui/              # shadcn primitives (DO NOT edit directly)
│   ├── hooks/               # Custom React hooks
│   ├── contexts/            # React context providers (ThemeContext)
│   └── lib/                 # Utilities, constants, Sentry setup
├── convex/                  # Backend (co-located, deployed to Convex Cloud)
│   ├── schema.ts            # Single source of truth for all tables
│   ├── auth.ts              # Auth config (Password + TestCredentials)
│   ├── pearl.ts             # Core AI engine (~660 lines, orchestrates everything)
│   ├── ephemeris.ts         # Swiss Ephemeris calculations (astronomy-engine)
│   ├── humandesign.ts       # Human Design from real astronomical data
│   ├── lifePurpose.ts       # Life Purpose interpretation framework
│   ├── oracle.ts            # Conversation CRUD
│   ├── profiles.ts          # User + Cosmic profile queries/mutations
│   ├── readings.ts          # Reading queries (daily brief, life purpose, etc.)
│   ├── admin.ts             # Admin dashboard, user management, analytics
│   ├── featureFlags.ts      # Feature flag CRUD + public isEnabled query
│   └── http.ts              # HTTP router (auth routes only)
└── package.json
```

### innerpearl (Marketing Website)

| What | Details |
|------|---------|
| **Purpose** | Public marketing site with waitlist |
| **Stack** | Next.js 14 (App Router) + Tailwind v3 + TypeScript |
| **Deploy** | Vercel |
| **Analytics** | @vercel/analytics + @vercel/speed-insights |

```
innerpearl/
├── src/
│   ├── app/
│   │   ├── layout.tsx       # Root layout (fonts, metadata)
│   │   ├── page.tsx         # Landing page
│   │   ├── about/page.tsx
│   │   ├── experience/page.tsx
│   │   └── wisdom/page.tsx
│   └── components/
│       ├── Navigation.tsx
│       ├── Footer.tsx
│       ├── WaitlistForm.tsx
│       └── DiamondDivider.tsx
└── package.json
```

### pearl-ios (Native iOS App)

| What | Details |
|------|---------|
| **Purpose** | Native iOS experience |
| **Stack** | Swift + SwiftUI + SwiftData + XcodeGen |
| **Auth** | Sign in with Apple → Keychain storage |
| **AI** | Direct Anthropic API calls (⚠️ should migrate to Convex) |
| **Deploy** | Fastlane → App Store / TestFlight |

```
pearl-ios/
├── Pearl/
│   ├── PearlApp.swift       # @main entry, environment objects
│   ├── RootView.swift       # Onboarding vs MainTabView router
│   ├── Views/               # SwiftUI views, grouped by feature
│   │   ├── Dashboard/
│   │   ├── Chat/
│   │   ├── Insights/
│   │   ├── Onboarding/
│   │   └── Profile/
│   ├── ViewModels/          # ObservableObject classes
│   ├── Services/            # Business logic & external APIs
│   │   ├── AuthService.swift
│   │   ├── PearlEngine.swift   # Claude API integration
│   │   ├── AstrologyService.swift
│   │   ├── HumanDesignService.swift
│   │   ├── KabbalahService.swift
│   │   ├── NumerologyService.swift
│   │   └── LifePurposeEngine.swift
│   ├── Models/              # SwiftData @Model types
│   ├── Design/              # Design system tokens
│   │   ├── PearlColors.swift
│   │   ├── PearlFonts.swift
│   │   └── Components/      # Reusable UI components
│   └── Configuration/
│       └── AppConfig.swift   # Environment, API keys, feature flags
├── PearlTests/
├── PearlUITests/
├── project.yml              # XcodeGen project definition
└── Fastfile                 # Fastlane deployment config
```

### Shared Contracts (No Shared Package — Yet)

The three repos have **no shared code package**. Contracts are implicitly aligned:

- **Schema shape**: iOS models (`UserProfile.swift`, `Conversation.swift`) mirror Convex schema tables
- **API voice**: Pearl's system prompt is duplicated in `PearlEngine.swift` (iOS) and `pearl.ts` (backend)
- **Color tokens**: `PearlColors.swift` (iOS) and Tailwind config (web) define the same palette

> **Tech debt**: Pearl's voice/prompt and cosmic calculation logic should live in one place (the Convex backend). iOS currently calls Anthropic directly — this should be migrated.

---

## 3. Frontend Architecture (pearl-app)

### Route Structure

All routes are defined in a single `App.tsx` using React Router v7. Three layout layers:

```
Routes
├── PublicLayout (no sidebar)
│   ├── /                    → LandingPage
│   ├── PublicOnlyRoute      (redirects authenticated users)
│   │   ├── /login           → LoginPage
│   │   └── /signup          → SignupPage
│
├── /onboarding              → OnboardingPage (protected, no sidebar)
│
├── ProtectedRoute           (requires auth + completed onboarding)
│   └── AppLayout            (sidebar + header)
│       ├── /dashboard       → DashboardPage
│       ├── /blueprint       → BlueprintPage
│       ├── /purpose         → LifePurposePage
│       ├── /transits        → TransitsPage
│       ├── /progressions    → ProgressionsPage
│       ├── /oracle          → OraclePage
│       ├── /reading         → ReadingPage
│       ├── /settings        → SettingsPage
│       │
│       └── AdminRoute       (requires @innerpearl.ai email)
│           ├── /admin           → AdminDashboardPage
│           ├── /admin/flags     → FeatureFlagsPage
│           ├── /admin/users     → UserManagementPage
│           ├── /admin/analytics → AnalyticsPage
│           ├── /admin/billing   → BillingPage
│           └── /admin/tools     → PlatformToolsPage
│
└── /*                       → Redirect to /
```

**No lazy loading currently** — all pages are eagerly imported via barrel exports (`pages/index.ts`). The bundle is small enough that this hasn't been a problem, but `React.lazy()` + `Suspense` is the obvious next step if bundle size grows.

### Component Hierarchy

```
ErrorBoundary (catches all, reports to Sentry)
└── ThemeProvider (dark mode default)
    └── ConvexAuthProvider (WebSocket connection)
        └── BrowserRouter
            └── App (routes)
                ├── PublicLayout → Outlet
                ├── ProtectedRoute → checks auth + onboarding → Outlet
                │   └── AppLayout (AppSidebar + Header + Outlet)
                └── AdminRoute → checks admin domain → Outlet
```

**Four component tiers:**
1. **Pages** (`pages/`) — route-level, fetch data, compose feature components
2. **Layouts** (`AppLayout`, `PublicLayout`) — structural wrappers with navigation
3. **Feature components** (`components/`) — `SignIn`, `SignUp`, `AppSidebar`, `Header`
4. **UI primitives** (`components/ui/`) — shadcn/Radix components, never edited directly

### State Management: Convex Real-Time Queries

**No Redux. No Zustand. No client state library.**

Convex provides real-time reactive queries over WebSocket. Every `useQuery()` call auto-subscribes and re-renders when the underlying data changes. This eliminates the need for client-side state management for server data entirely.

```typescript
// This is all you need — it's live, reactive, and type-safe
const profile = useQuery(api.profiles.getUserProfile);
const cosmic  = useQuery(api.profiles.getCosmicProfile);
const isAdmin = useQuery(api.admin.isAdmin);
```

**Client-only state uses:**
- `ThemeContext` — dark/light mode preference (localStorage-backed)
- `useConvexAuth()` — auth loading/authenticated status (from Convex)
- Component-local `useState` for UI state (modals, form inputs, etc.)

### Auth Flow

```
User → /signup → Password signup (ConvexAuth)
                         │
                         ▼
              Auth session created
                         │
          ┌──────────────┤
          ▼              ▼
    isOnboardingComplete?
     false │           true │
           ▼                ▼
    /onboarding        /dashboard
    (collect birth     (full app)
     data + name)
           │
           ▼
    saveOnboarding()
           │
           ▼
    generateCosmicFingerprint()
           │
           ▼
    Redirect → /dashboard
```

`ProtectedRoute` handles the auth + onboarding gate:
- Not authenticated → redirect to `/login`
- Authenticated but no profile → redirect to `/onboarding`
- Authenticated + onboarding complete → render child routes

### Error Handling

```
ErrorBoundary (class component, wraps entire app)
    │
    ├─ Catches: unhandled React render errors
    ├─ Reports: Sentry.captureException() with componentStack
    └─ Displays: FallbackUI with error stack + reload button

Sentry (initialized before React renders in main.tsx)
    ├─ browserTracingIntegration — route-level performance
    ├─ replayIntegration — session replay on errors (100%)
    ├─ httpClientIntegration — fetch/XHR error tracking
    └─ Filters: ResizeObserver errors excluded (browser noise)
```

---

## 4. Backend Architecture (Convex)

### Function Types

Convex has four function types, and we use all of them:

| Type | Purpose | Can read DB? | Can write DB? | Can call APIs? | How we use it |
|------|---------|:---:|:---:|:---:|---|
| `query` | Real-time reads | ✅ | ❌ | ❌ | `profiles.getUserProfile`, `oracle.getMessages`, `admin.isAdmin` |
| `mutation` | Writes | ✅ | ✅ | ❌ | `profiles.saveOnboarding`, `oracle.addMessage`, `featureFlags.toggle` |
| `action` | Side effects | Via `runQuery` | Via `runMutation` | ✅ | `pearl.generateCosmicFingerprint`, `pearl.askOracle` |
| `internalQuery` / `internalMutation` | Server-only helpers | ✅ | ✅ | ❌ | `oracle.getMessagesInternal`, `pearl.saveNatalChart` |

**Key constraint**: Actions cannot read/write the DB directly. They must call `ctx.runQuery()` / `ctx.runMutation()` to access internal functions. This is by design — actions run in a different execution context.

### Auth Pattern

Every public function starts with authentication:

```typescript
// Standard pattern — every public query/mutation/action
export const getMessages = query({
  args: { conversationId: v.id("conversations") },
  handler: async (ctx, { conversationId }) => {
    const userId = await getAuthUserId(ctx);
    if (!userId) return [];  // or throw new Error("Not authenticated")

    // Verify ownership before returning data
    const conv = await ctx.db.get(conversationId);
    if (!conv || conv.userId !== userId) return [];

    return await ctx.db.query("messages")
      .withIndex("by_conversationId", q => q.eq("conversationId", conversationId))
      .order("asc")
      .collect();
  },
});
```

**Rules:**
1. `getAuthUserId(ctx)` at the top of every public function
2. Return empty / null for queries when not authenticated (don't throw)
3. Throw for mutations / actions when not authenticated
4. Always verify ownership: check `userId` matches before returning/modifying data

### Admin Pattern

Admin authorization is domain-based:

```typescript
const ADMIN_DOMAIN = "innerpearl.ai";

async function requireAdmin(ctx) {
  const userId = await getAuthUserId(ctx);
  if (!userId) throw new Error("Not authenticated");

  const user = await ctx.db.get(userId);
  if (!user?.email) throw new Error("No email found");

  const domain = user.email.split("@")[1]?.toLowerCase();
  if (domain !== ADMIN_DOMAIN) throw new Error("Admin access required");

  return { userId, email: user.email };
}
```

Any user with an `@innerpearl.ai` email is automatically an admin. No roles table, no permission matrix — just domain check. Simple until we need more.

### Schema Design

Single schema file (`convex/schema.ts`). All tables are normalized with `userId` indexes for fast per-user queries.

```
┌─────────────┐    ┌─────────────────┐    ┌────────────────┐
│    users     │◄───│  userProfiles   │    │ cosmicProfiles │
│  (auth)      │    │  (birth data,   │    │ (4-system      │
│              │    │   onboarding)   │    │  fingerprint)  │
└──────┬───────┘    └─────────────────┘    └────────────────┘
       │
       │    ┌─────────────────┐    ┌────────────────────────┐
       ├───►│  natalCharts    │    │  lifePurposeProfiles   │
       │    │  (full Swiss    │    │  (North Node + MC +    │
       │    │   Ephemeris)    │    │   Sun + Saturn derived)│
       │    └─────────────────┘    └────────────────────────┘
       │
       │    ┌─────────────────┐    ┌──────────────┐
       ├───►│  readings       │    │ featureFlags │
       │    │  (daily brief,  │    │ (admin-only  │
       │    │   life purpose, │    │  CRUD)       │
       │    │   transit, etc.)│    └──────────────┘
       │    └─────────────────┘
       │
       │    ┌─────────────────┐    ┌──────────────┐
       └───►│  conversations  │───►│   messages   │
            │  (userId index) │    │ (convId idx) │
            └─────────────────┘    └──────────────┘
```

**Index strategy:**
- Every table with user data has `index("by_userId", ["userId"])`
- `readings` has compound indexes: `by_userId_type` and `by_userId_date`
- `featureFlags` has `index("by_key", ["key"])` for O(1) flag lookups
- `messages` uses `index("by_conversationId", ["conversationId"])`

**Auth tables** are managed by `@convex-dev/auth`: `users`, `authAccounts`, `authSessions`, `authRefreshTokens`, `authVerificationCodes`, `authVerifiers`, `authRateLimits`.

### AI Pipeline (pearl.ts)

`pearl.ts` is the core engine (~660 lines). It orchestrates all four wisdom systems:

```
generateCosmicFingerprint (action)
│
├─ 1. calculateNatalChart()          ← ephemeris.ts (Swiss Ephemeris)
│     └─ geocodeCity() → getTimezone() → birthToUTC() → astronomy-engine
│
├─ 2. saveNatalChart()               ← internal mutation
│
├─ 3. generateLifePurpose()          ← lifePurpose.ts
│     └─ North Node + MC + Sun + Saturn → interpretation tables
│
├─ 4. saveLifePurpose()              ← internal mutation
│
├─ 5. computeSimplifiedSystems()     ← humandesign.ts + inline Kabbalah/Numerology
│     ├─ calculateHDChart()          ← REAL astronomical HD (88° solar arc)
│     ├─ Kabbalah (sephirah mapping from birth date)
│     └─ Numerology (life path, expression, soul numbers)
│
├─ 6. generateFingerprintSummary()   ← prose generation from all systems
│
└─ 7. saveCosmicProfile()            ← internal mutation (legacy compat)
```

**Critical design choice**: All AI text generation is currently **template-based** (no LLM calls from the backend). Pearl's voice is crafted through carefully written interpretation tables and prose templates in `pearl.ts` and `lifePurpose.ts`. The iOS app calls Claude directly for chat, but the web backend generates readings without any external AI API.

**Other actions:**
- `generateDailyBrief` — natal chart + transits + day-of-week energy
- `generateLifePurposeReading` — deep life purpose text
- `askOracle` — contextual response using chart + conversation history
- `getTransits` — current transit aspects to natal chart
- `getProgressions` — secondary progressions (progressed Sun, Moon, Ascendant)

---

## 5. iOS Architecture (pearl-ios)

### MVVM Pattern

```
┌─────────────────────────────────────────────────────┐
│                     PearlApp                         │
│  @main struct, creates environment objects:           │
│  AppState + AuthService + PearlEngine                │
│  + SwiftData ModelContainer                          │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────────────┐
│                   RootView                            │
│  if !onboarding → OnboardingFlow                     │
│  else           → MainTabView                        │
│                     ├── Dashboard (Blueprint)        │
│                     ├── Chat (Pearl)                 │
│                     ├── Insights                     │
│                     └── Profile (You)                │
└──────────────────────────────────────────────────────┘

Views ←→ ViewModels ←→ Services
  │                       │
  │  @Published props     │  Async API calls
  │  @EnvironmentObject   │  Keychain access
  │  User intent methods  │  Calculation engines
  │                       │
  ▼                       ▼
SwiftUI renders       AuthService
                      PearlEngine
                      AstrologyService
                      HumanDesignService
                      KabbalahService
                      NumerologyService
                      LifePurposeEngine
                      SpeechService
```

**ViewModels**: `ChatViewModel`, `DashboardViewModel`, `OnboardingViewModel`, `ProfileViewModel` — all `ObservableObject` with `@Published` properties.

**Services layer**:
- `AuthService` — Sign in with Apple + Keychain credential storage
- `PearlEngine` — Anthropic Claude integration (direct API calls)
- Domain services — astrology, HD, kabbalah, numerology calculations
- `CrashReporting` — Sentry SDK wrapper
- `SpeechService` — speech recognition/synthesis

### Auth: Sign in with Apple

```
User → ASAuthorizationAppleIDCredential
         │
         ├─ Store userId → Keychain
         ├─ Store email → Keychain (if provided)
         ├─ Store name → Keychain (if provided)
         │
         ▼
  On launch: checkExistingSession()
         │
         ├─ Load userId from Keychain
         └─ Verify with ASAuthorizationAppleIDProvider.getCredentialState()
              ├─ .authorized → isAuthenticated = true
              └─ .revoked/.notFound → signOut()
```

### AI: Direct Anthropic (Migration Needed)

The iOS app calls `api.anthropic.com/v1` directly from `PearlEngine.swift`. This works but has problems:

1. **API key in client** — even read from env/Keychain, the key exists on-device
2. **No shared context** — web and iOS conversations are siloed
3. **Duplicated prompt** — Pearl's system prompt is maintained in two places
4. **No rate limiting** — client-side only

**Planned migration**: Route all AI calls through Convex backend actions, unifying the conversation model and removing client-side API keys.

### Design System

iOS has its own design system tokens:

- `PearlColors` — hex-based color palette matching the web theme
- `PearlFonts` — Cormorant Garamond (oracle voice) + DM Sans (UI body)
- `Components/` — `CosmicBackground`, `PearlButton`, `PearlCard`
- View modifiers: `.oracleStyle()`, `.pearlBody()` for consistent typography

---

## 6. Data Flow Patterns

### User Onboarding → Cosmic Profile Generation

```
1. User signs up (password auth)
         │
2. ProtectedRoute detects no profile
         │
3. Redirect → /onboarding
         │
4. User enters: name, birthDate, birthTime, birthCity, birthCountry
         │
5. saveOnboarding() mutation
   └─ Creates/updates userProfiles row (onboardingComplete: true)
         │
6. Frontend calls generateCosmicFingerprint() action
   ├─ Swiss Ephemeris natal chart calculation
   ├─ Real Human Design chart (88° solar arc, planetary gates)
   ├─ Life Purpose generation (North Node + MC + Sun + Saturn)
   ├─ Kabbalah sephirah mapping
   ├─ Numerology life path calculation
   └─ Saves: natalCharts, lifePurposeProfiles, cosmicProfiles
         │
7. Redirect → /dashboard
   └─ useQuery(api.profiles.getCosmicProfile) reactively loads
```

### Oracle Conversation Flow

```
1. User creates conversation
   └─ oracle.createConversation mutation → conversations table
         │
2. User types message
   └─ oracle.addMessage mutation → messages table (role: "user")
         │
3. Frontend calls pearl.askOracle action
   ├─ Loads user profile (internal query)
   ├─ Calculates natal chart (ephemeris)
   ├─ Computes HD + Kabbalah + Numerology
   ├─ Loads last 6 messages for context (internal query)
   ├─ Generates contextual response (template-based, topic-aware)
   └─ Saves oracle response (internal mutation → messages table)
         │
4. useQuery(api.oracle.getMessages) reactively updates UI
```

**Topic detection** in `askOracle`: The oracle examines the user's question for keywords (relationship, career, health, etc.) and selects the appropriate response template, weaving in the user's specific chart placements.

### Feature Flag System

```
Admin creates flag:
  featureFlags.create({ key: "oracle_v2", name: "...", enabled: false })
         │
Admin toggles:
  featureFlags.toggle({ id })  ──→  enabled: true
         │
Frontend checks:
  const isEnabled = useQuery(api.featureFlags.isEnabled, { key: "oracle_v2" });
  if (isEnabled) { /* show new feature */ }
```

Feature flags are **global booleans** — no per-user targeting, no percentage rollouts, no A/B testing. Designed for simple ship/no-ship decisions. Admin-only CRUD.

### Reading Generation Pipeline

All readings follow the same pattern:

```
Frontend calls action (e.g., pearl.generateDailyBrief)
  │
  ├─ 1. Auth check (getAuthUserId)
  ├─ 2. Load profile (internal query)
  ├─ 3. Calculate natal chart (ephemeris)
  ├─ 4. Calculate supplementary systems (HD, KB, NUM)
  ├─ 5. Generate text (template engine)
  ├─ 6. Save reading (internal mutation → readings table)
  └─ 7. Return text to frontend
```

Reading types: `"life_purpose"`, `"daily_brief"`, `"weekly"`, `"transit"`

---

## 7. Security Architecture

> See PRINCIPLES.md for the full security philosophy.

### Authentication Layers

```
Web (pearl-app):
  @convex-dev/auth (Password provider + TestCredentials)
  ├─ Password: email + bcrypt hash
  ├─ TestCredentials: dev-only, test user seeding
  ├─ Sessions: server-managed by Convex
  └─ JWT: signed with AUTH_PRIVATE_KEY (RSA, env variable)

iOS (pearl-ios):
  Sign in with Apple
  ├─ ASAuthorizationAppleIDCredential
  ├─ Keychain storage for tokens/IDs
  └─ Credential state verification on launch
```

### Authorization Model

Two levels, both enforced server-side:

1. **User-level**: `getAuthUserId(ctx)` — every public function checks auth
2. **Admin-level**: `requireAdmin(ctx)` — checks `@innerpearl.ai` email domain

```typescript
// User data is always scoped by userId
const profile = await ctx.db.query("userProfiles")
  .withIndex("by_userId", q => q.eq("userId", userId))  // ← never skip this
  .first();

// Conversation ownership verified before message access
const conv = await ctx.db.get(conversationId);
if (!conv || conv.userId !== userId) return [];  // ← ownership check
```

### Data Access Patterns

- **No direct DB access from clients** — all reads go through Convex queries, all writes through mutations
- **No raw SQL** — Convex's query builder prevents injection
- **User isolation** — every table query is scoped by `userId` index
- **Ownership verification** — cross-table reads verify the parent belongs to the requesting user

### Secret Management

| Secret | Where | How |
|--------|-------|-----|
| `AUTH_PRIVATE_KEY` | Convex env | RSA key for JWT signing, base64-encoded |
| `VITE_CONVEX_URL` | Vercel env | Convex deployment URL (safe to expose) |
| `VITE_SENTRY_DSN` | Vercel env | Sentry DSN (safe to expose — write-only) |
| `ANTHROPIC_API_KEY` | iOS env / Keychain | ⚠️ Client-side (migration needed) |
| `SENTRY_DSN` (iOS) | Hardcoded in AppConfig | Safe — DSN is write-only |

---

## 8. Naming Conventions

### Files

| Type | Convention | Example |
|------|-----------|---------|
| React component | PascalCase | `DashboardPage.tsx`, `AppSidebar.tsx` |
| React hook | camelCase, `use` prefix | `useSpeechRecognition.ts`, `use-mobile.tsx` |
| Utility / library | camelCase | `utils.ts`, `sentry.ts`, `constants.ts` |
| Convex function file | camelCase | `pearl.ts`, `featureFlags.ts`, `humandesign.ts` |
| UI primitive (shadcn) | kebab-case | `button.tsx`, `alert-dialog.tsx`, `scroll-area.tsx` |
| Swift view | PascalCase | `DashboardView.swift`, `ChatView.swift` |
| Swift service | PascalCase, `Service` suffix | `AuthService.swift`, `PearlEngine.swift` |
| Swift model | PascalCase | `UserProfile.swift`, `Conversation.swift` |

### Functions

| Context | Convention | Example |
|---------|-----------|---------|
| Convex query | camelCase, `get` / `is` / `list` prefix | `getUserProfile`, `isAdmin`, `listUsers` |
| Convex mutation | camelCase, verb prefix | `saveOnboarding`, `createConversation`, `deleteUser` |
| Convex action | camelCase, `generate` / `ask` / `get` prefix | `generateCosmicFingerprint`, `askOracle` |
| Internal helpers | camelCase, `Internal` suffix | `getUserProfileInternal`, `addMessageInternal` |
| React component | PascalCase, exported function | `ProtectedRoute()`, `AdminRoute()` |
| React hook | camelCase, `use` prefix | `useTheme()`, `useSpeechRecognition()` |
| Utility function | camelCase | `initSentry()`, `captureError()`, `geocodeCity()` |

### Types

| Convention | Example |
|-----------|---------|
| PascalCase | `NatalChart`, `HDChart`, `PlanetPosition` |
| Interface with `Props` suffix | `ThemeProviderProps` |
| Interface with `State` suffix | (component state types) |
| Enum / literal union for variants | `"user" \| "oracle"` (message role) |
| Convex validator objects | inline `v.object({...})` in `args` |

### Database Tables (Convex)

| Convention | Example |
|-----------|---------|
| camelCase, plural | `userProfiles`, `cosmicProfiles`, `natalCharts` |
| `userId` as foreign key | Every user-owned table has `userId: v.id("users")` |
| Timestamps as numbers | `createdAt: v.number()` (Date.now() epoch ms) |
| Date strings as ISO | `birthDate: v.string()` → `"YYYY-MM-DD"` |

---

## 9. Design System

### Color Palette (Shared Across Platforms)

The aesthetic is *dark cosmic void with warm gold accents*:

| Token | Hex | Usage |
|-------|-----|-------|
| `gold` | `#C9A84C` | Primary accent, Pearl's signature |
| `goldLight` | `#E8D5A3` | Hover states, highlights |
| `void` | `#0A0A0F` | Primary background |
| `surface` | `#1A1A2E` | Cards, elevated surfaces |
| `textPrimary` | `#F5F0E8` | Main text (warm white) |
| `textSecondary` | `#A09B8C` | Secondary text |
| `textMuted` | `#6B6760` | Disabled, hints |
| `cosmic` | `#6366F1` | Accent (indigo) |
| `nebula` | `#8B5CF6` | Accent (purple) |

### Typography

| Font | Usage |
|------|-------|
| **Cormorant Garamond** | Pearl's voice, headings, oracle-style text |
| **DM Sans** | Body text, UI elements, buttons, labels |

Web uses CSS custom properties / Tailwind utilities. iOS uses `PearlFonts` enum with preset styles (`heroTitle`, `screenTitle`, `pearlMessage`, `bodyRegular`, etc.).

### Signature Element

Pearl uses the `✦` diamond symbol as a signature mark in generated text. This appears in oracle responses and is part of the brand identity.

---

## 10. Key Design Decisions

### Why Convex (not Supabase, Firebase, or custom backend)?

1. **Real-time by default** — every query is a live subscription, no polling needed
2. **Type-safe end-to-end** — schema → generated API → React hooks, zero runtime type errors
3. **No ORM, no SQL** — the query builder is the database, eliminating N+1s and injection
4. **Actions for side effects** — clean separation of pure DB ops from external API calls
5. **Co-located backend** — `convex/` lives in the app repo, deployed atomically

### Why Template-Based AI (not LLM calls from backend)?

Pearl's readings are generated from carefully crafted interpretation tables, not LLM API calls:

- **Deterministic** — same birth data always produces same core reading
- **No API costs** — readings don't consume Claude tokens
- **No latency** — generation is instant, not 2-5 seconds
- **Quality control** — every word is intentionally written, not probabilistically generated
- **Offline capable** — no external dependency for core features

The Oracle chat on iOS does use Claude (direct API), and this may expand — but the core cosmic profile and readings are Pearl's own voice, not delegated to an LLM.

### Why No Shared Code Package?

The three repos are small enough that duplication is manageable, and the overhead of a monorepo or published package isn't justified yet. When we hit one of these triggers, we'll extract a shared package:

- Pearl's system prompt diverges between web and iOS
- A third client is added
- Schema changes require synchronized multi-repo updates

### Why astronomy-engine (not a hosted astrology API)?

- **Runs in Convex** — pure JavaScript, no external API calls for calculations
- **Swiss Ephemeris accuracy** — VSOP87 (planets) + ELP2000 (Moon), aligned with NASA JPL DE431
- **No API costs or rate limits** — calculations happen in-process
- **Deterministic** — same input always produces same chart (important for caching)

### Why Biome (not ESLint + Prettier)?

- **Single tool** — lint + format in one binary, one config file
- **Fast** — written in Rust, 10-100x faster than ESLint
- **Opinionated** — less config bikeshedding, more building

### Why Dark Mode Only?

Pearl's brand identity is built around the *cosmic void* aesthetic. The dark palette creates the atmosphere of looking into the night sky. Light mode would require a completely different design language and dilute the brand. The `ThemeProvider` supports toggling (via `switchable` prop) but it's intentionally set to `defaultTheme="dark"` with switching disabled.
