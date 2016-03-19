//
//  WebDelegate.swift
//  NetKit
//
//  Created by Aziz Uysal on 2/16/16.
//  Copyright © 2016 Aziz Uysal. All rights reserved.
//

import Foundation

class WebDelegate: NSObject {
  
  var tasks = [Int:WebTask]()
  
  var handlers = [Int:Any]()
  var datas = [Int: NSMutableData?]()
  
  weak var webService: WebService?
}

extension WebDelegate: NSURLSessionTaskDelegate {
  func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
    let webTask = tasks[task.taskIdentifier]
    webTask?.authenticate(challenge.protectionSpace.authenticationMethod, completionHandler: completionHandler)
  }
  
  func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
    webService?.backgroundCompletionHandler?()
  }
}

extension WebDelegate: NSURLSessionDelegate {
  func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
    if task.isKindOfClass(NSURLSessionDataTask) || task.isKindOfClass(NSURLSessionUploadTask) {
      if let handler = handlers[task.taskIdentifier] as? (NSData?, NSURLResponse?, NSError?) -> Void, taskData = datas[task.taskIdentifier] {
        handler(taskData, task.response, error)
      }
      handlers.removeValueForKey(task.taskIdentifier)
      datas.removeValueForKey(task.taskIdentifier)
    }
  }
}

extension WebDelegate: NSURLSessionDataDelegate {
  func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
    if let taskData = datas[dataTask.taskIdentifier] {
      taskData?.appendData(data)
    }
  }
}

extension WebDelegate: NSURLSessionDownloadDelegate {
  func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
    let webTask = tasks[downloadTask.taskIdentifier]
    webTask?.downloadFile(location, response: downloadTask.response)
  }
}

class TaskSource {
  class func defaultSource(configuration: NSURLSessionConfiguration, delegate: NSURLSessionDelegate?, delegateQueue: NSOperationQueue?) -> SessionTaskSource {
    if configuration.identifier != nil {
      return BackgroundTaskSource(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
    }
    return NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
  }
}

class BackgroundTaskSource {
  var urlSession: NSURLSession
  let webDelegate: WebDelegate?
  
  init(configuration: NSURLSessionConfiguration, delegate: NSURLSessionDelegate?, delegateQueue: NSOperationQueue?) {
    webDelegate = delegate as? WebDelegate
    urlSession = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
  }
}

extension BackgroundTaskSource: SessionTaskSource {
  @objc func dataTaskWithRequest(request: NSURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask {
    let task = urlSession.dataTaskWithRequest(request)
    webDelegate?.handlers[task.taskIdentifier] = completionHandler
    webDelegate?.datas[task.taskIdentifier] = NSMutableData()
    return task
  }
  
  @objc func downloadTaskWithRequest(request: NSURLRequest, completionHandler: (NSURL?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDownloadTask {
    let task = urlSession.downloadTaskWithRequest(request)
    webDelegate?.handlers[task.taskIdentifier] = completionHandler
    return task
  }
  
  @objc func uploadTaskWithRequest(request: NSURLRequest, fromData: NSData?, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionUploadTask {
    let task = urlSession.uploadTaskWithRequest(request, fromData: fromData!)
    webDelegate?.handlers[task.taskIdentifier] = completionHandler
    webDelegate?.datas[task.taskIdentifier] = NSMutableData()
    return task
  }
}