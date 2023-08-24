@testable import WooCommerce
import struct Yosemite.StoreProfilerAnswers

import Foundation

class MockStoreCreationProfilerUploadAnswersUseCase: StoreCreationProfilerUploadAnswersUseCaseProtocol {
    var storedAnswers: StoreProfilerAnswers?
    func storeAnswers(_ data: StoreProfilerAnswers) {
        storedAnswers = data
    }

    var uploadAnswersCalled = false
    func uploadAnswers() async {
        uploadAnswersCalled = true
    }
}
