# Accessibility Scope of Work - Astronova iOS App

**Document Version:** 1.0
**Date:** January 13, 2026
**Audit Completed:** ✅
**Status:** Ready for Implementation

---

## Executive Summary

This document outlines a comprehensive plan to bring Astronova iOS app into full compliance with Apple's accessibility guidelines (WCAG 2.1 Level AA standards). The audit revealed 73 existing accessibility implementations across 17 files, indicating partial coverage. However, critical gaps exist in VoiceOver support for main user journeys, Dynamic Type support for vision accessibility, and touch target compliance.

**Impact:** 15-20% of iOS users have some form of accessibility need. Addressing these gaps will:
- Enable VoiceOver users to use core app features (currently impossible)
- Support users with vision impairments through Dynamic Type
- Improve usability for users with motor impairments
- Improve App Store review outcomes
- Demonstrate commitment to inclusive design

**Estimated Total Effort:** 24-32 hours
**Recommended Timeline:** 1-2 weeks (phased approach)

---

## Phase 1: VoiceOver Support (CRITICAL - Priority 1)

### 1.1 HomeView.swift - Today Tab
**File:** `/client/AstronovaApp/Features/Home/HomeView.swift`
**Current State:** 0 accessibility implementations
**Estimated Effort:** 4-6 hours

#### Components Requiring Accessibility:

**Navigation & Header Elements:**
- [ ] App title/header
  - Add `.accessibilityAddTraits(.isHeader)` to main title
  - Ensure proper heading hierarchy

**Today's Cosmic Weather Card:**
- [ ] Card container
  - `.accessibilityElement(children: .combine)` to group related content
  - `.accessibilityLabel("Today's cosmic weather for [date]")`
  - `.accessibilityHint("Displays your daily astrological forecast")`

**Domain Cards Grid (6 cards: Personal, Love, Career, Wealth, Health, Family):**
- [ ] Each domain card button
  ```swift
  .accessibilityElement(children: .combine)
  .accessibilityLabel("\(domain) domain. \(summaryText)")
  .accessibilityHint("Double tap to view detailed \(domain) insights")
  .accessibilityAddTraits(.isButton)
  ```
- [ ] Planet/transit indicator badges
  - `.accessibilityLabel("Active transit: [planet name] [aspect] [planet name]")`
  - OR `.accessibilityHidden(true)` if purely decorative

**Action Buttons:**
- [ ] "View All Insights" or navigation buttons
  - Clear labels describing destination
  - Appropriate hints for non-obvious actions

**Loading & Error States:**
- [ ] Loading spinner
  - `.accessibilityLabel("Loading cosmic weather")`
  - `.accessibilityValue("In progress")`
- [ ] Error messages
  - Ensure error text is automatically read by VoiceOver
  - Add recovery action hints

#### Implementation Pattern:
```swift
// Example for Domain Card
VStack(alignment: .leading) {
    HStack {
        Image(systemName: "sparkles")
            .accessibilityHidden(true) // Decorative icon
        Text(domain.title)
            .font(.cosmicHeadline)
        Spacer()
        if domain.hasActiveTransit {
            Circle()
                .accessibilityLabel("Active transit today")
        }
    }
    Text(domain.summary)
        .font(.cosmicBody)
        .lineLimit(2)
}
.accessibilityElement(children: .combine)
.accessibilityLabel("\(domain.title) domain: \(domain.summary)")
.accessibilityHint("Double tap to explore \(domain.title) insights")
.accessibilityAddTraits(.isButton)
.onTapGesture {
    // Navigate to domain detail
}
```

#### Testing Checklist:
- [ ] All interactive elements focusable with VoiceOver swipe
- [ ] Navigation order follows visual hierarchy (top to bottom, left to right)
- [ ] Card tap actions clearly announced
- [ ] No "Button" or generic labels without context
- [ ] Loading states announced automatically

---

### 1.2 OracleView.swift - AI Chat Feature
**File:** `/client/AstronovaApp/Features/Oracle/OracleView.swift`
**Current State:** 0 accessibility implementations
**Estimated Effort:** 5-7 hours

#### Components Requiring Accessibility:

**Chat Message List:**
- [ ] ScrollView/List container
  - `.accessibilityLabel("Chat conversation with Oracle")`
  - `.accessibilityHint("Scroll to view message history")`

- [ ] Individual message bubbles (user + assistant)
  ```swift
  // User message
  .accessibilityElement(children: .combine)
  .accessibilityLabel("You said: \(messageText)")
  .accessibilityAddTraits(.isStaticText)

  // Assistant message
  .accessibilityElement(children: .combine)
  .accessibilityLabel("Oracle replied: \(messageText)")
  .accessibilityAddTraits(.isStaticText)
  ```

- [ ] Timestamp labels
  - `.accessibilityLabel("Sent at \(formattedTime)")` OR
  - `.accessibilityHidden(true)` if redundant

**Message Input Area:**
- [ ] Text field
  ```swift
  TextField("Ask Oracle about your cosmic journey...", text: $messageText)
      .accessibilityLabel("Message input field")
      .accessibilityHint("Type your question for Oracle. Double tap to edit.")
  ```

- [ ] Send button
  ```swift
  Button(action: sendMessage) {
      Image(systemName: "paperplane.fill")
  }
  .accessibilityLabel("Send message")
  .accessibilityHint("Sends your question to Oracle")
  .disabled(messageText.isEmpty)
  .accessibilityAddTraits(messageText.isEmpty ? .isButton : [.isButton])
  ```

