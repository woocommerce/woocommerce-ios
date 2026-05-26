import Testing
@testable import WooCommerce
import Yosemite

struct CIABOrderStatusMapperTests {

    // MARK: - displayName

    @Test("displayName maps pending to Open")
    func test_displayName_when_pending_then_returns_open() {
        #expect(CIABOrderStatusMapper.displayName(for: .pending) == "Open")
    }

    @Test("displayName maps processing to Open")
    func test_displayName_when_processing_then_returns_open() {
        #expect(CIABOrderStatusMapper.displayName(for: .processing) == "Open")
    }

    @Test("displayName maps onHold to Open")
    func test_displayName_when_onHold_then_returns_open() {
        #expect(CIABOrderStatusMapper.displayName(for: .onHold) == "Open")
    }

    @Test("displayName maps failed to Open")
    func test_displayName_when_failed_then_returns_open() {
        #expect(CIABOrderStatusMapper.displayName(for: .failed) == "Open")
    }

    @Test("displayName preserves completed")
    func test_displayName_when_completed_then_returns_localized_name() {
        #expect(CIABOrderStatusMapper.displayName(for: .completed) == OrderStatusEnum.completed.localizedName)
    }

    @Test("displayName preserves cancelled")
    func test_displayName_when_cancelled_then_returns_localized_name() {
        #expect(CIABOrderStatusMapper.displayName(for: .cancelled) == OrderStatusEnum.cancelled.localizedName)
    }

    @Test("displayName preserves refunded")
    func test_displayName_when_refunded_then_returns_localized_name() {
        #expect(CIABOrderStatusMapper.displayName(for: .refunded) == OrderStatusEnum.refunded.localizedName)
    }

    // MARK: - displayStatus

    @Test("displayStatus maps open statuses to custom open")
    func test_displayStatus_when_open_status_then_returns_custom_open() {
        let openStatuses: [OrderStatusEnum] = [.pending, .processing, .onHold, .failed]
        for status in openStatuses {
            #expect(CIABOrderStatusMapper.displayStatus(for: status) == .custom(CIABOrderStatusMapper.openSlug))
        }
    }

    @Test("displayStatus preserves non-open statuses")
    func test_displayStatus_when_non_open_status_then_returns_unchanged() {
        let nonOpenStatuses: [OrderStatusEnum] = [.completed, .cancelled, .refunded]
        for status in nonOpenStatuses {
            #expect(CIABOrderStatusMapper.displayStatus(for: status) == status)
        }
    }

    // MARK: - mapFilterOptions

    @Test("mapFilterOptions groups open statuses into single Open entry")
    func test_mapFilterOptions_when_all_statuses_then_groups_open() {
        // Given
        let statuses: [OrderStatus] = [
            OrderStatus(name: "Pending Payment", siteID: 1, slug: "pending", total: 3),
            OrderStatus(name: "Processing", siteID: 1, slug: "processing", total: 5),
            OrderStatus(name: "On hold", siteID: 1, slug: "on-hold", total: 2),
            OrderStatus(name: "Completed", siteID: 1, slug: "completed", total: 10),
            OrderStatus(name: "Cancelled", siteID: 1, slug: "cancelled", total: 1),
            OrderStatus(name: "Refunded", siteID: 1, slug: "refunded", total: 0),
            OrderStatus(name: "Failed", siteID: 1, slug: "failed", total: 1)
        ]

        // When
        let mapped = CIABOrderStatusMapper.mapFilterOptions(statuses)

        // Then
        #expect(mapped.count == 4) // Open, Completed, Cancelled, Refunded
        #expect(mapped[0].slug == CIABOrderStatusMapper.openSlug)
        #expect(mapped[0].name == "Open")
        #expect(mapped[1].slug == "completed")
        #expect(mapped[2].slug == "cancelled")
        #expect(mapped[3].slug == "refunded")
    }

