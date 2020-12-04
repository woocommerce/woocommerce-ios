# Architecture Overview


WooCommerce iOS's architecture is the result of a **massive team effort** which involves lots of brainstorming sessions, extremely fun
coding rounds, and most of all: the sum of past experiences on the platform.

The goal of the current document is to discuss several principles that strongly influenced our current architecture approach, along with providing
details on how each one of the layers work internally.




## **Design Principles**

Throughout the entire architecture design process, we've priorized several key concepts which guided us all the way:


1.  **Do NOT Reinvent the Wheel**

        Our main goal is to exploit as much as possible all of the things the platform already offers through its SDK,
        for obvious reasons.

        The -non extensive- list of tools we've built upon include: [CoreData, NotificationCenter, KVO]


2.  **Separation of concerns**

        We've emphasized a clean separation of concerns at the top level, by splitting our app into four targets:

        1.  Storage.framework:
            Wraps up all of the actual CoreData interactions, and exposes a framework-agnostic Public API.

        2.  Networking.framework:
            In charge of providing a Swift API around the WooCommerce REST Endpoints.

        3.  Yosemite.framework:
            Encapsulates our Business Logic: is in charge of interacting with the Storage and Networking layers.

        4.  WooCommerce:
            Our main target, which is expected to **only** interact with the entire stack thru the Yosemite.framework.


3.  **Immutability**

        For a wide variety of reasons, we've opted for exposing Mutable Entities **ONLY** to our Service Layer (Yosemite.framework).
        The main app's ViewControllers can gain access to [Remote, Cached] Entities only through ReadOnly instances.

        (A) Thread Safe: We're shielded from known CoreData Threading nightmares
        (B) A valid object will always remain valid. This is not entirely true with plain NSManagedObjects!
        (C) Enforces, at the compiler level, not to break the architecture.


4.  **Testability**

        Every class in the entire stack (Storage / Networking / Services) has been designed with testability in mind.
        This enabled us to test every single key aspect, without requiring third party tools to do so.


5.  **Keeping it Simple**

        Compact code is amazing. But readable code is even better. Anything and everything must be easy to understand
        by everyone, including the committer, at a future time.




## **Storage.framework**

CoreData interactions are contained within the Storage framework. A set of protocols has been defined, which would, in theory, allow us to
replace CoreData with any other database. Key notes:


1.  **CoreDataManager**

        In charge of bootstrapping the entire CoreData stack: contains a NSPersistentContainer instance, and
        is responsible for loading both the Data Model and the actual `.sqlite` file.

2.  **StorageManagerType**

        Defines the public API that's expected to be conformed by any actual implementation that intends to contain
        and grant access to StorageType instances.

        **Conformed by CoreDataManager.**

3.  **StorageType**

        Defines a set of framework-agnostic API's for CRUD operations over collections of Objects.
        Every instance of this type is expected to be associated with a particular GCD Queue (Thread).

        **Conformed by NSManagedObjectContext**

4.  **Object**

        Defines required methods / properties, to be implemented by Stored Objects.

        **Conformed by NSManagedObject.**

5.  **StorageType+Extensions**

        The extension `StorageType+Extensions` defines a set of convenience methods, aimed at easing out WC specific
        tasks (such as: `loadOrder(orderID:)`).




## **Networking.framework**

Our Networking framework offers a Swift API around the WooCommerce's RESTful endpoints. In this section we'll do a walkthru around several
key points.

More on [Networking](NETWORKING.md)

### Model Entities

ReadOnly Model Entities live at the Networking Layer level. This effectively translates into: **none** of the Models at this level is expected to have
even a single mutable property.

Each one of the concrete structures conforms to Swift's  `Decodable`  protocol, which is heavily used for JSON Parsing purposes.



### Parsing Model Entities!

In order to maximize separation of concerns, parsing backend responses into Model Entities is expected to be performed (only) by means of
a  concrete `Mapper` implementation:

    ```
    protocol Mapper {
        associatedtype Output
        func map(response: Data) throws -> Output
    }
    ```

