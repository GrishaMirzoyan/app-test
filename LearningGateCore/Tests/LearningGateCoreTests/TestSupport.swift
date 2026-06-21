import Foundation
import XCTest
@testable import LearningGateCore

enum Fixture {
    static func url(_ resource: String, _ ext: String) throws -> URL {
        if let url = Bundle.module.url(forResource: resource, withExtension: ext, subdirectory: "Fixtures") {
            return url
        }
        if let url = Bundle.module.url(forResource: resource, withExtension: ext) {
            return url
        }
        throw XCTSkip("Fixture \(resource).\(ext) not found in test bundle")
    }

    static func data(_ resource: String, _ ext: String) throws -> Data {
        try Data(contentsOf: try url(resource, ext))
    }
}

extension Card {
    /// A card due `secondsAgo` in the past, for scheduler/session tests.
    static func due(_ front: String, deck: DeckID, secondsAgo: TimeInterval = 60, now: Date = Date()) -> Card {
        var state = SchedulingState.new(due: now.addingTimeInterval(-secondsAgo))
        state.dueDate = now.addingTimeInterval(-secondsAgo)
        return Card(deckID: deck, front: front, back: "\(front)-back", scheduling: state)
    }
}

func makeTempDir() throws -> URL {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("lgc-test-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
}
