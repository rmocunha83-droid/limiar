@preconcurrency import AVFoundation
import FamilyControls
import ManagedSettings
import SwiftUI

struct ContentView: View {
    @Environment(LimiarAppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            Group {
                if model.hasCompletedOnboarding {
                    DashboardView()
                } else {
                    OnboardingView()
                }
            }
            .preferredColorScheme(.dark)
        }
        .tint(Color.sageButton)
        .statusBarHidden(true)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                model.prepareFreshPassageForForeground()
            }
        }
    }
}

private struct DashboardView: View {
    @Environment(LimiarAppModel.self) private var model
    @StateObject private var narration = PassageNarrationService()
    @State private var showingPicker = false
    @State private var showingSettings = false
    @State private var unlockPhase = UnlockButtonPhase.locked
    @State private var unlockAnimationTick = 0

    var body: some View {
        @Bindable var model = model

        ZStack {
            LimiarBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Limiar")
                                .font(.system(size: 48, weight: .regular, design: .serif))
                                .foregroundStyle(Color.ivory)

                            Text("Reserve alguns minutos para iluminar sua mente.")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundStyle(Color.softText)
                                .lineSpacing(4)
                        }

                        Spacer()

                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "person")
                                .font(.system(size: 18, weight: .medium))
                                .frame(width: 46, height: 46)
                                .glassCircle()
                        }
                        .accessibilityLabel("Abrir configurações")
                    }

                    blockedAppsStrip
                    readingRequirementHeader
                    readingItemsList
                    chooseAppsButton
                    completionExplanation
                    unlockButton
                    footer
                }
                .padding(.horizontal, 24)
                .padding(.top, 58)
                .padding(.bottom, 30)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationDestination(isPresented: $showingSettings) {
            SettingsView()
        }
        .familyActivityPicker(
            headerText: "Escolha apps, categorias ou sites que o Limiar deve proteger.",
            footerText: "Você pode alterar isso depois em Preferências.",
            isPresented: $showingPicker,
            selection: $model.selection
        )
        .onChange(of: model.selection) { _, _ in
            model.saveProfile()
            model.applyBlocking()
        }
        .task {
            model.reapplyBlockIfNeeded()
        }
        .onDisappear {
            narration.stop()
        }
    }

    private var blockedAppsStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("APPS BLOQUEADOS")
                .font(.system(size: 13, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(Color.warmGold)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    let tokens = Array(model.selection.applicationTokens)
                    if tokens.isEmpty {
                        InstagramIcon()
                            .frame(width: 58, height: 58)
                            .accessibilityLabel("Instagram")
                    } else {
                        ForEach(tokens, id: \.self) { token in
                            BlockedApplicationIcon(token: token)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(18)
        .limiarPanel()
    }

    private var readingRequirementHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("SEU LIMIAR", systemImage: "book.closed")
                .font(.system(size: 13, weight: .bold))
                .tracking(1.3)
                .foregroundStyle(Color.warmGold)

            Text(model.currentReadingTitle)
                .font(.system(size: 40, weight: .regular, design: .serif))
                .foregroundStyle(Color.ivory)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            Text("Leia com calma e conclua para liberar seus APPs pelo tempo escolhido.")
                .font(.system(size: 18))
                .foregroundStyle(Color.softText)
                .lineSpacing(5)
        }
    }

    private var readingItemsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Button {
                    narration.toggle(text: model.currentReadingNarrationText)
                } label: {
                    Label(narration.isSpeaking ? "Parar narração" : "Ouvir leitura", systemImage: narration.isSpeaking ? "stop.circle.fill" : "speaker.wave.2.fill")
                        .lineLimit(1)
                }
                .buttonStyle(ReadingActionButtonStyle(isHighlighted: narration.isSpeaking))
            }

            ForEach(model.currentSpiritualReadingItems) { item in
                SpiritualReadingCard(
                    item: item,
                    isSaved: model.isFavorite(item),
                    saveAction: {
                        model.toggleFavorite(item)
                    },
                    listenAction: {
                        narration.toggle(text: "\(item.reference). \(item.text). \(item.homily). \(item.practicalConclusion)")
                    },
                    isSpeaking: narration.isSpeaking
                )
            }
        }
    }

    private var chooseAppsButton: some View {
        Button {
            showingPicker = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 24, weight: .regular))
                    .frame(width: 52, height: 52)
                    .glassCircle()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Ajustar APPs bloqueados")
                        .font(.system(size: 19, weight: .regular, design: .serif))
                        .foregroundStyle(Color.ivory)
                    Text("Escolha quais APPs você quer bloquear")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.softText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.sageButton)
            }
            .contentShape(Rectangle())
        }
        .padding(16)
        .limiarPanel()
        .padding(.top, 8)
    }

    private var completionExplanation: some View {
        Text("Após concluir a leitura, seus APPs bloqueados serão liberados por \(model.unlockDurationDescription). Quando esse tempo terminar, será necessário fazer uma nova leitura para liberar o acesso novamente.")
            .font(.system(size: 14))
            .foregroundStyle(Color.softText)
            .lineSpacing(5)
            .padding(.horizontal, 2)
    }

    private var unlockButton: some View {
        Button {
            completeReadingWithUnlockAnimation()
        } label: {
            HStack(spacing: 18) {
                Image(systemName: unlockPhase.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.deepInk.opacity(0.70))
                    .scaleEffect(unlockPhase == .opening ? 1.18 : 1)
                    .rotationEffect(.degrees(unlockPhase == .opening ? -8 : 0))
                    .symbolEffect(.bounce, value: unlockAnimationTick)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 5) {
                    Text(unlockPhase.title)
                        .font(.system(size: 22, weight: .regular, design: .serif))
                        .foregroundStyle(Color.deepInk)
                    Text(unlockPhase.subtitle(duration: model.unlockDurationDescription))
                        .font(.system(size: 15))
                        .foregroundStyle(Color.deepInk.opacity(0.70))
                }
                Spacer()
                Image(systemName: unlockPhase.trailingIconName)
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(Color.deepInk)
                    .opacity(unlockPhase == .unlocked ? 0.9 : 1)
            }
            .padding(.horizontal, 34)
            .frame(height: 104)
            .background(unlockPhase.backgroundColor, in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(unlockPhase.strokeColor, lineWidth: 1)
            )
            .shadow(color: unlockPhase.shadowColor, radius: unlockPhase == .unlocked ? 18 : 8, x: 0, y: 10)
            .animation(.spring(response: 0.38, dampingFraction: 0.78), value: unlockPhase)
        }
        .disabled(unlockPhase == .opening)
        .accessibilityLabel(unlockPhase.title)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Image(systemName: "shield.lefthalf.filled")
            Text("Você no controle. Você escolhe o que atravessar.")
        }
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(Color.sageButton)
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private func completeReadingWithUnlockAnimation() {
        guard unlockPhase != .opening else { return }

        unlockPhase = .opening
        unlockAnimationTick += 1

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            model.finishReading()
            unlockPhase = .unlocked
            unlockAnimationTick += 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            unlockPhase = .locked
        }
    }
}

