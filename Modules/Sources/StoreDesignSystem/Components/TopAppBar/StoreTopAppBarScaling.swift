import SwiftUI

/// How a ``StoreTopAppBar`` responds to Dynamic Type: text scales up to ``maximumDynamicTypeSize``
/// and the bar grows with it, while the controls keep their fixed size, like a `UIBarButtonItem`,
/// and offer the Large Content Viewer instead.
enum StoreTopAppBarScaling {
    /// Text stops growing here; the title stays one line and truncates.
    static let maximumDynamicTypeSize: DynamicTypeSize = .accessibility2
}
