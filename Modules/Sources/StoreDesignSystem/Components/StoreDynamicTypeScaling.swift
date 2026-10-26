import SwiftUI

/// Dynamic Type limits shared by the module's chrome components.
enum StoreDynamicTypeScaling {
    /// Where bars and fields stop growing (``StoreTopAppBar``, ``StoreSearchField``), so they
    /// stay in step on one screen. Content below them keeps scaling.
    static let chromeMaximum: DynamicTypeSize = .accessibility2
}
