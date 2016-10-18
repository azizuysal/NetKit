//
//  WebTask.swift
//  NetKit
//
//  Created by Aziz Uysal on 2/12/16.
//  Copyright © 2016 Aziz Uysal. All rights reserved.
//

import Foundation

public enum WebTaskResult {
  case success, failure(Error)
}

public enum WebTaskError: Error {
  case jsonSerializationFailedNilResponseBody
}

class Observer: NSObject {
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if keyPath == "operationCount" {
      if let queue = object as? OperationQueue, queue.operationCount == 0 {
        let semaphore = context?.assumingMemoryBound(to: DispatchSemaphore.self).pointee
        semaphore?.signal()
      }
    }
  }
}

public class WebTask {
  
  public enum TaskType {
    case data, download, upload
  }
  
  public typealias ResponseHandler = (Data?, URL?, URLResponse?) -> WebTaskResult
  public typealias JSONHandler = (Any) -> WebTaskResult
  public typealias FileDownloadHandler = (URL?, URLResponse?) -> WebTaskResult
  public typealias ErrorHandler = (Error) -> Void
  
  fileprivate let queueObserver = Observer()
  fileprivate let handlerQueue: OperationQueue = {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    queue.isSuspended = true
    return queue
  }()
  
  fileprivate var webRequest: WebRequest
  fileprivate weak var webService: WebService?
  fileprivate let taskType: TaskType
  fileprivate var urlTask: URLSessionTask?
  
  fileprivate var urlResponse: URLResponse?
  fileprivate var responseData: Data?
  fileprivate var responseURL: URL?
  fileprivate var taskResult: WebTaskResult?
  
  fileprivate var semaphore: DispatchSemaphore?
  fileprivate var timeout: Double = -1
  
  fileprivate var authCount: Int = 0
  fileprivate var fileDownloadHandler: FileDownloadHandler?
  
//  private var useOriginQueue = false
//  private let originQueue: NSOperationQueue = {
//    return NSOperationQueue.currentQueue() ?? NSOperationQueue()
//  }()
  
  deinit {
//    handlerQueue.cancelAllOperations()
    handlerQueue.removeObserver(queueObserver, forKeyPath: "operationCount")
  }
  
  public init(webRequest: WebRequest, webService: WebService, taskType: TaskType = .data) {
    self.webRequest = webRequest
    self.webService = webService
    self.taskType = taskType
  }
}

extension WebTask {
  
  @discardableResult public func resume() -> Self {
    
    handlerQueue.addObserver(queueObserver, forKeyPath: "operationCount", options: .new, context: &semaphore)
    
    if urlTask == nil {
      switch taskType {
      case .data:
        urlTask = webService?.taskSource.nkDataTask?(with: webRequest.urlRequest) { data, response, error in
          self.handleResponse(data, response: response, error: error)
        }
      case .download:
        urlTask = webService?.taskSource.nkDownloadTask?(with: webRequest.urlRequest) { location, response, error in
          self.handleResponse(location: location, response: response, error: error)
        }
      case .upload:
        urlTask = webService?.taskSource.nkUploadTask?(with: webRequest.urlRequest, from: webRequest.body) { data, response, error in
          self.handleResponse(data, response: response, error: error)
        }
      }
    }
    
    if let task = urlTask {
      webService?.webDelegate?.tasks[task.taskIdentifier] = self
      task.resume()
    }
    
    if let semaphore = semaphore {
      let result = semaphore.wait(timeout: DispatchTime.now() + timeout)
      if result == DispatchTimeoutResult.timedOut && urlTask?.state != .completed {
        cancel()
      }
      handlerQueue.waitUntilAllOperationsAreFinished()
    } else if timeout == 0 {
      handlerQueue.waitUntilAllOperationsAreFinished()
    }
    return self
  }
  
  @discardableResult public func resumeAndWait(_ timeout: Double = 0) -> Self {
    self.timeout = timeout
    if timeout > 0 {
      semaphore = DispatchSemaphore(value: 0)
    }
    return resume()
  }
  
  public func suspend() {
    urlTask?.suspend()
  }
  
  public func cancel() {
    urlTask?.cancel()
  }
  
  fileprivate func handleResponse(_ data: Data? = nil, location: URL? = nil, response: URLResponse?, error: Error?) {
    urlResponse = response
    responseData = data
    responseURL = location
    if let error = error {
      taskResult = WebTaskResult.failure(error)
    }
    handlerQueue.isSuspended = false
    if let urlTask = urlTask {
      _ = webService?.webDelegate?.tasks.removeValue(forKey: urlTask.taskIdentifier)
    }
  }
}

extension WebTask {
  
  public func setURLParameters(_ parameters: [String:Any]) -> Self {
    webRequest.urlParameters = parameters
    return self
  }
  
  public func setBodyParameters(_ parameters: [String:Any], encoding: WebRequest.ParameterEncoding? = nil) -> Self {
    webRequest.bodyParameters = parameters
    webRequest.parameterEncoding = encoding ?? .percent
    if encoding == .json {
      webRequest.contentType = WebRequest.Headers.ContentType.json
    }
    return self
  }
  
