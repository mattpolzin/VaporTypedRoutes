//
//  TypedRequest+Query.swift
//  
//
//  Created by Mathew Polzin on 12/28/19.
//

extension TypedRequest {
	/// An object containing the various 
    @dynamicMemberLookup
    public final class Query {
		/// The parent request.
        private unowned var typedRequest: TypedRequest
		/// The context for the request.
        private let context: Context = .shared

		/// Initialize from a given TypedRequest instance.
        init(request: TypedRequest) {
            self.typedRequest = request
        }

		/// Get a string value for a given query param.
        private func getString(at name: String) -> String? {
            return typedRequest
                .underlyingRequest
                .query[String.self, at: name]
        }

		/// Get an array of strings for a given comma-separated query param.
		private func getStringArray(at name: String) -> [String]? {
            return getString(at: name)?
                .split(separator: ",")
                .map(String.init)
        }

        /// Get a single query value using a given key path in the associated `Context` object.
		/// - Parameters:
		///   - dynamicMember: A `KeyPath` from the `Context` object to a `QueryParam`.
        public subscript<T: LosslessStringConvertible>(dynamicMember path: KeyPath<Context, QueryParam<T>>) -> T? {
            return getString(at: context[keyPath: path].name)
                .flatMap(T.init) ?? context[keyPath: path].defaultValue
        }

        /// Get an array of values using a given key path to an array in the associated `Context` object.
		/// - Parameters:
		///   - dynamicMember: A `KeyPath` from the `Context` object to a `QueryParam` where the value is an array.
        public subscript<T: LosslessStringConvertible>(dynamicMember path: KeyPath<Context, QueryParam<[T]>>) -> [T]? {
            return getStringArray(at: context[keyPath: path].name)?
                .compactMap(T.init) ?? context[keyPath: path].defaultValue
        }

        // TODO: add better support for dictionary
        //      needs modifications to or replacement of the default
        //      parser which throws fatal error if requesting a path
        //      that is not in the query params.
        //        public subscript(dynamicMember path: KeyPath<Context, NestedQueryParam<String>>) -> String? {
        //            return typedRequest
        //                .underlyingRequest
        //                .query[String.self, at: context[keyPath: path].path]
        //                ?? context[keyPath: path].defaultValue
        //        }
    }
}
