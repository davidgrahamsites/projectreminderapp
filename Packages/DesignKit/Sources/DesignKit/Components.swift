import SwiftUI

// MARK: - Neumorphic surface

/// Soft raised/sunken surface. On watchOS, elevation is dialed down to a subtle stroke
/// (tiny OLED screen) while keeping the accent + rounding so it stays in the same family.
public struct NeumorphicSurface: ViewModifier {
    public enum Style { case raised, sunken }
    let style: Style
    let cornerRadius: CGFloat

    public init(_ style: Style = .raised, cornerRadius: CGFloat = Theme.cardCornerRadius) {
        self.style = style
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return content
            .background {
                #if os(watchOS)
                shape
                    .fill(style == .sunken ? Theme.surfaceSunken : Theme.surface)
                    .overlay(shape.strokeBorder(Theme.accent.opacity(0.18), lineWidth: 1))
                #else
                if style == .raised {
                    shape
                        .fill(Theme.surface)
                        .shadow(color: Theme.shadowDark.opacity(0.55), radius: 8, x: 6, y: 6)
                        .shadow(color: Theme.shadowLight.opacity(0.9), radius: 8, x: -6, y: -6)
                } else {
                    shape
                        .fill(Theme.surfaceSunken)
                        .overlay(shape.strokeBorder(Theme.shadowDark.opacity(0.35), lineWidth: 1))
                }
                #endif
            }
    }
}

public extension View {
    func raised(cornerRadius: CGFloat = Theme.cardCornerRadius) -> some View {
        modifier(NeumorphicSurface(.raised, cornerRadius: cornerRadius))
    }
    func sunken(cornerRadius: CGFloat = Theme.cardCornerRadius) -> some View {
        modifier(NeumorphicSurface(.sunken, cornerRadius: cornerRadius))
    }
    /// Full-screen app background (Theme.background, ignoring safe areas).
    func screenBackground() -> some View {
        background(Theme.background.ignoresSafeArea())
    }
}

// MARK: - Accent button

public struct AccentButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.display(15, .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(configuration.isPressed ? Theme.accentDeep : Theme.accent)
            )
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == AccentButtonStyle {
    static var accent: AccentButtonStyle { AccentButtonStyle() }
}

// MARK: - Initial badge

/// Circular badge with the project's first letter — the recurring motif from the reference kit.
public struct InitialBadge: View {
    let title: String
    var size: CGFloat

    public init(title: String, size: CGFloat = 40) {
        self.title = title
        self.size = size
    }

    public var body: some View {
        ZStack {
            Circle().fill(Theme.accent.opacity(0.16))
            Text(String(title.first.map(Character.init) ?? "•").uppercased())
                .font(Theme.display(size * 0.42, .bold))
                .foregroundStyle(Theme.accent)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Project row / card (the signature element)

/// An "Up Next" row: badge + rounded-semibold title + quiet meta.
public struct ProjectRow: View {
    let title: String
    let subtitle: String

    public init(title: String, subtitle: String = "") {
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        HStack(spacing: 12) {
            InitialBadge(title: title, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.display(16, .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

/// The head "Now" card: larger, accent-bordered, the project currently surfaced.
public struct ProjectCard: View {
    let title: String
    let subtitle: String

    public init(title: String, subtitle: String = "") {
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        HStack(spacing: 14) {
            InitialBadge(title: title, size: 52)
            VStack(alignment: .leading, spacing: 4) {
                Text("NOW")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(Theme.accent)
                Text(title)
                    .font(Theme.display(22, .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .raised()
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                .strokeBorder(Theme.accent.opacity(0.5), lineWidth: 1.5)
        )
    }
}
