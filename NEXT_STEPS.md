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

### ⏳ iOS app — baseline builds; feature build NOT started
Existing scaffolding: `ContentView`, `MainTabView`, `HomeView`, `ShopView`, `LoginRegisterView`,
`ServicesAuthService` (auth networking), theme (`Color+Theme`, `Font+Theme`), `AppConfiguration`,
home models/viewmodel, `Assets.xcassets` (14 images). Target/scheme: `NaturallyYours`.

## Next steps (ordered) — build the storefront + admin UI mirroring naturallyyourssupply.com
1. **Networking layer**: `APIClient` (shared URLSession w/ cookie-based session to match
   server sessions), wire `AppConfiguration.apiBaseURL` to the chosen port. Services:
   `ProductService`, `CartService`, `FavoritesService`, `OrderService`, `MessagingService`.
   Codable models mirroring server DTOs (ProductDTO, CartDTO, OrderDTO, ConversationDTO, MessageDTO).
   Image URL helper: if URL starts with `http` use as-is, else prepend `apiBaseURL`.
2. **Storefront screens** (match website nav: Home, Shop, About, Contact):
   - Home: Featured Bundles + category tiles (Haircare / Skincare / Treatments)
   - Shop: category tree (Bundles, Skincare, Haircare→Shampoo/Conditioner/Oils/Styling, Treatments, Men), search
   - Product detail; Cart; Favorites; Account + order history
3. **Checkout** with **Square In-App Payments SDK** (add SDK via SPM), collect card → token →
   `POST /api/checkout`. Needs `SQUARE_APPLICATION_ID` + `SQUARE_LOCATION_ID` on the client
   (sandbox). Server already charges via Payments API.
4. **Contact/messaging** screen → `/api/contact` + conversation thread view (polling).
5. **Admin section** (admin-login gated): inventory CRUD, price/stock edit, per-product image
   upload, CSV import/export, order logs, messaging inbox.
6. Verify each step via `xcodebuild` (or Xcode). Then wire a local end-to-end test
   (server on 8081 + simulator) before deploying server to Render.

## Known issues / follow-ups
- One product from the CSV merged due to a duplicate Title (49 created vs 50 parsed) — reconcile later.
- **Rotate Square + Baserow credentials**: a `.env` with them was briefly committed to GitHub
  in the discarded `a98e9a5` push (still reachable in GitHub history until GC).
- Tax is 0 and shipping is a flat `SHIPPING_FLAT_CENTS` env (default 0) — wire real rates later.
