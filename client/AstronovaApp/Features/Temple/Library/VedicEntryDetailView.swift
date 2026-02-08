//
//  VedicEntryDetailView.swift
//  AstronovaApp
//
//  Full Vedic entry detail: Sanskrit, transliteration, translation
//

import SwiftUI

struct VedicEntryDetailView: View {
    let entry: VedicEntry
    @EnvironmentObject private var gamification: GamificationManager

    var body: some View {
        ScrollView {
            VStack(spacing: Cosmic.Spacing.xl) {
                // Category badge
                Text(entry.category)
                    .font(.cosmicCaptionEmphasis)
                    .foregroundStyle(Color.cosmicGold)
                    .padding(.horizontal, Cosmic.Spacing.md)
                    .padding(.vertical, Cosmic.Spacing.xxs)
                    .background {
                        Capsule()
                            .fill(Color.cosmicGold.opacity(0.15))
                    }
                    .padding(.top, Cosmic.Spacing.lg)

                // Title
                Text(entry.title)
                    .font(.cosmicTitle2)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Cosmic.Spacing.screen)

                // Sanskrit text
                if let sanskrit = entry.sanskritText, !sanskrit.isEmpty {
                    Text(sanskrit)
                        .font(.system(size: 22, weight: .medium, design: .serif))
                        .foregroundStyle(Color.cosmicGold)
                        .multilineTextAlignment(.center)
                        .padding(Cosmic.Spacing.lg)
                        .frame(maxWidth: .infinity)
                        .background {
                            RoundedRectangle(cornerRadius: Cosmic.Radius.prominent)
                                .fill(Color.cosmicGold.opacity(0.08))
                                .overlay {
                                    RoundedRectangle(cornerRadius: Cosmic.Radius.prominent)
                                        .stroke(Color.cosmicGold.opacity(0.2), lineWidth: 1)
                                }
                        }
                        .padding(.horizontal, Cosmic.Spacing.screen)
                }

                // Transliteration
                if let transliteration = entry.transliteration, !transliteration.isEmpty {
                    VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
                        Text("Transliteration")
                            .font(.cosmicCaptionEmphasis)
                            .foregroundStyle(Color.cosmicTextTertiary)
                        Text(transliteration)
                            .font(.cosmicBody.italic())
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Cosmic.Spacing.screen)
                }

                // Translation
                VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
                    Text("Translation")
                        .font(.cosmicCaptionEmphasis)
                        .foregroundStyle(Color.cosmicTextTertiary)
                    Text(entry.translation)
                        .font(.cosmicBody)
                        .foregroundStyle(Color.cosmicTextPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Cosmic.Spacing.screen)

                // Source
                if let source = entry.source, !source.isEmpty {
                    HStack(spacing: Cosmic.Spacing.xs) {
                        Image(systemName: "book.closed.fill")
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicGold)
                        Text(L10n.Temple.Library.source)
                            .font(.cosmicCaptionEmphasis)
                            .foregroundStyle(Color.cosmicTextTertiary)
                        Text(source)
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                    .padding(.horizontal, Cosmic.Spacing.screen)
                }

                // Tags
                if !entry.tags.isEmpty {
                    FlowLayout(spacing: Cosmic.Spacing.xs) {
                        ForEach(entry.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.cosmicMicro)
                                .foregroundStyle(Color.cosmicTextSecondary)
                                .padding(.horizontal, Cosmic.Spacing.s)
                                .padding(.vertical, Cosmic.Spacing.xxs)
                                .background {
                                    Capsule()
                                        .stroke(Color.cosmicTextTertiary.opacity(0.3), lineWidth: 1)
                                }
                        }
                    }
                    .padding(.horizontal, Cosmic.Spacing.screen)
                }

                Spacer().frame(height: 60)
            }
        }
        .background(Color.cosmicVoid)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(entry.title)
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .lineLimit(1)
            }
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.cosmicBody)
                        .foregroundStyle(Color.cosmicGold)
                }
            }
        }
        .onAppear {
            Analytics.shared.track(.vedicEntryRead, properties: [
                "entry_id": entry.id,
                "category": entry.category
            ])
            gamification.markVedicEntryRead(entryId: entry.id)
        }
    }

    private var shareText: String {
        var text = entry.title + "\n\n"
        if let sanskrit = entry.sanskritText { text += sanskrit + "\n\n" }
        if let transliteration = entry.transliteration { text += transliteration + "\n\n" }
        text += entry.translation
        if let source = entry.source { text += "\n\n- " + source }
        text += "\n\nAstronova"
        return text
    }
}
