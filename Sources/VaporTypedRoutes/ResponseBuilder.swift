//
//  ResponseBuilder.swift
//  App
//
//  Created by Mathew Polzin on 10/23/19.
//

import Vapor

@dynamicMemberLookup
public struct ResponseBuilder<Context: RouteContext> {
	/// The context for the route.
    public let context: Context = .shared
	/// The associated request for the route.
    private unowned var request: TypedRequest<Context>

	/// Takes a KeyPath to a response context and returns a `ResponseEncoder` using the given `ResponseContext`.
	///
	/// - Parameters:
	///   - dynamicMember: A KeyPath from the route's `Context` to a  `ResponseContext` to use in the `ResponseEncoder`.
    public subscript<T>(dynamicMember path: KeyPath<Context, ResponseContext<T>>) -> ResponseEncoder<T> {
        return .init(request: request, modifiers: [context[keyPath: path].configure])
    }

	/// Takes a KeyPath to a canned response and returns the canned response.
	///
	/// This is a function because subscripts can't be asynchronous or throw.
	///
	/// - Parameters:
	///   - path: A KeyPath from the route's `Context` to a  `CannedResponse` to return.
	public func get<T>(_ path: KeyPath<Context, CannedResponse<T>>) async throws -> Response {
		return try await self.subscript(dynamicMember: path).get()
	}

	/// Takes a KeyPath to a canned response and returns an `EventLoopFuture` with the canned response.
	///
	/// - Parameters:
	///   - dynamicMember: A KeyPath from the route's `Context` to a  `CannedResponse` to return in the `EventLoopFuture`.
    public subscript<T>(dynamicMember path: KeyPath<Context, CannedResponse<T>>) -> EventLoopFuture<Response> {
		return self.subscript(dynamicMember: path)
    }

	/// Takes a KeyPath to a canned response and returns the canned response.
	///
	/// This is a function so it can be shared between Futures and async/await.
	///
	/// - Parameters:
	///   - dynamicMember: A KeyPath from the route's `Context` to a  `CannedResponse` to return.
	private func `subscript`<T>(dynamicMember path: KeyPath<Context, CannedResponse<T>>) -> EventLoopFuture<Response> {
		return request.eventLoop.makeSucceededFuture(context[keyPath: path].response)
	}

	/// Create a response builder with a given `TypedRequest`.
    public init(request: TypedRequest<Context>) {
        self.request = request
    }

	/// A response encoder for a given body type.
    public struct ResponseEncoder<ResponseBodyType: ResponseEncodable> {
		/// The associated request.
        private let request: TypedRequest<Context>
		/// A set of functions used to modify the request.
        private let modifiers: [(inout Response) -> Void]

		/// Returns an `EventLoopFuture` containing the encoded response, using a given instance of `ResponseBodyType`.
		/// - Parameters:
		///   - response: The instance of `ResponseBodyType` to use to generate the response.
        public func encode(_ response: ResponseBodyType) -> EventLoopFuture<Response> {
            let encodedResponseFuture = response
                .encodeResponse(for: request.underlyingRequest)

            return encodedResponseFuture.map { encodedResponse in
                self.modifiers
                    .reduce(into: encodedResponse) { resp, mod in mod(&resp) }
            }
        }

		/// Encodes the response using a given instance of `ResponseBodyType`.
		/// - Parameters:
		///   - response: The instance of `ResponseBodyType` to use to generate the response.
		public func encode(_ response: ResponseBodyType) async throws -> Response {
			try await self.encode(response).get()
		}

		/// Create a `ResponseEncoder` using a given `TypedRequest` and set of modifiers.
		/// - Parameters:
		///   - request: The `TypedRequest` to use to generate the `Response`.
		///   - modifiers: The functions to use to modify thr request.
        init(request: TypedRequest<Context>, modifiers: [(inout Response) -> Void]) {
            self.request = request
            self.modifiers = modifiers
        }
    }
}

public extension ResponseBuilder.ResponseEncoder where ResponseBodyType == EmptyResponseBody {
	/// Encodes and returns an empty response in an `EventLoopFuture`.
    func encodeEmptyResponse() -> EventLoopFuture<Response> {
        return encode(EmptyResponseBody())
    }

	/// Encodes and returns an empty response.
	func encodeEmptyResponse() async throws -> Response {
		try await self.encodeEmptyResponse().get()
	}
}
