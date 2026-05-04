# Atlas - Tracks Your Travels

Atlas is a SwiftUI iOS app that lets you browse countries, filter by region, search by name or capital, and dive into rich detail views with flags, key facts, maps, and nearby attractions. The design is dark, minimal, and travel‑inspired with polished cards, subtle strokes, and the Nunito typeface.

## Screenshots

- Home list with search and region filter
- Country detail with hero header, info cards, and attractions
- Scrapbook journaling with photo gallery
![Home list](assets/screenshot1.png)
![Country detail](assets/screenshot2.png)
![Scrapbook](assets/screenshot3.png)

## Features

- Searchable list of countries with flags, capitals, population, and color‑coded region badges
- Filter by region via toolbar menu
- Detail view with gradient hero, grid of info cards, and nearby attractions (Geoapify Places API)
- Adaptable color palette and polished card styling with rounded rectangles and subtle strokes
- Uses async/await networking and a simple view model architecture
- Optional scrapbook to journal thoughts and add photos per country

## Setup

1. Clone the repository.
2. Open the Xcode project.
3. Add your Geoapify API key to the project if required (see NetworkManager configuration).
4. Build and run on iOS Simulator or a device.

Screenshots should be placed in an `assets/` folder at the root of the repo and referenced with relative paths as shown above.

## Tech notes

- Country data from RestCountries v3.1 API (limited to 10 fields)
- Nearby attractions from Geoapify Places API
- SwiftUI with async/await, `@StateObject` view models, and lazy stacks for performance

## License

This project is for educational purposes as part of a native app development course.

