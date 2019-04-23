//
//  WebService.swift
//  NetKit
//
//  Created by Aziz Uysal on 2/12/16.
//  Copyright © 2016 Aziz Uysal. All rights reserved.
//

import Foundation

public typealias DataTaskHandler = (Data?, URLResponse?, Error?) -> Void
public typealias DownloadTaskHandler = (URL?, URLResponse?, Error?) -> Void
public typealias UploadTaskHandler = DataTaskHandler

@objc public protocol SessionTaskSource {
  @objc optional func nkDataTask(with: URLRequest, completionHandler: @escaping DataTaskHandler) -> URLSessionDataTask
  @objc optional func nkDownloadTask(with: URLRequest, completionHandler: @escaping DownloadTaskHandler) -> URLSessionDownloadTask
  @objc optional func nkUploadTask(with: URLRequest, from: Data?, completionHandler: @escaping UploadTaskHandler) -> URLSessionUploadTask
  @objc optional func invalidateAndCancel()
}

extension URLSession: SessionTaskSource {
  public func nkDataTask(with request: URLRequest, completionHandler: @escaping DataTaskHandler) -> URLSessionDataTask {
    return dataTask(with: request, completionHandler: completionHandler)
  }
  public func nkDownloadTask(with request: URLRequest, completionHandler: @escaping DownloadTaskHandler) -> URLSessionDownloadTask {
    return downloadTask(with: request, completionHandler: completionHandler)
  }
  public func nkUploadTask(with request: URLRequest, from data: Data?, completionHandler: @escaping UploadTaskHandler) -> URLSessionUploadTask {
    return uploadTask(with: request, from: data, completionHandler: completionHandler)
  }
}

public class WebService {
  
  public typealias AuthenticationHandler = (ChallengeMethod, ChallengeCompletionHandler) -> WebTaskResult
  public typealias ChallengeCompletionHandler = (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
  public enum ChallengeMethod: String {
    case Default, HTTPBasic, HTTPDigest, HTMLForm, Negotiate, NTLM, ClientCertificate, ServerTrust
    init?(method: String) {
      switch method {
      case NSURLAuthenticationMethodDefault: self = .Default
      case NSURLAuthenticationMethodHTTPBasic: self = .HTTPBasic
      case NSURLAuthenticationMethodHTTPDigest: self = .HTTPDigest
      case NSURLAuthenticationMethodHTMLForm: self = .HTMLForm
      case NSURLAuthenticationMethodNegotiate: self = .Negotiate
      case NSURLAuthenticationMethodNTLM: self = .NTLM
      case NSURLAuthenticationMethodClientCertificate: self = .ClientCertificate
      case NSURLAuthenticationMethodServerTrust: self = .ServerTrust
      default: return nil
      }
    }
  }
  
  public var taskSource: SessionTaskSource
  public var backgroundCompletionHandler: (() -> Void)?
  
  fileprivate let url: URL
  fileprivate let webQueue = OperationQueue()
  
  fileprivate(set) var webDelegate: WebDelegate?
  var authenticationHandler: AuthenticationHandler?
  
  public var maxAuthRetry: Int = 0
  
  deinit {
    taskSource.invalidateAndCancel?()
  }
  
  public convenience init?(urlString: String) {
    self.init(urlString: urlString, configuration: .default)
  }
  
  public init?(urlString: String, configuration: URLSessionConfiguration) {
    
//    method_exchangeImplementations(class_getInstanceMethod(URLSession.classForCoder(), "dataTaskWithRequest:completionHandler:"), class_getInstanceMethod(URLSession.classForCoder(), "nkDataTaskWithRequest:completionHandler:"))
    
    guard let url = URL(string: urlString) else {
      return nil
    }
    
    self.url = url
    webDelegate = WebDelegate()
    taskSource = TaskSource.defaultSource(configuration, delegate: webDelegate, delegateQueue: webQueue)
    webDelegate?.webService = self
  }
}

extension WebService {
  
  public func HEAD(_ path: String) -> WebTask {
    return WebTask(webRequest: WebRequest(method: .HEAD, url: url.appendingPathComponent(path)), webService: self)
  }
  public func GET(_ path: String, taskType: WebTask.TaskType = .data) -> WebTask {
    return WebTask(webRequest: WebRequest(method: .GET, url: url.appendingPathComponent(path)), webService: self, taskType: taskType)
  }
  public func POST(_ path: String, taskType: WebTask.TaskType = .data) -> WebTask {
    return WebTask(webRequest: WebRequest(method: .POST, url: url.appendingPathComponent(path)), webService: self, taskType: taskType)
  }
  public func PUT(_ path: String) -> WebTask {
    return WebTask(webRequest: WebRequest(method: .PUT, url: url.appendingPathComponent(path)), webService: self)
  }
  public func DELETE(_ path: String) -> WebTask {
    return WebTask(webRequest: WebRequest(method: .DELETE, url: url.appendingPathComponent(path)), webService: self)
  }
}
