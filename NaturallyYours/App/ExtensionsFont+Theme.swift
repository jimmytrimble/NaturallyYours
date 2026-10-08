import SwiftUI

extension Font {
    // MARK: - Brand Typography
    
    /// Naturally Yours brand logo font
    /// Use a handwritten/script style font. System default until custom font is added.
    static func nyLogoFont(size: CGFloat = 34) -> Font {
        // TODO: Add custom handwritten font to project
        // For now, use a cursive system font or fall back to system
        // When you add a custom font file (like "NaturallyYours.ttf"), use:
        // return .custom("YourCustomFontName", size: size)
        
        // Using system's rounded design as a softer alternative for now
        return .system(size: size, weight: .medium, design: .rounded).italic()
    }
    
    /// Heading font - bold and clean
    static func nyHeading(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }
    
    /// Subheading font
    static func nySubheading(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }
    
    /// Body text
    static func nyBody(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }
    
    /// Caption/small text
    static func nyCaption(_ size: CGFloat = 14) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }
}

// MARK: - View Modifier for Logo Text

struct NaturallyYoursLogoModifier: ViewModifier {
    let size: CGFloat
    
    func body(content: Content) -> some View {
        content
            .font(.nyLogoFont(size: size))
            .foregroundStyle(.white)
    }
}

extension View {
    /// Apply the Naturally Yours logo styling
    func nyLogoStyle(size: CGFloat = 34) -> some View {
        self.modifier(NaturallyYoursLogoModifier(size: size))
    }
}

// MARK: - Instructions for Adding Custom Font
/*
 To add the exact "Naturally Yours" handwritten font:
 
 1. Get the font file (e.g., a .ttf or .otf file with the handwritten style)
 2. Add it to your Xcode project
 3. Add the font file name to Info.plist under "Fonts provided by application"
 4. Update the nyLogoFont() function above to use:
    return .custom("YourFontName", size: size)
 
 Some similar handwritten/script fonts to consider:
 - Pacifico
 - Dancing Script
 - Great Vibes
 - Sacramento
 - Allura
 - Playlist Script
 */
