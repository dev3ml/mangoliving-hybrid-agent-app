# MangoLiving Agent

Flutter app for real-estate **agents** (Android + iOS). Sibling of [`mangoliving-hybrid-mobile-app`](../mangoliving-hybrid-mobile-app) (buyers) and the web dashboard in [`mangoliving/agent`](../mangoliving/agent).

Screen specs: [`mangoliving/docs/agent-mobile`](../mangoliving/docs/agent-mobile).

## Architecture

Feature-first clean architecture with Riverpod, GoRouter, and Dio — same habits as the buyer app, new product.

```
lib/
  core/          # theme, router, network, storage
  features/      # auth, overview, clients, messages, showings, offers, analytics, account
```

Login is `POST /v1/auth/admin/login` (agent JWT). Buyer login is a different app.

## Getting started

```bash
cp .env.example .env
flutter pub get
flutter run
```

Point `API_BASE_URL` at your local or staging API (same Express server as the buyer apps).

## First slice

Auth + tab shell are in. Feature screens are placeholders until implemented from the specs:

1. Home — `01-overview.md`
2. Clients — `02-clients.md`
3. Messages — `03-messages.md`
4. Showings — `04-showing-requests.md`
5. Offers / Analytics / Account — via **More**
