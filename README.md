# Clutchkeep

Clutchkeep is a backyard yard book. A keeper logs each egg onto a named hen on the roost so the yard's yield, mash cost, and health score update. It is for small keepers who need a roost, not farm ERP.

## Who it is for

People with a handful of named birds who tap a nest to log an egg, then read eggs per Layer, cost per egg, and FCR — without typing a flock-size integer or a basket count.

## Architecture

**Roost-credit encoding.** Named `Hen` rows sit the roost. A nest tap writes one `Credit` on that hen. `qty` is the Credit count, never a flock-size field. The first Credit on a Pullet writes a `LayMark` and flips her role to Layer; later Credits never write another LayMark. Cull takes her off the roost today and out of tomorrow's Layer divisor. Mash lines hold kilograms and cost; `costPerUnit` is mash cost over qty and FCR is mash kilograms over qty, both empty when qty is 0. Dose notes hang on a hen; `healthScore` is clamp of 100 minus mortality times 140 minus min of 20 and notes.

This pattern fits the product because the persisted verb is credit-the-hen. Home is the roost, not a form. One `RoostStore` owns the fold. Views observe `RoostWatch` and never touch `UserDefaults`.

## Unique feature

**Pullet-then-layer.** Home is the roost of named hen tiles. A tap writes one Credit. The first Credit writes a LayMark and she becomes a Layer. Analytics counts LayMarks and Credits and shows eggs per Layer, cost versus yield, FCR, healthScore, and a seven-day predict folded from Credits. Cull drops her from tomorrow's divisor.

## Art

Style: 3D glass render with glassmorphism. Base prompt reused for every asset:

```
3D glass render with glassmorphism: studio-lit editorial still life of a backyard roost rail and nest cups in dune-cut light, frosted refraction, soft bloom, quiet uncluttered ground, isolated subjects, no text, no letters, no logo, no photoreal stock, no specified colours
```

Exact prompts:

**ckp_AppIcon** — A single 3D glass hen on a tiny roost rail, glassmorphism, subject centred filling the canvas edge to edge, no text, no letters, no words, no alpha, no transparency, no rounded corners, no drop shadow outside the canvas

**ckp_Splash** — A tall vertical 3D glass roost rail of nest cups, frosted glassmorphism, quiet uncluttered centre band for a wordmark, dune-cut studio light, no readable text

**ckp_Onboarding1** — 3D glass still life of a backyard roost with named hen nest cups, what the product is in one glance, isolated cutout, no text

**ckp_Onboarding2** — 3D glass mid-gesture: a finger tapping a nest cup on a hen so one glass egg credits, glassmorphism, isolated cutout, no text

**ckp_Onboarding3** — 3D glass roost after many credits: Layer hens wearing LayMark beads beside a Pullet still unmarked, accumulated yard, isolated cutout, no text

**ckp_EmptyHome** — An empty 3D glass roost rail with no hens seated, waiting to be filled, calm and inviting, never sad, isolated cutout, no text

**ckp_EmptyList** — An empty 3D glass nest cup with no Credits seated, hens exist but the nest is unused, calm, isolated cutout, no text

**ckp_CardBackdrop** — Abstract low-contrast 3D frosted glass roost slats and dune-cut bloom, quiet enough for text on top, filling the canvas, no letters

**ckp_ControlFace** — The face of a nest tap as a single physical control: a glass nest cup, 3D glass cutout, isolated, no text

**ckp_TwistHero** — 3D glass emblem of pullet-then-layer: an unmarked pullet nest beside a Layer nest wearing one LayMark bead, glassmorphism cutout, no text

**ckp_SuccessMark** — A small glass egg seated in a nest cup after a credit, 3D glass cutout, confirmation not fireworks, no letters

**ckp_HeaderDecor** — A wide low 3D glass band of roost rail and nest cups, frosted glassmorphism, low contrast, no readable text

## How this differs

HenTrack logs a flock-size integer and a daily egg count on a form. Clutchkeep has neither field: yield is a fold over Credits on named hens, and a Pullet cannot become a Layer without a LayMark. It is not a habit tracker with a chicken icon and not farm ERP. Mash and health stay inline on the Flock pager. There is no Nest mini-game, Scan, or Search tab.

## Build

```bash
cd Clutchkeep
xcodegen generate
xcodebuild -scheme Clutchkeep -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
xcrun simctl list devices available
xcodebuild -scheme Clutchkeep -destination 'platform=iOS Simulator,id=<UDID>' test
```

iOS 17, Swift 6.2, no Swift packages. Simulator seed `ckp.demo.v1` fills several named hens with a mix of Pullet and Layer, several Credits, Mash lines, and Dose notes, leaves credit-the-hen enabled, and marks onboarding complete. `-ReviewScreen today|log|goals` opens Flock, Analytics, and Settings after onboarding.
