//
//  WebRequest.swift
//  NetKit
//
//  Created by Aziz Uysal on 2/12/16.
//  Copyright © 2016 Aziz Uysal. All rights reserved.
//

import Foundation

public struct WebRequest {
  
  public struct Headers {
    public static let userAgent = "User-Agent"
    public static let contentType = "Content-Type"
    public static let contentLength = "Content-Length"
    public static let accept = "Accept"
    public static let cacheControl = "Cache-Control"
    
    public struct ContentType {
      public static let json = "application/json"
      public static let xml = "text/xml"
      public static let formEncoded = "application/x-www-form-urlencoded"
    }
  }
  
  public enum Method: String {
    case HEAD = "HEAD"
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
  }
  
  public enum ParameterEncoding {
    case Percent, JSON
    
    public func encodeURL(url: NSURL, parameters: [String:AnyObject]) -> NSURL? {
      if let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false) {
        components.appendPercentEncodedQuery(parameters.percentEncodedQueryString)
        return components.URL
      }
      return nil
    }
    
    public func encodeBody(parameters: [String:AnyObject]) -> NSData? {
      switch self {
      case .Percent:
        return parameters.percentEncodedQueryString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
      case .JSON:
        do {
          return try NSJSONSerialization.dataWithJSONObject(parameters, options: [])
        } catch {
          return nil
        }
      }
    }
  }
  
  let method: Method
  private(set) var url: String
  var body: NSData?
  
  var cachePolicy = NSURLRequestCachePolicy.UseProtocolCachePolicy
  
  var urlParameters = [String:AnyObject]()
  var bodyParameters = [String:AnyObject]()
  var parameterEncoding = ParameterEncoding.Percent {
    didSet {
      if parameterEncoding == .JSON {
        contentType = Headers.ContentType.json
      }
    }
  }
  
  var restPath = "" {
    didSet {
      url = url.stringByAppendingPathComponent(restPath)
    }
  }
  
  var headers = [String:String]()
  var contentType: String? {
    set { headers[Headers.contentType] = newValue }
    get { return headers[Headers.contentType] }
  }
  
  var urlRequest: NSURLRequest {
    let request = NSMutableURLRequest(URL: NSURL(string: url)!)
    request.HTTPMethod = method.rawValue
    request.cachePolicy = cachePolicy
    
    for (name, value) in headers {
      request.addValue(value, forHTTPHeaderField: name)
    }
    
    if urlParameters.count > 0 {
      if let url = request.URL, encodedURL = parameterEncoding.encodeURL(url, parameters: urlParameters) {
        request.URL = encodedURL
      }
    }
    
    if bodyParameters.count > 0 {
      if let data = parameterEncoding.encodeBody(bodyParameters) {
        request.HTTPBody = data
        if request.valueForHTTPHeaderField(Headers.contentType) == nil {
          request.setValue(Headers.ContentType.formEncoded, forHTTPHeaderField: Headers.contentType)
        }
      }
    }
    
    if let body = body {
      request.HTTPBody = body
    }
    
    return request.copy() as! NSURLRequest
  }
  
  public init(method: Method, url: String) {
    self.method = method
    self.url = url
  }
}

extension NSURLComponents {
  func appendPercentEncodedQuery(query: String) {
    percentEncodedQuery = percentEncodedQuery == nil ? query : "\(percentEncodedQuery)&\(query)"
  }
}

extension Dictionary {
  var percentEncodedQueryString: String {
    var components = [String]()
    for (name, value) in self {
      if let percentEncodedPair = percentEncode((name, value)) {
        components.append(percentEncodedPair)
      }
    }
    return components.joinWithSeparator("&")
  }
  
  func percentEncode(element: Element) -> String? {
    let (name, value) = element
    if let encodedName = "\(name)".percentEncodeURLQueryCharacters, let encodedValue = "\(value)".percentEncodeURLQueryCharacters {
      return "\(encodedName)=\(encodedValue)"
    }
    return nil
  }
}

extension String {
  var percentEncodeURLQueryCharacters: String? {
    return self.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())
  }
}