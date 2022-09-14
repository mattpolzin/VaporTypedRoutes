//
//  RoutesBuilder+RouteContext.swift
//  App
//
//  Created by Mathew Polzin on 10/23/19.
//

import Vapor

extension RoutesBuilder {
	/// A `GET` request handler using `TypedRequest`.
	/// - Parameters:
	///   - path: A variadic set of `TypedPathComponent`s describing the path of the route.
	///   - use: A closure that takes a `TypedRequest`, can throw errors, and returns a `Response`.
    @discardableResult
    public func get<Context, Response>(
        _ path: TypedPathComponent...,
        use closure: @escaping (TypedRequest<Context>) throws -> Response
    ) -> Route
        where Context: RouteContext, Response: ResponseEncodable
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
        use closure: @escaping (TypedRequest<Context>) throws -> Response
    ) -> Route
        where Context: RouteContext, Response: ResponseEncodable
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
        use closure: @escaping (TypedRequest<Context>) throws -> Response
    ) -> Route
        where Context: RouteContext, Response: ResponseEncodable
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
        use closure: @escaping (TypedRequest<Context>) throws -> Response
    ) -> Route
        where Context: RouteContext, Response: ResponseEncodable
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
        use closure: @escaping (TypedRequest<Context>) throws -> Response
    ) -> Route
        where Context: RouteContext, Response: ResponseEncodable
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
        use closure: @escaping (TypedRequest<Context>) throws -> Response
    ) -> Route
        where Context: RouteContext, Response: ResponseEncodable
    {
        let wrappingClosure = { (request: Vapor.Request) -> Response in
            return try closure(.init(underlyingRequest: request))
        }

        let responder = BasicResponder { request in
            if case .collect(let max) = body, request.body.data == nil {
                return request.body.collect(max: max?.value ?? request.application.routes.defaultMaxBodySize.value).flatMapThrowing { _ in
                    return try wrappingClosure(request)
                }.encodeResponse(for: request)
            } else {
                return try wrappingClosure(request)
                    .encodeResponse(for: request)
            }
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
