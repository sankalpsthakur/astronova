//
//  VedicSearchView.swift
//  AstronovaApp
//
//  Search interface for Vedic library (integrated into VedicLibraryView)
//  This file provides a standalone search view if needed separately
//

import SwiftUI

struct VedicSearchResultsView: View {
    let entries: [VedicEntry]
    let query: String

    var body: some View {
        if entries.isEmpty {
            VStack(spacing: Cosmic.Spacing.md) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.cosmicTextTertiary)

                Text(L10n.Temple.Library.noResults)
                    .font(.cosmicBody)
                    .foregroundStyle(Color.cosmicTextSecondary)

                if !query.isEmpty {
                    Text("No entries found for \"\(query)\"")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextTertiary)
                }
            }
            .padding(.top, Cosmic.Spacing.xl)
        } else {
            LazyVStack(spacing: Cosmic.Spacing.md) {
                ForEach(entries) { entry in
                    NavigationLink(value: entry) {
                        VedicEntryCardView(entry: entry)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
