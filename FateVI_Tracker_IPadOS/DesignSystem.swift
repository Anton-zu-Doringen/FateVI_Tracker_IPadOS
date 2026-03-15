import SwiftUI

enum Palette {
    static let parchment = Color(red: 0.95, green: 0.92, blue: 0.86)
    static let stone = Color(red: 0.16, green: 0.18, blue: 0.20)
    static let mist = Color(red: 0.85, green: 0.88, blue: 0.88)
    static let moss = Color(red: 0.28, green: 0.41, blue: 0.34)
    static let copper = Color(red: 0.66, green: 0.39, blue: 0.23)
    static let ember = Color(red: 0.70, green: 0.23, blue: 0.18)
    static let sand = Color(red: 0.82, green: 0.73, blue: 0.60)
    static let dusk = Color(red: 0.22, green: 0.24, blue: 0.28)
}

struct StageBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Palette.stone, Palette.dusk, Palette.moss.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Rectangle()
                .fill(
                    RadialGradient(
                        colors: [Palette.parchment.opacity(0.24), .clear],
                        center: .topTrailing,
                        startRadius: 10,
                        endRadius: 420
                    )
                )
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Palette.copper.opacity(0.18), .clear, Palette.mist.opacity(0.12)],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                )
        }
        .ignoresSafeArea()
    }
}

struct StageCard<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder var content: Content

    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(.title3, design: .serif, weight: .bold))
                    .foregroundStyle(Palette.parchment)
                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(Palette.mist.opacity(0.9))
                }
            }

            content
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Palette.parchment.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

struct SectionChip: View {
    let label: String
    let isActive: Bool

    var body: some View {
        Text(label)
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isActive ? Palette.parchment : Palette.parchment.opacity(0.08))
            .foregroundStyle(isActive ? Palette.stone : Palette.parchment)
            .clipShape(Capsule())
    }
}
