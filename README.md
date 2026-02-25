# Pearl ✦ Your Personal Spirit Guide

Pearl is a native iOS app that synthesizes ancient wisdom traditions — Western Astrology, Human Design, Gene Keys, Kabbalah, and Numerology — into one unified voice. Pearl speaks as a timeless oracle, not an assistant. She makes you feel *seen*.

## Architecture

- **Platform:** iOS 17+ (SwiftUI)
- **Pattern:** MVVM with SwiftData persistence
- **AI Engine:** Claude API (Anthropic) for Pearl's voice
- **Calculations:** Swiss Ephemeris for astrology, custom HD engine

## Structure

```
Pearl/
├── PearlApp.swift              # App entry point
├── RootView.swift              # Root navigation (onboarding → main tabs)
├── Configuration/
│   └── AppConfig.swift         # Environment config, feature flags
├── Design/
│   ├── PearlColors.swift       # Color system (cosmic void + warm gold)
│   ├── PearlFonts.swift        # Typography (Cormorant Garamond + DM Sans)
│   └── Components/
│       ├── CosmicBackground.swift  # Animated starfield background
│       ├── PearlButton.swift       # Primary, secondary, text buttons
│       └── PearlCard.swift         # Card components
├── Models/
│   ├── UserProfile.swift       # User profile + cosmic blueprint models
│   └── Conversation.swift      # Chat messages + weekly insights
├── Services/
│   ├── PearlEngine.swift       # Claude API integration (Pearl's voice)
│   ├── AuthService.swift       # Sign in with Apple
│   ├── AstrologyService.swift  # Natal chart calculation
│   └── HumanDesignService.swift # HD type/strategy/authority
├── ViewModels/
│   ├── OnboardingViewModel.swift
│   ├── DashboardViewModel.swift
│   ├── ChatViewModel.swift
│   └── ProfileViewModel.swift
└── Views/
    ├── Onboarding/
    │   ├── OnboardingFlow.swift
    │   ├── WelcomeStep.swift
    │   └── BirthDataSteps.swift
    ├── Dashboard/
    │   └── DashboardView.swift
    ├── Chat/
    │   └── ChatView.swift
    ├── Insights/
    │   └── InsightsView.swift
    └── Profile/
        └── ProfileView.swift
```

## Design Language

- **Background:** Deep cosmic void (`#0A0A0F` → `#1A1A2E`)
- **Accent:** Warm gold (`#C9A84C`, `#E8D5A3`)
- **Fonts:** Cormorant Garamond (oracle voice) + DM Sans (UI)
- **Motif:** ✦ diamond symbol throughout
- **Mood:** Ancient, warm, mystical — not techy

## Setup

1. Open in Xcode 15+
2. Set `ANTHROPIC_API_KEY` in environment
3. Build for iOS 17+ simulator or device

## Key Screens

1. **Onboarding** — Pearl introduces herself, collects birth data, delivers first reading
2. **Blueprint Dashboard** — Natal chart, Human Design type, wisdom traditions
3. **Pearl Chat** — Conversational Q&A with streaming responses
4. **Weekly Insights** — Personalized cosmic weather each week
5. **Profile** — Settings, premium, sharing

## License

Proprietary — InnerPearl Inc.
