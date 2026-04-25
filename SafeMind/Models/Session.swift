//
//  Session.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 24/04/26.
//
import Foundation

struct Session: Codable, Identifiable {
    let id: String
    let type: String      // breathing, cbt, focus, acupressure
    let duration: Int     // in seconds
    let date: Date
}
