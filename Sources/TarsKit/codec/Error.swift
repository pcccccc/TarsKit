//
//  Error.swift
//  TarsKit
//
//  Created by littleTurnip on 12/4/24.
//

// MARK: - BinaryReaderError

enum BinaryReaderError: Error {
  case outOfBounds
  case invalidLength
}

// MARK: - BinaryWriterError

enum BinaryWriterError: Error {
  case invalidLength
}

// MARK: - TarsStreamError

enum TarsStreamError: Error {
  case readToEnd
  case typeMismatch(expected: String, actual: String)
  case requiredFieldMissing
  case invalidSize(String)
  case invalidType(String)
}
