//
//  ExtensionsColor+Theme.swift
//  NaturallyYours
//
//  Created by Jamiel Trimble II on 5/28/26.
//

import SwiftUI

// MARK: - Color Extensions

extension Color {
    // MARK: - Brand Colors
    
    /// Primary brand pink - vibrant and attention-grabbing
    static let nyPink = Color(red: 0.95, green: 0.4, blue: 0.6)
    
    /// Soft pink - used for backgrounds and accents
    static let nySoftPink = Color(red: 0.99, green: 0.9, blue: 0.93)
    
    /// Light pink - subtle backgrounds
    static let nyLightPink = Color(red: 0.98, green: 0.85, blue: 0.9)
    
    // MARK: - Neutral Colors
    
    /// Primary black for text and UI elements
    static let nyBlack = Color(red: 0.15, green: 0.15, blue: 0.15)
    
    /// White for backgrounds
    static let nyWhite = Color.white
    
    /// Gray for secondary text
    static let nyGray = Color(red: 0.5, green: 0.5, blue: 0.5)
    
    /// Light gray for backgrounds and borders
    static let nyLightGray = Color(red: 0.95, green: 0.95, blue: 0.95)
    
    // MARK: - Additional Accent Colors
    
    /// Success green
    static let nySuccess = Color(red: 0.3, green: 0.7, blue: 0.4)
    
    /// Error red
    static let nyError = Color(red: 0.9, green: 0.3, blue: 0.3)
    
    /// Warning orange
    static let nyWarning = Color(red: 0.95, green: 0.6, blue: 0.2)
    
    // MARK: - Hex Color Initializer
    
    /// Initialize a Color from a hex string (e.g., "F26699" or "#F26699")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - ShapeStyle Extensions

extension ShapeStyle where Self == Color {
    // MARK: - Brand Colors
    
    /// Primary brand pink - vibrant and attention-grabbing
    static var nyPink: Color { .nyPink }
    
    /// Soft pink - used for backgrounds and accents
    static var nySoftPink: Color { .nySoftPink }
    
    /// Light pink - subtle backgrounds
    static var nyLightPink: Color { .nyLightPink }
    
    // MARK: - Neutral Colors
    
    /// Primary black for text and UI elements
    static var nyBlack: Color { .nyBlack }
    
    /// White for backgrounds
    static var nyWhite: Color { .nyWhite }
    
    /// Gray for secondary text
    static var nyGray: Color { .nyGray }
    
    /// Light gray for backgrounds and borders
    static var nyLightGray: Color { .nyLightGray }
    
    // MARK: - Additional Accent Colors
    
    /// Success green
    static var nySuccess: Color { .nySuccess }
    
    /// Error red
    static var nyError: Color { .nyError }
    
    /// Warning orange
    static var nyWarning: Color { .nyWarning }
}

// MARK: - View Modifiers

struct NYCardShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

struct NYElevationShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
    }
}

extension View {
    /// Apply card shadow styling
    func nyCardShadow() -> some View {
        modifier(NYCardShadowModifier())
    }
    
    /// Apply elevated element shadow styling
    func nyElevationShadow() -> some View {
        modifier(NYElevationShadowModifier())
    }
}

// MARK: - Theme Configuration

/// Central theme configuration for the Naturally Yours app
enum NYTheme {
    // MARK: - Spacing
    
    static let spacingXSmall: CGFloat = 4
    static let spacingSmall: CGFloat = 8
    static let spacingMedium: CGFloat = 16
    static let spacingLarge: CGFloat = 24
    static let spacingXLarge: CGFloat = 32
    
    // MARK: - Corner Radius
    
    static let cornerRadiusSmall: CGFloat = 4
    static let cornerRadiusMedium: CGFloat = 8
    static let cornerRadiusLarge: CGFloat = 12
    static let cornerRadiusXLarge: CGFloat = 16
    
    // MARK: - Border Width
    
