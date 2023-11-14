@testable import DangerSwiftCoverage
import XCTest

final class XcodeBuildCoverageParserTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockedXcCovJSONParser.xcresultResult = XcresultJSONResponse.data(using: .utf8)
    }

    override func tearDown() {
        super.tearDown()
        MockedXcCovJSONParser.receivedXcresultFile = nil
        MockedXcCovJSONParser.xcresultResult = nil
    }

    func testItHidesProjectCoverage() throws {
        let files = ["/Users/franco/Projects/swift/Sources/Danger/BitBucketServerDSL.swift",
                     "/Users/franco/Projects/swift/Sources/Danger/Danger.swift",
                     "/Users/franco/Projects/swift/Sources/RunnerLib/Files Import/ImportsFinder.swift",
                     "/Users/franco/Projects/swift/Sources/RunnerLib/HelpMessagePresenter.swift"]

        let result = try XcodeBuildCoverageParser.coverage(xcresultBundlePath: "derived", files: files, excludedFiles: [], excludedTargets: [], hideProjectCoverage: true, xcCovParser: MockedXcCovJSONParser.self)

        XCTAssertTrue(result.messages.isEmpty)
    }

    func testItFiltersTheExcludedTarget() throws {
        let files = ["/Users/franco/Projects/swift/Sources/Danger/BitBucketServerDSL.swift",
                     "/Users/franco/Projects/swift/Sources/Danger/Danger.swift",
                     "/Users/franco/Projects/swift/Sources/RunnerLib/Files Import/ImportsFinder.swift",
                     "/Users/franco/Projects/swift/Sources/RunnerLib/HelpMessagePresenter.swift"]

        let result = try XcodeBuildCoverageParser.coverage(xcresultBundlePath: "derived", files: files, excludedFiles: [], excludedTargets: [.exact("RunnerLib.xctest")], xcCovParser: MockedXcCovJSONParser.self)

        XCTAssertEqual(result.messages, ["Project coverage: 50.09%"])

        let firstSection = result.sections[0]
        XCTAssertEqual(firstSection.titleText, "Danger.framework: Coverage: 43.44")
        XCTAssertEqual(firstSection.items, [
            ReportFile(fileName: "BitBucketServerDSL.swift", coverage: 100),
            ReportFile(fileName: "Danger.swift", coverage: 0),
        ])

        XCTAssertEqual(result.sections.count, 1)
    }

    func testItFiltersTheExcludedTargetByRegexp() throws {
        let files = ["/Users/franco/Projects/swift/Sources/Danger/BitBucketServerDSL.swift",
                     "/Users/franco/Projects/swift/Sources/Danger/Danger.swift",
                     "/Users/franco/Projects/swift/Sources/RunnerLib/Files Import/ImportsFinder.swift",
                     "/Users/franco/Projects/swift/Sources/RunnerLib/HelpMessagePresenter.swift"]

        let result = try XcodeBuildCoverageParser.coverage(xcresultBundlePath: "derived", files: files, excludedFiles: [], excludedTargets: [.regex("\\.xctest$")], xcCovParser: MockedXcCovJSONParser.self)

        XCTAssertEqual(result.messages, ["Project coverage: 50.09%"])

        let firstSection = result.sections[0]
        XCTAssertEqual(firstSection.titleText, "Danger.framework: Coverage: 43.44")
        XCTAssertEqual(firstSection.items, [
            ReportFile(fileName: "BitBucketServerDSL.swift", coverage: 100),
            ReportFile(fileName: "Danger.swift", coverage: 0),
        ])

        XCTAssertEqual(result.sections.count, 1)
    }
    
    func testItFiltersTheExcludedFileByRegexp() throws {
        let files = ["/Users/franco/Projects/swift/Sources/Danger/PersonServiceTest.swift",
                     "/Users/franco/Projects/swift/Sources/Danger/UserView.swift",
                     "/Users/franco/Projects/swift/Sources/Danger/View+DragAndDrop.swift",
                     "/Users/franco/Projects/swift/Sources/Danger/Danger.swift",
                     "/Users/franco/Projects/swift/Sources/RunnerLib/Files Import/ImportsFinder.swift",
                     "/Users/franco/Projects/swift/Sources/RunnerLib/HelpMessagePresenter.swift"]

        let result = try XcodeBuildCoverageParser.coverage(xcresultBundlePath: "derived", files: files, excludedFiles: [.regex("^(.)+(View|Test)|^View\\+(.)+")], excludedTargets: [], xcCovParser: MockedXcCovJSONParser.self)

        XCTAssertEqual(result.messages, ["Project coverage: 50.09%"])

        let secondSection = result.sections[1]
        XCTAssertEqual(secondSection.titleText, "RunnerLib.xctest: Coverage: 66.67")
        XCTAssertEqual(secondSection.items, [
            ReportFile(fileName: "ImportsFinder.swift", coverage: 100),
            ReportFile(fileName: "HelpMessagePresenter.swift", coverage: 100),
        ])
        
        let firstSection = result.sections[0]
        XCTAssertEqual(firstSection.titleText, "Danger.framework: Coverage: 43.44")
        XCTAssertEqual(firstSection.items, [
            ReportFile(fileName: "Danger.swift", coverage: 0)
        ])

        XCTAssertEqual(result.sections.count, 2)
    }

    func testItFiltersTheExcludedFile() throws {
        let files = ["/Users/franco/Projects/swift/Sources/Danger/BitBucketServerDSL.swift",
                     "/Users/franco/Projects/swift/Sources/Danger/Danger.swift",
                   ]

        let result = try XcodeBuildCoverageParser.coverage(xcresultBundlePath: "derived", files: files, excludedFiles: [.exact("Danger.swift")], excludedTargets: [], xcCovParser: MockedXcCovJSONParser.self)

        XCTAssertEqual(result.messages, ["Project coverage: 50.09%"])

        let firstSection = result.sections[0]
        XCTAssertEqual(firstSection.titleText, "Danger.framework: Coverage: 43.44")
        XCTAssertEqual(firstSection.items, [
            ReportFile(fileName: "BitBucketServerDSL.swift", coverage: 100)
        ])

        XCTAssertEqual(result.sections.count, 1)
    }
    
    func testItFiltersTheEmptyTargets() throws {
        let files = ["/Users/franco/Projects/swift/Sources/Danger/BitBucketServerDSL.swift",
                     "/Users/franco/Projects/swift/Sources/Danger/Danger.swift"]

        let result = try XcodeBuildCoverageParser.coverage(xcresultBundlePath: "derived", files: files, excludedFiles: [], excludedTargets: [], xcCovParser: MockedXcCovJSONParser.self)

        let firstSection = result.sections[0]
        XCTAssertEqual(firstSection.titleText, "Danger.framework: Coverage: 43.44")
        XCTAssertEqual(firstSection.items, [
            ReportFile(fileName: "BitBucketServerDSL.swift", coverage: 100),
            ReportFile(fileName: "Danger.swift", coverage: 0),
        ])

        XCTAssertEqual(result.sections.count, 1)
    }

    func testItReturnsTheCoverageWhenThereAreNoTargets() throws {
        let result = try XcodeBuildCoverageParser.coverage(xcresultBundlePath: "derived", files: [], excludedFiles: [], excludedTargets: [], xcCovParser: MockedXcCovJSONParser.self)

        XCTAssertEqual(result.messages, [])
        XCTAssertEqual(result.sections.count, 0)
    }

    func testItCorrectlyParsesTheXcresult() throws {
        let files = ["/Users/franco/Projects/swift/Sources/Danger/BitBucketServerDSL.swift",
                     "/Users/franco/Projects/swift/Sources/Danger/Danger.swift",
                     "/Users/franco/Projects/swift/Sources/RunnerLib/Files Import/ImportsFinder.swift",
                     "/Users/franco/Projects/swift/Sources/RunnerLib/HelpMessagePresenter.swift"]

        let result = try XcodeBuildCoverageParser.coverage(xcresultBundlePath: "derived", files: files, excludedFiles: [], excludedTargets: [], xcCovParser: MockedXcCovJSONParser.self)

        XCTAssertEqual(MockedXcCovJSONParser.receivedXcresultFile, "derived")
        XCTAssertEqual(result.messages, ["Project coverage: 50.09%"])
        let firstSection = result.sections[0]
        XCTAssertEqual(firstSection.titleText, "Danger.framework: Coverage: 43.44")
        XCTAssertEqual(firstSection.items, [
            ReportFile(fileName: "BitBucketServerDSL.swift", coverage: 100),
            ReportFile(fileName: "Danger.swift", coverage: 0),
        ])

        XCTAssertEqual(result.sections.count, 2)
    }

    func testWhenXcresultFileIsInvalidThrowsAnError() throws {
        MockedXcCovJSONParser.xcresultResult = nil

        XCTAssertThrowsError(try XcodeBuildCoverageParser.coverage(xcresultBundlePath: "derived", files: [], excludedFiles: [], excludedTargets: [], xcCovParser: MockedXcCovJSONParser.self)) { error in
            XCTAssertEqual(error.localizedDescription, "Invalid coverage report")
        }
    }
}

private struct MockedXcCovJSONParser: XcCovJSONParsing {
    static var xcresultResult: Data?
    static var receivedXcresultFile: String?

    static func json(fromXcresultFile file: String) throws -> Data {
        receivedXcresultFile = file
        if let result = xcresultResult {
            return result
        } else {
            throw XcCovJSONParserError.invalidData
        }
    }
}

extension ReportFile: Equatable {
    public static func == (lhs: ReportFile, rhs: ReportFile) -> Bool {
        lhs.fileName == rhs.fileName &&
            lhs.coverage == rhs.coverage
    }
}
