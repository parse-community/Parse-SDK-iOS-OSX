/**
 * Copyright (c) 2016-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

import Foundation
import Parse
import BoltsSwift

/**
 This protocol describes the interface for handling events from a liveQuery client.

 You can use this protocol on any custom class of yours, instead of Subscription, if it fits your use case better.
 */
public protocol SubscriptionHandling: AnyObject {
    /// The type of the PFObject subclass that this handler uses.
    associatedtype PFObjectSubclass: PFObject

    /**
     Tells the handler that an event has been received from the live query server.

     - parameter event: The event that has been recieved from the server.
     - parameter query: The query that the event occurred on.
     - parameter client: The live query client which received this event.
     */
    func didReceive(_ event: Event<PFObjectSubclass>, forQuery query: PFQuery<PFObjectSubclass>, inClient client: Client)

    /**
     Tells the handler that an error has been received from the live query server.

     - parameter error: The error that the server has encountered.
     - parameter query: The query that the error occurred on.
     - parameter client: The live query client which received this error.
     */
    func didEncounter(_ error: Error, forQuery query: PFQuery<PFObjectSubclass>, inClient client: Client)

    /**
     Tells the handler that a query has been successfully registered with the server.

     - note: This may be invoked multiple times if the client disconnects/reconnects.

     - parameter query: The query that has been subscribed.
     - parameter client: The live query client which subscribed this query.
     */
    func didSubscribe(toQuery query: PFQuery<PFObjectSubclass>, inClient client: Client)

    /**
     Tells the handler that a query has been successfully deregistered from the server.

     - note: This is not called unless `unregister()` is explicitly called.

     - parameter query: The query that has been unsubscribed.
     - parameter client: The live query client which unsubscribed this query.
     */
    func didUnsubscribe(fromQuery query: PFQuery<PFObjectSubclass>, inClient client: Client)
}

/**
 Represents an update on a specific object from the live query server.

 - Entered: The object has been updated, and is now included in the query.
 - Left:    The object has been updated, and is no longer included in the query.
 - Created: The object has been created, and is a part of the query.
 - Updated: The object has been updated, and is still a part of the query.
 - Deleted: The object has been deleted, and is no longer included in the query.
 */
public enum Event<T> where T: PFObject {
    /// The object has been updated, and is now included in the query
    case entered(T)

    /// The object has been updated, and is no longer included in the query
    case left(T)

    /// The object has been created, and is a part of the query
    case created(T)

    /// The object has been updated, and is still a part of the query
    case updated(T)

    /// The object has been deleted, and is no longer included in the query
    case deleted(T)

    init<V>(event: Event<V>) {
        switch event {
        case .entered(let value as T): self = .entered(value)
        case .left(let value as T):    self = .left(value)
        case .created(let value as T): self = .created(value)
        case .updated(let value as T): self = .updated(value)
        case .deleted(let value as T): self = .deleted(value)
        default: fatalError()
        }
    }
}

private func == <T>(lhs: Event<T>, rhs: Event<T>) -> Bool {
    switch (lhs, rhs) {
    case (.entered(let obj1), .entered(let obj2)): return obj1 == obj2
    case (.left(let obj1), .left(let obj2)):       return obj1 == obj2
    case (.created(let obj1), .created(let obj2)): return obj1 == obj2
    case (.updated(let obj1), .updated(let obj2)): return obj1 == obj2
    case (.deleted(let obj1), .deleted(let obj2)): return obj1 == obj2
    default: return false
    }
}

/**
 A default implementation of the SubscriptionHandling protocol, using closures for callbacks.
 */
open class Subscription<T>: SubscriptionHandling where T: PFObject {
    fileprivate var errorHandlers: [(PFQuery<T>, Error) -> Void] = []
    fileprivate var eventHandlers: [(PFQuery<T>, Event<T>) -> Void] = []
    fileprivate var subscribeHandlers: [(PFQuery<T>) -> Void] = []
    fileprivate var unsubscribeHandlers: [(PFQuery<T>) -> Void] = []

