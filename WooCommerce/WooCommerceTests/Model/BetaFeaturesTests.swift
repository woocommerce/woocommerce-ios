import XCTest
import Storage
@testable import WooCommerce

class BetaFeaturesTests: XCTestCase {
    var appSettings: GeneralAppSettingsStorage!

    override func setUpWithError() throws {
        appSettings = GeneralAppSettingsStorage.init(fileStorage: MockInMemoryStorage())
    }

    override func tearDownWithError() throws {
        appSettings = nil
    }

    func test_viewAddons_defaults_to_false() {
        let enabled = appSettings.betaFeatureEnabled(.viewAddOns)
        XCTAssertEqual(enabled, false)
    }

    func test_viewAddons_defaults_saves_value() throws {
        try appSettings.setBetaFeatureEnabled(.viewAddOns, enabled: true)
        let enabled = appSettings.betaFeatureEnabled(.viewAddOns)
        XCTAssertEqual(enabled, true)
    }

    func test_viewAddons_binding_reads_and_writes_value() {
        let enabledBinding = appSettings.betaFeatureEnabledBinding(.viewAddOns)
        XCTAssertEqual(enabledBinding.wrappedValue, false)
        enabledBinding.wrappedValue = true
        let enabled = appSettings.betaFeatureEnabled(.viewAddOns)
        XCTAssertEqual(enabled, true)
    }

    func test_productSKUScanner_defaults_to_false() {
        let enabled = appSettings.betaFeatureEnabled(.productSKUScanner)
        XCTAssertEqual(enabled, false)
    }

    func test_productSKUScanner_defaults_saves_value() throws {
        try appSettings.setBetaFeatureEnabled(.productSKUScanner, enabled: true)
        let enabled = appSettings.betaFeatureEnabled(.productSKUScanner)
        XCTAssertEqual(enabled, true)
    }

    func test_productSKUScanner_binding_reads_and_writes_value() {
        let enabledBinding = appSettings.betaFeatureEnabledBinding(.productSKUScanner)
        XCTAssertEqual(enabledBinding.wrappedValue, false)
        enabledBinding.wrappedValue = true
        let enabled = appSettings.betaFeatureEnabled(.productSKUScanner)
        XCTAssertEqual(enabled, true)
    }

    func test_couponManagement_defaults_to_false() {
        let enabled = appSettings.betaFeatureEnabled(.couponManagement)
        XCTAssertEqual(enabled, false)
    }

    func test_couponManagement_defaults_saves_value() throws {
        try appSettings.setBetaFeatureEnabled(.couponManagement, enabled: true)
        let enabled = appSettings.betaFeatureEnabled(.couponManagement)
        XCTAssertEqual(enabled, true)
    }

    func test_couponManagement_binding_reads_and_writes_value() {
        let enabledBinding = appSettings.betaFeatureEnabledBinding(.couponManagement)
        XCTAssertEqual(enabledBinding.wrappedValue, false)
        enabledBinding.wrappedValue = true
        let enabled = appSettings.betaFeatureEnabled(.couponManagement)
        XCTAssertEqual(enabled, true)
    }

}

private final class MockInMemoryStorage: FileStorage {
    private(set) var data: [URL: Codable] = [:]

    func data<T>(for fileURL: URL) throws -> T where T: Decodable {
        guard let data = data[fileURL] as? T else {
            throw Errors.readFailed
        }
        return data
    }

    func write<T>(_ data: T, to fileURL: URL) throws where T: Encodable {
        self.data[fileURL] = data as? Codable
    }

    func deleteFile(at fileURL: URL) throws {
        data.removeValue(forKey: fileURL)
    }

    enum Errors: Error {
        case readFailed
    }
}
