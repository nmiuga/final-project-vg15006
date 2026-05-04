import Foundation
import Combine

// MARK: - Country List ViewModel
@MainActor
class CountryListViewModel: ObservableObject {
    @Published var countries: [Country] = []
    @Published var searchText: String = ""
    @Published var selectedRegion: String = "All"
    @Published var isLoading = false
    @Published var errorMessage: String?

    var regions: [String] {
        let r = Set(countries.map { $0.region }).sorted()
        return ["All"] + r
    }

    // Computed so it always reflects latest searchText/selectedRegion
    var filteredCountries: [Country] {
        let base: [Country]
        if selectedRegion == "All" {
            base = countries
        } else {
            base = countries.filter { $0.region == selectedRegion }
        }

        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return base }

        let query = q.lowercased()
        return base.filter { country in
            country.name.common.lowercased().contains(query) ||
            country.capitalCity.lowercased().contains(query)
        }
    }

    func loadCountries() async {
        isLoading = true
        errorMessage = nil
        do {
            print("➡️ loadCountries() called")
            let result = try await NetworkManager.shared.fetchAllCountries()
            self.countries = result
            self.isLoading = false
            print("✅ Loaded countries: \(result.count)")
        } catch {
            print("❌ loadCountries error: \(error)")
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
}

// MARK: - Detail ViewModel
@MainActor
class DetailViewModel: ObservableObject {
    @Published var attractions: [Place] = []
    @Published var isLoadingAttractions = false

    private let country: Country

    init(country: Country) {
        self.country = country
    }

    func loadAttractions() async {
        print("⚡️ loadAttractions called")
        guard let lat = country.latitude, let lon = country.longitude else {
            print("❌ No lat/lon for \(country.name.common)")
            return
        }
        print("✅ Coords found: \(lat), \(lon)")
        isLoadingAttractions = true
        do {
            attractions = try await NetworkManager.shared.fetchAttractions(lat: lat, lon: lon)
        } catch {
            print("Attractions error: \(error.localizedDescription)")
        }
        isLoadingAttractions = false
    }
}
