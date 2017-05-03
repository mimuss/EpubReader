//
//  EBook.swift
//  BookTesting
//
//  Created by Никита Прохоров on 02.05.17.
//  Copyright © 2017 N_P. All rights reserved.
//

import Foundation
import SSZipArchive


class EBook {
    
    let epubURL: URL
    let unzipURL: URL
    private let parser: EpubParser
    let manifest: [String:String]
    let spine: [String]
    var shouldDeleteUnzippedFiles: Bool {
        didSet {
            parser.shouldDeleteUnzippedFiles = shouldDeleteUnzippedFiles
        }
    }
    
    init(epubURL: URL, unzipTo unzipURL: URL, deleteUnzippedFiles: Bool = true) throws {
        parser = try EpubParser(epubURL: epubURL, unzipTo: unzipURL, deleteUnzippedFiles: deleteUnzippedFiles)
        self.epubURL = epubURL
        self.unzipURL = unzipURL
        self.shouldDeleteUnzippedFiles = deleteUnzippedFiles
        manifest = try parser.getManifest()
        spine = try parser.spineFrom()
    }
    
    func deleteUnzippedFiles() throws {
        try parser.deleteUnzippedFiles()
    }
    
    func spine(at index: Int) -> (string: String, baseURL: URL) {
        var contentURL = parser.contentURL
        contentURL.appendPathComponent(manifest[spine[index]]!)
        return (string: String(data: try! Data(contentsOf: contentURL), encoding: .utf8)!, baseURL: contentURL)
    }
}






