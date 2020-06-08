//
//  TodayViewController.swift
//  TodayStatsWidget
//
//  Created by Paolo Musolino on 08/06/2020.
//  Copyright © 2020 Automattic. All rights reserved.
//

import UIKit
import NotificationCenter

final class TodayViewController: UIViewController, NCWidgetProviding {
        
    @IBOutlet private weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
        
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
}
