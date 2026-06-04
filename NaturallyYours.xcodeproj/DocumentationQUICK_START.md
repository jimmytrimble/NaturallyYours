# 🚀 Quick Start - TL;DR

## The 5-Minute Setup

### 1. Add to Info.plist (30 seconds)
Right-click Info.plist → Open As → Source Code → Add before `</dict></plist>`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### 2. Start Backend (1 minute)
```bash
cd path/to/backend
swift run NaturallyYoursServer serve
```

### 3. Run App (30 seconds)
Press **⌘ + R** in Xcode

### 4. Test (3 minutes)
- Tap "Sign Up"
- Create account with any email/password
- Should see "Hello, [FirstName]!"

## ✅ Done!

That's it. Your authentication is working!

---

## 📋 What You Got

| Feature | Status |
|---------|--------|
| User registration | ✅ |
| User login | ✅ |
| Guest mode | ✅ |
| Personalized greeting | ✅ |
| Logout | ✅ |
| OAuth-ready | ✅ |

## 🎯 What You Can Do Now

**Immediate:**
- Test registration
- Test login
- Test guest mode

**Next:**
- Add products (see `Examples/ExampleProductService.swift`)
- Build shopping cart
- Implement checkout

## 📖 Need More Help?

| Question | File to Check |
|----------|--------------|
| How do I set this up? | `IMPLEMENTATION_GUIDE.md` |
| Step-by-step setup? | `SETUP_CHECKLIST.md` |
| Info.plist help? | `INFO_PLIST_DETAILED_GUIDE.md` |
| How does it work? | `VISUAL_SUMMARY.md` |
| OAuth integration? | `iOS_AUTH_SETUP.md` |
| Complete overview? | `README.md` |

## 🐛 Troubleshooting

**Can't connect?**
→ Check backend is running: `lsof -i :8080`

**Login fails?**
→ Check password has 8+ chars, uppercase, number

**Session not persisting?**
→ Check backend session middleware is configured

## 🎨 Customize

**Change colors:**
```swift
// LoginRegisterView.swift, line ~70
.buttonStyle(.borderedProminent)
.tint(.green)  // ← Change this
```

**Add your logo:**
```swift
// LoginRegisterView.swift, line ~41
Image("your-logo")  // Instead of system image
```

## 📱 Files You'll Edit Most

1. **AppConfiguration.swift** - URLs and settings
2. **LoginRegisterView.swift** - Login/signup UI
3. **HomeView.swift** - After-login UI
4. **AuthService.swift** - Add OAuth methods

## ⚡ Quick Commands

```bash
# Check if backend is running
lsof -i :8080

# Check database
docker ps

# Start database
docker start naturally-yours-db

# Backend logs
# (Shown in terminal where server runs)

# Test login with curl
curl -X POST http://localhost:8080/api/auth/users/login \
  -u "email@test.com:Password123" -v
```

## 🎯 Common Tasks

### Add a New Screen
1. Create new SwiftUI View file
2. Add to HomeView as new tab/navigation

### Call Protected API
```swift
// Copy pattern from AuthService.swift
let (data, response) = try await session.data(for: request)
// Session cookies automatically included!
```

### Add OAuth Button
```swift
// See iOS_AUTH_SETUP.md for full implementation
SignInWithAppleButton(.signIn) { request in
    // Handle sign in
} onCompletion: { result in
    Task {
        try await authService.signInWithApple(result)
    }
}
```

---

## 🎊 You're Ready!

Everything works out of the box. Just add Info.plist config and run!

**Have fun building your beauty products app!** 💚✨
