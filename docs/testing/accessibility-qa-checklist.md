# Accessibility QA Checklist - Astronova iOS

## Setup
- Enable VoiceOver (Settings -> Accessibility).
- Set Dynamic Type sizes: Default, XL, XXXL (Accessibility).
- Optional: Reduce Motion ON, Increase Contrast ON, Button Shapes ON.

## VoiceOver Core Flows
- Discover: read Today's Cosmic Weather, open a domain card.
- Oracle: open from Temple, navigate messages, send a prompt.
- Temple: open a pooja, book a time slot, confirm.
- Connect: add a connection, navigate relationship rows.

### Per-screen checks
- Every tappable element announces a clear label.
- Hints are provided for non-obvious actions.
- Section headers announce as headers.
- Decorative icons are not read.
- Focus order matches visual order.

## Dynamic Type
Test sizes: Default, XL, Accessibility XXXL.
- Text does not clip or overlap.
- Buttons remain tappable and readable.
- Cards and forms scroll when content grows.

## Touch Targets
- All buttons >= 44x44pt.
- Icon-only buttons use `.accessibleIconButton()`.
- Inline controls (e.g., chips) remain tappable.

## Contrast
- Run Accessibility Inspector on light and dark modes.
- Ensure text contrast >= 4.5:1 (normal) or 3:1 (large).

## Bug Reporting Template
- Screen / Flow:
- Steps to Reproduce:
- Expected:
- Actual:
- Accessibility Setting (VoiceOver/Dynamic Type/Contrast):
- Screenshot or Recording:
