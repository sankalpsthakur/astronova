# Time Travel Page Aesthetic Rethink -- Implementation Plan

## Executive Summary

The Time Travel page has a stunning dark astrological chart that drops into flat beige cards. The luminance jump is ~0.03 to ~0.87 (near-black to near-white) with no visual bridge. The NOW card whispers its insight when it should speak with confidence. The NEXT card's data density accidentally outweighs the NOW card, inverting the visual hierarchy.

**Goal**: Make the page feel like one immersive cosmic reading experience, not "chart on top, cards on bottom."

---

## Phase 1: Dark-to-Light Bridge (HIGH impact, MEDIUM effort)

### 1A. Nebula Fade Overlay on CosmicMapView
**File**: `UnifiedTimeTravelView.swift`
**What**: Add a 60pt gradient overlay at the bottom of CosmicMapView that fades from transparent to `Color.cosmicBackground`.

```swift
CosmicMapView(...)
    .frame(height: 350)
    .padding(.horizontal)
    .overlay(alignment: .bottom) {
        LinearGradient(
            colors: [
                Color.cosmicBackground.opacity(0),
                Color.cosmicBackground.opacity(0.4),
                Color.cosmicBackground.opacity(0.85),
                Color.cosmicBackground
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 60)
        .allowsHitTesting(false)
    }
```

### 1B. Elevation Shadow on CosmicMapView
**File**: `UnifiedTimeTravelView.swift`
**What**: Add `.cosmicElevation(.medium)` to the CosmicMapView frame for depth separation.

### 1C. Float Tooltip to Overlap Chart Edge
**File**: `UnifiedTimeTravelView.swift`
**What**: Add `offset(y: -16)` and `.cosmicElevation(.low)` to the planet tooltip pill. Restyle its background to `.ultraThinMaterial` with `Color.cosmicVoid.opacity(0.6)` underlay, so it visually bridges the dark chart and light cards.

### 1D. Tighten Spacing Below Chart
**File**: `UnifiedTimeTravelView.swift`
**What**: Change from uniform `Cosmic.Spacing.lg` (24pt) between all sections to:
- `Cosmic.Spacing.xl` (32pt) above the chart (after TimeSeeker)
- `Cosmic.Spacing.sm` (12pt) below the chart (to tooltip and MeaningStack)
This groups the "result" elements together and separates them from the "input" control.

---

## Phase 2: NOW Card Promotion (HIGH impact, LOW effort)

### 2A. Promote Theme Headline
**File**: `MeaningStack.swift`
**What**: Change theme text from `.cosmicHeadline` (18pt) to `.cosmicTitle1` (26pt semibold) with `.cosmicCelestialGradient()` text fill and `.cosmicBreathingGlow(color: .cosmicGold)`.

### 2B. Restructure Dasha Symbols
**File**: `MeaningStack.swift`
**What**: Move dasha lord symbols from top-right header to directly above the theme text at `.cosmicTitle1` size with `.cosmicFloat(amount: 3)`. Creates visual narrative: symbols = cause, theme = effect.

### 2C. Promote "NOW" Label
**File**: `MeaningStack.swift`
**What**: Change from `.cosmicCaptionEmphasis` + `.cosmicTextSecondary` to `.cosmicUppercaseLabel()` + `.cosmicGold`.

### 2D. Risk/Opportunity Visual Polarity
**File**: `MeaningStack.swift`
**What**: Stack risk and opportunity vertically (not side-by-side). Each gets:
- **Risk**: `.cosmicError.opacity(0.12)` background, 3pt leading accent bar in `.cosmicError`, text in `.cosmicCalloutEmphasis` colored `.cosmicError`
- **Opportunity**: `.cosmicSuccess.opacity(0.12)` background, 3pt leading accent bar in `.cosmicSuccess`, text in `.cosmicCalloutEmphasis` colored `.cosmicSuccess`

### 2E. Strengthen Gold Border
**File**: `MeaningStack.swift`
**What**: Increase border gradient from `opacity(0.3)/opacity(0.1)` to `opacity(0.5)/opacity(0.2)` with lineWidth 1.5pt. Use `Cosmic.Radius.hero` (28pt) instead of `Cosmic.Radius.card` (16pt).

