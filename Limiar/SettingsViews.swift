@preconcurrency import AVFoundation
import FamilyControls
import ManagedSettings
import PhotosUI
import SwiftUI

struct SettingsView: View {
    @Environment(LimiarAppModel.self) private var model
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(LimiarNotificationCoordinator.self) private var notifications
    @Environment(\.openURL) private var openURL
    @State private var showingPicker = false
    @State private var showingPaywall = false
    @State private var showingHistory = false
    @State private var showingFavorites = false
    @State private var selectedProfilePhoto: PhotosPickerItem?
    @State private var showingRemoveProfilePhotoConfirmation = false
    @State private var showingNotificationPrePrompt = false

    private let subscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!
    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private let privacyURL = URL(string: "https://limiar-five.vercel.app/privacy.html")!
    private let supportURL = URL(string: "https://limiar-five.vercel.app/support.html")!

    var body: some View {
        @Bindable var model = model
        let hasProfileImage = model.profileImageStore.image != nil
        let profileImageActionTitle = hasProfileImage ? "Alterar foto" : "Adicionar foto"
        let profileImageAccessibilityLabel = hasProfileImage
            ? "Alterar foto do perfil"
            : "Adicionar foto do perfil"

        ZStack {
            LimiarBackground()

            Form {
                Section("Perfil") {
                    VStack(spacing: 16) {
                        ProfileAvatarView(
                            store: model.profileImageStore,
                            size: 104
                        )

                        PhotosPicker(
                            selection: $selectedProfilePhoto,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Label(
                                profileImageActionTitle,
                                systemImage: "photo.on.rectangle"
                            )
                            .font(.system(size: 15, weight: .semibold))
                            .frame(minHeight: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.sageButton)
                        .foregroundStyle(Color.deepInk)
                        .disabled(model.profileImageStore.isLoading)
                        .accessibilityLabel(profileImageAccessibilityLabel)

                        if hasProfileImage {
                            Button(role: .destructive) {
                                showingRemoveProfilePhotoConfirmation = true
                            } label: {
                                Label("Remover foto", systemImage: "trash")
                                    .frame(minHeight: 44)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Remover foto do perfil")
                        }

                        if let errorMessage = model.profileImageStore.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(Color.conversionCoral)
                                .multilineTextAlignment(.center)
                                .accessibilityLabel("Erro: \(errorMessage)")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }

                Section("Ativação") {
                    Toggle("Limiar ativo", isOn: $model.blockingEnabled)
                        .disabled(!model.hasPauseAccess)

                    Picker(
                        "Turno da pausa",
                        selection: Binding(
                            get: { model.pauseCycleTurn },
                            set: { model.selectPauseCycleTurn($0) }
                        )
                    ) {
                        ForEach(PauseCycleTurn.allCases) { turn in
                            Text("\(turn.title) · \(turn.hourLabel)").tag(turn)
                        }
                    }
                    .disabled(!model.hasPauseAccess)

                    Text("A mudança vale a partir do próximo ciclo.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

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

                Section("Notificações") {
                    HStack {
                        Text("Permissão")
                        Spacer()
                        Text(notifications.authorizationStatusLabel)
                            .foregroundStyle(notificationStatusColor)
                            .multilineTextAlignment(.trailing)
                    }

                    if notifications.authorizationStatus == .denied {
                        Button("Abrir Ajustes do iOS") {
                            notifications.openNotificationSettings()
                        }
                    } else if notifications.authorizationStatus == .notDetermined {
                        Button("Ativar notificações") {
                            showingNotificationPrePrompt = true
                        }
                    }

                    Text("A mesma permissão serve para o atalho da travessia e para o futuro lembrete da pausa diária.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                    Button("Ver leituras") {
                        // Sem depender de canShowPaywall: entre o fim do trial
                        // e a meia-noite seguinte o botão ficaria mudo.
                        if subscription.hasPremiumAccess {
                            showingHistory = true
                        } else {
                            showingPaywall = true
                        }
                    }
                    Button("Ver trechos salvos") {
                        if subscription.hasPremiumAccess || subscription.isEssentialMode {
                            showingFavorites = true
                        } else {
                            showingPaywall = true
                        }
                    }
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

                    if !subscription.hasActiveSubscription && subscription.isEssentialMode {
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
        .task {
            await notifications.refreshAuthorizationStatus()
        }
        .onChange(of: selectedProfilePhoto) { _, selectedPhoto in
            guard let selectedPhoto else { return }
            Task {
                await model.profileImageStore.importImage(from: selectedPhoto)
                selectedProfilePhoto = nil
            }
        }
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
        .navigationDestination(isPresented: $showingHistory) { HistoryView() }
        .navigationDestination(isPresented: $showingFavorites) { FavoritePassagesView() }
        .confirmationDialog(
            "Remover foto do perfil?",
            isPresented: $showingRemoveProfilePhotoConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remover foto", role: .destructive) {
                model.profileImageStore.removeImage()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("O Limiar voltará a mostrar o ícone padrão de perfil.")
        }
        .alert(
            LimiarNotificationCoordinator.prePromptTitle,
            isPresented: $showingNotificationPrePrompt
        ) {
            Button("Ativar") {
                Task { await notifications.requestAuthorization() }
            }
            Button("Agora não", role: .cancel) {}
        } message: {
            Text(LimiarNotificationCoordinator.prePromptMessage)
        }
    }

    private var notificationStatusColor: Color {
        switch notifications.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            Color.sageButton
        case .denied:
            Color.conversionCoral
        case .notDetermined:
            .secondary
        @unknown default:
            .secondary
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
                VStack(alignment: .leading, spacing: 4) {
                    Text("Escolha ao menos \(config.minSelected). Você pode mudar quando quiser.")
                    if model.faithProfile.selectedReadingCategoryCount == 2 {
                        Text("Dica: escolher mais estilos traz mais variedade às suas manhãs.")
                    }
                }
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
    @Environment(SubscriptionManager.self) private var subscription
    @State private var showingPaywall = false

    var body: some View {
        List {
            if model.favoritePassages.isEmpty {
                Text("Nenhum trecho salvo ainda.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(model.favoritePassages) { item in
                    NavigationLink {
                        FavoritePassageDetailView(favorite: item)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.passageTitle)
                                .font(.headline)
                            let passageText = model.favoritePassageText(for: item)
                            if !passageText.isEmpty {
                                Text(passageText)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                                    .truncationMode(.tail)
                            }
                            Text(item.savedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: removeFavorites)
            }
        }
        .navigationTitle("Trechos salvos")
        .scrollContentBackground(.hidden)
        .background(LimiarBackground())
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
                .environment(subscription)
        }
    }

    private func removeFavorites(at offsets: IndexSet) {
        if model.isEssentialMode {
            showingPaywall = true
        } else {
            model.removeFavorites(at: offsets)
        }
    }
}

private struct FavoritePassageDetailView: View {
    @Environment(LimiarAppModel.self) private var model
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(\.dismiss) private var dismiss
    @StateObject private var narration = PassageNarrationService()
    @State private var showingPaywall = false

    let favorite: FavoritePassageItem

    private var readingItem: SpiritualReadingItem {
        SpiritualReadingItem(
            id: favorite.passageID,
            reference: favorite.reference,
            text: model.favoritePassageText(for: favorite),
            homily: favorite.homily ?? "",
            practicalConclusion: favorite.practicalConclusion ?? "",
            passageID: favorite.passageID
        )
    }

    private var narrationSegments: [String] {
        [
            canonicalPassageNarrationText(
                reference: readingItem.reference,
                text: readingItem.text
            )
        ] + narrationExplanationSegments([
            readingItem.homily,
            readingItem.practicalConclusion
        ])
    }

    var body: some View {
        ZStack {
            LimiarBackground()

            ScrollView {
                SpiritualReadingCard(
                    item: readingItem,
                    isSaved: true,
                    saveAction: removeFavorite,
                    listenAction: listen,
                    narrationState: model.isEssentialMode
                        ? .idle
                        : narration.state(for: narrationSegments),
                    showsReflection: true,
                    showsNarration: model.hasPremiumAccess || model.isEssentialMode,
                    isSaveLocked: model.isEssentialMode,
                    isNarrationLocked: model.isEssentialMode
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle(favorite.reference)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            narration.stop()
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
                .environment(subscription)
        }
    }

    private func removeFavorite() {
        if model.isEssentialMode {
            showingPaywall = true
        } else {
            model.toggleFavorite(readingItem)
            dismiss()
        }
    }

    private func listen() {
        if model.isEssentialMode {
            showingPaywall = true
        } else {
            narration.toggle(segments: narrationSegments)
        }
    }
}
