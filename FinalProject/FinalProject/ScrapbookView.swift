import SwiftUI
import PhotosUI
import Combine

struct ScrapbookEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let text: String
    let images: [Data]
}

class ScrapbookStore: ObservableObject {
    @Published private(set) var entries: [ScrapbookEntry] = []
    private let countryCode: String
    private let userDefaultsKey: String

    init(countryCode: String) {
        self.countryCode = countryCode
        self.userDefaultsKey = "scrapbook.entries.\(countryCode)"
        load()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            entries = []
            return
        }
        do {
            let decoded = try JSONDecoder().decode([ScrapbookEntry].self, from: data)
            entries = decoded.sorted { $0.date > $1.date }
        } catch {
            entries = []
        }
    }

    private func save() {
        do {
            let encoded = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        } catch {
            // Handle error silently
        }
    }

    func addEntry(text: String, images: [Data]) {
        let newEntry = ScrapbookEntry(id: UUID(), date: Date(), text: text, images: images)
        entries.insert(newEntry, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }
}

struct ScrapbookView: View {
    let countryCode: String
    let countryName: String

    @StateObject private var store: ScrapbookStore
    @State private var draftText: String = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var pickedImagesData: [Data] = []

    private let gridColumns = [GridItem(.flexible()), GridItem(.flexible())]

    init(countryCode: String, countryName: String) {
        self.countryCode = countryCode
        self.countryName = countryName
        _store = StateObject(wrappedValue: ScrapbookStore(countryCode: countryCode))
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Scrapbook for \(countryName)")
                .font(.custom("Nunito-Bold", size: 24))
                .foregroundColor(Color("AccentColor"))

            TextEditor(text: $draftText)
                .font(.custom("Nunito-Regular", size: 16))
                .padding(8)
                .background(Color("CardSurface"))
                .cornerRadius(10)
                .frame(minHeight: 100)

            PhotosPicker(selection: $selectedItems, maxSelectionCount: 5, matching: .images) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Add Photos")
                }
                .font(.custom("Nunito-SemiBold", size: 16))
                .foregroundColor(Color("AccentColor"))
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(Color("CardSurface"))
                .cornerRadius(10)
            }
            .onChange(of: selectedItems) { newItems in
                Task {
                    var loadedImagesData: [Data] = []
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            loadedImagesData.append(data)
                        }
                    }
                    pickedImagesData = loadedImagesData
                }
            }

            Button {
                let trimmedText = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedText.isEmpty || !pickedImagesData.isEmpty else { return }
                store.addEntry(text: trimmedText, images: pickedImagesData)
                draftText = ""
                pickedImagesData = []
                selectedItems = []
            } label: {
                Text("Save Entry")
                    .font(.custom("Nunito-SemiBold", size: 18))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("AccentColor"))
                    .cornerRadius(12)
            }
            .disabled(draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && pickedImagesData.isEmpty)

            Divider()

            if store.entries.isEmpty {
                Spacer()
                Text("No scrapbook entries yet.")
                    .font(.custom("Nunito-Regular", size: 16))
                    .foregroundColor(Color.gray)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(store.entries) { entry in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(entry.date, style: .date)
                                    .font(.custom("Nunito-SemiBold", size: 14))
                                    .foregroundColor(Color("AccentColor"))
                                if !entry.text.isEmpty {
                                    Text(entry.text)
                                        .font(.custom("Nunito-Regular", size: 16))
                                }
                                if !entry.images.isEmpty {
                                    LazyVGrid(columns: gridColumns, spacing: 8) {
                                        ForEach(entry.images.indices, id: \.self) { idx in
                                            if let uiImage = UIImage(data: entry.images[idx]) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(minHeight: 100)
                                                    .clipped()
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color("CardSurface"))
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                            .padding(.horizontal)
                        }
                        .onDelete(perform: store.delete)
                    }
                    .padding(.vertical)
                }
            }
        }
        .padding()
    }
}

struct ScrapbookView_Previews: PreviewProvider {
    static var previews: some View {
        ScrapbookView(countryCode: "US", countryName: "United States")
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
        ScrapbookView(countryCode: "US", countryName: "United States")
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
    }
}
