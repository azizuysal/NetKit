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
  var locations = [Int: URL?]()
  
  let fileHandlerQueue = OperationQueue()
  
  weak var webService: WebService?
}

extension WebDelegate: URLSessionTaskDelegate {
  func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    let webTask = tasks[task.taskIdentifier]
    webTask?.authenticate(challenge.protectionSpace.authenticationMethod, completionHandler: completionHandler)
  }
  
  @objc(URLSessionDidFinishEventsForBackgroundURLSession:) func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    if let completionHandler = webService?.backgroundCompletionHandler {
      webService?.backgroundCompletionHandler = nil
      DispatchQueue.main.async {
        completionHandler()
      }
    }
  }
}

extension WebDelegate: URLSessionDelegate {
  @objc(URLSession:task:didCompleteWithError:) func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    if task.isKind(of: URLSessionDataTask.self) || task.isKind(of: URLSessionUploadTask.self) {
      if let handler = handlers[task.taskIdentifier] as? DataTaskHandler, let data = datas[task.taskIdentifier] {
        handler(data as Data?, task.response, error as NSError?)
      }
      datas.removeValue(forKey: task.taskIdentifier)
    } else if task.isKind(of: URLSessionDownloadTask.self) {
      if let handler = handlers[task.taskIdentifier] as? DownloadTaskHandler {
        fileHandlerQueue.waitUntilAllOperationsAreFinished()
        let url = locations[task.taskIdentifier]
        handler(url ?? nil, task.response, error as NSError?)
      }
    }
    handlers.removeValue(forKey: task.taskIdentifier)
  }
}

extension WebDelegate: URLSessionDataDelegate {
  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    if let taskData = datas[dataTask.taskIdentifier] {
      taskData?.append(data)
    }
  }
}

extension WebDelegate: URLSessionDownloadDelegate {
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    fileHandlerQueue.isSuspended = true
    fileHandlerQueue.addOperation {
      // just wait
    }
    let webTask = tasks[downloadTask.taskIdentifier]
    webTask?.downloadFile(location, response: downloadTask.response)
    fileHandlerQueue.isSuspended = false
  }
}

class TaskSource {
  class func defaultSource(_ configuration: URLSessionConfiguration, delegate: URLSessionDelegate?, delegateQueue: OperationQueue?) -> SessionTaskSource {
    if configuration.identifier != nil {
      return BackgroundTaskSource(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
    }
    return URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
  }
}

class BackgroundTaskSource {
  var urlSession: URLSession
  let webDelegate: WebDelegate?
  
  init(configuration: URLSessionConfiguration, delegate: URLSessionDelegate?, delegateQueue: OperationQueue?) {
    webDelegate = delegate as? WebDelegate
    urlSession = URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
  }
}

extension BackgroundTaskSource: SessionTaskSource {
  @objc func nkDataTask(with request: URLRequest, completionHandler: @escaping DataTaskHandler) -> URLSessionDataTask {
    let task = urlSession.dataTask(with: request)
    webDelegate?.handlers[task.taskIdentifier] = completionHandler
    webDelegate?.datas[task.taskIdentifier] = NSMutableData()
    return task
  }
  
  @objc func nkDownloadTask(with request: URLRequest, completionHandler: @escaping DownloadTaskHandler) -> URLSessionDownloadTask {
    let task = urlSession.downloadTask(with: request)
    webDelegate?.handlers[task.taskIdentifier] = completionHandler
    return task
  }
  
  @objc func nkUploadTask(with request: URLRequest, from data: Data?, completionHandler: @escaping UploadTaskHandler) -> URLSessionUploadTask {
    let task = urlSession.uploadTask(with: request, from: data!)
    webDelegate?.handlers[task.taskIdentifier] = completionHandler
    webDelegate?.datas[task.taskIdentifier] = NSMutableData()
    return task
  }
}
