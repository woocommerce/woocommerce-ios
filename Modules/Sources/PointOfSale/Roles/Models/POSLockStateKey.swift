import Foundation

/// Shared UserDefaults key for POS lock state persistence.
/// Used by both permission providers, the tab coordinator, and the main tab bar controller.
public enum POSLockStateKey {
    public static let isLocked = "com.woocommerce.pos.isLocked"
}
