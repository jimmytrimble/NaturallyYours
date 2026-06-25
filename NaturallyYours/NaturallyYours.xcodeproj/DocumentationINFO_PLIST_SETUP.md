# Info.plist Configuration

Add these entries to your `Info.plist` file to enable local network connections during development.

## For Local Development (HTTP connections)

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## For Production (HTTPS only, more secure)

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>your-server.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```

## How to Edit Info.plist in Xcode

1. In Xcode, select your project in the navigator
2. Select your app target
3. Click on the "Info" tab
4. Right-click in the list and select "Add Row" or click the "+" button
5. Type "App Transport Security Settings"
6. Expand it and add the required keys

Alternatively, you can:
1. Right-click on `Info.plist` in the project navigator
2. Choose "Open As" → "Source Code"
3. Paste the XML directly into the file

## Important Security Notes

⚠️ **Never ship an app to production with `NSAllowsArbitraryLoads` set to `true`!**

For production:
- Use HTTPS exclusively
- Only add specific exception domains if absolutely necessary
- Implement certificate pinning for sensitive data
- Remove any insecure transport settings before App Store submission