Since our Model entities conform to `Decodable`, this results in small-footprint-mappers, along with clean and compact Unit Tests.



### Network Access

The networking layer is **entirely decoupled** from third party frameworks. We rely upon component injection to actually perform network requests:

1.  **NetworkType**

        Defines a set of API's, to be implemented by any class that offers actual Network Access.

2.  **AlamofireNetwork**

        Thin wrapper around the Alamofire library.

3.  **MockNetwork**

        As the name implies, the Mock Network is extensively used in Unit Tests. Allows us to simulate backend
        responses without requiring third party tools. No more NSURLSession swizzling!



### Building Requests

Rather than building URL instances in multiple spots, we've opted for implementing three core tools, that, once fully initialized, are capable
of performing this task for us:

1.  **DotcomRequest**

        Represents a WordPress.com request. Set the proper API Version, method, path and parameters, and this structure
        will generate a URLRequest for you.

2.  **JetpackRequest**

        Analog to DotcomRequest, this structure represents a Jetpack Endpoint request. Capable of building a ready-to-use
        URLRequest for a "Jetpack Tunneled" endpoint.

3.  **AuthenticatedRequest**

        Injects a set of Credentials into anything that conforms to the URLConvertible protocol. Usually wraps up
        a DotcomRequest (OR) JetpackRequest.



### Remote Endpoints

Related Endpoints are expected to be accessible by means of a concrete `Remote` implementation. The `Remote` base class offers few
convenience methods for enqueuing requests and parsing responses in a standard and cohesive way `(Mappers)`.

`Remote(s)` receive a Network concrete instance via its initializer. This allows us to Unit Test it's behavior, by means of the `MockNetwork`
tool, which was designed to simulate Backend Responses.




## **Yosemite.framework**

The [Yosemite framework](YOSEMITE.md) is the keystone of our architecture. Encapsulates all of the Business Logic of our app, and interacts with both the Networking and
Storage layers.

More on [Yosemite](YOSEMITE.md)


### Main Concepts

We've borrowed several concepts from  the [WordPress FluxC library](https://github.com/wordpress-mobile/WordPress-FluxC-Android), and tailored them down
for the iOS platform (and our specific requirements):


1.  **Actions**

        Lightweight entities expected to contain anything required to perform a specific task.
        Usually implemented by means of Swift enums, but can be literally any type that conforms to the Action protocol.

        *Allowed* to have a Closure Callback to indicate Success / Failure scenarios.

        **NOTE:** Success callbacks can return data, but the "preferred" mechanism is via the EntityListener or
        ResultsController tools.

2.  **Stores**

        Stores offer sets of related API's that allow you to perform related tasks. Typically each Model Entity will have an
        associated Store.

        References to the `Network` and `StorageManager` instances are received at build time. This allows us to inject Mock
        Storage and Network layers, for unit testing purposes.

        Differing from our Android counterpart, Yosemite.Stores are *only expected process Actions*, and do not expose
        Public API's to retrieve / observe objects. The name has been kept *for historic reasons*.

3.  **Dispatcher**

        Binds together Actions and ActionProcessors (Stores), with key differences from FluxC:

        -   ActionProcessors must register themselves to handle a specific ActionType.
        -   Each ActionType may only have one ActionProcessor associated.
        -   Since each ActionType may be only handled by a single ActionProcessor, a Yosemite.Action is *allowed* to have
            a Callback Closure.

4.  **ResultsController**

        Associated with a Stored.Entity, allows you to query the Storage layer, but grants you access to the *ReadOnly* version
        of the Observed Entities.
        Internally, implemented as a thin wrapper around NSFetchedResultsController.

5.  **EntityListener**

        Allows you to observe changes performed over DataModel Entities. Whenever the observed entity is Updated / Deleted,
        callbacks will be executed.



