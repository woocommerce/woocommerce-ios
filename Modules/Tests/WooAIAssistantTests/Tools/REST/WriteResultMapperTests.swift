import Foundation
import Testing
@testable import WooAIAssistant

struct WriteResultMapperTests {
    @Test
    func test_mapEntity_when_response_ok_then_returns_success_with_pruned_card_and_summary() {
        // Given
        let body = """
        {
            "id": 42,
            "status": "completed",
            "_links": {"self": []},
            "meta_data": [{"id": 9, "key": "_x", "value": "y"}]
        }
        """
        let response = WCRESTResponse(data: Data(body.utf8), statusCode: 200)

        // When
        let result = WriteResultMapper.mapEntity(response,
                                                 toolName: "orders_update",
                                                 family: .order,
                                                 summarize: { entity in
            if case .object(let dict) = entity, let status = dict["status"] {
                return .object(["status": status])
            }
            return entity
        })

        // Then
        guard case .success(let success) = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        let cards = success.uiStructured?.cards ?? []
        #expect(cards.count == 1)
        #expect(cards.first?.id == "42")
        #expect(cards.first?.family == .order)
        if case .object(let element) = cards.first?.element {
            #expect(element["_links"] == nil)
            #expect(element["meta_data"] == nil)
            #expect(element["status"] == .string("completed"))
        } else {
            Issue.record("expected object element")
        }
        if case .object(let summary) = success.structured {
            #expect(summary["status"] == .string("completed"))
        }
    }

    @Test
    func test_mapEntity_when_response_408_then_returns_outcomeUnknown() {
        // Given
        let response = WCRESTResponse(data: Data(), statusCode: 408)

        // When
        let result = WriteResultMapper.mapEntity(response,
                                                 toolName: "orders_update",
                                                 family: .order,
                                                 summarize: { _ in .object([:]) })

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .outcomeUnknown)
    }

    @Test
    func test_mapEntity_when_response_is_transport_failure_then_returns_outcomeUnknown() {
        // Given
        let response = WCRESTResponse(data: Data(), statusCode: 0)

        // When
        let result = WriteResultMapper.mapEntity(response,
                                                 toolName: "products_update",
                                                 family: .product,
                                                 summarize: { _ in .object([:]) })

        // Then
        guard case .failed(let failed) = result, failed.kind == .outcomeUnknown else {
            Issue.record("expected outcomeUnknown, got \(result)")
            return
        }
    }

    @Test
    func test_mapEntity_when_response_4xx_then_returns_failed_with_status_kind_not_outcomeUnknown() {
        // Given
        let response = WCRESTResponse(data: Data(#"{"code":"invalid"}"#.utf8), statusCode: 400)

        // When
        let result = WriteResultMapper.mapEntity(response,
                                                 toolName: "orders_update",
                                                 family: .order,
                                                 summarize: { _ in .object([:]) })

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind != .outcomeUnknown)
    }

    @Test
    func test_mapEntity_when_response_has_no_id_then_succeeds_without_card() {
        // Given
        let response = WCRESTResponse(data: Data(#"{"name": "Foo"}"#.utf8), statusCode: 200)

        // When
        let result = WriteResultMapper.mapEntity(response,
                                                 toolName: "orders_update",
                                                 family: .order,
                                                 summarize: { entity in entity })

        // Then
        guard case .success(let success) = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        #expect(success.uiStructured == nil)
    }

    @Test
    func test_mapBatch_when_all_entries_succeed_then_summary_lists_updated_ids() {
        // Given
        let body = """
        {"update": [{"id": 1, "status": "publish"}, {"id": 2, "status": "publish"}]}
        """
        let response = WCRESTResponse(data: Data(body.utf8), statusCode: 200)

        // When
        let result = WriteResultMapper.mapBatch(response,
                                                toolName: "products_bulk_update",
                                                family: .product)

        // Then
        guard case .success(let success) = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        if case .object(let summary) = success.structured {
            #expect(summary["updated_count"] == .int(2))
            #expect(summary["failed_count"] == .int(0))
            if case .array(let ids) = summary["updated_ids"] {
                #expect(ids == [.int(1), .int(2)])
            } else {
                Issue.record("expected updated_ids array")
            }
        }
        #expect(success.uiStructured?.cards.count == 2)
    }

    @Test
    func test_mapBatch_when_partial_failure_then_summary_includes_failed_entries() {
        // Given
        let body = """
        {"update": [
            {"id": 1, "status": "publish"},
            {"error": {"code": "rest_invalid", "message": "bad"}, "id": 2}
        ]}
        """
        let response = WCRESTResponse(data: Data(body.utf8), statusCode: 200)

        // When
        let result = WriteResultMapper.mapBatch(response,
                                                toolName: "products_bulk_update",
                                                family: .product)

        // Then
        guard case .success(let success) = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        if case .object(let summary) = success.structured {
            #expect(summary["updated_count"] == .int(1))
            #expect(summary["failed_count"] == .int(1))
        }
    }

    @Test
    func test_mapBatch_when_408_then_returns_outcomeUnknown() {
        // Given
        let response = WCRESTResponse(data: Data(), statusCode: 408)

        // When
        let result = WriteResultMapper.mapBatch(response,
                                                toolName: "orders_bulk_update",
                                                family: .order)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .outcomeUnknown)
    }
}
