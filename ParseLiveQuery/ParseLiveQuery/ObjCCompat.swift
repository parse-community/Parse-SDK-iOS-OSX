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
 This protocol describes the interface for handling events from a live query client.

 You can use this protocol on any custom class of yours, instead of Subscription, if it fits your use case better.
 */
@objc(PFLiveQuerySubscriptionHandling)
public protocol ObjCCompat_SubscriptionHandling {

    /**
     Tells the handler that an event has been received from the live query server.

     - parameter query: The query that the event occurred on.
     - parameter event: The event that has been recieved from the server.
     - parameter client: The live query client which received this event.
     */
    @objc(liveQuery:didRecieveEvent:inClient:)
    optional func didRecieveEvent(_ query: PFQuery<PFObject>, event: PFLiveQueryEvent, client: Client)

    /**
     Tells the handler that an error has been received from the live query server.

     - parameter query: The query that the error occurred on.
     - parameter error: The error that the server has encountered.
     - parameter client: The live query client which received this error.
     */
    @objc(liveQuery:didEncounterError:inClient:)
    optional func didRecieveError(_ query: PFQuery<PFObject>, error: NSError, client: Client)

    /**
     Tells the handler that a query has been successfully registered with the server.

     - note: This may be invoked multiple times if the client disconnects/reconnects.

     - parameter query: The query that has been subscribed.
     - parameter client: The live query client which subscribed this query.
     */
    @objc(liveQuery:didSubscribeInClient:)
    optional func didSubscribe(_ query: PFQuery<PFObject>, client: Client)

    /**
     Tells the handler that a query has been successfully deregistered from the server.

     - note: This is not called unless `unregister()` is explicitly called.

     - parameter query: The query that has been unsubscribed.
     - parameter client: The live query client which unsubscribed this query.
     */
    @objc(liveQuery:didUnsubscribeInClient:)
    optional func didUnsubscribe(_ query: PFQuery<PFObject>, client: Client)
}

// HACK: Compiler bug causes enums (and sometimes classes) that are declared in structs that are marked as @objc
// to not actually be emitted by  the compiler (lolwut?). Moving this to global scope fixes the problem, but we can't
// change the objc name of an enum either, so we pollute the swift namespace here.
// TODO: Fix this eventually.

/**
 A type of an update event on a specific object from the live query server.
 */
@objc
public enum PFLiveQueryEventType: Int {
    /// The object has been updated, and is now included in the query.
    case entered
    /// The object has been updated, and is no longer included in the query.
    case left
    /// The object has been created, and is a part of the query.
    case created
    /// The object has been updated, and is still a part of the query.
    case updated
    /// The object has been deleted, and is no longer included in the query.
    case deleted
}

/**
 Represents an update on a specific object from the live query server.
 */
@objc
open class PFLiveQueryEvent: NSObject {
    /// Type of the event.
    @objc
    public let type: PFLiveQueryEventType

    /// Object this event is for.
    @objc
    public let object: PFObject

    init(type: PFLiveQueryEventType, object: PFObject) {
        self.type = type
        self.object = object
    }
}

/**
 This struct wraps up all of our Objective-C compatibility layer. You should never need to touch this if you're using Swift.
 */
public struct ObjCCompat {
    fileprivate init() { }

    /**
     A default implementation of the SubscriptionHandling protocol, using blocks for callbacks.
     */
    @objc(PFLiveQuerySubscription)
    open class Subscription: NSObject {
        public typealias SubscribeHandler = @convention(block) (PFQuery<PFObject>) -> Void
        public typealias ErrorHandler = @convention(block) (PFQuery<PFObject>, NSError) -> Void
        public typealias EventHandler = @convention(block) (PFQuery<PFObject>, PFLiveQueryEvent) -> Void
        public typealias ObjectHandler = @convention(block) (PFQuery<PFObject>, PFObject) -> Void

        var subscribeHandlers = [SubscribeHandler]()
        var unsubscribeHandlers = [SubscribeHandler]()
        var errorHandlers = [ErrorHandler]()
        var eventHandlers = [EventHandler]()

