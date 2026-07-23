import Foundation

/// Design-system animation durations, centralized so components animate consistently.
public enum StoreMotion {
    /// Press / state-change feedback on interactive controls.
    public static let pressDuration: TimeInterval = 0.15
    /// A selection indicator moving between options (e.g. a segmented-control pill).
    public static let selectionDuration: TimeInterval = 0.2
}
