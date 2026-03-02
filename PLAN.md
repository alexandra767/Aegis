# Aegis — Implementation Plan

## Project Overview

- **Name**: Aegis (Greek for "shield/protection")
- **Type**: Native iOS AI assistant
- **Language**: Swift / SwiftUI
- **Bundle ID**: `com.alexandra767.aegis`
- **Target**: iOS 26+, iPhone 15 Pro+ and M-series iPads
- **GitHub**: `alexandra767/Aegis`
- **Distribution**: App Store (public)

## Architecture Overview

Aegis uses a **protocol-based architecture** with four core abstractions that allow swapping providers without changing any UI or business logic:

| Protocol | Responsibility | Implementations |
|---|---|---|
| `AIProvider` | Text/chat completion | Apple Foundation Models, OpenAI, Anthropic, Gemini, Groq, Custom Server |
| `CameraSource` | Live video feeds & snapshots | HomeKit cameras, RTSP streams, Custom Server relay |
| `SmartHomeProvider` | Device control & status | HomeKit, Custom Server |
| `VoiceProvider` | Speech-to-text & text-to-speech | Apple Speech, ElevenLabs, Custom Server |

### Provider Modes

1. **Standalone** — Apple Foundation Models + Apple Speech. Zero configuration, works entirely on-device. **This is the default App Store experience.**
2. **BYO API Keys** — User supplies their own keys for OpenAI, Anthropic, Gemini, Groq, ElevenLabs. Keys stored in device Keychain (never bundled, never transmitted).
3. **Custom Server** — User points to their own server. URL and credentials stored in device Keychain.

### Data & Security (App Store)

- **No hardcoded keys** — All API keys are user-provided, per-device
- **Keychain storage** — Secrets never leave the device, never in UserDefaults or bundles
- **No server-side component** — Aegis is a pure client; each user connects to their own providers
- **SwiftData** for local persistence (conversations, settings, device cache)
- **Biometric gate** (Face ID / Touch ID) for app access
- **Privacy Policy** required for App Store submission

## Theme

- Dark-only UI
- Primary: Cyan `#00FFFF`
- Secondary: Orange `#FF9500`
- Backgrounds: `#0a0a0a` / `#050505`
- Glow effects on cards and interactive elements

## Phase Breakdown

### Phase 0 — Project Skeleton ✅ COMPLETE
- Xcode project setup
- SwiftData container and Keychain service
- AegisTheme constants and reusable components (CyanButton, AegisCard)
- Protocol definitions (AIProvider, CameraSource, SmartHomeProvider, VoiceProvider)
- Onboarding flow (Welcome, AI Backend, Smart Home, Camera steps)
- Navigation shell (TabView with Chat + Settings)

### Phase 1 — Chat MVP ✅ COMPLETE
- Apple Foundation Models provider (on-device, streaming)
- OpenAI provider (GPT-4o, GPT-4o-mini, GPT-4 Turbo, o3-mini)
- Anthropic provider (Claude Opus 4, Sonnet 4, Haiku 4)
- Gemini provider (2.0 Flash, 2.0 Pro, 1.5 Pro)
- Groq provider (Llama 3.3 70B, Llama 3.1 8B, Mixtral 8x7B)
- Custom Server provider (two-step Spark-style API)
- Chat UI with streaming responses
- Conversation persistence (SwiftData)
- Conversation list with delete/select
- Message bubbles with streaming indicator
- Model picker for switching providers
- Provider switching in settings (AIBackendSettingsView)
- ProviderManager (active provider registry)
- NetworkService (REST, SSE streaming, connection testing)

### Phase 2 — Voice (Next Up)
- Apple Speech provider (STT via Speech framework + TTS via AVSpeechSynthesizer)
- ElevenLabs provider (TTS — user provides their own API key)
- Custom Server voice provider
- Voice chat mode UI (push-to-talk and hands-free)
- Microphone permission handling

### Phase 3 — Smart Home
- HomeKit provider (discover rooms, control accessories, activate scenes)
- Custom Server smart home provider
- Smart Home tab with device list and room views
- Natural language device control via AI ("turn off the living room lights")
- HomeKit entitlement and permission handling

### Phase 4 — Cameras
- HomeKit camera source
- RTSP camera source (MobileVLCKit or AVFoundation)
- Custom Server camera relay
- Camera grid and full-screen views
- Snapshot support

### Phase 5 — Security & Biometrics
- Face ID / Touch ID app lock (LocalAuthentication)
- Per-conversation lock
- Secure data wipe option
- Biometric prompt on app foreground

### Phase 6 — App Store Preparation
- **Privacy Policy** (webpage hosted on GitHub Pages or similar)
- **App Store metadata** — description, keywords, category (Productivity)
- **App Store screenshots** — iPhone 15 Pro, iPad Pro mockups
- **App Review compliance**:
  - Guideline 4.2: Apple AI works with zero config (not a thin wrapper)
  - Guideline 5.1.1: Privacy policy URL, data collection disclosure
  - Guideline 3.1.1: No IAP needed (users bring own keys, no resale of API access)
