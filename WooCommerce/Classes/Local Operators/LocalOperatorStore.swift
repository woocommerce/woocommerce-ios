import Foundation

final class LocalOperatorStore: LocalOperatorStoreProtocol {
    private let defaults: UserDefaults
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var settings: LocalOperatorSettings {
        get {
            guard let data: Data = defaults[.localOperatorSettings],
                  let decoded = try? decoder.decode(LocalOperatorSettings.self, from: data) else {
                return .default
            }
            return decoded
        }
        set {
            defaults[.localOperatorSettings] = try? encoder.encode(newValue)
        }
    }

    func loadProfiles() -> [LocalOperatorProfile] {
        guard let data: Data = defaults[.localOperatorProfiles],
              let decoded = try? decoder.decode([LocalOperatorProfile].self, from: data) else {
            return []
        }
        return decoded
    }

    func saveProfiles(_ profiles: [LocalOperatorProfile]) {
        defaults[.localOperatorProfiles] = try? encoder.encode(profiles)
    }
}