        /**
         Register a callback for when a client succesfully subscribes to a query.

         - parameter handler: The callback to register.

         - returns: The same subscription, for easy chaining.
         */
        @objc(addSubscribeHandler:)
        open func addSubscribeHandler(_ handler: @escaping SubscribeHandler) -> Subscription {
            subscribeHandlers.append(handler)
            return self
        }

        /**
         Register a callback for when a query has been unsubscribed.

         - parameter handler: The callback to register.

         - returns: The same subscription, for easy chaining.
         */
        @objc(addUnsubscribeHandler:)
        open func addUnsubscribeHandler(_ handler: @escaping SubscribeHandler) -> Subscription {
            unsubscribeHandlers.append(handler)
            return self
        }

        /**
         Register a callback for when an error occurs.

         - parameter handler: The callback to register.

         - returns: The same subscription, for easy chaining.
         */
        @objc(addErrorHandler:)
        open func addErrorHandler(_ handler: @escaping ErrorHandler) -> Subscription {
            errorHandlers.append(handler)
            return self
        }

        /**
         Register a callback for when an event occurs.

         - parameter handler: The callback to register.

         - returns: The same subscription, for easy chaining.
         */
        @objc(addEventHandler:)
        open func addEventHandler(_ handler: @escaping EventHandler) -> Subscription {
            eventHandlers.append(handler)
            return self
        }

        /**
         Register a callback for when an object enters a query.

         - parameter handler: The callback to register.

         - returns: The same subscription, for easy chaining.
         */
        @objc(addEnterHandler:)
        open func addEnterHandler(_ handler: @escaping ObjectHandler) -> Subscription {
            return addEventHandler { $1.type == .entered ? handler($0, $1.object) : () }
        }

        /**
         Register a callback for when an object leaves a query.

         - parameter handler: The callback to register.

         - returns: The same subscription, for easy chaining.
         */
        @objc(addLeaveHandler:)
        open func addLeaveHandler(_ handler: @escaping ObjectHandler) -> Subscription {
            return addEventHandler { $1.type == .left ? handler($0, $1.object) : () }
        }

        /**
         Register a callback for when an object that matches the query is created.

         - parameter handler: The callback to register.

         - returns: The same subscription, for easy chaining.
         */
        @objc(addCreateHandler:)
        open func addCreateHandler(_ handler: @escaping  ObjectHandler) -> Subscription {
            return addEventHandler { $1.type == .created ? handler($0, $1.object) : () }
        }

        /**
         Register a callback for when an object that matches the query is updated.

         - parameter handler: The callback to register.

         - returns: The same subscription, for easy chaining.
         */
        @objc(addUpdateHandler:)
        open func addUpdateHandler(_ handler: @escaping  ObjectHandler) -> Subscription {
            return addEventHandler { $1.type == .updated ? handler($0, $1.object) : () }
        }

        /**
         Register a callback for when an object that matches the query is deleted.

         - parameter handler: The callback to register.

         - returns: The same subscription, for easy chaining.
         */
        @objc(addDeleteHandler:)
        open func addDeleteHandler(_ handler: @escaping  ObjectHandler) -> Subscription {
            return addEventHandler { $1.type == .deleted ? handler($0, $1.object) : () }
        }
    }
}

extension ObjCCompat.Subscription: ObjCCompat_SubscriptionHandling {
    public func didRecieveEvent(_ query: PFQuery<PFObject>, event: PFLiveQueryEvent, client: Client) {
        eventHandlers.forEach { $0(query, event) }
    }

    public func didRecieveError(_ query: PFQuery<PFObject>, error: NSError, client: Client) {
        errorHandlers.forEach { $0(query, error) }
    }

    public func didSubscribe(_ query: PFQuery<PFObject>, client: Client) {
        subscribeHandlers.forEach { $0(query) }
    }

    public func didUnsubscribe(_ query: PFQuery<PFObject>, client: Client) {
        unsubscribeHandlers.forEach { $0(query) }
    }
}

