import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct CardReferenceResolverTests {
    @Test
    func test_resolve_when_three_mixed_family_references_then_all_resolved_in_input_order() async {
        // Given
        let client = StubbedWCRESTClient()
        await client.stub(path: "wc/v3/orders",
                    response: StubResponses.ok("[{\"id\": 3551, \"status\": \"processing\", \"total\": \"120.00\"}]"))
        await client.stub(path: "wc/v3/products",
                    response: StubResponses.ok("[{\"id\": 42, \"name\": \"Beanie\", \"price\": \"19.99\", \"stock_status\": \"instock\"}]"))
        await client.stub(path: "wc/v3/customers",
                    response: StubResponses.ok("[{\"id\": 7, \"first_name\": \"Jane\", \"email\": \"jane@example.com\"}]"))
        let resolver = CardReferenceResolver(client: client)
        let references: [CardReference] = [
            CardReference(family: .order, id: "3551"),
            CardReference(family: .product, id: "42"),
            CardReference(family: .customer, id: "7")
        ]

        // When
        let resolutions = await resolver.resolve(references)

        // Then
        #expect(resolutions.count == 3)
        #expect(isResolved(resolutions[0], family: .order, id: "3551"))
        #expect(isResolved(resolutions[1], family: .product, id: "42"))
        #expect(isResolved(resolutions[2], family: .customer, id: "7"))
    }

    @Test
    func test_resolve_when_multiple_orders_then_uses_single_batched_fetch() async {
        // Given
        let client = StubbedWCRESTClient()
        await client.stub(path: "wc/v3/orders",
                    response: StubResponses.ok("""
                    [{"id": 1, "status": "processing", "total": "10.00"},
                     {"id": 2, "status": "processing", "total": "20.00"},
                     {"id": 3, "status": "processing", "total": "30.00"}]
                    """))
        let resolver = CardReferenceResolver(client: client)
        let references = [1, 2, 3].map { CardReference(family: .order, id: String($0)) }

        // When
        let resolutions = await resolver.resolve(references)

        // Then
        #expect(resolutions.count == 3)
        #expect(await client.calls.filter { $0 == "wc/v3/orders" }.count == 1)
    }

    @Test
    func test_resolve_when_eleven_references_then_first_ten_processed_and_overflow_rejected_as_overLimit() async {
        // Given
        let client = StubbedWCRESTClient()
        let rows = (1...10).map { "{\"id\": \($0), \"status\": \"processing\", \"total\": \"10.00\"}" }.joined(separator: ",")
        await client.stub(path: "wc/v3/orders",
                    response: StubResponses.ok("[\(rows)]"))
        let resolver = CardReferenceResolver(client: client)
        let references = (1...11).map { CardReference(family: .order, id: String($0)) }

        // When
        let resolutions = await resolver.resolve(references)

        // Then
        #expect(resolutions.count == 11)
        for index in 0..<10 {
            #expect(isResolved(resolutions[index], family: .order, id: String(index + 1)),
                    "expected resolution \(index) to be resolved")
        }
        if case .rejected(_, _, let reason) = resolutions[10] {
            #expect(reason == .overLimit)
        } else {
            Issue.record("expected overflow to be rejected.overLimit")
        }
    }

    @Test
    func test_resolve_when_same_reference_twice_then_first_resolves_and_second_rejected_as_duplicate() async {
        // Given
        let client = StubbedWCRESTClient()
        await client.stub(path: "wc/v3/orders",
                    response: StubResponses.ok("[{\"id\": 3551, \"status\": \"processing\", \"total\": \"120.00\"}]"))
        let resolver = CardReferenceResolver(client: client)
        let references: [CardReference] = [
            CardReference(family: .order, id: "3551"),
            CardReference(family: .order, id: "3551")
        ]

        // When
        let resolutions = await resolver.resolve(references)

        // Then
        #expect(isResolved(resolutions[0], family: .order, id: "3551"))
        if case .rejected(let family, let id, let reason) = resolutions[1] {
            #expect(family == .order)
            #expect(id == "3551")
            #expect(reason == .duplicate)
        } else {
            Issue.record("expected second to be rejected.duplicate")
        }
        #expect(await client.calls.filter { $0 == "wc/v3/orders" }.count == 1)
    }

    @Test(arguments: ["0", "abc", "-1"])
    func test_resolve_when_id_fails_int64_guard_then_rejects_as_malformed(rawID: String) async {
        // Given
        let client = StubbedWCRESTClient()
        let resolver = CardReferenceResolver(client: client)

        // When
        let resolutions = await resolver.resolve([CardReference(family: .order, id: rawID)])

        // Then
        if case .rejected(_, _, let reason) = resolutions[0] {
            #expect(reason == .malformed)
        } else {
            Issue.record("expected rejected.malformed for id=\(rawID)")
        }
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_resolve_when_id_missing_from_response_then_rejects_as_notFound() async {
        // Given
        let client = StubbedWCRESTClient()
        await client.stub(path: "wc/v3/orders", response: StubResponses.ok("[]"))
        let resolver = CardReferenceResolver(client: client)

        // When
        let resolutions = await resolver.resolve([CardReference(family: .order, id: "9999")])

        // Then
        if case .rejected(_, _, let reason) = resolutions[0] {
            #expect(reason == .notFound)
        } else {
            Issue.record("expected rejected.notFound")
        }
    }

    @Test
    func test_resolve_when_remote_returns_403_then_rejects_all_in_family_as_notPermitted() async {
        // Given
        let client = StubbedWCRESTClient()
        await client.stub(path: "wc/v3/products", response: StubResponses.failure(statusCode: 403))
        let resolver = CardReferenceResolver(client: client)
        let references = [
            CardReference(family: .product, id: "1"),
            CardReference(family: .product, id: "2")
        ]

        // When
        let resolutions = await resolver.resolve(references)

        // Then
        for index in 0..<2 {
            if case .rejected(_, _, let reason) = resolutions[index] {
                #expect(reason == .notPermitted)
            } else {
                Issue.record("expected rejected.notPermitted at slot \(index)")
            }
        }
    }

    @Test
    func test_resolve_when_entity_status_trash_then_rejects_as_staleReference() async {
        // Given
        let client = StubbedWCRESTClient()
        await client.stub(path: "wc/v3/orders",
                    response: StubResponses.ok("[{\"id\": 3551, \"status\": \"trash\"}]"))
        let resolver = CardReferenceResolver(client: client)

        // When
        let resolutions = await resolver.resolve([CardReference(family: .order, id: "3551")])

        // Then
        if case .rejected(_, _, let reason) = resolutions[0] {
            #expect(reason == .staleReference)
        } else {
            Issue.record("expected rejected.staleReference")
        }
    }

    @Test
    func test_resolve_when_remote_returns_410_then_rejects_as_staleReference() async {
        // Given
        let client = StubbedWCRESTClient()
        await client.stub(path: "wc/v3/orders", response: StubResponses.failure(statusCode: 410))
        let resolver = CardReferenceResolver(client: client)

        // When
        let resolutions = await resolver.resolve([CardReference(family: .order, id: "3551")])

        // Then
        if case .rejected(_, _, let reason) = resolutions[0] {
            #expect(reason == .staleReference)
        } else {
            Issue.record("expected rejected.staleReference")
        }
    }

    @Test
    func test_resolve_when_remote_returns_500_then_rejects_as_fetchFailed() async {
        // Given
        let client = StubbedWCRESTClient()
        await client.stub(path: "wc/v3/orders", response: StubResponses.failure(statusCode: 500))
        let resolver = CardReferenceResolver(client: client)

        // When
        let resolutions = await resolver.resolve([CardReference(family: .order, id: "1")])

        // Then
        if case .rejected(_, _, let reason) = resolutions[0] {
            #expect(reason == .fetchFailed)
        } else {
            Issue.record("expected rejected.fetchFailed")
        }
    }

    @Test
    func test_resolve_when_response_is_unparseable_then_rejects_as_internalError() async {
        // Given
        let client = StubbedWCRESTClient()
        await client.stub(path: "wc/v3/orders", response: StubResponses.ok("not json at all"))
        let resolver = CardReferenceResolver(client: client)

        // When
        let resolutions = await resolver.resolve([CardReference(family: .order, id: "1")])

        // Then
        if case .rejected(_, _, let reason) = resolutions[0] {
            #expect(reason == .internalError)
        } else {
            Issue.record("expected rejected.internalError")
        }
    }

    @Test
    func test_resolve_when_mixed_resolved_and_rejected_then_preserves_input_order() async {
        // Given
        let client = StubbedWCRESTClient()
        await client.stub(path: "wc/v3/orders",
                    response: StubResponses.ok("[{\"id\": 3551, \"status\": \"processing\", \"total\": \"120.00\"}]"))
        let resolver = CardReferenceResolver(client: client)
        let references: [CardReference] = [
            CardReference(family: .order, id: "3551"),
            CardReference(family: .order, id: "9999"),
            CardReference(family: .order, id: "3551")
        ]

        // When
        let resolutions = await resolver.resolve(references)

        // Then
        #expect(isResolved(resolutions[0], family: .order, id: "3551"))
        if case .rejected(_, _, let reason) = resolutions[1] {
            #expect(reason == .notFound)
        } else {
            Issue.record("expected slot 1 to be rejected.notFound")
        }
        if case .rejected(_, _, let reason) = resolutions[2] {
            #expect(reason == .duplicate)
        } else {
            Issue.record("expected slot 2 to be rejected.duplicate")
        }
    }

    @Test
    func test_resolve_when_product_variation_reference_then_resolves() async {
        // Given
        let client = StubbedWCRESTClient()
        await client.stub(path: "wc/v3/products/821/variations/822",
                    response: StubResponses.ok("""
                    {"id": 822, "name": "Black", "sku": "BNY-BLK", "price": "74.99",
                     "stock_status": "instock", "parent_id": 821, "status": "publish"}
                    """))
        let resolver = CardReferenceResolver(client: client)
        let references = [CardReference(family: .productVariation, id: "822", parentID: "821")]

        // When
        let resolutions = await resolver.resolve(references)

        // Then
        #expect(resolutions.count == 1)
        guard case .resolved(let family, let id, let summary, let rendered) = resolutions[0] else {
            Issue.record("expected resolved, got \(resolutions[0])")
            return
        }
        #expect(family == .productVariation)
        #expect(id == "822")
        if case .object(let fields) = summary {
            #expect(fields["id"] == .int(822))
            #expect(fields["name"] == .string("Black"))
            #expect(fields["price"] == .string("74.99"))
            #expect(fields["parent_id"] == .int(821))
        } else {
            Issue.record("expected object summary")
        }
        #expect(rendered.family == .productVariation)
        #expect(rendered.id == "822")
    }

    @Test
    func test_resolve_when_product_variation_missing_parent_id_then_malformed() async {
        // Given
        let client = StubbedWCRESTClient()
        let resolver = CardReferenceResolver(client: client)
        let references = [CardReference(family: .productVariation, id: "822", parentID: nil)]

        // When
        let resolutions = await resolver.resolve(references)

        // Then
        if case .rejected(let family, let id, let reason) = resolutions[0] {
            #expect(family == .productVariation)
            #expect(id == "822")
            #expect(reason == .malformed)
        } else {
            Issue.record("expected rejected.malformed")
        }
        #expect(await client.calls.isEmpty)
    }

    @Test(arguments: ["abc", "0", "-1"])
    func test_resolve_when_product_variation_non_numeric_parent_id_then_malformed(rawParent: String) async {
        // Given
        let client = StubbedWCRESTClient()
        let resolver = CardReferenceResolver(client: client)
        let references = [CardReference(family: .productVariation, id: "822", parentID: rawParent)]

        // When
        let resolutions = await resolver.resolve(references)

        // Then
        if case .rejected(_, _, let reason) = resolutions[0] {
            #expect(reason == .malformed)
        } else {
            Issue.record("expected rejected.malformed for parent_id=\(rawParent)")
        }
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_resolve_when_product_variation_remote_returns_404_then_rejects_as_notFound() async {
        // Given
        let client = StubbedWCRESTClient()
        await client.stub(path: "wc/v3/products/821/variations/9999",
                    response: StubResponses.failure(statusCode: 404))
        let resolver = CardReferenceResolver(client: client)
        let references = [CardReference(family: .productVariation, id: "9999", parentID: "821")]

        // When
        let resolutions = await resolver.resolve(references)

        // Then
        if case .rejected(_, _, let reason) = resolutions[0] {
            #expect(reason == .notFound)
        } else {
            Issue.record("expected rejected.notFound")
        }
    }

    @Test
    func test_resolve_when_variation_response_omits_parent_id_then_summary_and_rendered_carry_requested_parent() async {
        // Given
        let client = StubbedWCRESTClient()
        await client.stub(path: "wc/v3/products/12/variations/841",
                    response: StubResponses.ok("""
                    {"id": 841, "name": "Black", "sku": "BNY-BLK", "price": "74.99",
                     "regular_price": "74.99", "sale_price": "", "stock_quantity": 5,
                     "stock_status": "instock", "status": "publish",
                     "attributes": [{"id": 1, "name": "Color", "option": "Black"}]}
                    """))
        let resolver = CardReferenceResolver(client: client)
        let references = [CardReference(family: .productVariation, id: "841", parentID: "12")]

        // When
        let resolutions = await resolver.resolve(references)

        // Then
        guard case .resolved(_, _, let summary, let rendered) = resolutions[0] else {
            Issue.record("expected resolved, got \(resolutions[0])")
            return
        }
        if case .object(let fields) = summary {
            #expect(fields["parent_id"] == .int(12))
        } else {
            Issue.record("expected object summary")
        }
        if case .object(let element) = rendered.element {
            #expect(element["parent_id"] == .int(12))
        } else {
            Issue.record("expected rendered.element to be an object carrying parent_id")
        }
    }

    @Test
    func test_resolve_when_two_product_variations_then_each_uses_nested_path() async {
        // Given
        let client = StubbedWCRESTClient()
        await client.stub(path: "wc/v3/products/821/variations/822",
                    response: StubResponses.ok("""
                    {"id": 822, "name": "Black", "price": "74.99", "stock_status": "instock", "parent_id": 821}
                    """))
        await client.stub(path: "wc/v3/products/821/variations/823",
                    response: StubResponses.ok("""
                    {"id": 823, "name": "White", "price": "79.99", "stock_status": "instock", "parent_id": 821}
                    """))
        let resolver = CardReferenceResolver(client: client)
        let references = [
            CardReference(family: .productVariation, id: "822", parentID: "821"),
            CardReference(family: .productVariation, id: "823", parentID: "821")
        ]

        // When
        let resolutions = await resolver.resolve(references)

        // Then
        #expect(resolutions.count == 2)
        #expect(isResolved(resolutions[0], family: .productVariation, id: "822"))
        #expect(isResolved(resolutions[1], family: .productVariation, id: "823"))
        let calls = await client.calls
        #expect(calls.contains("wc/v3/products/821/variations/822"))
        #expect(calls.contains("wc/v3/products/821/variations/823"))
    }

    @Test
    func test_resolve_when_analytics_revenue_reference_then_dispatches_to_revenue_stats_path() async {
        // Given
        let body = """
        {"totals":{"net_revenue":"123.45"},
         "intervals":[{"interval":"2026-04-01","date_start":"2026-04-01 00:00:00",
                       "subtotals":{"net_revenue":"50.00"}}]}
        """
        let client = StubbedWCRESTClient()
        await client.stub(path: "wc-analytics/reports/revenue/stats", response: StubResponses.ok(body))
        let resolver = CardReferenceResolver(client: client)
        let analyticsID = "analytics_revenue:after:2026-04-01:before:2026-04-30:interval:day:currency:none"
        let references = [CardReference(family: .analyticsStats, id: analyticsID)]

        // When
        let resolutions = await resolver.resolve(references)

        // Then
        guard case .resolved(let family, let id, let summary, let rendered) = resolutions[0] else {
            Issue.record("expected resolved, got \(resolutions[0])")
            return
        }
        #expect(family == .analyticsStats)
        #expect(id == analyticsID)
        guard case .object(let fields) = summary else {
            Issue.record("expected object summary")
            return
        }
        // Per-bucket data is rendered-only; the model-visible summary keeps
        // just the projection keys so a year-by-day query doesn't blow the
        // model context.
        #expect(Set(fields.keys) == Set(["after", "before", "interval", "totals"]))
        #expect(fields["interval_subtotals"] == nil)
        #expect(fields["interval_count"] == nil)
        #expect(rendered.family == .analyticsStats)
        #expect(rendered.id == analyticsID)
        // Rendered card payload still carries the per-bucket data the chart needs.
        guard case .object(let renderedFields) = rendered.element else {
            Issue.record("expected object rendered.element")
            return
        }
        #expect(renderedFields["interval_count"] == .int(1))
        #expect(renderedFields["interval_subtotals"] != nil)
    }

    @Test
    func test_resolve_when_analytics_id_is_malformed_then_rejects_without_calling_client() async {
        // Given
        let client = StubbedWCRESTClient()
        let resolver = CardReferenceResolver(client: client)
        let references = [
            CardReference(family: .analyticsStats,
                          id: "analytics_revenue:after:not-a-date:before:2026-04-30:interval:day:currency:none")
        ]

        // When
        let resolutions = await resolver.resolve(references)

        // Then
        if case .rejected(let family, _, let reason) = resolutions[0] {
            #expect(family == .analyticsStats)
            #expect(reason == .malformed)
        } else {
            Issue.record("expected rejected.malformed")
        }
        #expect(await client.calls.isEmpty)
    }

    @Test
    func test_resolve_when_mixed_entity_and_analytics_references_then_runs_both_in_parallel_preserving_order() async {
        // Given
        let client = StubbedWCRESTClient()
        await client.stub(path: "wc/v3/orders",
                          response: StubResponses.ok("[{\"id\": 3551, \"status\": \"processing\", \"total\": \"120.00\"}]"))
        await client.stub(path: "wc-analytics/reports/orders/stats",
                          response: StubResponses.ok(#"{"totals":{"orders_count":7},"intervals":[]}"#))
        let resolver = CardReferenceResolver(client: client)
        let analyticsID = "analytics_orders:after:2026-04-01:before:2026-04-30:interval:day:currency:none"
        let references = [
            CardReference(family: .order, id: "3551"),
            CardReference(family: .analyticsStats, id: analyticsID)
        ]

        // When
        let resolutions = await resolver.resolve(references)

        // Then
        #expect(resolutions.count == 2)
        #expect(isResolved(resolutions[0], family: .order, id: "3551"))
        #expect(isResolved(resolutions[1], family: .analyticsStats, id: analyticsID))
    }

    @Test
    func test_resolve_when_analytics_endpoint_returns_500_then_rejects_as_fetchFailed() async {
        // Given
        let client = StubbedWCRESTClient()
        await client.stub(path: "wc-analytics/reports/revenue/stats",
                          response: StubResponses.failure(statusCode: 500))
        let resolver = CardReferenceResolver(client: client)
        let analyticsID = "analytics_revenue:after:2026-04-01:before:2026-04-30:interval:day:currency:none"
        let references = [CardReference(family: .analyticsStats, id: analyticsID)]

        // When
        let resolutions = await resolver.resolve(references)

        // Then
        if case .rejected(let family, let id, let reason) = resolutions[0] {
            #expect(family == .analyticsStats)
            #expect(id == analyticsID)
            #expect(reason == .fetchFailed)
        } else {
            Issue.record("expected rejected.fetchFailed")
        }
    }

    private func isResolved(_ resolution: Resolution, family: CardFamilyID, id: String) -> Bool {
        if case .resolved(let resolvedFamily, let resolvedID, _, _) = resolution {
            return resolvedFamily == family && resolvedID == id
        }
        return false
    }
}
