# Accessibility Guidelines - Astronova iOS

## Quick Reference

### VoiceOver
- Every interactive element must have a clear `.accessibilityLabel`.
- Add `.accessibilityHint` for non-obvious actions.
- Combine card content with `.accessibilityElement(children: .combine)`.
- Hide decorative icons with `.accessibilityHidden(true)`.
- Use `.accessibilityAddTraits(.isHeader)` for section titles.

### Dynamic Type
- Use `Font.cosmic*` variants (dynamic) instead of fixed `Font.system(size:)`.
- Avoid fixed heights on text containers; allow wrapping with `lineLimit` > 1.
- For controls that must stay compact, add `minimumScaleFactor(0.8)`.

### Touch Targets
- Minimum tap size is 44x44pt.
- Use `.accessibleTouchTarget()` for general controls.
- Use `.accessibleIconButton()` for icon-only buttons.

### Color Contrast
- Use `Color.cosmicTextPrimary` for primary text.
- Reserve `Color.cosmicGold` for emphasis; avoid low-contrast pairings.
- Check contrast in Accessibility Inspector for new UI.

## Examples

### Card Button
```swift
VStack(alignment: .leading) {
    Text(title)
        .font(.cosmicHeadline)
    Text(detail)
        .font(.cosmicBody)
}
.accessibilityElement(children: .combine)
.accessibilityLabel("\(title). \(detail)")
.accessibilityHint("Double tap to view details")
.accessibilityAddTraits(.isButton)
```

### Icon Button
```swift
Button(action: close) {
    Image(systemName: "xmark")
}
.accessibleIconButton()
.accessibilityLabel("Close")
```

### Text Field
```swift
TextField("Name", text: $name)
    .accessibilityLabel("Partner name")
    .accessibilityHint("Enter the full name")
```

## Testing Checklist
- VoiceOver: verify labels, hints, and focus order.
- Dynamic Type: test XL and Accessibility XXXL.
- Touch targets: all tappable elements >= 44pt.
- Contrast: run Accessibility Inspector on key screens.
