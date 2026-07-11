@preconcurrency import AVFoundation
import FamilyControls
import ManagedSettings
import SwiftUI

struct SettingsView: View {
    @Environment(LimiarAppModel.self) private var model
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(\.openURL) private var openURL
    @State private var showingPicker = false
    @State private var showingPaywall = false

    private let subscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!
    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private let privacyURL = URL(string: "https://limiar-five.vercel.app/privacy.html")!
    private let supportURL = URL(string: "https://limiar-five.vercel.app/support.html")!

    var body: some View {
        @Bindable var model = model

        ZStack {
            LimiarBackground()

            Form {
                Section("Ativação") {
                    Toggle("Limiar ativo", isOn: $model.blockingEnabled)
                        .disabled(!model.hasPauseAccess)
                    LabeledContent("Pausa diária") {
                        Text(model.unlockDurationDescription)
                            .foregroundStyle(.secondary)
                    }
                    Button("Ajustar apps que ativam o Limiar") {
                        showingPicker = true
                    }
                    .disabled(!model.hasPauseAccess)

                    if model.hasBlockedAppsSelection {
                        BlockedSelectionHierarchySummary(selection: model.selection)
                            .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                            .listRowBackground(Color.clear)
                    }
                }

                Section("Preferências bíblicas") {
                    Picker(
                        "Tradição",
                        selection: Binding(
                            get: { model.faithProfile.tradition },
                            set: { model.selectTradition($0) }
                        )
                    ) {
                        ForEach(FaithTradition.allCases) { tradition in
                            Text(tradition.title).tag(tradition)
                        }
                    }
                    .disabled(!subscription.hasPremiumAccess)
                    Picker("Explicação", selection: $model.faithProfile.explanationDepth) {
                        ForEach(ExplanationDepth.allCases) { depth in
                            Text(depth.title).tag(depth)
                        }
                    }
                    .disabled(!subscription.hasPremiumAccess)
                    NavigationLink("Estilos de leitura e livros") {
                        BiblicalPreferencesView()
                    }
                    .disabled(!subscription.hasPremiumAccess)
                }

                Section("Histórico") {
                    NavigationLink("Ver leituras") {
                        HistoryView()
                    }
                    .disabled(!subscription.hasPremiumAccess)
                    NavigationLink("Ver trechos salvos") {
                        FavoritePassagesView()
                    }
                    .disabled(!subscription.hasPremiumAccess)
                    Button("Resetar histórico") {
                        model.resetHistory()
                    }
                    .foregroundStyle(.red)
                }

                Section("Limiar Premium") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(subscriptionStatusLabel)
                            .foregroundStyle(subscription.hasPremiumAccess || subscription.isEssentialMode ? Color.sageButton : .secondary)
                    }

                    if !subscription.hasActiveSubscription && subscription.canShowPaywall {
                        Button("Assinar Premium") {
                            showingPaywall = true
                        }
                    }

                    Button("Restaurar compra") {
                        Task {
                            await subscription.restorePurchases()
                        }
                    }
                    .disabled(subscription.isBusy)

                    Button("Gerenciar assinatura na Apple") {
                        openURL(subscriptionsURL)
                    }

                    if subscription.canResetTrialForTesting {
                        Button("Reiniciar acesso inicial de 7 dias") {
                            subscription.resetFreeTrialForTesting()
                            model.updateAccess(
                                hasPremiumAccess: subscription.hasPremiumAccess,
                                isEssentialMode: subscription.isEssentialMode
                            )
                        }

                        Text("Disponível apenas no TestFlight/sandbox para validar o período completo.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if !subscription.statusText.isEmpty {
                        Text(subscription.statusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Sobre") {
                    Text("Limiar ajuda você a escolher uma pausa antes de atravessar para apps de distração.")
                    Button("Termos de Uso") {
                        openURL(termsURL)
                    }
                    Button("Política de Privacidade") {
                        openURL(privacyURL)
                    }
                    Button("Suporte") {
                        openURL(supportURL)
                    }
                    NavigationLink("Diagnóstico técnico") {
                        DiagnosticsView()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .tint(Color.sageButton)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Configurações")
        .onChange(of: model.blockingEnabled) { _, _ in
            model.saveProfile()
            model.applyBlocking()
        }
        .onChange(of: model.faithProfile) { _, _ in model.saveProfile() }
        .familyActivityPicker(isPresented: $showingPicker, selection: $model.selection)
        .onChange(of: model.selection) { _, _ in
            model.saveProfile()
            model.applyBlocking()
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
                .environment(subscription)
        }
    }

    private var subscriptionStatusLabel: String {
        switch subscription.accessState {
        case .trialNotStarted:
            return "Acesso inicial não iniciado"
        case .trialActive:
            return "Acesso inicial ativo"
        case .trialExpired:
            return "Acesso inicial encerrado"
        case .subscribed:
            return "Assinatura ativa"
        }
    }
}

struct BiblicalPreferencesView: View {
    @Environment(LimiarAppModel.self) private var model

    var body: some View {
        let config = model.faithProfile.tradition.readingConfig

        List {
            Section {
                Text("Estas escolhas orientam as leituras e reflexões geradas pelo Limiar.")
                    .foregroundStyle(.secondary)
            }

            Section {
                ForEach(config.categories) { category in
                    Toggle(isOn: categoryBinding(for: category, config: config)) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.label)
                            Text(category.hint)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                        }
                    }
                }
            } header: {
                Text("Estilos de leitura")
            } footer: {
                Text("Escolha ao menos \(config.minSelected). Você pode mudar quando quiser.")
            }

            let pool = model.faithProfile.refinementBookPool
            if !pool.isEmpty {
                Section {
                    ForEach(pool) { book in
                        Toggle(
                            config.bookDisplayTitle(book, tradition: model.faithProfile.tradition),
                            isOn: refinedBookBinding(for: book)
                        )
                    }
                } header: {
                    Text("Afinar por livros específicos (opcional)")
                } footer: {
                    Text("Estes livros terão prioridade nas suas leituras diárias. Os demais livros dos estilos escolhidos continuam aparecendo para variar.")
                }
            }
        }
        .navigationTitle("Leituras")
        .scrollContentBackground(.hidden)
        .background(LimiarBackground())
        .tint(Color.sageButton)
        .onDisappear {
            model.saveProfile()
            model.beginNewReading()
        }
    }

    private func categoryBinding(for category: ReadingStyleCategory, config: TraditionReadingConfig) -> Binding<Bool> {
        Binding {
            model.faithProfile.isCategorySelected(category.id)
        } set: { isSelected in
            let currentlySelected = model.faithProfile.isCategorySelected(category.id)
            guard isSelected != currentlySelected else { return }
            // Mantém sempre ao menos o mínimo selecionado nas configurações.
            if !isSelected, model.faithProfile.selectedReadingCategoryCount <= config.minSelected {
                return
            }
            model.toggleReadingCategory(category.id)
        }
    }

    private func refinedBookBinding(for book: BibleBook) -> Binding<Bool> {
        Binding {
            model.faithProfile.isRefinedBookSelected(book)
        } set: { isSelected in
            let currentlySelected = model.faithProfile.isRefinedBookSelected(book)
            guard isSelected != currentlySelected else { return }
            model.toggleRefinedBook(book)
        }
    }
}

struct HistoryView: View {
    @Environment(LimiarAppModel.self) private var model

    var body: some View {
        List {
            if model.history.isEmpty {
                Text("Nenhuma leitura concluída ainda.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(model.history) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.passageTitle)
                            .font(.headline)
                        Text(item.reference)
                            .foregroundStyle(.secondary)
                        Text(item.completedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Histórico")
        .scrollContentBackground(.hidden)
        .background(LimiarBackground())
    }
}

struct FavoritePassagesView: View {
    @Environment(LimiarAppModel.self) private var model

    var body: some View {
        List {
            if model.favoritePassages.isEmpty {
                Text("Nenhum trecho salvo ainda.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(model.favoritePassages) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.passageTitle)
                            .font(.headline)
                        Text(item.reference)
                            .foregroundStyle(.secondary)
                        Text(item.savedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Trechos salvos")
        .scrollContentBackground(.hidden)
        .background(LimiarBackground())
    }
}
