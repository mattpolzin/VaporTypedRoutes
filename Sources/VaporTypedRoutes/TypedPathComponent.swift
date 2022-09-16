//
//  TypedPathComponent.swift
//  
//
//  Created by Mathew Polzin on 5/8/20.
//

import Vapor

/// A strongly-typed path component.
public enum TypedPathComponent: ExpressibleByStringLiteral, CustomStringConvertible {
    /// A normal, constant path component.
    case constant(String)
    /// A dynamic parameter component with an associated Meta value.
    ///
    /// The supplied identifier will be used to fetch the associated
    /// value from `Parameters`.
    ///
    /// Represented as `:` followed by the identifier. If provided as a StringLiteral, the Meta type will be initialized as a String with no description.
    case parameter(name: String, Meta)
    /// A dynamic parameter component with a discarded value.
    case anything
    /// A fallback component that will match one or more dynamic parameter components with discarded values.
    ///
    /// Catch alls have the lowest precedence, and will only be matched if no more specific path components are found.
    ///    The matched subpath will be stored into Parameters.catchall.
    ///    Represented as `**`.
    case catchall

    /// A struct with a Swift type and an associated description for a route parameter.
    public struct Meta {
        /// The type for the route parameter.
        public let type: Any.Type
        /// An optional description for the route parameter.
        public let description: String?

        /// Create an instance with an associated type (defaults to `String`) and optional description.
        /// - Parameters:
        ///   - type: The type for the route parameter.
        ///   - description: An optional description for the route parameter.
        public init(type: Any.Type = String.self, description: String? = nil) {
            self.type = type
            self.description = description
        }
    }

    /// Create a typed path component from a string literal.
    public init(stringLiteral value: StringLiteralType) {
        switch Vapor.PathComponent(stringLiteral: value) {
        case .constant(let value):
            self = .constant(value)
        case .parameter(let name):
            self = .parameter(name: name, .init(type: String.self, description: nil))
        case .anything:
            self = .anything
        case .catchall:
            self = .catchall
        }
    }

    /// The type associated with the route parameter, if any.
    public var parameterType: Any.Type? {
        guard case .parameter(_, let meta) = self else {
            return nil
        }
        return meta.type
    }

    /// The string equivalent of the component.
    public var description: String {
        switch self {
        case .anything:
            return Vapor.PathComponent.anything.description
        case .catchall:
            return Vapor.PathComponent.catchall.description
        case .parameter(name: let value, _):
            return Vapor.PathComponent.parameter(value).description
        case .constant(let value):
            return Vapor.PathComponent.constant(value).description
        }
    }

    /// The equivalent untyped `PathComponent`.
    public var vaporPathComponent: Vapor.PathComponent {
        switch self {
        case .anything:
            return .anything
        case .catchall:
            return .catchall
        case .parameter(name: let name, _):
            return .parameter(name)
        case .constant(let value):
            return .constant(value)
        }
    }
}

extension TypedPathComponent {
    /// Creates a TypedPathComponent with a given name, and a type of String.
    /// - Parameters:
    ///   - name: The name of the route parameter.
    public static func parameter(_ name: String) -> Self {
        return .parameter(name: name, .init(type: String.self, description: nil))
    }


    /// Creates a TypedPathComponent with a given name and type.
    /// - Parameters:
    ///   - name: The name of the route parameter.
    ///   - type: The type to use for the route parameter.
    public static func parameter(_ name: String, type: Any.Type) -> Self {
        return .parameter(name: name, .init(type: type, description: nil))
    }

    /// Add a description to this path component.
    ///
    /// This only has an effect on path components that
    /// are parameters.
    public func description(_ description: String) -> Self {
        guard case let .parameter(name, meta) = self else {
            return self
        }
        return .parameter(name: name, .init(type: meta.type, description: description))
    }

    /// Set the type for this path component.
    ///
    /// This only has an effect on path components that
    /// are parameters. If not set, the type will be String by
    /// default.
    public func parameterType(_ type: Any.Type) -> Self {
        guard case let .parameter(name, meta) = self else {
            return self
        }
        return .parameter(name: name, .init(type: type, description: meta.description))
    }
}

extension Vapor.PathComponent {
    /// The equivalent `TypedPathComponent.
    var typedPathComponent: TypedPathComponent {
        switch self {
        case .anything:
            return .anything
        case .catchall:
            return .catchall
        case .constant(let value):
            return .constant(value)
        case .parameter(let name):
            return .parameter(name)
        }
    }
}

extension String {
    /// Add a description to a path component.
    ///
    /// This only has an effect on path components that
    /// are parameters.
    public func description(_ string: String) -> TypedPathComponent {
        let component = TypedPathComponent(stringLiteral: self)
        guard case let .parameter(name, _) = component else {
            return component
        }
        return .parameter(name: name, .init(type: String.self, description: string))
    }

    /// Set the type for a path component.
    ///
    /// This only has an effect on path components that
    /// are parameters. If not set, the type will be String by
    /// default.
    public func parameterType(_ type: Any.Type) -> TypedPathComponent {
        let component = TypedPathComponent(stringLiteral: self)
        guard case let .parameter(name, meta) = component else {
            return component
        }
        return .parameter(name: name, .init(type: type, description: meta.description))
    }
}

extension Array where Element == TypedPathComponent {
    /// A path constructed from the array of `TypedPathComponent`s.
    public var string: String {
        self.map(\.description).joined(separator: "/")
    }
}