**Special Features:**
- [ ] Package selection button (if quota limited)
  - `.accessibilityLabel("Chat packages. Current: \(packageName), \(remainingMessages) messages remaining")`
  - `.accessibilityHint("Double tap to view and upgrade chat packages")`

- [ ] Birth data sync indicator
  - `.accessibilityLabel("Birth data synced with Oracle for personalized insights")`
  - OR `.accessibilityHidden(true)` if purely visual feedback

**Typing Indicators & Loading:**
- [ ] "Oracle is typing..." indicator
  - `.accessibilityLabel("Oracle is composing a response")`
  - `.accessibilityLiveRegion(.polite)` for dynamic updates

**Empty States:**
- [ ] Welcome message / empty conversation
  - Clear instructions for first-time users
  - Example questions as accessible buttons

#### Keyboard Navigation:
- [ ] Ensure TextField and Send button are in proper focus order
- [ ] Test with hardware keyboard (Tab navigation)
- [ ] Return key should send message (configure `.submitLabel(.send)`)

#### Implementation Pattern:
```swift
// Message bubble
HStack(alignment: .top) {
    if message.role == .assistant {
        Image(systemName: "sparkles")
            .accessibilityHidden(true)
    }

    VStack(alignment: message.role == .user ? .trailing : .leading) {
        Text(message.content)
            .font(.cosmicBody)
        Text(message.timestamp)
            .font(.cosmicCaption)
            .foregroundColor(.cosmicTextSecondary)
            .accessibilityHidden(true) // Timestamp not critical for comprehension
    }
}
.accessibilityElement(children: .combine)
.accessibilityLabel("\(message.role == .user ? "You" : "Oracle") said: \(message.content)")
.accessibilityAddTraits(.isStaticText)
```

#### Testing Checklist:
- [ ] Can navigate through all messages with VoiceOver
- [ ] Message role (user vs Oracle) clearly announced
- [ ] Text input field accessible and editable
- [ ] Send button state (enabled/disabled) announced
- [ ] Typing indicators announced via live region
- [ ] New incoming messages announced automatically

---

### 1.3 TempleView.swift - Pooja Booking
**File:** `/client/AstronovaApp/Features/Temple/TempleView.swift`
**Current State:** 0 accessibility implementations
**Estimated Effort:** 6-8 hours

#### Components Requiring Accessibility:

**Pooja Type Selection Grid:**
- [ ] Section header
  - `.accessibilityAddTraits(.isHeader)`
  - `.accessibilityLabel("Available Pooja Types")`

- [ ] Each Pooja card (Ganesh, Lakshmi, Durga, etc.)
  ```swift
  .accessibilityElement(children: .combine)
  .accessibilityLabel("\(poojaName) Pooja. Duration: \(duration) minutes. Price: \(price) rupees")
  .accessibilityHint("Double tap to view details and book this pooja")
  .accessibilityAddTraits(.isButton)
  ```

- [ ] Deity icons
  - `.accessibilityHidden(true)` (decorative)

- [ ] Benefits list (if visible on card)
  - Combine into accessibility label: "Benefits: \(benefits.joined(separator: ", "))"

**Pandit Selection:**
- [ ] Pandit profile cards
  ```swift
  .accessibilityLabel("Pandit \(name). \(experience) years experience. Rating \(rating) out of 5 stars. Specializes in \(specializations). Price: \(price) per session")
  .accessibilityHint("Double tap to select this pandit for your pooja")
  ```

- [ ] Rating stars
  - `.accessibilityLabel("\(rating) out of 5 stars")`
  - `.accessibilityHidden(false)` // Important info

- [ ] Language badges
  - `.accessibilityLabel("Speaks \(languages.joined(separator: ", "))")`

**Booking Form:**
- [ ] Date picker
  ```swift
  DatePicker("Select date", selection: $selectedDate)
      .accessibilityLabel("Pooja date")
      .accessibilityHint("Select the date for your pooja ceremony")
  ```

- [ ] Time slot picker
  ```swift
  Picker("Time slot", selection: $selectedTime) { ... }
      .accessibilityLabel("Available time slots")
      .accessibilityHint("Choose a time slot for your pooja")
  ```

- [ ] Sankalp details (name, gotra, nakshatra)
  ```swift
  TextField("Your name", text: $sankalpName)
      .accessibilityLabel("Sankalp name")
      .accessibilityHint("Enter your full name for the pooja ceremony")

  TextField("Gotra", text: $gotra)
      .accessibilityLabel("Gotra")
      .accessibilityHint("Optional. Enter your gotra if known")
  ```

- [ ] Special requests text area
  ```swift
  TextEditor(text: $specialRequests)
      .accessibilityLabel("Special requests")
      .accessibilityHint("Optional. Add any special instructions for the pandit")
  ```

**Booking Summary & Confirmation:**
- [ ] Price breakdown
  - `.accessibilityElement(children: .combine)`
  - `.accessibilityLabel("Total cost: \(totalPrice) rupees. Includes: Pooja fee \(poojaPrice), Pandit fee \(panditPrice)")`

- [ ] "Confirm Booking" button
  ```swift
  .accessibilityLabel("Confirm booking")
  .accessibilityHint("Complete your booking and proceed to payment")
  .disabled(!isValid)
  ```

