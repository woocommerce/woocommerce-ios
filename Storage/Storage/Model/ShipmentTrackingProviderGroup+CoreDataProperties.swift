//
//  ShipmentTrackingProviderGroup+CoreDataProperties.swift
//  Storage
//
//  Created by Cesar Tardaguila on 14/3/2019.
//  Copyright © 2019 Automattic. All rights reserved.
//
import Foundation
import CoreData


extension ShipmentTrackingProviderGroup {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShipmentTrackingProviderGroup> {
        return NSFetchRequest<ShipmentTrackingProviderGroup>(entityName: "ShipmentTrackingProviderGroup")
    }

    @NSManaged public var name: String?
    @NSManaged public var providers: NSSet?

}

// MARK: Generated accessors for providers
extension ShipmentTrackingProviderGroup {

    @objc(addProvidersObject:)
    @NSManaged public func addToProviders(_ value: ShipmentTrackingProvider)

    @objc(removeProvidersObject:)
    @NSManaged public func removeFromProviders(_ value: ShipmentTrackingProvider)

    @objc(addProviders:)
    @NSManaged public func addToProviders(_ values: NSSet)

    @objc(removeProviders:)
    @NSManaged public func removeFromProviders(_ values: NSSet)

}
