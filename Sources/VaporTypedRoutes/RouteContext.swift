//
//  RouteContext.swift
//  App
//
//  Created by Mathew Polzin on 10/23/19.
//

import Vapor

public struct EmptyRequestBody: Decodable {}
public struct EmptyResponseBody: Encodable {}

extension EmptyResponseBody: ResponseEncodable {
    public func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
        return "".encodeResponse(for: request)
    }
}

@available(macOS 12, *)
extension EmptyRequestBody: AsyncResponseEncodable {
	public func encodeResponse(for request: Request) async throws -> Response {
		return try await "".encodeResponse(for: request)
	}
}

public protocol AbstractRouteContext {
    static var requestBodyType: Any.Type { get }

    /// The default Content-Type of the response for the given context
    /// assuming no Content-Type is specified by the request headers.
    static var defaultContentType: HTTPMediaType? { get }

    static var requestQueryParams: [AbstractQueryParam] { get }

    static var responseBodyTuples: [(statusCode: Int, contentType: HTTPMediaType?, responseBodyType: Any.Type)] { get }
}

public protocol AbstractJSONRouteContext: AbstractRouteContext {}
extension AbstractJSONRouteContext {
    public static var defaultContentType: HTTPMediaType? { .json }
}

/// A RouteContext holds the context for a particular route/endpoint.
///
/// You must specify the request body type (although it may be a typealias to
/// `EmptyRequestBody`). Additionally, you must expose a shared instance
/// of the context that can be used to create a mirror of the context.
///
/// Beyond those requirements, you specify the possible responses for this context
/// as properties with types conforming to `AbstractResponseContextType`.
/// You also specify any query parameters as `QueryParam` properties.
/// Two common response context types are `CannedResponse` (when you want
/// to provide a premade response, such as an error response) and `ResponseContext`
/// (which is initialized with a configuration closure that you can use to apply any transformation
/// or replacement on a `Response`).
///
/// **Example** (a context for a GET endpoint):
///
///     struct SayHelloRouteContext: RouteContext {
///         typealias RequestBodyType = EmptyRequestBody
///
///         static let shared = Self()
///
///         let queryParam: StringQueryParam = .init(name: "arg")
///
///         let success: ResponseContext<String> = .init({ response in
///             response.status = .ok
///         })
///
///         let badRequest: CannedResponse<String> = .init(
///             response: Response(
///                 status: .badRequest,
///                 body: .empty
///             )
///         )
///     }
public protocol RouteContext: AbstractRouteContext {
	/// The type to expect for the request's body.
    associatedtype RequestBodyType: Decodable

	/// A shared instance of the type.
    static var shared: Self { get }
}

/// A `RouteContext` with the `defaultContentType` of
/// application/json.
public protocol JSONRouteContext: RouteContext & AbstractJSONRouteContext {}

extension RouteContext {
	/// The type of the request body.
    public static var requestBodyType: Any.Type { return RequestBodyType.self }

	/// An array containing the status code, MIME type, and body type of all the route context's `ResponseContext`s.
	///
	/// Any variable you declare that conforms to `AbstractResponseContextType` will be returned.
	///
	/// - Parameters:
	///   - statusCode: An integer containing the HTTP status code of the response.
	///   - contentType: The `HTTPMediaType` of the response (if any).'
	///   - responseBodyType: The Swift type returned as the response body.
    public static var responseBodyTuples: [(statusCode: Int, contentType: HTTPMediaType?, responseBodyType: Any.Type)] {
        let context = Self.shared

        let mirror = Mirror(reflecting: context)

        let responseContexts = mirror
            .children
            .compactMap { property in property.value as? AbstractResponseContextType }

        return responseContexts
            .map { responseContext in
                var dummyResponse = Response()
                responseContext.configure(&dummyResponse)

                let statusCode = Int(dummyResponse.status.code)
                let contentType = dummyResponse.headers.contentType

                return (
                    statusCode: statusCode,
                    contentType: contentType,
                    responseBodyType: responseContext.responseBodyType
                )
        }
    }

	/// The abstract query parameters for the `RouteContext`.
	///
	/// Any variable you declare that conforms to `AbstractQueryParam` in the conforming object will be returned.
    public static var requestQueryParams: [AbstractQueryParam] {
        let context = Self.shared

        let mirror = Mirror(reflecting: context)

        return mirror
            .children
            .compactMap { property in property.value as? AbstractQueryParam }
    }
}
