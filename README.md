# AI Chat

## About app

An iOS application with an AI chat and a video generator. The app contains onboarding, a paywall, the main screen, a chat, a template gallery, video generation, history and settings. The chat answers through the Dola API and keeps the conversation history. The video generator turns a user's photo into a video using PixVerse templates: the user picks a template, a photo, a format (16:9, 1:1, 9:16) and a quality, then saves or shares the result. Premium features are unlocked by an Apphud subscription.

## Preview

[<img src="Preview%20Video/poster.jpg" width="250" alt="App preview">](Preview%20Video/iPhone.mp4)

[Watch the video](Preview%20Video/iPhone.mp4)

## Architecture

The application is built with SwiftUI and the MVVM architecture. Views only describe the layout, view models (`ObservableObject`) hold the screen state. The code is split into layers: `App` (startup and dependencies), `Features` (screens), `Domain` (models, protocols, services) and `Data` (network, database, files).

The app is offline-first: GRDB is the source of truth for chats and videos. `ChatService` and `VideoGenerationService` write network results to the database, and screens observe the database. Because of that, a video keeps generating after the user leaves the screen, and the history card updates by itself.

Dependencies are passed through initializers and protocols, without singletons. The network layer uses Alamofire.

## Requirements

- Xcode 26, iOS 16+
- Swift Package Manager: Alamofire, ApphudSDK, GRDB, Lottie

## Setup

API keys are not stored in the repository. Generate them before the first build:

```bash
NEBULA_API_TOKEN=... APPHUD_API_KEY=... python3 scripts/gen_secrets.py
```

For debugging without a network, run the app with the `-mockData` launch argument; `-mockPremium` turns the subscription on.
