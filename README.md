<p align="center">
  <img src="App/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="120" alt="Nimbus app icon">
</p>

<h1 align="center">Nimbus</h1>

<p align="center">
  A weather app for iPhone in SwiftUI: your location and saved cities, the next 24 hours, a 10-day forecast,
  and skies that change with the weather. Built on the free Open-Meteo API, with no API key.
</p>

<p align="center">
  <img alt="iOS 17+" src="https://img.shields.io/badge/iOS-17%2B-black">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-5.10-orange">
  <img alt="SwiftUI" src="https://img.shields.io/badge/UI-SwiftUI-0a84ff">
  <img alt="CI" src="https://github.com/Irenapoghosian/nimbus-weather/actions/workflows/ci.yml/badge.svg">
  <img alt="Coverage" src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/Irenapoghosian/nimbus-weather/badges/coverage.json">
  <img alt="SwiftLint" src="https://img.shields.io/badge/lint-SwiftLint-blue">
  <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-lightgrey">
</p>

---

<p align="center">
  <img src="docs/screenshots/hero.png" alt="Nimbus on iPhone: a cloudy day with the rain chart, a clear night with stars and the temperature curve, the Home Screen widget, and the city list">
</p>

## Screenshots

| Day | Night | 10 days | Widget | Cities |
|:--:|:--:|:--:|:--:|:--:|
| <img src="docs/screenshots/day.png" width="160"> | <img src="docs/screenshots/night.png" width="160"> | <img src="docs/screenshots/daily.png" width="160"> | <img src="docs/screenshots/widget.png" width="160"> | <img src="docs/screenshots/cities.png" width="160"> |

## Demo

https://github.com/user-attachments/assets/54e7a4c0-50a2-4339-88d5-40338124501b

## Features

- **Weather where you are** — Core Location finds you (city-level accuracy is enough and answers faster), and the page is named after your city. If location is off, the page says so and offers a button to Settings.
- **Saved cities** — search any city in the world, swipe between cities like in Apple Weather, delete with a swipe and reorder by dragging. The list survives relaunches.
- **A living sky** — rain streaks, drifting snow, slow clouds, twinkling stars at night, a warm sun glow, and lightning in storms, drawn with `Canvas` and `TimelineView`. With Reduce Motion on, the sky holds still.
- **Now** — temperature, condition, today's high and low.
- **Next 24 hours** — a strip of hours with icons (moons at night) and the chance of rain when it's worth mentioning.
- **Chart** — the next 24 hours as a temperature curve or chance-of-rain bars (Swift Charts). Drag across it to read any hour.
- **10 days** — each day's low-to-high bar is drawn on the same scale as the rest of the week, so a cold day looks cold.
- **Details** — feels like, humidity, wind with its direction, pressure, UV index with its level, sunrise and sunset, all in the city's own time zone.
- **Widgets** — small and medium on the Home Screen, plus circular, rectangular and inline on the Lock Screen. Each widget has its own city: long-press, *Edit Widget*, and search any city in the world. Tapping a widget opens Nimbus on that city.
- **Pull to refresh**, and a quiet refresh when the app comes back after ten minutes or more.
- **Errors that help** — offline, the service not answering, location denied: each has its own message and a way out. A failed refresh never wipes a forecast that is already on screen.
- **Privacy** — coordinates are rounded to two decimals (about 1 km) before they leave the phone.

## Architecture

A local Swift package, `NimbusKit`, holds everything except the app's entry point. Modules only depend inward, on `WeatherCore`:

```mermaid
flowchart LR
    App["Nimbus app<br/>(composition root)"] --> Feature[WeatherFeature]
    App --> OpenMeteo
    App --> LocationKit
    Widgets["Widget extension"] --> WidgetFeature
    Widgets --> OpenMeteo
    WidgetFeature --> Core
    WidgetFeature --> Design
    Feature --> Core[WeatherCore]
    Feature --> Design[DesignSystem]
    Design --> Core
    OpenMeteo --> Core
    LocationKit --> Core
```

