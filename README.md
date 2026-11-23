# Expy

A personal expense tracker that installs on iPhone as a full-screen PWA. It's built for one user, works offline first, and syncs to MongoDB Atlas through Vercel serverless functions.

**Stack:** React 18, Vite 5, Tailwind 3, Framer Motion, Zustand, IndexedDB (idb-keyval), vite-plugin-pwa, ExcelJS (lazy-loaded), custom SVG charts. The API runs on Vercel Functions with MongoDB.

```
src/
  screens/     Tap, History, Analytics, Settings, Lock, Login
  components/  UI kit (Button, Pills, BottomSheet, Toast…), charts/, settings/
  store/       useDataStore (persisted + migrations), useSyncStore (auth + outbox),
               useLockStore (PIN/Face ID), useUIStore
  lib/         sync engine, API client, exporters, crypto, WebAuthn, dates, formatting
  hooks/
shared/        zod schemas + default categories (used by client AND server)
server/        API modules: db, auth, rate limit, routes
api/index.js   single serverless entry; vercel.json rewrites /api/* here
```

---

## 1. MongoDB Atlas

1. Create a free **M0** cluster at <https://cloud.mongodb.com>.
2. **Database Access** → add a user, e.g. `expy`, with a generated password and the *Read and write to any database* role.
3. **Network Access** → allow `0.0.0.0/0`. Vercel functions don't use fixed IPs, and auth is enforced by the app.
4. **Connect → Drivers** → copy the connection string and put the password into it. That's your `MONGODB_URI`.

Collections (`transactions`, `categories`, `budgets`, `settings`, plus `ratelimits` with a TTL index) and their indexes are created automatically on first request.

## 2. Environment variables

| Name | Required | What it is |
|---|---|---|
| `MONGODB_URI` | ✅ | Atlas connection string |
| `JWT_SECRET` | ✅ | 32+ random chars, used to sign 30-day login tokens. `openssl rand -base64 48` |
| `API_KEY` | ✅ | **Setup key** for creating your account the first time, and the **initial iOS Shortcuts key**. `openssl rand -base64 24` |
| `MONGODB_DB` | | Database name (default `expy`) |
| `ALLOWED_ORIGINS` | | Extra browser origins allowed to call the API. Your own domain is always allowed. |

These are server-only. Nothing is prefixed `VITE_`, so none of it is bundled into the frontend. Copy `.env.example` to `.env.local` for local development.

## 3. Local development

```bash
npm install
npm i -g vercel          # once
vercel link              # once, creates/links the Vercel project
vercel env pull .env.local   # or fill .env.local from .env.example
vercel dev               # app + /api on http://localhost:3000
```

**Without the Vercel CLI:** with MongoDB running locally (`brew services start mongodb-community`), set `MONGODB_URI="mongodb://127.0.0.1:27017"` and the other variables in `.env.local`, then run two terminals:

```bash
npm run dev:api   # API on :3001 (reloads on changes to api/, server/, shared/)
npm run dev       # app on :5173, proxies /api → :3001
```

To work on the frontend only, run `npm run dev`. The app still works; at sign-in, choose **Use without sync on this device**.

`npm run build && npm run preview` serves the production build, including the service worker.

## 4. Deploy to Vercel

1. Push the repo to GitHub, then **Vercel → Add New Project → Import**. The framework is detected as **Vite**.
2. **Settings → Environment Variables**: add `MONGODB_URI`, `JWT_SECRET` and `API_KEY` for Production (and Preview if you use it).
3. Deploy. Alternatively, run `vercel --prod` from the CLI.
4. Open `https://<your-app>.vercel.app`. You'll get **Set up Expy**: choose a password (8+ characters) and paste your `API_KEY` as the setup key. Setup only works once. After that, the screen is a normal sign-in.

The whole API is a single function (`api/index.js`), which keeps you well under the Hobby plan's function limit.

### API summary

| Method & path | Auth | Purpose |
|---|---|---|
| `GET /api/auth/status` | – | `{ configured }` |
| `POST /api/auth/setup` | setup key | First-time password (bcrypt) → JWT |
| `POST /api/auth/login` | – | Password → JWT (30 days) |
| `POST /api/auth/password` | JWT | Change password (signs out other devices) |
| `GET/POST /api/{transactions,categories,budgets,settings}` | JWT | List / upsert (last-write-wins on `updatedAt`) |
| `GET/PUT/DELETE /api/{collection}/{id}` | JWT | Read / upsert / soft delete |
| `GET /api/sync?since=<serverTime>` | JWT | Everything changed since the cursor |
| `POST /api/sync` | JWT | Push a batch of local changes |
| `GET /api/export` | JWT | Full JSON export |
| `GET /api/shortcut/categories` | `x-api-key` | `["🍔 Food", …]` for Shortcuts |
| `POST /api/quick-add` | `x-api-key` | `{ amount, category, type?, note?, date? }` → `Saved ₹80 · Food` |
| `GET /api/shortcut/key`, `POST /api/shortcut/key/regenerate` | JWT | Show / rotate the Shortcuts key |

Auth and Shortcut routes are rate-limited per IP: auth allows 10 requests per 15 minutes, Shortcut routes 30 per minute. All input is validated with zod. Browser requests from other origins get a 403.

---

## 5. Install on iPhone

1. Open your Vercel URL in **Safari**, not Chrome. Add to Home Screen only works from Safari.
2. Tap **Share → Add to Home Screen → Add**.
3. Launch **Expy** from the icon. It opens full-screen, with no browser bars.
4. Sign in. Your data syncs and is cached for offline use.