**Video Session Interface:**
- [ ] Session link button
  ```swift
  .accessibilityLabel("Join video session with Pandit \(panditName)")
  .accessibilityHint("Opens video call for your scheduled pooja")
  ```

- [ ] Session status indicators
  - "Waiting for pandit to join"
  - "Session in progress"
  - "Session ended"
  - Ensure all announced with `.accessibilityLiveRegion(.polite)`

**Booking History:**
- [ ] Past booking cards
  ```swift
  .accessibilityLabel("\(poojaName) pooja with Pandit \(panditName) on \(date). Status: \(status)")
  .accessibilityHint("Double tap to view booking details")
  ```

#### Implementation Pattern:
```swift
// Pooja Card
VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
    HStack {
        Image(pooja.icon)
            .resizable()
            .frame(width: 48, height: 48)
            .accessibilityHidden(true)

        VStack(alignment: .leading) {
            Text(pooja.name)
                .font(.cosmicHeadline)
            Text("\(pooja.duration) min • ₹\(pooja.price)")
                .font(.cosmicCaption)
                .foregroundColor(.cosmicTextSecondary)
        }
    }

    Text(pooja.description)
        .font(.cosmicBody)
        .lineLimit(2)

    HStack {
        ForEach(pooja.benefits.prefix(3), id: \.self) { benefit in
            Text("• \(benefit)")
                .font(.cosmicCaption)
        }
    }
}
.padding(Cosmic.Spacing.md)
.background(Color.cosmicStardust)
.cornerRadius(Cosmic.Radius.card)
.accessibilityElement(children: .combine)
.accessibilityLabel("""
    \(pooja.name) Pooja.
    Duration: \(pooja.duration) minutes.
    Price: \(pooja.price) rupees.
    Benefits: \(pooja.benefits.prefix(3).joined(separator: ", "))
    """)
.accessibilityHint("Double tap to view full details and book this pooja")
.accessibilityAddTraits(.isButton)
```

#### Testing Checklist:
- [ ] All pooja types accessible and distinguishable
- [ ] Pandit profiles provide sufficient context
- [ ] Form fields clearly labeled and hinted
- [ ] Date/time pickers accessible
- [ ] Booking summary read completely before confirmation
- [ ] Video session controls accessible
- [ ] Error states (unavailable slots, etc.) announced

---

### 1.4 ConnectView.swift - Relationships/Compatibility
**File:** `/client/AstronovaApp/ConnectView.swift`
**Current State:** 0 accessibility implementations
**Estimated Effort:** 4-5 hours

#### Components Requiring Accessibility:

**Relationship List:**
- [ ] Empty state
  - `.accessibilityLabel("No relationships added yet")`
  - `.accessibilityHint("Add a relationship to explore cosmic compatibility")`

- [ ] "Add Relationship" button
  ```swift
  .accessibilityLabel("Add new relationship")
  .accessibilityHint("Create a compatibility analysis with someone special")
  ```

- [ ] Relationship cards
  ```swift
  .accessibilityLabel("""
      Relationship with \(partnerName).
      Compatibility score: \(score) out of 100.
      \(favoriteStatus)
      """)
  .accessibilityHint("Double tap to view detailed compatibility analysis")
  .accessibilityAddTraits(.isButton)
  ```

- [ ] Favorite star icon
  ```swift
  Button(action: toggleFavorite) {
      Image(systemName: isFavorite ? "star.fill" : "star")
  }
  .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
  .accessibilityAddTraits(.isButton)
  ```

**Relationship Detail View:**
- [ ] Synastry Compass visualization
  ```swift
  // Complex visualization - provide text alternative
  .accessibilityLabel("""
      Synastry compass showing \(activeAspects.count) active aspects.
      Current relationship pulse: \(pulseState).
      \(aspectsSummary)
      """)
  .accessibilityHint("Visual representation of astrological compatibility")
  ```

- [ ] Compatibility score gauge
  - `.accessibilityLabel("Overall compatibility: \(score) out of 100")`
  - `.accessibilityValue("\(scoreCategory)")`  // e.g., "Excellent", "Good", "Challenging"

- [ ] Aspect breakdown cards (Conjunction, Trine, Square, etc.)
  ```swift
  .accessibilityLabel("\(aspectType) aspect. \(planetA) \(aspectType) \(planetB). Impact: \(impactDescription)")
  .accessibilityHint("Double tap to learn more about this aspect")
  ```

**Add Relationship Flow:**
- [ ] Contact picker button
  ```swift
  .accessibilityLabel("Select from contacts")
  .accessibilityHint("Choose a contact to import birth date information")
  ```

- [ ] Birth data form fields
  ```swift
  TextField("Partner name", text: $name)
      .accessibilityLabel("Partner's name")

  DatePicker("Birth date", selection: $birthDate)
      .accessibilityLabel("Partner's birth date")

  // Location field with autocomplete
  .accessibilityLabel("Birth location")
  .accessibilityHint("Start typing to search for cities")
  ```

- [ ] "Create Relationship" button
  ```swift
  .accessibilityLabel("Create relationship analysis")
  .accessibilityHint("Generates compatibility report with entered birth data")
  .disabled(!isValid)
  ```

**Relationship Actions:**
- [ ] Edit button
  - `.accessibilityLabel("Edit relationship details")`

- [ ] Delete button
  - `.accessibilityLabel("Delete relationship")`
  - `.accessibilityHint("Removes this relationship from your list")`
  - Should trigger confirmation alert

