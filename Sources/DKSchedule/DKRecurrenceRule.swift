//
//  DKRecurrenceRule.swift
//  DueKit
//
//  Created by Calugar George on 18/09/2026.
//

import Foundation


public enum RecurrenceRule: Sendable, Equatable, Codable {
    case monthly(every: Int, day: Int)
    case yearly(every: Int, month: Int, day: Int)
    
    
}

extension RecurrenceRule {
    
}
//public struct RecurrenceRule: Equatable, Sendable {
//extension RecurrenceRule {
//    public enum Unit: Equatable, Sendable {
//        //no psecial cases for this
//        //        case  day
//        //        case week
//        case month
//        case year
//    }
//    public init(unit: Unit, interval: Int = 1, dayAnchor: Int, monthAnchor: Int? = nil) {
//        //preconditioning
//        precondition(interval >= 1, "interval must be at least 1")
//        precondition((1...31).contains(dayAnchor), "dayAnchor must be 1...31")
//        if let monthAnchor { precondition((1...12).contains(monthAnchor), "monthAnchor must be 1...12") }
//        if unit == .year { precondition(monthAnchor != nil, "yearly rules need monthAnchor") }
//        
//        //init
//        self.unit = unit
//        self.interval = interval
//        self.dayAnchor = dayAnchor
//        self.monthAnchor = monthAnchor
//    }
//}

//convenient initialzers
extension RecurrenceRule {
    public init?(monthlyEvery every: Int, on day: Int){
        let rule = RecurrenceRule.monthly(every: every, day: day)
        guard rule.isValid else {
            return nil
        }
        self = rule
    }
    public init?(yearlyEvery every: Int, on month: Int, and day: Int) {
        let rule = RecurrenceRule.yearly(every: every, month: month, day: day)
        guard rule.isValid else {
            return nil
        }
        self = rule
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
            .monthly(every: interval,
                             day: calendar.component(.day, from: date))
//        RecurrenceRule(unit: .month,
//                       interval: interval,
//                       dayAnchor: calendar.component(.day, from: date))
    }
    
    public static func yearly(interval: Int = 1,
                              anchoring date: Date,
                              calendar: Calendar = Calendar.current) -> RecurrenceRule{
        .yearly(every: interval, month: calendar.component(.month, from: date), day: calendar.component(.day, from: date))
//        RecurrenceRule(unit: .year,
//                       interval: interval,
//                       dayAnchor: calendar.component(.day, from: date),
//                       monthAnchor: calendar.component(.month, from: date))
    }
    
}
//Anchors
extension RecurrenceRule {
    public static func monthlyAnchored(to date: Date, every: Int = 1, in  calendar: Calendar) -> RecurrenceRule {
        .monthly(every: every, day: calendar.component(.day, from: date))
    }
    public static func yearlyAnchored(to date: Date, every: Int = 1, in calendar: Calendar) -> RecurrenceRule {
        .yearly(every: every, month: calendar.component(.month, from: date), day: calendar.component(.day, from: date))
    }
    private var dayAnchor: Int {
        switch self {
            case let.monthly(every: _, day: day),
            let .yearly(every: _, month: _, day: day): day
        }
    }
}
extension RecurrenceRule {
    public func occurrence(_ step: Int, from start: Date, in calendar: Calendar) -> Date? {
        guard isValid else {
            //Trowable with clear error here.
            return nil;
        }
        var firstOfMonth: Date
        switch self {
        case let .monthly(every: every, day: _):
            let startMonth = calendar.dateInterval(of: .month, for: start)!.start
            firstOfMonth = calendar.date(byAdding: .month, value: step * every, to: startMonth)!
        case let .yearly(every: every, month: month, day: _):
            let year = calendar.component(.year, from: start)+step*every
            firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        }
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)!.count
        let day = min(dayAnchor,daysInMonth)
        return calendar.date(byAdding: .day, value: day, to: firstOfMonth)
    }
    public func nextOccurrence(after reference: Date, from start: Date, in calendar: Calendar) -> Date {
        let limit = calendar.startOfDay(for: max(reference, start))
        var step = 1
        while true {
            let candidate = occurrence(step, from: start, in: calendar)!
            if candidate > limit { return candidate }
            step += 1
        }
    }
}
extension RecurrenceRule {
    public var isValid: Bool {
        switch self {
        case let .monthly(every: every, day: day):
            return every >= 1 && (1...31).contains(day) //day can be any day. beecause it will float base on the month
        case let .yearly(every: every, month: month, day: day):
            guard every >= 1, (1...12).contains(month) else {
                return false;
            }
            return (1...Self.lastDayOfTheMonth(in: month)).contains(day)
        }
    }
    private static func lastDayOfTheMonth(in month: Int) -> Int {
        switch month {
            //TODO: Maybe add "in year" here.. will help in testability and also make sure the validatino is ok.
        case 2: return 29 //February....
        case 4, 6, 9, 11: return 30  //Fewer than 31...
        default: return 31
        }
    }
}
