//
//  VedicLibraryView.swift
//  AstronovaApp
//
//  Browsable Vedic/Puranic reference library
//

import SwiftUI

struct VedicLibraryView: View {
    @EnvironmentObject private var gamification: GamificationManager
    @State private var categories: [VedicCategory] = VedicCategory.samples
    @State private var entries: [VedicEntry] = []
    @State private var selectedCategory: String?
    @State private var searchText = ""
    @State private var isLoading = false

    private var filteredEntries: [VedicEntry] {
        var result = entries
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query) ||
                $0.translation.lowercased().contains(query) ||
                $0.tags.contains(where: { $0.lowercased().contains(query) })
            }
        }
        return result
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Cosmic.Spacing.xl) {
                if selectedCategory == nil && searchText.isEmpty {
                    // Category grid
                    categoryGrid
                } else {
                    // Entries list
                    entriesList
                }
            }
            .padding(.top, Cosmic.Spacing.md)
        }
        .background(Color.cosmicVoid)
        .searchable(text: $searchText, prompt: L10n.Temple.Library.searchPlaceholder)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(selectedCategory ?? L10n.Temple.Library.sectionTitle)
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicTextPrimary)
            }

            if selectedCategory != nil {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation {
                            selectedCategory = nil
                        }
                    } label: {
                        HStack(spacing: Cosmic.Spacing.xxs) {
                            Image(systemName: "chevron.left")
                            Text("All")
                        }
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicGold)
                    }
                }
            }
        }
        .task {
            await loadLibrary()
        }
    }

    private var categoryGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: Cosmic.Spacing.md),
            GridItem(.flexible(), spacing: Cosmic.Spacing.md)
        ], spacing: Cosmic.Spacing.md) {
            ForEach(categories) { category in
                Button {
                    withAnimation {
                        selectedCategory = category.name
                    }
                } label: {
                    VStack(spacing: Cosmic.Spacing.s) {
                        Image(systemName: category.iconName)
                            .font(.system(size: 28))
                            .foregroundStyle(Color.cosmicGold)

                        Text(category.name)
                            .font(.cosmicCalloutEmphasis)
                            .foregroundStyle(Color.cosmicTextPrimary)

                        Text("\(category.entryCount) entries")
                            .font(.cosmicMicro)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Cosmic.Spacing.lg)
                    .background {
                        RoundedRectangle(cornerRadius: Cosmic.Radius.prominent)
                            .fill(Color.cosmicSurface)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Cosmic.Spacing.screen)
    }

    private var entriesList: some View {
        LazyVStack(spacing: Cosmic.Spacing.md) {
            if filteredEntries.isEmpty {
                VStack(spacing: Cosmic.Spacing.md) {
                    Image(systemName: "text.book.closed")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.cosmicTextTertiary)
                    Text(L10n.Temple.Library.noResults)
                        .font(.cosmicBody)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
                .padding(.top, Cosmic.Spacing.xl)
            } else {
                ForEach(filteredEntries) { entry in
                    NavigationLink(value: entry) {
                        VedicEntryCardView(entry: entry)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, Cosmic.Spacing.screen)
    }

    @MainActor
    private func loadLibrary() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await APIServices.shared.fetchVedicLibrary()
            categories = response.categories
            entries = response.entries
        } catch {
            // Keep sample data
        }
    }
}

// MARK: - Vedic Entry Card (List Item)

struct VedicEntryCardView: View {
    let entry: VedicEntry

    var body: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
            HStack {
                Text(entry.title)
                    .font(.cosmicCalloutEmphasis)
                    .foregroundStyle(Color.cosmicTextPrimary)
                Spacer()
                Text(entry.category)
                    .font(.cosmicMicro)
                    .foregroundStyle(Color.cosmicGold)
                    .padding(.horizontal, Cosmic.Spacing.xs)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.cosmicGold.opacity(0.15)))
            }

            if let sanskrit = entry.sanskritText, !sanskrit.isEmpty {
                Text(sanskrit)
                    .font(.system(size: 14, design: .serif))
                    .foregroundStyle(Color.cosmicGold.opacity(0.8))
                    .lineLimit(1)
            }

            Text(entry.translation)
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)
                .lineLimit(2)

            if let source = entry.source, !source.isEmpty {
                Text(source)
                    .font(.cosmicMicro)
                    .foregroundStyle(Color.cosmicTextTertiary)
            }
        }
        .padding(Cosmic.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Cosmic.Radius.prominent)
                .fill(Color.cosmicSurface)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.title). \(entry.translation)")
    }
}