#### Implementation Pattern:
```swift
// Relationship Card
HStack(spacing: Cosmic.Spacing.md) {
    // Avatar or initial
    Circle()
        .fill(Color.cosmicGold)
        .frame(width: 56, height: 56)
        .overlay(
            Text(relationship.partnerName.prefix(1))
                .font(.cosmicTitle2)
        )
        .accessibilityHidden(true)

    VStack(alignment: .leading, spacing: 4) {
        HStack {
            Text(relationship.partnerName)
                .font(.cosmicHeadline)

            if relationship.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.cosmicGold)
                    .accessibilityHidden(true) // Announced in label
            }
        }

        HStack {
            Text("\(relationship.compatibilityScore)%")
                .font(.cosmicBodyEmphasis)
                .foregroundColor(.cosmicGold)

            Text("compatibility")
                .font(.cosmicBody)
                .foregroundColor(.cosmicTextSecondary)
        }

        Text(relationship.pulseState)
            .font(.cosmicCaption)
            .foregroundColor(.cosmicTextTertiary)
    }

    Spacer()

    Image(systemName: "chevron.right")
        .foregroundColor(.cosmicTextTertiary)
        .accessibilityHidden(true)
}
.padding(Cosmic.Spacing.md)
.background(Color.cosmicStardust)
.cornerRadius(Cosmic.Radius.card)
.accessibilityElement(children: .combine)
.accessibilityLabel("""
    Relationship with \(relationship.partnerName).
    Compatibility score: \(relationship.compatibilityScore) percent.
    Current energy: \(relationship.pulseState).
    \(relationship.isFavorite ? "Marked as favorite." : "")
    """)
.accessibilityHint("Double tap to view detailed compatibility analysis")
.accessibilityAddTraits(.isButton)
```

#### Testing Checklist:
- [ ] Can navigate through relationship list
- [ ] Compatibility scores clearly announced
- [ ] Add relationship flow fully accessible
- [ ] Contact picker integration works with VoiceOver
- [ ] Complex visualizations have text alternatives
- [ ] Edit/delete actions clearly labeled

---

## Phase 2: Dynamic Type Support (HIGH - Priority 2)

### 2.1 Typography System Update
**File:** `/client/AstronovaApp/CosmicTypography.swift`
**Current State:** Fixed font sizes (44pt, 32pt, 26pt, etc.) - does NOT scale
**Estimated Effort:** 6-8 hours (including testing)

#### Problem Statement:
Current typography uses `Font.system(size: CGFloat)` with hardcoded point sizes. This prevents text from scaling when users enable Larger Text in iOS Settings (Accessibility → Display & Text Size).

**Impact:** Users with vision impairments cannot enlarge text for readability.

#### Solution Options:

**Option A: Use Native TextStyles (Recommended - Lower Risk)**
```swift
enum CosmicTypography {
    // BEFORE (fixed):
    static let hero = Font.system(size: 44, weight: .bold, design: .default)
    static let body = Font.system(size: 16, weight: .regular, design: .default)

    // AFTER (scales automatically):
    static let hero = Font.largeTitle.weight(.bold)
    static let display = Font.title.weight(.bold)
    static let title1 = Font.title2.weight(.semibold)
    static let title2 = Font.title3.weight(.semibold)
    static let headline = Font.headline.weight(.semibold)
    static let body = Font.body
    static let bodyEmphasis = Font.body.weight(.medium)
    static let callout = Font.callout
    static let caption = Font.caption.weight(.medium)
    static let micro = Font.caption2.weight(.medium)
}
```

**Pros:**
- Automatic Dynamic Type support
- Apple-recommended approach
- Minimal code changes
- Well-tested by iOS

**Cons:**
- Less control over exact sizes
- May require visual design adjustments

---

**Option B: Custom Scaling with @ScaledMetric (More Control)**
```swift
enum CosmicTypography {
    // Define base sizes
    private enum BaseSize {
        static let hero: CGFloat = 44
        static let display: CGFloat = 32
        static let title1: CGFloat = 26
        static let body: CGFloat = 16
        static let caption: CGFloat = 12
        static let micro: CGFloat = 10
    }

    // Use @ScaledMetric in views
    struct ScaledFonts {
        @ScaledMetric(relativeTo: .largeTitle) private var heroSize: CGFloat = BaseSize.hero
        @ScaledMetric(relativeTo: .title) private var displaySize: CGFloat = BaseSize.display
        @ScaledMetric(relativeTo: .title2) private var title1Size: CGFloat = BaseSize.title1
        @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = BaseSize.body
        @ScaledMetric(relativeTo: .caption) private var captionSize: CGFloat = BaseSize.caption
        @ScaledMetric(relativeTo: .caption2) private var microSize: CGFloat = BaseSize.micro

        var hero: Font { Font.system(size: heroSize, weight: .bold) }
        var display: Font { Font.system(size: displaySize, weight: .bold) }
        var title1: Font { Font.system(size: title1Size, weight: .semibold) }
        var body: Font { Font.system(size: bodySize, weight: .regular) }
        var caption: Font { Font.system(size: captionSize, weight: .medium) }
        var micro: Font { Font.system(size: microSize, weight: .medium) }
    }
}

// Usage in views:
struct HomeView: View {
    @ScaledMetric private var spacing: CGFloat = 12
    private let fonts = CosmicTypography.ScaledFonts()

    var body: some View {
        Text("Welcome")
            .font(fonts.hero)
    }
}
```

