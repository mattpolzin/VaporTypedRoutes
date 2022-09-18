//
//  TypedRequest.swift
//  App
//
//  Created by Mathew Polzin on 10/22/19.
//

import Vapor
import NIO

/// A strongly-typed Request.
@dynamicMemberLookup
public final class TypedRequest<Context: RouteContext> {
    /// The underlying request.
    private let request: Request

    public private(set) lazy var query: Query = Query(request: self)
    public private(set) lazy var header: Headers = Headers(request: self)
    public private(set) lazy var response = ResponseBuilder<Context>(request: self)

    public subscript<T>(dynamicMember path: KeyPath<Request, T>) -> T {
        return request[keyPath: path]
    }

    public var underlyingRequest: Request { return request }

    public init(underlyingRequest: Request) {
        request = underlyingRequest
    }

    public func decodeBody(using decoder: ContentDecoder) throws -> Context.RequestBodyType {
        return try request.content.decode(Context.RequestBodyType.self, using: decoder)
    }

    public func decodeBody() throws -> Context.RequestBodyType {
        if request.content.contentType == nil {
            request.headers.contentType = Context.defaultContentType
        }
        return try request.content.decode(Context.RequestBodyType.self)
    }
}
