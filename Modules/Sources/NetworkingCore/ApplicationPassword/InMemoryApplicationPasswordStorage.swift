import Foundation

/// In-memory application password storage that does not persist to the Keychain.
/// Used for POS credential overrides where the cashier's ephemeral application password
/// should not overwrite the admin's stored credential.
final class InMemoryApplicationPasswordStorage: ApplicationPasswordStorageType {
    private(set) var applicationPassword: ApplicationPassword?

    func saveApplicationPassword(_ password: ApplicationPassword) {
        applicationPassword = password
    }

    func removeApplicationPassword() {
        applicationPassword = nil
    }
}
