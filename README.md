# AI Media: Multi-Model Social Content Studio

<div align="center">
  <img src="assets/hero.png" alt="AI Media Banner" width="780">
</div>

<div align="center">
  <img src="https://img.shields.io/badge/CI-passing-brightgreen">
  <img src="https://img.shields.io/badge/license-MIT-blue">
  <img src="https://img.shields.io/badge/realtime-WebSockets-black">
  <img src="https://img.shields.io/badge/DB/SaaS-Supabase-3ECF8E">
  <img src="https://img.shields.io/badge/AI-OpenAI-6E56CF">
</div>

> **TL;DR**  
> AI Media lets users log in with their socials (e.g., X) and generate on-brand media by orchestrating multiple AI models.  
> We use **WebSockets** (as a capability), **Supabase** for auth/storage, **OpenAI** for generation, and **WebTucker** + basic **HTTP** for job orchestration.  
> The backend is **Node.js**. The client app is **SwiftUI**.  
> Backend repo will be linked here: **[Backend API → (add your link)](#)**.

---

## 🎬 Demo Video

<div align="center">
  <a href="DEMO_VIDEO_URL" target="_blank" rel="noopener noreferrer">
    <img src="assets/video-thumb.png" alt="Watch the demo" width="720">
  </a>
  <p><em>Click the thumbnail to watch a 90-second overview of the product.</em></p>
</div>

---

## 🧠 What It Does

- **Social Login:** Sign in with providers like **X (Twitter)** to authorize posting on your behalf.
- **Multi-Model Content:** Generate posts/threads, captions, alt text, and image prompts by chaining multiple AI models.
- **Media Generation:** Use **OpenAI** to create copy and images; assets attach to drafts or scheduled posts.
- **History-First UX:** _No real-time “view-time” streaming._ Users see a job timeline and a **My Posts** library for drafts, scheduled, and published items.
- **Library & Scheduling:** Organize assets and schedule posts to publish via connected accounts.

---

## 🏗️ Architecture (High-Level)

**Client:** SwiftUI (iOS/macOS)  
**Backend:** Node.js (API + orchestration)  
**Core Services:** Supabase (Auth, Postgres, Storage), OpenAI (text/image), WebSockets (capability), WebTucker (HTTP orchestration), Basic HTTP (callbacks/webhooks)

### Components

- **SwiftUI App** — Handles X OAuth handoff; shows job status snapshots (no streaming); displays **My Posts** (drafts, scheduled, published).
- **Node.js Backend** — Auth via Supabase; multi-step AI orchestration (Draft → Refine → Image Prompt → Moderation → Finalize); persists job states in Postgres.
- **WebTucker + Basic HTTP** — HTTP task routing/dispatch, reliable callback patterns; endpoints record status snapshots (queued/running/done/failed).
- **OpenAI** — Text generation, image prompting/generation, moderation checks.
- **Publishers** — Post approved content to X using user-granted scopes.

### Data Flow (Simplified)

1. User signs in with X → backend completes OAuth via Supabase → session stored.  
2. User creates a content job → backend records a “queued” snapshot.  
3. Orchestrator runs model chain via OpenAI → writes periodic status snapshots (no live token streaming).  
4. Results (text/images) saved to Storage and linked to the job.  
5. User reviews outputs in **My Posts** and chooses Draft / Schedule / Publish.  
6. On publish, backend posts to X using stored tokens and records the publish event.  
7. **My Posts** shows history: draft → scheduled → published (with permalinks if available).

---

## 🔐 Privacy & Permissions

- **Minimal Scopes:** Only what’s needed to read profile basics, upload media, and publish posts.  
- **Token Security:** Tokens encrypted at rest; rotation and revocation respected.  
- **User Control:** Publishing requires explicit user action or scheduled time.  
- **Storage:** Media/artifacts in Supabase Storage with RLS and signed URLs.

---

## 📱 App Behavior (No View-Time Feedback)

- No token-level streams or “live typing” visuals.  
- Clear, timestamped **status snapshots** (queued → running → done/failed).  
- **My Posts** is the single source of truth for drafts, scheduled, and published posts.

---

## 🗂 Suggested Data Model (Conceptual)

- **content_jobs:** job state, model chain config, inputs, outputs, timestamps.  
- **social_accounts:** provider, encrypted tokens, user linkage.  
- **posts:** draft body, media links, scheduling metadata, publish status/outcome.  
- **publish_events:** per-network result records and permalinks.  

> **Note:** Implement with Supabase Postgres and enforce Row-Level Security (RLS) so users can only access their own data.

---

## 🔗 Integrations

- **OpenAI:** text generation, image prompting/generation, moderation.  
- **Supabase:** OAuth, Postgres, Storage, RLS.  
- **X (Twitter):** OAuth 2.0, media upload, post creation.  
- **WebTucker:** HTTP orchestration, callback handling.  
- **WebSockets:** internal signaling only; not used for user-visible streaming.

---

## 🧭 User Journeys

- **Create Content:** Open app → New → prompt/brand details → submit job → later review in **My Posts**.  
- **Schedule Post:** From draft → set time/date → confirm schedule.  
- **Publish Now:** From draft → publish → record publish event and permalink to X.  
- **Asset Library:** View generated text/images; reuse or remix in future jobs.

---

## 🗺️ Roadmap

- Multi-platform publishing (Instagram, LinkedIn)  
- Brand kits and reusable templates  
- Team workspaces and roles  
- A/B testing and performance analytics  
- Content calendar with drag-and-drop rescheduling

---

## 🔗 Repositories

- **Backend (Node.js):** [add your link here](#)  
- **Client (SwiftUI):** current repo

---

## 📄 License

MIT © You