**Pros:**
- Maintains exact visual design at default size
- Scales proportionally with user preferences
- More granular control

**Cons:**
- More complex implementation
- Requires updating all views to use new pattern
- Need to test each font size category

---

#### Recommended Implementation: **Hybrid Approach**

**Phase 2.1a: Update Core Typography (3-4 hours)**
1. Modify `CosmicTypography.swift` to provide both static (legacy) and dynamic options
2. Create new `.dynamic` namespace for scaled fonts
3. Maintain backward compatibility during transition

```swift
// CosmicTypography.swift
enum CosmicTypography {
    // MARK: - Fixed Sizes (Legacy - Deprecated)
    @available(*, deprecated, message: "Use .dynamic for accessibility support")
    static let hero = Font.system(size: 44, weight: .bold)

    // MARK: - Dynamic Type Support (Preferred)
    enum Dynamic {
        static let hero = Font.largeTitle.weight(.bold)
        static let display = Font.title.weight(.bold)
        static let title1 = Font.title2.weight(.semibold)
        static let title2 = Font.title3.weight(.semibold)
        static let headline = Font.headline.weight(.semibold)
        static let body = Font.body
        static let bodyEmphasis = Font.body.weight(.medium)
        static let callout = Font.callout
        static let calloutEmphasis = Font.callout.weight(.medium)
        static let caption = Font.caption.weight(.medium)
        static let micro = Font.caption2.weight(.medium)
    }
}

// Convenience extensions for SwiftUI
extension Font {
    static let cosmicHero = CosmicTypography.Dynamic.hero
    static let cosmicDisplay = CosmicTypography.Dynamic.display
    static let cosmicTitle1 = CosmicTypography.Dynamic.title1
    static let cosmicTitle2 = CosmicTypography.Dynamic.title2
    static let cosmicHeadline = CosmicTypography.Dynamic.headline
    static let cosmicBody = CosmicTypography.Dynamic.body
    static let cosmicBodyEmphasis = CosmicTypography.Dynamic.bodyEmphasis
    static let cosmicCallout = CosmicTypography.Dynamic.callout
    static let cosmicCaption = CosmicTypography.Dynamic.caption
    static let cosmicMicro = CosmicTypography.Dynamic.micro
}
```

**Phase 2.1b: Update Views (3-4 hours)**
Systematically replace fixed fonts with dynamic equivalents:

**Priority Views for Update:**
1. ✅ HomeView.swift - Daily insights text
2. ✅ OracleView.swift - Chat messages
3. ✅ TempleView.swift - Booking details
4. ✅ ConnectView.swift - Relationship descriptions
5. ✅ RootView.swift - Tab labels
6. ✅ PaywallView.swift - Pricing info

**Search & Replace Strategy:**
```bash
# Find all .font(.cosmicBody) usages
grep -r "\.font(\.cosmic" client/AstronovaApp/

# Verify they're already using the extension (no code change needed!)
# If using Font.system directly, update to Font.cosmicBody
```

**Manual Review Required:**
- Custom font applications
- Attributed strings
- Text in images/charts (may need layout adjustments)

---

### 2.2 Layout Considerations
**Estimated Effort:** 2-3 hours

When text scales, layouts must adapt:

**Issue 1: Text Truncation**
```swift
// BEFORE (bad - truncates at larger sizes):
Text("Your cosmic insights for today")
    .lineLimit(1)

// AFTER (good - adapts to content):
Text("Your cosmic insights for today")
    .lineLimit(2)  // Allow wrapping
    .minimumScaleFactor(0.8)  // Slight scale-down before wrapping
```

**Issue 2: Fixed Heights**
```swift
// BEFORE (bad - clips content):
VStack {
    Text(headline)
        .font(.cosmicHeadline)
}
.frame(height: 50)  // Fixed height

// AFTER (good - flexible):
VStack {
    Text(headline)
        .font(.cosmicHeadline)
}
// No fixed height - let content determine size
```

**Issue 3: ScrollView Containment**
```swift
// Ensure content can scroll when text grows
ScrollView {
    VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
        // Dynamic content
    }
    .padding()
}
```

---

### 2.3 Testing Strategy
**Estimated Effort:** 2-3 hours

**Test Matrix:**

| Content Size Category | iOS Setting | Test Scenarios |
|-----------------------|-------------|----------------|
| XS (Default) | Default | Baseline - current appearance |
| S-M | 1-2 notches larger | Common vision assistance |
| L-XL | 3-4 notches larger | Significant vision impairment |
| XXL-XXXL (Accessibility) | Max sizes | Severe vision impairment |

**Per View Testing:**
1. Launch app with each size category
2. Navigate to view
3. Verify:
   - [ ] Text readable (not truncated)
   - [ ] Buttons remain tappable
   - [ ] Layout doesn't break
   - [ ] ScrollViews scroll when needed
   - [ ] No overlapping elements

**Automated Testing:**
```swift
// Add to AstronovaAppTests
func testDynamicTypeSupport() {
    // Test with different content size categories
    let categories: [UIContentSizeCategory] = [
        .extraSmall,
        .medium,
        .extraLarge,
        .extraExtraExtraLarge,
        .accessibilityMedium,
        .accessibilityExtraExtraExtraLarge
    ]

    for category in categories {
        // Set content size
        app.contentSizeCategory = category

        // Verify key views render without errors
        XCTAssertTrue(app.buttons["Add Relationship"].exists)
        XCTAssertTrue(app.buttons["Send message"].exists)
    }
}
```

