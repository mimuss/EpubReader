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
    let parser: EpubParser
    let manifest: [String:String]
    let spine: [String]
    
    
    init(epubURL: URL, unzipTo unzipURL: URL) throws {
        self.epubURL = epubURL
        self.unzipURL = unzipURL
        parser = try EpubParser(epubURL: epubURL, unzipTo: unzipURL)
        manifest = try parser.getManifest()
        spine = try parser.spineFrom()
    }
    
}






