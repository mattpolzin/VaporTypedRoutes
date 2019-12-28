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

public protocol AbstractRouteContext {
    static var requestBodyType: Any.Type { get }
    static var requestQueryParams: [AbstractQueryParam] { get }

    static var responseBodyTuples: [(statusCode: Int, contentType: HTTPMediaType?, responseBodyType: Any.Type)] { get }
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
    associatedtype RequestBodyType: Decodable

    static var shared: Self { get }
}

extension RouteContext {
    public static var requestBodyType: Any.Type { return RequestBodyType.self }

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

    public static var requestQueryParams: [AbstractQueryParam] {
        let context = Self.shared

        let mirror = Mirror(reflecting: context)

        return mirror
            .children
            .compactMap { property in property.value as? AbstractQueryParam }
    }
}
