# 🚀 Quick Setup Checklist

Follow these steps to get your authentication system running:

## Backend Setup

- [ ] **1. Start PostgreSQL Database**
  ```bash
  docker run --name naturally-yours-db \
    -e POSTGRES_USER=vapor_username \
    -e POSTGRES_PASSWORD=vapor_password \
    -e POSTGRES_DB=vapor_database \
    -p 5432:5432 \
    -d postgres:15
  ```

- [ ] **2. Run Database Migrations**
  ```bash
  cd path/to/backend
  swift run NaturallyYoursServer migrate
  ```

- [ ] **3. Start Backend Server**
  ```bash
  swift run NaturallyYoursServer serve
  ```
  
  You should see: `[ INFO ] Server starting on http://127.0.0.1:8080`

## iOS App Setup

- [ ] **4. Configure Info.plist**
  - Open `Info.plist` in Xcode
  - Add App Transport Security settings (see `INFO_PLIST_SETUP.md`)

- [ ] **5. Update Backend URL** (if needed)
  - Open `Services/AuthService.swift`
  - Update `baseURL` variable:
    - Simulator: `http://localhost:8080`
    - Physical device: `http://YOUR_MAC_IP:8080`

- [ ] **6. Build and Run**
  - Select a simulator or device
  - Press **⌘ + R**

## Testing

- [ ] **7. Test Guest Mode**
  - Tap "Continue as Guest"
  - Should see "Hello, Guest!" screen

- [ ] **8. Test Registration**
  - Tap "Sign Up"
  - Fill in all fields
  - Create account
  - Should see "Hello, [FirstName]!" screen

- [ ] **9. Test Logout**
  - Tap "Log Out"
  - Should return to login screen

- [ ] **10. Test Login**
  - Enter email and password from step 8
  - Tap "Log In"
  - Should see welcome screen with your name

## Verify Everything Works

✅ You can create a new account
✅ You can log in with existing credentials
✅ You can continue as a guest
✅ You can log out
✅ You see personalized greetings with your first name
✅ Guest users see "Hello, Guest!"

## Common Issues

### Cannot connect to server
- Check backend is running: `lsof -i :8080`
- Verify `baseURL` is correct
- For physical device, use Mac's IP address
- Check Info.plist has transport security settings

### Login/Signup fails
- Check backend logs for errors
- Verify database is running: `docker ps`
- Ensure migrations ran successfully
- Check password meets requirements (8+ chars, uppercase, number)

### Session not persisting
- Verify backend session middleware is configured
- Check cookies are being set in browser/app
- Ensure session storage is working in backend

## Next Steps

Once everything is working:
1. Start building your product catalog
2. Add shopping cart functionality
3. Implement checkout flow
4. Add order history
5. Build user profile management

## Need Help?

Check the documentation:
- `iOS_AUTH_SETUP.md` - Detailed iOS setup guide
- `API_DOCUMENTATION.md` - Backend API reference (in backend project)
- `INFO_PLIST_SETUP.md` - Info.plist configuration

Happy coding! 🎉
