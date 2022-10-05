import Foundation

public final class SharedContainerCache<T: Codable>: SharedContainerCacheHousekeepingProtocol {

    private let fileName: String
    private let subdirectoryPathComponent: String?
    private let defaultCache: () -> T
    
    public init(fileName: String, subdirectoryPathComponent: String? = String(), defaultCache: @escaping () -> T) {
        self.fileName = fileName
        self.subdirectoryPathComponent = subdirectoryPathComponent
        self.defaultCache = defaultCache
    }
    
    private var cacheDirectoryContainerURL: URL {
        FileManager.default.wmf_containerURL()
    }
    
    private var cacheDataFileURL: URL {
        let baseURL = subdirectoryURL() ?? cacheDirectoryContainerURL
        return baseURL.appendingPathComponent(fileName).appendingPathExtension("json")
    }
    
    private func subdirectoryURL() -> URL? {
        guard let subdirectoryPathComponent = subdirectoryPathComponent else {
            return nil
        }
        return cacheDirectoryContainerURL.appendingPathComponent(subdirectoryPathComponent, isDirectory: true)
    }

    public func loadCache() -> T {
        if let data = try? Data(contentsOf: cacheDataFileURL), let decodedCache = try? JSONDecoder().decode(T.self, from: data) {
            return decodedCache
        }
        return defaultCache()
    }

    public func saveCache(_ cache: T) {
        let encoder = JSONEncoder()
        guard let encodedCache = try? encoder.encode(cache) else {
            return
        }

        if let subdirectoryURL = subdirectoryURL() {
            try? FileManager.default.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: nil)

        }

        try? encodedCache.write(to: cacheDataFileURL)
    }

    /// Persist only the last 50 visited talk pages
    @objc public func deleteStaleCachedItems(for folder: String) {
        let folderURL = cacheDirectoryContainerURL.appendingPathComponent(folder)

        if let urlArray = try? FileManager.default.contentsOfDirectory(at: folderURL,
                                                                       includingPropertiesForKeys: [.contentModificationDateKey],
                                                                       options: .skipsHiddenFiles) {
            let maxCacheSize = 50
            if urlArray.count > maxCacheSize {
                let sortedArray =  urlArray.map { url in
                    (url, (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast)
                }.sorted(by: {$0.1 > $1.1 })
                    .map { $0.0 }

                let itemsToDelete = Array(sortedArray.suffix(from: maxCacheSize))
                for urlItem in itemsToDelete {
                    try? FileManager.default.removeItem(at: urlItem)
                }
            }
        }

    }
}

@objc public protocol SharedContainerCacheHousekeepingProtocol: AnyObject {
    func deleteStaleCachedItems(for folder: String)
}
