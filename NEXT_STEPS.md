# Naturally Yours — Build Handoff / Next Steps

> Read this first when picking up the project in a new chat. It captures the current
> state, how to build/run, important gotchas, and the ordered plan for what's next.

## Project location & environment
- **Canonical path:** `~/Developer/NaturallyYours` (deliberately OUTSIDE iCloud).
  - ⚠️ Do **not** move this into `~/Desktop` or `~/Documents` — those have iCloud
    "Desktop & Documents" sync ON, which creates `" 2"/" 3"` conflict copies and
    previously corrupted the repo (lost app source, duplicate `.git`, bad refs).
    If you want it reachable from the Desktop, use a **symlink/alias** to this folder.
- **Git remote:** `git@github.com:jimmytrimble/NaturallyYours.git`, branch `main`.
- Always `git add` new files early so an accidental reset can't lose uncommitted work.

## How to build / run
- **Server (Vapor):** `cd ~/Developer/NaturallyYours/NaturallyYoursServer && swift build`
  - Run: `.build/debug/NaturallyYoursServer serve --hostname 127.0.0.1 --port 8081`
  - ⚠️ **Port 8080 is taken by another app on this Mac (`FitmojiBa`)**, so the server
    was tested on **8081**. Either free 8080 or run on 8081 — and make the iOS app's
    `AppConfiguration.apiBaseURL` match whatever port the server uses.
  - `.env` lives at `NaturallyYoursServer/.env` (gitignored) with Square + Baserow keys.
- **iOS app:** open `NaturallyYours.xcodeproj` in Xcode, or CLI:
  `xcodebuild -project NaturallyYours.xcodeproj -scheme NaturallyYours -destination 'generic/platform=iOS Simulator' -configuration Debug CODE_SIGNING_ALLOWED=NO build`
  - Uses Xcode **File System Synchronized Groups**: files added under `NaturallyYours/`
    are auto-included in the target — no `.pbxproj` edits needed. (Don't edit the
    `.pbxproj` while Xcode is open.)

## Current status (as of last session)
### ✅ Server — COMPLETE and verified (builds + runs; catalog seeded: 49 products, 44 active)
Endpoints (base `/api`):
- Auth: `/auth/users/*` (signup/login/logout/me), `/auth/admin/*`, admin roles = superAdmin/moderator/support
- Products: `GET /products`, `/products/category/:c`, `/products/search`, admin CRUD on `/products`
- Cart: `/cart/*` (guest via session + user); Favorites: `/favorites/*`
- **Checkout:** `POST /checkout` → charges Square (card token), creates Order, decrements stock, clears cart
- **Orders:** customer `/orders`, `/orders/:id`; admin `/admin/orders*` (+ status PATCH)
- **Bulk CSV:** `POST /admin/products/import`, `GET /admin/products/export`
- **Image upload:** `POST /admin/products/:id/images/upload` → served from `/uploads/...` (FileMiddleware)
- **Messaging:** customer `POST /contact`, `/conversations*`; admin shared inbox `/admin/conversations*`
- Seed source: `NaturallyYoursServer/SeedData/products.csv` (imported on first run if products table empty)

### ⏳ iOS app — storefront built & build-verified; admin + real Square SDK remain
Target/scheme: `NaturallyYours`. Build: BUILD SUCCEEDED. `AppConfiguration.apiBaseURL`
now points at port **8081**.

**Done this session (storefront, steps 1–4):**
- **Networking layer** (`NaturallyYours/Networking/APIClient.swift`): shared, cookie-aware
  HTTP client (uses `HTTPCookieStorage.shared`, so the session cookie from `AuthService`
  login carries to all requests). ISO8601 date strategy + camelCase keys to match Vapor's
  output. `imageURL(for:)` helper (absolute URLs as-is; relative `/uploads/...` prepended).
- **Models** (`NaturallyYours/Models/StoreModels.swift`): `CatalogProduct`, `Page<T>`,
  `CartDTO`/`CartItemDTO`, `OrderDTO`/`OrderItemDTO`/`OrderStatus`, `FavoriteDTO`,
  `ConversationDTO`/`MessageDTO`, and all request payloads — mirror the server DTOs
  (verified against live JSON).
