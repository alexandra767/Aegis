# Aegis — Implementation Plan

## Project Overview

- **Name**: Aegis (Greek for "shield/protection")
- **Type**: Native iOS AI assistant
- **Language**: Swift / SwiftUI
- **Bundle ID**: `com.alexandra767.aegis`
- **Target**: iOS 26+, iPhone 15 Pro+ and M-series iPads
- **GitHub**: `alexandra767/Aegis`

## Architecture Overview

Aegis uses a **protocol-based architecture** with four core abstractions that allow swapping providers without changing any UI or business logic:

| Protocol | Responsibility | Implementations |
|---|---|---|
| `AIProvider` | Text/chat completion | Apple Foundation Models, OpenAI, Anthropic, Gemini, Groq, Jarvis Server |
| `CameraSource` | Live video feeds & snapshots | HomeKit cameras, RTSP streams, Jarvis Server cameras |
| `SmartHomeProvider` | Device control & status | HomeKit, Jarvis Server |
| `VoiceProvider` | Speech-to-text & text-to-speech | Apple Speech, ElevenLabs, Jarvis Server |

### Provider Modes

1. **Standalone** — Apple Foundation Models + Apple Speech. Zero configuration, works entirely on-device.
2. **BYO API Keys** — User supplies keys for OpenAI, Anthropic, Gemini, Groq, ElevenLabs. Keys stored in Keychain (never UserDefaults).
3. **Custom Server** — Points to a Jarvis API backend (e.g., on DGX Spark) for AI, cameras, and smart home control.

### Data & Security

- **SwiftData** for local persistence (conversations, settings, device cache)
- **Keychain** for all secrets (API keys, server credentials)
- **Biometric gate** (Face ID / Touch ID) for app access

## Theme

- Dark-only UI
- Primary: Cyan `#00FFFF`
- Secondary: Orange `#FF9500`
- Backgrounds: `#0a0a0a` / `#050505`
- Glow effects on cards and interactive elements

## Phase Breakdown

### Phase 0 — Project Skeleton (Week 1)
- Xcode project setup, SPM dependencies
- SwiftData container and Keychain service
- AegisTheme constants and reusable components
- Protocol definitions (AIProvider, CameraSource, SmartHomeProvider, VoiceProvider)
- Onboarding flow (provider selection, API key entry)
- Navigation shell (tab bar or sidebar)

### Phase 1 — Chat MVP (Weeks 2-3)
- Apple Foundation Models provider (on-device)
- OpenAI provider (GPT-4o, GPT-4o-mini)
- Anthropic provider (Claude)
- Chat UI with streaming responses
- Conversation persistence (SwiftData)
- Provider switching in settings
- ProviderManager (active provider registry)

### Phase 2 — Voice + Remaining AI Providers (Weeks 4-5)
- Apple Speech provider (STT + TTS)
- ElevenLabs provider (TTS)
- Gemini provider
- Groq provider
- Jarvis Server AI provider
- Voice chat mode (push-to-talk and hands-free)

### Phase 3 — Smart Home (Weeks 6-7)
- HomeKit provider (discover, control, status)
- Jarvis Server smart home provider
- Device list and room views
- Natural language device control via AI ("turn off the living room lights")

### Phase 4 — Cameras (Weeks 8-9)
- HomeKit camera source
- RTSP camera source (MobileVLCKit)
- Jarvis Server camera source
- Camera grid and full-screen views
- Snapshot and recording support

### Phase 5 — Security & Biometrics (Week 10)
- Face ID / Touch ID app lock
- Per-conversation lock
- Audit log
- Secure data wipe option

### Phase 6 — Feature Expansion (Weeks 11-13)
- Weather integration (WeatherKit)
- Calendar integration (EventKit)
- Home/Lock Screen Widgets (WidgetKit)
- Shortcuts / Siri Intents
- Notification support

### Phase 7 — Polish & App Store (Weeks 14-16)
- Accessibility audit (VoiceOver, Dynamic Type)
- Performance profiling and optimization
- App Store screenshots and metadata
- TestFlight beta
- App Store submission

## Project Structure

```
Aegis/
├── PLAN.md
├── Assets/                     # Asset catalogs, colors, icons
├── Intents/                    # Siri Shortcuts / App Intents
├── Models/                     # SwiftData models (Conversation, Message, Device, etc.)
├── Protocols/                  # Core abstractions
│   ├── AIProvider.swift
│   ├── CameraSource.swift
│   ├── SmartHomeProvider.swift
│   └── VoiceProvider.swift
├── Providers/                  # Protocol implementations
│   ├── AI/
│   │   ├── AppleAIProvider.swift
│   │   ├── OpenAIProvider.swift
│   │   ├── AnthropicProvider.swift
│   │   ├── GeminiProvider.swift
│   │   ├── GroqProvider.swift
│   │   └── JarvisAIProvider.swift
│   ├── Camera/
│   │   ├── HomeKitCameraSource.swift
│   │   ├── RTSPCameraSource.swift
│   │   └── JarvisCameraSource.swift
│   ├── SmartHome/
│   │   ├── HomeKitProvider.swift
│   │   └── JarvisSmartHomeProvider.swift
│   └── Voice/
│       ├── AppleVoiceProvider.swift
│       ├── ElevenLabsProvider.swift
│       └── JarvisVoiceProvider.swift
├── Services/                   # App-level services
│   ├── KeychainService.swift
│   ├── ProviderManager.swift
│   ├── NetworkService.swift
│   └── PersistenceService.swift
├── ViewModels/                 # View models
│   ├── ChatViewModel.swift
│   ├── SettingsViewModel.swift
│   ├── HomeViewModel.swift
│   └── CameraViewModel.swift
├── Views/                      # SwiftUI views
│   ├── AegisApp.swift
│   ├── Components/
│   │   ├── AegisTheme.swift
│   │   ├── GlowCard.swift
│   │   ├── MessageBubble.swift
│   │   └── ProviderPicker.swift
│   ├── Chat/
│   │   ├── ChatView.swift
│   │   └── VoiceChatView.swift
│   ├── Home/
│   │   ├── DashboardView.swift
│   │   └── DeviceControlView.swift
│   ├── Cameras/
│   │   ├── CameraGridView.swift
│   │   └── CameraDetailView.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   ├── ProviderSettingsView.swift
│   │   └── SecuritySettingsView.swift
│   └── Onboarding/
│       ├── OnboardingView.swift
│       └── APIKeyEntryView.swift
└── Widgets/                    # WidgetKit extensions
```

## Dependencies

| Dependency | Manager | Purpose |
|---|---|---|
| swift-markdown (Apple) | SPM | Markdown rendering in chat |
| MobileVLCKit | CocoaPods | RTSP camera streaming |

### Apple Frameworks

- `FoundationModels` — On-device AI (iOS 26+)
- `Speech` — Speech recognition
- `AVFoundation` — Audio recording/playback
- `HomeKit` — Smart home device control
- `SwiftData` — Local persistence
- `Security` — Keychain access
- `WeatherKit` — Weather data
- `EventKit` — Calendar integration
- `WidgetKit` — Home/Lock Screen widgets
- `LocalAuthentication` — Face ID / Touch ID

## Notes

- Full details for each phase, API contracts, and UI specifications are in the original plan document.
- This file serves as the high-level reference for the Aegis implementation roadmap.