---

### 2.4 Visual Design Review
**Estimated Effort:** 2 hours

**Collaboration Required:** Designer review after implementation

After Dynamic Type is implemented:
1. Review app at largest accessibility sizes
2. Identify if any spacing/padding needs adjustment
3. Confirm visual hierarchy maintained
4. Approve font size mappings (e.g., hero → largeTitle)

**Potential Adjustments:**
- Card padding may need to increase at larger sizes
- Icon sizes may need to scale (use @ScaledMetric)
- Grid layouts may need to change columns (3 → 2 → 1)

---

## Phase 3: Touch Target Compliance (MEDIUM - Priority 3)

### 3.1 Button Height Correction
**File:** `/client/AstronovaApp/CosmicDesignSystem.swift`
**Current State:** ButtonHeight.small = 40pt (violates 44pt minimum)
**Estimated Effort:** 1 hour implementation + 2 hours testing

#### Changes Required:

```swift
// BEFORE:
enum ButtonHeight {
    static let small: CGFloat = 40  // ❌ Violates accessibility
    static let medium: CGFloat = 48
    static let large: CGFloat = 52
    static let hero: CGFloat = 56
}

// AFTER:
enum ButtonHeight {
    static let small: CGFloat = 44   // ✅ Meets minimum
    static let medium: CGFloat = 48
    static let large: CGFloat = 52
    static let hero: CGFloat = 56
}
```

**Impact Analysis:**
- Search for all usages: `grep -r "ButtonHeight.small" client/AstronovaApp/`
- Review visual impact (buttons may look slightly taller)
- Test layouts to ensure no overlapping

---

### 3.2 Touch Target Audit
**Estimated Effort:** 3-4 hours

Systematically check all interactive elements:

**Checklist:**
- [ ] All buttons minimum 44x44pt
- [ ] Tab bar icons + labels meet 44pt height
- [ ] Stepper controls (+ / -) meet 44pt
- [ ] Close/dismiss buttons (×) meet 44pt
- [ ] Slider thumbs meet 44pt
- [ ] Toggle switches (native = compliant)
- [ ] Segmented controls segments ≥ 44pt height
- [ ] List row touch targets ≥ 44pt height

**Common Violations to Check:**

**Small Icon Buttons:**
```swift
// BEFORE (bad - 32pt touch target):
Button(action: dismiss) {
    Image(systemName: "xmark")
        .font(.system(size: 14))
}
.frame(width: 32, height: 32)

// AFTER (good - 44pt touch target):
Button(action: dismiss) {
    Image(systemName: "xmark")
        .font(.system(size: 14))
}
.frame(width: 44, height: 44)
.contentShape(Rectangle())  // Ensure full frame is tappable
```

**Inline Action Buttons:**
```swift
// Bad - small tap area
HStack {
    Text("Favorite")
    Button(action: toggleFavorite) {
        Image(systemName: "star")
            .font(.system(size: 16))
    }
}

// Good - adequate tap area
HStack {
    Text("Favorite")
    Button(action: toggleFavorite) {
        Image(systemName: "star")
            .font(.system(size: 16))
    }
    .frame(minWidth: 44, minHeight: 44)
}
```

---

### 3.3 Implementation Utilities

Create reusable modifier for touch target enforcement:

```swift
// Add to CosmicDesignSystem.swift
extension View {
    /// Ensures minimum 44x44pt touch target (Apple HIG)
    func accessibleTouchTarget() -> some View {
        self.frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
    }

    /// Square touch target for icon buttons
    func accessibleIconButton(size: CGFloat = 44) -> some View {
        self.frame(width: size, height: size)
            .contentShape(Rectangle())
    }
}

// Usage:
Button(action: close) {
    Image(systemName: "xmark")
}
.accessibleIconButton()  // Automatically 44x44
```

---

## Phase 4: Color Contrast Verification (LOW - Priority 4)

### 4.1 Color Contrast Audit
**Estimated Effort:** 2-3 hours

**WCAG 2.1 Requirements:**
- **Normal text:** 4.5:1 contrast ratio minimum
- **Large text (≥18pt):** 3:1 contrast ratio minimum
- **UI components:** 3:1 contrast ratio minimum

**Current Color System:**
```swift
// Primary text on dark background
cosmicTextPrimary (#F5F0E6) on cosmicVoid (#08080C)
// Calculate: contrast ratio = ?

// Primary text on light background
cosmicTextPrimary (#1A1612) on cosmicVoid (#FAF6F0)
// Calculate: contrast ratio = ?

// Gold accent on dark background
cosmicGold (#D4A853) on cosmicVoid (#08080C)
// Calculate: contrast ratio = ? (concern)
```

**Tools for Verification:**
1. Online: https://webaim.org/resources/contrastchecker/
2. macOS: Digital Color Meter + manual calculation
3. Xcode: Accessibility Inspector → Color Contrast

**Testing Process:**
1. Screenshot each view
2. Extract hex colors from design tokens
3. Calculate contrast ratios
4. Document violations
5. Propose adjusted colors if needed

---

### 4.2 Potential Issues & Solutions

**Likely Issue: Gold accent on dark backgrounds**
```swift
// Current (might fail 4.5:1 for small text):
cosmicGold (#D4A853) on cosmicVoid (#08080C)

// Solution options:
// 1. Lighten gold for dark mode
static let cosmicGold = SwiftUI.Color(
    light: SwiftUI.Color(hex: "B8923D"),  // Darker for light mode
    dark: SwiftUI.Color(hex: "E6C679")    // Lighter for dark mode
)

// 2. Add text outline/shadow for small gold text
Text("Important")
    .foregroundColor(.cosmicGold)
    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 0)

// 3. Use gold only for large text (≥18pt) or decorative elements
```

