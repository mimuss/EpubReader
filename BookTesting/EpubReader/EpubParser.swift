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
    
    var epubURL: URL!
    let unzipURL: URL
    private var opfFileExtension: String!
    var opfFileURL: URL {
        return unzipURL.appendingPathComponent(opfFileExtension)
    }
    var contentURL: URL {
        return opfFileURL.deletingLastPathComponent()
    }
    
    init(epubURL: URL, unzipTo unzipURL: URL) throws {
        let fileManager = FileManager.default
        self.unzipURL = unzipURL
        if fileManager.fileExists(atPath: epubURL.path) && fileManager.fileExists(atPath: unzipURL.path) {
            self.epubURL = try renameEpubToZip(from: epubURL)
            if SSZipArchive.unzipFile(atPath: epubURL.path, toDestination: unzipURL.path) {
                opfFileExtension = try getFullPath(from: unzipURL)
            } else {
                throw EbookError.couldNotUnzip
            }
        } else {
            throw EbookError.wrongURLs
        }
    }

    // because we cannot unzip file if extension does not correspond to .zip
    private func renameEpubToZip(from epubURL: URL) throws -> URL {
        let bookName = (epubURL.path as NSString).lastPathComponent
        let bookExtension = (bookName as NSString).pathExtension
        guard bookExtension == "epub" else {
            throw EbookError.wrongEpubFile(info: "File does not have .epub extension")
        }
        var renamedBookURL = epubURL.deletingLastPathComponent()
        renamedBookURL.appendPathComponent("\(bookName).zip")
        do {
            try FileManager.default.moveItem(at: epubURL, to: epubURL)
            return renamedBookURL
        } catch {
            throw EbookError.wrongEpubFile(info: "could not rename epub file to zip (maybe file does not have .epub extension)")
        }
    }
    
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