private enum UnlockButtonPhase: Equatable {
    case locked
    case opening
    case unlocked

    var iconName: String {
        switch self {
        case .locked: "lock.fill"
        case .opening, .unlocked: "lock.open.fill"
        }
    }

    var trailingIconName: String {
        switch self {
        case .locked: "arrow.right"
        case .opening: "sparkles"
        case .unlocked: "checkmark"
        }
    }

    var title: String {
        switch self {
        case .locked: "Li com calma, liberar acesso"
        case .opening: "Liberando acesso"
        case .unlocked: "Acesso liberado"
        }
    }

    func subtitle(duration: String) -> String {
        switch self {
        case .locked: "Libera por \(duration)"
        case .opening: "Abrindo seus APPs bloqueados"
        case .unlocked: "APPs liberados por \(duration)"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .locked: Color.sageButton
        case .opening: Color.warmGold
        case .unlocked: Color(red: 0.78, green: 0.89, blue: 0.80)
        }
    }

    var strokeColor: Color {
        switch self {
        case .locked: Color.ivory.opacity(0.26)
        case .opening: Color.ivory.opacity(0.34)
        case .unlocked: Color.ivory.opacity(0.42)
        }
    }

    var shadowColor: Color {
        switch self {
        case .locked: Color.black.opacity(0.20)
        case .opening: Color.warmGold.opacity(0.22)
        case .unlocked: Color.sageButton.opacity(0.28)
        }
    }
}

private struct InstagramIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0.99, green: 0.80, blue: 0.22), location: 0.00),
                            .init(color: Color(red: 0.98, green: 0.22, blue: 0.32), location: 0.38),
                            .init(color: Color(red: 0.75, green: 0.16, blue: 0.79), location: 0.72),
                            .init(color: Color(red: 0.25, green: 0.32, blue: 0.92), location: 1.00)
                        ],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white, lineWidth: 3)
                .frame(width: 30, height: 30)

            Circle()
                .stroke(.white, lineWidth: 3)
                .frame(width: 12, height: 12)

            Circle()
                .fill(.white)
                .frame(width: 5, height: 5)
                .offset(x: 10, y: -10)
        }
    }
}

private struct BlockedApplicationIcon: View {
    let token: ApplicationToken

    var body: some View {
        Label(token)
            .labelStyle(.iconOnly)
            .frame(width: 58, height: 58)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.sageButton.opacity(0.20), lineWidth: 1)
            )
            .accessibilityLabel("APP bloqueado")
    }
}

private struct SpiritualReadingCard: View {
    let item: SpiritualReadingItem
    let isSaved: Bool
    let saveAction: () -> Void
    let listenAction: () -> Void
    let isSpeaking: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                Label(item.reference, systemImage: "quote.opening")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.warmGold)
                    .lineLimit(2)

                Spacer()

                Button(action: saveAction) {
                    Image(systemName: isSaved ? "heart.fill" : "heart")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(isSaved ? Color.sageButton : Color.ivory)
                        .frame(width: 42, height: 42)
                        .background(Color.white.opacity(0.08), in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                }
                .accessibilityLabel(isSaved ? "Remover trecho salvo" : "Salvar trecho")
            }

            Text(item.text)
                .font(.system(size: 22, weight: .regular, design: .serif))
                .foregroundStyle(Color.ivory)
                .lineSpacing(7)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                Text("Explicação espiritual")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1.1)
                    .foregroundStyle(Color.warmGold)

                Text(item.homily)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.softText)
                    .lineSpacing(5)

                Text(item.practicalConclusion)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.ivory.opacity(0.9))
                    .lineSpacing(5)
            }
            .padding(14)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))

            Button(action: listenAction) {
                Label(isSpeaking ? "Parar narração" : "Ouvir este trecho", systemImage: isSpeaking ? "stop.circle.fill" : "speaker.wave.2.fill")
                    .lineLimit(1)
            }
            .buttonStyle(ReadingActionButtonStyle(isHighlighted: isSpeaking))
        }
        .padding(18)
        .limiarPanel()
    }
}

private struct ReadingView: View {
    @Environment(LimiarAppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @StateObject private var narration = PassageNarrationService()
    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        @Bindable var model = model

        ZStack {
            LimiarBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    Text(model.currentReadingTitle)
                        .font(.system(size: 42, weight: .regular, design: .serif))
                        .foregroundStyle(Color.ivory)
                        .padding(.top, 18)

                    HStack {
                        Label(model.currentReadingReference, systemImage: "book.closed")
                        Spacer()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.warmGold)

                    readingActions

                    Text(model.currentReadingText)
                        .font(.system(size: 24, weight: .regular, design: .serif))
                        .foregroundStyle(Color.ivory)
                        .lineSpacing(8)
                        .padding(.vertical, 10)

                    aiStatusBanner
                    reflectionSection
                    readingGate
                    disclaimer
                    completionButton
                }
                .padding(22)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(timer) { date in
            now = date
            model.updateReadingProgress(at: date)
        }
        .onAppear {
            model.startReadingSession()
        }
        .onDisappear {
            narration.stop()
            model.endReadingSession()
        }
    }

    private var readingActions: some View {
        HStack(spacing: 12) {
            Button {
                narration.toggle(text: model.currentReadingNarrationText)
            } label: {
                Label(narration.isSpeaking ? "Parar narração" : "Ouvir trecho", systemImage: narration.isSpeaking ? "stop.circle.fill" : "speaker.wave.2.fill")
                    .lineLimit(1)
            }
            .buttonStyle(ReadingActionButtonStyle(isHighlighted: narration.isSpeaking))

            Button {
                model.toggleFavoriteCurrentPassage()
            } label: {
                Label(model.isCurrentPassageFavorite ? "Salvo" : "Salvar", systemImage: model.isCurrentPassageFavorite ? "heart.fill" : "heart")
                    .lineLimit(1)
            }
            .buttonStyle(ReadingActionButtonStyle(isHighlighted: model.isCurrentPassageFavorite))
        }
    }

    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Reflexão breve", systemImage: "sparkle")
                .font(.system(size: 13, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(Color.warmGold)
                .padding(.top, 4)
            ReadingBlock(title: "Entenda o significado", text: model.currentReflection.summary)
            ReadingBlock(title: "Sentido espiritual", text: model.currentReflection.spiritualMeaning)
            ReadingBlock(title: "Para levar para o dia", text: model.currentReflection.practicalApplication)
            ReadingBlock(title: "Pergunta para refletir", text: model.currentReflection.meditationQuestion)
        }
    }

    private var aiStatusBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            if model.aiContentState == .generating {
                ProgressView()
                    .controlSize(.small)
                    .tint(Color.warmGold)
                    .padding(.top, 2)
            } else {
                Image(systemName: model.aiContentState == .remoteReady ? "sparkles" : "sparkle.magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.warmGold)
                    .padding(.top, 2)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(model.aiContentState.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.ivory)

                Text(model.aiContentState.subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.softText)
                    .lineSpacing(3)
            }
        }
        .padding(14)
        .background(Color.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.ivory.opacity(0.1), lineWidth: 1)
        )
    }

    private var readingGate: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.canCompleteReading ? "Leitura suficiente para liberar" : "Permaneça mais um pouco no trecho")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.ivory)

            Text(model.canCompleteReading ? "Você já pode concluir e liberar o tempo de uso." : "A barra avança enquanto você lê ou escuta. O objetivo é atravessar com calma.")
                .font(.system(size: 13))
                .foregroundStyle(Color.softText)
                .lineSpacing(4)
        }
        .padding(.top, 4)
    }

    private var disclaimer: some View {
        Text("As reflexões são geradas por IA para fins de meditação pessoal e não substituem orientação religiosa, pastoral ou rabínica.")
            .font(.system(size: 13))
            .foregroundStyle(Color.softText)
            .lineSpacing(4)
    }

    private var completionButton: some View {
        Button {
            model.finishReading()
            dismiss()
        } label: {
            Text(model.canCompleteReading ? "Concluir leitura" : "Siga no seu tempo")
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(model.canCompleteReading ? Color.aqua : Color.warmStone, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(model.canCompleteReading ? .black : Color.ivory.opacity(0.65))
        }
        .disabled(!model.canCompleteReading)
    }
}

private struct OnboardingView: View {
    @Environment(LimiarAppModel.self) private var model
    @State private var step = 0
    @State private var status = ""
    @State private var showingPicker = false
    @State private var showingAuthorizationAlert = false

