import PhotosUI
import SwiftUI
import UIKit

enum DraftedColors {
    static let background = Color(red: 0.018, green: 0.018, blue: 0.021)
    static let elevated = Color.white.opacity(0.045)
    static let hairline = Color.white.opacity(0.14)
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.62)
    static let tertiaryText = Color.white.opacity(0.38)
}

struct ScreenScaffold<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            DraftedColors.background.ignoresSafeArea()
            content
        }
    }
}

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 24
    var material: Material = .ultraThinMaterial
    let content: Content

    init(cornerRadius: CGFloat = 28, material: Material = .ultraThinMaterial, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.material = material
        self.content = content()
    }

    var body: some View {
        content
            .background(material, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(DraftedColors.hairline, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.22), radius: 18, x: 0, y: 10)
    }
}

struct GlassButton: View {
    var title: String
    var systemImage: String
    var isProminent = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(.headline, design: .default, weight: .semibold))
            }
            .foregroundStyle(isProminent ? .black : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .padding(.horizontal, 20)
            .background(isProminent ? Color.white : DraftedColors.elevated, in: Capsule())
            .overlay {
                Capsule().stroke(Color.white.opacity(isProminent ? 0.0 : 0.22), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct CircleIconButton: View {
    var systemImage: String
    var size: CGFloat = 54
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(.ultraThinMaterial, in: Circle())
                .overlay { Circle().stroke(DraftedColors.hairline, lineWidth: 1) }
        }
        .buttonStyle(.plain)
    }
}

struct SectionHeader: View {
    var title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.headline, design: .default, weight: .semibold))
                .foregroundStyle(.white)
            if let subtitle {
                Text(subtitle)
                    .font(.system(.footnote, design: .default, weight: .medium))
                    .foregroundStyle(DraftedColors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AvatarView: View {
    var profile: DraftProfile?
    var player: DraftPlayer?
    var size: CGFloat = 58

    var body: some View {
        ZStack {
            if let data = profile?.avatarImageData,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: profile?.avatarPreset ?? player?.avatarPreset ?? "person.fill")
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: size, height: size)
                    .background(.regularMaterial, in: Circle())
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay { Circle().stroke(Color.white.opacity(0.28), lineWidth: 1) }
        .shadow(color: .white.opacity(0.10), radius: 10)
    }
}

struct XPProgressView: View {
    var progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.12))
                Capsule()
                    .fill(Color.white)
                    .frame(width: max(8, proxy.size.width * min(max(progress, 0), 1)))
            }
        }
        .frame(height: 8)
        .accessibilityLabel("XP progress")
    }
}

struct CategorySymbol: View {
    var symbol: String
    var size: CGFloat = 58

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.40, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(.regularMaterial, in: Circle())
            .overlay { Circle().stroke(Color.white.opacity(0.16), lineWidth: 1) }
    }
}

struct PillSelector<Value: Hashable & Identifiable>: View {
    var values: [Value]
    var title: (Value) -> String
    @Binding var selection: Value

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(values, id: \.id) { value in
                    Button {
                        selection = value
                    } label: {
                        Text(title(value))
                            .font(.system(.subheadline, design: .default, weight: .semibold))
                            .foregroundStyle(selection == value ? .black : .white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(selection == value ? Color.white : Color.white.opacity(0.08), in: Capsule())
                            .overlay { Capsule().stroke(Color.white.opacity(0.16), lineWidth: 1) }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
        }
        .scrollClipDisabled()
    }
}

struct EmptyStateView: View {
    var title: String
    var subtitle: String
    var symbol: String

    var body: some View {
        GlassCard {
            VStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                Text(title)
                    .font(.system(.headline, design: .default, weight: .bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(.subheadline, design: .default, weight: .medium))
                    .foregroundStyle(DraftedColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
        }
    }
}

enum ScreenTitleAlignment {
    case leading
    case center

    var horizontal: HorizontalAlignment {
        switch self {
        case .leading:
            return .leading
        case .center:
            return .center
        }
    }

    var text: TextAlignment {
        switch self {
        case .leading:
            return .leading
        case .center:
            return .center
        }
    }

    var frame: Alignment {
        switch self {
        case .leading:
            return .leading
        case .center:
            return .center
        }
    }
}

struct ScreenTitle: View {
    var title: String
    var subtitle: String?
    var alignment: ScreenTitleAlignment = .leading

    var body: some View {
        VStack(alignment: alignment.horizontal, spacing: 8) {
            Text(title)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(alignment.text)
                .lineLimit(3)
                .minimumScaleFactor(0.76)

            if let subtitle {
                Text(subtitle)
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(DraftedColors.secondaryText)
                    .multilineTextAlignment(alignment.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment.frame)
    }
}

struct StatusPill: View {
    var title: String
    var isProminent = false

    var body: some View {
        Text(title)
            .font(.system(.caption, weight: .semibold))
            .foregroundStyle(isProminent ? .black : .white)
            .lineLimit(1)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(isProminent ? Color.white : Color.white.opacity(0.08), in: Capsule())
            .overlay {
                Capsule().stroke(Color.white.opacity(isProminent ? 0 : 0.14), lineWidth: 1)
            }
    }
}

struct FloatingSticker: View {
    var symbol: String

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .shadow(color: .white.opacity(0.45), radius: 8)
            .accessibilityHidden(true)
    }
}

extension View {
    func draftedNavigationTitle(_ title: String) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}