- **Services** (`NaturallyYours/Services/`): `ProductService`, `CartStore`, `FavoritesStore`,
  `OrderService`, `MessagingService` (all `@MainActor @Observable`). Plus
  `PaymentTokenProvider` abstraction with a `SandboxPaymentTokenProvider` (returns Square's
  `cnon:card-nonce-ok` sandbox nonce).
- **Storefront screens**: real `MainTabView` (Home/Shop/Cart/Favorites/Account, injects all
  services via `.environment`), `ShopView` (category chips + search + grid), `ProductDetailView`
  (image carousel, qty, add-to-cart, favorite toggle), `CartView`, `FavoritesView`,
  `CheckoutView` (contact+shipping form → `/api/checkout`), `ContactView` + conversation
  thread (5s polling), `AccountView` (profile, order history, About, logout). `HomeView`
  still uses its sample-data sections.
- Root (`LoginRegisterView`) now routes authenticated/guest users into `MainTabView`.
- Fixed client `AuthResponse` (`token?` instead of `message`, which had been breaking
  login/signup decoding). Removed the conflicting `ExamplesExampleProductService.swift`.
- **End-to-end verified** against the server on 8081: product list, cart add, and a real
  Square **sandbox** checkout (returned a `paid` order, `paymentStatus: COMPLETED`).

**Admin section — done & verified (step 5):**
- Reached via Account → "Staff Login" (`AdminGateView` as a full-screen cover).
  `AdminService` (`Services/AdminService.swift`) + `Models/AdminModels.swift` cover
  admin auth, catalog, orders, and messaging. `APIClient` gained Basic-auth login,
  raw-body (CSV import), download (CSV export), and multipart image upload.
- **Login**: `AdminLoginView` → `POST /api/auth/admins/login` (HTTP Basic); session
  restored via `/me`. Default seeded super admin: **admin@naturallyyours.com /
  ChangeMe123!** (change this!).
- **Inventory** (`AdminInventoryView` + `AdminProductEditView`): list/search, create,
  edit all fields, price/stock, activate/deactivate, delete, per-product image upload
  (PhotosPicker → multipart), CSV import (fileImporter) and export (fileExporter).
- **Orders** (`AdminOrdersView`): order log + status change (`PATCH .../status`).
- **Inbox** (`AdminInboxView`): shared conversation inbox, reply, close/reopen, assign-to-me.
- Verified end-to-end on 8081: Basic login, admin order list, product create/delete.

**Still TODO on iOS:**
- Replace `SandboxPaymentTokenProvider` with the real **Square In-App Payments SDK**
  (add via SPM/CocoaPods; present card entry; return the real nonce). Needs
  `SQUARE_APPLICATION_ID` + `SQUARE_LOCATION_ID` (sandbox) on the client.
- Wire `HomeView`'s featured/collections to live catalog data (currently sample data) and
  its cart toolbar button to the Cart tab.
- **Server gap**: there's no admin "list all products (incl. inactive)" endpoint —
  `GET /api/products` filters `isActive == true`, so deactivated products disappear from
  the admin inventory list on refresh (can't easily be reactivated from the UI). Add an
  admin list endpoint that returns inactive products too.

## Next steps (ordered)
1. ✅ **Networking layer** — done (see iOS status above).
2. ✅ **Storefront screens** — done (Home still on sample data; see TODO above).
3. ⏳ **Checkout** — flow + server call done via `SandboxPaymentTokenProvider`; swap in the
   real **Square In-App Payments SDK** (add via SPM) for live card entry. Needs
   `SQUARE_APPLICATION_ID` + `SQUARE_LOCATION_ID` on the client (sandbox).
4. ✅ **Contact/messaging** — done (compose + thread with 5s polling).
5. ✅ **Admin section** — done (see iOS status above): login-gated inventory CRUD,
   price/stock, image upload, CSV import/export, order logs, messaging inbox.
6. ⏳ Full local end-to-end pass in the simulator (server on 8081), then deploy server to Render.

## Known issues / follow-ups
- One product from the CSV merged due to a duplicate Title (49 created vs 50 parsed) — reconcile later.
- **Rotate Square + Baserow credentials**: a `.env` with them was briefly committed to GitHub
  in the discarded `a98e9a5` push (still reachable in GitHub history until GC).
- Tax is 0 and shipping is a flat `SHIPPING_FLAT_CENTS` env (default 0) — wire real rates later.
