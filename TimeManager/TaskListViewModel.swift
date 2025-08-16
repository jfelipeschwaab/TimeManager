//MARK: VERSAO 6 + VERSAO 2 DO TIME MANAGER
// MARK: - TaskListViewModel.swift
import SwiftUI
import SwiftData
import Combine

@MainActor
final class TaskListViewModel: ObservableObject {
    @Published var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @Published private(set) var tasks: [Task] = []
    @Published var remainingTime: TimeInterval = 0


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
    
    func handleScenePhase(_ newPhase: ScenePhase) {
        if newPhase == .active {
            let today = Calendar.current.startOfDay(for: Date())
            if today != selectedDate {
                selectedDate = today
            }
            // Atualiza tempo restante
            remainingTime = TimeManager.shared.remainingTimeSinceStart()
        }
    }
    
    func startObservingTimer() {
        remainingTime = TimeManager.shared.remainingTimeSinceStart()
        
        TimeManager.shared.remainingTimeDidChange
            .receive(on: RunLoop.main)
            .sink { [weak self] newRemaining in
                self?.remainingTime = newRemaining
            }
            .store(in: &cancellables)
    }


}


struct TaskListView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: TaskListViewModel

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

            Text("Tempo restante: \(TimeManager.shared.formatTime(viewModel.remainingTime))")
                .font(.headline)

            Button("Iniciar Timer de 5 minutos") {
                TimeManager.shared.startCountdown(duration: 5 * 60)
            }
        }
        .onAppear {
            viewModel.startObservingTimer()
        }
        .onChange(of: scenePhase) { _, newPhase in
            viewModel.handleScenePhase(newPhase)
        }

    }
}
