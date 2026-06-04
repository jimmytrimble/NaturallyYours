# ⚙️ Info.plist Setup - Step by Step

## Option 1: Using Xcode's Property List Editor (Recommended for Beginners)

### Step-by-Step Instructions:

1. **Open your project in Xcode**
   - Select your project in the Project Navigator (left sidebar)

2. **Select your app target**
   - In the main editor, select your app under "TARGETS"

3. **Go to the Info tab**
   - Click on the "Info" tab at the top

4. **Add App Transport Security**
   - Right-click anywhere in the list and select "Add Row"
   - OR click the "+" button that appears when hovering over a row
   
5. **Type the key name**
   - Start typing: "App Transport Security Settings"
   - It should autocomplete - select it

6. **Expand the entry**
   - Click the disclosure triangle (▶) next to "App Transport Security Settings"

7. **Add Allow Arbitrary Loads**
   - Hover over "App Transport Security Settings" and click the "+" button
   - Select "Allow Arbitrary Loads"
   - Make sure it's set to "YES" (or check the checkbox)

8. **Add Allow Local Networking (Optional but recommended)**
   - Click "+" again on "App Transport Security Settings"
   - Select "Allows Local Networking"
   - Set to "YES"

### Your Info tab should now show:

```
▼ App Transport Security Settings          Dictionary
    Allow Arbitrary Loads                   YES
    Allows Local Networking                 YES
```

## Option 2: Direct XML Editing (For Advanced Users)

### Step-by-Step Instructions:

1. **Locate Info.plist**
   - Find `Info.plist` in your Project Navigator
   - It's usually in the main app folder

2. **Open as Source Code**
   - Right-click on `Info.plist`
   - Select "Open As" → "Source Code"

3. **Find the closing `</dict>` tag**
   - Scroll to near the bottom
   - Look for the last `</dict>` before `</plist>`

4. **Add this XML code** just BEFORE the final `</dict></plist>`:

```xml
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsLocalNetworking</key>
		<true/>
		<key>NSAllowsArbitraryLoads</key>
		<true/>
	</dict>
```

5. **Your Info.plist should look like this:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<!-- Other existing keys -->
	<key>CFBundleName</key>
	<string>$(PRODUCT_NAME)</string>
	<!-- ... more keys ... -->
	
	<!-- ADD THIS SECTION -->
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsLocalNetworking</key>
		<true/>
		<key>NSAllowsArbitraryLoads</key>
		<true/>
	</dict>
	<!-- END OF NEW SECTION -->
	
</dict>
</plist>
```

6. **Save the file** (⌘ + S)

## What These Settings Mean

### `NSAppTransportSecurity` (App Transport Security Settings)
The main dictionary that controls network security requirements.

### `NSAllowsLocalNetworking` (Allows Local Networking)
- Allows connections to local network addresses
- Needed for: Connecting to `localhost` or local IP addresses
- Safe for: Development and testing
- **Keep in production:** Yes (harmless if you're not using local connections)

### `NSAllowsArbitraryLoads` (Allow Arbitrary Loads)
- Allows insecure HTTP connections
- Needed for: Testing with HTTP during development
- Safe for: Development only
- **Remove before production:** YES! ⚠️

## ⚠️ Important Security Warnings

### For Development (What you just added)
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
    <key>NSAllowsArbitraryLoads</key>    ⬅️ REMOVE BEFORE APP STORE!
    <true/>
</dict>
```

### For Production (When deploying)
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
    <!-- NSAllowsArbitraryLoads REMOVED -->
    
    <!-- Optional: Specific exception for your server if still using HTTP -->
    <key>NSExceptionDomains</key>
    <dict>
        <key>api.naturallyyours.com</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>   ⬅️ Require HTTPS
        </dict>
    </dict>
</dict>
```

## Verification

### After adding these settings, verify they work:

1. **Build and run your app** (⌘ + R)

2. **Try to register a new user**
   - If it works: ✅ Settings are correct
   - If you see "Cannot connect": ❌ Check the following:
     - Backend server is running
     - URL in `AppConfiguration.swift` is correct
     - Info.plist changes were saved

3. **Check Xcode console for errors**
   - Look for messages like:
     - "NSURLSession/NSURLConnection HTTP load failed" = Need to add transport security settings
     - "Connection refused" = Backend server not running
     - "Network is unreachable" = Wrong URL or network issue

## Common Mistakes

### ❌ Mistake #1: Added to wrong Info.plist
**Problem:** You might have multiple Info.plist files (app, tests, etc.)

**Solution:** Make sure you edit the one in your main app target, not the test target.

### ❌ Mistake #2: Typo in key names
**Problem:** XML is case-sensitive

**Solution:** Copy-paste the exact keys from this guide.

### ❌ Mistake #3: Forgot to save
**Problem:** Changes not saved to disk

**Solution:** Press ⌘ + S after editing.

### ❌ Mistake #4: Added in wrong location
**Problem:** XML structure is invalid

**Solution:** Make sure the new section is INSIDE the main `<dict>` but BEFORE the closing `</dict></plist>`.

## Testing Different Scenarios

### Scenario 1: iOS Simulator (Default)
- URL: `http://localhost:8080`
- Should work immediately after adding settings

### Scenario 2: Physical iPhone/iPad (Same WiFi)
1. Find your Mac's IP address:
   - System Settings → Network → IP Address
   - Example: `192.168.1.5`

2. Update `AppConfiguration.swift`:
```swift
case .development:
    return "http://192.168.1.5:8080"  // Your Mac's IP
```

3. Make sure:
   - Mac and device on same WiFi network
   - Mac firewall allows incoming connections (System Settings → Network → Firewall)

### Scenario 3: Production (HTTPS)
1. Update `AppConfiguration.swift`:
```swift
case .production:
    return "https://api.naturallyyours.com"
```

2. Update Info.plist (remove `NSAllowsArbitraryLoads`)

3. Ensure your server has valid SSL certificate

## Still Not Working?

### Debug Checklist:

- [ ] Backend server is running (`lsof -i :8080` should show a process)
- [ ] Database is running (`docker ps` shows postgres container)
- [ ] Info.plist has transport security settings
- [ ] Info.plist changes were saved
- [ ] App was rebuilt after Info.plist changes
- [ ] URL in `AppConfiguration.swift` matches your backend
- [ ] For physical device: Mac and device on same network
- [ ] For physical device: Using Mac's IP address, not `localhost`

### View Xcode Logs:

1. Run the app in debug mode
2. Open the debug console (View → Debug Area → Activate Console)
3. Look for error messages starting with "NSURLSession" or "Network"
4. Common messages:
   - "App Transport Security has blocked..." = Info.plist issue
   - "Could not connect to the server" = Backend not running
   - "The network connection was lost" = Wrong URL or network issue

## Quick Reference

| Setting | Development | Production |
|---------|-------------|------------|
| `NSAllowsLocalNetworking` | ✅ YES | ✅ YES |
| `NSAllowsArbitraryLoads` | ✅ YES | ❌ NO |
| Use HTTPS | ❌ Optional | ✅ Required |

---

**Once this is set up, you won't need to touch it again during development!** ✨

Just remember to remove `NSAllowsArbitraryLoads` before submitting to the App Store! 🚀
