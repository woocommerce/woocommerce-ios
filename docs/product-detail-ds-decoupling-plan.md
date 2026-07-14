# Product Detail — design system decoupling plan

Preparation step for the RFC "Adopting the design system in the iOS app". Covers the
**Decoupling** step for the easier of the two coupled UIKit screens: **Product Detail**
(`ProductFormViewController`). Order Detail is the harder sibling and is out of scope here.

## Objective

Bring Product Detail to a *switchable* state so the DS feature flag can decide, at the
container level, whether the screen renders via **today's `UITableView`** or via a **new
SwiftUI DS view** — both sharing the *same presentation state + business logic*. Flag off must
return today's UI unchanged. This plan covers only the behavior-preserving preparation; building
the SwiftUI DS view is the later "Migrate" step.

Success criteria for the preparation:
- Flag off ⇒ Product Detail is behaviorally identical to today.
- The presentation state (`[ProductFormSection]`) and the tap→navigation/analytics routing are
  consumable by a renderer that is **not** a `UIViewController`.
- The extracted seams are unit-tested; the previously untested tap routing gains coverage.
- No SwiftUI view is built as part of the preparation; the legacy renderer stays the only consumer.

## Starting point

| Type | Role | View-agnostic? | Tested? |
|---|---|---|---|
| `ProductFormViewModelProtocol` (+ `ProductFormViewModel`, `ProductVariationFormViewModel`) | **Business logic**: product state, updates, save/delete/duplicate, `canX()` checks, observables | Yes | Yes (Observables/Save/Updates/Changes tests) |
| `DefaultProductFormTableViewModel` (`ProductFormTableViewModel` protocol) | Builds `[ProductFormSection]` from product + `actionsFactory` | Mostly — row VMs carry `UIImage`/`UIColor` | Yes (`DefaultProductFormTableViewModelTests`, ~915 LOC) |
| `ProductFormViewController<ViewModel>` | UIKit host: table, tap handling, rebuild/observation, ~35 nav methods, nav bar, more-options sheet, save/publish/preview, tooltip, image uploader | No | No (only an image-uploader test) |
| `ProductFormTableViewDataSource` | `UITableViewDataSource`: row → UIKit cell + inline action closures | No | No |

The sections model was already the shared, tested seam. The action routing was fused into the
view controller and untested — that is what the preparation extracts.

## Couplings that block a SwiftUI renderer

1. **Tap/action routing fused in the VC.** `didSelectRowAt` — a ~170-line switch interleaving
   editability guards, analytics, and direct nav calls. More routing lives as inline DataSource
   closures (`updateDataSourceActions`) and in `moreDetailsButtonTapped` (its own 7-action routing
   table + analytics).
2. **Rebuild + observation fused in the VC** — six subscriptions plus three rebuild paths that draw
   from *different* sources: `onProductUpdated` rebuilds from the **emitted** product, while
   `onImageStatusesUpdated`/`updateFormTableContent`/`reloadLinkedPromoCell` rebuild from **current**
   `viewModel.productModel`.
3. **Row VMs carry UIKit types** — `icon: UIImage`, `tintColor: UIColor?`; rows map to concrete
   UIKit cells. A SwiftUI renderer can consume these via `Image(uiImage:)`/`Color(uiColor:)`; a
   token-mapping layer arrives with the DS view.
4. **View state drives whether to rebuild.** The "don't reload while typing" behavior depends on
   `view.window == nil` — a *view-layer* signal governing a *presentation-state* decision. It
   cannot simply move into a presenter; the decision must stay view-owned.
5. **Lossy `Equatable`.** `ProductFormSection.SettingsRow.ViewModel.==` compares only
   `icon/title/details` and ignores `tintColor/isActionable/numberOfLinesForDetails/hideSeparator`.
   Harmless while the VC always `reloadData()`s, but a landmine if a section stream ever adds
   `.removeDuplicates()` — real updates would be swallowed. Rule: no dedup until the `Equatable`
   is fixed.
6. **Popover/cell anchors.** `editProductType` presents from the tapped cell and the more-options
   sheet from a `barButtonItem`. Anchors must be captured at tap time; a SwiftUI renderer has no
   cell.
7. **Dual analytics channels.** Routing mixes `eventLogger.log*Tapped()` and
   `ServiceLocator.analytics.track(...)`, with per-case ordering that differs. Both channels must
   be preserved per case, in order.

## Plan — incremental, each step ships on `trunk`, flag stays off

### Step 1 — Extract the action-routing seam (PR-1, this branch)
- `ProductFormRowActionHandler` routes every content interaction: row selections (primary +
  settings), the "Add more details" sheet actions, and the inline cell actions (add image,
  description AI, linked-products promo, AI legal link). Guards → analytics (both channels,
  order preserved) → navigation.
