//
//  RoutesBuilder+RouteContext.swift
//  App
//
//  Created by Mathew Polzin on 10/23/19.
//

import Vapor

extension RoutesBuilder {

    @discardableResult
    public func get<Context, Response>(
        _ path: TypedPathComponent...,
        use closure: @escaping (TypedRequest<Context>) throws -> Response
    ) -> Route
        where Context: RouteContext, Response: ResponseEncodable
    {
        return self.on(.GET, path, use: closure)
    }

    @discardableResult
    public func post<Context, Response>(
        _ path: TypedPathComponent...,
        use closure: @escaping (TypedRequest<Context>) throws -> Response
    ) -> Route
        where Context: RouteContext, Response: ResponseEncodable
    {
        return self.on(.POST, path, use: closure)
    }

    @discardableResult
    public func patch<Context, Response>(
        _ path: TypedPathComponent...,
        use closure: @escaping (TypedRequest<Context>) throws -> Response
    ) -> Route
        where Context: RouteContext, Response: ResponseEncodable
    {
        return self.on(.PATCH, path, use: closure)
    }

    @discardableResult
    public func put<Context, Response>(
        _ path: TypedPathComponent...,
        use closure: @escaping (TypedRequest<Context>) throws -> Response
    ) -> Route
        where Context: RouteContext, Response: ResponseEncodable
    {
        return self.on(.PUT, path, use: closure)
    }

    @discardableResult
    public func delete<Context, Response>(
        _ path: TypedPathComponent...,
        use closure: @escaping (TypedRequest<Context>) throws -> Response
    ) -> Route
        where Context: RouteContext, Response: ResponseEncodable
    {
        return self.on(.DELETE, path, use: closure)
    }

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
