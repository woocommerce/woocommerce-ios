import Foundation
@testable import NetworkingCore

final class MockApplicationPasswordStorage: ApplicationPasswordStorageType {
    private(set) var applicationPassword: ApplicationPassword?

    func saveApplicationPassword(_ password: ApplicationPassword) {
        applicationPassword = password
    }

    func removeApplicationPassword() {
        applicationPassword = nil
    }
}
