import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError(Error)
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid server response"
        case .decodingError(let e): return "Decoding error: \(e.localizedDescription)"
        case .serverError(let code): return "Server error: \(code)"
        }
    }
}

class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    private let geoapifyKey = "6e3ef502c6e943a5aa8a8acd86b41529"

    // MARK: - RestCountries
    func fetchAllCountries() async throws -> [Country] {
        // Start with a minimal, known-good set of fields to avoid 400 responses from the API.
        // We can expand this later if needed.
        let urlStr = "https://restcountries.com/v3.1/all?fields=name,capital,region,subregion,flags,cca2,latlng,population,currencies,languages"
        guard let url = URL(string: urlStr) else { throw NetworkError.invalidURL }

        print("🌐 Countries URL: \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }

        print("📡 Countries status: \(http.statusCode)")
        if !(200...299).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            print("📦 Countries error body: \(body)")
            throw NetworkError.serverError(http.statusCode)
        }

        do {
            let countries = try JSONDecoder().decode([Country].self, from: data)
            print("✅ Decoded countries: \(countries.count)")
            return countries.sorted { $0.name.common < $1.name.common }
        } catch {
            print("❌ Countries decode error: \(error)")
            throw NetworkError.decodingError(error)
        }
    }

    // MARK: - Geoapify
    func fetchAttractions(lat: Double, lon: Double, radius: Int = 50000, limit: Int = 10) async throws -> [Place] {
        var components = URLComponents(string: "https://api.geoapify.com/v2/places")!
        components.queryItems = [
            URLQueryItem(name: "categories", value: "tourism.attraction,tourism.sights"),
            URLQueryItem(name: "filter",     value: "circle:\(lon),\(lat),\(radius)"),
            URLQueryItem(name: "limit",      value: "\(limit)"),
            URLQueryItem(name: "apiKey",     value: geoapifyKey)
        ]

        guard let url = components.url else { throw NetworkError.invalidURL }

        print("🌐 REQUEST URL: \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }

        print("📡 STATUS CODE: \(http.statusCode)")
        print("📦 RAW RESPONSE: \(String(data: data, encoding: .utf8) ?? "unreadable")")

        guard http.statusCode == 200 else { throw NetworkError.serverError(http.statusCode) }

        do {
            let result = try JSONDecoder().decode(GeoapifyPlaceResponse.self, from: data)
            return result.features.compactMap { feature in
                guard let name = feature.properties.name, !name.isEmpty else { return nil }
                return Place(
                    id: feature.properties.place_id ?? UUID().uuidString,
                    name: name,
                    distance: feature.properties.distance,
                    category: feature.properties.categories?.first
                )
            }
        } catch {
            print("❌ DECODE ERROR: \(error)")
            throw NetworkError.decodingError(error)
        }
    }

    // MARK: - Geoapify (Rectangle filter)
    func fetchPlacesInRect(minLon: Double, minLat: Double, maxLon: Double, maxLat: Double,
                           categories: String = "commercial.supermarket",
                           limit: Int = 20) async throws -> [Place] {
        var components = URLComponents(string: "https://api.geoapify.com/v2/places")!
        components.queryItems = [
            URLQueryItem(name: "categories", value: categories),
            URLQueryItem(name: "filter",     value: "rect:\(minLon),\(minLat),\(maxLon),\(maxLat)"),
            URLQueryItem(name: "limit",      value: "\(limit)"),
            URLQueryItem(name: "apiKey",     value: geoapifyKey)
        ]

        guard let url = components.url else { throw NetworkError.invalidURL }

        print("🌐 REQUEST URL: \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }

        print("📡 STATUS CODE: \(http.statusCode)")
        print("📦 RAW RESPONSE: \(String(data: data, encoding: .utf8) ?? "unreadable")")

        guard http.statusCode == 200 else { throw NetworkError.serverError(http.statusCode) }

        do {
            let result = try JSONDecoder().decode(GeoapifyPlaceResponse.self, from: data)
            return result.features.compactMap { feature in
                guard let name = feature.properties.name, !name.isEmpty else { return nil }
                return Place(
                    id: feature.properties.place_id ?? UUID().uuidString,
                    name: name,
                    distance: feature.properties.distance,
                    category: feature.properties.categories?.first
                )
            }
        } catch {
            print("❌ DECODE ERROR: \(error)")
            throw NetworkError.decodingError(error)
        }
    }
}