---

## Phase 5: Testing & Validation

### 5.1 Manual Testing with Assistive Technologies
**Estimated Effort:** 6-8 hours

**Test Environment Setup:**
- [ ] iPhone with VoiceOver enabled
- [ ] Enable Dynamic Type at various sizes
- [ ] Test on physical device (not just simulator)

**VoiceOver Testing Protocol:**

**Per View Checklist:**
1. Enable VoiceOver (triple-click side button)
2. Navigate using swipe gestures
3. Verify:
   - [ ] All interactive elements reachable
   - [ ] Labels clear and contextual
   - [ ] Hints provided where needed
   - [ ] Actions announced ("Button", "Activates", etc.)
   - [ ] State changes announced (loading, error, success)
   - [ ] Navigation hierarchy logical
   - [ ] No "Button" without description
   - [ ] No "Image" without alt text (unless decorative)

**Common Issues to Watch:**
- Nested VStack/HStack breaking navigation order
- Custom gestures not accessible (use Button instead)
- Animations interfering with focus
- Sheet/modal dismissal not obvious

**Gesture Testing:**
- Two-finger swipe down: Read from top
- Two-finger Z: Back navigation
- Double-tap: Activate
- Rotor: Quick navigation (headings, links, buttons)

---

### 5.2 Automated Testing
**Estimated Effort:** 4-5 hours

**Add Accessibility Tests:**

```swift
// AstronovaAppUITests.swift
class AccessibilityTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launchArguments = ["UITEST_MODE"]
    }

    func testVoiceOverAccessibility() {
        app.launch()

        // Test main tabs are accessible
        XCTAssertTrue(app.tabBars.buttons["Discover"].exists)
        XCTAssertTrue(app.tabBars.buttons["Time Travel"].exists)
        XCTAssertTrue(app.tabBars.buttons["Temple"].exists)
        XCTAssertTrue(app.tabBars.buttons["Connect"].exists)
        XCTAssertTrue(app.tabBars.buttons["Self"].exists)

        // Verify accessibility labels
        let discoverButton = app.tabBars.buttons["Discover"]
        XCTAssertNotNil(discoverButton.label)
        XCTAssertFalse(discoverButton.label.isEmpty)
    }

    func testHomeViewAccessibility() {
        app.launch()

        // Navigate to Home/Discover tab (default)
        let cosmicWeatherCard = app.staticTexts["Today's Cosmic Weather"]
        XCTAssertTrue(cosmicWeatherCard.exists)

        // Verify domain cards exist and are accessible
        let personalCard = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Personal'")).firstMatch
        XCTAssertTrue(personalCard.exists)
        XCTAssertTrue(personalCard.isHittable)

        // Test interaction
        personalCard.tap()
        // Verify navigation occurred
    }

    func testOracleViewAccessibility() {
        app.launch()
        app.tabBars.buttons["Ask"].tap()

        // Verify chat input is accessible
        let messageField = app.textFields["Message input field"]
        XCTAssertTrue(messageField.exists)
        XCTAssertTrue(messageField.isHittable)

        // Verify send button
        let sendButton = app.buttons["Send message"]
        XCTAssertTrue(sendButton.exists)

        // Test typing and sending
        messageField.tap()
        messageField.typeText("Test message")
        XCTAssertTrue(sendButton.isEnabled)
    }

    func testTouchTargetSizes() {
        app.launch()

        // Verify critical buttons meet 44pt minimum
        let allButtons = app.buttons.allElementsBoundByIndex

        for button in allButtons {
            let frame = button.frame
            XCTAssertGreaterThanOrEqual(frame.height, 44,
                "Button '\(button.label)' height (\(frame.height)) is below 44pt minimum")
        }
    }

    func testDynamicTypeScaling() {
        // Test with accessibility content size
        app.launchArguments.append("-UIPreferredContentSizeCategoryName")
        app.launchArguments.append("UICTContentSizeCategoryAccessibilityXXXL")
        app.launch()

        // Verify app doesn't crash or truncate at largest size
        XCTAssertTrue(app.exists)

        // Take screenshot for manual review
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "DynamicType_XXXL"
        add(attachment)
    }
}
```

---

### 5.3 Accessibility Audit Tools
**Estimated Effort:** 2 hours

**Xcode Accessibility Inspector:**
1. Open Xcode → Xcode menu → Open Developer Tool → Accessibility Inspector
2. Connect to Simulator or device
3. Navigate through app
4. Inspector shows:
   - Accessibility labels
   - Hints
   - Traits
   - Element hierarchy
   - Color contrast warnings

**Document Issues:**
- Screenshot each warning
- Note file/view location
- Assign priority

---

## Phase 6: Documentation & Handoff

### 6.1 Developer Documentation
**Estimated Effort:** 2-3 hours

Create: `/client/ACCESSIBILITY_GUIDELINES.md`

