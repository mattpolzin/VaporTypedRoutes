//
//  RoutesBuilderContext+Concurrency.swift
//  
//
//  Created by Charlie Welsh on 9/14/22.
//

import Vapor

@available(macOS 12, *)
extension RoutesBuilder {
    /// A `GET` request handler using `TypedRequest`.
    /// - Parameters:
    ///   - path: A variadic set of `TypedPathComponent`s describing the path of the route.
    ///   - use: A closure that takes a `TypedRequest`, can throw errors, and returns a `Response`.
    @discardableResult
    public func get<Context, Response>(
        _ path: TypedPathComponent...,
        use closure: @escaping (TypedRequest<Context>) async throws -> Response
    ) -> Route
    where Context: RouteContext, Response: AsyncResponseEncodable
    {
        return self.on(.GET, path, use: closure)
    }

    /// A `POST` request handler using `TypedRequest`.
    /// - Parameters:
    ///   - path: A variadic set of `TypedPathComponent`s describing the path of the route.
    ///   - use: A closure that takes a `TypedRequest`, can throw errors, and returns a `Response`.
    @discardableResult
    public func post<Context, Response>(
        _ path: TypedPathComponent...,
        use closure: @escaping (TypedRequest<Context>) async throws -> Response
    ) -> Route
    where Context: RouteContext, Response: AsyncResponseEncodable
    {
        return self.on(.POST, path, use: closure)
    }

    /// A `PATCH` request handler using `TypedRequest`.
    /// - Parameters:
    ///   - path: A variadic set of `TypedPathComponent`s describing the path of the route.
    ///   - use: A closure that takes a `TypedRequest`, can throw errors, and returns a `Response`.
    @discardableResult
    public func patch<Context, Response>(
        _ path: TypedPathComponent...,
        use closure: @escaping (TypedRequest<Context>) async throws -> Response
    ) -> Route
    where Context: RouteContext, Response: AsyncResponseEncodable
    {
        return self.on(.PATCH, path, use: closure)
    }

    /// A `PUT` request handler using `TypedRequest`.
    /// - Parameters:
    ///   - path: A variadic set of `TypedPathComponent`s describing the path of the route.
    ///   - use: A closure that takes a `TypedRequest`, can throw errors, and returns a `Response`.
    @discardableResult
    public func put<Context, Response>(
        _ path: TypedPathComponent...,
        use closure: @escaping (TypedRequest<Context>) async throws -> Response
    ) -> Route
    where Context: RouteContext, Response: AsyncResponseEncodable
    {
        return self.on(.PUT, path, use: closure)
    }

    /// A `DELETE` request handler using `TypedRequest`.
    /// - Parameters:
    ///   - path: A variadic set of `TypedPathComponent`s describing the path of the route.
    ///   - use: A closure that takes a `TypedRequest`, can throw errors, and returns a `Response`.
    @discardableResult
    public func delete<Context, Response>(
        _ path: TypedPathComponent...,
        use closure: @escaping (TypedRequest<Context>) async throws -> Response
    ) -> Route
    where Context: RouteContext, Response: AsyncResponseEncodable
    {
        return self.on(.DELETE, path, use: closure)
    }

    /// A generic request type handler using `TypedRequest`.
    /// - Parameters:
    ///   - method: The HTTP method the route uses.
    ///   - path: An array of `TypedPathComponent`s describing the path of the route.
    ///   - body: An `HTTPBodyStreamStrategy` to get the body with.
    ///   - use: A closure that takes a `TypedRequest`, can throw errors, and returns a `Response`.
    @discardableResult
    public func on<Context, Response>(
        _ method: HTTPMethod,
        _ path: [TypedPathComponent],
        body: HTTPBodyStreamStrategy = .collect,
        use closure: @escaping (TypedRequest<Context>) async throws -> Response
    ) -> Route
    where Context: RouteContext, Response: AsyncResponseEncodable
    {

        let responder = AsyncBasicResponder { request in
            if case .collect(let max) = body, request.body.data == nil {
                _ = try await request.body.collect(max: max?.value ?? request.application.routes.defaultMaxBodySize.value).get()
            }
            return try await closure(.init(underlyingRequest: request)).encodeResponse(for: request)
        }
        let route = Route(
            method: method,
            path: path.map(\.vaporPathComponent),
            responder: responder,
            requestType: Context.RequestBodyType.self,
            responseType: Context.self
        )

        for pathComponent in path {
            if case let .parameter(name, meta) = pathComponent {
                route.userInfo["typed_parameter:\(name)"] = meta
            }
        }

        self.add(route)
        return route
    }
}
