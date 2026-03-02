# Aegis

Native iOS AI assistant app built with Swift and SwiftUI.

## Features

- **AI Chat** — Apple Foundation Models (on-device, free), OpenAI, Anthropic, Gemini, Groq, or custom server
- **Voice Control** — On-device speech recognition and TTS (Phase 2)
- **Smart Home** — HomeKit integration + custom server relay (Phase 3)
- **Security Cameras** — RTSP, HomeKit, and server-relayed feeds (Phase 4)

## Requirements

- iOS 26+
- iPhone 15 Pro+ or M-series iPad
- Xcode 26+

## Architecture

Protocol-based provider system — each feature (AI, Voice, Smart Home, Cameras) is backed by a protocol with multiple implementations:

- **Standalone**: Apple Foundation Models, Speech framework, HomeKit — works with zero config
- **BYO API Keys**: OpenAI, Anthropic, Gemini, Groq, ElevenLabs — user provides their own keys
- **Custom Server**: Any compatible FastAPI server (e.g., Jarvis on DGX Spark)

All API keys stored in Keychain. Dark-only UI with cyan/orange accent theme.

## Setup

1. Open in Xcode 26+
2. Set team and bundle ID in project settings
3. Build and run on device (Foundation Models requires real hardware)

## Bundle ID

`com.alexandra767.aegis`