extension Client {
    fileprivate class HandlerConverter: SubscriptionHandling {
        typealias T = PFObject

        fileprivate static var associatedObjectKey: Int = 0
        fileprivate weak var handler: ObjCCompat_SubscriptionHandling?

        init(handler: ObjCCompat_SubscriptionHandling) {
            self.handler = handler

            objc_setAssociatedObject(handler, &HandlerConverter.associatedObjectKey, self, .OBJC_ASSOCIATION_RETAIN)
        }

        fileprivate func didReceive(_ event: Event<T>, forQuery query: PFQuery<T>, inClient client: Client) {
            handler?.didRecieveEvent?(query, event: PFLiveQueryEvent(event: event), client: client)
        }

        fileprivate func didEncounter(_ error: Error, forQuery query: PFQuery<T>, inClient client: Client) {
            handler?.didRecieveError?(query, error: error as NSError, client: client)
        }

        fileprivate func didSubscribe(toQuery query: PFQuery<T>, inClient client: Client) {
            handler?.didSubscribe?(query, client: client)
        }

        fileprivate func didUnsubscribe(fromQuery query: PFQuery<T>, inClient client: Client) {
            handler?.didUnsubscribe?(query, client: client)
        }
    }

    /**
     Registers a query for live updates, using a custom subscription handler.

     - parameter query:   The query to register for updates.
     - parameter handler: A custom subscription handler.

     - returns: The subscription that has just been registered.
     */
    @objc(subscribeToQuery:withHandler:)
    public func _PF_objc_subscribe(
        _ query: PFQuery<PFObject>, handler: ObjCCompat_SubscriptionHandling
        ) -> ObjCCompat_SubscriptionHandling {
            let swiftHandler = HandlerConverter(handler: handler)
            _ = subscribe(query, handler: swiftHandler)
            return handler
    }

    /**
     Registers a query for live updates, using the default subscription handler.

     - parameter query: The query to register for updates.

     - returns: The subscription that has just been registered.
     */
    @objc(subscribeToQuery:)
    public func _PF_objc_subscribe(_ query: PFQuery<PFObject>) -> ObjCCompat.Subscription {
        let subscription = ObjCCompat.Subscription()
        _ = _PF_objc_subscribe(query, handler: subscription)
        return subscription
    }

    /**
     Unsubscribes a specific handler from a query.

     - parameter query: The query to unsubscribe from.
     - parameter handler: The specific handler to unsubscribe from.
     */
    @objc(unsubscribeFromQuery:withHandler:)
    public func _PF_objc_unsubscribe(_ query: PFQuery<PFObject>, subscriptionHandler: ObjCCompat_SubscriptionHandling) {
        unsubscribe { record in
            guard let handler = record.subscriptionHandler as? HandlerConverter
                else {
                    return false
            }
            return record.query == query && handler.handler === subscriptionHandler
        }
    }
}

// HACK: Another compiler bug - if you have a required initializer with a generic type, the compiler simply refuses to 
// emit the entire class altogether. Moving this to an extension for now solves the issue.

extension PFLiveQueryEvent {
    convenience init<T>(event: ParseLiveQuery.Event<T>) {
        let results: (type: PFLiveQueryEventType, object: PFObject) = {
            switch event {
            case .entered(let object): return (.entered, object)
            case .left(let object):    return (.left, object)
            case .created(let object): return (.created, object)
            case .updated(let object): return (.updated, object)
            case .deleted(let object): return (.deleted, object)
            }
        }()

        self.init(type: results.type, object: results.object)
    }
}

extension PFQuery {
    /**
     Register this PFQuery for updates with Live Queries.
     This uses the shared live query client, and creates a default subscription handler for you.

     - returns: The created subscription for observing.
     */
    @objc(subscribe)
    public func _PF_objc_subscribe() -> ObjCCompat.Subscription {
        return Client.shared._PF_objc_subscribe(self as! PFQuery<PFObject>)
    }
}
