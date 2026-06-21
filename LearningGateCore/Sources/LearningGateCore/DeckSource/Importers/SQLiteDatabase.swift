import Foundation
import CSQLite

/// Minimal read-only SQLite wrapper over the system `libsqlite3`, used by the
/// .apkg importer. Returns rows as arrays of optional strings — enough to read
/// Anki's `col`, `cards`, and `notes` tables without pulling in an ORM.
final class SQLiteDatabase {
    private var handle: OpaquePointer?

    init(path: String) throws {
        if sqlite3_open_v2(path, &handle, SQLITE_OPEN_READONLY, nil) != SQLITE_OK {
            let message = handle.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown error"
            sqlite3_close(handle)
            handle = nil
            throw LearningGateError.importFailed("SQLite open failed: \(message)")
        }
    }

    deinit {
        sqlite3_close(handle)
    }

    /// Run a query and return all rows as `[[String?]]`.
    func query(_ sql: String) throws -> [[String?]] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK else {
            let message = handle.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown error"
            throw LearningGateError.importFailed("SQLite prepare failed: \(message)")
        }
        defer { sqlite3_finalize(statement) }

        let columnCount = Int(sqlite3_column_count(statement))
        var rows: [[String?]] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            var row: [String?] = []
            row.reserveCapacity(columnCount)
            for index in 0..<columnCount {
                if let text = sqlite3_column_text(statement, Int32(index)) {
                    row.append(String(cString: text))
                } else {
                    row.append(nil)
                }
            }
            rows.append(row)
        }
        return rows
    }
}
