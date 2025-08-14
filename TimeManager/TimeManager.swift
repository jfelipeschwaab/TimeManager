// MARK: - TimeManager.swift
import Foundation
import Combine

final class TimeManager {
    static let shared = TimeManager()
    let dayDidChange = PassthroughSubject<Date, Never>()

    private var timer: Timer?
    private var currentDay: Date

    private init() {
        //Meia noite de Hoje
        currentDay = Calendar.current.startOfDay(for: Date())
        
        //Cria o timer para a meia noite do dia de amanhã
        scheduleTimerForNextDay()
    }

    /// Calcula o tempo  de intervalo, em segundos, para a próxima meia noite e cria um Timer único baseado nesse tempo.
    /// Quando o timer dispara, atualiza currentDay(TimeManager) para a nova meia-noite
    private func scheduleTimerForNextDay() {
        timer?.invalidate()
        let now = Date()
        if let nextMidnight = Calendar.current.date(byAdding: .day, value: 1, to: currentDay) {
            let interval = nextMidnight.timeIntervalSince(now)
            print("Timer agendado para \(nextMidnight) (\(interval) segundos)")
            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                let today = Calendar.current.startOfDay(for: Date())
                self.currentDay = today
                print("Dia mudou! Notificando subscribers: \(today)")
                /// Publica a nova data por meio .send
                self.dayDidChange.send(today)
                ///Cria um novo schedule pro próximo dia
                self.scheduleTimerForNextDay()
            }
        }
    }
}
