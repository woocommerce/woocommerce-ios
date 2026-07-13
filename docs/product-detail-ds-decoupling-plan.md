# Product Detail — DS decoupling / preparation plan

Preparation step for the RFC "Adopting the design system in the iOS app". Covers the
**Decoupling** step for the easier of the two coupled UIKit screens: **Product Detail**
(`ProductFormViewController`). Order Detail is the harder sibling and is out of scope here.

> Revised after a principal-engineer review. Amendments from that review are folded in and
> called out inline as **[review]**.

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
- The extracted seams are unit-tested; the currently-untested tap routing gains coverage.
- No SwiftUI view is built yet; the legacy renderer is the only consumer, proving the seam.

## What exists today

| Type | Role | View-agnostic? | Tested? |
|---|---|---|---|
| `ProductFormViewModelProtocol` (+ `ProductFormViewModel`, `ProductVariationFormViewModel`) | **Business logic**: product state, updates, save/delete/duplicate, `canX()` checks, observables | Yes | Yes (Observables/Save/Updates/Changes tests) |
| `DefaultProductFormTableViewModel` (`ProductFormTableViewModel` protocol) | Builds `[ProductFormSection]` from product + `actionsFactory` | Mostly — row VMs carry `UIImage`/`UIColor` | **Yes, heavily** (`DefaultProductFormTableViewModelTests`, ~915 LOC) |
| `ProductFormViewController<ViewModel>` | UIKit host: table, tap handling, rebuild/observation, ~35 nav methods, nav bar, more-options sheet, save/publish/preview, tooltip, image uploader | No | No (only an image-uploader test) |
| `ProductFormTableViewDataSource` | `UITableViewDataSource`: row → UIKit cell + inline action closures | No | No |

The RFC's "already has a sections/row model and an action-routing seam" is true for the
**sections model** (the shared, tested seam). The **action-routing seam is aspirational** — routing
is currently fused into the view controller.

## Couplings that block a SwiftUI renderer

1. **Tap/action routing fused in the VC.** `didSelectRowAt` (`ProductFormViewController.swift:445-616`)
   — ~170-line switch interleaving editability guards, analytics, and direct nav calls. More routing
   lives as inline DataSource closures (`updateDataSourceActions` `:949-974`; wired at
   `ProductFormTableViewDataSource.swift:32-35,178-186,276,320,369-374`) and in
   `moreDetailsButtonTapped` (`:990-1032`, its own 7-action routing table + analytics).
2. **Rebuild + observation fused in the VC** (`:814-985`) — six subscriptions plus three rebuild
   paths that draw from *different* sources: `onProductUpdated` rebuilds from the **emitted** product
   (`:879-886`), while `onImageStatusesUpdated`/`updateFormTableContent`/`reloadLinkedPromoCell`
   rebuild from **current** `viewModel.productModel` (`:910,920,871`).
3. **Row VMs carry UIKit types** — `icon: UIImage`, `tintColor: UIColor?`
   (`ProductFormTableViewModel.swift:57-61`); rows map to concrete UIKit cells.

**[review] Additional couplings the first draft under-weighted:**
4. **View-state drives whether to rebuild.** The "don't reload while typing" behavior depends on
   `view.window == nil` (`:834`) — a *view-layer* signal governing a *presentation-state* decision.
   This is the main threat to Step 2 (see below); it cannot simply "move into" a presenter.
5. **Lossy `Equatable`.** `ProductFormSection.SettingsRow.ViewModel.==` compares only
   `icon/title/details` and ignores `tintColor/isActionable/numberOfLinesForDetails/hideSeparator`
   (`ProductFormTableViewModel.swift:114-119`). Harmless today (VC always `reloadData()`), but a
   landmine if a section stream ever adds `.removeDuplicates()` — it would swallow real updates
   (e.g. a status toggle flipping only `isActionable`).
