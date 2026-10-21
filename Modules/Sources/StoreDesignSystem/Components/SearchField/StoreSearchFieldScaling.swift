import SwiftUI

/// How a ``StoreSearchField`` responds to Dynamic Type: text and glyphs scale together up to
/// ``maximumDynamicTypeSize`` and the field grows with them, the cap ``StoreTopAppBar`` uses, so
/// the two components stop growing at the same point.
enum StoreSearchFieldScaling {
    static let maximumDynamicTypeSize: DynamicTypeSize = .accessibility2
}
