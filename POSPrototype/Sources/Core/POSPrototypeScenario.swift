import SwiftUI

@MainActor
protocol POSPrototypeScenario: Identifiable {
    var id: String { get }
    var name: String { get }
    var description: String { get }
    var icon: String { get }

    func makeMockConfiguration() -> MockConfiguration
}
