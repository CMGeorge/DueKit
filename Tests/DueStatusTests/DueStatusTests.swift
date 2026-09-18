//
//  DueStatusTests.swift
//  DueKit
//
//  Created by Calugar George on 18/09/2026.
//

import Testing
import DKDueStatus

@Test func dueStatusCaseExist() { //make sure no due case is deleted
    let _: [DueStatus] = [.overdue, .dueSoon, .upcoming] //force compilation errro

}