### 2F. Add Inline Detail Preview
**File**: `MeaningStack.swift`
**What**: Show first 2 lines of `snapshot.now.expandedDetail` directly in the card using `.cosmicBody` with `.lineLimit(2)`. Users shouldn't need to tap to get the narrative.

### 2G. Entrance Animation
**File**: `MeaningStack.swift`
**What**: Add `.transition(.cosmicDramaticReveal)` on card appear.

---

## Phase 3: NEXT Card Demotion + Timeline Redesign (MEDIUM impact, MEDIUM effort)

### 3A. Vertical Timeline Visualization
**File**: `MeaningStack.swift`
**What**: Replace flat `ForEach` list with a vertical timeline:
- 2pt vertical line in `.cosmicTextTertiary.opacity(0.3)` on the left
- Node markers sized by significance: 8pt (Praty), 12pt (Antar), 16pt (Maha)
- Colors: `.cosmicAmethyst` (Praty), `.cosmicInfo` (Antar), `.cosmicGold` with breathing glow (Maha)
- Staggered appearance via `.cosmicStaggeredAppear()`

### 3B. Escalating Typography
**File**: `MeaningStack.swift`
**What**: Scale typography by transition significance:
- Pratyantardasha: `.cosmicCalloutEmphasis` for lords, `.caption.monospacedDigit()` for countdown
- Antardasha: `.cosmicBodyEmphasis` for lords, `.cosmicCallout.monospacedDigit()` for countdown
- Mahadasha: `.cosmicHeadline` for lords, `.cosmicCalloutEmphasis.monospacedDigit()` for countdown, subtle gold gradient border on row

### 3C. Hero Countdown Number
**File**: `MeaningStack.swift`
**What**: Replace small capsule pill with hero countdown: `.cosmicMonoLarge` + `.cosmicGoldGradient()` in top-right of NEXT card. Urgency coloring: <7d = `.cosmicCopper`, <30d = `.cosmicAmethyst`, >365d = `.cosmicGold`.

### 3D. Demote Card Container
**File**: `MeaningStack.swift`
**What**: Keep `Color.cosmicSurface` but add `.cosmicElevation(.low)` and thin (1pt) `.cosmicTextTertiary.opacity(0.15)` border. No gold -- reserve gold for NOW card.

### 3E. whatShifts Promotion
**File**: `MeaningStack.swift`
**What**: Move `whatShifts` from bottom footnote to subtitle under each transition's "From -> To". Use `.cosmicCaption` in `.cosmicTextTertiary`, `lineLimit(2)`.

### 3F. Increase Inter-Card Spacing
**File**: `MeaningStack.swift`
**What**: Change VStack spacing from `Cosmic.Spacing.sm` (12pt) to `Cosmic.Spacing.md` (16pt) between NOW and NEXT cards.

---

## Implementation Order

```
Phase 1 (Bridge)  -- do first, biggest visual improvement
  1A -> 1B -> 1C -> 1D  (sequential, ~45 min)

Phase 2 (NOW Card) -- do second, highest insight impact
  2C -> 2A -> 2B -> 2D -> 2E -> 2F -> 2G  (sequential, ~60 min)

Phase 3 (NEXT Card) -- do third, polish
  3F -> 3D -> 3A -> 3B -> 3C -> 3E  (sequential, ~90 min)
```

## Files Changed

| File | Phases |
|------|--------|
| `UnifiedTimeTravelView.swift` | 1A, 1B, 1C, 1D |
| `MeaningStack.swift` | 2A-2G, 3A-3F |

**Total: 2 files.** All changes use existing Cosmic design tokens -- zero new tokens needed.

## Dark Mode Notes

All proposed colors have light/dark variants in CosmicColors.swift. One caution: `.cosmicBreathingGlow()` shadow is more visible on dark backgrounds. Consider reducing glow opacity on light mode via `@Environment(\.colorScheme)` check (0.15 light vs 0.3 dark).