    var body: some View {
        @Bindable var model = model

        ZStack {
            if step == 0 {
                WelcomeHeroScreen {
                    withAnimation { step = 1 }
                }
            } else {
                LimiarBackground()

                VStack(alignment: .leading, spacing: 24) {
                    Spacer(minLength: 18)

                    Group {
                        switch step {
                        case 1:
                            tradition
                        case 2:
                            biblicalPreferences
                        case 3:
                            screenTime
                        default:
                            unlockTime
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                    .animation(.easeInOut(duration: 0.22), value: step)

                    HStack(spacing: 14) {
                        if step > 0 {
                            Button {
                                withAnimation { step -= 1 }
                            } label: {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 22, weight: .regular))
                                    .frame(width: 48, height: 48)
                                    .glassCircle()
                            }
                            .accessibilityLabel("Voltar")
                        }

                        ForEach(0..<5, id: \.self) { index in
                            Capsule()
                                .fill(index == step ? Color.sageButton : Color.white.opacity(0.18))
                                .frame(width: index == step ? 34 : 8, height: 8)
                        }

                        Spacer()

                        Button {
                            advance()
                        } label: {
                            HStack(spacing: 14) {
                                Text(step == 4 ? "Ativar" : "Continuar")
                                if step != 4 {
                                    Image(systemName: "arrow.right")
                                }
                            }
                        }
                        .buttonStyle(LimiarPrimaryButtonStyle())
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 24)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .familyActivityPicker(
            headerText: "Escolha quais APPs você quer bloquear.",
            footerText: "O Limiar usa o seletor nativo do Tempo de Uso.",
            isPresented: $showingPicker,
            selection: $model.selection
        )
        .alert("Autorize o Tempo de Uso", isPresented: $showingAuthorizationAlert) {
            Button("Entendi", role: .cancel) {}
        } message: {
            Text("Para bloquear APPs, primeiro toque em Autorizar Tempo de Uso e confirme a permissão do iOS.")
        }
    }

    private var tradition: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                OnboardingTitle(eyebrow: "TRADIÇÃO", title: "Qual linguagem espiritual guia sua leitura?")
                ForEach(FaithTradition.allCases) { tradition in
                    SelectableRow(
                        title: tradition.title,
                        subtitle: tradition.subtitle,
                        isSelected: model.faithProfile.tradition == tradition
                    ) {
                        model.faithProfile.tradition = tradition
                    }
                }
            }
        }
        .padding(22)
    }

