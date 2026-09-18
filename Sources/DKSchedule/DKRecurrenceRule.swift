//
//  DKRecurrenceRule.swift
//  DueKit
//
//  Created by Calugar George on 18/09/2026.
//

import Foundation

//errors on validation
public enum RecurrenceRuleError: Error {
    case intervalShouldBeGraterThanZero
    case dayOutOfRange
    case monthOutOfRange
    case monthDayIsOutOfMonth(month: Int, day: Int)
}

public struct RecurrenceRule: Equatable, Sendable {
    public enum Unit: Equatable, Sendable {
        //no psecial cases for this
        //        case  day
        //        case week
        case month
        case year
    }
    
    public let unit: Unit
    public let interval: Int
    
    public let dayAnchor: Int
    public let monthAnchor: Int? //Optional, unued on monthly
    
    public init(unit: Unit, interval: Int = 1, dayAnchor: Int, monthAnchor: Int? = nil) {
        //preconditioning
        precondition(interval >= 1, "interval must be at least 1")
        precondition((1...31).contains(dayAnchor), "dayAnchor must be 1...31")
        if let monthAnchor { precondition((1...12).contains(monthAnchor), "monthAnchor must be 1...12") }
        if unit == .year { precondition(monthAnchor != nil, "yearly rules need monthAnchor") }
        
        //init
        self.unit = unit
        self.interval = interval
        self.dayAnchor = dayAnchor
        self.monthAnchor = monthAnchor
    }
    
}

//helpers
//Calendar to allow uage of different type of calendars. Tests whould be implemented
extension RecurrenceRule {
    public static func validate(toValidate: Int ) throws {
        guard toValidate>=1 else{ throw RecurrenceRuleError.intervalShouldBeGraterThanZero }
    }
    
    public static func monthly(interval: Int = 1,
                               anchoring date:Date,
                               calendar: Calendar = Calendar.current) -> RecurrenceRule {
        RecurrenceRule(unit: .month,
                       interval: interval,
                       dayAnchor: calendar.component(.day, from: date))
    }
    
    public static func yearly(interval: Int = 1,
                              anchoring date: Date,
                              calendar: Calendar = Calendar.current) -> RecurrenceRule{
        RecurrenceRule(unit: .year,
                       interval: interval,
                       dayAnchor: calendar.component(.day, from: date),
                       monthAnchor: calendar.component(.month, from: date))
    }
    
    private static func lastDayOfTheMonth(in month: Int) -> Int {
        switch month {
        case 2: return 29 //February....
        case 4, 6, 9, 11: return 30  //Fewer than 31...
        default: return 31
        }
    }
    
}
