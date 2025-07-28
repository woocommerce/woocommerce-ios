import Foundation
@testable import WooCommerce

final class MockPointOfSaleSoundPlayer: PointOfSaleSoundPlayerProtocol {
    var onPlaySound: ((PointOfSaleSound) -> Void)?

    func playSound(_ sound: PointOfSaleSound) {
        onPlaySound?(sound)
    }

    func playSound(_ sound: WooCommerce.PointOfSaleSound, completion: @escaping () -> Void) async {
        onPlaySound?(sound)
    }
}
