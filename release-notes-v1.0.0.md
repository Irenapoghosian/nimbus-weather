# Nimbus 1.0.0

The first release of Nimbus, a weather app for iPhone built with SwiftUI on the free Open-Meteo API.

## Highlights

- **Weather where you are and in any city** — Core Location for "My Location", worldwide city search, swipe between saved cities, delete and reorder.
- **A living sky** — rain, snow, drifting clouds, twinkling stars and lightning, drawn with `Canvas` and `TimelineView`. Reduce Motion keeps it still.
- **Next 24 hours as a chart** — a Swift Charts temperature curve or chance-of-rain bars; drag to read any hour, labelled in the city's own time zone.
- **10-day forecast** with each day's range on the week's shared scale, plus feels like, humidity, wind, pressure, UV, sunrise and sunset.
- **Widgets** — small and medium on the Home Screen, circular, rectangular and inline on the Lock Screen. Each widget picks its own city; tapping it opens that city in the app.

## Under the hood

- 7 Swift packages with one-way dependencies: `WeatherCore`, `OpenMeteo`, `LocationKit`, `DesignSystem`, `WeatherFeature`, `WidgetFeature`.
- `@Observable` view models, async/await, protocols at every edge.
- 89 unit tests, SwiftLint in strict mode and a coverage badge, all in GitHub Actions.
- No API key and no App Group: builds with a free Apple ID.

## Requirements

iOS 17 or later. Build with Xcode 16 or later and XcodeGen (see the README).

Weather data by [Open-Meteo.com](https://open-meteo.com/) (CC BY 4.0).
