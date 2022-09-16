import XCTest
import VaporTypedRoutes
import XCTVapor
import Vapor

final class VaporTypedRoutesTests: XCTestCase {
    func test_get() throws {
        let app = Application(.testing)
        defer { app.shutdown() }

        app.routes.get("hello", use: TestController.showRoute)

        try app.testable().test(.GET, "/hello", afterResponse:  { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.headers.contentType, .plainText)
            XCTAssertEqual(res.body.string, "Hello")
        })

        try app.testable().test(.GET, "/hello?failHard=t", afterResponse:  { res in
            print(res)
            let resBodyData = Data(buffer: res.body)
            print(String(data: resBodyData, encoding: .utf8)!)

            XCTAssertEqual(res.status, .badRequest)
            XCTAssertEqual(res.headers.contentType, .plainText)
            XCTAssertEqual(res.body.string, "")
        })

        try app.testable().test(.GET, "/hello?echo=10", afterResponse:  { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.headers.contentType, .plainText)
            XCTAssertEqual(res.body.string, "10")
        })
    }

    @available(macOS 12, *)
    func test_async_get() throws {
        let app = Application(.testing)
        defer { app.shutdown() }

        app.routes.get("hello", use: AsyncTestController.showRoute)

        try app.testable().test(.GET, "/hello", afterResponse:  { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.headers.contentType, .plainText)
            XCTAssertEqual(res.body.string, "Hello")
        })

        try app.testable().test(.GET, "/hello?failHard=t", afterResponse:  { res in
            XCTAssertEqual(res.status, .badRequest)
            XCTAssertEqual(res.headers.contentType, .plainText)
            XCTAssertEqual(res.body.string, "")
        })

        try app.testable().test(.GET, "/hello?echo=10", afterResponse:  { res in
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
        if let text = req.query.echo {
            return try await req.response.success.encode("\(text)")
        }
        return try await req.response.success.encode("Hello")
    }
}