| Module | What's inside |
|---|---|
| `WeatherCore` | `Place`, `Forecast`, `WeatherCondition` (WMO codes), the service protocols, `WeatherError`, and `ForecastRules`: pure functions for the next hours, the week's temperature scale, compass directions and UV levels. Foundation only. |
| `OpenMeteo` | `OpenMeteoClient` for forecasts and city search. Decodes Open-Meteo's column-shaped JSON and turns it into rows, skipping gaps instead of showing zeros. Network and decoding errors come out as `WeatherError`. |
| `LocationKit` | `DeviceLocationProvider` wraps `CLLocationManager` and `CLGeocoder` in `async` calls. |
| `DesignSystem` | Sky gradients and the animated sky (`SkyScene`, `ParticleMath`, `WeatherEffectsView`), number and time formats, and reusable views: glass cards, condition icons, temperature bars. |
| `WeatherFeature` | `@Observable` view models (`NimbusModel`, `WeatherViewModel`, `PlaceSearchModel`), the hourly chart and the SwiftUI screens. |
| `WidgetFeature` | Widget entries, `WeatherEntryLoader` (the app's `ForecastService` turned into timelines) and the views for every widget size. |

### Key decisions

- **Protocols at the edges.** The screens know `ForecastService`, `PlaceSearchService`, `LocationProvider` and `PlacesStore`, never Open-Meteo or Core Location. Tests use fakes, and another weather provider would be one new type.
- **One page model per city.** Each page loads itself the first time it appears and keeps its own state, so swiping to a city that failed doesn't affect the others.
- **Time zones done right.** Open-Meteo is asked for Unix times plus the city's time zone, so "Today", "15:00" and sunrise are always the city's, not the phone's.
- **Search that waits for you.** Typing restarts a short pause (`.task(id:)` cancels the previous one), so the API is called once you stop typing, not on every key.
- **Particles without state.** Every raindrop, snowflake and star is a pure function of its index and the current time, so nothing is stored between frames, nothing drifts, and the motion is unit-tested like any other code.
- **Widgets without an App Group.** A widget keeps its city in its own configuration (an App Intent with a searchable `CityEntity`), so it never needs to read the app's storage. Several widgets can show several cities, and the app builds with a free Apple ID.
- **Testable time.** View models take a clock, so "is this forecast older than ten minutes?" is tested without waiting.

## Requirements

- Xcode 16 or later, iOS 17 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

No API key is needed.

## Getting started

```bash
git clone https://github.com/Irenapoghosian/nimbus-weather.git
cd nimbus-weather
xcodegen
open Nimbus.xcodeproj
```

Press **⌘R** to run, or **⌘U** to run the tests. In the Simulator, pick a location with **Features → Location**.

To try the widget, run the **NimbusWidgets** scheme: it puts the widget straight onto the simulator's Home Screen.

## Testing

**89 unit tests**, run on every push by GitHub Actions together with SwiftLint in strict mode. The coverage badge counts logic files; SwiftUI views and the thin Core Location and URLSession wrappers are checked by running the app.

- `OpenMeteoClientTests`, `DecodingTests` — real response shapes as fixtures: mapping, skipped gaps, columns of different lengths, Unix and local times, request URLs, rounded coordinates, offline and server errors.
- `WeatherConditionTests`, `ForecastRulesTests`, `PlaceTests` — WMO codes, day and night symbols, the next 24 hours, the week's scale, compass, UV, saving cities.
- `LocationNamingTests` — naming your location from a city, a region or nothing.
- `NimbusFormatTests` — temperatures (never "-0°"), times in the city's time zone, "Today".
- `SkySceneTests`, `ParticleMathTests` — which effects each weather gets, drops that fall and wrap, snow that sways in its column, stars that twinkle, rare and gentle lightning.
- `WidgetFeatureTests`, `PlaceLinkTests` — widget snapshots, the Lock Screen gauge's scale, refresh and retry times, and the `nimbus://` links widgets open.
- `HourlyChartDataTests` — the chart's scale, missing rain chances, picking the nearest hour, labels.
- `WeatherViewModelTests`, `PlaceSearchModelTests`, `NimbusModelTests`, `ForecastDetailsTests` — loading, errors, keeping a forecast after a failed refresh, the ten-minute rule, search, adding, deleting and reordering cities.

## Roadmap

- [x] Forecasts, location, city search, saved cities, tests and CI
- [x] Animated skies (rain, snow, clouds, stars, lightning) and Swift Charts for temperature and rain
- [x] Home Screen and Lock Screen widgets
- [ ] An Apple Watch app
- [x] Screenshots, a demo video and the first release (v1.0.0)

## Credits

[Weather data by Open-Meteo.com](https://open-meteo.com/), under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). The app shows this credit under every forecast.

## Author

**Irena Poghosyan** — iOS developer · [GitHub](https://github.com/Irenapoghosian)

## License

MIT. See [LICENSE](LICENSE).
