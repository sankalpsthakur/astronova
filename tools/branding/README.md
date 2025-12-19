# Astronova branding assets

Source files:
- `tools/branding/astronova-icon.svg` — app icon concept (with background)
- `tools/branding/astronova-mark.svg` — transparent mark (for in-app use)
- `tools/branding/generate_astronova_assets.swift` — deterministic PNG generator used to refresh `AppIcon` + `BrandLogo`

Regenerate PNGs:
```bash
mkdir -p tools/branding/output/module-cache
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun swiftc -O -parse-as-library \
  -module-cache-path tools/branding/output/module-cache \
  -o tools/branding/output/generate_astronova_assets \
  tools/branding/generate_astronova_assets.swift
tools/branding/output/generate_astronova_assets tools/branding/output
```

