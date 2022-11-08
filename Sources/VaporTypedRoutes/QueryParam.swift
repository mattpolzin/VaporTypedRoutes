//
//  QueryContext.swift
//  App
//
//  Created by Mathew Polzin on 12/8/19.
//

import Vapor

/// A type that represents an abstract query parameter in a request.
public protocol AbstractQueryParam {
    /// The name of the parameter.
    var name: String { get }
    /// A list of allowed values, if any.
    ///
    /// Defaults to allowing anything.
    var allowedValues: [String]? { get }
    /// A description of the query parameter.
    ///
    /// Useful for documentation generation.
    var description: String? { get }
    /// Determines whether this parameter is mandatory.
    ///
    /// Default value is `false`.
    var required: Bool { get }
    /// Determines if the parameter is deprecated and SHOULD be transitioned out of usage.
    ///
    /// Default value is `false`
    var deprecated: Bool { get }

    /// The associated Swift type for the query parameter.
    var swiftType: Any.Type { get }
}

/// A type that represents a concrete query parameter in a request, with an associated type.
public protocol QueryParamProtocol: AbstractQueryParam {
    /// The associated Swift type for the query parameter.
    associatedtype SwiftType

    /// The default value of the query parameter, if any.
    var defaultValue: SwiftType? { get }
}

extension QueryParamProtocol {
    public var swiftType: Any.Type {
        return SwiftType.self
    }
}

/// A concrete query parameter with an associated Swift type.
public struct QueryParam<T: Decodable>: QueryParamProtocol {
    public typealias SwiftType = T

    public let name: String
    public let allowedValues: [String]?
    public let description: String?
    public let defaultValue: T?
    public let required: Bool
    public let deprecated: Bool

    /// Creates a new parameter instance with the constituent elements, allowing all values.
    /// - Parameters:
    ///   - name: The name of the query parameter (e.g, the part before the equals sign).
    ///   - description: An optional description of the query param (for documentation generation and the like).
    ///   - defaultValue: An optional default value to use when a request doesn't provide one.
    ///   - required: An optional flag indicating whether or not the query parameter is required.
    ///   - deprecated: An optional flag indicating whether or not the query parameter is deprecated and should be transitioned out of usage.
    public init(name: String, description: String? = nil, defaultValue: T? = nil, required: Bool = false, deprecated: Bool = false) {
        self.name = name
        self.allowedValues = nil
        self.defaultValue = defaultValue
        self.description = description
        self.required = required
        self.deprecated = deprecated
    }

    /// Creates a new parameter instance with the constituent elements, specifying a finite list of allowed values.
    /// - Parameters:
    ///   - name: The name of the query parameter (e.g, the part before the equals sign).
    ///   - description: An optional description of the query param (for documentation generation and the like).
    ///   - defaultValue: An optional default value to use when a request doesn't provide one.
    ///   - allowedValues: A finite list of allowed values.
    ///   - required: An optional flag indicating whether or not the query parameter is required.
    ///   - deprecated: An optional flag indicating whether or not the query parameter is deprecated and should be transitioned out of usage.
    public init<U: LosslessStringConvertible>(name: String, description: String? = nil, defaultValue: T? = nil, allowedValues: [U], required: Bool = false, deprecated: Bool = false) {
        self.name = name
        self.description = description
        self.defaultValue = defaultValue
        self.allowedValues = allowedValues.map(String.init(describing:))
        self.required = required
        self.deprecated = deprecated
    }
}

/// A query parameter with a single value.
///
/// e.x.
///
///     {path}?param=hello
public typealias StringQueryParam = QueryParam<String>

/// A query parameter with a single value (must be an integer).
///
/// e.x.
///
///     {path}?param=1
public typealias IntegerQueryParam = QueryParam<Int>

/// A query parameter with a single value (must be number, not necessarily an integer)
///
/// e.x.
///
///     {path}?param=10.345
public typealias NumberQueryParam = QueryParam<Double>

/// A query parameter where the value is a comma-separated list of values.
///
/// e.x. (`CSVQueryParam<String>`)
///
///     {path}?param=hello,world
public typealias CSVQueryParam<SwiftType: Decodable> = QueryParam<[SwiftType]>

/// A query parameter where the value is nested in an object.
///
/// e.x.
///
///     {path}?param[hello]=hi+there
///
/// In this example, the path would be `["param", "hello"]`
public struct NestedQueryParam<SwiftType: Decodable>: QueryParamProtocol {
    /// The path components of the query parameter.
    public let path: [String]
    public let allowedValues: [String]?
    public let description: String?
    public let defaultValue: SwiftType?
    public let required: Bool
    public let deprecated: Bool

    /// The name of the parameter.
    ///
    /// This will be the first path component.
    public var name: String { path[0] }

    /// Creates a new nested parameter instance with the constituent elements, allowing all values.
    /// - Parameters:
    ///   - path: The complete path of the query parameter.
    ///   - description: An optional description of the query param (for documentation generation and the like).
    ///   - defaultValue: An optional default value to use when a request doesn't provide one.
    ///   - allowedValues: A finite list of allowed values.
    ///   - required: An optional flag indicating whether or not the query parameter is required.
    ///   - deprecated: An optional flag indicating whether or not the query parameter is deprecated and should be transitioned out of usage.
    public init(path: String..., description: String? = nil, defaultValue: SwiftType? = nil, allowedValues: [String]? = nil, required: Bool = false, deprecated: Bool = false) {
        self.init(path: path, description: description, defaultValue: defaultValue, allowedValues: allowedValues, required: required, deprecated: deprecated)
    }
    /// Creates a new nested parameter instance with the constituent elements, specifying a finite list of allowed values.
    /// - Parameters:
    ///   - path: The complete path of the query parameter.
    ///   - description: An optional description of the query param (for documentation generation and the like).
    ///   - defaultValue: An optional default value to use when a request doesn't provide one.
    ///   - allowedValues: A finite list of allowed values.
    ///   - required: An optional flag indicating whether or not the query parameter is required.
    ///   - deprecated: An optional flag indicating whether or not the query parameter is deprecated and should be transitioned out of usage.
    public init(path: [String], description: String? = nil, defaultValue: SwiftType? = nil, allowedValues: [String]? = nil, required: Bool = false, deprecated: Bool = false) {
        self.path = path
        self.allowedValues = allowedValues
        self.description = description
        self.defaultValue = defaultValue
        self.required = required
        self.deprecated = deprecated
    }
}