    private var biblicalPreferences: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                OnboardingTitle(eyebrow: "PREFERÊNCIAS", title: "Quais partes da Bíblia mais falam com você?")
                ChipGrid(
                    items: BibleSection.allCases.map(\.title),
                    selected: model.faithProfile.favoriteBibleSections.map(\.title)
                ) { title in
                    toggleSection(title)
                }
                Text("Temas espirituais")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.ivory)
                ChipGrid(
                    items: SpiritualTheme.allCases.map(\.title),
                    selected: model.faithProfile.favoriteThemes.map(\.title)
                ) { title in
                    toggleTheme(title)
                }
            }
            .padding(22)
        }
    }

    private var screenTime: some View {
        VStack(alignment: .leading, spacing: 20) {
            OnboardingTitle(eyebrow: "TEMPO DE USO", title: "Escolha quais APPs você quer bloquear.")

            Button {
                showingPicker = true
            } label: {
                Label("Selecionar APPs e categorias", systemImage: "square.grid.2x2")
                    .font(.system(size: 18, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.sageButton.opacity(0.28), lineWidth: 1))
            }

            Button {
                Task { status = await model.requestAuthorization() }
            } label: {
                Label(model.hasAuthorizedScreenTime ? "Tempo de Uso autorizado" : "Autorizar Tempo de Uso", systemImage: model.hasAuthorizedScreenTime ? "checkmark.shield.fill" : "checkmark.shield")
                    .font(.system(size: 18, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(Color.sageButton.opacity(0.95), in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(Color.deepInk)
            }

            Text(status.isEmpty ? "O iOS pedirá permissão antes de aplicar bloqueios." : status)
                .font(.system(size: 15))
                .foregroundStyle(Color.softText)
        }
        .padding(22)
    }

    private var unlockTime: some View {
        VStack(alignment: .leading, spacing: 20) {
            OnboardingTitle(eyebrow: "LIBERAÇÃO", title: "Defina o tempo de liberação do app após a leitura religiosa.")

            Text("Depois desse tempo, será necessário fazer uma nova leitura para liberar mais tempo de uso do APP.")
                .font(.system(size: 16))
                .foregroundStyle(Color.softText)
                .lineSpacing(5)

            ForEach([15, 30, 60], id: \.self) { minutes in
                SelectableRow(
                    title: "\(minutes) minutos",
                    subtitle: minutes == 30 ? "Equilíbrio recomendado para começar." : "Pode ser alterado depois.",
                    isSelected: model.unlockDurationMinutes == minutes
                ) {
                    model.unlockDurationMinutes = minutes
                }
            }
        }
        .padding(22)
    }

    private func toggleSection(_ title: String) {
        guard let section = BibleSection.allCases.first(where: { $0.title == title }) else { return }
        if model.faithProfile.favoriteBibleSections.contains(section) {
            model.faithProfile.favoriteBibleSections.removeAll { $0 == section }
        } else {
            model.faithProfile.favoriteBibleSections.append(section)
        }
    }

    private func toggleTheme(_ title: String) {
        guard let theme = SpiritualTheme.allCases.first(where: { $0.title == title }) else { return }
        if model.faithProfile.favoriteThemes.contains(theme) {
            model.faithProfile.favoriteThemes.removeAll { $0 == theme }
        } else {
            model.faithProfile.favoriteThemes.append(theme)
        }
    }

    private func advance() {
        if step == 3, !model.hasAuthorizedScreenTime {
            showingAuthorizationAlert = true
            return
        }

        if step < 4 {
            withAnimation { step += 1 }
        } else {
            model.completeOnboarding()
        }
    }
}

private struct SettingsView: View {
    @Environment(LimiarAppModel.self) private var model
    @State private var showingPicker = false

    var body: some View {
        @Bindable var model = model

        ZStack {
            LimiarBackground()

            Form {
                Section("Bloqueio") {
                    Toggle("Bloqueio ativo", isOn: $model.blockingEnabled)
                    Picker("Tempo liberado", selection: $model.unlockDurationMinutes) {
                        Text("15 min").tag(15)
                        Text("30 min").tag(30)
                        Text("1 hora").tag(60)
                    }
                    Button("Ajustar APPs bloqueados") {
                        showingPicker = true
                    }
                }

                Section("Preferências bíblicas") {
                    Picker("Tradição", selection: $model.faithProfile.tradition) {
                        ForEach(FaithTradition.allCases) { tradition in
                            Text(tradition.title).tag(tradition)
                        }
                    }
                    Picker("Explicação", selection: $model.faithProfile.explanationDepth) {
                        ForEach(ExplanationDepth.allCases) { depth in
                            Text(depth.title).tag(depth)
                        }
                    }
                    NavigationLink("Livros, temas e seções") {
                        BiblicalPreferencesView()
                    }
                }

                Section("Histórico") {
                    NavigationLink("Ver leituras") {
                        HistoryView()
                    }
                    NavigationLink("Ver trechos salvos") {
                        FavoritePassagesView()
                    }
                    Button("Resetar histórico") {
                        model.resetHistory()
                    }
                    .foregroundStyle(.red)
                }

                Section("Sobre") {
                    Text("Limiar ajuda você a escolher uma pausa antes de atravessar para apps de distração.")
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
        .onChange(of: model.unlockDurationMinutes) { _, _ in model.saveProfile() }
        .onChange(of: model.faithProfile) { _, _ in model.saveProfile() }
        .familyActivityPicker(isPresented: $showingPicker, selection: $model.selection)
    }
}

private struct BiblicalPreferencesView: View {
    @Environment(LimiarAppModel.self) private var model

    var body: some View {
        @Bindable var model = model

        List {
            Section("Partes da Bíblia") {
                ForEach(BibleSection.allCases) { section in
                    Toggle(section.title, isOn: binding(for: section, in: $model.faithProfile.favoriteBibleSections))
                }
            }
            Section("Livros favoritos") {
                ForEach(BibleBook.allCases) { book in
                    Toggle(book.title, isOn: binding(for: book, in: $model.faithProfile.favoriteBooks))
                }
            }
            Section("Temas") {
                ForEach(SpiritualTheme.allCases) { theme in
                    Toggle(theme.title, isOn: binding(for: theme, in: $model.faithProfile.favoriteThemes))
                }
            }
        }
        .navigationTitle("Preferências bíblicas")
        .scrollContentBackground(.hidden)
        .background(LimiarBackground())
        .tint(Color.sageButton)
        .onDisappear {
            model.saveProfile()
            model.beginNewReading()
        }
    }

    private func binding<T: Equatable>(for item: T, in collection: Binding<[T]>) -> Binding<Bool> {
        Binding {
            collection.wrappedValue.contains(item)
        } set: { isSelected in
            if isSelected {
                if !collection.wrappedValue.contains(item) {
                    collection.wrappedValue.append(item)
                }
            } else {
                collection.wrappedValue.removeAll { $0 == item }
            }
        }
    }
}

private struct HistoryView: View {
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

private struct FavoritePassagesView: View {
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

private struct LimiarBackground: View {
    var body: some View {
        ZStack {
            Color.deepInk
                .ignoresSafeArea()

            Image("DoorwayBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.deepInk.opacity(1.0),
                    Color.deepInk.opacity(0.94),
                    Color.deepInk.opacity(0.34),
                    Color.deepInk.opacity(0.78)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .ignoresSafeArea()

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: Color.deepInk.opacity(0.18), location: 0.24),
                    .init(color: Color.deepInk.opacity(0.94), location: 0.42),
                    .init(color: Color.deepInk.opacity(0.99), location: 1.0)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

private struct WelcomeHeroScreen: View {
    let action: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let horizontalInset: CGFloat = 28
            let contentWidth = max(proxy.size.width - (horizontalInset * 2), 1)

            ZStack {
                LimiarBackground()

                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                        .frame(height: proxy.size.height * 0.24)

                    Image("LimiarLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 84, height: 84, alignment: .leading)

                    Text("B E M - V I N D O")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.warmGold)
                        .padding(.top, 14)

                    Text("Limiar")
                        .font(.system(size: 76, weight: .regular, design: .serif))
                        .foregroundStyle(Color.ivory)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .padding(.top, 16)

                    Text("Antes de voltar para as\ndistrações, reserve alguns\nminutos para iluminar\nsua mente.")
                        .font(.system(size: 27, weight: .regular))
                        .foregroundStyle(Color.softText)
                        .lineSpacing(14)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 26)

                    Spacer()

                    HStack(alignment: .center, spacing: 12) {
                        HStack(spacing: 13) {
                            Capsule()
                                .fill(Color.sageButton)
                                .frame(width: 42, height: 7)
                            ForEach(0..<4, id: \.self) { _ in
                                Circle()
                                    .fill(Color.white.opacity(0.24))
                                    .frame(width: 9, height: 9)
                            }
                        }

                        Spacer()

                        Button(action: action) {
                            HStack(spacing: 14) {
                                Text("Continuar")
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 22, weight: .regular))
                            }
                        }
                        .buttonStyle(LimiarHeroButtonStyle())
                    }
                    .frame(width: contentWidth, alignment: .leading)
                    .padding(.bottom, 42)
                }
                .frame(width: contentWidth, alignment: .leading)
                .padding(.horizontal, horizontalInset)
                .ignoresSafeArea(edges: .top)
            }
        }
    }
}

private struct OnboardingTitle: View {
    let eyebrow: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow)
                .font(.system(size: 13, weight: .bold))
                .tracking(1.3)
                .foregroundStyle(Color.warmGold)
            Text(title)
                .font(.system(size: 38, weight: .regular, design: .serif))
                .foregroundStyle(Color.ivory)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct SelectableRow: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.sageButton : Color.softText)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(Color.ivory)
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.softText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
            }
            .padding(16)
            .background(.white.opacity(isSelected ? 0.15 : 0.07), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.sageButton.opacity(0.62) : Color.white.opacity(0.12), lineWidth: 1)
            )
        }
    }
}

