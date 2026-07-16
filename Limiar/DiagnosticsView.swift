import SwiftUI

/// Tela de diagnóstico em campo: mostra os eventos registrados pelo app e pela
/// extensão de monitoramento (aplicações de shield, agendamentos, falhas).
/// Essencial para investigar o rearme do ciclo sem depender do Xcode.
struct DiagnosticsView: View {
    @State private var entries: [LimiarEventLog.Entry] = []

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM HH:mm:ss"
        return formatter
    }()

    var body: some View {
        ZStack {
            LimiarBackground()

            Form {
                Section {
                    Text("Eventos do shield e do agendamento matinal. Os eventos \"monitor.*\" provam que a extensão rodou com o app fechado.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Eventos recentes") {
                    if entries.isEmpty {
                        Text("Nenhum evento registrado ainda.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(entries) { entry in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text("\(entry.source).\(entry.event)")
                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                Spacer()
                                Text(Self.timeFormatter.string(from: entry.timestamp))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            if !entry.details.isEmpty {
                                Text(entry.details.sorted { $0.key < $1.key }
                                    .map { "\($0.key)=\($0.value)" }
                                    .joined(separator: "  "))
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section {
                    Button("Copiar eventos") {
                        UIPasteboard.general.string = entries
                            .map { entry in
                                let details = entry.details.sorted { $0.key < $1.key }
                                    .map { "\($0.key)=\($0.value)" }
                                    .joined(separator: " ")
                                return "\(Self.timeFormatter.string(from: entry.timestamp)) \(entry.source).\(entry.event) \(details)"
                            }
                            .joined(separator: "\n")
                    }
                    Button("Limpar registro") {
                        LimiarEventLog.clear()
                        entries = []
                    }
                    .foregroundStyle(.red)
                }
            }
            .scrollContentBackground(.hidden)
            .tint(Color.sageButton)
        }
        .navigationTitle("Diagnóstico técnico")
        .onAppear { entries = LimiarEventLog.recentEntries() }
        .refreshable { entries = LimiarEventLog.recentEntries() }
    }
}
