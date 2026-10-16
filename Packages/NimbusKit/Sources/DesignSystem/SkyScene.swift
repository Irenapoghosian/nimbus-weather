import CoreGraphics
import Foundation
import WeatherCore

/// What moves over the sky for a condition: how many clouds, drops, flakes and stars, and whether
/// lightning flashes or the sun glows.
public struct SkyScene: Equatable, Sendable {
    public var clouds: Int
    public var cloudOpacity: Double
    public var rainDrops: Int
    public var snowFlakes: Int
    public var stars: Int
    public var lightning: Bool
    public var sunGlow: Bool

    public init(
        clouds: Int = 0,
        cloudOpacity: Double = 0,
        rainDrops: Int = 0,
        snowFlakes: Int = 0,
        stars: Int = 0,
        lightning: Bool = false,
        sunGlow: Bool = false
    ) {
        self.clouds = clouds
        self.cloudOpacity = cloudOpacity
        self.rainDrops = rainDrops
        self.snowFlakes = snowFlakes
        self.stars = stars
        self.lightning = lightning
        self.sunGlow = sunGlow
    }

    public static func scene(for condition: WeatherCondition, isDay: Bool) -> SkyScene {
        // White clouds read well on a day sky; at night they stay faint.
        let puff = isDay ? 0.22 : 0.1
        switch condition {
        case .clear: return SkyScene(stars: isDay ? 0 : 90, sunGlow: isDay)
        case .mainlyClear: return SkyScene(clouds: 2, cloudOpacity: puff, stars: isDay ? 0 : 60, sunGlow: isDay)
        case .partlyCloudy: return SkyScene(clouds: 4, cloudOpacity: puff, stars: isDay ? 0 : 25)
        case .overcast: return SkyScene(clouds: 7, cloudOpacity: puff)
        case .fog: return SkyScene(clouds: 9, cloudOpacity: 0.3)
        case .drizzle, .freezingDrizzle: return SkyScene(clouds: 5, cloudOpacity: puff, rainDrops: 60)
        case .rain, .freezingRain: return SkyScene(clouds: 6, cloudOpacity: puff, rainDrops: 140)
        case .rainShowers: return SkyScene(clouds: 5, cloudOpacity: puff, rainDrops: 100)
        case .snow: return SkyScene(clouds: 5, cloudOpacity: puff, snowFlakes: 90)
        case .snowShowers: return SkyScene(clouds: 4, cloudOpacity: puff, snowFlakes: 60)
        case .thunderstorm: return SkyScene(clouds: 7, cloudOpacity: puff, rainDrops: 160, lightning: true)
        case .unknown: return SkyScene()
        }
    }
}

/// Where each particle is at a moment in time. Pure functions of (index, time, size): nothing is stored
/// between frames, so the animation can't drift and every frame is reproducible in tests.
public enum ParticleMath {
    /// How far a rain streak leans: it moves this many points left for every point it falls.
    public static let rainSlant = 0.12
    /// How far a snowflake drifts to each side, in points.
    public static let snowSway = 14.0

    /// A stable pseudo-random number in 0..<1 for a particle (SplitMix64).
    public static func noise(_ index: Int, salt: Int = 0) -> Double {
        var value = UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15
        value &+= UInt64(bitPattern: Int64(salt)) &* 0xC2B2_AE3D_27D4_EB4F &+ 0x1656_67B1_9E37_79F9
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        value ^= value >> 31
        return Double(value >> 11) / 9_007_199_254_740_992
    }

    /// The part after the decimal point, always 0..<1, also for negative numbers.
    public static func fraction(_ value: Double) -> Double {
        value - value.rounded(.down)
    }

    /// The top of a rain streak. Drops cross the screen in about a second, then start again at the top.
    public static func rainDrop(_ index: Int, time: Double, in size: CGSize) -> CGPoint {
        let height = Double(size.height)
        let width = Double(size.width)
        let speed = 0.9 + noise(index, salt: 1) * 0.6
        let fall = fraction(noise(index, salt: 2) + time * speed) * (height + 60) - 30
        let start = noise(index, salt: 3) * (width * 1.2 + 40)
        return CGPoint(x: start - fall * rainSlant, y: fall)
    }

    /// A snowflake's center: it takes 8 to 20 seconds to fall and sways from side to side.
    public static func snowFlake(_ index: Int, time: Double, in size: CGSize) -> CGPoint {
        let height = Double(size.height)
        let speed = 0.05 + noise(index, salt: 4) * 0.07
        let fall = fraction(noise(index, salt: 5) + time * speed) * (height + 20) - 10
        let sway = sin(time * (0.6 + noise(index, salt: 6)) + noise(index, salt: 7) * 2 * .pi) * snowSway
        return CGPoint(x: noise(index, salt: 8) * Double(size.width) + sway, y: fall)
    }

    /// Stars stay put in the upper half of the sky.
    public static func star(_ index: Int, in size: CGSize) -> CGPoint {
        CGPoint(x: noise(index, salt: 16) * Double(size.width), y: noise(index, salt: 17) * Double(size.height) * 0.55)
    }

    /// Each star twinkles at its own pace, between 30% and 100% opacity.
    public static func starOpacity(_ index: Int, time: Double) -> Double {
        let rate = 0.5 + noise(index, salt: 18) * 1.5
        let wave = 0.5 + 0.5 * sin(time * rate + noise(index, salt: 19) * 2 * .pi)
        return 0.3 + 0.7 * wave
    }

    /// A cloud's left edge, drifting right and coming back in from the left.
    public static func cloudX(_ index: Int, time: Double, width: Double, cloudWidth: Double) -> Double {
        let speed = 0.004 + noise(index, salt: 20) * 0.008
        return fraction(noise(index, salt: 21) + time * speed) * (width + cloudWidth) - cloudWidth
    }

    /// The white flash of lightning: a double flicker at the start of most 6.5-second cycles, 0 otherwise.
    public static func lightningFlash(at time: Double, period: Double = 6.5) -> Double {
        let cycle = (time / period).rounded(.down)
        let phase = time - cycle * period
        guard noise(Int(cycle), salt: 22) < 0.7 else { return 0 }
        switch phase {
        case ..<0.08: return 0.5
        case 0.14..<0.22: return 0.3
        default: return 0
        }
    }
}
