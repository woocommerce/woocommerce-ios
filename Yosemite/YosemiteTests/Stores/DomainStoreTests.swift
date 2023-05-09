import XCTest
import class WooFoundation.CurrencySettings
@testable import Networking
@testable import Yosemite

final class DomainStoreTests: XCTestCase {
    /// Mock Dispatcher.
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory.
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses.
    private var network: MockNetwork!

    private var remote: MockDomainRemote!
    private var paymentRemote: MockPaymentRemote!
    private var store: DomainStore!

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
        remote = MockDomainRemote()
        paymentRemote = MockPaymentRemote()
        store = DomainStore(dispatcher: dispatcher,
                            storageManager: storageManager,
                            network: network,
                            remote: remote,
                            paymentRemote: paymentRemote)
    }

    override func tearDown() {
        store = nil
        remote = nil
        paymentRemote = nil
        network = nil
        storageManager = nil
        dispatcher = nil
        super.tearDown()
    }

    // MARK: - `loadFreeDomainSuggestions`

    func test_loadFreeDomainSuggestions_returns_suggestions_on_success() throws {
        // Given
        remote.whenLoadingDomainSuggestions(thenReturn: .success([.init(name: "freedomaintesting", isFree: false)]))

        // When
        let result: Result<[FreeDomainSuggestion], Error> = waitFor { promise in
            let action = DomainAction.loadFreeDomainSuggestions(query: "domain") { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let suggestions = try XCTUnwrap(result.get())
        XCTAssertEqual(suggestions, [.init(name: "freedomaintesting", isFree: false)])
    }

    func test_loadFreeDomainSuggestions_returns_error_on_failure() throws {
        // Given
        remote.whenLoadingDomainSuggestions(thenReturn: .failure(NetworkError.timeout))

        // When
        let result: Result<[FreeDomainSuggestion], Error> = waitFor { promise in
            let action = DomainAction.loadFreeDomainSuggestions(query: "domain") { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, .timeout)
    }

    // MARK: - `loadPaidDomainSuggestions`

    func test_loadPaidDomainSuggestions_returns_suggestions_on_success() throws {
        // Given
        remote.whenLoadingPaidDomainSuggestions(thenReturn: .success([.init(name: "paid.domain", productID: 203, supportsPrivacy: true, isPremium: false)]))
        remote.whenLoadingDomainProducts(thenReturn: .success([.init(productID: 203, term: "year", cost: "NT$610.00", saleCost: "NT$154.00")]))

        // When
        let result = waitFor { promise in
            self.store.onAction(DomainAction.loadPaidDomainSuggestions(query: "domain", currencySettings: .init()) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let suggestions = try XCTUnwrap(result.get())
        XCTAssertEqual(suggestions, [
            .init(productID: 203,
                  supportsPrivacy: true,
                  name: "paid.domain",
                  term: "year",
                  cost: "NT$610.00",
                  saleCost: "NT$154.00",
                  isPremium: false)
        ])
    }

    func test_loadPaidDomainSuggestions_returns_empty_suggestions_from_failed_productID_mapping() throws {
        // Given
        remote.whenLoadingPaidDomainSuggestions(thenReturn: .success([.init(name: "paid.domain", productID: 203, supportsPrivacy: true, isPremium: false)]))
        // The product ID does not match the domain suggestion.
        remote.whenLoadingDomainProducts(thenReturn: .success([.init(productID: 156, term: "year", cost: "NT$610.00", saleCost: "NT$154.00")]))

        // When
        let result = waitFor { promise in
            self.store.onAction(DomainAction.loadPaidDomainSuggestions(query: "domain", currencySettings: .init()) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let suggestions = try XCTUnwrap(result.get())
        XCTAssertEqual(suggestions, [])
    }

    func test_loadPaidDomainSuggestions_returns_premium_domain_with_formatted_price_from_loadPremiumDomainPrice() throws {
        // Given
        let domainName = "premium.domain"
        remote.whenLoadingPaidDomainSuggestions(thenReturn: .success([
            .init(name: domainName, productID: 645, supportsPrivacy: true, isPremium: true)
        ]))
        remote.whenLoadingDomainProducts(thenReturn: .success([.init(productID: 645, term: "year", cost: "NT$610.00", saleCost: "NT$154.00")]))
        remote.whenLoadingPremiumDomainPrice(domain: domainName, thenReturn: .init(cost: 1000.5, saleCost: 6.8, currency: "TWD"))
        let currencySettings = CurrencySettings(currencyCode: .USD,
                                                currencyPosition: .leftSpace,
                                                thousandSeparator: ",",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 1)

        // When
        let result = waitFor { promise in
            self.store.onAction(DomainAction.loadPaidDomainSuggestions(query: "domain", currencySettings: currencySettings) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let suggestions = try XCTUnwrap(result.get())
        XCTAssertEqual(suggestions, [
            .init(productID: 645, supportsPrivacy: true, name: "premium.domain", term: "year", cost: "NT$ 1,000.5", saleCost: "NT$ 6.8", isPremium: true)
        ])
    }

    func test_loadPaidDomainSuggestions_skips_premium_domains_without_a_price() throws {
        // Given
        remote.whenLoadingPaidDomainSuggestions(thenReturn: .success([
            .init(name: "premium.domain", productID: 645, supportsPrivacy: true, isPremium: true),
            .init(name: "not.premium.domain", productID: 645, supportsPrivacy: true, isPremium: false)
        ]))
        remote.whenLoadingDomainProducts(thenReturn: .success([.init(productID: 645, term: "year", cost: "NT$610.00", saleCost: "NT$154.00")]))

        // When
        let result = waitFor { promise in
            self.store.onAction(DomainAction.loadPaidDomainSuggestions(query: "domain", currencySettings: .init()) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let suggestions = try XCTUnwrap(result.get())
        XCTAssertEqual(suggestions, [
            .init(productID: 645, supportsPrivacy: true, name: "not.premium.domain", term: "year", cost: "NT$610.00", saleCost: "NT$154.00", isPremium: false)
        ])
    }

    func test_loadPaidDomainSuggestions_returns_error_on_failure() throws {
        // Given
        remote.whenLoadingPaidDomainSuggestions(thenReturn: .failure(NetworkError.invalidURL))
        remote.whenLoadingDomainProducts(thenReturn: .failure(NetworkError.timeout))

        // When
        let result = waitFor { promise in
            self.store.onAction(DomainAction.loadPaidDomainSuggestions(query: "domain", currencySettings: .init()) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let error = try XCTUnwrap(result.failure)
        // The error of `loadDomainProducts` is returned since it is the first async call.
        XCTAssertEqual(error as? NetworkError, .timeout)
    }


    // MARK: - `loadDomains`

    func test_loadDomains_returns_domains_on_success() throws {
        // Given
        remote.whenLoadingDomains(thenReturn: .success([
            .init(name: "candy.land", isPrimary: true, isWPCOMStagingDomain: true, type: .wpcom, renewalDate: .distantFuture),
            .init(name: "pods.pro", isPrimary: true, isWPCOMStagingDomain: false, type: .mapping)
        ]))

        // When
        let result: Result<[SiteDomain], Error> = waitFor { promise in
            self.store.onAction(DomainAction.loadDomains(siteID: 606) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let suggestions = try XCTUnwrap(result.get())
        XCTAssertEqual(suggestions, [
            .init(name: "candy.land", isPrimary: true, isWPCOMStagingDomain: true, type: .wpcom, renewalDate: .distantFuture),
            .init(name: "pods.pro", isPrimary: true, isWPCOMStagingDomain: false, type: .mapping)
        ])
    }

    func test_loadDomains_returns_error_on_failure() throws {
        // Given
        remote.whenLoadingDomains(thenReturn: .failure(NetworkError.timeout))

        // When
        let result: Result<[SiteDomain], Error> = waitFor { promise in
            self.store.onAction(DomainAction.loadDomains(siteID: 606) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, .timeout)
    }

    // MARK: - `createDomainShoppingCart`

    func test_createDomainShoppingCart_returns_response_on_success() throws {
        // Given
        paymentRemote.whenCreatingDomainCart(thenReturn: .success([:]))

        // When
        let result = waitFor { promise in
            self.store.onAction(DomainAction.createDomainShoppingCart(siteID: 606,
                                                                      domain: .init(name: "",
                                                                                    productID: 1,
                                                                                    supportsPrivacy: true)) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func test_createDomainShoppingCart_returns_error_on_failure() throws {
        // Given
        paymentRemote.whenCreatingDomainCart(thenReturn: .failure(NetworkError.timeout))

        // When
        let result = waitFor { promise in
            self.store.onAction(DomainAction.createDomainShoppingCart(siteID: 606,
                                                                      domain: .init(name: "",
                                                                                    productID: 1,
                                                                                    supportsPrivacy: true)) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, .timeout)
    }

    // MARK: - `redeemDomainCredit`

    func test_redeemDomainCredit_returns_response_on_success() throws {
        // Given
        paymentRemote.whenCreatingDomainCart(thenReturn: .success([:]))
        paymentRemote.whenCheckingOutCartWithDomainCredit(thenReturn: .success(()))

        // When
        let result = waitFor { promise in
            self.store.onAction(DomainAction.redeemDomainCredit(siteID: 606, domain: .init(name: "",
                                                                                           productID: 1,
                                                                                           supportsPrivacy: true),
                                                                contactInfo: .fake()) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func test_redeemDomainCredit_returns_createCart_error_on_failure() throws {
        // Given
        paymentRemote.whenCreatingDomainCart(thenReturn: .failure(NetworkError.timeout))

        // When
        let result = waitFor { promise in
            self.store.onAction(DomainAction.redeemDomainCredit(siteID: 606, domain: .init(name: "",
                                                                                           productID: 1,
                                                                                           supportsPrivacy: true),
                                                                contactInfo: .fake()) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, .timeout)
    }

    func test_redeemDomainCredit_returns_checkoutCartWithDomainCredit_error_on_failure() throws {
        // Given
        paymentRemote.whenCreatingDomainCart(thenReturn: .success([:]))
        paymentRemote.whenCheckingOutCartWithDomainCredit(thenReturn: .failure(NetworkError.notFound))

        // When
        let result = waitFor { promise in
            self.store.onAction(DomainAction.redeemDomainCredit(siteID: 606, domain: .init(name: "",
                                                                                           productID: 1,
                                                                                           supportsPrivacy: true),
                                                                contactInfo: .fake()) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, .notFound)
    }

    // MARK: - `loadDomainContactInfo`

    func test_loadDomainContactInfo_returns_contact_info_on_success() throws {
        // Given
        let contactInfo = DomainContactInfo(firstName: "woo",
                                            lastName: "Merch",
                                            organization: "Woo",
                                            address1: "No 300",
                                            address2: nil,
                                            postcode: "18888",
                                            city: "SF",
                                            state: "CA",
                                            countryCode: "US",
                                            phone: "181800",
                                            email: "woo@merch.com")
        remote.whenLoadingDomainContactInfo(thenReturn: .success(contactInfo))

        // When
        let result = waitFor { promise in
            self.store.onAction(DomainAction.loadDomainContactInfo { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let returnedContactInfo = try XCTUnwrap(result.get())
        XCTAssertEqual(returnedContactInfo, contactInfo)
    }

    func test_loadDomainContactInfo_returns_error_on_failure() throws {
        // Given
        remote.whenLoadingDomainContactInfo(thenReturn: .failure(NetworkError.timeout))

        // When
        let result = waitFor { promise in
            self.store.onAction(DomainAction.loadDomainContactInfo { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, .timeout)
    }

    // MARK: - `validateDomainContactInfo`

    func test_validateDomainContactInfo_returns_on_success() throws {
        // Given
        remote.whenValidatingDomainContactInfo(thenReturn: .success(()))

        // When
        let result = waitFor { promise in
            self.store.onAction(DomainAction.validate(domainContactInfo: .fake(), domain: "") { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func test_validateDomainContactInfo_returns_error_on_failure() throws {
        // Given
        remote.whenValidatingDomainContactInfo(thenReturn: .failure(NetworkError.timeout))

        // When
        let result = waitFor { promise in
            self.store.onAction(DomainAction.validate(domainContactInfo: .fake(), domain: "") { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, .timeout)
    }
}
