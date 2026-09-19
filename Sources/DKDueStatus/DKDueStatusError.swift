//
//  DKDueStatusError.swift
//  DueKit
//
//  Created by Calugar George on 19/09/2026.
//

public enum DueStatusError: Error, Equatable {
    case dueSoonDaysOutOfRange(Int)
}