### Face ID

1. **Settings → Security → App Lock** on, then create a 4-digit PIN (entered twice).
2. Turn on **Face ID** and approve the system prompt.
3. From now on Expy locks on launch and when you come back to it, according to **Auto-lock** (Immediately / 1 min / 5 min). Face ID is offered first, with **Use PIN** as a fallback. If iOS needs a tap before showing Face ID, tap the Face ID icon.

Good to know:

- The PIN is stored only as a salted PBKDF2-SHA256 hash, on this device. After 5 wrong attempts there's a 30-second cooldown.
- **Forgot PIN?** signs you out, after syncing first. Sign in with your password to get back in.
- Face ID requires HTTPS (your Vercel URL qualifies) and iOS 16 or later. The Face ID row is hidden on devices that don't support it.

---

## 6. iOS Shortcut: “Log Expense”

Shortcuts let you log an expense without opening the app, from Back Tap, Siri or a widget. You'll need two values from **Settings → Quick Logging** (each has a copy button):

- **Categories URL**: `https://<your-app>/api/shortcut/categories`
- **Quick-add URL**: `https://<your-app>/api/quick-add`
- **API key**: tap to reveal, then copy

Open the **Shortcuts** app → **+** → rename the shortcut to **Log Expense**, then add these actions in order:

1. **Get Contents of URL**
   - URL: your *Categories URL*
   - Tap ▸ **Show More**: Method **GET**. Under **Headers**, add a header: key `x-api-key`, value: your API key.
2. **Choose from List**
   - Input: **Contents of URL** (filled in automatically)
   - Prompt: `Choose a category`

   The list always reflects your current categories in Expy.
3. **Ask for Input**
   - Input type: **Number**
   - Prompt: `How much did you spend?`
   - Turn on **Allow Decimal Numbers** and leave **Allow Negative Numbers** off.
4. **Ask for Input**
   - Input type: **Text**
   - Prompt: `Add a note (optional)`

   You can leave it empty and tap Done.
5. **Get Contents of URL**
   - URL: your *Quick-add URL*
   - Tap ▸ **Show More**: Method **POST**
   - **Headers**: `x-api-key` = your API key
   - **Request Body**: **JSON**, with these fields:
     - `amount` (Number) → choose the magic variable **Provided Input** from step 3
     - `category` (Text) → **Chosen Item**
     - `note` (Text) → **Provided Input** from step 4
     - `type` (Text) → `expense`
     - `date` is optional. Leave it out to use “now”, or pass **Current Date**.
6. **Show Notification**
   - Body: **Contents of URL**

   The server replies with short text, e.g. `Saved ₹80 · Food`.

Tap ▶ to try it. The entry appears in Expy on the next sync, which also happens whenever the app comes to the foreground.

The server matches the category by name, ignoring case and emoji. An unknown category goes to **Other**, and `type` defaults to `expense`. If something fails, the notification shows `Error: …` (bad key, invalid amount, too many requests).

### Second shortcut: “Log Credit”

Long-press **Log Expense → Duplicate**, rename it **Log Credit**, change step 3's prompt to `How much came in?`, and set the `type` field in step 5 to `credit`.

### Back Tap

**Settings → Accessibility → Touch → Back Tap → Double Tap →** select **Log Expense**. You can also set **Triple Tap → Log Credit**.

### Siri

Say “Hey Siri, Log Expense”. Siri runs the shortcut by its name and asks the same questions by voice.

### Home Screen and Lock Screen widgets

- **Home Screen:** long-press an empty area → **Edit → Add Widget → Shortcuts**, then pick the size and choose **Log Expense** and **Log Credit**.
- **Lock Screen:** long-press the Lock Screen → **Customize → Lock Screen → Add Widgets → Shortcuts**, then select **Log Expense**.
- **Control Center** (iOS 18+): **Add a Control → Shortcuts → Log Expense**.

The app also accepts a prefill URL for anything that can open links:
`https://<your-app>/?amount=80&cat=Food&type=expense&note=Chai`

(The web manifest declares “Log Expense” / “Log Credit” shortcuts too. Android shows them on long-press; iOS doesn't support manifest shortcuts, so use the Shortcuts app as above.)

---

## Data, export and currency

- **Offline-first:** every write goes to IndexedDB and an outbox, and the app always reads from IndexedDB. Sync pushes the outbox, then pulls changes since the last server cursor. It runs when the app opens, when you reconnect, when it returns to the foreground, after each write, and every 5 minutes. Conflicts resolve last-write-wins on `updatedAt`, and deletes are soft so they sync too. The cloud icon on the Tap screen shows synced (green), pending (amber), or offline/error (red).
- **Excel:** Settings → Data, or the buttons at the bottom of Analytics. The workbook has a styled Transactions sheet (frozen header, autofilter, Indian ₹ grouping), plus Summary, By Category and Daily/Monthly sheets with live `SUMIFS` formulas. It opens the iOS share sheet, falling back to a download.
- **CSV / JSON backup / restore:** restore validates the file before importing. **Erase all data** asks for confirmation twice.
- **Currency:** the base currency defaults to ₹ INR. Tap the ₹ on the Tap screen to log an entry in another currency. Rates come from [Frankfurter](https://frankfurter.dev); the old `api.frankfurter.app` now redirects there without CORS headers, so the app calls `api.frankfurter.dev`. Rates are cached for 12 hours and can be overridden manually in Settings → Exchange rates.
