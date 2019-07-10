//
//  OrderStatsV4+CoreDataProperties.swift
//  
//
//  Created by Cesar Tardaguila on 10/7/2019.
//
//

import Foundation
import CoreData


extension OrderStatsV4 {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderStatsV4> {
        return NSFetchRequest<OrderStatsV4>(entityName: "OrderStatsV4")
    }

    @NSManaged public var totals: OrderStatsV4Totals?

}
