import Charts
import DesignSystem
import SwiftUI
import WeatherCore

/// Temperature or chance of rain over the next 24 hours. Drag across the chart to read an hour.
///
/// The two metrics are two separate `Chart`s. Switching mark types with `if` inside one chart's `ForEach`
/// builds a very deep generic type that crashed Swift Charts at runtime.
struct HourlyChartView: View {
    let hours: [HourlyForecast]
    let timeZone: TimeZone
    @State private var metric = ChartMetric.temperature
    @State private var selectedTime: Date?

    private static let areaFill = LinearGradient(
        colors: [.orange.opacity(0.45), .orange.opacity(0.02)],
        startPoint: .top,
        endPoint: .bottom
    )

    private var points: [ChartPoint] { HourlyChartData.points(from: hours) }

    /// The hour under the finger, as a list of zero or one, so the chart needs no `if`.
    private var selection: [ChartPoint] {
        HourlyChartData.nearest(to: selectedTime, in: points).map { [$0] } ?? []
    }

    var body: some View {
        GlassCard("Next 24 hours", systemImage: "chart.xyaxis.line") {
            Picker("Chart", selection: $metric) {
                ForEach(ChartMetric.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)
            Group {
                if metric == .temperature {
                    styled(temperatureChart)
                } else {
                    styled(rainChart)
                }
            }
            .frame(height: 170)
        }
    }

    private var temperatureChart: some View {
        let base = HourlyChartData.domain(for: .temperature, points: points).lowerBound
        return Chart {
            ForEach(points) { point in
                AreaMark(
                    x: .value("Time", point.time),
                    yStart: .value("Base", base),
                    yEnd: .value("Temperature", point.temperature)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Self.areaFill)
            }
            ForEach(points) { point in
                LineMark(x: .value("Time", point.time), y: .value("Temperature", point.temperature))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .foregroundStyle(.white)
            }
            ForEach(selection) { point in
                selectionRule(at: point)
            }
        }
        .chartYScale(domain: HourlyChartData.domain(for: .temperature, points: points))
    }

    private var rainChart: some View {
        Chart {
            ForEach(points) { point in
                BarMark(x: .value("Time", point.time, unit: .hour), y: .value("Chance of rain", point.precipitationChance))
                    .foregroundStyle(.cyan)
                    .cornerRadius(3)
            }
            ForEach(selection) { point in
                selectionRule(at: point)
            }
        }
        .chartYScale(domain: HourlyChartData.domain(for: .precipitation, points: points))
    }

    private func selectionRule(at point: ChartPoint) -> some ChartContent {
        RuleMark(x: .value("Selected", point.time))
            .foregroundStyle(.white.opacity(0.6))
            .annotation(position: .top, spacing: 4, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                selectionLabel(for: point)
            }
    }

    /// Selection and axes shared by both charts.
    private func styled(_ chart: some View) -> some View {
        chart
            .chartXSelection(value: $selectedTime)
            .chartXAxis {
                AxisMarks(values: HourlyChartData.axisDates(for: points, in: timeZone)) { value in
                    AxisGridLine().foregroundStyle(.white.opacity(0.15))
                    AxisValueLabel {
                        Text(value.as(Date.self).map { NimbusFormat.hour($0, in: timeZone) } ?? "")
                    }
                    .foregroundStyle(.white.opacity(0.7))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine().foregroundStyle(.white.opacity(0.15))
                    AxisValueLabel {
                        Text(HourlyChartData.label(value.as(Double.self) ?? 0, metric: metric))
                    }
                    .foregroundStyle(.white.opacity(0.7))
                }
            }
    }

    private func selectionLabel(for point: ChartPoint) -> some View {
        VStack(spacing: 2) {
            Text(NimbusFormat.hour(point.time, in: timeZone)).font(.caption2)
            Text(HourlyChartData.label(point.value(for: metric), metric: metric)).font(.caption.weight(.bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.black.opacity(0.35), in: Capsule())
    }
}
