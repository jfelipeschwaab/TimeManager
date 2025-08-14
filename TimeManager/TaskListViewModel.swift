//MARK: VERSAO 6 + VERSAO 2 DO TIME MANAGER
// MARK: - TaskListViewModel.swift
import SwiftUI
import SwiftData
import Combine

@MainActor
final class TaskListViewModel: ObservableObject {
    @Published var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @Published private(set) var tasks: [Task] = []

    private let context: ModelContext
    private var cancellables = Set<AnyCancellable>()

    init(context: ModelContext) {
        self.context = context

        // Recarrega tasks automaticamente quando selectedDate muda
        $selectedDate
            .sink { [weak self] newDate in
                self?.fetchTasks(for: newDate)
            }
            .store(in: &cancellables)

        // Escuta as mudanças do TimeManager que é um Singleton
        TimeManager.shared.dayDidChange
            .sink { [weak self] newDate in
                self?.selectedDate = newDate
            }
            .store(in: &cancellables)
    }

    private func fetchTasks(for date: Date) {
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!

        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate { task in
                task.criacao >= start && task.criacao < end
            },
            sortBy: [.init(\.criacao)]
        )

        do {
            tasks = try context.fetch(descriptor)
        } catch {
            print("Erro ao buscar tasks: \(error)")
        }
    }

    func criarTasksPadrao() {
        let startOfDay = selectedDate
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let titulo = formatter.string(from: startOfDay)

        let novaTask = Task(name: titulo, criacao: startOfDay)
        context.insert(novaTask)
        try? context.save()
    }
}
// MARK: - TaskListView.swift
import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: TaskListViewModel

    // Estado do timer
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?

    init(context: ModelContext) {
        _viewModel = StateObject(wrappedValue: TaskListViewModel(context: context))
    }

    var body: some View {
        VStack(spacing: 20) {
            List(viewModel.tasks) { task in
                Text(task.name)
            }

            Button("Criar Task Padrão do Dia") {
                viewModel.criarTasksPadrao()
            }
            .padding()

            // Exibe o tempo decorrido formatado
            Text("Tempo decorrido: \(formatTime(elapsedTime))")
                .font(.headline)

            // Botão para iniciar o timer
            Button("Iniciar Timer") {
                startCustomTimer()
                updateElapsedTime()
            }
            .padding()
        }
        .onAppear {
            updateElapsedTime()
            startUpdatingTimer()
        }
        .onDisappear {
            stopUpdatingTimer()
        }
        
        .onChange(of: scenePhase) { _ , newPhase in
            if newPhase == .active {
                let today = Calendar.current.startOfDay(for: Date())
                if today != viewModel.selectedDate {
                    viewModel.selectedDate = today
                }
                updateElapsedTime()
                startUpdatingTimer()
            } else if newPhase == .background {
                stopUpdatingTimer()
            }
        }
    }

    // MARK: - Timer Persistente
    func startCustomTimer() {
        UserDefaults.standard.set(Date(), forKey: "timerStartDate")
    }

    func elapsedTimeSinceStart() -> TimeInterval {
        guard let startDate = UserDefaults.standard.object(forKey: "timerStartDate") as? Date else {
            return 0
        }
        return Date().timeIntervalSince(startDate)
    }

    // Atualiza o estado do tempo decorrido
    func updateElapsedTime() {
        elapsedTime = elapsedTimeSinceStart()
    }

    // Inicia o Timer que atualiza a cada segundo
    func startUpdatingTimer() {
        stopUpdatingTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateElapsedTime()
        }
    }

    // Para o Timer
    func stopUpdatingTimer() {
        timer?.invalidate()
        timer = nil
    }

    // Formata para mm:ss
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
