# NotificationServiceExtension

This framework enables us to unit test the service extension logic, which is the modified notification content. To support multi-store push notifications, we are modifying the notification content given the payload from the server to show more details about the notification. In the future, this framework also allows to support unit-testable richer notifications.

// TODO-5032: once the server-side implementation is finalized and deployed, more details about the payload format and notification content will be shared here.

## Dependencies

- [Experiments framework](EXPERIMENTS.md)

![Service extension dependency diagram](images/notification-service-extension-frameworks.png)

The tests also depend on:

- TestKit

## Public interfaces

- Class `NotificationService: UNNotificationServiceExtension`: the extension can call the functions from this class in its own `UNNotificationServiceExtension` subclass. At the moment, we cannot set a `UNNotificationServiceExtension` subclass from a different framework inside a notification service extension (Info.plist's `NSExtensionPrincipalClass` field).
