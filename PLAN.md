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

### Phase 2 — Avatar, Voice & iPad UI ✅ COMPLETE

#### Step 1 — Avatar Assets & Model ✅ COMPLETE
- `Models/AvatarConfig.swift` — 6 avatars (3 male, 3 female), SF Symbol placeholders
- Selection persisted via `@AppStorage("selectedAvatarID")`
- AI-generated portraits added in Step 9 (Gemini Imagen 4.0)

#### Step 2 — Avatar View with "Alive" Animations ✅ COMPLETE
- `Views/Avatar/AvatarView.swift` — breathing (scale pulse 3s), blinking (random 3-5.5s), floating, mouth overlay
- `SmallAvatarView` for message bubbles (24pt)
- Cyan glow intensifies when speaking
- Mouth driven by `mouthOpenness` binding (0.0-1.0)
- `Views/Avatar/AvatarPickerView.swift` — grid with gender filter tabs, checkmark selection

#### Step 3 — Apple Voice Selection & TTS ✅ COMPLETE
- `Services/SpeechService.swift` — `@MainActor @Observable`, wraps `AVSpeechSynthesizer` with delegate
- Multi-frequency mouth animation (natural oscillation + word-pulse from `willSpeak` callback)
- Voice discovery grouped by quality tier (Premium/Enhanced/Default)
- Preview playback, selected voice persisted in UserDefaults
- `Views/Avatar/VoicePickerView.swift` — quality badges, play preview, select
- `Providers/Voice/AppleVoiceProvider.swift` — full implementation with quality tiers
- `Protocols/VoiceProvider.swift` — added `qualityTier` to `VoiceOption`
- **100% free** — all Apple on-device, no API key needed

#### Step 4 — Integrate Avatar into Chat ✅ COMPLETE
- `Views/Chat/ChatView.swift` — hero avatar in empty state, `SpeechService` integration
- `Views/Chat/MessageBubbleView.swift` — small avatar on assistant messages, speak/stop button
- Avatar mouth animates during TTS playback

#### Step 5 — Onboarding Avatar & Voice Step ✅ COMPLETE
- `Views/Onboarding/AvatarVoiceStepView.swift` — combined avatar + voice picker
- Inserted at position 2 (after AI Backend), totalSteps bumped to 5
- Skip option to use defaults, iPad width constraint

#### Step 6 — Settings Avatar & Voice Section ✅ COMPLETE
- `Views/Settings/SettingsView.swift` — new "Avatar & Voice" section
- Shows current avatar thumbnail and voice name
- NavigationLink to dedicated AvatarPickerView and VoicePickerView

#### Step 7 — Universal iPad/iPhone UI ✅ COMPLETE
- `Views/Chat/ChatView.swift` — `NavigationSplitView` on iPad (permanent sidebar), `NavigationStack` on iPhone
- `@Environment(\.horizontalSizeClass)` checks in ChatView and OnboardingContainerView
- iPad onboarding constrained to 600pt max width
- Larger avatar on iPad (120pt vs 100pt in empty state)

#### Step 8 — Voice Chat, ElevenLabs, Server Voice ✅ COMPLETE
- `Protocols/VoiceProvider.swift` — added `VoiceProviderType` enum (.apple, .elevenLabs, .customServer), `providerType`, `voiceID` param
- `Providers/Voice/ElevenLabsProvider.swift` — full ElevenLabs TTS (xi-api-key auth, POST /text-to-speech, GET /voices)
- `Providers/Voice/ServerVoiceProvider.swift` — full custom server voice (POST /synthesize, GET /voices, bearer auth)
- `Services/VoiceProviderManager.swift` — mirrors ProviderManager pattern for voice, Keychain-backed ElevenLabs key
- `Services/SpeechService.swift` — multi-provider TTS routing (Apple/cloud), AVAudioPlayer for MP3, metered mouth animation
- `Services/SpeechRecognitionService.swift` — on-device STT (SFSpeechRecognizer), mic/speech permissions, tap-to-record
- `Views/Chat/ChatView.swift` — mic button toggles recording, live transcription bar, permission alerts, keyboard dismissal
- `Views/Avatar/VoicePickerView.swift` — segmented tabs per configured provider, cloud voice fetching
- `Views/Settings/VoiceBackendSettingsView.swift` — add/remove/set-active voice providers
- `Views/Settings/SettingsView.swift` — added Voice Providers nav link
- `AegisApp.swift` — VoiceProviderManager injected via .environment()