- The handler consumes the existing `ProductFormSection` row enums directly — no parallel intent
  enum; both the legacy table and a future SwiftUI view speak `ProductFormSection`.
- `ProductFormNavigating` protocol carries the navigation; the VC implements it. Scope is limited
  to content-reachable navigation: nav-bar / more-options-sheet / save-publish-delete chrome stays
  on the VC (a DS content renderer never invokes those).
- Interactions that are *not* navigation stay VC-bound by design: name/status changes (view-model
  data mutations), linked-promo reload (table rebuild), failed-upload alert (error UI).
- Tests: exhaustive per-case unit coverage (every settings row, primary row, more-details action,
  and inline action) asserting guards, analytics, and guard→log→navigate ordering.

### Step 2 — Extract the section/observation presenter (PR-1b)
- A `@MainActor` `ProductFormContentPresenter` (generic over `ProductModel`) owning the
  subscriptions, replicating each rebuild trigger explicitly (preserving which product source each
  rebuild path reads from).
- The typing-suppression decision stays view-owned: the presenter exposes distinct signals (or
  takes an injected `isVisible`/`isEditing` provider) and the VC keeps the "reload only when not
  actively editing" call. A plain `@Published sections` cannot reproduce the `view.window == nil`
  gate without leaking view state.
- No `.removeDuplicates()` on the section stream (see coupling 5).
- Note: `@Published`/Combine here is a deliberate bridge for the legacy VC; the project's
  preference for `@Observable` applies to new view models, and the DS view can observe either.

### Step 3 — Rendering seam + flag
- `FeatureFlag.productDetailDesignSystem` (default off) in `FeatureFlag.swift` +
  `DefaultFeatureFlagService.swift`.
- Extract the table setup into a legacy content renderer conforming to a small
  `ProductFormContentRendering` protocol (inputs: the section signals + the handler). The VC keeps
  nav bar, more-options sheet, save/publish/preview/delete, keyboard avoidance, tooltip, image
  uploader.
- Centralize the flag decision in one factory covering all four call sites
  (`ProductDetailsFactory`, `ProductVariationDetailsFactory`, `ProductVariationsViewController`,
  `AddProductCoordinator`). Note `ProductVariationsViewController` is both a call site and is
  pushed reentrantly from the VC's `showVariations()`.

### Step 4 — Migrate (out of scope)
Build the SwiftUI DS view against the presenter's section signals + the handler, install under the
flag. A spike has confirmed a SwiftUI view can consume `ProductFormSection` +
`ProductFormRowActionHandler` + `ProductFormNavigating` without changes to the seam.

## PR breakdown
The <300 non-test LOC Danger gate is knowingly exceeded by PR-1; it needs a size waiver on review.

- **PR-1 — routing extraction + exhaustive tests** (this branch). Flag does not exist yet; the
  table renders exactly as today. After PR-1 the screen is **not yet switchable** — that arrives
  with Steps 2–3.
- **PR-1b — presenter extraction.**
- **PR-2 — flag + rendering seam + centralized factory.**

Every new test must exercise behavior valid for both `Product` and `ProductVariation`
specializations (the handler operates on `ProductFormSection` rows, which are shared).

## What stays untestable (accepted)
Navigation method *bodies* (they build/push UIKit view controllers — spies prove the right intent
fired, not that the destination is correct), tooltip target-point math, keyboard-avoidance
constraints, cell self-sizing `beginUpdates/endUpdates`. The *routing and section logic* become
unit-testable; the whole screen does not.

## Alternative considered: per-cell SwiftUI hosting
`HostingConfigurationTableViewCell`/`HostingTableViewCell` (used by Order Detail and Settings)
would allow swapping only per-row cell rendering to DS SwiftUI cells while keeping the entire UIKit
host. Lower risk, but it does not deliver the RFC's container-level switch (the whole sectioned
layout rendered in SwiftUI) and does not remove the UIKit host. This plan pursues the
container-swap; per-cell hosting remains the documented fallback if Step 2 proves too risky.

## Open decisions
1. Row value types: keep `ProductFormSection` (+ a thin SwiftUI adapter for `UIImage`→`Image`,
   `UIColor`→`Color`) vs. introduce pure view-agnostic types when the DS view lands. DS icons are
   likely DS assets, so some mapping is unavoidable.
2. Navigation ownership: the VC implements `ProductFormNavigating` today (surgical); extracting a
   Coordinator is a possible follow-up.
3. `isLinkedProductsPromoEnabled` lives on the concrete `ProductFormViewModel`, not the protocol —
   the presenter (generic over `ProductModel`) can't reach it cleanly; decide how the promo reload
   is triggered when Step 2 lands.
