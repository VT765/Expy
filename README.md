# Expy

Expy is a personal expense tracker made of two parts:

- **`ios/`**: the native iPhone app (SwiftUI, SwiftData, Swift Charts, Face ID, App Intents). See [`ios/README.md`](ios/README.md) to build and install it.
- **Backend** (this folder): Vercel serverless functions + MongoDB Atlas. The app signs in and syncs through it.

```
api/index.js     single serverless entry; vercel.json rewrites /api/* here
server/          db connection, auth (bcrypt + JWT), rate limiting, routes
shared/          zod schemas + default categories
scripts/dev-api.mjs   run the API locally
public/          placeholder page (the root URL serves no app)
ui-ss/           design reference screenshots
```

## Environment variables

| Name | Required | What it is |
|---|---|---|
| `MONGODB_URI` | ✅ | Atlas connection string |
| `JWT_SECRET` | ✅ | 32+ random chars for 30-day login tokens (`openssl rand -base64 48`) |
| `API_KEY` | | Initial key for the `x-api-key` Shortcut endpoints (random if unset) |
| `MONGODB_DB` | | Database name (default `expy`) |
| `ALLOWED_ORIGINS` | | Extra browser origins allowed to call the API |

Locally, put them in `.env.local` (git-ignored; see `.env.example`). On Vercel, set them under Project → Settings → Environment Variables.

## Run the API locally

```bash
npm install
npm run dev:api        # http://localhost:3001/api, reloads on changes
```

To point the iOS app at it, open the app's **Server** setting and use your Mac's LAN address, e.g. `http://192.168.1.2:3001`. iOS only allows plain `http` for local-network addresses.

## Deploy

Vercel deploys every push to `main` (project `expy`, connected to this repo). You can also deploy manually with `npx vercel --prod`. Production URL: `https://expy-iota.vercel.app`.

The first time you sign in from the app, you create the password, and setup then closes for good.

## API

| Method & path | Auth | Purpose |
|---|---|---|
| `GET /api/auth/status` | – | `{ configured }` |
| `POST /api/auth/setup` | first visit only | First-time password (bcrypt) → JWT |
| `POST /api/auth/login` | – | Password → JWT (30 days) |
| `POST /api/auth/password` | JWT | Change password (signs out other devices) |
| `GET/POST /api/{transactions,categories,budgets,settings}` | JWT | List / upsert (last-write-wins on `updatedAt`) |
| `GET/PUT/DELETE /api/{collection}/{id}` | JWT | Read / upsert / soft delete |
| `GET /api/sync?since=<serverTime>` | JWT | Everything changed since the cursor |
| `POST /api/sync` | JWT | Push a batch of local changes |
| `GET /api/export` | JWT | Full JSON export |
| `GET /api/shortcut/categories` | `x-api-key` | Category names for HTTP-based Shortcuts |
| `POST /api/quick-add` | `x-api-key` | `{ amount, category, type?, note?, date? }` → `Saved ₹80 · Food` |
| `GET /api/shortcut/key`, `POST /api/shortcut/key/regenerate` | JWT | Show / rotate the Shortcut key |

Auth and Shortcut routes are rate-limited per IP, all input is validated with zod, and browser requests from unknown origins get a 403.

The iOS app's own Siri/Shortcuts actions log on the device and don't use the `x-api-key` endpoints. Those endpoints remain for logging from outside the app.