6. **Popover/cell anchors.** `editProductType(cell:)` presents from `sourceView: cell` (`:504,1684`)
   and the more-options sheet from a `barButtonItem` (`:424-425`). The anchor must be captured
   *semantically at tap time*; a handler cannot resolve a cell later, and SwiftUI has no cell.
7. **Dual analytics channels.** Routing mixes `eventLogger.log*Tapped()`
   (`ProductFormEventLoggerProtocol`) and `ServiceLocator.analytics.track(...)`, with per-case
   ordering that differs (guard-then-log vs log-unconditionally; `.externalURL` even has dead code
   `:547-548`). "Verbatim" means injecting **both** and preserving order per case.
8. **`HostingConfigurationTableViewCell` precedent** already exists (`HostingTableViewCell.swift:59`,
   used by Order Detail's `OrderDetailsDataSource` + Settings). See "Alternative" below.

## Plan — incremental, each step ships on `trunk`, flag stays off

### Step 0 — Backfill *section-output* characterization only  **[review: rescoped]**
- Audit/extend `DefaultProductFormTableViewModelTests` across representative configs (simple /
  variable / external / grouped / bundle / composite / subscription; editable vs readonly; private
  WPCom store; description-AI on).
- **Do not** pretend to characterize tap routing here — it is not testable through the nib-backed,
  ServiceLocator-saturated VC (`:107-127`) before extraction. Its coverage arrives *with* Step 1,
  written against the extracted handler and verified against the pre-extraction switch by review.

### Step 1 — Extract the action-routing seam (highest test value)
- Introduce a semantic action currency (intent) covering **only** the switchable surface: the
  ~row-tap cases, the DataSource inline closures, and the more-details sheet actions. Each intent
  **captures its anchor semantically at creation time** (for product-type popover / share).
- `ProductFormRowActionHandler`: given an intent, (a) applies the editability guard, (b) fires the
  moved-verbatim analytics via **both** injected `eventLogger` and `Analytics`, preserving per-case
  guard→log→navigate ordering, (c) calls `ProductFormNavigating` for the push/present.
- **`ProductFormNavigating` is scoped to the row-actionable + inline-closure + more-details set only**
  (~20 methods). **[review]** Nav-bar / action-sheet chrome (`displayProductSettings`,
  `duplicateProduct`, `deleteProduct`, `displayShareProduct`, `publishProduct`, `saveProductAsDraft`,
  `displayProductPreview`, the more-options sheet) **stays in the VC** — Step 3 keeps it there, so
  moving it behind the protocol is churn with no switchability payoff.
- Rewire `didSelectRowAt` → `sections[indexPath] → intent → handler.handle(intent)`; funnel the
  DataSource closures + more-details actions into the same handler.
- Tests: `MockAnalytics` + `MockEventLogger` + a spy `ProductFormNavigating`, asserting
  **guard→log→navigate ordering and the no-op-when-not-editable cases** — not merely "nav X fired".

#### Scope boundary — which nav methods go behind `ProductFormNavigating`
Only methods reachable **from the table content** (rows, inline cell closures, or the "Add more
details" bottom sheet) go on the protocol — because only those are what a SwiftUI content renderer
will call. Nav-bar buttons, the more-options action sheet, and save/publish/delete flows stay
owned by the VC (Step 3 keeps them there), so they are **not** added to the protocol, moved, or
routed through the handler. Rule: *reachable from content ⇒ on the protocol* (even if chrome also
calls it); *reachable only from chrome ⇒ stays on the VC*.

- **Behind `ProductFormNavigating`** (from `didSelectRowAt` `:445-616`, `updateDataSourceActions`
  `:949-974`, `moreDetailsButtonTapped` `:990-1032`): `editProductDescription`,
  `showProductDescriptionAI`, `displayBlaze`, `showProductImages`, `presentURL`(privacy),
  `editPriceSettings`, `showCustomFields`, `showReviews`, `showDownloadableFiles`,
  `editLinkedProducts`, `editProductType(cell:)`, `editShippingSettings`, `editInventorySettings`,
  `navigateToAddOns`, `editCategories`, `editTags`, `editShortDescription`, `editExternalLink`,
  `editSimplifiedInventory`, `editGroupedProducts`, `showVariations`, `editAttributes`,
  `showBundledProducts`, `showCompositeComponents`, `showSubscriptionFreeTrialSettings`,
  `showSubscriptionExpirySettings`, `showQuantityRules`, plus the closure targets
  `reloadLinkedPromoCell` / name-change / status-change / `displayImageUploadErrorAlert`.
- **Stays on the VC as chrome** (from nav bar `:1357+` / more-options sheet `:357-428` / save flow):
  `publishProduct`, `saveProductAsDraft`, `saveProduct`(`AndLogEvent`), `displayProductPreview`
  (via `saveDraftAndDisplayProductPreview`), `displayWebViewForProductInStore`, `displayShareProduct`,
  `displayProductSettings`, `duplicateProduct`, `displayDeleteProductAlert`/`deleteProduct`,
  `presentMoreOptionsActionSheet`, `displayProductSavingErrorAlert`, `displayError`/`displayErrorAlert`.

Method *bodies* for the protocol set still live on the VC (it implements `ProductFormNavigating`),
so chrome that also calls them keeps working with no duplication.

### Step 2 — Extract the section/observation presenter  **[review: reshaped — weakest part of v1]**
- Introduce a `@MainActor` `ProductFormContentPresenter` (generic over `ProductModel`) owning the
  `ViewModel` + `ProductImageActionHandler` + currency + AI flag, receiving upstream on main
  (`addUpdateObserver` `:171` and the VM publishers give no main guarantee).
- It hosts the subscriptions and **replicates each rebuild trigger explicitly** — preserving that
  `onProductUpdated` rebuilds from the emitted product while the others rebuild from current
  `productModel`. A single naïve `product → sections` pipeline collapses this distinction and is
  forbidden.
- **The typing-suppression decision stays view-owned.** A plain `@Published sections` cannot
  reproduce the `view.window == nil` gate (`:830-838`) without leaking window state into the
  presenter. So the presenter exposes **distinct signals** (e.g. `sectionsDidRebuild` vs
  `nameChangedOffscreen`) *or* takes an injected `isVisible`/`isEditing` provider, and the VC keeps
  the "reload only when not actively editing" call. Do **not** claim `$sections` preserves it
  transparently.
- **Forbid `.removeDuplicates()`** on the section stream until the lossy `Equatable`
  (`ProductFormTableViewModel.swift:114-119`) is fixed — otherwise real updates are dropped.
- Convention note: AGENTS.md prefers `@Observable` (Observation) for new VMs; `@Published`/
  `ObservableObject` here is a deliberate legacy bridge (Combine sinks for the VC, observable by a
  future SwiftUI view) — call the deviation out rather than let it read as endorsed.
- Test win: "given product state X ⇒ sections Y; re-emits on trigger Z; suppresses name-only while
  editing" becomes unit-testable without a `UIViewController`.

### Step 3 — Rendering seam + flag (no new UI)
- Add `FeatureFlag.productDetailDesignSystem` (default off) to `FeatureFlag.swift` +
  `DefaultFeatureFlagService.swift`.
- Extract the table setup into a legacy content renderer conforming to `ProductFormContentRendering`
  (inputs: the section signals + the `ProductFormRowActionHandler`). The VC keeps nav bar,
  more-options sheet, save/publish/preview/delete, keyboard avoidance, tooltip, image uploader.
- **Centralize the flag decision in one factory function** covering all four call sites
  (`ProductDetailsFactory.swift:51`, `ProductVariationDetailsFactory.swift:56`,
  `ProductVariationsViewController.swift:565`, `AddProductCoordinator.swift:273`) so it can't drift
  four ways. Note `ProductVariationsViewController` is both a call site and is pushed reentrantly
  from the VC's `showVariations()` (`:2085`).
- Exit: flag off ⇒ identical screen, now driven by the extracted presenter + handler.

### Step 4 — (Migration, out of scope) Build the SwiftUI DS view against the presenter's section
signals + `handler`, install under the flag. Listed only for continuity.

## PR breakdown — 2 PRs
The <300 non-test LOC Danger gate is intentionally waived for this work; PR-1 will be large and
needs a size waiver on review. The split is by "extract everything (behavior-preserving)" then
"make it switchable".

- **PR-1 — Decouple + test (no flag; legacy table stays the only renderer).**
  - `ProductFormNavigating` protocol + VC conformance (relocate the content-reachable method bodies).
  - Intent enum + `ProductFormRowActionHandler`; rewire `didSelectRowAt`, the DataSource inline
    closures, and the "Add more details" sheet through it.
  - `ProductFormContentPresenter` — move the six subscriptions + three rebuild paths out of the VC,
    keeping the `view.window`/typing-suppression decision view-owned; forbid `.removeDuplicates()`.
  - All new unit tests: handler guard→log→navigate ordering (`MockAnalytics`/`MockEventLogger`/nav
    spy) and presenter trigger→re-emit incl. name-only suppression.
  - Verification bar: flag does not exist yet; table renders exactly as today. This is the
    "prove nothing changed" PR — hence all tests land here.
- **PR-2 — Make it switchable (flag + seam + call sites).**
  - `ProductFormContentRendering` protocol; wrap the existing table as the legacy renderer.
  - `FeatureFlag.productDetailDesignSystem` (default off) in `FeatureFlag.swift` +
    `DefaultFeatureFlagService.swift`.
  - Centralize the flag decision in one factory across the 4 call sites.
  - Verification bar: flag off ⇒ identical screen, now driven through the seam. No SwiftUI view yet.

Escape hatch: if PR-1 review gets unwieldy, split the presenter back into its own PR (→ 3 PRs).
Every new test must exercise **both** `Product` and `ProductVariation` specializations.

## What stays untestable (accept it)  **[review]**
Nav method *bodies* (they build/push UIKit VCs — the spy only proves the right intent fired),
tooltip target-point math (`:738-755`), keyboard-avoidance constraints (`:709-724`), cell
self-sizing `beginUpdates/endUpdates` (`:1508-1509`). Out of scope; the screen does not become
broadly unit-testable — the *routing and section logic* do.

## Alternative weighed: per-cell SwiftUI hosting  **[review: must be justified]**
The app already hosts SwiftUI inside this exact `UITableView` pattern via
`HostingConfigurationTableViewCell`/`HostingTableViewCell` (Order Detail, Settings). A lower-risk
first increment: keep the entire UIKit host (`didSelectRowAt`, observations, rebuild) and swap only
*per-row cell rendering* to DS SwiftUI cells. This sidesteps the Step-2 presenter extraction and the
whole typing-suppression hazard for v1.

Trade-off (state honestly): it does **not** deliver the RFC's "screen renders via a SwiftUI DS view
that is not a UIViewController" and does not remove the UIKit host — so it is not container-level
switchable. **Decision:** this plan pursues the container-swap because the RFC's flag switches the
whole view (sectioned layout + cells) rendered in SwiftUI; per-cell hosting is retained as the
documented fallback / possible first increment if Step 2 proves too risky.

## Open decisions for implementation
1. Row value types: keep `ProductFormSection` (+ thin SwiftUI adapter for `UIImage`→`Image`,
   `UIColor`→`Color`) vs. introduce pure view-agnostic types now. RFC says "duplicate minimal"; DS
   icons are likely DS assets, so *some* mapping is unavoidable.
2. Intent granularity: dedicated `ProductFormRowAction` enum vs. reuse `PrimaryFieldRow`/`SettingsRow`
   as the action currency.
3. Navigation ownership: keep VC as `ProductFormNavigating` impl (surgical) vs. extract a Coordinator
   (matches convention, larger blast radius).
4. `isLinkedProductsPromoEnabled` lives on the concrete `ProductFormViewModel` (`:1082`), not the
   protocol — the generic presenter can't reach it cleanly; decide how the promo reload is triggered.
