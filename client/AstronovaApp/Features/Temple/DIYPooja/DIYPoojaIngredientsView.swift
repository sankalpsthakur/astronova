//
//  DIYPoojaIngredientsView.swift
//  AstronovaApp
//
//  Interactive ingredient checklist for DIY Poojas
//

import SwiftUI

struct DIYPoojaIngredientsView: View {
    let ingredients: [DIYPoojaIngredient]
    @State private var checkedItems: Set<String> = []

    private var groupedIngredients: [IngredientCategory: [DIYPoojaIngredient]] {
        Dictionary(grouping: ingredients, by: { $0.category })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
            // Header
            HStack {
                Text(L10n.Temple.DIYPooja.ingredients)
                    .font(.cosmicTitle3)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text("\(checkedItems.count)/\(ingredients.count)")
                    .font(.cosmicCaptionEmphasis)
                    .foregroundStyle(Color.cosmicGold)
            }
            .padding(.horizontal, Cosmic.Spacing.screen)

            // Grouped ingredients
            ForEach([IngredientCategory.essential, .flowers, .offering, .special], id: \.self) { category in
                if let items = groupedIngredients[category], !items.isEmpty {
                    VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                        HStack(spacing: Cosmic.Spacing.xs) {
                            Image(systemName: category.icon)
                                .font(.system(size: 12))
                                .foregroundStyle(Color.cosmicGold)
                            Text(category.displayName)
                                .font(.cosmicCaptionEmphasis)
                                .foregroundStyle(Color.cosmicTextSecondary)
                        }

                        ForEach(items) { ingredient in
                            DIYIngredientRow(
                                ingredient: ingredient,
                                isChecked: checkedItems.contains(ingredient.id),
                                onToggle: {
                                    CosmicHaptics.light()
                                    if checkedItems.contains(ingredient.id) {
                                        checkedItems.remove(ingredient.id)
                                    } else {
                                        checkedItems.insert(ingredient.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, Cosmic.Spacing.screen)
                }
            }
        }
    }
}

struct DIYIngredientRow: View {
    let ingredient: DIYPoojaIngredient
    let isChecked: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Cosmic.Spacing.md) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.cosmicBody)
                    .foregroundStyle(isChecked ? Color.cosmicSuccess : Color.cosmicTextTertiary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(ingredient.name)
                        .font(.cosmicBody)
                        .foregroundStyle(isChecked ? Color.cosmicTextSecondary : Color.cosmicTextPrimary)
                        .strikethrough(isChecked, color: Color.cosmicTextTertiary)

                    if ingredient.isOptional {
                        Text("Optional")
                            .font(.cosmicMicro)
                            .foregroundStyle(Color.cosmicTextTertiary)
                    }
                }

                Spacer()

                Text(ingredient.quantity)
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
            }
            .padding(.vertical, Cosmic.Spacing.xs)
            .frame(minHeight: Cosmic.TouchTarget.minimum)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(ingredient.name), \(ingredient.quantity)")
        .accessibilityValue(isChecked ? L10n.Temple.Accessibility.checked : L10n.Temple.Accessibility.unchecked)
        .accessibilityHint(L10n.Temple.Accessibility.toggleHint)
    }
}
