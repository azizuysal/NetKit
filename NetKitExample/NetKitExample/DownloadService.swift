//
//  DownloadService.swift
//  NetKitExample
//
//  Created by Aziz Uysal on 3/19/16.
//  Copyright © 2016 Aziz Uysal. All rights reserved.
//

import Foundation
import NetKit

protocol DownloadServiceAPI {
  var webService: WebService {get}
  
  func getFile() -> WebTask
}

extension DownloadServiceAPI {
  
  func getFile() -> WebTask {
    return webService.GET("", taskType: WebTask.TaskType.download)
  }
}

class DownloadService: DownloadServiceAPI {
  
  fileprivate static let baseURL = "http://web4host.net/"
  let webService: WebService = {
    let configuration = URLSessionConfiguration.background(withIdentifier: "com.azizuysal.netkit.test")
    configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
    let service = WebService(urlString: baseURL, configuration: configuration)
    return service!
  }()
  
  static let FileDownloaded = "DownloadService.FileDownloaded"
  static let FileName = "DownloadService.FileName"
}
