//
//  JSONRouteContextTests.swift
//  
//
//  Created by Mathew Polzin on 5/7/20.
//

import Vapor
import VaporTypedRoutes
import XCTest

final class JSONRouteContextTests: XCTestCase {
    func test_defaultContentType() {
        XCTAssertEqual(TestContext.defaultContentType, .json)
    }
}

fileprivate struct TestContext: JSONRouteContext, Sendable {
    typealias RequestBodyType = EmptyRequestBody

    static let shared: TestContext = .init()
}
