//
//  RepositoryError.swift
//  AIChat2
//

import Foundation

nonisolated enum RepositoryError: Error, Hashable, Sendable {
    case chatNotFound(UUID)
    case messageNotFound(UUID)
    case folderNotFound(UUID)
}
