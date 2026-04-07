import Foundation

/// Persists prototype state across app launches for instant restoration after rebuild.
/// Saves to UserDefaults so state survives app termination.
enum PrototypeStateRestoration {
    private static let defaults = UserDefaults.standard

    private enum Keys {
        static let scenarioID = "prototype.scenarioID"
        static let readerStatus = "prototype.readerStatus"
        static let paymentEvent = "prototype.paymentEvent"
        static let controlMode = "prototype.controlMode"
        static let isAutoRestore = "prototype.autoRestore"
        static let controlPanelExpanded = "prototype.controlPanelExpanded"
        static let controlPanelTab = "prototype.controlPanelTab"
    }

    // MARK: - Auto-restore flag

    static var isAutoRestoreEnabled: Bool {
        get { defaults.bool(forKey: Keys.isAutoRestore) }
        set { defaults.set(newValue, forKey: Keys.isAutoRestore) }
    }

    // MARK: - Scenario

    static var savedScenarioID: String? {
        get { defaults.string(forKey: Keys.scenarioID) }
        set { defaults.set(newValue, forKey: Keys.scenarioID) }
    }

    // MARK: - Reader Status

    static var savedReaderStatus: String? {
        get { defaults.string(forKey: Keys.readerStatus) }
        set { defaults.set(newValue, forKey: Keys.readerStatus) }
    }

    // MARK: - Payment Event

    static var savedPaymentEvent: String? {
        get { defaults.string(forKey: Keys.paymentEvent) }
        set { defaults.set(newValue, forKey: Keys.paymentEvent) }
    }

    // MARK: - Control Mode

    static var savedControlMode: String? {
        get { defaults.string(forKey: Keys.controlMode) }
        set { defaults.set(newValue, forKey: Keys.controlMode) }
    }

    // MARK: - Control Panel UI State

    static var savedControlPanelExpanded: Bool {
        get { defaults.bool(forKey: Keys.controlPanelExpanded) }
        set { defaults.set(newValue, forKey: Keys.controlPanelExpanded) }
    }

    static var savedControlPanelTab: String? {
        get { defaults.string(forKey: Keys.controlPanelTab) }
        set { defaults.set(newValue, forKey: Keys.controlPanelTab) }
    }

    // MARK: - Clear

    static func clear() {
        defaults.removeObject(forKey: Keys.scenarioID)
        defaults.removeObject(forKey: Keys.readerStatus)
        defaults.removeObject(forKey: Keys.paymentEvent)
        defaults.removeObject(forKey: Keys.controlMode)
        defaults.removeObject(forKey: Keys.controlPanelExpanded)
        defaults.removeObject(forKey: Keys.controlPanelTab)
    }
}