### Main Flows

    1.  Performing Tasks

                                SomeAction >> Dispatcher >> SomeStore

        A.  [Main App]  SomeAction is built and enqueued in the main dispatcher
        B.  [Yosemite]  The dispatcher looks up for the processor that support SomeAction.Type, and relays the Action.
        C.  [Yosemite]  SomeStore receives the action, and performs a task
        D.  [Yosemite]  Upon completion, SomeStore *may* (or may not) run the Action's callback (if any).

    2.  Observing a Collection of Entities

                                ResultsController >> Observer

        A.  [Main App]  An observer (typically a ViewController) initializes a ResultsController, and subscribes to its callbacks
        B.  [Yosemite]  ResultsController listens to Storage Layer changes that match the target criteria (Entity / Predicate)
        C.  [Yosemite]  Whenever there are changes, the observer gets notified
        D.  [Yosemite]  ResultsController *grants ReadOnly Access* to the stored entities

    3.  Observing a Single Entity

                                EntityListener >> Observer

        A.  [Main App]  An observer initializes an EntityListener instance with a specific ReadOnly Entity.
        B.  [Yosemite]  EntityListener hooks up to the Storage Layer, and listens to changes matching it's criteria.
        C.  [Yosemite]  Whenever an Update / Deletion OP is performed on the target entity, the Observer is notified.



### Model Entities

It's important to note that in the proposed architecture Model Entities must be defined in two spots:

A.  **Storage.framework**

        New entities are defined in the CoreData Model, and its code is generated thru the Model Editor.

B.  **Networking.framework**

        Entities are typically implemented as `structs` with readonly properties, and Decodable conformance.

In order to avoid code duplication we've taken a few shortcuts:

*   All of the 'Networking Entities' are typealiased as 'Yosemite Entities', and exposed publicly (Model.swift).
    This allows us to avoid the need for importing `Networking` in the main app, and also lets us avoid reimplementing, yet again,
    the same entities that have been defined twice.

*   Since ResultsController uses internally a FRC, the Storage.Model *TYPE* is required for its initialization.
    We may revisit and fix this shortcoming in upcoming iterations.

    As a workaround to prevent the need for `import Storage` statements, all of the Storage.Entities that are used in
    ResultsController instances through the main app have been re-exported by means of a typealias.



### Mapping: Storage.Entity <> Yosemite.Entity

It's important to note that the Main App is only expected to interact with ReadOnly Entities (Yosemite). We rely on two main protocols to convert a Mutable Entity
into a ReadOnly instance:


*  **ReadOnlyConvertible**

        Protocol implemented by all of the Storage.Entities, allows us to obtain a ReadOnly Type matching the Receiver's Payload.
        Additionally, this protocol defines an API to update the receiver's fields, given a ReadOnly instance (potentially a Backend
        response we've received from the Networking layer)

*  **ReadOnlyType**

        Protocol implemented by *STRONG* Storage.Entities. Allows us to determine if a ReadOnly type represents a given Mutable instance.
        Few notes that led us to this approach:

        A.      Why is it only supported by *Strong* stored types?: because in order to determine if A represents B, a
                primaryKey is needed. Weak types might not have a pK accessible.

        B.      We've intentionally avoided adding a objectID field to the Yosemite.Entities, because in order to do this in a clean
                way, we would have ended up defining Model structs x3 (instead of simply re-exporting the Networking ones).

        C.      "Weak Entities" are okay not to conform to this protocol. In turn, their parent (strong entities) can be observed.


## WooCommerce

The outer layer is where the UI and the business logic associated to it belongs to.

It is important to note that at the moment there is not a global unified architecture of this layer, but more of a micro-architecture oriented approach and the general idea that business logic should be detached from view controllers.

That being said, there are some high-level abstractions that are starting to pop up.

### Global Dependencies

Global dependencies are provided by an implementation of the Service Locator pattern. In WooCommerce, a [`ServiceLocator`](../WooCommerce/Classes/ServiceLocator/ServiceLocator.swift) is just a set of static getters to the high-level global abstractions (i.e. stats, stores manager) and set of setters that allow overriding the actual implementation of those abstractions for better testability.
