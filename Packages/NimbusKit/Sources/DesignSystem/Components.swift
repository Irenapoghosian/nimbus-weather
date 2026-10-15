import SwiftUI
import WeatherCore

/// A frosted card over the sky, with an optional small caps header like Apple Weather.
public struct GlassCard<Content: View>: View {
    private let title: String?
    private let systemImage: String?
    private let content: Content

    public init(_ title: String? = nil, systemImage: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                header(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .accessibilityAddTraits(.isHeader)
                Divider().overlay(.white.opacity(0.25))
            }
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial.opacity(0.9), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.2))
        )
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder
    private func header(_ title: String) -> some View {
        if let systemImage {
            Label(title.uppercased(), systemImage: systemImage)
        } else {
            Text(title.uppercased())
        }
    }
}

/// The condition's SF Symbol in full color.
public struct ConditionIcon: View {
    private let condition: WeatherCondition
    private let isDay: Bool

    public init(_ condition: WeatherCondition, isDay: Bool = true) {
        self.condition = condition
        self.isDay = isDay
    }

    public var body: some View {
        Image(systemName: condition.symbolName(isDay: isDay))
            .symbolRenderingMode(.multicolor)
            .accessibilityLabel(condition.title)
    }
}

/// A day's low-to-high bar on the week's shared temperature scale.
public struct TemperatureRangeBar: View {
    private let position: ClosedRange<Double>

    public init(position: ClosedRange<Double>) {
        self.position = position
    }

    public var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.18))
                Capsule()
                    .fill(LinearGradient(colors: [.cyan, .green, .yellow, .orange], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(6, width * (position.upperBound - position.lowerBound)))
                    .offset(x: width * position.lowerBound)
            }
        }
        .frame(height: 5)
        .accessibilityHidden(true)
    }
}
