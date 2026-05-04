import SwiftUI

struct CountryDetailView: View {
    let country: Country
    @StateObject private var viewModel: DetailViewModel

    init(country: Country) {
        self.country = country
        _viewModel = StateObject(wrappedValue: DetailViewModel(country: country))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("AppBackground"), Color("LightGreen")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Hero Header
                    HeroHeaderView(country: country)

                    // Stats Row
                    StatsRowView(country: country)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                    // Country Info Section
                    SectionView(title: "COUNTRY INFO") {
                        InfoCardView(items: [
                            ("Language", country.primaryLanguage),
                            ("Currency", country.primaryCurrency),
                            ("Subregion", country.subregion ?? "N/A")
                        ])
                        .overlay(EmptyView()) // keep structure unchanged

                        VStack(spacing: 0) {
                            HStack {
                                Text("Traveled")
                                    .font(.custom("Nunito-Regular", size: 14))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Toggle("", isOn: Binding(get: {
                                    UserDefaults.standard.bool(forKey: "traveled.\(country.cca2)")
                                }, set: { newValue in
                                    UserDefaults.standard.set(newValue, forKey: "traveled.\(country.cca2)")
                                }))
                                .labelsHidden()
                                .tint(Color("AccentColor"))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)

                            if UserDefaults.standard.bool(forKey: "traveled.\(country.cca2)") {
                                Divider().padding(.horizontal, 14)
                                NavigationLink {
                                    ScrapbookView(countryCode: country.cca2, countryName: country.name.common)
                                } label: {
                                    HStack {
                                        Text("Open Scrapbook")
                                            .font(.custom("Nunito-SemiBold", size: 14))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "book.closed")
                                            .foregroundColor(Color("AccentColor"))
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                }
                            }
                        }
                        .background(Color("CardSurface"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 0.5))
                    }

                    // Attractions Section
                    SectionView(title: "TOP ATTRACTIONS") {
                        if viewModel.isLoadingAttractions {
                            HStack {
                                ProgressView().tint(Color("AccentColor"))
                                Text("Finding attractions...")
                                    .font(.custom("Nunito-Regular", size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else if viewModel.attractions.isEmpty {
                            Text("No attractions found.")
                                .font(.custom("Nunito-Regular", size: 14))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            VStack(spacing: 8) {
                                ForEach(viewModel.attractions.prefix(8)) { place in
                                    AttractionRowView(place: place)
                                }
                            }
                        }
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle(country.name.common)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            print("🚀 DETAIL VIEW LOADED FOR: \(country.name.common)")
            print("📍 LAT: \(String(describing: country.latitude)) LON: \(String(describing: country.longitude))")
            await viewModel.loadAttractions() }
    }
}

// MARK: - Hero Header
struct HeroHeaderView: View {
    let country: Country

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("HeroTop"), Color("HeroBottom")],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 10) {
                AsyncImage(url: URL(string: country.flags.png)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                             .aspectRatio(contentMode: .fit)
                             .frame(height: 80)
                             .clipShape(RoundedRectangle(cornerRadius: 10))
                             .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 1))
                             .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    default:
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 128, height: 80)
                    }
                }

                Text(country.name.common)
                    .font(.custom("Nunito-Bold", size: 24))
                    .foregroundColor(.white)

                Text("Capital: \(country.capitalCity)")
                    .font(.custom("Nunito-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.vertical, 24)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Stats Row
struct StatsRowView: View {
    let country: Country

    var body: some View {
        HStack(spacing: 10) {
            StatPillView(value: country.formattedPopulation, label: "Population")
            StatPillView(value: country.primaryCurrency.components(separatedBy: " ").first ?? "—", label: "Currency")
            StatPillView(value: country.region, label: "Region")
        }
    }
}

struct StatPillView: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.custom("Nunito-SemiBold", size: 13))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.custom("Nunito-Regular", size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color("CardSurface"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.06), lineWidth: 0.5))
    }
}

// MARK: - Section Wrapper
struct SectionView<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom("Nunito-Regular", size: 11))
                .tracking(0.8)
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            content()
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
    }
}

// MARK: - Info Card
struct InfoCardView: View {
    let items: [(String, String)]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack {
                    Text(item.0)
                        .font(.custom("Nunito-Regular", size: 14))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(item.1)
                        .font(.custom("Nunito-SemiBold", size: 14))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

                if index < items.count - 1 {
                    Divider().padding(.horizontal, 14)
                }
            }
        }
        .background(Color("CardSurface"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 0.5))
    }
}

// MARK: - Attraction Row
struct AttractionRowView: View {
    let place: Place

    var body: some View {
        HStack(spacing: 12) {
            Text(place.emoji)
                .font(.system(size: 20))
                .frame(width: 40, height: 40)
                .background(Color("AccentColor").opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(place.name)
                    .font(.custom("Nunito-SemiBold", size: 14))
                    .foregroundColor(.primary)
                Text(place.primaryKind)
                    .font(.custom("Nunito-Regular", size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let dist = place.distance {
                Text("\(Int(dist / 1000)) km")
                    .font(.custom("Nunito-Regular", size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color("CardSurface"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 0.5))
    }
}

