//
//  TarsKit
//
//  Created by littleTurnip on 12/4/24.
//

import Alamofire
import Foundation
import OSLog

/// Tup 网络请求封装
public final class TarsHttp: Sendable {
  private let baseUrl: String
  private let path: String
  private let servantName: String
  private let timeOut: TimeInterval
  private let debugLog: Bool
  private let headers: [String: String]
  private let logger = Logger(subsystem: "TarsKit", category: "TarsHttpClient")

  public init(
    baseUrl: String,
    servantName: String,
    path: String = "",
    timeOut: TimeInterval = 60000,
    debugLog: Bool = false,
    headers: [String: String] = [:]
  ) {
    self.baseUrl = baseUrl
    self.servantName = servantName
    self.path = path
    self.timeOut = timeOut
    self.debugLog = debugLog

    var defaultHeaders = headers
    defaultHeaders["Content-Type"] = "application/x-wup"
    self.headers = defaultHeaders
  }

  public func tupRequest<REQ, RSP>(_ method: String, tReq: REQ, tRsp: RSP) async throws -> RSP {
    let response = try await tupRequestWithRspCode(method, tReq: tReq, tRsp: tRsp)
    guard response.code == 0 else {
      logger.error("tupDecode decode error: \(response.code)")
      throw TupResultException(response.code)
    }
    return response.response!
  }

  func tupRequestWithRspCode<REQ, RSP>(_ method: String, tReq: REQ, tRsp: RSP) async throws -> TupResponse<RSP> {
    let data = try buildRequest(methodName: method, request: tReq)
    logger.debug("send tupRequest, methodName: \(method)")

    let responseData = try await AF
      .upload(
        Data(data),
        to: baseUrl + path,
        headers: HTTPHeaders(headers),
        requestModifier: { $0.timeoutInterval = self.timeOut })
      .serializingData()
      .value

    return try tupResponseDecode(method: method, data: Uint8List(responseData), tRsp: tRsp)
  }

  func tupRequestNoRsp<REQ>(_ methodName: String, request: REQ) async throws {
    let response = try await tupRequestWithRspCodeNoRsp(methodName, request: request)
    guard response.code == 0 else {
      logger.error("tupDecode decode error: \(response.code)")
      throw TupResultException(response.code)
    }
  }

  func tupRequestWithRspCodeNoRsp<REQ>(_ methodName: String, request: REQ) async throws -> TupResponse<Void> {
    let data = try buildRequest(methodName: methodName, request: request)
    logger.debug("send tupRequestNoRsp, methodName: \(methodName)")

    let responseData = try await AF
      .upload(
        Data(data),
        to: baseUrl + path,
        headers: HTTPHeaders(headers),
        requestModifier: { $0.timeoutInterval = self.timeOut })
      .serializingData()
      .value

    return try tupEmptyResponseDecode(methodName: methodName, data: Uint8List(responseData))
  }

  private func buildRequest<REQ>(methodName: String, request: REQ) throws -> Uint8List {
    let encodePack = TarsUniPacket()
    encodePack.requestId = 0
    encodePack.setTarsVersion(Constants.packetTypeTup3)
    encodePack.setTarsPacketType(Constants.packetTypeTarsNormal)
    encodePack.servantName = servantName
    encodePack.funcName = methodName

    try encodePack.put("tReq", request)
    return try encodePack.encode()
  }

  private func tupResponseDecode<RSP>(method: String, data: Uint8List, tRsp: RSP) throws -> TupResponse<RSP> {
    let size = data.withUnsafeBytes { $0.load(as: Int32.self).bigEndian }
    logger.debug("size: \(size)")

    let respPack = TarsUniPacket()
    try respPack.decode(data)

    let code = respPack.get("", defaultValue: 0)
    logger.debug("get tupRequest response, methodName: \(method), code: \(code)")

    let response: RSP = respPack.get("tRsp", defaultValue: tRsp)
    return TupResponse(code: code, response: response)
  }

  private func tupEmptyResponseDecode(methodName: String, data: Uint8List) throws -> TupResponse<Void> {
    let size = data.withUnsafeBytes { $0.load(as: Int32.self).bigEndian }
    logger.debug("size: \(size) with no response")

    let respPack = TarsUniPacket()
    try respPack.decode(data)

    let code = respPack.get("", defaultValue: 0)
    logger.debug("get tupRequest response, methodName: \(methodName), code: \(code)")

    return TupResponse(code: code)
  }
}
