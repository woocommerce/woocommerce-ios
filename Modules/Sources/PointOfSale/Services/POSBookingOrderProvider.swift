// POSBookingOrderProvider.swift
import Foundation
import Yosemite

/// Order provider for booking payments that fetches orders via the order service
public final class POSBookingOrderProvider: POSOrderProviding {
    private let orderService: POSOrderServiceProtocol

    public init(orderService: POSOrderServiceProtocol) {
        self.orderService = orderService
    }

    public func fetchOrder(siteID: Int64, orderID: Int64) async throws -> Order {
        // siteID is ignored because the order service already knows its siteID
        try await orderService.fetchOrder(orderID: orderID)
    }
}
