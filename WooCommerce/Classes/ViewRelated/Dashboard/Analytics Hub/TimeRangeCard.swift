//
//  TimeRangeCard.swift
//  WooCommerce
//
//  Created by Thomaz F B Cortez on 22/11/22.
//  Copyright © 2022 Automattic. All rights reserved.
//

import SwiftUI

struct TimeRangeCard: View {

    let timeRangeTitle: String
    let currentRangeDescription: String
    let previousRangeDescription: String

    var body: some View {
        VStack(alignment: .leading) {
            Divider()

            HStack {
                ZStack(alignment: .center) {
                    Circle()
                        .fill(.gray)
                        .frame(width: Layout.calendarCircleWidth)
                    Image(uiImage: .calendar)
                }
                VStack(alignment: .leading, spacing: .zero) {
                    Text(timeRangeTitle)
                        .foregroundColor(Color(.text))
                        .subheadlineStyle()
                    Text(currentRangeDescription)
                        .bold()
                }
                .padding(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading)
            .frame(minHeight: Layout.selectedRangeMinHeight)

            Divider()

            Text("Compared to **\(previousRangeDescription)**")
                .padding(.leading)
                .frame(maxWidth: .infinity, minHeight: Layout.previousRangeMinHeight, alignment: .leading)
                .font(.callout)
                .foregroundColor(Color(.textSubtle))

            Divider()
        }
        .background(Color(uiColor: .listForeground))
    }
}

private extension TimeRangeCard {
    enum Layout {
        static let calendarCircleWidth: CGFloat = 48
        static let selectedRangeMinHeight: CGFloat = 72
        static let previousRangeMinHeight: CGFloat = 32
    }
}

struct TimeRangeCard_Previews: PreviewProvider {
    static var previews: some View {
        let timeRange = AnalyticsHubTimeRange(selectedTimeRange: .thisMonth)
        TimeRangeCard(
            timeRangeTitle: timeRange.selectionType.rawValue,
            currentRangeDescription: timeRange.currentRangeDescription, previousRangeDescription: timeRange.previousRangeDescription)
    }
}
