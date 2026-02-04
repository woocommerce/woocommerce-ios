import SwiftUI

@propertyWrapper
struct DebugSetting<Value> {
    let key: String
    let value: Value
    let defaults: UserDefaults

    init(_ key: String, value: Value, defaults: UserDefaults = .standard) {
        self.key = key
        self.value = value
        self.defaults = defaults
    }

    var wrappedValue: Value? {
        get { defaults.object(forKey: key) as? Value }
        nonmutating set {
            if let newValue {
                defaults.set(newValue, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }
    }

    var projectedValue: Binding<Bool> {
        Binding(
            get: { self.wrappedValue != nil },
            set: { self.wrappedValue = $0 ? self.value : nil }
        )
    }
}

final class DebugSettings {
    static let shared = DebugSettings()

    @DebugSetting("debug.forcedMinimumWooCommerceVersion", value: "9999.9.9")
    var forcedMinimumWooCommerceVersion: String?
}