#### Step 9 — AI-Generated Avatar Images ✅ COMPLETE
- 6 avatar portraits generated via Gemini Imagen 4.0 API
- Added to `Assets.xcassets/` as proper imagesets (avatar_male1–3, avatar_female1–3)
- `AvatarView` + `SmallAvatarView` load real PNGs via `UIImage(named:)`, gradient fallback if missing
- `Services/AvatarImageGenerator.swift` — cached gradient fallbacks (NSCache) for performance

#### Step 10 — Dashboard Home Tab ✅ COMPLETE
- `Views/App/DashboardView.swift` — hero avatar with greeting, status cards (AI/Voice/Conversations/Avatar), quick actions, recent conversations
- `Views/App/MainTabView.swift` — 3-tab layout: Home | Chat | Settings
- Tab switching via NotificationCenter from quick action buttons

#### Phase 2 — COMPLETE

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
│   ├── AvatarConfig.swift          # Phase 2: avatar data model
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
│       ├── AppleVoiceProvider.swift        # Phase 2: full TTS implementation
│       ├── ElevenLabsProvider.swift        # Phase 2: full ElevenLabs TTS
│       └── ServerVoiceProvider.swift       # Phase 2: custom server voice
├── Services/
│   ├── AvatarImageGenerator.swift  # Phase 2: gradient avatars
│   ├── KeychainService.swift
│   ├── NetworkService.swift        # + NetworkError
│   ├── NotificationService.swift   # partial
│   ├── ProviderManager.swift
│   ├── SpeechRecognitionService.swift  # Phase 2: on-device STT
│   ├── SpeechService.swift         # Phase 2: multi-provider TTS + metered mouth
│   └── VoiceProviderManager.swift  # Phase 2: voice provider management
├── ViewModels/
│   ├── CameraViewModel.swift       # stub
│   ├── ChatViewModel.swift
│   ├── OnboardingViewModel.swift
│   ├── SettingsViewModel.swift
│   └── SmartHomeViewModel.swift    # stub
└── Views/
    ├── App/
    │   ├── ContentView.swift
    │   ├── DashboardView.swift        # Phase 2: home tab with status cards
    │   └── MainTabView.swift          # 3 tabs: Home, Chat, Settings
    ├── Chat/
    │   ├── ChatView.swift
    │   ├── ConversationListView.swift
    │   ├── MessageBubbleView.swift
    │   └── ModelPickerView.swift
    ├── Components/
    │   ├── AegisTheme.swift        # + Color hex, AegisCard, CyanGlow modifiers
    │   └── CyanButton.swift        # + AegisCardView
    ├── Avatar/                        # Phase 2
    │   ├── AvatarPickerView.swift     # avatar selection grid
    │   ├── AvatarView.swift           # animated avatar display
    │   └── VoicePickerView.swift      # voice selection list
    ├── Onboarding/
    │   ├── AIBackendStepView.swift
    │   ├── AvatarVoiceStepView.swift  # Phase 2: avatar + voice step
    │   ├── CameraStepView.swift
    │   ├── OnboardingContainerView.swift
    │   ├── SmartHomeStepView.swift
    │   └── WelcomeStepView.swift
    └── Settings/
        ├── AIBackendSettingsView.swift
        ├── SettingsView.swift
        └── VoiceBackendSettingsView.swift  # Phase 2: voice provider settings
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
