//
//  DKRecurrenceRuleError.swift
//  DueKit
//
//  Created by Calugar George on 18/09/2026.
//

//errors on validation
public enum RecurrenceRuleError: Error, Equatable, Sendable {
    case intervalShouldBeGraterThanZero(Int)
    case dayOutOfRange(Int)
    case monthOutOfRange(Int)
    case monthDayIsOutOfMonth(month: Int, day: Int)
    case dateOutOfRange  
}
