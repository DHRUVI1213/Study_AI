# StudyAI — AI Study Assistant

A Flutter mobile app that helps students learn smarter using **Supabase** (backend) and **Gemini AI** (intelligence).

## Features

- **Authentication** — Email/password + Google sign-in
- **Document Upload** — Upload PDF notes, textbooks, slides
- **AI Chat** — Ask questions about your uploaded materials
- **Summaries** — Short, medium, and detailed revision notes
- **Quiz Generator** — MCQ, True/False, short answer practice tests
- **Flashcards** — Flip cards for active recall
- **Study Planner** — AI-generated day-by-day exam schedule

## Screenshots / UI

Modern dark theme with indigo gradients, animated splash, glass-style cards, and smooth navigation.

## Getting Started

### 1. Prerequisites

- Flutter SDK 3.9+
- Android Studio or VS Code
- Supabase account (free)
- Gemini API key

### 2. Install dependencies

```bash
cd ai_study_assistant
flutter pub get
```

### 3. Configure Supabase

Follow the complete guide: **[SUPABASE_SETUP.md](SUPABASE_SETUP.md)**

Quick version:
1. Create Supabase project
2. Run `supabase/schema.sql` in SQL Editor
3. Create `documents` storage bucket
4. Update `lib/config/supabase_config.dart` with your URL and anon key
5. Deploy Edge Functions and set `GEMINI_API_KEY` secret

### 4. Run the app

```bash
flutter run
```

> The app works in **demo mode** without Supabase — AI features show sample data until backend is connected.

## Project Structure

```
lib/
├── config/          # Supabase credentials
├── core/            # Theme, router, colors
├── models/          # Data models
├── services/        # Auth, documents, AI API calls
├── screens/         # All UI screens
└── widgets/         # Reusable components
supabase/
├── schema.sql       # Database setup
└── functions/       # Edge Functions for Gemini AI
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter, Provider, GoRouter |
| Backend | Supabase (Auth, PostgreSQL, Storage) |
| AI | Google Gemini via Edge Functions |
| UI | Google Fonts, Flutter Animate |

## License

Built for educational / internship project purposes.
