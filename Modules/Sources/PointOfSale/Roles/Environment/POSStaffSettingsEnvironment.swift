import SwiftUI

struct POSStaffSettingsModeKey: EnvironmentKey {
    static let defaultValue: POSStaffSettingsMode? = nil
}

extension EnvironmentValues {
    var posStaffSettingsMode: POSStaffSettingsMode? {
        get { self[POSStaffSettingsModeKey.self] }
        set { self[POSStaffSettingsModeKey.self] = newValue }
    }
}
