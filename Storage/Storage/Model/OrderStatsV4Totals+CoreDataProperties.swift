//
//  OrderStatsV4Totals+CoreDataProperties.swift
//  Storage
//
//  Created by Cesar Tardaguila on 10/7/2019.
//  Copyright © 2019 Automattic. All rights reserved.
//
//

import Foundation
import CoreData


extension OrderStatsV4Totals {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderStatsV4Totals> {
        return NSFetchRequest<OrderStatsV4Totals>(entityName: "OrderStatsV4Totals")
    }

    @NSManaged public var orders: Int64
    @NSManaged public var itemsSold: Int64
    @NSManaged public var grossRevenue: Double
    @NSManaged public var couponDiscount: Double
    @NSManaged public var coupons: Int64
    @NSManaged public var refunds: Double
    @NSManaged public var taxes: Double
    @NSManaged public var shipping: Double
    @NSManaged public var netRevenue: Double
    @NSManaged public var products: Int64
    @NSManaged public var interval: OrderStatsV4Interval?
    @NSManaged public var stats: OrderStatsV4?

}
