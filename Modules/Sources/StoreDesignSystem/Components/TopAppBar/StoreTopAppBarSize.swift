import SwiftUI

/// The configuration of a ``StoreTopAppBar``.
///
/// - Note: A closed type — each size carries its own title and supporting-text typography, and the
///   bar branches on it for its row layout.
public enum StoreTopAppBarSize: Sendable {
    /// One row: navigation, text, and actions side by side. The default bar.
    case small
    /// Two rows: controls above, text below, for screens that lead with their title.
    case medium

    var titleStyle: StoreTextStyle {
        switch self {
        case .small: .titleLarge.emphasized
        case .medium: .headlineSmall.emphasized
        }
    }

    var supportingTextStyle: StoreTextStyle {
        switch self {
        case .small: .bodySmall.emphasized
        case .medium: .bodyMedium.emphasized
        }
    }
}

/// Where the text of a ``StoreTopAppBar`` sits horizontally.
public enum StoreTopAppBarTitleAlignment: Sendable {
    /// Text starts after the navigation control (or at the bar's inset when there is none).
    case leading
    /// Text is centered on the bar, clear of the navigation control and actions.
    case center

    var horizontalAlignment: HorizontalAlignment {
        switch self {
        case .leading: .leading
        case .center: .center
        }
    }

    var frameAlignment: Alignment {
        switch self {
        case .leading: .leading
        case .center: .center
        }
    }

    var textAlignment: TextAlignment {
        switch self {
        case .leading: .leading
        case .center: .center
        }
    }
}