    @Test("mapFilterOptions preserves non-open statuses unchanged")
    func test_mapFilterOptions_when_only_non_open_statuses_then_preserves_all() {
        // Given
        let statuses: [OrderStatus] = [
            OrderStatus(name: "Completed", siteID: 1, slug: "completed", total: 10),
            OrderStatus(name: "Refunded", siteID: 1, slug: "refunded", total: 0)
        ]

        // When
        let mapped = CIABOrderStatusMapper.mapFilterOptions(statuses)

        // Then
        #expect(mapped.count == 2)
        #expect(mapped[0].slug == "completed")
        #expect(mapped[1].slug == "refunded")
    }

    @Test("mapFilterOptions handles empty input")
    func test_mapFilterOptions_when_empty_then_returns_empty() {
        #expect(CIABOrderStatusMapper.mapFilterOptions([]).isEmpty)
    }

    // MARK: - resolveFilterStatuses

    @Test("resolveFilterStatuses expands open to core statuses")
    func test_resolveFilterStatuses_when_open_then_expands_to_four_statuses() {
        // Given
        let statuses: [OrderStatusEnum] = [.custom(CIABOrderStatusMapper.openSlug)]

        // When
        let resolved = CIABOrderStatusMapper.resolveFilterStatuses(statuses)

        // Then
        #expect(resolved.count == 4)
        #expect(Set(resolved) == CIABOrderStatusMapper.openStatuses)
    }

    @Test("resolveFilterStatuses preserves non-open statuses")
    func test_resolveFilterStatuses_when_non_open_then_returns_unchanged() {
        // Given
        let statuses: [OrderStatusEnum] = [.completed, .cancelled]

        // When
        let resolved = CIABOrderStatusMapper.resolveFilterStatuses(statuses)

        // Then
        #expect(resolved == [.completed, .cancelled])
    }

    @Test("resolveFilterStatuses handles mix of open and non-open")
    func test_resolveFilterStatuses_when_mixed_then_expands_open_preserves_rest() {
        // Given
        let statuses: [OrderStatusEnum] = [.custom(CIABOrderStatusMapper.openSlug), .completed]

        // When
        let resolved = CIABOrderStatusMapper.resolveFilterStatuses(statuses)

        // Then
        #expect(resolved.count == 5) // 4 open + completed
        #expect(resolved.contains(.pending))
        #expect(resolved.contains(.processing))
        #expect(resolved.contains(.onHold))
        #expect(resolved.contains(.failed))
        #expect(resolved.contains(.completed))
    }

    @Test("resolveFilterStatuses handles empty input")
    func test_resolveFilterStatuses_when_empty_then_returns_empty() {
        #expect(CIABOrderStatusMapper.resolveFilterStatuses([]).isEmpty)
    }

    // MARK: - Filter persistence validation (resolveFilterStatuses used to validate stored filters)

    @Test("Resolved open filter statuses all exist in API-returned statuses")
    func test_resolveFilterStatuses_when_open_then_all_resolved_statuses_exist_in_api_statuses() {
        // Given — API returns core statuses; stored filter is synthetic "open"
        let apiStatuses: Set<OrderStatusEnum> = [.pending, .processing, .onHold, .failed, .completed, .cancelled, .refunded]
        let storedFilter: [OrderStatusEnum] = [.custom(CIABOrderStatusMapper.openSlug)]

        // When — resolve synthetic status to core statuses for validation
        let resolved = CIABOrderStatusMapper.resolveFilterStatuses(storedFilter)

        // Then — every resolved status exists in the API set
        for status in resolved {
            #expect(apiStatuses.contains(status), "Resolved status \(status) should exist in API statuses")
        }
    }

    @Test("Unresolved open filter does not exist in API-returned statuses")
    func test_custom_open_status_does_not_exist_in_api_statuses() {
        // Given — API returns core statuses only
        let apiStatuses: Set<OrderStatusEnum> = [.pending, .processing, .onHold, .failed, .completed, .cancelled, .refunded]

        // Then — the synthetic "open" status is NOT in the API set (the bug scenario)
        #expect(!apiStatuses.contains(.custom(CIABOrderStatusMapper.openSlug)))
    }
}
