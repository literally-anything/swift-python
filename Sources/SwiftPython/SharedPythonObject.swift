/**
 * SharedPythonObject.swift
 * SwiftPython
 * 
 * Created by Hunter Baker on 12/25/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

/// A shared reference to a python object. This is used to encapsulate a noncopyable `PythonObject` type inside a `Copyable` type.
/// This is supposed to be a temporary fix until more protocols and features support noncopyable types.
@safe
public final class SharedPythonObject: @unchecked Sendable {
    public let object: PythonObject

    /// Initialize a `SharedPythonObject` with an existing `PythonObject`.
    /// - Parameter object: An existing `PythonObject`.
    public init(_ object: consuming PythonObject) {
        self.object = object
    }

    /// Creates a new strong reference to the underlying python object.
    /// - Returns: A new `PythonObject` pointing to the same instance.
    public func take() -> PythonObject {
        object.copy()
    }
}

// String Conversions
extension SharedPythonObject: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        object.description
    }
    public var debugDescription: String {
        object.debugDescription
    }
}
