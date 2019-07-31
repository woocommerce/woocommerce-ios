import Foundation
import Networking
import Storage



// MARK: - Exported ReadOnly Symbols

public typealias Account = Networking.Account
public typealias AccountSettings = Networking.AccountSettings
public typealias Address = Networking.Address
public typealias APNSDevice = Networking.APNSDevice
public typealias CommentStatus = Networking.CommentStatus
public typealias Credentials = Networking.Credentials
public typealias DotcomDevice = Networking.DotcomDevice
public typealias MetaContainer = Networking.MetaContainer
public typealias Note = Networking.Note
public typealias NoteBlock = Networking.NoteBlock
public typealias NoteMedia = Networking.NoteMedia
public typealias NoteRange = Networking.NoteRange
public typealias Order = Networking.Order
public typealias OrderCount = Networking.OrderCount
public typealias OrderCountItem = Networking.OrderCountItem
public typealias OrderItem = Networking.OrderItem
public typealias OrderStatusEnum = Networking.OrderStatusEnum
public typealias OrderCouponLine = Networking.OrderCouponLine
public typealias OrderNote = Networking.OrderNote
public typealias OrderStats = Networking.OrderStats
public typealias OrderStatsItem = Networking.OrderStatsItem
public typealias OrderStatsV4 = Networking.OrderStatsV4
public typealias OrderStatsV4Interval = Networking.OrderStatsV4Interval
public typealias OrderStatsV4Totals = Networking.OrderStatsV4Totals
public typealias OrderStatus = Networking.OrderStatus
public typealias Product = Networking.Product
public typealias ProductStatus = Networking.ProductStatus
public typealias ProductStockStatus = Networking.ProductStockStatus
public typealias ProductType = Networking.ProductType
public typealias ProductCategory = Networking.ProductCategory
public typealias ProductTag = Networking.ProductTag
public typealias ProductImage = Networking.ProductImage
public typealias ProductAttribute = Networking.ProductAttribute
public typealias ProductDimensions = Networking.ProductDimensions
public typealias ProductDefaultAttribute = Networking.ProductDefaultAttribute
public typealias ProductDownload = Networking.ProductDownload
public typealias StatGranularity = Networking.StatGranularity
public typealias StatsGranularityV4 = Networking.StatsGranularityV4
public typealias ShipmentTracking = Networking.ShipmentTracking
public typealias ShipmentTrackingProvider = Networking.ShipmentTrackingProvider
public typealias ShipmentTrackingProviderGroup = Networking.ShipmentTrackingProviderGroup
public typealias Site = Networking.Site
public typealias SiteAPI = Networking.SiteAPI
public typealias SiteSetting = Networking.SiteSetting
public typealias SiteSettingGroup = Networking.SiteSettingGroup
public typealias SiteVisitStats = Networking.SiteVisitStats
public typealias SiteVisitStatsItem = Networking.SiteVisitStatsItem
public typealias TopEarnerStats = Networking.TopEarnerStats
public typealias TopEarnerStatsItem = Networking.TopEarnerStatsItem
public typealias WooAPIVersion = Networking.WooAPIVersion


// MARK: - Exported Storage Symbols

public typealias StorageAccount = Storage.Account
public typealias StorageNote = Storage.Note
public typealias StorageOrder = Storage.Order
public typealias StorageOrderNote = Storage.OrderNote
public typealias StorageOrderStats = Storage.OrderStats
public typealias StorageOrderStatsItem = Storage.OrderStatsItem
public typealias StorageOrderStatus = Storage.OrderStatus
public typealias StoragePreselectedProvider = Storage.PreselectedProvider
public typealias StorageProduct = Storage.Product
public typealias StorageProductDimensions = Storage.ProductDimensions
public typealias StorageProductAttribute = Storage.ProductAttribute
public typealias StorageProductImage = Storage.ProductImage
public typealias StorageProductCategory = Storage.ProductCategory
public typealias StorageProductDefaultAttribute = Storage.ProductDefaultAttribute
public typealias StorageProductDownload = Storage.ProductDownload
public typealias StorageProductTag = Storage.ProductTag
public typealias StorageShipmentTracking = Storage.ShipmentTracking
public typealias StorageShipmentTrackingProvider = Storage.ShipmentTrackingProvider
public typealias StorageShipmentTrackingProviderGroup = Storage.ShipmentTrackingProviderGroup
public typealias StorageSite = Storage.Site
public typealias StorageSiteSetting = Storage.SiteSetting
public typealias StorageSiteVisitStats = Storage.SiteVisitStats
public typealias StorageSiteVisitStatsItem = Storage.SiteVisitStatsItem
public typealias StorageTopEarnerStats = Storage.TopEarnerStats
public typealias StorageTopEarnerStatsItem = Storage.TopEarnerStatsItem
