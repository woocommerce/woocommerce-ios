import Foundation
@testable import PointOfSale

final class MockPointOfSaleSoundPlayer: PointOfSaleSoundPlayerProtocol {
    var onPlaySound: ((PointOfSaleSound) -> Void)?

    func playSound(_ sound: PointOfSaleSound) {
        onPlaySound?(sound)
    }

    func playSound(_ sound: PointOfSale.PointOfSaleSound, completion: @escaping () -> Void) async {
        onPlaySound?(sound)
    }
}
