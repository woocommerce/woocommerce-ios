import XCTest
import Yosemite
@testable import WooCommerce

@MainActor
final class StoreCreationProfilerUploadAnswersUseCaseTests: XCTestCase {
    func test_it_stores_answer_correctly() throws {
        // Given
        let siteID: Int64 = 123
        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let sut = StoreCreationProfilerUploadAnswersUseCase(siteID: siteID,
                                                            stores: stores,
                                                            userDefaults: userDefaults)

        let answer = StoreProfilerAnswers(sellingStatus: .alreadySellingOnline,
                                          sellingPlatforms: "wordpress",
                                          category: "health_and_beauty",
                                          countryCode: "US")

        // When
        sut.storeAnswers(answer)

        // Then
        let answers = try XCTUnwrap(userDefaults[.storeProfilerAnswers] as? [String: Data])
        let receivedData = try XCTUnwrap(answers["\(siteID)"])
        let receivedAnswer = try JSONDecoder().decode(StoreProfilerAnswers.self, from: receivedData)
        assertEqual(answer, receivedAnswer)
    }

    func test_it_uploads_answers_if_stored_answers_available() async throws {
        // Given
        let siteID: Int64 = 123
        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let sut = StoreCreationProfilerUploadAnswersUseCase(siteID: siteID,
                                                            stores: stores,
                                                            userDefaults: userDefaults)
        var uploadedAnswer: StoreProfilerAnswers?

        let answer = StoreProfilerAnswers(sellingStatus: .alreadySellingOnline,
                                          sellingPlatforms: "wordpress",
                                          category: "health_and_beauty",
                                          countryCode: "US")
        sut.storeAnswers(answer)

        // When

        stores.whenReceivingAction(ofType: SiteAction.self) { action in
            if case let .uploadStoreProfilerAnswers(_, answers, onCompletion) = action {
                onCompletion(.success(()))
                uploadedAnswer = answers
            }
        }
        await sut.uploadAnswers()

        // Then
        XCTAssertEqual(uploadedAnswer, answer)
    }

    func test_it_clears_stored_answers_if_upload_successful() async throws {
        // Given
        let siteID: Int64 = 123
        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let sut = StoreCreationProfilerUploadAnswersUseCase(siteID: siteID,
                                                            stores: stores,
                                                            userDefaults: userDefaults)

        let answer = StoreProfilerAnswers(sellingStatus: .alreadySellingOnline,
                                          sellingPlatforms: "wordpress",
                                          category: "health_and_beauty",
                                          countryCode: "US")
        sut.storeAnswers(answer)

        // When

        stores.whenReceivingAction(ofType: SiteAction.self) { action in
            if case let .uploadStoreProfilerAnswers(_, _, onCompletion) = action {
                onCompletion(.success(()))
            }
        }
        await sut.uploadAnswers()

        // Then
        let answers = try XCTUnwrap(userDefaults[.storeProfilerAnswers] as? [String: Data])
        XCTAssertNil(answers["\(siteID)"])
    }

    func test_it_does_not_upload_answers_if_stored_answers_not_available() async throws {
        // Given
        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let usecase = StoreCreationProfilerUploadAnswersUseCase(siteID: 123,
                                                                stores: stores,
                                                                userDefaults: userDefaults)
        var uploadedAnswer: StoreProfilerAnswers?

        let answer = StoreProfilerAnswers(sellingStatus: .alreadySellingOnline,
                                          sellingPlatforms: "wordpress",
                                          category: "health_and_beauty",
                                          countryCode: "US")
        usecase.storeAnswers(answer)

        // When
        stores.whenReceivingAction(ofType: SiteAction.self) { action in
            if case let .uploadStoreProfilerAnswers(_, answers, onCompletion) = action {
                onCompletion(.success(()))
                uploadedAnswer = answers
            }
        }

        let sut = StoreCreationProfilerUploadAnswersUseCase(siteID: 132, // Different site ID
                                                            stores: stores,
                                                            userDefaults: userDefaults)
        await sut.uploadAnswers()

        // Then
        XCTAssertNil(uploadedAnswer)
    }
}
