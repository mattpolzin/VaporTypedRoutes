//
//  TypedPathComponent.swift
//  
//
//  Created by Mathew Polzin on 5/8/20.
//

import Vapor

public enum TypedPathComponent: ExpressibleByStringLiteral, CustomStringConvertible {
    case constant(String)
    case parameter(name: String, Meta)
    case anything
    case catchall

    public struct Meta {
        public let type: Any.Type
        public let description: String?

        public init(type: Any.Type = String.self, description: String? = nil) {
            self.type = type
            self.description = description
        }
    }

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

    public var parameterType: Any.Type? {
        guard case .parameter(_, let meta) = self else {
            return nil
        }
        return meta.type
    }

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
    public static func parameter(_ name: String) -> Self {
        return .parameter(name: name, .init(type: String.self, description: nil))
    }

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
    public var string: String {
        self.map(\.description).joined(separator: "/")
    }
}
