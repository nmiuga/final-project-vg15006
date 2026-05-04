import Foundation

// MARK: - RestCountries Models
struct Country: Codable, Identifiable {
    let id = UUID()
    let name: CountryName
    let capital: [String]?
    let population: Int
    let region: String
    let subregion: String?
    let languages: [String: String]?
    let currencies: [String: Currency]?
    let timezones: [String]?
    let area: Double?
    let flags: Flags
    let latlng: [Double]?
    let cca2: String

    enum CodingKeys: String, CodingKey {
        case name, capital, population, region, subregion
        case languages, currencies, timezones, area, flags, latlng, cca2
    }

    var capitalCity: String { capital?.first ?? "N/A" }
    var primaryLanguage: String { languages?.values.first ?? "N/A" }
    var primaryCurrency: String {
        guard let c = currencies?.values.first else { return "N/A" }
        return "\(c.symbol ?? "") \(c.name)"
    }
    var primaryTimezone: String { timezones?.first ?? "N/A" }
    var formattedArea: String {
        guard let a = area else { return "N/A" }
        return "\(Int(a).formatted()) km²"
    }
    var formattedPopulation: String { population.formatted() }

    var latitude: Double? { latlng?.first }
    var longitude: Double? { latlng?.dropFirst().first }
}

struct CountryName: Codable {
    let common: String
    let official: String
}

struct Currency: Codable {
    let name: String
    let symbol: String?
}

struct Flags: Codable {
    let png: String
    let svg: String?
}

// MARK: - Geoapify Models
struct GeoapifyPlaceResponse: Codable {
    let features: [GeoapifyPlaceFeature]

    enum CodingKeys: String, CodingKey {
        case features
    }
}

struct GeoapifyPlaceFeature: Codable {
    let properties: GeoapifyPlaceProperties

    enum CodingKeys: String, CodingKey {
        case properties
    }
}

struct GeoapifyPlaceProperties: Codable {
    let place_id: String?
    let name: String?
    let distance: Double?
    let categories: [String]?

    enum CodingKeys: String, CodingKey {
        case place_id, name, distance, categories
    }
}

// MARK: - Place Model (used throughout the app)
struct Place: Identifiable {
    let id: String
    let name: String
    let distance: Double?
    let category: String?

    var primaryKind: String {
        category?
            .split(separator: ".")
            .last
            .map { String($0).replacingOccurrences(of: "_", with: " ").capitalized }
            ?? "Attraction"
    }

    var emoji: String {
        let k = category ?? ""
        if k.contains("religion") || k.contains("temple") { return "⛩️" }
        if k.contains("castle") || k.contains("historic")  { return "🏯" }
        if k.contains("museum")                            { return "🏛️" }
        if k.contains("natural") || k.contains("park")    { return "🌿" }
        if k.contains("tower") || k.contains("landmark")  { return "🗼" }
        if k.contains("beach") || k.contains("coast")     { return "🏖️" }
        if k.contains("mountain")                         { return "⛰️" }
        return "📍"
    }
}
