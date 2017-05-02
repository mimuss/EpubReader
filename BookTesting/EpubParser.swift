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
    let unzipURL: URL
    private var fullPath: String!
    private var fullPathURL: URL {
        return unzipURL.appendingPathComponent(fullPath)
    }
    
    
    init(epubURL: URL, unzipTo unzipURL: URL) throws {
        let fileManager = FileManager.default
        self.epubURL = epubURL
        self.unzipURL = unzipURL
        if fileManager.fileExists(atPath: epubURL.path) && fileManager.fileExists(atPath: unzipURL.path) {
            if SSZipArchive.unzipFile(atPath: epubURL.path, toDestination: unzipURL.path) {
                fullPath = try getFullPath(from: unzipURL)
            } else {
                throw EbookError.couldNotUnzip
            }
        } else {
            throw EbookError.wrongURLs
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
        guard let urlData = try? Data(contentsOf: fullPathURL) else {
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
        guard let urlData = try? Data(contentsOf: fullPathURL) else {
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