- Accessibility audit (VoiceOver, Dynamic Type)
- Performance profiling and optimization
- TestFlight beta
- App Store submission

### Phase 7 — Post-Launch Features (Optional)
- Siri Shortcuts / App Intents (stubs already exist)
- Home/Lock Screen Widgets (WidgetKit)
- Weather integration (WeatherKit)
- Calendar integration (EventKit)
- Notification support (partially implemented)
- Audit log

## Project Structure (Actual)

```
Aegis/
├── AegisApp.swift                  # @main App entry point
├── PLAN.md
├── PrivacyInfo.xcprivacy
├── Assets/
│   └── GeneratedImages/            # App icon, backgrounds
├── Assets.xcassets/                # Xcode asset catalog
├── Intents/                        # Siri Shortcuts / App Intents
│   ├── ActivateSceneIntent.swift
│   ├── AskAegisIntent.swift
│   └── ControlLightsIntent.swift
├── Models/                         # SwiftData models
│   ├── CameraConfig.swift
│   ├── ChatMessage.swift
│   └── Conversation.swift
├── Protocols/                      # Core abstractions
│   ├── AIProvider.swift            # + AIProviderType, AIModel, ChatContext
│   ├── CameraSource.swift
│   ├── SmartHomeProvider.swift     # + SmartRoom, SmartScene
│   └── VoiceProvider.swift         # + VoiceOption
├── Providers/
│   ├── AI/
│   │   ├── AnthropicProvider.swift
│   │   ├── AppleAIProvider.swift   # + AIProviderError
│   │   ├── CustomServerProvider.swift
│   │   ├── GeminiProvider.swift
│   │   ├── GroqProvider.swift
│   │   └── OpenAIProvider.swift
│   ├── Camera/
│   │   ├── HomeKitCameraSource.swift       # stub
│   │   ├── RTSPCameraSource.swift          # stub
│   │   └── ServerCameraRelay.swift         # stub
│   ├── SmartHome/
│   │   ├── HomeKitProvider.swift           # stub
│   │   └── ServerSmartHomeProvider.swift   # stub
│   └── Voice/
│       ├── AppleVoiceProvider.swift        # partial
│       ├── ElevenLabsProvider.swift        # stub
│       └── ServerVoiceProvider.swift       # stub
├── Services/
│   ├── KeychainService.swift
│   ├── NetworkService.swift        # + NetworkError
│   ├── NotificationService.swift   # partial
│   └── ProviderManager.swift
├── ViewModels/
│   ├── CameraViewModel.swift       # stub
│   ├── ChatViewModel.swift
│   ├── OnboardingViewModel.swift
│   ├── SettingsViewModel.swift
│   └── SmartHomeViewModel.swift    # stub
└── Views/
    ├── App/
    │   ├── ContentView.swift
    │   └── MainTabView.swift
    ├── Chat/
    │   ├── ChatView.swift
    │   ├── ConversationListView.swift
    │   ├── MessageBubbleView.swift
    │   └── ModelPickerView.swift
    ├── Components/
    │   ├── AegisTheme.swift        # + Color hex, AegisCard, CyanGlow modifiers
    │   └── CyanButton.swift        # + AegisCardView
    ├── Onboarding/
    │   ├── AIBackendStepView.swift
    │   ├── CameraStepView.swift
    │   ├── OnboardingContainerView.swift
    │   ├── SmartHomeStepView.swift
    │   └── WelcomeStepView.swift
    └── Settings/
        ├── AIBackendSettingsView.swift
        └── SettingsView.swift
```

## Dependencies

| Dependency | Manager | Purpose | Phase |
|---|---|---|---|
| MobileVLCKit | CocoaPods/SPM | RTSP camera streaming | Phase 4 |

### Apple Frameworks

- `FoundationModels` — On-device AI (iOS 26+)
- `Speech` — Speech recognition (Phase 2)
- `AVFoundation` — Audio recording/playback (Phase 2)
- `HomeKit` — Smart home device control (Phase 3)
- `SwiftData` — Local persistence
- `Security` — Keychain access
- `LocalAuthentication` — Face ID / Touch ID (Phase 5)
- `WeatherKit` — Weather data (Phase 7, optional)
- `EventKit` — Calendar integration (Phase 7, optional)
- `WidgetKit` — Home/Lock Screen widgets (Phase 7, optional)

## App Store Notes

- **Category**: Productivity
- **Price**: Free (no IAP — users bring their own API keys)
- **Guideline 4.2 (Minimum Functionality)**: Apple AI provides a full on-device experience with zero configuration. The app is not just a thin API wrapper.
- **Guideline 5.1.1 (Data Collection)**: No data collected by the developer. API keys stored on-device only. Third-party API calls go directly from user device to provider (OpenAI, Anthropic, etc.).
- **Guideline 3.1.1 (Payments)**: No resale of API access. Users supply their own keys from their own accounts.
- **Privacy Policy**: Required — host on GitHub Pages or similar. Disclose that the app makes network requests to user-configured third-party APIs.
- **Export Compliance**: Uses system encryption only (Keychain). No custom encryption = no export compliance filing needed.
