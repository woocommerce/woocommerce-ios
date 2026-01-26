# POS Full-Text Search for Products and Variations

## Overview

Add full-text search (FTS) to the Point of Sale product search, replacing the current LIKE-based search. This enables searching for words in any order with relevance-based ranking, and extends search to include variations alongside products.

## Goals

- Search for words in any order (e.g., "blue shirt" matches "Shirt - Blue")
- Better ranking of matches using BM25 relevance scoring
- Search variations directly by their attributes, SKU, or barcode
- Display variations in search results with parent product context

## Non-Goals

- Searching description fields (excluded to keep index lean and results predictable)
- Fuzzy matching or typo tolerance

## Design

### FTS Table Schema

A unified FTS5 virtual table indexes both products and variations:

```sql
CREATE VIRTUAL TABLE pos_search_fts USING fts5(
    searchable_text,
    content='',
    contentless_delete=1
);
```

A mapping table links FTS results back to source records:

```swift
struct POSSearchIndex: Codable {
    let rowid: Int64
    let siteID: Int64
    let itemType: ItemType     // .simpleProduct, .variableProduct, .variation
    let itemID: Int64
    let parentProductID: Int64?

    enum ItemType: String, Codable {
        case simpleProduct
        case variableProduct
        case variation
    }
}
```

### Searchable Text Composition

| Item Type | Searchable Text |
|-----------|-----------------|
| Simple product | `"{name} {sku} {barcode}"` |
| Variable product | `"{name} {sku} {barcode}"` |
| Variation | `"{parentProductName} {attributeOptions} {sku} {barcode}"` |

Example variation: `"Coffee 500ml double shot VAR-123 012345678901"`

### Index Population & Maintenance

**Migration:** Creates FTS tables and populates from existing synced data. This ensures existing users have working FTS search immediately without requiring a sync.

**Full sync:** Rebuilds the entire FTS index for the site.

**Incremental sync:** Updates individual FTS entries when products/variations are added, updated, or deleted.

**Open item:** Ensure migration completes before POS search is available (verify during modal opening screen).

### Query Structure

Search uses FTS5 MATCH with BM25 ranking:

```swift
static func posUnifiedSearch(siteID: Int64, searchTerm: String) -> some Query {
    let ftsQuery = searchTerm
        .split(separator: " ")
        .map { "\($0)*" }  // Prefix matching
        .joined(separator: " ")

    """
    SELECT idx.itemType, idx.itemID, idx.parentProductID, bm25(pos_search_fts) as rank
    FROM pos_search_fts
    JOIN POSSearchIndex idx ON pos_search_fts.rowid = idx.rowid
    WHERE POSSearchIndex.siteID = ?
      AND pos_search_fts MATCH ?
    ORDER BY rank
    LIMIT ? OFFSET ?
    """
}
```

- Prefix matching (`*` suffix) enables search-as-you-type
- BM25 ranking favors results matching more terms with closer proximity
- Results are hydrated to full POSItem instances in a second step

### Search Result Types

New case added to `POSItem`:

```swift
public enum POSItem: Identifiable, Hashable {
    case simpleProduct(POSSimpleProduct)
    case variableParentProduct(POSVariableParentProduct)
    case variation(POSVariation)
    case searchResultVariation(POSVariation, parentProduct: POSVariableParentProduct)  // New
    case coupon(POSCoupon)
}
```

The `searchResultVariation` case carries the parent product so the UI can display both.

### UI Changes

**New `SearchResultVariationCardView`** for variations in search results:

- Title: Parent product name (e.g., "Coffee")
- Subtitle: Variation attributes (e.g., "500ml, double shot")
- Image: Variation image (fallback to parent if none)
- Price: Variation price

This matches the cart display pattern where variations show parent name as title and attributes as subtitle.

**Existing `VariationCardView`** remains unchanged for browsing variations under a parent product.

**`ItemListRow` update:**

```swift
case let .variation(variation):
    VariationCardView(variation: variation)

case let .searchResultVariation(variation, parentProduct):
    SearchResultVariationCardView(variation: variation, parentProduct: parentProduct)
```

### Tap Behavior

| Item Type | Action |
|-----------|--------|
| Simple product | Add to cart |
| Variable parent product | Open variation picker |
| Variation (browsing) | Add to cart |
| Variation (search result) | Add to cart |

### Integration Points

**`PointOfSaleLocalSearchPurchasableItemFetchStrategy`:** Replace LIKE query with FTS query. The `fetchVariations` method remains for browsing under a parent product.

**`POSCatalogPersistenceService`:** Add FTS index rebuild during full sync.

**`POSCatalogIncrementalSyncService`:** Add FTS entry updates during incremental sync.

## Files to Modify

- `Modules/Sources/Storage/GRDB/Model/` - Add FTS table and mapping table models
- `Modules/Sources/Storage/GRDB/Migrations/` - Add migration for FTS tables
- `Modules/Sources/Yosemite/PointOfSale/Items/PointOfSaleLocalSearchPurchasableItemFetchStrategy.swift` - Use FTS query
- `Modules/Sources/Yosemite/Tools/POS/POSCatalogPersistenceService.swift` - FTS index management
- `Modules/Sources/Yosemite/Model/PointOfSale/POSItem.swift` - Add `searchResultVariation` case
- `Modules/Sources/PointOfSale/Presentation/Item Selector/ItemList.swift` - Handle new case
- `Modules/Sources/PointOfSale/Presentation/Item Selector/` - Add `SearchResultVariationCardView`

## Open Items

- Verify migration completes before POS search is available (modal opening screen)
- Confirm incremental sync properly updates FTS entries (add/update/delete)
- Test BM25 ranking with real catalog data to ensure results feel right
