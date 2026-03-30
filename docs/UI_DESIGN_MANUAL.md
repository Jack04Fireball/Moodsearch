# StyleMatch - UI_Design Moodboard Manual

Source board: https://de.pinterest.com/jeremiaflammer/ui_design/
Analysis date: 2026-03-30

## 1) Visual analysis (board-driven)
- Sample size: 31 pin images (public board thumbnails/original references).
- Average luminance: 121.41 (mid-tone overall, not pure dark-only).
- Average saturation: 0.226 (desaturated, restrained chroma).
- High-chroma red accent ratio: 2.63% (rare accent, not base color).
- Dominant colors:
  - #000000 (22.63%)
  - #e0e0e0 (16.46%)
  - #c0c0c0 (7.31%)
  - #a0a0a0 (5.42%)
  - #202020 / #404040 (dark neutral stack)
  - subtle cool/deep accents: #202040, #406060, #200000

Interpretation:
- The board language is editorial-tech: mostly monochrome, high contrast, sparse accent use.
- Typography and composition carry identity more than color.
- Visual hierarchy is created via scale, spacing, and weight shifts, not decorative UI chrome.

## 2) Typography system
Primary body font:
- Unica 77 (`Unica77LL-Regular`)

Display/accent font:
- Helvetica LT Bold 2 (`HelveticaLT-Bold2`)

Rules:
- H1/H2/H3 and action emphasis use HelveticaLT-Bold2.
- Body, captions, metadata, and controls use Unica77.
- Avoid mixed decorative effects; use strict weight contrast (Bold vs Regular).
- Keep line-height compact for headlines and moderate for body copy.

Recommended scale (iPhone):
- H1 app header: 72-88
- H1 poster: 100-120
- H2 section: 22-30
- H3 labels: 18-22
- Body: 15-17
- Meta/caption: 11-13

## 3) Color strategy
Base:
- Background: #000000
- Surface: #0A0A0A
- Surface alt: #121212

Text hierarchy:
- Primary: #F0F0F0
- Secondary: #C2C2C6
- Tertiary: #94949A

Accent (use sparingly):
- Cool metallic gradient (light steel -> slate)
- Accent should mark state and direction, never fill whole UI.

## 4) Decoration and framing
- Keep blocks transparent/near-transparent where possible.
- Replace soft rounded cards with sharp-edged editorial frames.
- Use non-continuous/dashed white contours to separate layers from background.
- Noise texture remains subtle, as atmospheric grain, never overpowering content.

## 5) Layout principles
- Primary differentiation by typography and composition.
- Product cards keep existing image composition (hero + stacked previews).
- Right-side metadata column stays compact.
- Header tab row acts like a magazine strapline: clear, minimal, equal rhythm.

## 6) Interaction and animation
- Swipe interactions remain direct and physical:
  - left swipe -> archive
  - right swipe -> like
- On-state icons switch to high-contrast white.
- Keep animation short and spring-based for card return.
- Avoid ornamental transitions; motion is functional.

## 7) Imagery handling
- Placeholder mode: grayscale blocks only.
- No unnecessary ornamental borders around placeholder images.
- Product readability first: image composition must stay clear.

## 8) Implementation mapping (current update)
- iOS font assets embedded in app target:
  - `StyleMatch/Fonts/Unica77LL.otf`
  - `StyleMatch/Fonts/HelveticaLT-Bold2.otf`
- `Info.plist` updated with `UIAppFonts` and dark mode (`UIUserInterfaceStyle = Dark`).
- App typography shifted to:
  - headlines/actions = HelveticaLT-Bold2
  - body/meta = Unica77
- Card framing updated toward sharp, segmented/dashed border language.
- Theme adjusted to monochrome + cool accent gradient aligned to board analysis.

## 9) Next pass (optional)
- Replace remaining system-font fallback paths with strict custom-font calls once all screens are verified on device.
- Move typography tokens into a dedicated shared file to avoid drift.
- Add snapshot tests for active icon states and top header typography to lock visual consistency.
