//
//  AudioMindUITests.swift
//  AudioMindUITests
//
//  Created by Mirvaben Dudhagara on 7/2/25.
//

import XCTest

final class AudioMindUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testExample() throws {
        let app = XCUIApplication()
        app.launch()
    }

}
