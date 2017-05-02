//
//  ViewController.swift
//  BookTesting
//
//  Created by Никита Прохоров on 30.04.17.
//  Copyright © 2017 N_P. All rights reserved.
//

import UIKit
import SSZipArchive
import SWXMLHash

class ViewController: UIViewController {

    lazy var epubURL: URL = {
        var result = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        result.appendPathComponent("Books")
        result.appendPathComponent("TolstoyZip.zip")
        return result
    }()
    
    lazy var unzipURL: URL = {
        return URL(fileURLWithPath: NSTemporaryDirectory())
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(epubURL)
        
        if let book = try? EBook(epubURL: epubURL, unzipTo: unzipURL) {
            print(book.manifest)
            print(book.spine)
        }
        
          
    }
    
}