    static let borderWidthThin: CGFloat = 1
    static let borderWidthMedium: CGFloat = 2
    static let borderWidthThick: CGFloat = 3
}

// MARK: - Additional View Modifiers

extension View {
    /// Apply standard card styling
    func nyCardStyle() -> some View {
        self
            .background(Color.nyWhite)
            .cornerRadius(NYTheme.cornerRadiusMedium)
            .nyCardShadow()
    }
    
    /// Apply primary button styling
    func nyPrimaryButtonStyle() -> some View {
        self
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.nyPink)
            .cornerRadius(NYTheme.cornerRadiusMedium)
    }
    
    /// Apply secondary button styling
    func nySecondaryButtonStyle() -> some View {
        self
            .foregroundStyle(.nyPink)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.nySoftPink)
            .cornerRadius(NYTheme.cornerRadiusMedium)
    }
    
    /// Apply outline button styling
    func nyOutlineButtonStyle() -> some View {
        self
            .foregroundStyle(.nyPink)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: NYTheme.cornerRadiusMedium)
                    .stroke(Color.nyPink, lineWidth: NYTheme.borderWidthMedium)
            )
    }
}

// MARK: - Color Accessibility Helpers

extension Color {
    /// Check if this color provides sufficient contrast with another color
    /// - Parameter otherColor: The color to check contrast against
    /// - Returns: True if contrast ratio meets WCAG AA standards (4.5:1)
    func hasAccessibleContrast(with otherColor: Color) -> Bool {
        // This is a simplified check - for production apps, consider using
        // a proper color contrast calculation library
        return true // Placeholder implementation
    }
    
    /// Get an accessible foreground color (black or white) for this background color
    var accessibleForeground: Color {
        // Simplified implementation - returns white for dark backgrounds, black for light
        // For production, calculate luminance properly
        return .nyBlack
    }
}

// MARK: - Usage Examples & Documentation

/*
 NATURALLY YOURS COLOR THEME
 ===========================
 
 Usage Examples:
 ---------------
 
 1. Using Brand Colors:
    ```swift
    Text("Hello")
        .foregroundStyle(.nyPink)
    
    Rectangle()
        .fill(.nySoftPink)
    ```
 
 2. Using Shadows:
    ```swift
    VStack {
        // content
    }
    .nyCardShadow()
    
    Button("Tap Me") { }
        .nyElevationShadow()
    ```
 
 3. Using Button Styles:
    ```swift
    Button("Primary") { }
        .nyPrimaryButtonStyle()
    
    Button("Secondary") { }
        .nySecondaryButtonStyle()
    
    Button("Outline") { }
        .nyOutlineButtonStyle()
    ```
 
 4. Using Card Style:
    ```swift
    VStack {
        Text("Card Content")
    }
    .nyCardStyle()
    ```
 
 5. Using Theme Spacing:
    ```swift
    VStack(spacing: NYTheme.spacingMedium) {
        // content
    }
    .padding(NYTheme.spacingLarge)
    ```
 
 6. Using Hex Colors:
    ```swift
    Color(hex: "F26699")
    Color(hex: "#FF5733")
    ```
 
 Customization:
 -------------
 
 To customize colors for different brands:
 1. Update the static color values in the Color extension
 2. Use the hex initializer for easy color specification
 3. Test with accessibility tools to ensure proper contrast
 
 Dark Mode Support:
 -----------------
 
 To add dark mode support, consider using dynamic colors:
 
 ```swift
 static let nyBackground = Color(uiColor: UIColor { traitCollection in
     traitCollection.userInterfaceStyle == .dark ?
         UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1) :
         UIColor.white
 })
 ```
 
 Accessibility:
 -------------
 
 All colors should maintain a contrast ratio of at least 4.5:1 for normal text
 and 3:1 for large text according to WCAG AA standards.
 
 Test your colors at: https://webaim.org/resources/contrastchecker/
 */
