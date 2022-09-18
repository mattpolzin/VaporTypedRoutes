//
//  Header.swift
//  
//
//  Created by Charlie Welsh on 9/18/22.
//

import Vapor

/// A type that represents an abstract header in a request.
public protocol AbstractHeader {
    /// The name of the header.
    var name: String { get }
    /// A list of allowed values, if any.
    ///
    /// Defaults to allowing anything.
    var allowedValues: [String]? { get }
    /// A description of the query parameter.
    ///
    /// Useful for documentation generation.
    var description: String? { get }

    /// The associated Swift type for the query parameter.
    var swiftType: Any.Type { get }
}

/// A type that represents a concrete query parameter in a request, with an associated type.
public protocol HeaderProtocol: AbstractHeader {
    /// The associated Swift type for the header.
    associatedtype SwiftType

    /// The default value of the header, if any.
    var defaultValue: SwiftType? { get }
}

extension HeaderProtocol {
    public var swiftType: Any.Type {
        return SwiftType.self
    }
}

/// A concrete header with an associated Swift type.
public struct Header<T: Decodable>: HeaderProtocol {
    public typealias SwiftType = T

    public let name: String
    public let allowedValues: [String]?
    public let description: String?
    public let defaultValue: T?

    /// Creates a new header instance with the constituent elements, allowing all values.
    /// - Parameters:
    ///   - name: The name of the header (e.g, the part before the colon).
    ///   - description: An optional description of the header (for documentation generation and the like).
    ///   - defaultValue: An optional default value to use when a request doesn't provide one.
    public init(name: String, description: String? = nil, defaultValue: T? = nil) {
        self.name = name
        self.allowedValues = nil
        self.defaultValue = defaultValue
        self.description = description
    }

    /// Creates a new parameter instance with the constituent elements, specifying a finite list of allowed values.
    /// - Parameters:
    ///   - name: The name of the header (e.g, the part before the colon).
    ///   - description: An optional description of the header (for documentation generation and the like).
    ///   - defaultValue: An optional default value to use when a request doesn't provide one.
    ///   - allowedValues: A finite list of allowed values.
    public init<U: LosslessStringConvertible>(name: String, description: String? = nil, defaultValue: T? = nil, allowedValues: [U]) {
        self.name = name
        self.description = description
        self.defaultValue = defaultValue
        self.allowedValues = allowedValues.map(String.init(describing:))
    }
}

/// A header with a single value.
///
/// e.x.
///
///     Header-Name: hello
public typealias StringHeader = Header<String>

/// A header with a single value (must be an integer).
///
/// e.x.
///
///     Header-Name: 1
public typealias IntegerHeader = Header<Int>

/// A header with a single value (must be number, not necessarily an integer)
///
/// e.x.
///
///     Header-Name: 10.345
public typealias NumberHeader = Header<Double>

/// A header where the value is a comma-separated list of values.
///
/// e.x. (`CSVHeader<String>`)
///
///     Header-Name: hello,world
public typealias CSVHeader<SwiftType: Decodable> = Header<[SwiftType]>
