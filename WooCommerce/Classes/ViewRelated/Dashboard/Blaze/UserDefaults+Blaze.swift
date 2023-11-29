import Foundation

extension UserDefaults {

    /// Expose value for `hasDismissedBlazeSectionOnMyStore` to be observable through KVO.
    @objc var hasDismissedBlazeSectionOnMyStore: Bool {
        get {
            bool(forKey: Key.hasDismissedBlazeSectionOnMyStore.rawValue)
        }
        set {
            set(newValue, forKey: Key.hasDismissedBlazeSectionOnMyStore.rawValue)
        }
    }

    /// Checks if the Blaze section on My Store has been dismissed for a site.
    ///
    func hasDismissedBlazeSectionOnMyStore(for siteID: Int64) -> Bool {
        let hasDismissed = self[.hasDismissedBlazeSectionOnMyStore] as? [String: Bool]
        let idAsString = "\(siteID)"
        return hasDismissed?[idAsString] == true
    }

    /// Marks the Blaze section on My Store as **not** dismissed for a site.
    ///
    func restoreBlazeSectionOnMyStore(for siteID: Int64) {
        let idAsString = "\(siteID)"
        guard var hasDismissed = self[.hasDismissedBlazeSectionOnMyStore] as? [String: Bool] else {
            return
        }
        hasDismissed[idAsString] = false
        self[.hasDismissedBlazeSectionOnMyStore] = hasDismissed
    }

    /// Marks the Blaze section on My Store as dismissed for a site.
    ///
    func setDismissedBlazeSectionOnMyStore(for siteID: Int64) {
        let idAsString = "\(siteID)"
        if var hasDismissed = self[.hasDismissedBlazeSectionOnMyStore] as? [String: Bool] {
            hasDismissed[idAsString] = true
            self[.hasDismissedBlazeSectionOnMyStore] = hasDismissed
        } else {
            self[.hasDismissedBlazeSectionOnMyStore] = [idAsString: true]
        }
    }
}
