import XCTest
import VaporTypedRoutes
import XCTVapor
import Vapor

final class VaporTypedRoutesTests: XCTestCase {
    func test_get() async throws {
        let app = try await Application.make(.testing)

        app.routes.get("hello", use: TestController.showRoute)

        try await app.testable().test(.GET, "/hello") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.headers.contentType, .plainText)
            XCTAssertEqual(res.body.string, "Hello")
        }

        try await app.testable().test(.GET, "/hello?failHard=t") { res async in
            print(res)
            let resBodyData = Data(buffer: res.body)
            print(String(data: resBodyData, encoding: .utf8)!)

            XCTAssertEqual(res.status, .badRequest)
            XCTAssertEqual(res.headers.contentType, .plainText)
            XCTAssertEqual(res.body.string, "")
        }

        try await app.testable().test(.GET, "/hello?echo=10") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.headers.contentType, .plainText)
            XCTAssertEqual(res.body.string, "10")
        }

        try await app.asyncShutdown()
    }

    @available(macOS 12, *)
    func test_async_get() async throws {
        let app = try await Application.make(.testing)

        app.routes.get("hello", use: AsyncTestController.showRoute)

        try await app.testable().test(.GET, "/hello") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.headers.contentType, .plainText)
            XCTAssertEqual(res.body.string, "Hello")
        }

        try await app.testable().test(.GET, "/hello?failHard=t") { res async in
            XCTAssertEqual(res.status, .badRequest)
            XCTAssertEqual(res.headers.contentType, .plainText)
            XCTAssertEqual(res.body.string, "")
        }

        try await app.testable().test(.GET, "/hello?echo=10") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.headers.contentType, .plainText)
            XCTAssertEqual(res.body.string, "10")
        }

        try await app.asyncShutdown()
    }
}

struct TestShowRouteContext: RouteContext {
    typealias RequestBodyType = EmptyRequestBody

    static let defaultContentType: HTTPMediaType? = .plainText

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