**Content:**
```markdown
# Accessibility Guidelines - Astronova iOS

## Quick Reference

### VoiceOver Labels
All interactive elements MUST have:
- `.accessibilityLabel("Clear description")`
- `.accessibilityHint("What happens when activated")` (optional)
- `.accessibilityAddTraits(.isButton)` (if button-like)

### Dynamic Type
Use: `.font(.cosmicBody)` or `.font(.cosmicHeadline)`
NOT: `.font(.system(size: 16))`

### Touch Targets
Minimum 44x44pt for ALL interactive elements.
Use: `.accessibleTouchTarget()` modifier

### Testing Checklist
- [ ] VoiceOver: Navigate entire flow
- [ ] Dynamic Type: Test at XXXL size
- [ ] Touch targets: Verify no small buttons
- [ ] Color contrast: Check with Accessibility Inspector

## Examples
[Include code examples from this SOW]
```

---

### 6.2 QA Testing Guide
**Estimated Effort:** 1-2 hours

Create: `/client/ACCESSIBILITY_QA_CHECKLIST.md`

**Content:**
- Step-by-step VoiceOver testing instructions
- Dynamic Type testing procedure
- Screenshots of Accessibility Inspector
- Pass/fail criteria
- Bug reporting template

---

### 6.3 Ongoing Maintenance

**Add to Pull Request Template:**
```markdown
## Accessibility Checklist
- [ ] All new interactive elements have accessibility labels
- [ ] Fonts use .cosmicBody/.cosmicHeadline (not fixed sizes)
- [ ] Touch targets ≥ 44x44pt
- [ ] Tested with VoiceOver
- [ ] Tested with Dynamic Type (at least XL size)
```

---

## Implementation Timeline

### Week 1: VoiceOver Foundation
- **Day 1-2:** HomeView + OracleView
- **Day 3-4:** TempleView + ConnectView
- **Day 5:** Testing & bug fixes

### Week 2: Dynamic Type & Polish
- **Day 1-2:** Typography system update
- **Day 3:** Layout adjustments & testing
- **Day 4:** Touch target audit & fixes
- **Day 5:** Final testing, documentation

---

## Success Metrics

### Quantitative:
- [ ] 100% of interactive elements have accessibility labels
- [ ] 0 buttons below 44pt minimum
- [ ] All text scales with Dynamic Type
- [ ] 0 color contrast violations
- [ ] 90%+ accessibility test coverage

### Qualitative:
- [ ] VoiceOver user can complete key flows:
  - View daily insights
  - Send Oracle message
  - Book a pooja
  - Add relationship
- [ ] App usable at XXXL text size
- [ ] Passes App Store accessibility review

---

## Risk Assessment

### Low Risk:
- Adding accessibility labels (no visual change)
- Touch target size increases (minor visual change)

### Medium Risk:
- Dynamic Type implementation (requires layout testing)
- Color adjustments (requires design approval)

### Mitigation:
- Implement in feature branches
- Review with designer before merging
- Test on multiple devices/OS versions
- Phased rollout (beta testers with accessibility needs)

---

## Resources Required

### Team:
- **iOS Developer:** 24-32 hours
- **Designer:** 4-6 hours (review & approval)
- **QA Tester:** 8-10 hours (accessibility testing)

### Tools:
- Xcode 15+ (Accessibility Inspector)
- Physical iPhone for VoiceOver testing
- Color contrast checker (online or app)

### Reference:
- Apple Human Interface Guidelines - Accessibility
- WCAG 2.1 Level AA Standards
- SwiftUI Accessibility Documentation

---

## Appendix A: Common Patterns

### Pattern 1: Simple Button
```swift
Button(action: viewInsights) {
    Text("View Insights")
        .font(.cosmicCallout)
        .frame(height: 48)
}
.accessibilityLabel("View insights")
.accessibilityHint("Opens detailed cosmic insights for today")
```

### Pattern 2: Card with Multiple Elements
```swift
VStack(alignment: .leading) {
    Text(title)
        .font(.cosmicHeadline)
    Text(description)
        .font(.cosmicBody)
    Button("Learn More") { }
}
.accessibilityElement(children: .combine)
.accessibilityLabel("\(title). \(description)")
.accessibilityHint("Double tap to learn more")
.accessibilityAddTraits(.isButton)
```

### Pattern 3: Icon-Only Button
```swift
Button(action: toggleFavorite) {
    Image(systemName: isFavorite ? "star.fill" : "star")
        .font(.system(size: 20))
}
.frame(width: 44, height: 44)
.accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
```

### Pattern 4: Complex Visualization
```swift
SynastryCompassView(data: compatibility)
    .accessibilityLabel("""
        Compatibility visualization.
        Overall score: \(score) percent.
        \(aspectCount) active aspects detected.
        """)
    .accessibilityHint("Visual representation of astrological compatibility between you and your partner")
    .accessibilityAddTraits(.isImage)
```

---

## Appendix B: Testing Devices & OS Versions

### Minimum Test Coverage:
- iPhone SE (small screen)
- iPhone 16 Pro (standard)
- iPad (tablet experience)

### OS Versions:
- iOS 17.0 (deployment target)
- iOS 18.6 (current)

### Accessibility Settings to Test:
- VoiceOver ON
- Dynamic Type: Default, XL, XXXL
- Reduce Motion: ON
- Increase Contrast: ON
- Button Shapes: ON

---

**Document End**

For questions or clarifications, refer to:
- Apple HIG: https://developer.apple.com/design/human-interface-guidelines/accessibility
- WCAG 2.1: https://www.w3.org/WAI/WCAG21/quickref/
- SwiftUI Accessibility: https://developer.apple.com/documentation/swiftui/view-accessibility
