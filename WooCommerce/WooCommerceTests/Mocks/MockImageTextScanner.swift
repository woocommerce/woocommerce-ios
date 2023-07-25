@testable import WooCommerce
import UIKit

final class MockImageTextScanner: ImageTextScannerProtocol {
    var result: Result<[String], Error>

    init(result: Result<[String], Error>) {
        self.result = result
    }

    func scanText(from image: UIImage) async throws -> [String] {
        switch result {
            case .success(let value):
                return value
            case .failure(let error):
                throw error
        }
    }
}
