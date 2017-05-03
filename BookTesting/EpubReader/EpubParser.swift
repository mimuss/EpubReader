//
//  EpubParser.swift
//  BookTesting
//
//  Created by Никита Прохоров on 01.05.17.
//  Copyright © 2017 N_P. All rights reserved.
//

import Foundation
import SWXMLHash
import SSZipArchive

enum EbookError: Error {
    case wrongURLs
    case couldNotUnzip
    case wrongEpubFile(info: String)
}

class EpubParser {
    
    let epubURL: URL
    var unzipURL: URL
    var shouldDeleteUnzippedFiles: Bool
    private var opfFileExtension: String!
    
    private var opfFileURL: URL {
        return unzipURL.appendingPathComponent(opfFileExtension)
    }
    var contentURL: URL {
        return opfFileURL.deletingLastPathComponent()
    }
    var bookName: String {
        var epubFile = (epubURL.path as NSString).lastPathComponent
        let range = epubFile.index(epubFile.endIndex, offsetBy: -5)..<epubFile.endIndex
        epubFile.removeSubrange(range)
        return epubFile
    }
    
    
    init(epubURL: URL, unzipTo unzipURL: URL, deleteUnzippedFiles: Bool = true) throws {
        let fileManager = FileManager.default
        self.unzipURL = unzipURL
        self.epubURL = epubURL
        self.shouldDeleteUnzippedFiles = deleteUnzippedFiles
        if fileManager.fileExists(atPath: epubURL.path) && fileManager.fileExists(atPath: unzipURL.path) {
            createNewFolderForUnzippedFiles()
            if SSZipArchive.unzipFile(atPath: self.epubURL.path, toDestination: self.unzipURL.path) {
                opfFileExtension = try getFullPath(from: self.unzipURL)
            } else {
                throw EbookError.couldNotUnzip
            }
        } else {
            throw EbookError.wrongURLs
        }
    }
    
    func createNewFolderForUnzippedFiles() {
        let newFolderURL = unzipURL.appendingPathComponent(bookName)
        print(newFolderURL)
        try? FileManager.default.createDirectory(at: newFolderURL, withIntermediateDirectories: true, attributes: nil)
        unzipURL = newFolderURL
    }
    
    func deleteUnzippedFiles() throws {
        guard shouldDeleteUnzippedFiles else { return }
        try FileManager.default.removeItem(at: unzipURL)
    }
    
    deinit {
        do {
            try deleteUnzippedFiles()
        } catch {
            print("Could not delete unzipped files: \(error)")
        }
        print("deinit")
    }
    
    // because we cannot unzip file if extension does not correspond to .zip
    // don't need it, SSZipArchive can unzip .epub extension
    /*private func renameEpubToZip(from epubURL: URL) throws -> URL {
        var bookName = (epubURL.path as NSString).lastPathComponent
        guard bookName.hasSuffix(".epub") else {
            throw EbookError.wrongEpubFile(info: "File does not have .epub extension")
        }
        var renamedBookURL = epubURL.deletingLastPathComponent()
        let range = bookName.index(bookName.endIndex, offsetBy: -5)..<bookName.endIndex
        bookName.removeSubrange(range)
        renamedBookURL.appendPathComponent("\(bookName).zip")
        do {
            try FileManager.default.moveItem(at: epubURL, to: epubURL)
            return renamedBookURL
        } catch {
            throw EbookError.wrongEpubFile(info: "could not rename epub file to zip (maybe file does not have .epub extension)")
        }
    }*/
    
    private func getFullPath(from url: URL) throws -> String {
        var pathURl = url
        pathURl.appendPathComponent("META-INF")
        pathURl.appendPathComponent("container.xml")
        let data: Data
        do {
            data = try Data(contentsOf: pathURl)
        } catch {
            print(error)
            throw EbookError.wrongEpubFile(info: "Could not convert META-INF container.xml file")
        }
        let xmlParse = SWXMLHash.parse(data)
        do {
            if let path = try xmlParse["container"]["rootfiles"]["rootfile"].withAttr("media-type", "application/oebps-package+xml").element?.attribute(by: "full-path")?.text {
                return path
            } else {
                throw EbookError.wrongEpubFile(info: "Could not get full path in META-INF container.xml")
            }
        } catch {
            print(error)
            throw EbookError.wrongEpubFile(info: "Could not get full path in META-INF container.xml")
        }
    }
    
    func getManifest() throws -> Dictionary<String,String> {
        guard let urlData = try? Data(contentsOf: opfFileURL) else {
            throw EbookError.wrongEpubFile(info: "Could not get manifest")
        }
        var result = Dictionary<String, String>()
        let xmlFile = SWXMLHash.parse(urlData)
        for elem in xmlFile["package"]["manifest"]["item"].all {
            if let key = elem.element?.attribute(by: "id")?.text, let value = elem.element?.attribute(by: "href")?.text {
                result[key] = value
            }
        }
        return result
    }
    
    func spineFrom() throws -> [String] {
        guard let urlData = try? Data(contentsOf: opfFileURL) else {
            throw EbookError.wrongEpubFile(info: "Could not get spine")
        }
        var result: [String] = Array<String>()
        let xmlFile = SWXMLHash.parse(urlData)
        for elem in xmlFile["package"]["spine"]["itemref"].all {
            if let idref = elem.element?.attribute(by: "idref")?.text {
                result.append(idref)
            }
        }
        return result
    }
    
}






