@testable import WooCommerce
import struct Yosemite.StoreProfilerAnswers

import Foundation

class MockStoreCreationProfilerUploadAnswersUseCase: StoreCreationProfilerUploadAnswersUseCaseProtocol {
    var storeAnswersCalled = false
    func storeAnswers(_ data: StoreProfilerAnswers) {
        storeAnswersCalled = true
    }

    var uploadAnswersCalled = false
    func uploadAnswers() async {
        uploadAnswersCalled = true
    }
}
