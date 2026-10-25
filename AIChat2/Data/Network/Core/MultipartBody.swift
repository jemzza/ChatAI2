//
//  MultipartBody.swift
//  AIChat2
//

import Foundation

nonisolated struct MultipartBody: Sendable {
    
    struct File: Sendable {
        let name: String
        let fileName: String
        let mimeType: String
        let data: Data
    }
    
    private(set) var fields: [String: String] = [:]
    private(set) var files: [File] = []
    
    mutating func add(_ value: String, for name: String) {
        fields[name] = value
    }
    
    mutating func add(file data: Data, name: String, fileName: String, mimeType: String) {
        files.append(File(name: name, fileName: fileName, mimeType: mimeType, data: data))
    }
 }
