//
//  WooShippingPaymentMethodLine.swift
//  WooCommerce
//
//  Created by Rafael Kayumov on 11.05.2025.
//  Copyright © 2025 Automattic. All rights reserved.
//

/// Represents payment method line in the order details bottom sheet.
enum WooShippingPaymentMethodLine {
    case add
    case card(CardPaymentMethodLineViewModel)

    struct CardPaymentMethodLineViewModel {
        let id: String
        let title: String
        let isEditable: Bool
    }
}
