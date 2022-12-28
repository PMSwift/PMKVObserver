//
//  KVObserver.swift
//  PMKVObserver
//
//  Created by Lily Ballard on 11/18/15.
//  Copyright © 2015 Postmates. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
//  http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
//  <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
//  option. This file may not be copied, modified, or distributed
//  except according to those terms.
//

import Foundation

#if canImport(PMKVObserverC)
import PMKVObserverC
#endif

public typealias KVObserver = PMKVObserver

extension KVObserver {
    #if swift(>=3.2)
    /// Establishes a KVO relationship to `object`. The KVO will be active until `object` deallocates or
    /// until the `cancel()` method is invoked.
    public convenience init<Object: AnyObject, Value>(object: Object, keyPath: KeyPath<Object,Value>, options: NSKeyValueObservingOptions = [], block: @escaping (_ object: Object, _ change: Change<Value>, _ kvo: KVObserver) -> Void) {
        // FIXME: (SR-5220) We shouldn't need to use the _kvcKeyPathString SPI
        guard let keyPathStr = keyPath._kvcKeyPathString else {
            fatalError("Could not extract a String from KeyPath \(keyPath)")
        }
        self.init(__object: object, keyPath: keyPathStr, options: options, block: { (object, change, kvo) in
            block(unsafeDowncast(object as AnyObject, to: Object.self), Change(rawDict: change), kvo)
        })
    }
    
    /// Establishes a KVO relationship to `object`. The KVO will be active until either `object` or `observer`
    /// deallocates or until the `cancel()` method is invoked.
    public convenience init<T: AnyObject, Object: AnyObject, Value>(observer: T, object: Object, keyPath: KeyPath<Object,Value>, options: NSKeyValueObservingOptions = [], block: @escaping (_ observer: T, _ object: Object, _ change: Change<Value>, _ kvo: KVObserver) -> Void) {
        // FIXME: (SR-5220) We shouldn't need to use the _kvcKeyPathString SPI
        guard let keyPathStr = keyPath._kvcKeyPathString else {
            fatalError("Could not extract a String from KeyPath \(keyPath)")
        }
        self.init(__observer: observer, object: object, keyPath: keyPathStr, options: options, block: { (observer, object, change, kvo) in
            block(unsafeDowncast(observer as AnyObject, to: T.self), unsafeDowncast(object as AnyObject, to: Object.self), Change(rawDict: change), kvo)
        })
    }
    #endif
    
    /// Establishes a KVO relationship to `object`. The KVO will be active until `object` deallocates or
    /// until the `cancel()` method is invoked.
    public convenience init<Object: AnyObject>(object: Object, keyPath: String, options: NSKeyValueObservingOptions = [], block: @escaping (_ object: Object, _ change: Change<Any>, _ kvo: KVObserver) -> Void) {
        self.init(__object: object, keyPath: keyPath, options: options, block: { (object, change, kvo) in
            block(unsafeDowncast(object as AnyObject, to: Object.self), Change(rawDict: change), kvo)
        })
    }
    
    /// Establishes a KVO relationship to `object`. The KVO will be active until either `object` or `observer`
    /// deallocates or until the `cancel()` method is invoked.
    public convenience init<T: AnyObject, Object: AnyObject>(observer: T, object: Object, keyPath: String, options: NSKeyValueObservingOptions = [], block: @escaping (_ observer: T, _ object: Object, _ change: Change<Any>, _ kvo: KVObserver) -> Void) {
        self.init(__observer: observer, object: object, keyPath: keyPath, options: options, block: { (observer, object, change, kvo) in
            block(unsafeDowncast(observer as AnyObject, to: T.self), unsafeDowncast(object as AnyObject, to: Object.self), Change(rawDict: change), kvo)
        })
    }
    
    /// A type that provides type-checked accessors for the defined change keys.
    public struct Change<Value> {
        /// The kind of the change.
        /// - seealso: `NSKeyValueChangeKey.kindKey`
        @inlinable
        public var kind: NSKeyValueChange {
            // NB: Block-based KVO force-unwraps this, so we'll assume that it's safe to do the same.
            return NSKeyValueChange(rawValue: rawDict[.kindKey] as! UInt)!
        }
        
        /// The old value from the change.
        ///
        /// - Note: If the Obj-C change dictionary contains an `.oldKey` with a value of `NSNull` it
        ///   will be treated as `nil` for the purposes of casting to `Value`, unless `Value` itself
        ///   is `NSNull` or `Any`. This means that if `Value` is an optional type then the value of
        ///   this property will be `.some(.none)` when `.oldKey` is `NSNull`.
        ///
        ///   Note that if `Value` is `Any?` then the `NSNull` value will end up as `.some(.none)`
        ///   instead of staying as `NSNull`.
        /// - Bug: If `Value` is `NSNull?` this property will always be `nil` even when the change
        ///   dictionary contains an `.oldKey`. This is because Obj-C KVO change dictionaries
        ///   represent `nil` values as `NSNull` and so there is no way to distinguish between the
        ///   property being `nil` or being set to `NSNull`.
        ///
        /// - seealso: `NSKeyValueChangeKey.oldKey`
        @inlinable
        public var old: Value? {
            guard let value = rawDict[.oldKey] else { return nil }
            return _convert(value)
        }
        
