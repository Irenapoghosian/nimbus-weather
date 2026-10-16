import CoreGraphics
import DesignSystem
import WeatherCore
import XCTest

final class SkySceneTests: XCTestCase {
    func testClearSkiesGlowByDayAndShowStarsAtNight() {
        let day = SkyScene.scene(for: .clear, isDay: true)
        let night = SkyScene.scene(for: .clear, isDay: false)

        XCTAssertTrue(day.sunGlow)
        XCTAssertEqual(day.stars, 0)
        XCTAssertFalse(night.sunGlow)
        XCTAssertGreaterThan(night.stars, 0)
    }

    func testRainSnowAndStormsHaveTheirParticles() {
        XCTAssertGreaterThan(SkyScene.scene(for: .rain, isDay: true).rainDrops, SkyScene.scene(for: .drizzle, isDay: true).rainDrops)
        XCTAssertGreaterThan(SkyScene.scene(for: .snow, isDay: false).snowFlakes, 0)

        let storm = SkyScene.scene(for: .thunderstorm, isDay: true)
        XCTAssertTrue(storm.lightning)
        XCTAssertGreaterThan(storm.rainDrops, 0)
    }

    func testNoConditionMixesRainAndSnowOrSunAndStars() {
        for condition in WeatherCondition.allCases {
            for isDay in [true, false] {
                let scene = SkyScene.scene(for: condition, isDay: isDay)
                XCTAssertFalse(scene.rainDrops > 0 && scene.snowFlakes > 0, "\(condition)")
                XCTAssertFalse(scene.sunGlow && scene.stars > 0, "\(condition)")
                XCTAssertTrue((0...1).contains(scene.cloudOpacity), "\(condition)")
            }
        }
    }

    func testCloudsShowWheneverTheSkyIsCloudy() {
        XCTAssertGreaterThan(SkyScene.scene(for: .overcast, isDay: true).clouds, SkyScene.scene(for: .partlyCloudy, isDay: true).clouds)
        XCTAssertGreaterThan(SkyScene.scene(for: .fog, isDay: false).cloudOpacity, SkyScene.scene(for: .overcast, isDay: false).cloudOpacity)
        XCTAssertEqual(SkyScene.scene(for: .unknown, isDay: true), SkyScene())
    }
}

final class ParticleMathTests: XCTestCase {
    private let screen = CGSize(width: 390, height: 844)

    func testNoiseIsStableAndInRange() {
        for index in 0..<500 {
            let value = ParticleMath.noise(index, salt: 3)
            XCTAssertTrue((0..<1).contains(value))
            XCTAssertEqual(value, ParticleMath.noise(index, salt: 3))
        }
        XCTAssertNotEqual(ParticleMath.noise(1, salt: 1), ParticleMath.noise(1, salt: 2))
        XCTAssertNotEqual(ParticleMath.noise(1), ParticleMath.noise(2))
    }

    func testFractionWrapsNegativeNumbersToo() {
        XCTAssertEqual(ParticleMath.fraction(2.25), 0.25, accuracy: 1e-9)
        XCTAssertEqual(ParticleMath.fraction(-0.25), 0.75, accuracy: 1e-9)
    }

    func testRainFallsAndWrapsWithinTheScreen() {
        for index in 0..<100 {
            let earlier = ParticleMath.rainDrop(index, time: 1000, in: screen)
            let later = ParticleMath.rainDrop(index, time: 1000.05, in: screen)
            XCTAssertTrue((-30...screen.height + 30).contains(earlier.y))
            // Either it fell a little, or it reached the bottom and started again at the top.
            let moved = later.y - earlier.y
            XCTAssertTrue(moved > 0 || moved < -screen.height / 2, "drop \(index)")
        }
    }

    func testSnowSwaysButStaysNearItsColumn() {
        for index in 0..<100 {
            let column = CGFloat(ParticleMath.noise(index, salt: 8)) * screen.width
            for time in stride(from: 0.0, to: 60, by: 7.3) {
                let flake = ParticleMath.snowFlake(index, time: time, in: screen)
                XCTAssertLessThanOrEqual(Double(abs(flake.x - column)), ParticleMath.snowSway + 1e-6)
                XCTAssertTrue((-10...screen.height + 10).contains(flake.y))
            }
        }
    }

    func testStarsTwinkleBetweenDimAndBright() {
        let opacities = stride(from: 0.0, to: 20, by: 0.1).map { ParticleMath.starOpacity(4, time: $0) }
        XCTAssertGreaterThanOrEqual(opacities.min() ?? 0, 0.3 - 1e-9)
        XCTAssertLessThanOrEqual(opacities.max() ?? 1, 1 + 1e-9)
        XCTAssertGreaterThan((opacities.max() ?? 0) - (opacities.min() ?? 0), 0.3)
        XCTAssertLessThan(ParticleMath.star(9, in: screen).y, screen.height * 0.55)
    }

    func testCloudsDriftAcrossAndComeBack() {
        for time in stride(from: 0.0, to: 2000, by: 37) {
            let left = ParticleMath.cloudX(2, time: time, width: 390, cloudWidth: 250)
            XCTAssertTrue((-250...390).contains(left))
        }
    }

    func testLightningIsRareAndNeverBlinding() {
        let flashes = stride(from: 0.0, to: 650, by: 0.02).map { ParticleMath.lightningFlash(at: $0) }
        let lit = flashes.filter { $0 > 0 }

        XCTAssertFalse(lit.isEmpty)
        XCTAssertLessThan(Double(lit.count) / Double(flashes.count), 0.05)
        XCTAssertLessThanOrEqual(flashes.max() ?? 0, 0.5)
    }
}
