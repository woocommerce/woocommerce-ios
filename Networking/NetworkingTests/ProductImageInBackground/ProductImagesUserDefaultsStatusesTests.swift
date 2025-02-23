import XCTest
import Combine
@testable import Networking

class ProductImagesUserDefaultsStatusesTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()
    private var userDefaults: UserDefaults!
    private let userDefaultsKey: String = "productImagesUserDefaultsStatusesTests"
    private var productImagesStatuses: ProductImagesUserDefaultsStatuses!

    private let siteID: Int64 = 1234
    private let productID: ProductOrVariationID = .product(id: 3456)
    private let productVariationID: ProductOrVariationID = .variation(productID: 7890, variationID: 4321)

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: userDefaultsKey)
        productImagesStatuses = ProductImagesUserDefaultsStatuses(userDefaults: userDefaults, key: userDefaultsKey)
    }

    override func tearDown() {
        userDefaults.removeObject(forKey: userDefaultsKey)
        super.tearDown()
    }

    // MARK: - Test Cases

    func test_init_with_empty_storage_should_have_empty_statuses() {
        XCTAssertTrue(productImagesStatuses.getAllStatuses().isEmpty)
    }

    func test_addStatus_should_persist_new_status() {
        // Given
        let status = ProductImageStatus.uploading(asset: .uiImage(image: .strokedCheckmark,
                                                                  filename: nil,
                                                                  altText: nil),
                                                  siteID: siteID,
                                                  productID: productID)

        // When
        productImagesStatuses.addStatus(status)

        // Then
        XCTAssertEqual(productImagesStatuses.getAllStatuses(), [status])
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
        productImagesStatuses.addStatus(status)
        XCTAssertEqual(productImagesStatuses.getAllStatuses().count, 1)

        // When
        productImagesStatuses.removeStatus(status)

        // Then
        XCTAssertTrue(productImagesStatuses.getAllStatuses().isEmpty)
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
            productImagesStatuses.statusesPublisher
                .sink {
                    receivedValues.append($0)
                    if receivedValues.count == 2 {
                        expectation.fulfill()
                    }
                }
                .store(in: &cancellables)

            // When
            productImagesStatuses.addStatus(status)
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
            cancellable = productImagesStatuses.statusesPublisher
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

        let savedStatuses = productImagesStatuses.getAllStatuses()
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
        productImagesStatuses.addStatus(oldStatus)

        // When
        productImagesStatuses.setAllStatuses([newStatus], for: siteID, productID: productID)

        // Then
        let allStatuses = productImagesStatuses.getAllStatuses()
        XCTAssertEqual(allStatuses.count, 1)
        XCTAssertEqual(allStatuses.first, newStatus)
    }

    func test_updateStatus_should_add_status_if_not_present() {
        // Given
        XCTAssertTrue(productImagesStatuses.getAllStatuses().isEmpty)

        // When
        let status = ProductImageStatus.uploading(asset: .uiImage(image: .strokedCheckmark,
                                                                  filename: nil,
                                                                  altText: nil),
                                                  siteID: siteID,
                                                  productID: productID)
        productImagesStatuses.updateStatus(status)

        // Then
        let statuses = productImagesStatuses.getAllStatuses()
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
        productImagesStatuses.addStatus(status)
        XCTAssertEqual(productImagesStatuses.getAllStatuses().count, 1)

        // When
        productImagesStatuses.updateStatus(status)

        // Then
        let statuses = productImagesStatuses.getAllStatuses()
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
        productImagesStatuses.addStatus(uploadingStatus)
        productImagesStatuses.addStatus(remoteStatus)
        XCTAssertEqual(productImagesStatuses.getAllStatuses().count, 2)

        // When
        productImagesStatuses.removeStatus { status in
            if case .uploading = status {
                return true
            }
            return false
        }

        // Then
        let statuses = productImagesStatuses.getAllStatuses()
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
        productImagesStatuses.addStatus(status1)
        productImagesStatuses.addStatus(status2)
        XCTAssertEqual(productImagesStatuses.getAllStatuses().count, 2)

        // When
        productImagesStatuses.clearAllStatuses()

        // Then
        XCTAssertTrue(productImagesStatuses.getAllStatuses().isEmpty)
    }

    func test_setAllStatuses_should_replace_all_statuses() {
        // Given
        let initialStatus = ProductImageStatus.uploading(asset: .uiImage(image: .strokedCheckmark,
                                                                         filename: nil,
                                                                         altText: nil),
                                                          siteID: siteID,
                                                          productID: productID)
        productImagesStatuses.addStatus(initialStatus)
        XCTAssertEqual(productImagesStatuses.getAllStatuses().count, 1)

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
        productImagesStatuses.setAllStatuses([newStatus1, newStatus2])

        // Then
        let statuses = productImagesStatuses.getAllStatuses()
        XCTAssertEqual(statuses.count, 2)
        XCTAssertTrue(statuses.contains(newStatus1))
        XCTAssertTrue(statuses.contains(newStatus2))
    }

    func test_errorsPublisher_should_emit_on_upload_failure() {
        // Given
        let expectation = self.expectation(description: "Error emission")
        var receivedError: (siteID: Int64, productOrVariationID: ProductOrVariationID?, assetType: ProductImageAssetType?, error: Error)?

        let failureStatus = ProductImageStatus.uploadFailure(
            asset: .uiImage(image: .strokedCheckmark, filename: "error", altText: "error"),
            error: NSError(domain: "TestDomain", code: 123),
            siteID: siteID,
            productID: productID
        )

        let cancellable = productImagesStatuses.errorsPublisher
            .sink { errorInfo in
                receivedError = errorInfo
                expectation.fulfill()
            }

        // When
        productImagesStatuses.addStatus(failureStatus)

        waitForExpectations(timeout: 1, handler: nil)
        cancellable.cancel()

        // Then
        XCTAssertNotNil(receivedError)
        if let errorInfo = receivedError {
            XCTAssertEqual(errorInfo.siteID, siteID)
            XCTAssertEqual(errorInfo.productOrVariationID, productID)
            if case .uiImage = errorInfo.assetType! {
                // Asset type is uiImage as expected
            } else {
                XCTFail("Asset type is not uiImage")
            }
            let nsError = errorInfo.error as NSError
            XCTAssertEqual(nsError.domain, "TestDomain")
            XCTAssertEqual(nsError.code, 123)
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
        productImagesStatuses.addStatus(uploadingStatus)
        productImagesStatuses.addStatus(remoteStatus)

        // When
        let foundStatus = productImagesStatuses.findStatus { status in
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
