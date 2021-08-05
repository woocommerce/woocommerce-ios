import XCTest
import Yosemite

@testable import WooCommerce

final class RoleEligibilityUseCaseTests: XCTestCase {
    private var sessionManager: SessionManager!
    private var stores: MockStoresManager!

    override func setUp() {
        super.setUp()

        sessionManager = .makeForTesting(authenticated: false)
        stores = MockStoresManager(sessionManager: sessionManager)
    }

    override func tearDown() {
        sessionManager.defaultStoreID = nil
        stores = nil
        sessionManager = nil

        super.tearDown()
    }

    // MARK: checkEligibility

    func test_roleEligibilityUseCase_checkEligibility_returns_failure_when_not_authenticated() {
        // Given
        let useCase = RoleEligibilityUseCase(stores: stores)

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
        let useCase = RoleEligibilityUseCase(stores: stores)
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
        let useCase = RoleEligibilityUseCase(stores: stores)

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
        let sampleUser = makeUser()
        stores.authenticate(credentials: SessionSettings.credentials)
        stores.whenReceivingAction(ofType: UserAction.self) { action in
            guard case let .retrieveUser(_, completion) = action else {
                return
            }
            completion(.success(sampleUser))
        }
        let useCase = RoleEligibilityUseCase(stores: stores)

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

    func test_roleEligibilityUseCase_checkEligibility_persists_errorInfo_when_insufficientRoleError_and_storeID_matches_defaultStoreID() {
        // Given
        let ineligibleUser = makeUser()
        let storeID: Int64 = 123
        var errorInfoSaved = false
        sessionManager.setStoreId(storeID)
        stores.authenticate(credentials: SessionSettings.credentials)
        stores.whenReceivingAction(ofType: UserAction.self) { action in
            guard case let .retrieveUser(_, completion) = action else {
                return
            }
            completion(.success(ineligibleUser))
        }
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            guard case let AppSettingsAction.setEligibilityErrorInfo(_, completion) = action else {
                return
            }
            errorInfoSaved = true
            completion(.success(()))
        }
        let useCase = RoleEligibilityUseCase(stores: stores)

        // When
        let result: Result<Void, RoleEligibilityError> = waitFor { promise in
            useCase.checkEligibility(for: storeID) { promise($0) }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertTrue(errorInfoSaved)
    }

    func test_roleEligibilityUseCase_checkEligibility_shouldNot_persist_errorInfo_when_storeID_doesNot_match_defaultStoreID() {
        // Given
        let ineligibleUser = makeUser()
        let storeID: Int64 = 123
        var errorInfoSaved = false
        sessionManager.setStoreId(storeID)
        stores.authenticate(credentials: SessionSettings.credentials)
        stores.whenReceivingAction(ofType: UserAction.self) { action in
            guard case let .retrieveUser(_, completion) = action else {
                return
            }
            completion(.success(ineligibleUser))
        }
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            guard case let AppSettingsAction.setEligibilityErrorInfo(_, completion) = action else {
                return
            }
            errorInfoSaved = true
            completion(.success(()))
        }
        let useCase = RoleEligibilityUseCase(stores: stores)

        // When
        let result: Result<Void, RoleEligibilityError> = waitFor { promise in
            // calling eligibility check with a different store ID!
            useCase.checkEligibility(for: 456) { promise($0) }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertFalse(errorInfoSaved)
    }

    func test_roleEligibilityUseCase_checkEligibility_returns_success_when_user_is_eligible() {
        // Given
        let eligibleUser = makeUser(eligible: true)
        var resetErrorInfoInvoked = false
        stores.authenticate(credentials: SessionSettings.credentials)
        stores.whenReceivingAction(ofType: UserAction.self) { action in
            guard case let .retrieveUser(_, completion) = action else {
                return
            }
            completion(.success(eligibleUser))
        }
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            guard case AppSettingsAction.resetEligibilityErrorInfo = action else {
                return
            }
            resetErrorInfoInvoked = true
        }
        let useCase = RoleEligibilityUseCase(stores: stores)

        // When
        let result: Result<Void, RoleEligibilityError> = waitFor { promise in
            useCase.checkEligibility(for: 123) { error in
                promise(error)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertTrue(resetErrorInfoInvoked)
    }

    func test_roleEligibilityUseCase_updates_roles_in_sessionManager() throws {
        // Given
        let eligibleUser = makeUser(eligible: true)
        stores.authenticate(credentials: SessionSettings.credentials)
        stores.whenReceivingAction(ofType: UserAction.self) { action in
            guard case let .retrieveUser(_, completion) = action else {
                return
            }
            completion(.success(eligibleUser))
        }
        let useCase = RoleEligibilityUseCase(stores: stores)

        // When
        _ = waitFor { promise in
            useCase.checkEligibility(for: 123) { result in
                promise(result)
            }
        }

        // Then
        assertEqual(stores.sessionManager.defaultRoles.map(\.rawValue), eligibleUser.roles)
    }
}

private extension RoleEligibilityUseCaseTests {
    struct Constants {
        static let eligibleRoles = ["shop_manager", "editor"]
        static let ineligibleRoles = ["author", "editor"]
    }

    func makeUser(eligible: Bool = false) -> User {
        return User(localID: 0, siteID: 0, wpcomID: 0, email: "email", username: "username", firstName: "first", lastName: "last",
                    nickname: "nick", roles: eligible ? Constants.eligibleRoles : Constants.ineligibleRoles)
    }
}
