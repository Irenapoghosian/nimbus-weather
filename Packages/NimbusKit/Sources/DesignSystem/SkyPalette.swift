import SwiftUI
import WeatherCore

/// Background gradients: blue skies by day, deep navy at night, grays for clouds and rain.
public enum SkyPalette {
    public static func colors(for sky: WeatherCondition.Sky, isDay: Bool) -> [Color] {
        switch (sky, isDay) {
        case (.clear, true): [rgb(0x2F80ED), rgb(0x56CCF2)]
        case (.clear, false): [rgb(0x0B1026), rgb(0x2B3A67)]
        case (.cloudy, true): [rgb(0x5B7A99), rgb(0xA3B8CC)]
        case (.cloudy, false): [rgb(0x1C2333), rgb(0x3A4458)]
        case (.fog, true): [rgb(0x8E9EAB), rgb(0xC9D3DA)]
        case (.fog, false): [rgb(0x2A2F38), rgb(0x4A5160)]
        case (.rain, true): [rgb(0x3E5A73), rgb(0x6F8BA3)]
        case (.rain, false): [rgb(0x141B26), rgb(0x2E3D4F)]
        case (.snow, true): [rgb(0x7FA7C9), rgb(0xD6E6F2)]
        case (.snow, false): [rgb(0x1E2A3A), rgb(0x4C6178)]
        case (.storm, _): [rgb(0x1F1C2C), rgb(0x4B4A6B)]
        }
    }

    private static func rgb(_ hex: UInt32) -> Color {
        Color(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
