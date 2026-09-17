import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.49, green: 0.69, blue: 0.98)
    static let secondaryAccent = Color(red: 0.74, green: 0.80, blue: 0.97)
    static let pageBackground = Color(red: 0.04, green: 0.05, blue: 0.08)
    static let consoleBackground = Color(red: 0.02, green: 0.03, blue: 0.05)
    static let referenceCard = Color(red: 0.10, green: 0.12, blue: 0.18)
    static let panelCard = Color(red: 0.12, green: 0.14, blue: 0.21)
    static let subtleLine = Color.white.opacity(0.08)
    static let pageInset: CGFloat = 18
    static let rowIconSize: CGFloat = 17
    static let rowIconFrame: CGFloat = 28
    static let fileRowIconSize: CGFloat = 17
    static let fileRowIconFrame: CGFloat = 30
    static let fileRowHeight: CGFloat = 60
    static let appIconSize: CGFloat = 32
    static let emptyIconSize: CGFloat = 30
    static let selectionIconSize: CGFloat = 18

    static let cardCornerRadius: CGFloat = 18
    static let sectionSpacing: CGFloat = 18

    static func surface<S: ShapeStyle>(_ style: S = AppTheme.referenceCard) -> some View {
        RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
            .fill(style)
    }
}

struct AppRowIcon: View {
    let systemName: String
    var tint: Color = AppTheme.accent
    var symbolSize: CGFloat = AppTheme.rowIconSize
    var frameSize: CGFloat = AppTheme.rowIconFrame

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(tint.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(tint.opacity(0.15), lineWidth: 1)
                )
            Image(systemName: systemName)
                .font(.system(size: symbolSize, weight: .medium))
                .foregroundStyle(tint)
        }
        .frame(width: frameSize, height: frameSize)
        .accessibilityHidden(true)
    }
}

struct AppSearchField: View {
    @Binding var text: String
    let prompt: String
    let clearLabel: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField(prompt, text: $text)
                .font(.body.weight(.medium))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(clearLabel)
            }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 42)
        .background(
            AppTheme.referenceCard,
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.subtleLine, lineWidth: 1)
        )
        .padding(.horizontal, AppTheme.pageInset)
        .padding(.vertical, 8)
    }
}

struct AppLogo: View {
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let icon = UIImage(named: "AppIcon60x60")
                ?? Bundle.main.path(forResource: "AppIcon60x60@2x", ofType: "png").flatMap(UIImage.init(contentsOfFile:))
                ?? UIImage(named: "AppIcon") {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(colors: [AppTheme.accent, AppTheme.secondaryAccent], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .accessibilityHidden(true)
    }
}
