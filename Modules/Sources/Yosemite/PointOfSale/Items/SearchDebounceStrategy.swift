import Foundation

/// Defines the debouncing behavior for search input
public enum SearchDebounceStrategy: Equatable {
    /// Smart debouncing: Skip debounce on first keystroke after a search completes, then debounce subsequent keystrokes.
    /// Optionally delays showing loading indicators until a threshold is exceeded.
    /// Optimized for slow network searches where the first keystroke should show loading immediately.
    /// - Parameters:
    ///   - duration: The debounce duration in nanoseconds for subsequent keystrokes
    ///   - loadingDelayThreshold: Optional threshold in nanoseconds before showing loading indicators. If nil, shows loading immediately.
    case smart(duration: UInt64 = 500 * NSEC_PER_MSEC, loadingDelayThreshold: UInt64? = nil)

    /// Simple debouncing: Always debounce every keystroke by the specified duration.
    /// Optionally delays showing loading indicators until a threshold is exceeded.
    /// Optimized for fast local searches to prevent excessive queries and loading flicker.
    /// - Parameters:
    ///   - duration: The debounce duration in nanoseconds
    ///   - loadingDelayThreshold: Optional threshold in nanoseconds before showing loading indicators. If nil, shows loading immediately.
    case simple(duration: UInt64, loadingDelayThreshold: UInt64? = nil)

    /// Immediate: No debouncing, execute search on every keystroke.
    /// Use when debouncing is not needed (e.g., non-search operations).
    case immediate
}
