import XCTest
import Yosemite

@testable import WooCommerce

final class RoleEligibilityUseCaseTests: XCTestCase {
    private var sessionManager: SessionManager!
    private var stores: MockStoresManager!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()

        sessionManager = .makeForTesting(authenticated: false)
        stores = MockStoresManager(sessionManager: sessionManager)
        defaults = UserDefaults(suiteName: Constants.suiteName)
        defaults.removePersistentDomain(forName: Constants.suiteName)
    }

    override func tearDown() {
        sessionManager.defaultStoreID = nil
        defaults.removePersistentDomain(forName: Constants.suiteName)
        stores = nil
        sessionManager = nil
        defaults = nil

        super.tearDown()
    }

    // MARK: syncEligibilityStatusIfNeeded

    func test_roleEligibilityUseCase_sync_returns_when_not_authenticated() {
        // Given
        let useCase = RoleEligibilityUseCase(stores: stores, defaults: defaults)

        // When
        useCase.syncEligibilityStatusIfNeeded()

        // Then
        XCTAssertEqual(stores.receivedActions.count, 0)
    }

    func test_roleEligibilityUseCase_sync_returns_when_authenticated_without_storeID() {
        // Given
        stores.authenticate(credentials: SessionSettings.credentials)
        sessionManager.defaultStoreID = nil
        let useCase = RoleEligibilityUseCase(stores: stores, defaults: defaults)

        // When
        useCase.syncEligibilityStatusIfNeeded()

        // Then
        XCTAssertEqual(stores.receivedActions.count, 0)
    }

    func test_roleEligibilityUseCase_sync_resets_errorInfo_when_user_is_eligible() {
        // Given
        defaults.setValue(Constants.sampleDictionary, forKey: .errorInfoKey)
        stores.authenticate(credentials: SessionSettings.credentials)
        stores.whenReceivingAction(ofType: UserAction.self) { action in
            guard case let .retrieveUser(_, completion) = action else {
                return
            }
            completion(.success(self.makeUser(eligible: true)))
        }
        sessionManager.defaultStoreID = 123
        let useCase = RoleEligibilityUseCase(stores: stores, defaults: defaults)

        // When
        useCase.syncEligibilityStatusIfNeeded()

        // Then
        XCTAssertEqual(stores.receivedActions.count, 1)
        XCTAssertNil(defaults.value(forKey: .errorInfoKey))
    }

    func test_roleEligibilityUseCase_sync_updates_errorInfo_when_user_is_ineligible() {
        // Given
        stores.authenticate(credentials: SessionSettings.credentials)
        stores.whenReceivingAction(ofType: UserAction.self) { action in
            guard case let .retrieveUser(_, completion) = action else {
                return
            }
            completion(.success(self.makeUser()))
        }
        sessionManager.defaultStoreID = 123
        let useCase = RoleEligibilityUseCase(stores: stores, defaults: defaults)

        // When
        useCase.syncEligibilityStatusIfNeeded()
        let errorInfo = useCase.lastEligibilityErrorInfo()

        // Then
        XCTAssertEqual(stores.receivedActions.count, 1)
        XCTAssertNotNil(errorInfo)
        XCTAssertEqual(errorInfo?.name, "first last")
        XCTAssertEqual(errorInfo?.roles, ["author", "editor"])
    }

    func test_roleEligibilityUseCase_sync_returns_when_unknown_error_encountered() {
        // Given
        defaults.setValue(Constants.sampleDictionary, forKey: .errorInfoKey)
        stores.authenticate(credentials: SessionSettings.credentials)
        stores.whenReceivingAction(ofType: UserAction.self) { action in
            guard case let .retrieveUser(_, completion) = action else {
                return
            }
            completion(.failure(SampleError.first)) // returns unknown error (for caller)
        }
        sessionManager.defaultStoreID = 123
        let useCase = RoleEligibilityUseCase(stores: stores, defaults: defaults)

        // When
        useCase.syncEligibilityStatusIfNeeded()
        let errorInfo = useCase.lastEligibilityErrorInfo()

        // Then
        XCTAssertEqual(stores.receivedActions.count, 1)
        // ensure that the existing errorInfo is kept as is.
        XCTAssertNotNil(errorInfo)
        XCTAssertEqual(errorInfo?.toDictionary(), Constants.sampleDictionary)
    }

    // MARK: checkEligibility

    func test_roleEligibilityUseCase_checkEligibility_returns_failure_when_not_authenticated() {
        // Given
        let useCase = RoleEligibilityUseCase(stores: stores, defaults: defaults)

        // When
        let result: Result<Void, RoleEligibilityError> = waitFor { promise in
            useCase.checkEligibility(for: 123) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        guard case RoleEligibilityError.notAuthenticated = result.failure! else {
            XCTFail()
            return
        }
    }

    func test_roleEligibilityUseCase_checkEligibility_returns_failure_when_storeID_isInvalid() {
        // Given
        stores.authenticate(credentials: SessionSettings.credentials)
        let useCase = RoleEligibilityUseCase(stores: stores, defaults: defaults)
        let storeID: Int64 = 0

        // When
        let result: Result<Void, RoleEligibilityError> = waitFor { promise in
            useCase.checkEligibility(for: storeID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        guard case let RoleEligibilityError.invalidStoreId(id) = result.failure! else {
            XCTFail()
            return
        }
        XCTAssertEqual(id, storeID)
    }

    func test_roleEligibilityUseCase_checkEligibility_returns_failure_when_receiving_unknown_errors() {
        // Given
        stores.authenticate(credentials: SessionSettings.credentials)
        stores.whenReceivingAction(ofType: UserAction.self) { action in
            guard case let .retrieveUser(_, completion) = action else {
                return
            }
            completion(.failure(SampleError.first)) // returns unknown error (for caller)
        }
        let useCase = RoleEligibilityUseCase(stores: stores, defaults: defaults)

        // When
        let result: Result<Void, RoleEligibilityError> = waitFor { promise in
            useCase.checkEligibility(for: 123) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        guard case let RoleEligibilityError.unknown(error) = result.failure! else {
            XCTFail()
            return
        }
        XCTAssertTrue(error is SampleError)
    }

    func test_roleEligibilityUseCase_checkEligibility_returns_insufficientRoleError_when_user_is_ineligible() {
        // Given
        let sampleUser = self.makeUser()
        stores.authenticate(credentials: SessionSettings.credentials)
        stores.whenReceivingAction(ofType: UserAction.self) { action in
            guard case let .retrieveUser(_, completion) = action else {
                return
            }
            completion(.success(sampleUser)) // returns unknown error (for caller)
        }
        let useCase = RoleEligibilityUseCase(stores: stores, defaults: defaults)

        // When
        let result: Result<Void, RoleEligibilityError> = waitFor { promise in
            useCase.checkEligibility(for: 123) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        guard case let RoleEligibilityError.insufficientRole(info) = result.failure! else {
            XCTFail()
            return
        }
        XCTAssertEqual(info.name, sampleUser.displayName())
        XCTAssertEqual(info.roles, sampleUser.roles)
    }

    func test_roleEligibilityUseCase_checkEligibility_returns_success_when_user_is_eligible() {
        // Given
        let sampleUser = self.makeUser(eligible: true)
        stores.authenticate(credentials: SessionSettings.credentials)
        stores.whenReceivingAction(ofType: UserAction.self) { action in
            guard case let .retrieveUser(_, completion) = action else {
                return
            }
            completion(.success(sampleUser)) // returns unknown error (for caller)
        }
        let useCase = RoleEligibilityUseCase(stores: stores, defaults: defaults)

        // When
        let result: Result<Void, RoleEligibilityError> = waitFor { promise in
            useCase.checkEligibility(for: 123) { error in
                promise(error)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    // MARK: lastEligibilityErrorInfo

    func test_roleEligibilityUseCase_lastEligibilityErrorInfo_returns_object_when_errorInfo_exists() {
        // Given
        defaults.setValue(Constants.sampleDictionary, forKey: .errorInfoKey)
        let useCase = RoleEligibilityUseCase(stores: stores, defaults: defaults)

        // When
        let errorInfo = useCase.lastEligibilityErrorInfo()

        // Then
        XCTAssertNotNil(errorInfo)
        XCTAssertEqual(errorInfo?.toDictionary(), Constants.sampleDictionary)
    }

    func test_roleEligibilityUseCase_lastEligibilityErrorInfo_returns_nil_when_errorInfo_notExist() {
        // Given
        let useCase = RoleEligibilityUseCase(stores: stores, defaults: defaults)

        // When
        let errorInfo = useCase.lastEligibilityErrorInfo()

        // Then
        XCTAssertNil(errorInfo)
    }

    // MARK: Reset

    func test_roleEligibilityUseCase_reset_correctly_deletes_stored_errorInfo() {
        // Given
        defaults.setValue(Constants.sampleDictionary, forKey: .errorInfoKey)
        let useCase = RoleEligibilityUseCase(stores: stores, defaults: defaults)

        // When
        useCase.reset()

        // Then
        XCTAssertNil(defaults.value(forKey: .errorInfoKey))
    }
}

private extension RoleEligibilityUseCaseTests {
    struct Constants {
        static let eligibleRoles = ["shop_manager", "editor"]
        static let ineligibleRoles = ["author", "editor"]
        static let sampleDictionary = ["name": "Jane", "roles": "shop_manager,editor"]
        static let suiteName = "RoleEligibilityUseCaseTests"
    }

    func makeUser(eligible: Bool = false) -> User {
        return User(localID: 0, siteID: 0, wpcomID: 0, email: "email", username: "username", firstName: "first", lastName: "last",
                    nickname: "nick", roles: eligible ? Constants.eligibleRoles : Constants.ineligibleRoles)
    }
}

private extension String {
    // Constants.eligibilityErrorInfoKey
    static let errorInfoKey = "wc_eligibility_error_info"
}
