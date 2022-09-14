//
//  ResponseContext.swift
//  App
//
//  Created by Mathew Polzin on 10/23/19.
//

import Vapor

/// A type that represents an abstract response context.
///
/// The configured response is what gets sent to the user.
public protocol AbstractResponseContextType {
	/// A function used to configure the response.
	/// - Parameters:
	///   - response: The response to configure.
    var configure: (inout Response) -> Void { get }
	/// The type of the response's body.
    var responseBodyType: Any.Type { get }
}

/// A type that represents a concrete response context.
public protocol ResponseContextType: AbstractResponseContextType {
	/// The associated response body type.
    associatedtype ResponseBodyType: ResponseEncodable
}

extension ResponseContextType {
	/// The type of the response body.
    public var responseBodyType: Any.Type { return ResponseBodyType.self }
}

/// A concrete response context with an associated body type.
public struct ResponseContext<ResponseBodyType: ResponseEncodable>: ResponseContextType {
    public let configure: (inout Response) -> Void

	/// Create a response context with a given configuration function.
    public init(_ configure: @escaping (inout Response) -> Void) {
        self.configure = { response in
            configure(&response)
        }
    }
}

/// A response context that always sends a given pre-determined response.
public struct CannedResponse<ResponseBodyType: ResponseEncodable>: ResponseContextType {
    public let configure: (inout Response) -> Void
	/// The response to send to the user.
    public let response: Response

	/// Create a canned response with a given response to send.
	/// - Parameters:
	///   - response: The response to send to the user.
    public init(response cannedResponse: Response) {
        self.response = cannedResponse
        self.configure = { response in
            response = cannedResponse
        }
    }
}
