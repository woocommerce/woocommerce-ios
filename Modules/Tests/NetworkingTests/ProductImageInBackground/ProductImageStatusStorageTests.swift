import XCTest
import Combine
@testable import Networking
@testable import NetworkingCore

class ProductImageStatusStorageTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()
    private var userDefaults: UserDefaults!
    private let userDefaultsKey: String = "productImageStatusStorageTests"
    private var storage: ProductImageStatusStorage!

    private let siteID: Int64 = 1234
    private let productID: ProductOrVariationID = .product(id: 3456)
    private let productVariationID: ProductOrVariationID = .variation(productID: 7890, variationID: 4321)

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: userDefaultsKey)
        storage = ProductImageStatusStorage(userDefaults: userDefaults, key: userDefaultsKey)
    }

    override func tearDown() {
        userDefaults.removeObject(forKey: userDefaultsKey)
        super.tearDown()
    }

    // MARK: - Test Cases

    func test_init_with_empty_storage_should_have_empty_statuses() {
        XCTAssertTrue(storage.getAllStatuses().isEmpty)
    }

    func test_addStatus_should_persist_new_status() {
        // Given
        let status = ProductImageStatus.uploading(asset: .uiImage(image: .strokedCheckmark,
                                                                  filename: nil,
                                                                  altText: nil),
                                                  siteID: siteID,
                                                  productID: productID)

        // When
        storage.addStatus(status)

        // Then
        XCTAssertEqual(storage.getAllStatuses(), [status])
    }

    func test_removeStatus_should_delete_existing_status() {
        // Given
        let status = ProductImageStatus.remote(image: ProductImage(imageID: 1,
                                                                   dateCreated: Date(),
                                                                   dateModified: nil,
                                                                   src: "",
                                                                   name: "",
                                                                   alt: ""),
                                               siteID: siteID,
                                               productID: productID)
        storage.addStatus(status)
        XCTAssertEqual(storage.getAllStatuses().count, 1)

        // When
        storage.removeStatus(status)

        // Then
        XCTAssertTrue(storage.getAllStatuses().isEmpty)
    }

    func test_publisher_should_emit_on_changes() {
        // Given
        var receivedValues: [[ProductImageStatus]] = []
        let status = ProductImageStatus.uploadFailure(
            asset: .uiImage(image: .strokedCheckmark, filename: "test", altText: "test"),
            error: NSError(domain: "test", code: 500),
            siteID: 1,
            productID: .product(id: 0)
        )

        waitForExpectation(description: "Should emit 2 values", timeout: 1) { expectation in
            storage.statusesPublisher
                .sink {
                    receivedValues.append($0)
                    if receivedValues.count == 2 {
                        expectation.fulfill()
                    }
                }
                .store(in: &cancellables)

            // When
            storage.addStatus(status)
        }

        // Then
        XCTAssertEqual(receivedValues, [[], [status]])
    }

    func test_external_update_should_trigger_internal_update() {
        // Given
        let testDate = Date(timeIntervalSince1970: 1740050950)

        let externalStatus = ProductImageStatus.remote(
            image: ProductImage(
                imageID: 99,
                dateCreated: testDate,
                dateModified: testDate,
                src: "",
                name: "test",
                alt: "test"
            ),
            siteID: siteID,
            productID: productVariationID)

        var receivedValues: [[ProductImageStatus]] = []
        var cancellable: AnyCancellable?

        waitForExpectation(description: "External change detection", timeout: 2) { expectation in
            cancellable = storage.statusesPublisher
                .sink {
                    receivedValues.append($0)
                    if $0.count == 1 {
                        expectation.fulfill()
                    }
                }

            // When
            do {
                let externalEncoder = JSONEncoder()
                externalEncoder.dateEncodingStrategy = .iso8601

                let externalData = try externalEncoder.encode([externalStatus])
                userDefaults.set(externalData, forKey: userDefaultsKey)

                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: UserDefaults.didChangeNotification,
                        object: self.userDefaults
                    )
                }
            } catch {
                XCTFail("Encoding failed: \(error)")
            }
        }

        cancellable?.cancel()

        let savedStatuses = storage.getAllStatuses()
        XCTAssertEqual(savedStatuses.count, 1)

        if let firstStatus = savedStatuses.first,
           case .remote(let image, let receivedSiteID, let receivedProductID) = firstStatus {
            XCTAssertEqual(Int(image.dateCreated.timeIntervalSince1970), 1740050950)
            XCTAssertEqual(receivedSiteID, siteID)
            XCTAssertEqual(receivedProductID, productVariationID)
        } else {
            XCTFail("Status type mismatch")
        }
    }

    func test_setAllStatuses_for_site_id_should_replace_correct_entries() {
        // Given
        let oldStatus = ProductImageStatus.remote(
            image: ProductImage(imageID: 1, dateCreated: Date(), dateModified: nil, src: "test2", name: "test", alt: "test"),
            siteID: siteID,
            productID: productID
        )
        let newStatus = ProductImageStatus.remote(
            image: ProductImage(imageID: 2, dateCreated: Date(), dateModified: nil, src: "test2", name: "test2", alt: "test2"),
            siteID: siteID,
            productID: productID
        )
        storage.addStatus(oldStatus)

        // When
        storage.appendStatuses([newStatus], for: siteID, productID: productID)

        // Then
        let allStatuses = storage.getAllStatuses()
        XCTAssertEqual(allStatuses.count, 1)
        XCTAssertEqual(allStatuses.first, newStatus)
    }

    func test_updateStatus_should_add_status_if_not_present() {
        // Given
        XCTAssertTrue(storage.getAllStatuses().isEmpty)

        // When
        let status = ProductImageStatus.uploading(asset: .uiImage(image: .strokedCheckmark,
                                                                  filename: nil,
                                                                  altText: nil),
                                                  siteID: siteID,
                                                  productID: productID)
        storage.updateStatus(status)

        // Then
        let statuses = storage.getAllStatuses()
        XCTAssertEqual(statuses.count, 1)
        XCTAssertEqual(statuses.first, status)
    }

    func test_updateStatus_should_update_existing_status() {
        // Given
        let status = ProductImageStatus.uploading(asset: .uiImage(image: .strokedCheckmark,
                                                                  filename: nil,
                                                                  altText: nil),
                                                  siteID: siteID,
                                                  productID: productID)
        storage.addStatus(status)
        XCTAssertEqual(storage.getAllStatuses().count, 1)

        // When
        storage.updateStatus(status)

        // Then
        let statuses = storage.getAllStatuses()
        XCTAssertEqual(statuses.count, 1)
        XCTAssertEqual(statuses.first, status)
    }

    func test_removeStatusWherePredicate_should_remove_matching_statuses() {
        // Given
        let uploadingStatus = ProductImageStatus.uploading(asset: .uiImage(image: .strokedCheckmark,
                                                                           filename: nil,
                                                                           altText: nil),
                                                            siteID: siteID,
                                                            productID: productID)
        let remoteStatus = ProductImageStatus.remote(image: ProductImage(imageID: 10,
                                                                         dateCreated: Date(),
                                                                         dateModified: nil,
                                                                         src: "source",
                                                                         name: "Image",
                                                                         alt: "Alt text"),
                                                     siteID: siteID,
                                                     productID: productID)
        storage.addStatus(uploadingStatus)
        storage.addStatus(remoteStatus)
        XCTAssertEqual(storage.getAllStatuses().count, 2)

        // When
        storage.removeStatus { status in
            if case .uploading = status {
                return true
            }
            return false
        }

        // Then
        let statuses = storage.getAllStatuses()
        XCTAssertEqual(statuses.count, 1)
        XCTAssertEqual(statuses.first, remoteStatus)
    }

    func test_clearAllStatuses_should_remove_all_statuses() {
        // Given
        let status1 = ProductImageStatus.uploading(asset: .uiImage(image: .strokedCheckmark,
                                                                   filename: nil,
                                                                   altText: nil),
                                                    siteID: siteID,
                                                    productID: productID)
        let status2 = ProductImageStatus.remote(image: ProductImage(imageID: 20,
                                                                    dateCreated: Date(),
                                                                    dateModified: nil,
                                                                    src: "src",
                                                                    name: "name",
                                                                    alt: "alt"),
                                                siteID: siteID,
                                                productID: productID)
        storage.addStatus(status1)
        storage.addStatus(status2)
        XCTAssertEqual(storage.getAllStatuses().count, 2)

        // When
        storage.clearAllStatuses()

        // Then
        XCTAssertTrue(storage.getAllStatuses().isEmpty)
    }

    func test_setAllStatuses_should_replace_all_statuses() {
        // Given
        let initialStatus = ProductImageStatus.uploading(asset: .uiImage(image: .strokedCheckmark,
                                                                         filename: nil,
                                                                         altText: nil),
                                                          siteID: siteID,
                                                          productID: productID)
        storage.addStatus(initialStatus)
        XCTAssertEqual(storage.getAllStatuses().count, 1)

        // When
        let newStatus1 = ProductImageStatus.remote(image: ProductImage(imageID: 30,
                                                                       dateCreated: Date(),
                                                                       dateModified: nil,
                                                                       src: "src1",
                                                                       name: "name1",
                                                                       alt: "alt1"),
                                                   siteID: siteID,
                                                   productID: productID)
        let newStatus2 = ProductImageStatus.uploadFailure(
            asset: .uiImage(image: .strokedCheckmark, filename: "file", altText: "alt"),
            error: NSError(domain: "error", code: 404),
            siteID: siteID,
            productID: productID
        )
        storage.setAllStatuses([newStatus1, newStatus2])

        // Then
        let statuses = storage.getAllStatuses()
        XCTAssertEqual(statuses.count, 2)
        XCTAssertTrue(statuses.contains(newStatus1))
        XCTAssertTrue(statuses.contains(newStatus2))
    }

    func test_errorsPublisher_should_emit_all_error_statuses() {
        // Given
        let expectation = self.expectation(description: "Error emission")
        var receivedErrorInfos: [(siteID: Int64, productOrVariationID: ProductOrVariationID?, assetType: ProductImageAssetType?, error: Error)] = []

        let failureStatus1 = ProductImageStatus.uploadFailure(asset: .uiImage(image: .strokedCheckmark, filename: "error1", altText: "error1"),
            error: NSError(domain: "TestDomain1", code: 123),
            siteID: siteID,
            productID: productID
        )

        let failureStatus2 = ProductImageStatus.uploadFailure(asset: .uiImage(image: .strokedCheckmark,
                                                                              filename: "error2",
                                                                              altText: "error2"),
            error: NSError(domain: "TestDomain2", code: 456),
            siteID: siteID,
            productID: productVariationID
        )

        storage.addStatus(failureStatus1)
        storage.addStatus(failureStatus2)

        storage.errorsPublisher
            .sink { errorInfos in
                receivedErrorInfos = errorInfos
                if receivedErrorInfos.count == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        waitForExpectations(timeout: 1, handler: nil)

        // Then
        XCTAssertEqual(receivedErrorInfos.count, 2)

        if let errorInfo1 = receivedErrorInfos.first(where: { info in
            let nsError = info.error as NSError
            return nsError.domain == "TestDomain1" && nsError.code == 123
        }) {
            XCTAssertEqual(errorInfo1.siteID, siteID)
            XCTAssertEqual(errorInfo1.productOrVariationID, productID)
            guard case .uiImage = errorInfo1.assetType else {
                XCTFail("Expected asset type to be .uiImage")
                return
            }
        } else {
            XCTFail("Did not receive failureStatus1 error info")
        }

        if let errorInfo2 = receivedErrorInfos.first(where: { info in
            let nsError = info.error as NSError
            return nsError.domain == "TestDomain2" && nsError.code == 456
        }) {
            XCTAssertEqual(errorInfo2.siteID, siteID)
            XCTAssertEqual(errorInfo2.productOrVariationID, productVariationID)
            guard case .uiImage = errorInfo2.assetType else {
                XCTFail("Expected asset type to be .uiImage")
                return
            }
        } else {
            XCTFail("Did not receive failureStatus2 error info")
        }
    }

    func test_findStatus_should_return_correct_status() {
        // Given
        let uploadingStatus = ProductImageStatus.uploading(asset: .uiImage(image: .strokedCheckmark,
                                                                           filename: nil,
                                                                           altText: nil),
                                                            siteID: siteID,
                                                            productID: productID)
        let remoteStatus = ProductImageStatus.remote(image: ProductImage(imageID: 50,
                                                                         dateCreated: Date(),
                                                                         dateModified: nil,
                                                                         src: "src",
                                                                         name: "Test Image",
                                                                         alt: "alt"),
                                                     siteID: siteID,
                                                     productID: productVariationID)
        storage.addStatus(uploadingStatus)
        storage.addStatus(remoteStatus)

        // When
        let foundStatus = storage.findStatus { status in
            if case .remote(_, _, let pID) = status, pID == productVariationID {
                return true
            }
            return false
        }

        // Then
        XCTAssertNotNil(foundStatus)
        if let found = foundStatus, case .remote(let image, let sID, let pID) = found {
            XCTAssertEqual(sID, siteID)
            XCTAssertEqual(pID, productVariationID)
            XCTAssertEqual(image.imageID, 50)
        } else {
            XCTFail("Expected remote status not found")
        }
    }
}
