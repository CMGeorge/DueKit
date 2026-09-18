//
//  DKRecurrenceRuleError.swift
//  DueKit
//
//  Created by Calugar George on 18/09/2026.
//

//errors on validation
public enum RecurrenceRuleError: Error {
    case intervalShouldBeGraterThanZero
    case dayOutOfRange
    case monthOutOfRange
    case monthDayIsOutOfMonth(month: Int, day: Int)
}
