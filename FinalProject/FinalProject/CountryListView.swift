import SwiftUI

struct CountryListView: View {
    @StateObject private var viewModel = CountryListViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color("AppBackground"), Color("LightGreen")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView("Loading countries...")
                        .tint(Color("AccentColor"))
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error) {
                        Task { await viewModel.loadCountries() }
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(viewModel.filteredCountries) { country in
                                NavigationLink(destination: CountryDetailView(country: country)) {
                                    CountryRowCard(country: country)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Atlas")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $viewModel.searchText, prompt: "Search countries...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(viewModel.regions, id: \.self) { region in
                            Button {
                                viewModel.selectedRegion = region
                            } label: {
                                HStack {
                                    Text(region)
                                    if viewModel.selectedRegion == region {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(Color("AccentColor"))
                    }
                }
            }
        }
        .task { await viewModel.loadCountries() }
    }
}

// MARK: - Country Row Card
struct CountryRowCard: View {
    let country: Country

    var body: some View {
        HStack(spacing: 12) {
            // Flag image from RestCountries PNG URL
            AsyncImage(url: URL(string: country.flags.png)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                         .aspectRatio(contentMode: .fill)
                         .frame(width: 52, height: 36)
                         .clipShape(RoundedRectangle(cornerRadius: 6))
                         .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                default:
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color("CardSurface"))
                        .frame(width: 52, height: 36)
                        .overlay(
                            Text("🏳️").font(.system(size: 20))
                        )
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(country.name.common)
                    .font(.custom("Nunito-SemiBold", size: 15))
                    .foregroundColor(.primary)

                Text("\(country.capitalCity) · \(country.formattedPopulation)")
                    .font(.custom("Nunito-Regular", size: 12))
                    .foregroundColor(.secondary)

                RegionBadge(region: country.region)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color("CardSurface"))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Region Badge
struct RegionBadge: View {
    let region: String

    var badgeColor: Color {
        switch region {
        case "Europe": return Color.blue
        case "Asia": return Color.orange
        case "Americas": return Color.green
        case "Africa": return Color.yellow
        case "Oceania": return Color.teal
        default: return Color.gray
        }
    }

    var body: some View {
        Text(region)
            .font(.custom("Nunito-Regular", size: 11))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(0.18))
            .foregroundColor(badgeColor)
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text("Something went wrong")
                .font(.custom("Nunito-Bold", size: 18))
            Text(message)
                .font(.custom("Nunito-Regular", size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry", action: retry)
                .buttonStyle(.bordered)
                .tint(Color("AccentColor"))
        }
        .padding(32)
    }
}
#Preview {
    CountryListView()
}