    /**
     Creates a new subscription that can be used to handle updates.
     */
    public init() {
    }

    /**
     Register a callback for when an error occurs.

     - parameter handler: The callback to register.

     - returns: The same subscription, for easy chaining
     */
    @discardableResult open func handleError(_ handler: @escaping (PFQuery<T>, Error) -> Void) -> Subscription {
        errorHandlers.append(handler)
        return self
    }

    /**
     Register a callback for when an event occurs.

     - parameter handler: The callback to register.

     - returns: The same subscription, for easy chaining.
     */
    @discardableResult open func handleEvent(_ handler: @escaping (PFQuery<T>, Event<T>) -> Void) -> Subscription {
        eventHandlers.append(handler)
        return self
    }

    /**
     Register a callback for when a client succesfully subscribes to a query.

     - parameter handler: The callback to register.

     - returns: The same subscription, for easy chaining.
     */
    @discardableResult open func handleSubscribe(_ handler: @escaping (PFQuery<T>) -> Void) -> Subscription {
        subscribeHandlers.append(handler)
        return self
    }

    /**
     Register a callback for when a query has been unsubscribed.

     - parameter handler: The callback to register.

     - returns: The same subscription, for easy chaining.
     */
    @discardableResult open func handleUnsubscribe(_ handler: @escaping (PFQuery<T>) -> Void) -> Subscription {
        unsubscribeHandlers.append(handler)
        return self
    }

    // ---------------
    // MARK: SubscriptionHandling
    // TODO: Move to extension once swift compiler is less crashy
    // ---------------
    public typealias PFObjectSubclass = T

    open func didReceive(_ event: Event<PFObjectSubclass>, forQuery query: PFQuery<T>, inClient client: Client) {
        eventHandlers.forEach { $0(query, event) }
    }

    open func didEncounter(_ error: Error, forQuery query: PFQuery<T>, inClient client: Client) {
        errorHandlers.forEach { $0(query, error) }
    }

    open func didSubscribe(toQuery query: PFQuery<T>, inClient client: Client) {
        subscribeHandlers.forEach { $0(query) }
    }

    open func didUnsubscribe(fromQuery query: PFQuery<T>, inClient client: Client) {
        unsubscribeHandlers.forEach { $0(query) }
    }
}

extension Subscription {
    /**
     Register a callback for when an error occcurs of a specific type

     Example:

         subscription.handle(LiveQueryErrors.InvalidJSONError.self) { query, error in
             print(error)
          }

     - parameter errorType: The error type to register for
     - parameter handler:   The callback to register

     - returns: The same subscription, for easy chaining
     */
    @discardableResult public func handle<E: Error>(
        _ errorType: E.Type = E.self,
        _ handler: @escaping (PFQuery<T>, E) -> Void
        ) -> Subscription {
            errorHandlers.append { query, error in
                if let error = error as? E {
                    handler(query, error)
                }
            }
            return self
    }

    /**
     Register a callback for when an event occurs of a specific type

     Example:

         subscription.handle(Event.Created) { query, object in
            // Called whenever an object is creaated
         }

     - parameter eventType: The event type to handle. You should pass one of the enum cases in `Event`
     - parameter handler:   The callback to register

     - returns: The same subscription, for easy chaining

     */
    @discardableResult public func handle(_ eventType: @escaping (T) -> Event<T>, _ handler: @escaping (PFQuery<T>, T) -> Void) -> Subscription {
        return handleEvent { query, event in
            switch event {
            case .entered(let obj) where eventType(obj) == event: handler(query, obj)
            case .left(let obj)  where eventType(obj) == event: handler(query, obj)
            case .created(let obj) where eventType(obj) == event: handler(query, obj)
            case .updated(let obj) where eventType(obj) == event: handler(query, obj)
            case .deleted(let obj) where eventType(obj) == event: handler(query, obj)
            default: return
            }
        }
    }
}
