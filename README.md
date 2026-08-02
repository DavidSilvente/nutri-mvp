# nutri_mvp

A new Flutter project.

## Importing a diet PDF

Reading a new diet plan needs an API key for a multimodal model. Without one the
import button is hidden — offering an import that fails on its first request is
worse than not offering it, because a missing key looks exactly like an
unreadable plan.

1. Copy the template and fill in **one** key:

   ```sh
   cp .env.example .env
   ```

2. Run with it:

   ```sh
   flutter run --dart-define-from-file=.env
   ```

`.env` is gitignored. Which key you use decides which model reads the plan:

| Key | Model | Cost |
| --- | --- | --- |
| `GEMINI_API_KEY` | Gemini (free tier) | none, within your quota |
| `ANTHROPIC_API_KEY` | Claude | ~0.13–0.62 $ per plan, by model |

Gemini wins when both are set. Reading a plan is transcription rather than
reasoning, and both adapters are held to the same brief — see
`lib/features/nutrition/data/sources/diet_extraction_prompt.dart`. Swapping
providers changes who reads the plan, never what a correct reading is.

> **The key is compiled into the binary.** `String.fromEnvironment` resolves at
> build time, so anyone with the APK or IPA can extract it. That is fine for a
> build you run on your own phone. Before shipping this app to anyone else, move
> extraction behind a server you control.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
