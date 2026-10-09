# Deploying the Naturally Yours server to Render

The server now runs on **PostgreSQL in production** (Render's filesystem is ephemeral,
so SQLite would be wiped on every deploy) and on **SQLite locally** (automatic fallback
when `DATABASE_URL` is not set). Deploy is via **Docker** using the included `Dockerfile`
and the `render.yaml` blueprint.

## One-time deploy (Blueprint — easiest)

1. Push to GitHub (already the case).
2. In Render: **New → Blueprint**, select this repo. Render reads `render.yaml` and
   proposes a web service (`naturallyyours-server`) + a Postgres database
   (`naturallyyours-db`). Click **Apply**.
3. When prompted, fill the secret env vars (they're marked `sync: false`, so they are
   NOT in git):
   - `SQUARE_ACCESS_TOKEN`, `SQUARE_APPLICATION_ID`, `SQUARE_LOCATION_ID`
   - `SUPPORT_EMAIL`, `ZOHO_APP_PASSWORD`
   (The non-secret ones — `SQUARE_ENVIRONMENT`, `ZOHO_SMTP_HOST`, `ZOHO_SMTP_PORT`,
   `SUPPORT_FROM_NAME`, `SHIPPING_FLAT_CENTS` — are preset in `render.yaml`.)
4. First deploy builds the Docker image (~a few minutes), runs migrations automatically
   (`autoMigrate`), and seeds the catalog from `SeedData/products.csv` on first boot.
5. Note the service URL Render assigns (e.g. `https://naturallyyours-server.onrender.com`).

### If you'd rather wire it up manually (no blueprint)
- Create a **PostgreSQL** instance; copy its **Internal Database URL**.
- Create a **Web Service** → from this repo → **Root Directory** `NaturallyYoursServer`,
  **Runtime** Docker. Add env var `DATABASE_URL` = the internal URL, plus the vars above.
- Health check path: `/api/products`.

## How the server picks the database / port
- `DATABASE_URL` present → PostgreSQL (TLS `.prefer`, so it works with Render's internal
  and external URLs). Not present → local `db.sqlite`.
- Binds `0.0.0.0` and reads Render's `$PORT` automatically (see `configure.swift`).

## After it's live
1. Verify: open `https://<your-service>.onrender.com/api/products` → JSON list.
2. Update the iOS app's production URL in
   `NaturallyYours/Auth/ConfigurationAppConfiguration.swift` (`apiBaseURL` → `.production`)
   to the exact Render URL, then build a Release/TestFlight build.
3. Log into admin from the app (**Account → Staff Login**) with the seeded test admin
   (`test@account.com` / `123456789`) — **change this password or remove the
   `CreateTestAdmin` migration before real launch.**

## Important notes / limitations
- **Free tier:** the free web service sleeps after inactivity (first request after idle
  is slow), and Render's free Postgres is time-limited — upgrade to a paid instance for
  anything beyond testing.
- **Admin image uploads** are written to `Public/uploads`, which is **ephemeral** on
  Render (lost on redeploy). Most catalog images are already absolute CDN URLs, so this
  only affects admin-uploaded photos. For durable uploads, add a Render **Disk** mounted
  at `/app/Public/uploads` (paid) or move uploads to object storage (e.g. S3/Cloudflare R2).
- **Square:** flip `SQUARE_ENVIRONMENT` to `production` and swap in live Square
  credentials (and the client `applicationID`/`locationID` via `/api/payments/config`)
  when you're ready to take real payments.
- **Secrets:** never commit real keys. `.env` is gitignored; production secrets live only
  in Render's dashboard.