private struct ChipGrid: View {
    let items: [String]
    let selected: [String]
    let action: (String) -> Void

    var body: some View {
        FlowLayout(spacing: 10) {
            ForEach(items, id: \.self) { item in
                Button {
                    action(item)
                } label: {
                    Text(item)
                        .font(.system(size: 15, weight: .medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(selected.contains(item) ? Color.sageButton.opacity(0.22) : Color.white.opacity(0.08), in: Capsule())
                        .overlay(Capsule().stroke(selected.contains(item) ? Color.sageButton : Color.white.opacity(0.12)))
                        .foregroundStyle(selected.contains(item) ? Color.sageButton : Color.ivory)
                }
            }
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arrangement = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in arrangement.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? 340
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}

private struct ReadingBlock: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Color.gold)
            Text(text)
                .font(.system(size: 17))
                .foregroundStyle(Color.softText)
                .lineSpacing(5)
        }
        .padding(16)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct ReadingActionButtonStyle: ButtonStyle {
    let isHighlighted: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                isHighlighted ? Color.sageButton.opacity(0.22) : Color.white.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHighlighted ? Color.sageButton.opacity(0.7) : Color.white.opacity(0.14), lineWidth: 1)
            )
            .foregroundStyle(isHighlighted ? Color.sageButton : Color.ivory)
            .opacity(configuration.isPressed ? 0.74 : 1)
    }
}

