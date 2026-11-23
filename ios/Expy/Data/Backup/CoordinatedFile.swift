import Foundation

/// File access through `NSFileCoordinator`, as iCloud Drive requires: a
/// coordinated read downloads a file that's only in iCloud, and a
/// coordinated write hands the new version to iCloud for upload.
enum CoordinatedFile {
    static func write(_ data: Data, to url: URL) throws {
        var coordination: NSError?
        var failure: Error?
        NSFileCoordinator().coordinate(writingItemAt: url, options: .forReplacing, error: &coordination) { target in
            do { try data.write(to: target, options: .atomic) } catch { failure = error }
        }
        if let error = coordination ?? failure { throw error }
    }

    static func read(_ url: URL) throws -> Data {
        var coordination: NSError?
        var result: Result<Data, Error> = .failure(CocoaError(.fileReadUnknown))
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordination) { source in
            result = Result { try Data(contentsOf: source) }
        }
        if let coordination { throw coordination }
        return try result.get()
    }

    static func delete(_ url: URL) throws {
        var coordination: NSError?
        var failure: Error?
        NSFileCoordinator().coordinate(writingItemAt: url, options: .forDeleting, error: &coordination) { target in
            do { try FileManager.default.removeItem(at: target) } catch { failure = error }
        }
        if let error = coordination ?? failure { throw error }
    }
}
