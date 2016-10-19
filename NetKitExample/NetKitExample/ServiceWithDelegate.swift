//
//  ServiceWithDelegate.swift
//  NetKitExample
//
//  Created by Aziz Uysal on 2/19/16.
//  Copyright © 2016 Aziz Uysal. All rights reserved.
//

import Foundation
import NetKit

protocol ServiceWithDelegateAPI {
  
  var webService: WebService { get }
  
  func getComments() -> WebTask
}

extension ServiceWithDelegateAPI {
  
  func getComments() -> WebTask {
    return webService.GET("comments")
  }
}

extension ServiceWithDelegate: ServiceWithDelegateAPI {}

extension ServiceWithDelegate: SessionTaskSource {
  @objc func nkDataTask(with request: URLRequest, completionHandler: @escaping DataTaskHandler) -> URLSessionDataTask {
    let task = urlSession.dataTask(with: request)
    tasks[task.taskIdentifier] = completionHandler
    datas[task.taskIdentifier] = NSMutableData()
    return task
  }
}

extension ServiceWithDelegate: URLSessionDelegate {
  @objc(URLSession:task:didCompleteWithError:) func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    if task.isKind(of: URLSessionDataTask.self) || task.isKind(of: URLSessionUploadTask.self) {
      if let handler = tasks[task.taskIdentifier] as? (Data?, URLResponse?, NSError?) -> Void, let taskData = datas[task.taskIdentifier] {
        handler(taskData as Data?, task.response, error as NSError?)
      }
    } else if task.isKind(of: URLSessionDownloadTask.self) {
      if let handler = tasks[task.taskIdentifier] as? (URL?, URLResponse?, NSError?) -> Void, let location = locations[task.taskIdentifier] {
        handler(location, task.response, error as NSError?)
      }
    }
    tasks.removeValue(forKey: task.taskIdentifier)
    datas.removeValue(forKey: task.taskIdentifier)
    locations.removeValue(forKey: task.taskIdentifier)
  }
}

extension ServiceWithDelegate: URLSessionDataDelegate {
  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    if let taskData = datas[dataTask.taskIdentifier] {
      taskData?.append(data)
    }
  }
}

extension ServiceWithDelegate: URLSessionDownloadDelegate {
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    locations[downloadTask.taskIdentifier] = location
  }
}

class ServiceWithDelegate: NSObject {
  
  fileprivate static let baseURL = "http://localhost:3000/"
  let webService = WebService(urlString: baseURL)!
  
  var urlSession: Foundation.URLSession!
  
  var tasks = [Int:Any]()
  var datas = [Int: NSMutableData?]()
  var locations = [Int: URL?]()
  
  override init() {
    super.init()
    let configuration = URLSessionConfiguration.ephemeral
    configuration.httpCookieStorage = HTTPCookieStorage.shared
    configuration.httpAdditionalHeaders  = ["Accept":"application/json"]
    urlSession = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    webService.taskSource = self
  }
  
  static let CommentsDownloaded = "CommentsDownloaded"
}

class Comment {
  
  var id: Int = 0
  var postId: Int = 0
  var body: String = ""
  
  func toJson() -> [String:AnyObject] {
    var json = [String:AnyObject]()
    json["id"] = id as AnyObject?
    json["postId"] = postId as AnyObject?
    json["body"] = body as AnyObject?
    return json
  }
}