  public func setBody(_ data: Data) -> Self {
    webRequest.body = data
    return self
  }
  
  public func setPath(_ path: String) -> Self {
    webRequest.restPath = path
    return self
  }
  
  public func setJSON(_ json: Any) -> Self {
    webRequest.contentType = WebRequest.Headers.ContentType.json
    webRequest.body = try? JSONSerialization.data(withJSONObject: json, options: [])
    return self
  }
  
  public func setSOAP(_ soap: String) -> Self {
    webRequest.contentType = WebRequest.Headers.ContentType.xml
    webRequest.body = soap.placedInSoapEnvelope().data(using: String.Encoding.utf8)
    return self
  }
  
  public func setHeaders(_ headers: [String:String]) -> Self {
    webRequest.headers = headers
    return self
  }
  
  public func setHeaderValue(_ value: String, forName name: String) -> Self {
    webRequest.headers[name] = value
    return self
  }
  
  public func setParameterEncoding(_ encoding: WebRequest.ParameterEncoding) -> Self {
    webRequest.parameterEncoding = encoding
    return self
  }
  
  public func setCachePolicy(_ cachePolicy: NSURLRequest.CachePolicy) -> Self {
    webRequest.cachePolicy = cachePolicy
    return self
  }
  
//  public func respondOnCurrentQueue(useOriginQueue: Bool) -> Self {
//    self.useOriginQueue = useOriginQueue
//    return self
//  }
}

extension WebTask {
  
  func authenticate(_ authenticationMethod: String, completionHandler: WebService.ChallengeCompletionHandler) {
    guard let authenticationHandler = webService?.authenticationHandler else {
      completionHandler(.performDefaultHandling, nil)
      return
    }
    
    if let method = WebService.ChallengeMethod(method: authenticationMethod) , method == .Default || method == .HTTPBasic {
      if let maxAuth = webService?.maxAuthRetry , maxAuth == 0 || authCount < maxAuth {
        authCount += 1
        taskResult = authenticationHandler(WebService.ChallengeMethod(method: authenticationMethod)!, completionHandler)
      } else {
        completionHandler(.performDefaultHandling, nil)
      }
    } else {
      taskResult = authenticationHandler(WebService.ChallengeMethod(method: authenticationMethod)!, completionHandler)
    }
  }
  
  func downloadFile(_ location: URL, response: URLResponse?) {
    guard let fileDownloadHandler = fileDownloadHandler else {
      return
    }
    taskResult = fileDownloadHandler(location, response)
  }
}

extension WebTask {
  
  public func authenticate(_ handler: @escaping WebService.AuthenticationHandler) -> Self {
    webService?.authenticationHandler = handler
    return self
  }
  
  public func response(_ handler: @escaping ResponseHandler) -> Self {
    handlerQueue.addOperation {
      if let taskResult = self.taskResult {
        switch taskResult {
        case .failure(_): return
        case .success: break
        }
      }
      self.taskResult = handler(self.responseData, self.responseURL, self.urlResponse)
    }
    
//    let responseBlock = {
//      if let taskResult = self.taskResult {
//        switch taskResult {
//        case .Failure(_): return
//        case .Success: break
//        }
//      }
//      self.taskResult = handler(self.responseData, self.responseURL, self.urlResponse)
//    }
//    handlerQueue.addOperationWithBlock {
//      if self.useOriginQueue {
//        self.originQueue.addOperationWithBlock {
//          responseBlock()
//        }
//      } else {
//        responseBlock()
//      }
//    }
    return self
  }
  
  public func responseJSON(_ handler: @escaping JSONHandler) -> Self {
    return response { data, url, response in
      if let data = data {
        do {
          let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
          return handler(json)
        } catch let jsonError as NSError {
          return .failure(jsonError)
        } catch {
          fatalError()
        }
      } else {
        return .failure(WebTaskError.jsonSerializationFailedNilResponseBody)
      }
    }
  }
  
  public func responseFile(_ handler: @escaping FileDownloadHandler) -> Self {
    self.fileDownloadHandler = handler
    return response { data, url, response in
      return self.taskResult!
    }
  }
  
  public func responseError(_ handler: @escaping ErrorHandler) -> Self {
    handlerQueue.addOperation {
      if let taskResult = self.taskResult {
        switch taskResult {
        case .failure(let error): handler(error)
        case .success: break
        }
      }
    }
    
//    let responseErrorBlock = {
//      if let taskResult = self.taskResult {
//        switch taskResult {
//        case .Failure(let error): handler(error)
//        case .Success: break
//        }
//      }
//    }
//    handlerQueue.addOperationWithBlock {
//      if self.useOriginQueue {
//        self.originQueue.addOperationWithBlock {
//          responseErrorBlock()
//        }
//      } else {
//        responseErrorBlock()
//      }
//    }
    return self
  }
}

extension String {
  public func placedInSoapEnvelope() -> String {
    let xmlHeader = "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
    let soapStart = "<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">"
    let bodyStart = "<soap:Body>"
    let bodyEnd = "</soap:Body>"
    let soapEnd = "</soap:Envelope>"
    return xmlHeader+soapStart+bodyStart+self+bodyEnd+soapEnd
  }
}
