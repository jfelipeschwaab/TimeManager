import Foundation
import Combine

final class TimeManager {
    static let shared = TimeManager()

    // MARK: Publishers
    let dayDidChange = PassthroughSubject<Date, Never>()
    let remainingTimeDidChange = PassthroughSubject<TimeInterval, Never>()

    // MARK: Variáveis de controle do dia
    private var nextDayTriggerTimer: Timer?
    private var currentDay: Date

    // MARK: Variável de controle do timer regressivo
    private var liveTimer: Timer?

    private init() {
        currentDay = Calendar.current.startOfDay(for: Date())
        scheduleTimerForNextDay()

        if remainingTimeSinceStart() > 0 {
            startLiveTimer()
        }
    }

    /// Cria um timer para ser chamado na próxima meia-noite para atualizar o Publisher dayDidChange
    private func scheduleTimerForNextDay() {
        nextDayTriggerTimer?.invalidate()
        let now = Date()
        if let nextMidnight = Calendar.current.date(byAdding: .day, value: 1, to: currentDay) {
            let intervalToNextMidnight = nextMidnight.timeIntervalSince(now)
            nextDayTriggerTimer = Timer.scheduledTimer(withTimeInterval: intervalToNextMidnight, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                let today = Calendar.current.startOfDay(for: Date())
                self.currentDay = today
                self.dayDidChange.send(today)
                self.scheduleTimerForNextDay()
            }
        }
    }

    /// Cria um Timer Regressivo, da duração até 0d
    func startCountdown(duration: TimeInterval) {
        let endDate = Date().addingTimeInterval(duration)
        UserDefaults.standard.set(endDate, forKey: "timerEndDate")
        startLiveTimer()
    }
    
    
    /// Calcula o tempo que falta para o Timer regressivo acabar, em casos de o app ter sido minimizado ou celular desligado.
    func remainingTimeSinceStart() -> TimeInterval {
        guard let endDate = UserDefaults.standard.object(forKey: "timerEndDate") as? Date else {
            return 0
        }
        return max(endDate.timeIntervalSince(Date()), 0)
    }

    
    private func startLiveTimer() {
        stopLiveTimer()
        liveTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let remaining = self.remainingTimeSinceStart()
            self.remainingTimeDidChange.send(remaining)

            if remaining <= 0 {
                self.stopLiveTimer()
            }
        }
    }

    func stopLiveTimer() {
        liveTimer?.invalidate()
        liveTimer = nil
    }

    // MARK: - Formatação de tempo
    func formatTime(_ interval: TimeInterval) -> String {
        let seconds = Int(interval) % 60
        let minutes = (Int(interval) / 60) % 60
        let hours = Int(interval) / 3600
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
