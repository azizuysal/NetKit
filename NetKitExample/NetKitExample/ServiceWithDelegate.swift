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
  @objc func dataTaskWithRequest(request: NSURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask {
    let task = urlSession.dataTaskWithRequest(request)
    tasks[task.taskIdentifier] = completionHandler
    datas[task.taskIdentifier] = NSMutableData()
    return task
  }
}

extension ServiceWithDelegate: NSURLSessionDelegate {
  func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
    if task.isKindOfClass(NSURLSessionDataTask) || task.isKindOfClass(NSURLSessionUploadTask) {
      if let handler = tasks[task.taskIdentifier] as? (NSData?, NSURLResponse?, NSError?) -> Void, taskData = datas[task.taskIdentifier] {
        handler(taskData, task.response, error)
      }
    } else if task.isKindOfClass(NSURLSessionDownloadTask) {
      if let handler = tasks[task.taskIdentifier] as? (NSURL?, NSURLResponse?, NSError?) -> Void, location = locations[task.taskIdentifier] {
        handler(location, task.response, error)
      }
    }
    tasks.removeValueForKey(task.taskIdentifier)
    datas.removeValueForKey(task.taskIdentifier)
    locations.removeValueForKey(task.taskIdentifier)
  }
}

extension ServiceWithDelegate: NSURLSessionDataDelegate {
  func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
    if let taskData = datas[dataTask.taskIdentifier] {
      taskData?.appendData(data)
    }
  }
}

extension ServiceWithDelegate: NSURLSessionDownloadDelegate {
  func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
    locations[downloadTask.taskIdentifier] = location
  }
}

class ServiceWithDelegate: NSObject {
  
  private static let baseURL = "http://localhost:3000/"
  let webService = WebService(urlString: baseURL)
  
  var urlSession: NSURLSession!
  
  var tasks = [Int:Any]()
  var datas = [Int: NSMutableData?]()
  var locations = [Int: NSURL?]()
  
  override init() {
    super.init()
    let configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
    configuration.HTTPCookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
    configuration.HTTPAdditionalHeaders  = ["Accept":"application/json"]
    urlSession = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
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
    json["id"] = id
    json["postId"] = postId
    json["body"] = body
    return json
  }
}