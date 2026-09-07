import SwiftUI

enum OmiTheme {
    static let background = Color.black
    static let card = Color.white.opacity(0.07)
    static let tertiary = Color.white.opacity(0.10)
    static let muted = Color(red: 142 / 255, green: 142 / 255, blue: 147 / 255)
    static let meta = Color(white: 0.62)
    static let amber = Color(red: 1, green: 0.76, blue: 0.03)
    static let purple = Color(red: 0.45, green: 0.22, blue: 0.92)
    static let cyan = Color(red: 90 / 255, green: 200 / 255, blue: 250 / 255)
    static let recapHero = Color(red: 0.22, green: 0.14, blue: 0.42)
    static let green = Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255)
}

extension View {
    func omiScreenBackground() -> some View {
        background {
            LinearGradient(
                colors: [Color.black, Color(red: 0.06, green: 0.05, blue: 0.10)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    func omiGlass<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular.interactive(), in: shape)
        } else {
            background(.ultraThinMaterial, in: shape)
        }
    }

    func omiSurface(radius: CGFloat = 20) -> some View {
        background(OmiTheme.card, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    @ViewBuilder
    func omiSearchGlass(radius: CGFloat = 16) -> some View {
        omiGlass(in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

struct GlassChipButton: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glass)
                .controlSize(.small)
                .buttonBorderShape(.capsule)
        } else {
            content
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08), in: Capsule())
        }
    }
}

struct GlassCircleButton: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glass).buttonBorderShape(.circle)
        } else {
            content
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(.white.opacity(0.12), in: Circle())
        }
    }
}

struct GlassSendButton: ViewModifier {
    let empty: Bool
    func body(content: Content) -> some View {
        content
            .foregroundStyle(empty ? .black : .white)
            .frame(width: 32, height: 32)
            .background(empty ? Color.white : OmiTheme.purple, in: Circle())
    }
}

struct AppActionButton: View {
    let title: String
    var enabledLook: Bool
    var prominent: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: prominent ? 16 : 13, weight: .semibold))
                .foregroundStyle(enabledLook ? .white : .black)
                .frame(maxWidth: prominent ? .infinity : nil)
                .padding(.horizontal, prominent ? 16 : 14)
                .padding(.vertical, prominent ? 13 : 7)
        }
        .buttonStyle(.plain)
        .background(enabledLook ? Color.white.opacity(0.16) : Color.white, in: Capsule())
    }
}

struct GlassFAB: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 48, height: 48)
            .background(OmiTheme.purple, in: Circle())
            .shadow(color: OmiTheme.purple.opacity(0.35), radius: 10, y: 4)
    }
}

struct SectionHeader: View {
    let title: String
    var action: String? = "View all"
    var onAction: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
            Spacer()
            if let action, let onAction {
                Button(action, action: onAction)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 10)
    }
}
