//
//  OrderStatsV4Interval+CoreDataProperties.swift
//  Storage
//
//  Created by Cesar Tardaguila on 10/7/2019.
//  Copyright © 2019 Automattic. All rights reserved.
//
//

import Foundation
import CoreData


extension OrderStatsV4Interval {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderStatsV4Interval> {
        return NSFetchRequest<OrderStatsV4Interval>(entityName: "OrderStatsV4Interval")
    }

    @NSManaged public var interval: String?
    @NSManaged public var dateStart: String?
    @NSManaged public var dateEnd: String?
    @NSManaged public var subtotals: OrderStatsV4Totals?
    @NSManaged public var stats: OrderStatsV4?

}
