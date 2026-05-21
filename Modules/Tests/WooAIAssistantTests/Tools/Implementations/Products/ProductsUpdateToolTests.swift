import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct ProductsUpdateToolTests {

    @Test
    func test_update_when_id_is_simple_product_then_routes_to_products_batch_endpoint() async throws {
        // Given
        let probe = #"{"id": 12, "name": "Tee", "type": "simple", "regular_price": "20.00"}"#
        let discoveryList = "[\(probe)]"
        let batchResponse = #"{"update": [{"id": 12, "name": "Tee", "regular_price": "19.99"}]}"#
        let client = MockWCRESTClient(responses: [StubResponses.ok(discoveryList), StubResponses.ok(batchResponse)])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 12}, "regular_price": "19.99"}]}"#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        let calls = await client.calls
        #expect(calls.map { $0.method } == ["GET", "POST"])
        #expect(calls.first?.path == "wc/v3/products")
        #expect(calls.last?.path == "wc/v3/products/batch")
        let body = try requireBatchBody(calls.last?.body)
        try requireSingleUpdate(body, id: 12, fields: ["regular_price": "19.99"])
        #expect(updatedProductIDs(receipt) == [12])
        #expect(receipt["partial_success"] == .bool(false))
    }

    @Test
    func test_update_when_target_is_variation_then_routes_to_variations_batch_endpoint_under_parent() async throws {
        // Given
        let batchResponse = #"{"update": [{"id": 88, "sale_price": "27.00"}]}"#
        let client = MockWCRESTClient(response: StubResponses.ok(batchResponse))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "variation", "id": 88, "parent_id": 12}, "sale_price": "27.00"}]}"#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        let calls = await client.calls
        #expect(calls.last?.method == "POST")
        #expect(calls.last?.path == "wc/v3/products/12/variations/batch")
        let body = try requireBatchBody(calls.last?.body)
        try requireSingleUpdate(body, id: 88, fields: ["sale_price": "27.00"])
        let variation = try #require(updatedTargets(receipt).first)
        #expect(variation.kind == "variation")
        #expect(variation.id == 88)
        #expect(variation.parentID == 12)
    }

    @Test
    func test_update_when_id_is_variable_parent_with_stock_quantity_then_refuses_with_reason() async throws {
        // Given
        let probe = #"{"id": 50, "type": "variable"}"#
        let client = MockWCRESTClient(response: StubResponses.ok("[\(probe)]"))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 50}, "stock_quantity": 5}]}"#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        guard case .array(let failed) = receipt["failed"], case .object(let entry) = failed.first else {
            Issue.record("expected failed entry")
            return
        }
        #expect(entry["id"] == .int(50))
        if case .string(let reason) = entry["reason"] {
            #expect(reason.contains("variable parent"))
            #expect(reason.contains("target specific variations"))
        } else {
            Issue.record("expected reason string")
        }
        #expect(updatedTargets(receipt).isEmpty)
        let calls = await client.calls
        #expect(calls.allSatisfy { $0.method == "GET" })
    }

    @Test
    func test_update_when_variable_parent_name_only_then_posts_parent_to_products_batch() async throws {
        // Given
        let probe = #"{"id": 50, "type": "variable"}"#
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc/v3/products": StubResponses.ok("[\(probe)]"),
            "POST wc/v3/products/batch": StubResponses.ok(#"{"update": [{"id": 50, "name": "New name"}]}"#)
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 50}, "name": "New name"}]}"#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        let posts = await client.calls.filter { $0.method == "POST" }
        #expect(posts.count == 1)
        #expect(posts.first?.path == "wc/v3/products/batch")
        let body = try requireBatchBody(posts.first?.body)
        try requireSingleUpdate(body, id: 50, fields: ["name": "New name"])
        #expect(updatedProductIDs(receipt) == [50])
        guard case .array(let failed) = receipt["failed"] else {
            Issue.record("expected failed array")
            return
        }
        #expect(failed.isEmpty)
    }

    @Test
    func test_update_when_variable_parent_price_only_then_refused_with_no_write() async throws {
        // Given
        let probe = #"{"id": 50, "type": "variable"}"#
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc/v3/products": StubResponses.ok("[\(probe)]"),
            "POST wc/v3/products/batch": StubResponses.ok(#"{"update": [{"id": 50}]}"#)
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 50}, "regular_price": "19.99"}]}"#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        let posts = await client.calls.filter { $0.method == "POST" }
        #expect(posts.isEmpty)
        #expect(updatedTargets(receipt).isEmpty)
        guard case .array(let failed) = receipt["failed"], case .object(let entry) = failed.first else {
            Issue.record("expected failed entry")
            return
        }
        #expect(entry["id"] == .int(50))
        if case .string(let reason) = entry["reason"] {
            #expect(reason.contains("variation-level"))
            #expect(reason.contains("all_variations"))
        } else {
            Issue.record("expected reason string")
        }
    }

    @Test
    func test_update_when_variable_parent_variation_field_without_scope_then_rejected_with_scope_hint() async throws {
        // Given
        let probe = #"{"id": 50, "type": "variable"}"#
        let client = MockWCRESTClient(response: StubResponses.ok("[\(probe)]"))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 50}, "sale_price": "9"}]}"#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        guard case .array(let failed) = receipt["failed"], case .object(let entry) = failed.first else {
            Issue.record("expected failed entry")
            return
        }
        #expect(entry["id"] == .int(50))
        if case .string(let reason) = entry["reason"] {
            #expect(reason.contains("all_variations"))
            #expect(reason.contains("variation-level"))
            #expect(reason.contains("target.kind=\"variation\""))
        } else {
            Issue.record("expected reason string")
        }
    }

    @Test
    func test_update_when_variable_parent_name_and_price_without_scope_then_refuses_entire_entry() async throws {
        // Given
        let probe = #"{"id": 50, "type": "variable"}"#
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc/v3/products": StubResponses.ok("[\(probe)]"),
            "POST wc/v3/products/batch": StubResponses.ok(#"{"update": [{"id": 50}]}"#)
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"""
            {"updates": [{
              "target": {"kind": "product", "id": 50},
              "name": "Renamed", "regular_price": "19.99"
            }]}
            """#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        let posts = await client.calls.filter { $0.method == "POST" }
        #expect(posts.isEmpty)
        let nameWrites = posts.compactMap { try? requireBatchBody($0.body) }
            .flatMap { $0 }
            .filter { $0["name"] != nil }
        #expect(nameWrites.isEmpty)
        #expect(updatedTargets(receipt).isEmpty)
        guard case .array(let failed) = receipt["failed"], case .object(let entry) = failed.first else {
            Issue.record("expected failed entry")
            return
        }
        #expect(failed.count == 1)
        #expect(entry["id"] == .int(50))
        if case .string(let reason) = entry["reason"] {
            #expect(reason.contains("target.kind=\"variation\""))
            #expect(reason.contains("target.scope=\"all_variations\""))
        } else {
            Issue.record("expected reason string")
        }
    }

    @Test
    func test_update_when_mixed_simple_and_variations_then_routes_each_correctly() async throws {
        // Given
        let simpleProbe = #"{"id": 10, "type": "simple", "regular_price": "50.00"}"#
        let topLevelBatch = #"{"update": [{"id": 10}]}"#
        let variationsBatch = #"{"update": [{"id": 88}]}"#
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc/v3/products": StubResponses.ok("[\(simpleProbe)]"),
            "POST wc/v3/products/batch": StubResponses.ok(topLevelBatch),
            "POST wc/v3/products/12/variations/batch": StubResponses.ok(variationsBatch)
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"""
            {"updates": [
              {"target": {"kind": "product", "id": 10}, "sale_price": "45"},
              {"target": {"kind": "variation", "id": 88, "parent_id": 12}, "sale_price": "25"}
            ]}
            """#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        let posts = await client.calls.filter { $0.method == "POST" }
        #expect(Set(posts.map { $0.path }) == [
            "wc/v3/products/batch",
            "wc/v3/products/12/variations/batch"
        ])
        #expect(updatedProductIDs(receipt) == [10])
        #expect(updatedVariationIDs(receipt) == [88])
        let variation = try #require(updatedTargets(receipt).first { $0.kind == "variation" })
        #expect(variation.parentID == 12)
    }

    @Test
    func test_update_when_one_entry_fails_discovery_then_others_still_succeed() async throws {
        // Given
        let okProbe = #"{"id": 10, "type": "simple", "regular_price": "50.00"}"#
        let batchResponse = #"{"update": [{"id": 10}]}"#
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc/v3/products": StubResponses.ok("[\(okProbe)]"),
            "GET wc/v3/products/999": StubResponses.failure(statusCode: 404, body: "not found"),
            "POST wc/v3/products/batch": StubResponses.ok(batchResponse)
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"""
            {"updates": [
              {"target": {"kind": "product", "id": 999}, "sale_price": "1"},
              {"target": {"kind": "product", "id": 10}, "sale_price": "45"}
            ]}
            """#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        #expect(updatedProductIDs(receipt) == [10])
        guard case .array(let failed) = receipt["failed"], case .object(let entry) = failed.first else {
            Issue.record("expected failed entry")
            return
        }
        #expect(entry["id"] == .int(999))
        #expect(receipt["partial_success"] == .bool(true))
    }

    @Test
    func test_update_receipt_partial_success_flag_set_correctly() async throws {
        // Given
        let probe = #"{"id": 50, "type": "variable"}"#
        let client = MockWCRESTClient(response: StubResponses.ok("[\(probe)]"))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 50}, "stock_quantity": 5}]}"#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        #expect(updatedTargets(receipt).isEmpty)
        #expect(receipt["partial_success"] == .bool(false))
    }

    @Test
    func test_update_when_field_outside_allowlist_then_returns_invalidToolCall() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 12}, "weight": "0.5"}]}"#,
            client
        )

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.contains("weight"))
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_update_when_stock_quantity_set_on_simple_then_body_carries_manage_stock_true() async throws {
        // Given
        let probe = #"{"id": 12, "type": "simple"}"#
        let batchResponse = #"{"update": [{"id": 12}]}"#
        let client = MockWCRESTClient(responses: [StubResponses.ok("[\(probe)]"), StubResponses.ok(batchResponse)])
        let tool = ProductsUpdateTool.make()

        // When
        _ = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 12}, "stock_quantity": 5}]}"#,
            client
        )

        // Then
        let post = try #require(await client.calls.last)
        let body = try requireBatchBody(post.body)
        let entriesByID = batchEntriesByID(body)
        #expect(entriesByID[12]?["stock_quantity"] as? Int == 5)
        #expect(entriesByID[12]?["manage_stock"] as? Bool == true)
    }

    @Test
    func test_update_when_discovery_returns_5xx_then_entry_is_in_failed_array() async throws {
        // Given
        let client = MockWCRESTClient(response: StubResponses.failure(statusCode: 500, body: "boom"))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 12}, "sale_price": "9.99"}]}"#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        guard case .array(let failed) = receipt["failed"], case .object(let entry) = failed.first else {
            Issue.record("expected failed entry")
            return
        }
        #expect(entry["id"] == .int(12))
        if case .string(let reason) = entry["reason"] {
            #expect(reason.contains("HTTP 500"))
            #expect(!reason.contains("not found"))
        } else {
            Issue.record("expected reason string")
        }
        #expect(updatedTargets(receipt).isEmpty)
    }

    @Test
    func test_update_when_all_entries_fail_discovery_then_partial_success_is_false() async throws {
        // Given
        let client = MockWCRESTClient(responses: [
            StubResponses.failure(statusCode: 404, body: "not found"),
            StubResponses.failure(statusCode: 404, body: "not found")
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"""
            {"updates": [
              {"target": {"kind": "product", "id": 999}, "sale_price": "1"},
              {"target": {"kind": "product", "id": 1000}, "sale_price": "2"}
            ]}
            """#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        #expect(updatedTargets(receipt).isEmpty)
        #expect(receipt["partial_success"] == .bool(false))
    }

    @Test
    func test_update_when_variation_target_parent_id_is_zero_then_validation_rejects() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "variation", "id": 88, "parent_id": 0}, "sale_price": "9.99"}]}"#,
            client
        )

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.contains("parent_id"))
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_update_when_batch_returns_408_then_tool_result_is_outcome_unknown_failure() async {
        // Given
        let probeA = #"{"id": 10, "type": "simple", "regular_price": "50.00"}"#
        let probeB = #"{"id": 11, "type": "simple", "regular_price": "20.00"}"#
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc/v3/products": StubResponses.ok("[\(probeA),\(probeB)]"),
            "POST wc/v3/products/batch": StubResponses.failure(statusCode: 408, body: "timeout")
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"""
            {"updates": [
              {"target": {"kind": "product", "id": 10}, "sale_price": "45"},
              {"target": {"kind": "product", "id": 11}, "sale_price": "18"}
            ]}
            """#,
            client
        )

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected .failed, got \(result)")
            return
        }
        #expect(failed.kind == .outcomeUnknown)
        #expect(failed.reason.contains("Verify"))
    }

    @Test
    func test_update_when_entry_has_only_target_then_returns_invalidToolCall() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 12}}]}"#,
            client
        )

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_update_when_duplicate_target_then_returns_invalidToolCall() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"""
            {"updates": [
              {"target": {"kind": "product", "id": 42}, "sale_price": "9"},
              {"target": {"kind": "product", "id": 42}, "sale_price": "19"}
            ]}
            """#,
            client
        )

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.lowercased().contains("duplicate"))
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_update_when_batch_response_contains_per_entry_error_then_failed_array_captures_it() async throws {
        // Given
        let probeA = #"{"id": 50, "type": "simple", "regular_price": "20.00"}"#
        let probeB = #"{"id": 51, "type": "simple", "regular_price": "20.00"}"#
        let batchResponse = """
        {"update": [
          {"id": 50, "regular_price": "12.00"},
          {"id": 51, "error": {"code": "woocommerce_rest_product_sku_already_exists", "message": "SKU conflict"}}
        ]}
        """
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc/v3/products": StubResponses.ok("[\(probeA),\(probeB)]"),
            "POST wc/v3/products/batch": StubResponses.ok(batchResponse)
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"""
            {"updates": [
              {"target": {"kind": "product", "id": 50}, "sale_price": "12.00"},
              {"target": {"kind": "product", "id": 51}, "sale_price": "12.00"}
            ]}
            """#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        #expect(updatedProductIDs(receipt) == [50])
        guard case .array(let failed) = receipt["failed"] else {
            Issue.record("expected failed array")
            return
        }
        let conflict = failed.first { node in
            if case .object(let dict) = node, dict["id"] == .int(51) { return true }
            return false
        }
        guard case .object(let conflictDict) = conflict else {
            Issue.record("expected failed entry for 51")
            return
        }
        if case .string(let reason) = conflictDict["reason"] {
            #expect(reason.contains("SKU conflict"))
        } else {
            Issue.record("expected reason string")
        }
        #expect(receipt["partial_success"] == .bool(true))
    }

    @Test(arguments: [
        ("regular_price", "25.00"),
        ("sale_price", "15.00"),
        ("status", "draft"),
        ("name", "Renamed"),
        ("stock_status", "outofstock"),
        ("sku", "TEE-001")
    ])
    func test_update_when_simple_product_field_set_then_posted_via_products_batch(jsonKey: String, value: String) async throws {
        // Given
        let probe = #"{"id": 12, "type": "simple", "regular_price": "20.00"}"#
        let batchResponse = "{\"update\": [{\"id\": 12, \"\(jsonKey)\": \"\(value)\"}]}"
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc/v3/products": StubResponses.ok("[\(probe)]"),
            "POST wc/v3/products/batch": StubResponses.ok(batchResponse)
        ])
        let tool = ProductsUpdateTool.make()
        let arguments = "{\"updates\": [{\"target\": {\"kind\": \"product\", \"id\": 12}, \"\(jsonKey)\": \"\(value)\"}]}"

        // When
        let result = await tool.executor(arguments, client)

        // Then
        let receipt = try successReceipt(result)
        let calls = await client.calls
        #expect(calls.map { $0.method } == ["GET", "POST"])
        #expect(calls.last?.path == "wc/v3/products/batch")
        let body = try requireBatchBody(calls.last?.body)
        try requireSingleUpdate(body, id: 12, fields: [jsonKey: value])
        #expect(updatedProductIDs(receipt) == [12])
    }

    @Test
    func test_update_when_name_set_on_variation_then_entry_rejected_with_variation_name_reason() async throws {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "variation", "id": 88, "parent_id": 12}, "name": "Nope"}]}"#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        guard case .array(let failed) = receipt["failed"], case .object(let entry) = failed.first else {
            Issue.record("expected failed entry")
            return
        }
        #expect(entry["id"] == .int(88))
        if case .string(let reason) = entry["reason"] {
            #expect(reason.contains("Variations do not have settable names"))
            #expect(reason.contains("derived from parent"))
        } else {
            Issue.record("expected reason string")
        }
        let posts = await client.calls.filter { $0.method == "POST" }
        #expect(posts.isEmpty)
        #expect(updatedTargets(receipt).isEmpty)
    }

    @Test
    func test_update_when_stock_status_set_on_variation_then_routes_to_variations_batch_with_field_present() async throws {
        // Given
        let batchResponse = #"{"update": [{"id": 88, "stock_status": "outofstock"}]}"#
        let client = MockWCRESTClient(response: StubResponses.ok(batchResponse))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "variation", "id": 88, "parent_id": 12}, "stock_status": "outofstock"}]}"#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        let calls = await client.calls
        let posts = calls.filter { $0.method == "POST" }
        #expect(posts.count == 1)
        #expect(posts.first?.path == "wc/v3/products/12/variations/batch")
        let body = try requireBatchBody(posts.first?.body)
        try requireSingleUpdate(body, id: 88, fields: ["stock_status": "outofstock"])
        #expect(updatedVariationIDs(receipt) == [88])
    }

    @Test
    func test_update_when_sku_set_on_variation_then_routes_to_variations_batch_with_field_present() async throws {
        // Given
        let batchResponse = #"{"update": [{"id": 88, "sku": "TEE-RED-L"}]}"#
        let client = MockWCRESTClient(response: StubResponses.ok(batchResponse))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "variation", "id": 88, "parent_id": 12}, "sku": "TEE-RED-L"}]}"#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        let posts = await client.calls.filter { $0.method == "POST" }
        #expect(posts.count == 1)
        #expect(posts.first?.path == "wc/v3/products/12/variations/batch")
        let body = try requireBatchBody(posts.first?.body)
        try requireSingleUpdate(body, id: 88, fields: ["sku": "TEE-RED-L"])
        #expect(updatedVariationIDs(receipt) == [88])
    }

    @Test
    func test_update_when_many_entries_then_discovery_uses_single_batched_get() async throws {
        // Given
        let ids = (1...30).map { $0 + 1000 }
        let probes = ids.map { #"{"id": \#($0), "type": "simple", "regular_price": "10.00"}"# }
        let discoveryList = "[\(probes.joined(separator: ","))]"
        let updateEntries = ids.map { #"{"id": \#($0)}"# }
        let batchResponse = "{\"update\": [\(updateEntries.joined(separator: ","))]}"
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc/v3/products": StubResponses.ok(discoveryList),
            "POST wc/v3/products/batch": StubResponses.ok(batchResponse)
        ])
        let tool = ProductsUpdateTool.make()
        let entries = ids.map { #"{"target": {"kind": "product", "id": \#($0)}, "sale_price": "9"}"# }
        let argumentsJSON = "{\"updates\": [\(entries.joined(separator: ","))]}"

        // When
        let result = await tool.executor(argumentsJSON, client)

        // Then
        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        let calls = await client.calls
        let gets = calls.filter { $0.method == "GET" }
        #expect(gets.count == 1)
        #expect(gets.first?.path == "wc/v3/products")
        let includeQuery = try #require(gets.first?.query["include"])
        for id in ids {
            #expect(includeQuery.contains(String(id)))
        }
        let perIDGets = calls.filter { $0.method == "GET" && $0.path.hasPrefix("wc/v3/products/") }
        #expect(perIDGets.isEmpty)
    }

    @Test
    func test_update_when_batch_returns_403_then_failure_surfaces_in_failed_array() async throws {
        // Given
        let probe = #"{"id": 12, "type": "simple", "regular_price": "20.00"}"#
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc/v3/products": StubResponses.ok("[\(probe)]"),
            "POST wc/v3/products/batch": StubResponses.failure(statusCode: 403, body: "forbidden")
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 12}, "sale_price": "9.99"}]}"#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        #expect(updatedTargets(receipt).isEmpty)
        #expect(receipt["partial_success"] == .bool(false))
        guard case .array(let failed) = receipt["failed"], case .object(let entry) = failed.first else {
            Issue.record("expected failed entry")
            return
        }
        #expect(entry["id"] == .int(12))
        if case .string(let reason) = entry["reason"] {
            #expect(reason.contains("HTTP 403"))
        } else {
            Issue.record("expected reason string")
        }
    }

    @Test
    func test_update_when_batch_returns_500_then_entries_are_in_failed_array_not_outcome_unknown() async throws {
        // Given
        let probe = #"{"id": 12, "type": "simple", "regular_price": "20.00"}"#
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc/v3/products": StubResponses.ok("[\(probe)]"),
            "POST wc/v3/products/batch": StubResponses.failure(statusCode: 500, body: "boom")
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 12}, "sale_price": "9.99"}]}"#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        #expect(updatedTargets(receipt).isEmpty)
        guard case .array(let failed) = receipt["failed"], case .object(let entry) = failed.first else {
            Issue.record("expected failed entry")
            return
        }
        #expect(entry["id"] == .int(12))
        if case .string(let reason) = entry["reason"] {
            #expect(reason.contains("HTTP 500"))
        } else {
            Issue.record("expected reason string")
        }
    }

    @Test
    func test_update_when_multiple_variations_under_same_parent_then_single_variations_batch() async throws {
        // Given
        let batchResponse = #"{"update": [{"id": 88}, {"id": 89}]}"#
        let client = MockWCRESTClient(response: StubResponses.ok(batchResponse))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"""
            {"updates": [
              {"target": {"kind": "variation", "id": 88, "parent_id": 12}, "sale_price": "9"},
              {"target": {"kind": "variation", "id": 89, "parent_id": 12}, "sale_price": "8"}
            ]}
            """#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        let posts = await client.calls.filter { $0.method == "POST" }
        #expect(posts.count == 1)
        #expect(posts.first?.path == "wc/v3/products/12/variations/batch")
        let body = try requireBatchBody(posts.first?.body)
        #expect(Set(body.compactMap { $0["id"] as? Int }) == [88, 89])
        #expect(updatedVariationIDs(receipt) == [88, 89])
        #expect(updatedTargets(receipt).allSatisfy { $0.parentID == 12 })
    }

    @Test
    func test_update_when_variations_under_different_parents_then_one_batch_per_parent() async throws {
        // Given
        let client = RoutingMockWCRESTClient(routes: [
            "POST wc/v3/products/12/variations/batch": StubResponses.ok(#"{"update": [{"id": 88}]}"#),
            "POST wc/v3/products/13/variations/batch": StubResponses.ok(#"{"update": [{"id": 99}]}"#)
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"""
            {"updates": [
              {"target": {"kind": "variation", "id": 88, "parent_id": 12}, "sale_price": "9"},
              {"target": {"kind": "variation", "id": 99, "parent_id": 13}, "sale_price": "8"}
            ]}
            """#,
            client
        )

        // Then
        _ = try successReceipt(result)
        let posts = await client.calls.filter { $0.method == "POST" }
        #expect(posts.count == 2)
        #expect(Set(posts.map { $0.path }) == [
            "wc/v3/products/12/variations/batch",
            "wc/v3/products/13/variations/batch"
        ])
    }

    @Test
    func test_update_when_one_entry_sets_all_writable_fields_then_batch_body_carries_each() async throws {
        // Given
        let probe = #"{"id": 12, "type": "simple", "regular_price": "20.00"}"#
        let batchResponse = #"{"update": [{"id": 12}]}"#
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc/v3/products": StubResponses.ok("[\(probe)]"),
            "POST wc/v3/products/batch": StubResponses.ok(batchResponse)
        ])
        let tool = ProductsUpdateTool.make()

        // When
        _ = await tool.executor(
            #"""
            {"updates": [{"target": {"kind": "product", "id": 12},
              "regular_price": "30.00", "sale_price": "25.00", "stock_quantity": 7,
              "status": "draft", "name": "Renamed", "stock_status": "instock", "sku": "TEE-9"}]}
            """#,
            client
        )

        // Then
        let post = try #require(await client.calls.last)
        let body = try requireBatchBody(post.body)
        let entriesByID = batchEntriesByID(body)
        let entry = try #require(entriesByID[12])
        #expect(entry["regular_price"] as? String == "30.00")
        #expect(entry["sale_price"] as? String == "25.00")
        #expect(entry["stock_quantity"] as? Int == 7)
        #expect(entry["manage_stock"] as? Bool == true)
        #expect(entry["status"] as? String == "draft")
        #expect(entry["name"] as? String == "Renamed")
        #expect(entry["stock_status"] as? String == "instock")
        #expect(entry["sku"] as? String == "TEE-9")
    }

    @Test
    func test_update_when_discovery_chunk_returns_429_then_entry_failed_and_no_per_id_probe() async throws {
        // Given
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc/v3/products": StubResponses.failure(statusCode: 429, body: "slow down"),
            "GET wc/v3/products/12": StubResponses.ok(#"{"id": 12, "type": "simple"}"#),
            "POST wc/v3/products/batch": StubResponses.ok(#"{"update": [{"id": 12}]}"#)
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 12}, "sale_price": "9.99"}]}"#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        let calls = await client.calls
        #expect(!calls.contains { $0.method == "GET" && $0.path == "wc/v3/products/12" })
        #expect(!calls.contains { $0.method == "POST" })
        guard case .array(let failed) = receipt["failed"], case .object(let entry) = failed.first else {
            Issue.record("expected failed entry")
            return
        }
        #expect(entry["id"] == .int(12))
        if case .string(let reason) = entry["reason"] {
            #expect(reason.contains("HTTP 429"))
            #expect(reason.contains("look up"))
        } else {
            Issue.record("expected reason string")
        }
        #expect(updatedTargets(receipt).isEmpty)
    }

    @Test
    func test_update_when_discovery_chunk_succeeds_but_id_absent_then_one_per_id_probe_fires() async throws {
        // Given
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc/v3/products": StubResponses.ok("[]"),
            "GET wc/v3/products/12": StubResponses.ok(#"{"id": 12, "type": "simple", "regular_price": "20.00"}"#),
            "POST wc/v3/products/batch": StubResponses.ok(#"{"update": [{"id": 12}]}"#)
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 12}, "sale_price": "9.99"}]}"#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        let calls = await client.calls
        let perIDProbes = calls.filter { $0.method == "GET" && $0.path == "wc/v3/products/12" }
        #expect(perIDProbes.count == 1)
        #expect(calls.contains { $0.method == "POST" && $0.path == "wc/v3/products/batch" })
        #expect(updatedProductIDs(receipt) == [12])
    }

    @Test
    func test_update_when_status_set_on_variation_then_routes_to_variations_batch_with_status() async throws {
        // Given
        let batchResponse = #"{"update": [{"id": 88, "status": "draft"}]}"#
        let client = MockWCRESTClient(response: StubResponses.ok(batchResponse))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "variation", "id": 88, "parent_id": 12}, "status": "draft"}]}"#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        let posts = await client.calls.filter { $0.method == "POST" }
        #expect(posts.count == 1)
        #expect(posts.first?.path == "wc/v3/products/12/variations/batch")
        let body = try requireBatchBody(posts.first?.body)
        try requireSingleUpdate(body, id: 88, fields: ["status": "draft"])
        #expect(updatedVariationIDs(receipt) == [88])
    }

    @Test
    func test_update_when_stock_quantity_set_on_variation_then_body_carries_manage_stock_true() async throws {
        // Given
        let batchResponse = #"{"update": [{"id": 88}]}"#
        let client = MockWCRESTClient(response: StubResponses.ok(batchResponse))
        let tool = ProductsUpdateTool.make()

        // When
        _ = await tool.executor(
            #"{"updates": [{"target": {"kind": "variation", "id": 88, "parent_id": 12}, "stock_quantity": 4}]}"#,
            client
        )

        // Then
        let post = try #require(await client.calls.last)
        #expect(post.path == "wc/v3/products/12/variations/batch")
        let body = try requireBatchBody(post.body)
        let entriesByID = batchEntriesByID(body)
        #expect(entriesByID[88]?["stock_quantity"] as? Int == 4)
        #expect(entriesByID[88]?["manage_stock"] as? Bool == true)
    }

    @Test
    func test_update_receipt_when_mixed_batch_then_carries_both_product_and_variation_shapes() async throws {
        // Given
        let probe = #"{"id": 10, "type": "simple", "regular_price": "50.00"}"#
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc/v3/products": StubResponses.ok("[\(probe)]"),
            "POST wc/v3/products/batch": StubResponses.ok(#"{"update": [{"id": 10}]}"#),
            "POST wc/v3/products/12/variations/batch": StubResponses.ok(#"{"update": [{"id": 88}]}"#)
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"""
            {"updates": [
              {"target": {"kind": "product", "id": 10}, "sale_price": "45"},
              {"target": {"kind": "variation", "id": 88, "parent_id": 12}, "sale_price": "25"}
            ]}
            """#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        let product = try #require(updatedTargets(receipt).first { $0.kind == "product" })
        #expect(product.id == 10)
        #expect(product.parentID == nil)
        let variation = try #require(updatedTargets(receipt).first { $0.kind == "variation" })
        #expect(variation.id == 88)
        #expect(variation.parentID == 12)
    }

    @Test
    func test_update_when_batch_response_omits_a_requested_row_then_outcome_unknown() async {
        // Given
        let probeA = #"{"id": 10, "type": "simple", "regular_price": "50.00"}"#
        let probeB = #"{"id": 11, "type": "simple", "regular_price": "20.00"}"#
        let batchResponse = #"{"update": [{"id": 10, "regular_price": "45.00"}]}"#
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc/v3/products": StubResponses.ok("[\(probeA),\(probeB)]"),
            "POST wc/v3/products/batch": StubResponses.ok(batchResponse)
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"""
            {"updates": [
              {"target": {"kind": "product", "id": 10}, "sale_price": "45"},
              {"target": {"kind": "product", "id": 11}, "sale_price": "18"}
            ]}
            """#,
            client
        )

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected .failed, got \(result)")
            return
        }
        #expect(failed.kind == .outcomeUnknown)
        #expect(failed.reason.contains("no confirmation row for #11"))
        #expect(failed.reason.contains("\"kind\":\"product\""))
    }

    // MARK: - Target validation

    @Test
    func test_update_when_target_is_missing_then_invalidToolCall() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(#"{"updates": [{"sale_price": "9"}]}"#, client)

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.contains("target"))
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_update_when_target_kind_is_unknown_then_invalidToolCall() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "bundle", "id": 12}, "sale_price": "9"}]}"#,
            client
        )

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.contains("kind"))
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_update_when_target_id_is_zero_then_invalidToolCall() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 0}, "sale_price": "9"}]}"#,
            client
        )

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.contains("target.id"))
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_update_when_variation_target_missing_parent_id_then_invalidToolCall() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "variation", "id": 88}, "sale_price": "9"}]}"#,
            client
        )

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.contains("parent_id"))
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_update_when_product_target_with_parent_id_then_invalidToolCall() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("{}"))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 12, "parent_id": 3}, "sale_price": "9"}]}"#,
            client
        )

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.contains("parent_id"))
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_update_when_variation_target_then_skips_all_gets() async throws {
        // Given
        let batchResponse = #"{"update": [{"id": 88, "stock_status": "outofstock"}]}"#
        let client = MockWCRESTClient(response: StubResponses.ok(batchResponse))
        let tool = ProductsUpdateTool.make()

        // When
        _ = await tool.executor(
            #"{"updates": [{"target": {"kind": "variation", "id": 88, "parent_id": 12}, "stock_status": "outofstock"}]}"#,
            client
        )

        // Then
        let calls = await client.calls
        #expect(!calls.contains(where: { $0.method == "GET" }))
    }

    @Test
    func test_update_when_product_target_id_points_at_variation_entity_then_rejected_with_kind_hint() async throws {
        // Given
        let probe = #"{"id": 88, "type": "variation", "parent_id": 12}"#
        let client = MockWCRESTClient(response: StubResponses.ok("[\(probe)]"))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 88}, "sale_price": "9"}]}"#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        guard case .array(let failed) = receipt["failed"], case .object(let entry) = failed.first else {
            Issue.record("expected failed entry")
            return
        }
        #expect(entry["id"] == .int(88))
        if case .string(let reason) = entry["reason"] {
            #expect(reason.contains("variation"))
        } else {
            Issue.record("expected reason string")
        }
    }

    @Test
    func test_update_when_only_variation_targets_then_discovery_chunked_get_does_not_fire() async throws {
        // Given
        let batchResponse = #"{"update": [{"id": 88, "stock_status": "outofstock"}]}"#
        let client = MockWCRESTClient(response: StubResponses.ok(batchResponse))
        let tool = ProductsUpdateTool.make()

        // When
        _ = await tool.executor(
            #"{"updates": [{"target": {"kind": "variation", "id": 88, "parent_id": 12}, "stock_status": "outofstock"}]}"#,
            client
        )

        // Then
        let calls = await client.calls
        let chunkedGets = calls.filter { $0.method == "GET" && $0.path == "wc/v3/products" }
        #expect(chunkedGets.isEmpty)
    }

    @Test
    func test_update_when_per_id_percent_discount_then_uses_each_entitys_own_regular_price() async throws {
        // Given
        let probeA = #"{"id": 10, "type": "simple", "regular_price": "50.00"}"#
        let probeB = #"{"id": 11, "type": "simple", "regular_price": "20.00"}"#
        let batchResponse = #"{"update": [{"id": 10}, {"id": 11}]}"#
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc/v3/products": StubResponses.ok("[\(probeA),\(probeB)]"),
            "POST wc/v3/products/batch": StubResponses.ok(batchResponse)
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"""
            {"updates": [
              {"target": {"kind": "product", "id": 10}, "percent_discount": 20},
              {"target": {"kind": "product", "id": 11}, "percent_discount": 20}
            ]}
            """#,
            client
        )

        // Then
        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        let posts = await client.calls.filter { $0.method == "POST" }
        #expect(posts.count == 1)
        let body = try requireBatchBody(posts.first?.body)
        let entriesByID = batchEntriesByID(body)
        #expect(entriesByID[10]?["sale_price"] as? String == "40")
        #expect(entriesByID[11]?["sale_price"] as? String == "16")
    }

    @Test
    func test_update_when_percent_discount_and_regular_price_empty_then_appends_failed_reason() async throws {
        // Given
        let probe = #"{"id": 10, "type": "simple", "regular_price": ""}"#
        let client = MockWCRESTClient(response: StubResponses.ok("[\(probe)]"))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 10}, "percent_discount": 10}]}"#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        guard case .array(let failed) = receipt["failed"], case .object(let entry) = failed.first else {
            Issue.record("expected failed entry")
            return
        }
        if case .string(let reason) = entry["reason"] {
            #expect(reason.contains("regular_price"))
        } else {
            Issue.record("expected reason string")
        }
    }

    @Test
    func test_update_when_percent_discount_and_regular_price_is_zero_then_appends_failed_reason() async throws {
        // Given
        let probe = #"{"id": 10, "type": "simple", "regular_price": "0.00"}"#
        let client = MockWCRESTClient(response: StubResponses.ok("[\(probe)]"))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 10}, "percent_discount": 10}]}"#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        guard case .array(let failed) = receipt["failed"], case .object(let entry) = failed.first else {
            Issue.record("expected failed entry")
            return
        }
        #expect(entry["id"] == .int(10))
        if case .string(let reason) = entry["reason"] {
            #expect(reason.contains("regular_price"))
        } else {
            Issue.record("expected reason string")
        }
    }

    @Test
    func test_update_when_percent_discount_is_zero_then_invalidToolCall() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 10}, "percent_discount": 0}]}"#,
            client
        )

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.contains("percent_discount"))
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_update_when_percent_discount_is_100_then_invalidToolCall() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 10}, "percent_discount": 100}]}"#,
            client
        )

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.contains("percent_discount"))
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_update_when_percent_discount_is_negative_then_invalidToolCall() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 10}, "percent_discount": -10}]}"#,
            client
        )

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.contains("percent_discount"))
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_update_when_percent_discount_exceeds_100_then_invalidToolCall() async {
        // Given
        let client = MockWCRESTClient(response: StubResponses.ok("[]"))
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 10}, "percent_discount": 150}]}"#,
            client
        )

        // Then
        guard case .failed(let failed) = result else {
            Issue.record("expected failed, got \(result)")
            return
        }
        #expect(failed.kind == .invalidToolCall)
        #expect(failed.reason.contains("percent_discount"))
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_update_omits_percent_discount_from_outgoing_batch_body() async throws {
        // Given
        let probe = #"{"id": 10, "type": "simple", "regular_price": "100.00"}"#
        let batchResponse = #"{"update": [{"id": 10}]}"#
        let client = MockWCRESTClient(responses: [StubResponses.ok("[\(probe)]"), StubResponses.ok(batchResponse)])
        let tool = ProductsUpdateTool.make()

        // When
        _ = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 10}, "percent_discount": 25}]}"#,
            client
        )

        // Then
        let post = try #require(await client.calls.last)
        let body = try requireBatchBody(post.body)
        let entriesByID = batchEntriesByID(body)
        #expect(entriesByID[10]?["percent_discount"] == nil)
        #expect(entriesByID[10]?["sale_price"] as? String == "75")
    }

    @Test
    func test_update_when_variation_target_with_percent_discount_then_fetches_variation_and_routes_to_variations_batch() async throws {
        // Given
        let variationProbe = #"{"id": 88, "regular_price": "30.00"}"#
        let batchResponse = #"{"update": [{"id": 88, "sale_price": "27.00"}]}"#
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc/v3/products/12/variations/88": StubResponses.ok(variationProbe),
            "POST wc/v3/products/12/variations/batch": StubResponses.ok(batchResponse)
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "variation", "id": 88, "parent_id": 12}, "percent_discount": 10}]}"#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        let calls = await client.calls
        let topLevelGets = calls.filter { $0.method == "GET" && $0.path == "wc/v3/products" }
        #expect(topLevelGets.isEmpty)
        let posts = calls.filter { $0.method == "POST" }
        #expect(posts.first?.path == "wc/v3/products/12/variations/batch")
        let body = try requireBatchBody(posts.first?.body)
        let entriesByID = batchEntriesByID(body)
        #expect(entriesByID[88]?["sale_price"] as? String == "27")
        #expect(updatedVariationIDs(receipt) == [88])
    }

    @Test(arguments: [
        ("sale_price", "15.00"),
        ("regular_price", "25.00"),
        ("stock_status", "outofstock")
    ])
    func test_update_when_variable_parent_scoped_fanout_field_set_then_posts_to_variations_batch(jsonKey: String, value: String) async throws {
        // Given
        let probe = #"{"id": 50, "type": "variable", "name": "Tee"}"#
        let variationsList = """
        [{"id": 101, "regular_price": "20.00"}, {"id": 102, "regular_price": "30.00"}]
        """
        let batchResponse = "{\"update\": [{\"id\": 101, \"\(jsonKey)\": \"\(value)\"}, {\"id\": 102, \"\(jsonKey)\": \"\(value)\"}]}"
        let client = MockWCRESTClient(responses: [
            StubResponses.ok("[\(probe)]"),
            StubResponses.ok(variationsList),
            StubResponses.ok(batchResponse)
        ])
        let tool = ProductsUpdateTool.make()
        let arguments = "{\"updates\": [{\"target\": {\"kind\": \"product\", \"id\": 50, \"scope\": \"all_variations\"}, \"\(jsonKey)\": \"\(value)\"}]}"

        // When
        let result = await tool.executor(arguments, client)

        // Then
        let receipt = try successReceipt(result)
        let calls = await client.calls
        let posts = calls.filter { $0.method == "POST" }
        #expect(posts.count == 1)
        #expect(posts.first?.path == "wc/v3/products/50/variations/batch")
        let body = try requireBatchBody(posts.first?.body)
        #expect(body.count == 2)
        let entriesByID = batchEntriesByID(body)
        #expect(entriesByID[101]?[jsonKey] as? String == value)
        #expect(entriesByID[102]?[jsonKey] as? String == value)
        #expect(updatedVariationIDs(receipt) == [101, 102])
        for target in updatedTargets(receipt) where target.kind == "variation" {
            #expect(target.parentID == 50)
        }
    }

    @Test
    func test_update_when_variable_parent_scoped_fanout_percent_discount_then_computes_per_variation_sale_price() async throws {
        // Given
        let probe = #"{"id": 50, "type": "variable"}"#
        let variationsList = """
        [{"id": 101, "regular_price": "20.00"}, {"id": 102, "regular_price": "30.00"}]
        """
        let batchResponse = #"{"update": [{"id": 101}, {"id": 102}]}"#
        let client = MockWCRESTClient(responses: [
            StubResponses.ok("[\(probe)]"),
            StubResponses.ok(variationsList),
            StubResponses.ok(batchResponse)
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 50, "scope": "all_variations"}, "percent_discount": 10}]}"#,
            client
        )

        // Then
        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        let posts = await client.calls.filter { $0.method == "POST" }
        #expect(posts.count == 1)
        #expect(posts.first?.path == "wc/v3/products/50/variations/batch")
        let body = try requireBatchBody(posts.first?.body)
        let entriesByID = batchEntriesByID(body)
        #expect(entriesByID[101]?["sale_price"] as? String == "18")
        #expect(entriesByID[102]?["sale_price"] as? String == "27")
        for (_, entry) in entriesByID {
            #expect(entry["percent_discount"] == nil)
        }
    }

    @Test
    func test_update_when_variable_parent_scoped_fanout_then_updated_lists_each_variation_target() async throws {
        // Given
        let probe = #"{"id": 50, "type": "variable"}"#
        let variationsList = """
        [{"id": 101, "regular_price": "20.00"}, {"id": 102, "regular_price": "30.00"}]
        """
        let batchResponse = #"{"update": [{"id": 101}, {"id": 102}]}"#
        let client = MockWCRESTClient(responses: [
            StubResponses.ok("[\(probe)]"),
            StubResponses.ok(variationsList),
            StubResponses.ok(batchResponse)
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 50, "scope": "all_variations"}, "sale_price": "9.99"}]}"#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        let variations = updatedTargets(receipt).filter { $0.kind == "variation" }
        #expect(Set(variations.map(\.id)) == [101, 102])
        #expect(variations.allSatisfy { $0.parentID == 50 })
        #expect(updatedProductIDs(receipt).isEmpty)
    }

    @Test(arguments: [
        ("status", "draft"),
        ("name", "New Tee")
    ])
    func test_update_when_variable_parent_only_field_set_then_applied_to_parent_in_products_batch(jsonKey: String, value: String) async throws {
        // Given
        let probe = #"{"id": 50, "type": "variable"}"#
        let batchResponse = "{\"update\": [{\"id\": 50, \"\(jsonKey)\": \"\(value)\"}]}"
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc/v3/products": StubResponses.ok("[\(probe)]"),
            "POST wc/v3/products/batch": StubResponses.ok(batchResponse)
        ])
        let tool = ProductsUpdateTool.make()
        let arguments = "{\"updates\": [{\"target\": {\"kind\": \"product\", \"id\": 50}, \"\(jsonKey)\": \"\(value)\"}]}"

        // When
        let result = await tool.executor(arguments, client)

        // Then
        let receipt = try successReceipt(result)
        let calls = await client.calls
        let posts = calls.filter { $0.method == "POST" }
        #expect(posts.count == 1)
        #expect(posts.first?.path == "wc/v3/products/batch")
        let body = try requireBatchBody(posts.first?.body)
        try requireSingleUpdate(body, id: 50, fields: [jsonKey: value])
        #expect(body.first?["stock_status"] == nil)
        #expect(updatedProductIDs(receipt) == [50])
    }

    @Test
    func test_update_when_sku_set_on_variable_parent_then_applied_to_parent_only_not_expanded() async throws {
        // Given
        let probe = #"{"id": 50, "type": "variable"}"#
        let batchResponse = #"{"update": [{"id": 50, "sku": "TEE-PARENT"}]}"#
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc/v3/products": StubResponses.ok("[\(probe)]"),
            "POST wc/v3/products/batch": StubResponses.ok(batchResponse)
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 50}, "sku": "TEE-PARENT"}]}"#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        let calls = await client.calls
        let variationGets = calls.filter { $0.method == "GET" && $0.path == "wc/v3/products/50/variations" }
        #expect(variationGets.isEmpty)
        let posts = calls.filter { $0.method == "POST" }
        #expect(posts.count == 1)
        #expect(posts.first?.path == "wc/v3/products/batch")
        let body = try requireBatchBody(posts.first?.body)
        try requireSingleUpdate(body, id: 50, fields: ["sku": "TEE-PARENT"])
        #expect(updatedProductIDs(receipt) == [50])
    }

    @Test
    func test_update_when_scope_set_on_simple_product_then_applies_normally_without_fanout() async throws {
        // Given
        let probe = #"{"id": 10, "type": "simple", "regular_price": "50.00"}"#
        let batchResponse = #"{"update": [{"id": 10}]}"#
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc/v3/products": StubResponses.ok("[\(probe)]"),
            "POST wc/v3/products/batch": StubResponses.ok(batchResponse)
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 10, "scope": "all_variations"}, "sale_price": "45"}]}"#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        let calls = await client.calls
        #expect(!calls.contains { $0.path == "wc/v3/products/10/variations" })
        let posts = calls.filter { $0.method == "POST" }
        #expect(posts.first?.path == "wc/v3/products/batch")
        #expect(updatedProductIDs(receipt) == [10])
    }

    @Test
    func test_update_when_variable_parent_has_more_than_100_variations_then_refused_with_failed_entry() async throws {
        // Given
        let probe = #"{"id": 50, "type": "variable"}"#
        let variationsList = """
        [{"id": 101, "regular_price": "20.00"}, {"id": 102, "regular_price": "30.00"}]
        """
        let client = MockWCRESTClient(responses: [
            StubResponses.ok("[\(probe)]"),
            StubResponses.ok(variationsList, headers: ["X-WP-TotalPages": "2", "X-WP-Total": "150"])
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 50, "scope": "all_variations"}, "sale_price": "15.00"}]}"#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        let posts = await client.calls.filter { $0.method == "POST" }
        #expect(posts.isEmpty)
        guard case .array(let failed) = receipt["failed"], case .object(let entry) = failed.first else {
            Issue.record("expected failed entry")
            return
        }
        #expect(failed.count == 1)
        #expect(entry["id"] == .int(50))
        if case .string(let reason) = entry["reason"] {
            #expect(reason.contains("more than 100 variations"))
            #expect(reason.contains("inconsistent"))
            #expect(reason.contains("specific variation ids"))
        } else {
            Issue.record("expected reason string")
        }
        #expect(updatedTargets(receipt).isEmpty)
    }

    @Test
    func test_planVariableParent_when_full_page_and_no_total_pages_header_then_refused_as_unsafe() async throws {
        // Given
        let probe = #"{"id": 50, "type": "variable"}"#
        let rows = (1...100).map { #"{"id": \#($0), "regular_price": "20.00"}"# }.joined(separator: ",")
        let variationsList = "[\(rows)]"
        let client = MockWCRESTClient(responses: [
            StubResponses.ok("[\(probe)]"),
            StubResponses.ok(variationsList)
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 50, "scope": "all_variations"}, "sale_price": "15.00"}]}"#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        let posts = await client.calls.filter { $0.method == "POST" }
        #expect(posts.isEmpty)
        guard case .array(let failed) = receipt["failed"], case .object(let entry) = failed.first else {
            Issue.record("expected failed entry")
            return
        }
        #expect(entry["id"] == .int(50))
        if case .string(let reason) = entry["reason"] {
            #expect(reason.contains("more than 100 variations"))
        } else {
            Issue.record("expected reason string")
        }
    }

    @Test
    func test_planVariableParent_when_expansion_refused_with_parent_only_field_then_refuses_entire_entry() async throws {
        // Given
        let probe = #"{"id": 50, "type": "variable"}"#
        let variationsList = """
        [{"id": 101, "regular_price": "20.00"}, {"id": 102, "regular_price": "30.00"}]
        """
        let client = MockWCRESTClient(responses: [
            StubResponses.ok("[\(probe)]"),
            StubResponses.ok(variationsList, headers: ["X-WP-TotalPages": "2", "X-WP-Total": "150"])
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"""
            {"updates": [{
              "target": {"kind": "product", "id": 50, "scope": "all_variations"},
              "name": "Renamed", "percent_discount": 10
            }]}
            """#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        let posts = await client.calls.filter { $0.method == "POST" }
        #expect(posts.isEmpty)
        guard case .array(let failed) = receipt["failed"], case .object(let entry) = failed.first else {
            Issue.record("expected failed entry")
            return
        }
        #expect(failed.count == 1)
        #expect(entry["id"] == .int(50))
        if case .string(let reason) = entry["reason"] {
            #expect(reason.contains("parent-only fields"))
            #expect(reason.contains("per-variation"))
            #expect(reason.contains("two separate updates"))
        } else {
            Issue.record("expected reason string")
        }
        #expect(updatedTargets(receipt).isEmpty)
    }

    @Test
    func test_planVariableParent_when_expansion_refused_with_no_parent_only_field_then_returns_expansion_refusal_only() async throws {
        // Given
        let probe = #"{"id": 50, "type": "variable"}"#
        let variationsList = """
        [{"id": 101, "regular_price": "20.00"}]
        """
        let client = MockWCRESTClient(responses: [
            StubResponses.ok("[\(probe)]"),
            StubResponses.ok(variationsList, headers: ["X-WP-TotalPages": "2"])
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"{"updates": [{"target": {"kind": "product", "id": 50, "scope": "all_variations"}, "sale_price": "9.99"}]}"#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        let posts = await client.calls.filter { $0.method == "POST" }
        #expect(posts.isEmpty)
        guard case .array(let failed) = receipt["failed"], case .object(let entry) = failed.first else {
            Issue.record("expected failed entry")
            return
        }
        #expect(entry["id"] == .int(50))
        if case .string(let reason) = entry["reason"] {
            #expect(reason.contains("more than 100 variations"))
        } else {
            Issue.record("expected reason string")
        }
        #expect(updatedTargets(receipt).isEmpty)
    }

    @Test
    func test_planVariableParent_when_expansion_succeeds_with_parent_only_field_then_dispatches_both() async throws {
        // Given
        let probe = #"{"id": 50, "type": "variable"}"#
        let variationsList = """
        [{"id": 101, "regular_price": "20.00"}, {"id": 102, "regular_price": "30.00"}]
        """
        let parentBatch = #"{"update": [{"id": 50, "name": "Renamed"}]}"#
        let variationsBatch = #"{"update": [{"id": 101, "sale_price": "18.00"}, {"id": 102, "sale_price": "27.00"}]}"#
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc/v3/products": StubResponses.ok("[\(probe)]"),
            "GET wc/v3/products/50/variations": StubResponses.ok(variationsList),
            "POST wc/v3/products/batch": StubResponses.ok(parentBatch),
            "POST wc/v3/products/50/variations/batch": StubResponses.ok(variationsBatch)
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"""
            {"updates": [{
              "target": {"kind": "product", "id": 50, "scope": "all_variations"},
              "name": "Renamed", "percent_discount": 10
            }]}
            """#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        let posts = await client.calls.filter { $0.method == "POST" }
        #expect(posts.count == 2)
        #expect(updatedProductIDs(receipt) == [50])
        #expect(updatedVariationIDs(receipt) == [101, 102])
    }

    @Test
    func test_update_when_status_combined_with_sale_price_on_variable_parent_then_splits_into_parent_and_variation_writes() async throws {
        // Given
        let probe = #"{"id": 50, "type": "variable"}"#
        let variationsList = """
        [{"id": 101, "regular_price": "20.00"}, {"id": 102, "regular_price": "30.00"}]
        """
        let parentBatch = #"{"update": [{"id": 50, "status": "draft"}]}"#
        let variationsBatch = #"{"update": [{"id": 101, "sale_price": "9.99"}, {"id": 102, "sale_price": "9.99"}]}"#
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc/v3/products": StubResponses.ok("[\(probe)]"),
            "GET wc/v3/products/50/variations": StubResponses.ok(variationsList),
            "POST wc/v3/products/batch": StubResponses.ok(parentBatch),
            "POST wc/v3/products/50/variations/batch": StubResponses.ok(variationsBatch)
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"""
            {"updates": [{
              "target": {"kind": "product", "id": 50, "scope": "all_variations"},
              "status": "draft", "sale_price": "9.99"
            }]}
            """#,
            client
        )

        // Then
        let receipt = try successReceipt(result)
        let posts = await client.calls.filter { $0.method == "POST" }
        #expect(posts.count == 2)
        let parentPost = try #require(posts.first { $0.path == "wc/v3/products/batch" })
        try requireSingleUpdate(try requireBatchBody(parentPost.body), id: 50, fields: ["status": "draft"])
        let variationsPost = try #require(posts.first { $0.path == "wc/v3/products/50/variations/batch" })
        let entriesByID = batchEntriesByID(try requireBatchBody(variationsPost.body))
        #expect(entriesByID[101]?["sale_price"] as? String == "9.99")
        #expect(entriesByID[102]?["sale_price"] as? String == "9.99")
        #expect(updatedProductIDs(receipt) == [50])
        #expect(updatedVariationIDs(receipt) == [101, 102])
    }

    @Test
    func test_update_when_sku_and_percent_discount_set_on_variable_parent_then_parent_gets_sku_and_variations_get_computed_sale_price() async throws {
        // Given
        let probe = #"{"id": 50, "type": "variable"}"#
        let variationsList = """
        [{"id": 101, "regular_price": "20.00"}, {"id": 102, "regular_price": "30.00"}]
        """
        let parentBatch = #"{"update": [{"id": 50, "sku": "TEE-PARENT"}]}"#
        let variationsBatch = #"{"update": [{"id": 101}, {"id": 102}]}"#
        let client = RoutingMockWCRESTClient(routes: [
            "GET wc/v3/products": StubResponses.ok("[\(probe)]"),
            "GET wc/v3/products/50/variations": StubResponses.ok(variationsList),
            "POST wc/v3/products/batch": StubResponses.ok(parentBatch),
            "POST wc/v3/products/50/variations/batch": StubResponses.ok(variationsBatch)
        ])
        let tool = ProductsUpdateTool.make()

        // When
        let result = await tool.executor(
            #"""
            {"updates": [{
              "target": {"kind": "product", "id": 50, "scope": "all_variations"},
              "sku": "TEE-PARENT", "percent_discount": 10
            }]}
            """#,
            client
        )

        // Then
        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        let posts = await client.calls.filter { $0.method == "POST" }
        #expect(posts.count == 2)
        let parentPost = try #require(posts.first { $0.path == "wc/v3/products/batch" })
        try requireSingleUpdate(try requireBatchBody(parentPost.body), id: 50, fields: ["sku": "TEE-PARENT"])
        let variationsPost = try #require(posts.first { $0.path == "wc/v3/products/50/variations/batch" })
        let entriesByID = batchEntriesByID(try requireBatchBody(variationsPost.body))
        #expect(entriesByID[101]?["sale_price"] as? String == "18")
        #expect(entriesByID[102]?["sale_price"] as? String == "27")
        #expect(entriesByID[101]?["sku"] == nil)
        #expect(entriesByID[101]?["percent_discount"] == nil)
    }

    // MARK: Helpers

    private func requireBatchBody(_ body: Data?) throws -> [[String: Any]] {
        let body = try #require(body)
        let parsed = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        let updates = try #require(parsed["update"] as? [[String: Any]])
        return updates
    }

    private func batchEntriesByID(_ entries: [[String: Any]]) -> [Int: [String: Any]] {
        var bucket: [Int: [String: Any]] = [:]
        for entry in entries {
            if let id = entry["id"] as? Int {
                bucket[id] = entry
            }
        }
        return bucket
    }

    private func requireSingleUpdate(_ body: [[String: Any]], id: Int, fields: [String: String]) throws {
        #expect(body.count == 1)
        let entry = try #require(body.first)
        #expect(entry["id"] as? Int == id)
        for (key, value) in fields {
            #expect(entry[key] as? String == value)
        }
    }

    private func updatedTargets(_ receipt: [String: AnyCodableJSON]) -> [(kind: String, id: Int64, parentID: Int64?)] {
        guard case .array(let nodes) = receipt["updated"] else { return [] }
        return nodes.compactMap { node in
            guard case .object(let dict) = node,
                  case .string(let kind)? = dict["kind"],
                  case .int(let id)? = dict["id"] else { return nil }
            var parentID: Int64?
            if case .int(let parent)? = dict["parent_id"] { parentID = parent }
            return (kind, id, parentID)
        }
    }

    private func updatedProductIDs(_ receipt: [String: AnyCodableJSON]) -> Set<Int64> {
        Set(updatedTargets(receipt).filter { $0.kind == "product" }.map(\.id))
    }

    private func updatedVariationIDs(_ receipt: [String: AnyCodableJSON]) -> Set<Int64> {
        Set(updatedTargets(receipt).filter { $0.kind == "variation" }.map(\.id))
    }

    private func successReceipt(_ result: ToolResult) throws -> [String: AnyCodableJSON] {
        guard case .success(let success) = result else {
            Issue.record("expected .success, got \(result)")
            throw TestHelperError.unexpectedShape
        }
        guard case .object(let receipt) = success.structured else {
            Issue.record("expected receipt to be .object, got \(success.structured)")
            throw TestHelperError.unexpectedShape
        }
        return receipt
    }
}

private enum TestHelperError: Error {
    case unexpectedShape
}
