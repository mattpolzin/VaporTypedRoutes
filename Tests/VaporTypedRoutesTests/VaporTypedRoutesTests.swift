import XCTest
import VaporTypedRoutes
import XCTVapor
import Vapor

final class VaporTypedRoutesTests: XCTestCase {
    func test_get() throws {
        let app = Application(.testing)
        defer { app.shutdown() }

        app.routes.get("hello", use: TestController.showRoute)

        try test(on: app)
    }

    @available(macOS 12, *)
    func test_async_get() throws {
        let app = Application(.testing)
        defer { app.shutdown() }

        app.routes.get("hello", use: AsyncTestController.showRoute)

        try test(on: app)
    }

    /// The shared test requests.
    func test(on app: Application) throws {
        try app.testable().test(.GET, "/hello", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.headers.contentType, .plainText)
            XCTAssertEqual(res.body.string, "Hello")
        })

        try app.testable().test(.GET, "/hello", beforeRequest: { req in
            req.headers = [
                "String-Header": "exampletext"
            ]
        }, afterResponse:  { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.headers.contentType, .plainText)
            XCTAssertEqual(res.body.string, "exampletext")
        })

        // Check that the header won't accept an incorrect type
        try app.testable().test(.GET, "/hello", beforeRequest: { req in
            req.headers = [
                "Int-Header": "exampletext"
            ]
        }, afterResponse:  { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.headers.contentType, .plainText)
            XCTAssertEqual(res.body.string, "Hello")
        })

        // Check that the header won't accept an incorrect type
        try app.testable().test(.GET, "/hello", beforeRequest: { req in
            req.headers = [
                "Int-Header": "2"
            ]
        }, afterResponse:  { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.headers.contentType, .plainText)
            XCTAssertEqual(res.body.string, "Int 2")
        })

        try app.testable().test(.GET, "/hello?failHard=t", afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
            XCTAssertEqual(res.headers.contentType, .plainText)
            XCTAssertEqual(res.body.string, "")
        })

        // Check that the query param won't accept an incorrect type
        try app.testable().test(.GET, "/hello?echo=a21f", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.headers.contentType, .plainText)
            XCTAssertEqual(res.body.string, "Hello")
        })

        try app.testable().test(.GET, "/hello?echo=10", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.headers.contentType, .plainText)
            XCTAssertEqual(res.body.string, "10")
        })
    }
}

struct TestShowRouteContext: RouteContext {
    typealias RequestBodyType = EmptyRequestBody

    static var defaultContentType: HTTPMediaType? = .plainText

    static let shared = Self()

    let badQuery: StringQueryParam = .init(name: "failHard")
    let echo: IntegerQueryParam = .init(name: "echo")

    let stringHeader: StringHeader = .init(name: "String-Header")
    let intHeader: IntegerHeader = .init(name: "Int-Header")

    let success: ResponseContext<String> = .init { response in
        response.headers = Self.plainTextHeader
        response.status = .ok
    }

    let badRequest: CannedResponse<String> = .init(
        response: Response(
            status: .badRequest,
            headers: Self.plainTextHeader,
            body: .empty
        )
    )

    static let plainTextHeader = HTTPHeaders([
        (HTTPHeaders.Name.contentType.description, HTTPMediaType.plainText.serialize())
    ])
}

final class TestController {
    static func showRoute(_ req: TypedRequest<TestShowRouteContext>) -> EventLoopFuture<Response> {
        if req.query.badQuery != nil {
            return req.response.badRequest
        }
        // Check headers with higher precedence
        if let header = req.header.stringHeader {
            return req.response.success.encode(header)
        } else if let header = req.header.intHeader {
            return req.response.success.encode("Int \(header)")
        }
        if let text = req.query.echo {
            return req.response.success.encode("\(text)")
        }
        return req.response.success.encode("Hello")
    }
}

final class AsyncTestController {
    static func showRoute(req: TypedRequest<TestShowRouteContext>) async throws -> Response {
        if req.query.badQuery != nil {
            // This is clunky but I don't see a better option because subscripts can't be async
            return try await req.response.get(\.badRequest)
        }
        // Check headers with higher precedence
        if let header = req.header.stringHeader {
            return try await req.response.success.encode(header)
        } else if let header = req.header.intHeader {
            return try await req.response.success.encode("Int \(header)")
        }
        if let text = req.query.echo {
            return try await req.response.success.encode("\(text)")
        }
        return try await req.response.success.encode("Hello")
    }
}
