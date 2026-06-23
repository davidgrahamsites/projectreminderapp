import SwiftUI

/// Shared design tokens for Project Reminder. Code-defined (no asset catalog) and light/dark aware.
/// See `design.md` for the full direction. Agent D expands this into the full component set.
public enum Theme {

    // MARK: Color tokens (light / dark)

    public static let accent      = adaptive(light: 0x7C3AED, dark: 0x9D6BFF)
    public static let accentDeep  = adaptive(light: 0x5B21B6, dark: 0x7C3AED)
    public static let background  = adaptive(light: 0xECEDF3, dark: 0x16161E)
    public static let surface     = adaptive(light: 0xF1F2F8, dark: 0x23232F)
    public static let surfaceSunken = adaptive(light: 0xE4E5EE, dark: 0x1B1B24)
    public static let shadowLight = adaptive(light: 0xFFFFFF, dark: 0x2C2C3A)
    public static let shadowDark  = adaptive(light: 0xC9CBD8, dark: 0x0C0C12)
    public static let textPrimary = adaptive(light: 0x2A2A35, dark: 0xECEDF2)
    public static let textSecondary = adaptive(light: 0x8A8A99, dark: 0x9A9AAB)

    // MARK: Shape

    public static let cardCornerRadius: CGFloat = 20

    // MARK: Type — SF Rounded matches the soft neumorphic surfaces

    public static func display(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    // MARK: Helper

    /// Build a Color that resolves per color scheme. Cross-platform (iOS/watchOS/macOS).
    static func adaptive(light: UInt, dark: UInt) -> Color {
        Color(light: Color(hex: light), dark: Color(hex: dark))
    }
}

public extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    /// Resolve different colors for light vs dark without an asset catalog.
    init(light: Color, dark: Color) {
        #if os(watchOS)
        // watchOS has no light mode (always dark OLED) and no UIColor dynamic provider.
        self = dark
        #elseif canImport(UIKit)
        self.init(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #elseif canImport(AppKit)
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDark ? NSColor(dark) : NSColor(light)
        })
        #else
        self = light
        #endif
    }
}
