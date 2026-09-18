//
//  ScheduleTests.swift
//  DueKit
//
//  Created by Calugar George on 18/09/2026.
//

import Testing
import DKSchedule

@Test func unitTypeExistenceTest() {
    let _: [RecurrenceRule.Unit] = [RecurrenceRule.Unit.month, RecurrenceRule.Unit.year]  //force compilation errro
}
@Test func `recurenceRuleIntervalOne`() {
    //dest default rule
    let ruleMDefault = RecurrenceRule(unit: .month , dayAnchor: 31)
    
    #expect(ruleMDefault.unit == .month)
    #expect(ruleMDefault.interval == 1)
    
    let ruleM2 = RecurrenceRule(unit: .month,
                               interval: 2,
                                dayAnchor: 31)
    #expect(ruleM2.unit == .month)
    #expect(ruleM2.interval == 2)
    
}