@MainActor
private final class PassageNarrationService: NSObject, ObservableObject, @preconcurrency AVSpeechSynthesizerDelegate {
    @Published var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func toggle(text: String) {
        if synthesizer.isSpeaking || isSpeaking {
            stop()
        } else {
            speak(text)
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = preferredVoice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.82
        utterance.pitchMultiplier = 0.92
        utterance.volume = 1
        synthesizer.speak(utterance)
        isSpeaking = true
    }

    private var preferredVoice: AVSpeechSynthesisVoice? {
        AVSpeechSynthesisVoice.speechVoices().first {
            $0.language == "pt-BR" && $0.gender == .male && $0.quality == .enhanced
        } ?? AVSpeechSynthesisVoice.speechVoices().first {
            $0.language == "pt-BR" && $0.gender == .male
        } ?? AVSpeechSynthesisVoice.speechVoices().first {
            $0.language == "pt-BR" && $0.quality == .enhanced
        } ?? AVSpeechSynthesisVoice(language: "pt-BR")
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
}

private struct LimiarPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 24, weight: .regular, design: .serif))
            .padding(.horizontal, 18)
            .frame(minWidth: 156)
            .frame(height: 62)
            .background(Color.sageButton.opacity(configuration.isPressed ? 0.76 : 1), in: RoundedRectangle(cornerRadius: 24))
            .foregroundStyle(Color.deepInk)
    }
}

private struct LimiarHeroButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 22, weight: .regular, design: .serif))
            .frame(width: 154, height: 62)
            .background(Color.sageButton.opacity(configuration.isPressed ? 0.76 : 1), in: RoundedRectangle(cornerRadius: 24))
            .foregroundStyle(Color.deepInk)
    }
}

private extension View {
    func glassCircle() -> some View {
        self
            .foregroundStyle(Color.aquaMist)
            .background(Color.deepInk.opacity(0.58), in: Circle())
            .overlay(Circle().stroke(Color.sageButton.opacity(0.34), lineWidth: 1))
    }

    func limiarPanel() -> some View {
        self
            .background(Color.deepInk.opacity(0.58), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.sageButton.opacity(0.20), lineWidth: 1)
            )
    }
}

private extension Color {
    static let deepInk = Color(red: 0.02, green: 0.04, blue: 0.045)
    static let ivory = Color(red: 0.94, green: 0.91, blue: 0.84)
    static let softText = Color(red: 0.74, green: 0.75, blue: 0.75)
    static let sageButton = Color(red: 0.70, green: 0.81, blue: 0.72)
    static let sageMist = Color(red: 0.58, green: 0.70, blue: 0.63)
    static let warmGold = Color(red: 0.83, green: 0.62, blue: 0.43)
    static let aqua = Color.sageButton
    static let aquaMist = Color.sageMist
    static let gold = Color.warmGold
    static let warmStone = Color(red: 0.43, green: 0.41, blue: 0.35)
}

#Preview {
    ContentView()
        .environment(LimiarAppModel())
}