        /// The new value from the change.
        ///
        /// - Note: If the Obj-C change dictionary contains a `.newKey` with a value of `NSNull` it
        ///   will be treated as `nil` for the purposes of casting to `Value`, unless `Value` itself
        ///   is `NSNull` or `Any`. This means that if `Value` is an optional type then the value of
        ///   this property will be `.some(.none)` when `.newKey` is `NSNull`.
        ///
        ///   Note that if `Value` is `Any?` then the `NSNull` value will end up as `.some(.none)`
        ///   instead of staying as `NSNull`.
        /// - Bug: If `Value` is `NSNull?` this property will always be `nil` even when the change
        ///   dictionary contains a `.newKey`. This is because Obj-C KVO change dictionaries
        ///   represent `nil` values as `NSNull` and so there is no way to distinguish between the
        ///   property being `nil` or being set to `NSNull`.
        ///
        /// - seealso: `NSKeyValueChangeKey.newKey`
        @inlinable
        public var new: Value? {
            guard let value = rawDict[.newKey] else { return nil }
            return _convert(value)
        }
        
        /// Whether this callback is being sent prior to the change.
        /// - seealso: `NSKeyValueChangeKey.notificationIsPriorKey`
        @inlinable
        public var isPrior: Bool {
            return self.rawDict[.notificationIsPriorKey] as? Bool ?? false
        }
        
        /// The indexes of the inserted, removed, or replaced objects when relevant.
        /// - seealso: `NSKeyValueChangeKey.indexesKey`
        @inlinable
        public var indexes: IndexSet? {
            return self.rawDict[.indexesKey] as? IndexSet
        }
        
        /// The raw change dictionary passed to `observeValueForKeyPath(_:ofObject:change:context:)`.
        public let rawDict: [NSKeyValueChangeKey: Any]
        
        fileprivate init(rawDict: [NSKeyValueChangeKey: Any]) {
            self.rawDict = rawDict
        }
        
        @usableFromInline
        internal func _convert(_ value: Any) -> Value? {
            if value is NSNull {
                // NSNull is used by KVO to signal that the property value was nil.
                if Value.self == Optional<NSNull>.self {
                    // We can't tell the difference with `NSNull?` between `NSNull` and `nil`
                    return nil
                } else if let value = value as? Value,
                    // Only pass this through if the desired type is NSNull or Any
                    Value.self == NSNull.self || Value.self == Any.self
                {
                    return value
                } else {
                    // Try to convert nil to Value. This way if Value is optional we'll get a
                    // .some(.none) result.
                    #if swift(>=5)
                    return Optional<Any>.none as? Value
                    #else
                    if let type = Value.self as? _OptionalProtocol.Type {
                        return .some(type.init(nilLiteral: ()) as! Value)
                    } else {
                        return nil
                    }
                    #endif
                }
            } else {
                return value as? Value
            }
        }
    }
    
    /// Returns `true` iff the observer has already been cancelled.
    ///
    /// Returns `true` if `cancel()` has been invoked on any thread. If `cancel()` is invoked
    /// concurrently with accessing this property, it may or may not see the cancellation depending
    /// on the precise timing involved.
    ///
    /// - Note: This property does not support key-value observing.
    @nonobjc public var isCancelled: Bool {
        return __isCancelled
    }
}

#if !swift(>=5)
protocol _OptionalProtocol: ExpressibleByNilLiteral {}
extension Optional: _OptionalProtocol {}
#endif

extension KVObserver.Change where Value: RawRepresentable {
    // Override old and new to do RawRepresentable conversions
    
    /// The old value from the change.
    /// - seealso: `NSKeyValueChangeKey.oldKey`
    @inlinable
    public var old: Value? {
        guard let value = rawDict[.oldKey] else { return nil }
        return (value as? Value.RawValue).flatMap(Value.init(rawValue:))
    }
    
    /// The new value from the change.
    /// - seealso: `NSKeyValueChangeKey.newKey`
    @inlinable
    public var new: Value? {
        guard let value = rawDict[.newKey] else { return nil }
        return (value as? Value.RawValue).flatMap(Value.init(rawValue:))
    }
}

#if swift(>=4.1)
public protocol _OptionalRawRepresentable: ExpressibleByNilLiteral {
    associatedtype _Wrapped: RawRepresentable
    init(_ some: _Wrapped)
}
extension Optional: _OptionalRawRepresentable where Wrapped: RawRepresentable {
    public typealias _Wrapped = Wrapped
}

extension KVObserver.Change where Value: _OptionalRawRepresentable {
    /// The old value from the change.
    ///
    /// - Note: If the Obj-C change dictionary contains an `.oldKey` with a value of `NSNull` it
    ///   will be treated as `nil` for the purposes of casting to `Value`.
    ///
    /// - seealso: `NSKeyValueChangeKey.oldKey`
    @inlinable
    public var old: Value? {
        guard let value = rawDict[.oldKey] else { return nil }
        guard let rawValue = value as? Value._Wrapped.RawValue,
            let wrappedValue = Value._Wrapped(rawValue: rawValue)
            else { return .some(nil) }
        return .some(Value(wrappedValue))
    }
    
    /// The new value from the change.
    ///
    /// - Note: If the Obj-C change dictionary contains a `.newKey` with a value of `NSNull` it will
    ///   be treated as `nil` for the purposes of casting to `Value`.
    ///
    /// - seealso: `NSKeyValueChangeKey.newKey`
    @inlinable
    public var new: Value? {
        guard let value = rawDict[.newKey] else { return nil }
        guard let rawValue = value as? Value._Wrapped.RawValue,
            let wrappedValue = Value._Wrapped(rawValue: rawValue)
            else { return .some(nil) }
        return .some(Value(wrappedValue))
    }
}
#endif
