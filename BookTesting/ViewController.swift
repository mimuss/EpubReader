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

    @IBOutlet weak var webVIew: UIWebView!
    
    var book: EBook!
    
    lazy var epubURL: URL = {
        var result = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        result.appendPathComponent("Books")
        result.appendPathComponent("TolstoyZip.epub")
        return result
    }()
    
    lazy var unzipURL: URL = {
        return URL(fileURLWithPath: NSTemporaryDirectory())
    }()

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("viewDidDisappear")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            book = try EBook(epubURL: epubURL, unzipTo: unzipURL)
            webVIew.loadHTMLString(book.spine(at: 0).string, baseURL: book.spine(at: 1).baseURL)
        } catch let error as EbookError {
            switch error {
            case .couldNotUnzip:
                print("Could not unzip")
            case .wrongURLs:
                print("Wrong urls")
            case .wrongEpubFile(info: let info):
                print(info)
            }
        } catch {
            print(error)
        }
          
    }
    
}

