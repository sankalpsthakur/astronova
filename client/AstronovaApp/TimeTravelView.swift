import SwiftUI

struct DashasResponse: Codable {
    struct Period: Codable { let lord: String; let start: String?; let end: String?; let annotation: String }
    let mahadasha: Period
    let antardasha: Period
}

struct TimeTravelView: View {
    @EnvironmentObject private var auth: AuthState
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var planets: [DetailedPlanetaryPosition] = []
    @State private var dashas: DashasResponse?
    @State private var isLoading = false
    @State private var aspects: [Aspect] = []
    
    private let api = APIServices.shared
    private let yearRange = (1900...2100)
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Year slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Year: ")
                            .font(.headline)
                        Spacer()
                        Text("\(selectedYear)")
                            .font(.title2.weight(.semibold))
                    }
                    Slider(value: Binding(
                        get: { Double(selectedYear) },
                        set: { selectedYear = Int($0); Task { await loadData() } }
                    ), in: Double(yearRange.lowerBound)...Double(yearRange.upperBound), step: 1)
                }
                .padding(.horizontal)
                
                if isLoading {
                    ProgressView("Computing planetary positions…")
                        .padding()
                }
                
                // Planet list
                List(planets) { p in
                    HStack(spacing: 12) {
                        Text(p.symbol)
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text(p.name)
                                .font(.headline)
                            Text("\(p.sign) \(String(format: "%.2f°", p.degree))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if p.retrograde {
                            Text("℞")
                                .font(.headline)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                
                // Dashas panel
                if let d = dashas {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Vimshottari Dashas")
                            .font(.headline)
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Mahadasha: \(d.mahadasha.lord)")
                                    .font(.subheadline.weight(.semibold))
                                Text(d.mahadasha.annotation)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                Text("Antardasha: \(d.antardasha.lord)")
                                    .font(.subheadline.weight(.semibold))
                                Text(d.antardasha.annotation)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                // Aspects panel
                if !aspects.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Aspects")
                            .font(.headline)
                        ForEach(Array(aspects.prefix(8).enumerated()), id: \.offset) { _, a in
                            HStack {
                                Text("\(a.planet1.capitalized) – \(a.planet2.capitalized)")
                                Spacer()
                                Text("\(a.type.capitalized) (orb \(String(format: "%.1f", a.orb)))")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.footnote)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Time Travel")
            .task { await loadData() }
        }
    }
    
    private func loadData() async {
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { isLoading = false } } }
        do {
            // Build date for Jan 1 of selected year
            var comps = DateComponents()
            comps.year = selectedYear
            comps.month = 1
            comps.day = 1
            let date = Calendar.current.date(from: comps) ?? Date()
            
            // Fetch planetary positions
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateStr = dateFormatter.string(from: date)
            
            struct PlanetaryDataResponse: Codable { let planets: [DetailedPlanetaryPosition] }
            let response: PlanetaryDataResponse = try await api.directGET(
                endpoint: "/api/v1/ephemeris/at?date=\(dateStr)",
                responseType: PlanetaryDataResponse.self
            )
            await MainActor.run { planets = response.planets }
            
            // Fetch dashas based on profile if available
            if let bd = try? BirthData(from: auth.profileManager.profile) {
                var dashaURL = "/api/v1/astrology/dashas?birth_date=\(bd.date)&target_date=\(dateStr)"
                dashaURL += "&birth_time=\(bd.time)"
                dashaURL += "&timezone=\(bd.timezone)"
                dashaURL += "&lat=\(bd.latitude)&lon=\(bd.longitude)"
                let d: DashasResponse = try await api.directGET(
                    endpoint: dashaURL,
                    responseType: DashasResponse.self
                )
                await MainActor.run { dashas = d }
            } else {
                await MainActor.run { dashas = nil }
            }

            // Fetch aspects for date
            let asp: [Aspect] = try await api.directGET(
                endpoint: "/api/v1/chart/aspects?date=\(dateStr)",
                responseType: [Aspect].self
            )
            await MainActor.run { aspects = asp }
        } catch {
            print("Time Travel load failed: \(error)")
        }
    }
}

// Uses Aspect defined in APIModels.swift
