// ────────────────────────────────────────────────────────
// NotchSuperior — NSWeatherEngine.swift
// Part of the boring.notch fork
// Phase: 11 — Weather (zero API key via Open-Meteo)
// Created: 2026-06-15
// NOTCHSUPERIOR ADDITION
// Uses CoreLocation + Open-Meteo free public API.
// No API key. No account. Works offline gracefully.
// ────────────────────────────────────────────────────────

import Foundation
import CoreLocation
import Combine

// WMO weather codes → SF Symbol + label
private let wmoSymbol: [Int: (symbol: String, label: String)] = [
    0:  ("sun.max.fill",          "Clear"),
    1:  ("sun.max.fill",          "Mostly Clear"),
    2:  ("cloud.sun.fill",        "Partly Cloudy"),
    3:  ("cloud.fill",            "Overcast"),
    45: ("cloud.fog.fill",        "Foggy"),
    48: ("cloud.fog.fill",        "Icy Fog"),
    51: ("cloud.drizzle.fill",    "Light Drizzle"),
    53: ("cloud.drizzle.fill",    "Drizzle"),
    55: ("cloud.drizzle.fill",    "Heavy Drizzle"),
    61: ("cloud.rain.fill",       "Light Rain"),
    63: ("cloud.rain.fill",       "Rain"),
    65: ("cloud.heavyrain.fill",  "Heavy Rain"),
    71: ("cloud.snow.fill",       "Light Snow"),
    73: ("cloud.snow.fill",       "Snow"),
    75: ("cloud.snow.fill",       "Heavy Snow"),
    80: ("cloud.rain.fill",       "Rain Showers"),
    81: ("cloud.rain.fill",       "Rain Showers"),
    82: ("cloud.heavyrain.fill",  "Violent Rain"),
    95: ("cloud.bolt.fill",       "Thunderstorm"),
    96: ("cloud.bolt.rain.fill",  "Thunderstorm"),
    99: ("cloud.bolt.rain.fill",  "Thunderstorm"),
]

struct NSWeatherData {
    let tempC: Double
    let weatherCode: Int
    let cityName: String
    let symbol: String
    let label: String

    var tempF: Double { tempC * 9 / 5 + 32 }
    var tempString: String {
        let usesMetric = Locale.current.measurementSystem == .metric
        return usesMetric
            ? String(format: "%.0f°C", tempC)
            : String(format: "%.0f°F", tempF)
    }
}

@MainActor
final class NSWeatherEngine: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = NSWeatherEngine()

    @Published var weather: NSWeatherData?
    @Published var isLoading: Bool = false
    @Published var error: String?

    private let locationManager = CLLocationManager()
    private var lastFetch: Date = .distantPast
    private let cacheInterval: TimeInterval = 600  // 10 min

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func refresh(force: Bool = false) {
        let age = Date().timeIntervalSince(lastFetch)
        guard force || age > cacheInterval || weather == nil else { return }
        guard !isLoading else { return }

        isLoading = true
        error = nil

        switch locationManager.authorizationStatus {
        case .authorized, .authorizedAlways:
            locationManager.requestLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            fetchWithFallback()
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }
        Task { @MainActor [weak self] in
            await self?.fetchWeather(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude, location: loc)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.fetchWithFallback()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in
            switch manager.authorizationStatus {
            case .authorized, .authorizedAlways:
                manager.requestLocation()
            default:
                self?.fetchWithFallback()
            }
        }
    }

    // MARK: - Fallback: IP geolocation (also free, no key)

    private func fetchWithFallback() {
        Task {
            do {
                let url = URL(string: "https://ipapi.co/json/")!
                let (data, _) = try await URLSession.shared.data(from: url)
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let lat = json["latitude"] as? Double,
                   let lon = json["longitude"] as? Double {
                    await fetchWeather(lat: lat, lon: lon, location: nil, cityHint: json["city"] as? String)
                } else {
                    // Last resort: use a sensible default (London)
                    await fetchWeather(lat: 51.5, lon: -0.12, location: nil, cityHint: "London")
                }
            } catch {
                isLoading = false
                self.error = "Location unavailable"
            }
        }
    }

    // MARK: - Open-Meteo fetch (zero API key)

    private func fetchWeather(lat: Double, lon: Double, location: CLLocation?, cityHint: String? = nil) async {
        let urlStr = "https://api.open-meteo.com/v1/forecast" +
            "?latitude=\(lat)&longitude=\(lon)" +
            "&current=temperature_2m,weather_code" +
            "&wind_speed_unit=ms&timezone=auto"

        guard let url = URL(string: urlStr) else {
            isLoading = false; return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let current = json["current"] as? [String: Any],
                  let tempC = current["temperature_2m"] as? Double,
                  let code  = current["weather_code"]   as? Int else {
                isLoading = false
                error = "Weather parse failed"
                return
            }

            let info = wmoSymbol[code] ?? ("cloud.fill", "Unknown")
            var resolvedCity = cityHint
            if resolvedCity == nil { resolvedCity = await reverseGeocode(location) }
            let city = resolvedCity ?? "Your Location"

            weather = NSWeatherData(
                tempC: tempC,
                weatherCode: code,
                cityName: city,
                symbol: info.symbol,
                label: info.label
            )
            lastFetch = Date()
            isLoading = false
        } catch {
            isLoading = false
            self.error = "Network error"
        }
    }

    private func reverseGeocode(_ location: CLLocation?) async -> String? {
        guard let location else { return nil }
        return await withCheckedContinuation { cont in
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
                cont.resume(returning: placemarks?.first?.locality)
            }
        }
    }
}
