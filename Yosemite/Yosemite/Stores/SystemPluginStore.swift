import Foundation
import Networking
import Storage

/// Implements `SystemPluginActions` actions
///
public final class SystemPluginStore: Store {
    private let remote: SystemPluginsRemote

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = SystemPluginsRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: SystemPluginAction.self)
    }

    /// Receives and executes Actions.
    ///
    public override func onAction(_ action: Action) {
        guard let action = action as? SystemPluginAction else {
            assertionFailure("SystemPluginStore receives an unsupported action!")
            return
        }

        switch action {
        case .synchronizeSystemPlugins(let siteID, let onCompletion):
            synchronizeSystemPlugins(siteID: siteID, completionHandler: onCompletion)
        case .fetchSystemPlugins(let siteID, let onCompletion):
            fetchSystemPlugins(siteID: siteID, completionHandler: onCompletion)
        }
    }
}

// MARK: - Network request
//
private extension SystemPluginStore {
    func synchronizeSystemPlugins(siteID: Int64, completionHandler: @escaping (Result<Void, Error>) -> Void) {
        remote.loadSystemPlugins(for: siteID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let systemPlugins):
                self.upsertSystemPluginsInBackground(siteID: siteID, readonlySystemPlugins: systemPlugins, completionHandler: completionHandler)
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
}

// MARK: - Storage
//
private extension SystemPluginStore {

    /// Updates or inserts Readonly `SystemPlugin` entities in background.
    /// Triggers `completionHandler` on main thread.
    ///
    func upsertSystemPluginsInBackground(siteID: Int64, readonlySystemPlugins: [SystemPlugin], completionHandler: @escaping (Result<Void, Error>) -> Void) {
        let writerStorage = storageManager.writerDerivedStorage
        writerStorage.perform {
            self.upsertSystemPlugins(siteID: siteID, readonlySystemPlugins: readonlySystemPlugins, in: writerStorage)
        }

        storageManager.saveDerivedType(derivedStorage: writerStorage) {
            DispatchQueue.main.async {
                completionHandler(.success(()))
            }
        }
    }

    /// Updates or inserts Readonly `SystemPlugin` entities in specified storage.
    /// Also removes stale plugins that no longer exist in remote plugin list.
    ///
    func upsertSystemPlugins(siteID: Int64, readonlySystemPlugins: [SystemPlugin], in storage: StorageType) {
        readonlySystemPlugins.forEach { readonlySystemPlugin in
            // load or create new StorageSystemPlugin matching the readonly one
            let storageSystemPlugin: StorageSystemPlugin = {
                if let systemPlugin = storage.loadSystemPlugin(siteID: readonlySystemPlugin.siteID, name: readonlySystemPlugin.name) {
                    return systemPlugin
                }
                return storage.insertNewObject(ofType: StorageSystemPlugin.self)
            }()

            storageSystemPlugin.update(with: readonlySystemPlugin)
        }

        // remove stale system plugins
        let currentSystemPlugins = readonlySystemPlugins.map(\.name)
        storage.deleteStaleSystemPlugins(siteID: siteID, currentSystemPlugins: currentSystemPlugins)
    }

    /// Retrieve `SystemPlugin` entities of a specified storage by siteID
    ///
    func fetchSystemPlugins(siteID: Int64, completionHandler: @escaping ([SystemPlugin]?) -> Void) {
        let viewStorage = storageManager.viewStorage
        let systemPlugins = viewStorage.loadSystemPlugins(siteID: siteID).map { $0.toReadOnly() }
        completionHandler(systemPlugins)
    }
}
