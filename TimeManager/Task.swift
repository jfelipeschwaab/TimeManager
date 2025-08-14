//
//  Task.swift
//  TimeManager
//
//  Created by João Felipe Schwaab on 12/08/25.
//

// Task.swift
import Foundation
import SwiftData

@Model
class Task: Identifiable {
    var id = UUID()
    var name: String
    var criacao: Date
    
    init(name: String, criacao: Date) {
        self.name = name
        self.criacao = criacao
    }
}

