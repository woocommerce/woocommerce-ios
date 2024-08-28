//
//  POSTextButtonStyle.swift
//  WooCommerce
//
//  Created by Josh Heald on 28/08/2024.
//  Copyright © 2024 Automattic. All rights reserved.
//

import SwiftUI

struct POSTextButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.posBodyRegular)
            .contentShape(Rectangle())
            .foregroundColor(foregroundColor(for: configuration))
            .background(Color(.clear))
    }

    private func foregroundColor(for configuration: Configuration) -> Color {
        if isEnabled {
            return configuration.isPressed ? .posTextButtonForegroundPressed : .posTextButtonForeground
        } else {
            return .posTextButtonDisabled
        }
    }
}
