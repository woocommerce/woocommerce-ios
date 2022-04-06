//
//  SiteReviewsViewModel.swift
//  WooCommerce
//
//  Created by César Vargas Casaseca on 5/4/22.
//  Copyright © 2022 Automattic. All rights reserved.
//

import Foundation
import Yosemite

final class SiteReviewsViewModel {
    private let reviewsViewModel: ReviewsViewModelNew

    init(reviewsViewModel: ReviewsViewModelNew) {
        self.reviewsViewModel = reviewsViewModel
    }

    var hasUnreadNotifications: Bool {
        return unreadNotifications.count != 0
    }

    private var unreadNotifications: [Note] {
        return reviewsViewModel.data.notifications.filter { $0.read == false }
    }

    /// Used to check whether the user should be prompted for an app from `ReviewsViewController`
    ///
    var shouldPromptForAppReview: Bool {
        AppRatingManager.shared.shouldPromptForAppReview(section: Constants.section)
    }
}

private extension SiteReviewsViewModel {
    struct Constants {
        static let section = "notifications"
    }
}
