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
  var locations = [Int: NSURL?]()
  
  let fileHandlerQueue = NSOperationQueue()
  
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
      if let handler = handlers[task.taskIdentifier] as? (NSData?, NSURLResponse?, NSError?) -> Void, let data = datas[task.taskIdentifier] {
        handler(data, task.response, error)
      }
      datas.removeValueForKey(task.taskIdentifier)
    } else if task.isKindOfClass(NSURLSessionDownloadTask) {
      if let handler = handlers[task.taskIdentifier] as? (NSURL?, NSURLResponse?, NSError?) -> Void {
        fileHandlerQueue.waitUntilAllOperationsAreFinished()
        let url = locations[task.taskIdentifier]
        handler(url ?? nil, task.response, error)
      }
    }
    handlers.removeValueForKey(task.taskIdentifier)
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
    fileHandlerQueue.suspended = true
    fileHandlerQueue.addOperationWithBlock {
      // just wait
    }
    if let path = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).first?.URLByAppendingPathComponent(NSBundle.mainBundle().bundleIdentifier!) {
      try? NSFileManager.defaultManager().createDirectoryAtURL(path, withIntermediateDirectories: true, attributes: nil)
      let newLocation = path.URLByAppendingPathComponent(location.lastPathComponent!)
      try? NSFileManager.defaultManager().copyItemAtURL(location, toURL: newLocation)
      locations[downloadTask.taskIdentifier] = newLocation
    }
    fileHandlerQueue.suspended = false
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