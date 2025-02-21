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
        let expectation = XCTestExpectation(description: "Should emit 2 values")
        var receivedValues: [[ProductImageStatus]] = []
        let status = ProductImageStatus.uploadFailure(
            asset: .uiImage(image: .strokedCheckmark, filename: "test", altText: "test"),
            error: NSError(domain: "test", code: 500),
            siteID: 1,
            productID: nil
        )

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

        // Then
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(receivedValues, [[], [status]])
    }

    func test_external_update_should_trigger_internal_update() {
        // Given
        let expectation = XCTestExpectation(description: "External change detection")
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
        
        let cancellable = productImagesStatuses.statusesPublisher
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
            
            // 3. Forza notifica su main thread
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: UserDefaults.didChangeNotification,
                    object: self.userDefaults
                )
            }
        } catch {
            XCTFail("Encoding failed: \(error)")
        }
        
        // Then
        wait(for: [expectation], timeout: 2)
        cancellable.cancel()
        
        
        let savedStatuses = productImagesStatuses.getAllStatuses()
        XCTAssertEqual(savedStatuses.count, 1)
        
        if case .remote(let image, let receivedSiteID, let receivedProductID) = savedStatuses.first! {
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
}
