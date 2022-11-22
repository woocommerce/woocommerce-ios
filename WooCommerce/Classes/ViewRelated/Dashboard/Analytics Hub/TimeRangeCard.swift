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
        VStack(spacing: 0) {
            Divider()

            HStack {
                ZStack(alignment: .center) {
                    Circle()
                        .fill(.gray)
                        .frame(width: 48)
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
            .frame(minHeight: 80)

            Divider()

            Text("Compared to **\(previousRangeDescription)**")
                .padding(.leading)
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                .font(.callout)
                .foregroundColor(Color(.textSubtle))

            Divider()
        }
        .background(Color(uiColor: .listForeground))
    }
}

struct TimeRangeCard_Previews: PreviewProvider {
    static var previews: some View {
        let timeRange = AnalyticsHubTimeRange(selectedTimeRange: .thisMonth)
        TimeRangeCard(
            timeRangeTitle: timeRange.selectionType.rawValue,
            currentRangeDescription: timeRange.currentRangeDescription,
            previousRangeDescription: timeRange.previousRangeDescription)
    }
}
