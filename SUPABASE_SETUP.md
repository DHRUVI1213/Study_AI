# Supabase Setup Guide — Step by Step for Beginners

This guide walks you through connecting **StudyAI** (Flutter app) to Supabase from zero. Follow each step in order.

---

## What You Need Before Starting

| Tool | Purpose | Download |
|------|---------|----------|
| Flutter SDK | Run the mobile app | https://docs.flutter.dev/get-started/install |
| Node.js | Install Supabase CLI | https://nodejs.org |
| Google AI Studio account | Gemini API key | https://aistudio.google.com/apikey |
| Supabase account (free) | Backend | https://supabase.com |

---

## STEP 1 — Create a Supabase Project

1. Go to [https://supabase.com](https://supabase.com) and **Sign Up** (free tier is enough).
2. Click **New Project**.
3. Fill in:
   - **Name:** `ai-study-assistant`
   - **Database Password:** create a strong password and **save it** (you need it for direct DB access)
   - **Region:** choose closest to you (e.g. `South Asia (Mumbai)`)
4. Click **Create new project** and wait ~2 minutes.

---

## STEP 2 — Copy Your API Keys

1. In Supabase Dashboard, go to **Project Settings** (gear icon) → **API**.
2. Copy these two values:

| Key | Where to use |
|-----|--------------|
| **Project URL** | Flutter app (`supabase_config.dart`) |
| **anon public** key | Flutter app (`supabase_config.dart`) |

3. Open `lib/config/supabase_config.dart` in this project and replace:

```dart
static const String url = 'https://YOUR_PROJECT_REF.supabase.co';
static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

> **Never** put the `service_role` key in Flutter. That key is server-only.

---

## STEP 3 — Create Database Tables

1. In Supabase Dashboard, go to **SQL Editor**.
2. Click **New query**.
3. Open the file `supabase/schema.sql` from this project.
4. Copy the **entire contents** and paste into the SQL Editor.
5. Click **Run**.

You should see: `Success. No rows returned`

This creates:
- `profiles`, `documents`, `chat_sessions`, `chat_messages`
- `summaries`, `quizzes`, `quiz_attempts`, `flashcards`, `study_plans`
- Row Level Security (RLS) so users only see their own data

---

## STEP 4 — Create Storage Bucket for PDFs

1. Go to **Storage** in the sidebar.
2. Click **New bucket**.
3. Settings:
   - **Name:** `documents`
   - **Public bucket:** OFF (keep private)
4. Click **Create bucket**.

The storage policies were already created in `schema.sql` (Step 3). They allow each user to upload/read/delete only files in their own folder: `{user_id}/filename.pdf`.

---

## STEP 5 — Enable Authentication

### Email + Password

1. Go to **Authentication** → **Providers** → **Email**.
2. Make sure **Enable Email provider** is ON.
3. For development, you can turn OFF **Confirm email** (turn it back ON for production).

### Google Sign-In (Optional)

1. Go to [Google Cloud Console](https://console.cloud.google.com).
2. Create a project → **APIs & Services** → **Credentials**.
3. Create **OAuth 2.0 Client ID** → type: **Web application**.
4. Add **Authorized redirect URI:**
   ```
   https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback
   ```
5. Copy Client ID and Client Secret.
6. In Supabase: **Authentication** → **Providers** → **Google** → Enable and paste credentials.

### Redirect URL for Flutter

1. Go to **Authentication** → **URL Configuration**.
2. Add to **Redirect URLs:**
   ```
   io.supabase.aistudyassistant://login-callback/
   ```
3. Keep the existing Android intent filter host as `login-callback`. Keep the iOS URL scheme as `io.supabase.aistudyassistant`. The app recognizes both custom callback links and routes a valid Supabase `passwordRecovery` event to `/reset-password`.
4. For the web app, add a redirect URL matching the same host and port as the Flutter app page open in Chrome (not the DevTools page). With the current hash-based routing, the reset page route is `/#/reset-password`. For example:
   ```
   http://localhost:47638/**
   ```
   Replace `47638` with the port in the app page's address bar. For a deployed app, allow its web app origin as well.
5. Set the Supabase **Site URL** to the app origin, for example `http://localhost:47638` during this local run. If Flutter starts on a different port, update the URL allowlist and use the new port.

---

## STEP 6 — Install Supabase CLI

Open terminal (PowerShell on Windows):

```powershell
npm install -g supabase
supabase login
```

A browser window opens — log in with your Supabase account.

Link CLI to your project:

```powershell
cd ai_study_assistant
supabase link --project-ref YOUR_PROJECT_REF
```

> Find `YOUR_PROJECT_REF` in **Project Settings → General** (e.g. `abcdefghijklmnop`).

---

## STEP 7 — Get Gemini API Key

1. Go to [https://aistudio.google.com/apikey](https://aistudio.google.com/apikey).
2. Click **Create API Key**.
3. Copy the key.

Store it as a Supabase secret (never in Flutter code):

```powershell
supabase secrets set GEMINI_API_KEY=your_gemini_api_key_here
```

---

## STEP 8 — Deploy Edge Functions

Edge Functions are serverless code that call Gemini AI securely.

Deploy the AI chat function:

```powershell
supabase functions deploy ai-chat
```

Test it works:

```powershell
supabase functions list
```

You should see `ai-chat` with status `ACTIVE`.

> Create and deploy similar functions for `generate-summary`, `generate-quiz`, `generate-flashcards`, and `generate-study-plan` following the same pattern as `ai-chat`.

---

## STEP 9 — Run the Flutter App

```powershell
cd ai_study_assistant
flutter pub get
flutter run
```

### Test the full flow:

1. **Register** a new account on the login screen.
2. **Upload** a PDF from the Documents tab.
3. Open the document → tap **Ask AI Questions**.
4. Type a question → AI responds using your document content.

---

## STEP 10 — Verify Everything Works

Use this checklist:

- [ ] User can register and login
- [ ] PDF uploads to Storage (check **Storage → documents** in dashboard)
- [ ] Document row appears in **Table Editor → documents**
- [ ] AI chat returns a response (check **Edge Functions → Logs**)
- [ ] Chat messages saved in **chat_messages** table

---

## Architecture Overview

```
┌─────────────┐     Auth/DB/Storage      ┌──────────────┐
│  Flutter    │ ◄──────────────────────► │   Supabase   │
│  App        │                          │  PostgreSQL  │
└──────┬──────┘                          │  Auth        │
       │                                 │  Storage     │
       │  AI requests                    └──────┬───────┘
       ▼                                        │
┌─────────────┐     document text               │
│   Edge      │ ◄───────────────────────────────┘
│  Functions  │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Gemini AI  │
└─────────────┘
```

**Why this architecture?**
- Flutter never sees the Gemini API key (secure)
- Each user's data is isolated via RLS
- Edge Functions read document text from DB and send it to Gemini (RAG pattern)

---

## Common Problems & Fixes

### "Invalid API key" on login
→ Double-check `url` and `anonKey` in `supabase_config.dart`. No extra spaces.

### PDF upload fails
→ Ensure the `documents` storage bucket exists and RLS policies ran from `schema.sql`.

### AI returns demo message instead of real answer
→ Edge Function not deployed, or `GEMINI_API_KEY` secret not set. Run:
```powershell
supabase secrets list
supabase functions deploy ai-chat
```

### Google login doesn't work
→ Redirect URI must match exactly in Google Cloud Console and Supabase URL Configuration.

### "Row Level Security" error
→ User not logged in, or RLS policies missing. Re-run `schema.sql`.

---

## File Upload Path Convention

When a user uploads `notes.pdf`, the app stores it at:

```
documents/{user_id}/{document_id}.pdf
```

Example: `documents/a1b2c3d4-.../f5e6d7c8-....pdf`

---

## Security Rules (Important)

| Do | Don't |
|----|-------|
| Use `anon` key in Flutter | Put `service_role` key in Flutter |
| Store Gemini key as Supabase secret | Hardcode API keys in Dart files |
| Keep RLS enabled on all tables | Disable RLS in production |
| Validate user JWT in Edge Functions | Trust client-sent user IDs |

---

## Next Steps After Setup

1. Add PDF text extraction (use `syncfusion_flutter_pdf` package)
2. Deploy remaining Edge Functions (summary, quiz, flashcards, study plan)
3. Enable email confirmation for production
4. Add app icons and splash screen branding
5. Build APK: `flutter build apk --release`

---

## Quick Reference — Important Files

| File | Purpose |
|------|---------|
| `lib/config/supabase_config.dart` | Supabase URL + anon key |
| `supabase/schema.sql` | Full database setup |
| `supabase/functions/ai-chat/index.ts` | AI chat Edge Function |
| `lib/services/auth_service.dart` | Login/register logic |
| `lib/services/document_service.dart` | PDF upload logic |
| `lib/services/ai_service.dart` | Calls Edge Functions |

---

**You're done!** Your AI Study Assistant is now connected to Supabase. If something breaks, check **Supabase Dashboard → Logs** for errors.
