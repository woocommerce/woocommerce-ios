//
//  NotificationViewController.swift
//  NotificationExtension
//
//  Created by Ernesto Carrion on 4/09/23.
//  Copyright © 2023 Automattic. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet var label: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
    }

    func didReceive(_ notification: UNNotification) {
        self.label?.text = notification.request.content.userInfo.description
    }

}
