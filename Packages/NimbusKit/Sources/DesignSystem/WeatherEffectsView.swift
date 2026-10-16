import SwiftUI
import WeatherCore

/// The sky behind the forecast: a gradient for the weather and the time of day,
/// with rain, snow, clouds or stars moving over it.
public struct SkyBackground: View {
    private let condition: WeatherCondition
    private let isDay: Bool

    public init(condition: WeatherCondition, isDay: Bool) {
        self.condition = condition
        self.isDay = isDay
    }

    public var body: some View {
        ZStack {
            LinearGradient(colors: SkyPalette.colors(for: condition.sky, isDay: isDay), startPoint: .top, endPoint: .bottom)
            WeatherEffectsView(scene: SkyScene.scene(for: condition, isDay: isDay))
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.6), value: condition)
        .animation(.easeInOut(duration: 0.6), value: isDay)
    }
}

/// Rain, snow, clouds, stars and lightning, drawn in one `Canvas` up to 30 times a second.
/// With Reduce Motion on, the scene is drawn once and stays still, and lightning is off.
public struct WeatherEffectsView: View {
    private let scene: SkyScene
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(scene: SkyScene) {
        self.scene = scene
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                SkyPainter(scene: scene, time: time, size: size, animated: !reduceMotion).paint(in: context)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Draws one frame, one short function per layer.
struct SkyPainter {
    let scene: SkyScene
    let time: Double
    let size: CGSize
    let animated: Bool

    func paint(in context: GraphicsContext) {
        if scene.sunGlow { paintSunGlow(context) }
        if scene.stars > 0 { paintStars(context) }
        if scene.clouds > 0 { paintClouds(context) }
        if scene.rainDrops > 0 { paintRain(context) }
        if scene.snowFlakes > 0 { paintSnow(context) }
        if scene.lightning && animated { paintLightning(context) }
    }

    private func paintSunGlow(_ context: GraphicsContext) {
        let center = CGPoint(x: size.width * 0.82, y: size.height * 0.06)
        let radius = size.width * 0.8
        let pulse = 1 + 0.05 * sin(time * 0.5)
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        let glow = Gradient(colors: [Color(red: 1, green: 0.93, blue: 0.62).opacity(0.42 * pulse), .clear])
        context.fill(Path(ellipseIn: rect), with: .radialGradient(glow, center: center, startRadius: 0, endRadius: radius))
    }

    private func paintStars(_ context: GraphicsContext) {
        for index in 0..<scene.stars {
            let point = ParticleMath.star(index, in: size)
            let diameter = 1 + ParticleMath.noise(index, salt: 11) * 1.8
            let rect = CGRect(x: point.x, y: point.y, width: diameter, height: diameter)
            context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(ParticleMath.starOpacity(index, time: time))))
        }
    }

    private func paintClouds(_ context: GraphicsContext) {
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 22))
            for index in 0..<scene.clouds {
                let width = size.width * (0.55 + ParticleMath.noise(index, salt: 12) * 0.5)
                let height = width * 0.32
                let left = ParticleMath.cloudX(index, time: time, width: size.width, cloudWidth: width)
                let top = size.height * (0.02 + ParticleMath.noise(index, salt: 13) * 0.45)
                var puff = Path()
                puff.addEllipse(in: CGRect(x: left, y: top + height * 0.3, width: width, height: height * 0.7))
                puff.addEllipse(in: CGRect(x: left + width * 0.2, y: top, width: width * 0.45, height: height * 0.8))
                puff.addEllipse(in: CGRect(x: left + width * 0.45, y: top + height * 0.1, width: width * 0.4, height: height * 0.7))
                layer.fill(puff, with: .color(.white.opacity(scene.cloudOpacity)))
            }
        }
    }

    private func paintRain(_ context: GraphicsContext) {
        var streaks = Path()
        for index in 0..<scene.rainDrops {
            let top = ParticleMath.rainDrop(index, time: time, in: size)
            let length = 12 + ParticleMath.noise(index, salt: 14) * 12
            streaks.move(to: top)
            streaks.addLine(to: CGPoint(x: top.x - length * ParticleMath.rainSlant, y: top.y + length))
        }
        context.stroke(streaks, with: .color(.white.opacity(0.35)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
    }

    private func paintSnow(_ context: GraphicsContext) {
        var flakes = Path()
        for index in 0..<scene.snowFlakes {
            let center = ParticleMath.snowFlake(index, time: time, in: size)
            let radius = 1.5 + ParticleMath.noise(index, salt: 15) * 2.5
            flakes.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        }
        context.fill(flakes, with: .color(.white.opacity(0.8)))
    }

    private func paintLightning(_ context: GraphicsContext) {
        let flash = ParticleMath.lightningFlash(at: time)
        guard flash > 0 else { return }
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white.opacity(flash)))
    }
}
