@preconcurrency import AVFoundation
import FamilyControls
import ManagedSettings
import SwiftUI

struct ContentView: View {
    @Environment(LimiarAppModel.self) private var model
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(\.scenePhase) private var scenePhase
    @State private var dismissedTrialConversion = false
    @State private var dismissedEssentialModeIntro = false

    private static var forcePaywallForReviewScreenshot: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-LimiarForcePaywall")
        #else
        false
        #endif
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            Group {
                if Self.forcePaywallForReviewScreenshot {
                    PaywallView()
                } else if !model.hasCompletedOnboarding {
                    OnboardingView()
                } else if subscription.accessState == .trialNotStarted {
                    FreeTrialStartView()
                } else if subscription.shouldShowTrialConversion && !dismissedTrialConversion {
                    TrialConversionView {
                        dismissedTrialConversion = true
                    }
                } else if subscription.isEssentialMode && !dismissedEssentialModeIntro {
                    EssentialModeIntroView {
                        dismissedEssentialModeIntro = true
                    }
                } else {
                    DashboardView()
                }
            }
            .preferredColorScheme(.dark)
        }
        .tint(Color.sageButton)
        .statusBarHidden(true)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                subscription.refreshAccessState()
                model.updateAccess(
                    hasPremiumAccess: subscription.hasPremiumAccess,
                    isEssentialMode: subscription.isEssentialMode
                )
                model.prepareFreshPassageForForeground()
            }
        }
        .task {
            subscription.start()
            model.updateAccess(
                hasPremiumAccess: subscription.hasPremiumAccess,
                isEssentialMode: subscription.isEssentialMode
            )
        }
        .onChange(of: subscription.accessState) { _, _ in
            model.updateAccess(
                hasPremiumAccess: subscription.hasPremiumAccess,
                isEssentialMode: subscription.isEssentialMode
            )
        }
    }
}

private struct EssentialModeIntroView: View {
    let continueEssential: () -> Void

    var body: some View {
        ZStack {
            LimiarBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    Image("LimiarLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 62, height: 62)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("MODO ESSENCIAL")
                            .font(.system(size: 13, weight: .bold))
                            .tracking(1.3)
                            .foregroundStyle(Color.warmGold)

                        Text("Modo Essencial ativado")
                            .font(.system(size: 43, weight: .regular, design: .serif))
                            .foregroundStyle(Color.ivory)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Seu teste gratuito terminou. Você ainda pode continuar usando o Limiar com os trechos principais, mas sem narração e sem reflexões geradas pela IA.")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.softText)
                            .lineSpacing(5)

                        Text("Para ter reflexões personalizadas, narração dos textos e maior variedade de trechos, assine o Limiar completo.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.sageButton)
                            .lineSpacing(4)
                    }

                    VStack(alignment: .leading, spacing: 13) {
                        TrialDisclosureRow(icon: "book.closed", text: "3 trechos principais continuam disponíveis")
                        TrialDisclosureRow(icon: "sparkles", text: "Reflexões personalizadas na versão completa")
                        TrialDisclosureRow(icon: "speaker.wave.2", text: "Narração dos textos na versão completa")
                        TrialDisclosureRow(icon: "arrow.triangle.2.circlepath", text: "Maior variedade de trechos na versão completa")
                    }
                    .padding(16)
                    .limiarPanel()

                    NavigationLink {
                        PaywallView()
                    } label: {
                        HStack(spacing: 12) {
                            Text("Ver planos")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.sageButton, in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(Color.deepInk)
                    }

                    Button("Continuar no Modo Essencial") {
                        continueEssential()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.sageButton)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, 22)
                .padding(.top, 58)
                .padding(.bottom, 30)
            }
        }
    }
}

private struct FreeTrialStartView: View {
    @Environment(SubscriptionManager.self) private var subscription

    var body: some View {
        ZStack {
            LimiarBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    Image("LimiarLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 58, height: 58)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("TESTE GRATUITO")
                            .font(.system(size: 13, weight: .bold))
                            .tracking(1.3)
                            .foregroundStyle(Color.warmGold)

                        Text("Comece com 7 dias grátis")
                            .font(.system(size: 44, weight: .regular, design: .serif))
                            .foregroundStyle(Color.ivory)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Use o Limiar completo gratuitamente por 7 dias. Depois desse período, será necessária uma assinatura de R$ 9,90/mês para continuar usando as pausas, leituras e reflexões personalizadas.")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.softText)
                            .lineSpacing(5)
                    }

                    VStack(alignment: .leading, spacing: 13) {
                        TrialDisclosureRow(icon: "calendar.badge.clock", text: "7 dias grátis")
                        TrialDisclosureRow(icon: "creditcard", text: "Depois R$ 9,90/mês")
                        TrialDisclosureRow(icon: "xmark.circle", text: "Cancelamento a qualquer momento")
                        TrialDisclosureRow(icon: "checkmark.shield", text: "Sem cobrança antes do fim do teste")
                        TrialDisclosureRow(icon: "lock.open", text: "Assinatura necessária após o teste para continuar usando")
                    }
                    .padding(16)
                    .limiarPanel()

                    Button {
                        subscription.startFreeTrial()
                    } label: {
                        HStack(spacing: 12) {
                            Text("Começar 7 dias grátis")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.sageButton, in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(Color.deepInk)
                    }

                    Text("Você não está assinando agora. O teste começa localmente e o app pedirá assinatura somente após os 7 dias.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.softText)
                        .lineSpacing(4)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 22)
                .padding(.top, 58)
                .padding(.bottom, 30)
            }
        }
    }
}

private struct TrialConversionView: View {
    @Environment(SubscriptionManager.self) private var subscription
    let continueTrial: () -> Void

    var body: some View {
        ZStack {
            LimiarBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(subscription.trialRemainingText.uppercased())
                            .font(.system(size: 13, weight: .bold))
                            .tracking(1.3)
                            .foregroundStyle(Color.warmGold)

                        Text("Continue sua jornada com o Limiar")
                            .font(.system(size: 42, weight: .regular, design: .serif))
                            .foregroundStyle(Color.ivory)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Você já começou a recuperar seu foco e criar uma rotina espiritual. Para continuar usando as pausas, leituras e reflexões personalizadas após o teste gratuito, assine o Limiar Premium.")
                            .font(.system(size: 17))
                            .foregroundStyle(Color.softText)
                            .lineSpacing(5)
                    }

                    TrialMetricsPanel()

                    Button {
                        Task {
                            await subscription.purchase(.monthly)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text("Assinar por R$ 9,90/mês")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.sageButton, in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(Color.deepInk)
                    }
                    .disabled(subscription.isBusy)

                    Button("Continuar usando o teste") {
                        continueTrial()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.sageButton)
                    .frame(maxWidth: .infinity)

                    if !subscription.statusText.isEmpty {
                        Text(subscription.statusText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.softText)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 58)
                .padding(.bottom, 30)
            }
        }
    }
}

private struct TrialDisclosureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.warmGold)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.ivory)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct TrialMetricsPanel: View {
    @Environment(LimiarAppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Seu progresso até aqui")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.ivory)

            TrialMetricRow(
                icon: "book.closed",
                value: "\(model.history.count)",
                label: model.history.count == 1 ? "leitura concluída" : "leituras concluídas"
            )
            TrialMetricRow(
                icon: "clock",
                value: model.estimatedFocusTimeText,
                label: "com pausas antes dos apps"
            )
            TrialMetricRow(
                icon: "lock.open",
                value: "\(model.history.count)",
                label: model.history.count == 1 ? "pausa consciente" : "pausas conscientes"
            )
        }
        .padding(16)
        .limiarPanel()
    }
}

private struct TrialMetricRow: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.warmGold)
                .frame(width: 24)

            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(Color.ivory)
                .frame(minWidth: 46, alignment: .leading)

            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.softText)
        }
    }
}

private struct DashboardView: View {
    @Environment(LimiarAppModel.self) private var model
    @Environment(SubscriptionManager.self) private var subscription
    @StateObject private var narration = PassageNarrationService()
    @State private var showingPicker = false
    @State private var showingSettings = false
    @State private var unlockPhase = UnlockButtonPhase.locked
    @State private var unlockAnimationTick = 0

    var body: some View {
        @Bindable var model = model

        ZStack {
            LimiarBackground()

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 26) {
                        Color.clear
                            .frame(height: 1)
                            .id("readingTop")

                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Limiar")
                                    .font(.system(size: 48, weight: .regular, design: .serif))
                                    .foregroundStyle(Color.ivory)

                                Text("Reserve alguns minutos para uma leitura que fortaleça sua fé.")
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
                        trialStatusBadge
                        readingRequirementHeader
                        essentialModeNotice
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
                .onAppear {
                    proxy.scrollTo("readingTop", anchor: .top)
                }
                .onChange(of: model.readingTopResetID) { _, _ in
                    withAnimation(.easeOut(duration: 0.28)) {
                        proxy.scrollTo("readingTop", anchor: .top)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationDestination(isPresented: $showingSettings) {
            SettingsView()
        }
        .familyActivityPicker(
            headerText: "Escolha apps, categorias ou sites que vão ativar o Limiar.",
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

    private var trialStatusBadge: some View {
        Group {
            if subscription.accessState == .trialActive {
                HStack(spacing: 10) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.warmGold)

                    Text("Teste gratuito: \(subscription.trialRemainingText)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.ivory)

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
        }
    }

    private var blockedAppsStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("APPS QUE ATIVAM O LIMIAR")
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

            Text("Leia com calma e reflita sobre sua vida.")
                .font(.system(size: 18))
                .foregroundStyle(Color.softText)
                .lineSpacing(5)
        }
    }

    private var readingItemsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            if model.canNarrateCurrentReading {
                HStack(spacing: 12) {
                    Button {
                        narration.toggle(text: model.currentReadingNarrationText)
                    } label: {
                        Label(narration.isSpeaking ? "Parar narração" : "Ouvir leitura", systemImage: narration.isSpeaking ? "stop.circle.fill" : "speaker.wave.2.fill")
                            .lineLimit(1)
                    }
                    .buttonStyle(ReadingActionButtonStyle(isHighlighted: narration.isSpeaking))
                }
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
                    isSpeaking: narration.isSpeaking,
                    showsReflection: model.hasPremiumAccess && item.hasExplanationContent,
                    showsNarration: model.canNarrateCurrentReading
                )
            }
        }
    }

    private var essentialModeNotice: some View {
        Group {
            if model.isEssentialMode {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.sageButton)

                        Text("Modo Essencial")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.ivory)
                    }

                    Text("Você está lendo os trechos principais. Reflexões, narração e maior variedade estão disponíveis no Limiar completo.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.softText)
                        .lineSpacing(4)

                    NavigationLink {
                        PaywallView()
                    } label: {
                        Text("Ver planos")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.sageButton)
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.sageButton.opacity(0.18), lineWidth: 1)
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
                    Text("Ajustar Apps que ativam o Limiar")
                        .font(.system(size: 19, weight: .regular, design: .serif))
                        .foregroundStyle(Color.ivory)
                    Text("Defina quais apps vão acionar essa pausa")
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
        Text("Após concluir a leitura, os apps selecionados ficarão disponíveis para uso.")
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
        case .locked: "sunrise.fill"
        case .opening: "sparkles"
        case .unlocked: "checkmark.circle.fill"
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
        case .locked: "Li com calma, continuar"
        case .opening: "Preparando sua volta"
        case .unlocked: "Tudo pronto"
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
            .accessibilityLabel("App selecionado")
    }
}

private struct SpiritualReadingCard: View {
    let item: SpiritualReadingItem
    let isSaved: Bool
    let saveAction: () -> Void
    let listenAction: () -> Void
    let isSpeaking: Bool
    var showsReflection = true
    var showsNarration = true

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

            if showsReflection {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Explicação espiritual")
                        .font(.system(size: 13, weight: .bold))
                        .tracking(1.1)
                        .foregroundStyle(Color.warmGold)

                    Text(item.homily)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.ivory.opacity(0.92))
                        .lineSpacing(5)

                    Text(item.practicalConclusion)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color.softText.opacity(0.92))
                        .lineSpacing(5)
                }
                .padding(14)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
            }

            if showsNarration {
                Button(action: listenAction) {
                    Label(isSpeaking ? "Parar narração" : "Ouvir este trecho", systemImage: isSpeaking ? "stop.circle.fill" : "speaker.wave.2.fill")
                        .lineLimit(1)
                }
                .buttonStyle(ReadingActionButtonStyle(isHighlighted: isSpeaking))
            }
        }
        .padding(18)
        .limiarPanel()
    }
}

private struct ReadingView: View {
    @Environment(LimiarAppModel.self) private var model
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

                    if model.canNarrateCurrentReading {
                        readingActions
                    }

                    Text(model.currentReadingText)
                        .font(.system(size: 24, weight: .regular, design: .serif))
                        .foregroundStyle(Color.ivory)
                        .lineSpacing(8)
                        .padding(.vertical, 10)

                    if model.hasPremiumAccess {
                        aiStatusBanner
                        if model.hasVisibleReflection {
                            reflectionSection
                        }
                    } else if model.isEssentialMode {
                        essentialModeReadingNotice
                    }
                    readingGate
                    if model.hasPremiumAccess {
                        disclaimer
                    }
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

    private var essentialModeReadingNotice: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Modo Essencial", systemImage: "leaf.fill")
                .font(.system(size: 13, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(Color.warmGold)

            Text("Você está lendo os trechos principais. Reflexões, narração e maior variedade estão disponíveis no Limiar completo.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.softText)
                .lineSpacing(4)
        }
        .padding(14)
        .background(Color.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.ivory.opacity(0.1), lineWidth: 1)
        )
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
            Text(model.canCompleteReading ? "Leitura suficiente para continuar" : "Permaneça mais um pouco no trecho")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.ivory)

            Text(model.canCompleteReading ? "Você já pode concluir e retomar os apps selecionados." : "A barra avança enquanto você lê ou escuta. O objetivo é atravessar com calma.")
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
    @State private var step: Int
    @State private var status = ""
    @State private var readingPreferenceMessage = ""
    @State private var showingPicker = false
    @State private var didApplyDebugTradition = false

    init() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let stepFlagIndex = arguments.firstIndex(of: "-LimiarOnboardingStep"),
           arguments.indices.contains(stepFlagIndex + 1),
           let debugStep = Int(arguments[stepFlagIndex + 1]) {
            _step = State(initialValue: min(max(debugStep, 0), 5))
            return
        }
        #endif

        _step = State(initialValue: 0)
    }

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
                        switch displayedStep {
                        case 1:
                            tradition
                        case 2:
                            booksAndSections
                        case 3:
                            spiritualThemes
                        case 4:
                            reflectionDepth
                        case 5:
                            screenTime
                        default:
                            screenTime
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                    .animation(.easeInOut(duration: 0.22), value: step)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                    HStack(spacing: 12) {
                        Button {
                            moveToPreviousStep()
                        } label: {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 21, weight: .regular))
                                .frame(width: 46, height: 46)
                                .glassCircle()
                        }
                        .accessibilityLabel("Voltar")

                        HStack(spacing: 6) {
                            ForEach(Array(visibleSteps.enumerated()), id: \.offset) { index, _ in
                                Capsule()
                                    .fill(index == progressIndex ? Color.sageButton : Color.white.opacity(0.18))
                                    .frame(width: index == progressIndex ? 26 : 7, height: 7)
                            }
                        }
                        .frame(width: 106, alignment: .leading)

                        Spacer(minLength: 8)

                        Button {
                            advance()
                        } label: {
                            HStack(spacing: 10) {
                                Text(displayedStep == finalOnboardingStep ? "Ver teste grátis" : "Continuar")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)
                                if displayedStep != finalOnboardingStep {
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 18, weight: .regular))
                                }
                            }
                        }
                        .buttonStyle(LimiarPrimaryButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .familyActivityPicker(
            headerText: "Escolha quais apps vão ativar o Limiar.",
            footerText: "O Limiar usa o seletor nativo do Tempo de Uso.",
            isPresented: $showingPicker,
            selection: $model.selection
        )
        .onAppear {
            applyDebugTraditionIfNeeded()
            normalizeCurrentStepForTradition()
        }
        .onChange(of: model.selection) { _, _ in
            model.saveProfile()
        }
        .onChange(of: model.faithProfile.tradition) { _, _ in
            normalizeCurrentStepForTradition()
        }
    }

    private var shouldSkipStandaloneThemes: Bool {
        model.faithProfile.tradition == .spiritist
    }

    private var finalOnboardingStep: Int { 5 }

    private var visibleSteps: [Int] {
        shouldSkipStandaloneThemes ? [0, 1, 2, 4, 5] : [0, 1, 2, 3, 4, 5]
    }

    private var displayedStep: Int {
        shouldSkipStandaloneThemes && step == 3 ? 4 : step
    }

    private var progressIndex: Int {
        visibleSteps.firstIndex(of: displayedStep) ?? 0
    }

    private var screenTimeIsAuthorizedForDisplay: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-LimiarScreenTimeAuthorized") { return true }
        #endif
        return model.hasAuthorizedScreenTime
    }

    private var screenTimeHasSelectionForDisplay: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-LimiarBlockedAppsSelected") { return true }
        #endif
        return model.hasBlockedAppsSelection
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
                        selectTradition(tradition)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(22)
    }

    private var spiritualThemes: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                OnboardingTitle(eyebrow: "TEMAS", title: "Quais temas você quer cultivar nas pausas?")
                ChipGrid(
                    items: SpiritualTheme.standaloneOptions.map(\.title),
                    selected: model.faithProfile.favoriteThemes
                        .filter { SpiritualTheme.standaloneOptions.contains($0) }
                        .map(\.title)
                ) { title in
                    toggleTheme(title)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
        }
    }

    private var booksAndSections: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                OnboardingTitle(
                    eyebrow: "LIVROS",
                    title: "Quais textos você quer priorizar nas suas leituras?"
                )

                Text("Vamos criar leituras mais próximas da sua tradição. Você pode mudar depois.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.softText)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(model.faithProfile.tradition.readingPreferenceSections) { section in
                    ReadingPreferenceChipSection(
                        section: section,
                        profile: model.faithProfile
                    ) { option in
                        toggleReadingPreference(option)
                    }
                }

                if !readingPreferenceMessage.isEmpty {
                    Label(readingPreferenceMessage, systemImage: "info.circle")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.sageButton)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
        }
    }

    private var reflectionDepth: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                OnboardingTitle(eyebrow: "REFLEXÕES", title: "Qual tamanho de reflexão combina com sua rotina?")
                ForEach(ExplanationDepth.allCases) { depth in
                    SelectableRow(
                        title: depth.title,
                        subtitle: reflectionDepthSubtitle(for: depth),
                        isSelected: model.faithProfile.explanationDepth == depth
                    ) {
                        model.selectExplanationDepth(depth)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
        }
    }

    private var screenTime: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                OnboardingTitle(eyebrow: "ATIVAÇÃO", title: "Ative o Limiar")

                Text("Siga estas 2 etapas para começar.")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(Color.sageButton)
                    .lineSpacing(5)

                ScreenTimeSetupPanel(
                    isAuthorized: screenTimeIsAuthorizedForDisplay,
                    hasSelection: screenTimeHasSelectionForDisplay,
                    authorizeAction: {
                        Task { status = await model.requestAuthorization() }
                    },
                    selectAppsAction: {
                        showingPicker = true
                    }
                )

                if model.hasBlockedAppsSelection {
                    BlockedSelectionHierarchySummary(selection: model.selection)
                }

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.sageButton)
                        .padding(.top, 1)

                    Text(status.isEmpty ? "O iOS pedirá permissão antes de ativar as pausas." : status)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.softText)
                        .lineSpacing(4)
                }

                Button {
                    status = "Você poderá autorizar o Tempo de Uso depois em Configurações."
                    model.saveProfile()
                    model.completeOnboarding()
                } label: {
                    Text("Fazer isso depois")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.sageButton)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
        }
    }

    private func selectTradition(_ tradition: FaithTradition) {
        model.selectTradition(tradition)
        readingPreferenceMessage = ""
    }

    private func applyDebugTraditionIfNeeded() {
        #if DEBUG
        guard !didApplyDebugTradition else { return }
        didApplyDebugTradition = true
        let arguments = ProcessInfo.processInfo.arguments
        guard let traditionFlagIndex = arguments.firstIndex(of: "-LimiarTradition"),
              arguments.indices.contains(traditionFlagIndex + 1),
              let tradition = FaithTradition(rawValue: arguments[traditionFlagIndex + 1])
        else {
            return
        }
        model.selectTradition(tradition)
        #endif
    }

    private func toggleReadingPreference(_ option: ReadingPreferenceOption) {
        model.toggleReadingPreference(option)
        readingPreferenceMessage = ""
    }

    private func toggleTheme(_ title: String) {
        guard !shouldSkipStandaloneThemes else { return }
        guard let theme = SpiritualTheme.standaloneOptions.first(where: { $0.title == title }) else { return }
        model.toggleTheme(theme)
    }

    private func reflectionDepthSubtitle(for depth: ExplanationDepth) -> String {
        switch depth {
        case .short:
            return "Uma pausa breve, direta e fácil de concluir."
        case .medium:
            return "Equilíbrio recomendado para começar."
        case .deep:
            return "Mais contexto, aplicação e pergunta de meditação."
        }
    }

    private func advance() {
        if step == 2, !model.faithProfile.hasSelectedReadingPreferences {
            readingPreferenceMessage = "Escolha pelo menos uma opção para personalizar suas leituras."
            return
        }

        if step == 5 {
            model.saveProfile()
            advanceFromScreenTime()
            return
        }

        model.saveProfile()
        if let nextStep = nextStep(after: displayedStep) {
            withAnimation { step = nextStep }
        } else {
            model.completeOnboarding()
        }
    }

    private func advanceFromScreenTime() {
        if !model.hasAuthorizedScreenTime {
            Task { status = await model.requestAuthorization() }
            return
        }

        if !model.hasBlockedAppsSelection {
            status = "Agora escolha os apps ou categorias que vão ativar o Limiar."
            showingPicker = true
            return
        }

        model.completeOnboarding()
    }

    private func moveToPreviousStep() {
        guard let previousStep = previousStep(before: displayedStep) else { return }
        withAnimation { step = previousStep }
    }

    private func nextStep(after currentStep: Int) -> Int? {
        guard let currentIndex = visibleSteps.firstIndex(of: currentStep) else { return nil }
        let nextIndex = currentIndex + 1
        guard visibleSteps.indices.contains(nextIndex) else { return nil }
        return visibleSteps[nextIndex]
    }

    private func previousStep(before currentStep: Int) -> Int? {
        guard let currentIndex = visibleSteps.firstIndex(of: currentStep), currentIndex > 0 else { return nil }
        return visibleSteps[currentIndex - 1]
    }

    private func normalizeCurrentStepForTradition() {
        guard shouldSkipStandaloneThemes, step == 3 else { return }
        step = 4
    }
}

private struct ScreenTimeSetupPanel: View {
    let isAuthorized: Bool
    let hasSelection: Bool
    let authorizeAction: () -> Void
    let selectAppsAction: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(spacing: 0) {
                ScreenTimeStepBadge(
                    label: "1",
                    isComplete: isAuthorized,
                    isEnabled: true
                )

                Rectangle()
                    .fill(Color.sageButton.opacity(0.45))
                    .frame(width: 1, height: 62)
                    .overlay {
                        VStack(spacing: 7) {
                            ForEach(0..<5, id: \.self) { _ in
                                Circle()
                                    .fill(Color.deepInk.opacity(0.78))
                                    .frame(width: 3, height: 3)
                            }
                        }
                    }

                ScreenTimeStepBadge(
                    label: "2",
                    isComplete: hasSelection,
                    isEnabled: isAuthorized
                )
            }
            .padding(.top, 2)

            VStack(spacing: 22) {
                ScreenTimeSetupStep(
                    title: "1. Autorizar Tempo de Uso",
                    subtitle: "Permite que o Limiar crie pausas antes dos apps selecionados.",
                    buttonTitle: isAuthorized ? "Autorizado" : "Autorizar",
                    systemImage: isAuthorized ? "checkmark.shield.fill" : "checkmark.shield",
                    state: isAuthorized ? .completed : .available,
                    allowsCompletedAction: false,
                    action: authorizeAction
                )

                Divider()
                    .overlay(Color.white.opacity(0.10))

                ScreenTimeSetupStep(
                    title: "2. Escolher apps que ativam o Limiar",
                    subtitle: "Selecione apps ou categorias que vão acionar essa pausa.",
                    buttonTitle: !isAuthorized ? "Disponível após a autorização" : (hasSelection ? "Apps escolhidos" : "Escolher apps"),
                    systemImage: !isAuthorized ? "hourglass" : (hasSelection ? "checkmark.circle" : "square.grid.2x2"),
                    state: appSelectionState,
                    allowsCompletedAction: true,
                    action: selectAppsAction
                )
            }
        }
        .padding(18)
        .limiarPanel()
    }

    private var appSelectionState: ScreenTimeStepActionState {
        if !isAuthorized { return .disabled }
        return hasSelection ? .completed : .available
    }
}

private enum ScreenTimeStepActionState {
    case available
    case disabled
    case completed
}

private struct ScreenTimeStepBadge: View {
    let label: String
    let isComplete: Bool
    let isEnabled: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(isEnabled ? Color.sageButton.opacity(0.82) : Color.softText.opacity(0.34), lineWidth: 2)
                .frame(width: 54, height: 54)

            if isComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: 25, weight: .medium))
                    .foregroundStyle(Color.sageButton)
            } else {
                Text(label)
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(isEnabled ? Color.sageButton : Color.softText.opacity(0.70))
            }
        }
    }
}

private struct ScreenTimeSetupStep: View {
    let title: String
    let subtitle: String
    let buttonTitle: String
    let systemImage: String
    let state: ScreenTimeStepActionState
    let allowsCompletedAction: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(titleForeground)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(subtitleForeground)
                .lineSpacing(4)

            Button(action: action) {
                Label(buttonTitle, systemImage: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(buttonBackground, in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(buttonForeground)
            }
            .disabled(!isInteractive)
            .accessibilityLabel(buttonTitle)
        }
    }

    private var isInteractive: Bool {
        switch state {
        case .available:
            true
        case .disabled:
            false
        case .completed:
            allowsCompletedAction
        }
    }

    private var titleForeground: Color {
        switch state {
        case .available, .completed:
            Color.ivory
        case .disabled:
            Color.ivory.opacity(0.72)
        }
    }

    private var subtitleForeground: Color {
        switch state {
        case .available:
            Color.softText
        case .disabled, .completed:
            Color.softText.opacity(0.78)
        }
    }

    private var buttonBackground: Color {
        switch state {
        case .available:
            Color.sageButton
        case .disabled:
            Color.white.opacity(0.10)
        case .completed:
            Color.white.opacity(0.12)
        }
    }

    private var buttonForeground: Color {
        switch state {
        case .available:
            Color.deepInk
        case .disabled:
            Color.softText.opacity(0.68)
        case .completed:
            Color.softText.opacity(0.82)
        }
    }
}

private struct BlockedSelectionHierarchySummary: View {
    let selection: FamilyActivitySelection

    private var categoryTokens: [ActivityCategoryToken] {
        Array(selection.categoryTokens).sorted { "\($0)" < "\($1)" }
    }

    private var applicationTokens: [ApplicationToken] {
        Array(selection.applicationTokens).sorted { "\($0)" < "\($1)" }
    }

    private var webDomainTokens: [WebDomainToken] {
        Array(selection.webDomainTokens).sorted { "\($0)" < "\($1)" }
    }

    private var totalCount: Int {
        categoryTokens.count + applicationTokens.count + webDomainTokens.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("SELEÇÃO ATUAL")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.3)
                    .foregroundStyle(Color.warmGold)

                Text(selectionCountText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.softText.opacity(0.78))
            }

            VStack(alignment: .leading, spacing: 14) {
                if !categoryTokens.isEmpty {
                    BlockedSelectionGroup(
                        title: categoryTokens.count == 1 ? "Categoria selecionada" : "Categorias selecionadas",
                        subtitle: categoryTokens.count == 1 ? "Todos os apps desta categoria vão acionar a pausa." : "Todos os apps dessas categorias vão acionar a pausa.",
                        itemCount: categoryTokens.count,
                        systemImage: "square.stack.3d.up.fill"
                    ) {
                        ForEach(Array(categoryTokens.enumerated()), id: \.element) { index, token in
                            TokenChildRow(isLast: index == categoryTokens.count - 1) {
                                Label(token)
                            }
                        }
                    }
                }

                if !applicationTokens.isEmpty {
                    BlockedSelectionGroup(
                        title: applicationTokens.count == 1 ? "App escolhido" : "Apps escolhidos",
                        subtitle: "Selecionados individualmente no Tempo de Uso.",
                        itemCount: applicationTokens.count,
                        systemImage: "app.badge.fill",
                        showsChildConnectors: false
                    ) {
                        ForEach(Array(applicationTokens.enumerated()), id: \.element) { index, token in
                            TokenChildRow(
                                isLast: index == applicationTokens.count - 1,
                                showsConnector: false
                            ) {
                                Label(token)
                            }
                        }
                    }
                }

                if !webDomainTokens.isEmpty {
                    BlockedSelectionGroup(
                        title: webDomainTokens.count == 1 ? "Site selecionado" : "Sites selecionados",
                        subtitle: "Domínios selecionados no Tempo de Uso.",
                        itemCount: webDomainTokens.count,
                        systemImage: "globe"
                    ) {
                        ForEach(Array(webDomainTokens.enumerated()), id: \.element) { index, token in
                            TokenChildRow(isLast: index == webDomainTokens.count - 1) {
                                Label(token)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.deepInk.opacity(0.40), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.sageButton.opacity(0.18), lineWidth: 1)
        )
    }

    private var selectionCountText: String {
        totalCount == 1 ? "1 item" : "\(totalCount) itens"
    }
}

private struct BlockedSelectionGroup<Content: View>: View {
    let title: String
    let subtitle: String
    let itemCount: Int
    let systemImage: String
    var showsChildConnectors = true
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.sageButton)
                    .frame(width: 30, height: 30)
                    .background(Color.sageButton.opacity(0.13), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.ivory)

                        Text(countText)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.softText.opacity(0.68))
                    }

                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.softText.opacity(0.74))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.up")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.sageButton.opacity(0.80))
            }
            .padding(12)
            .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )

            if showsChildConnectors {
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.sageButton.opacity(0.28))
                            .frame(width: 1.2)
                    }
                    .frame(width: 16)
                    .padding(.leading, 4)

                    childRows
                }
                .padding(.leading, 22)
            } else {
                childRows
            }
        }
    }

    private var childRows: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .padding(10)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }

    private var countText: String {
        itemCount == 1 ? "· 1 item" : "· \(itemCount) itens"
    }
}

private struct TokenChildRow<Content: View>: View {
    let isLast: Bool
    var showsConnector = true
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: showsConnector ? 8 : 0) {
            if showsConnector {
                BranchConnector(isLast: isLast)
                    .frame(width: 18, height: 38)
            }

            content
                .font(.system(size: 14, weight: .semibold))
                .labelStyle(.titleAndIcon)
                .foregroundStyle(Color.ivory.opacity(0.92))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.deepInk.opacity(0.24), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

private struct BranchConnector: View {
    let isLast: Bool

    var body: some View {
        GeometryReader { proxy in
            let midY = proxy.size.height / 2

            Path { path in
                path.move(to: CGPoint(x: 8, y: 0))
                path.addLine(to: CGPoint(x: 8, y: isLast ? midY : proxy.size.height))
                path.move(to: CGPoint(x: 8, y: midY))
                path.addLine(to: CGPoint(x: proxy.size.width, y: midY))
            }
            .stroke(Color.sageButton.opacity(0.26), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
        }
    }
}

struct SettingsView: View {
    @Environment(LimiarAppModel.self) private var model
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(\.openURL) private var openURL
    @State private var showingPicker = false
    @State private var showingPaywall = false

    private let subscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!
    private let termsURL = URL(string: "https://limiar-five.vercel.app/terms.html")!
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
                    LabeledContent("Período após a leitura") {
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
                    Picker("Tradição", selection: $model.faithProfile.tradition) {
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
                    NavigationLink("Livros, temas e seções") {
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

                    if !subscription.hasActiveSubscription {
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
                        Button("Reiniciar teste gratuito de 7 dias") {
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
        .onChange(of: model.faithProfile.tradition) { _, newValue in
            model.selectTradition(newValue)
        }
        .onChange(of: model.faithProfile) { _, _ in model.saveProfile() }
        .familyActivityPicker(isPresented: $showingPicker, selection: $model.selection)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
                .environment(subscription)
        }
    }

    private var subscriptionStatusLabel: String {
        switch subscription.accessState {
        case .trialNotStarted:
            return "Teste não iniciado"
        case .trialActive:
            return "Teste ativo"
        case .trialExpired:
            return "Teste encerrado"
        case .subscribed:
            return "Assinatura ativa"
        }
    }
}

private struct BiblicalPreferencesView: View {
    @Environment(LimiarAppModel.self) private var model

    var body: some View {
        @Bindable var model = model

        List {
            Section {
                Text("Estas escolhas orientam as leituras e reflexões geradas pelo Limiar.")
                    .foregroundStyle(.secondary)
            }

            ForEach(model.faithProfile.tradition.readingPreferenceSections) { section in
                Section {
                    ForEach(section.options) { option in
                        Toggle(option.title, isOn: binding(for: option))
                    }
                } header: {
                    Text(section.title)
                } footer: {
                    if let subtitle = section.subtitle {
                        Text(subtitle)
                    }
                }
            }
        }
        .navigationTitle("Textos e temas")
        .scrollContentBackground(.hidden)
        .background(LimiarBackground())
        .tint(Color.sageButton)
        .onDisappear {
            model.faithProfile.normalizeReadingPreferencesForTradition()
            model.saveProfile()
            model.beginNewReading()
        }
    }

    private func binding(for option: ReadingPreferenceOption) -> Binding<Bool> {
        Binding {
            model.faithProfile.contains(option)
        } set: { isSelected in
            let currentlySelected = model.faithProfile.contains(option)
            guard isSelected != currentlySelected else { return }
            model.toggleReadingPreference(option)
            if model.faithProfile.hasSelectedReadingPreferences == false,
               let fallback = model.faithProfile.tradition.allowedReadingPreferenceOptions.first {
                model.toggleReadingPreference(fallback)
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

struct LimiarBackground: View {
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let action: () -> Void

    @State private var showLight = false
    @State private var showLogo = false
    @State private var showWelcome = false
    @State private var showTitle = false
    @State private var visibleBodyLineCount = 0
    @State private var showButton = false
    @State private var backgroundZoom = false
    @State private var logoBreathing = false
    @State private var didStartEntrance = false

    private let bodyLines = [
        "Antes de voltar às distrações,",
        "reserve alguns minutos",
        "para uma",
        "leitura que fortaleça sua fé."
    ]

    var body: some View {
        GeometryReader { proxy in
            let horizontalInset: CGFloat = 28
            let contentWidth = max(proxy.size.width - (horizontalInset * 2), 1)

            ZStack {
                LimiarBackground()
                    .scaleEffect(reduceMotion ? 1 : (backgroundZoom ? 1.03 : 1))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 8), value: backgroundZoom)
                    .overlay {
                        Rectangle()
                            .fill(Color.deepInk.opacity(showLight ? 0.03 : 0.28))
                            .ignoresSafeArea()
                    }
                    .overlay(alignment: .trailing) {
                        RadialGradient(
                            colors: [
                                Color.warmGold.opacity(showLight ? 0.18 : 0.04),
                                Color.clear
                            ],
                            center: .trailing,
                            startRadius: 18,
                            endRadius: proxy.size.width * 0.72
                        )
                        .blur(radius: 18)
                        .ignoresSafeArea()
                    }

                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                        .frame(height: proxy.size.height * 0.24)

                    Image("LimiarLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 84, height: 84, alignment: .leading)
                        .opacity(showLogo ? 1 : 0)
                        .scaleEffect(showLogo ? (logoBreathing && !reduceMotion ? 1.015 : 1) : 0.95)

                    Text("B E M - V I N D O")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.warmGold)
                        .padding(.top, 14)
                        .opacity(showWelcome ? 1 : 0)

                    Text("Limiar")
                        .font(.system(size: 76, weight: .regular, design: .serif))
                        .foregroundStyle(Color.ivory)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .padding(.top, 16)
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: reduceMotion ? 0 : (showTitle ? 0 : 12))

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(bodyLines.enumerated()), id: \.offset) { index, line in
                            Text(line)
                                .font(.system(size: 27, weight: .regular))
                                .foregroundStyle(Color.softText)
                                .opacity(visibleBodyLineCount > index ? 1 : 0)
                                .offset(y: reduceMotion ? 0 : (visibleBodyLineCount > index ? 0 : 8))
                        }
                    }
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
                    .opacity(showButton ? 1 : 0)
                    .offset(y: reduceMotion ? 0 : (showButton ? 0 : 10))
                }
                .frame(width: contentWidth, alignment: .leading)
                .padding(.horizontal, horizontalInset)
                .ignoresSafeArea(edges: .top)
            }
            .clipped()
        }
        .onAppear(perform: startEntranceAnimation)
    }

    private func startEntranceAnimation() {
        guard !didStartEntrance else { return }
        didStartEntrance = true

        if reduceMotion || UIAccessibility.isReduceMotionEnabled {
            withAnimation(.easeOut(duration: 0.45)) {
                showLight = true
                showLogo = true
                showWelcome = true
                showTitle = true
                visibleBodyLineCount = bodyLines.count
                showButton = true
            }
            return
        }

        backgroundZoom = true

        withAnimation(.easeInOut(duration: 2.6)) {
            showLight = true
        }

        animate(after: 0.65, duration: 0.72) {
            showLogo = true
        }
        animate(after: 1.18, duration: 0.62) {
            showWelcome = true
        }
        animate(after: 1.68, duration: 0.72) {
            showTitle = true
        }

        for index in bodyLines.indices {
            animate(after: 2.14 + (Double(index) * 0.22), duration: 0.58) {
                visibleBodyLineCount = index + 1
            }
        }

        animate(after: 3.25, duration: 0.72) {
            showButton = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.85) {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                logoBreathing = true
            }
        }
    }

    private func animate(after delay: TimeInterval, duration: TimeInterval, changes: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeOut(duration: duration)) {
                changes()
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
                .font(.system(size: 34, weight: .regular, design: .serif))
                .foregroundStyle(Color.ivory)
                .lineSpacing(4)
                .lineLimit(3)
                .minimumScaleFactor(0.86)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.softText)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
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
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(selected.contains(item) ? Color.sageButton.opacity(0.30) : Color.white.opacity(0.08), in: Capsule())
                        .overlay(Capsule().stroke(selected.contains(item) ? Color.sageButton.opacity(0.95) : Color.white.opacity(0.16), lineWidth: selected.contains(item) ? 1.5 : 1))
                        .foregroundStyle(selected.contains(item) ? Color.sageButton : Color.ivory.opacity(0.92))
                }
            }
        }
    }
}

private struct ReadingPreferenceChipSection: View {
    let section: ReadingPreferenceSection
    let profile: UserFaithProfile
    let action: (ReadingPreferenceOption) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(section.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.ivory)

                if let subtitle = section.subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.softText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            FlowLayout(spacing: 9) {
                ForEach(section.options) { option in
                    let selected = profile.contains(option)
                    Button {
                        action(option)
                    } label: {
                        ReadingPreferenceChip(title: option.title, isSelected: selected)
                    }
                    .accessibilityLabel(option.title)
                    .accessibilityValue(selected ? "Selecionado" : "Não selecionado")
                }
            }
        }
        .padding(14)
        .background(Color.deepInk.opacity(0.26), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct ReadingPreferenceChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .background(backgroundColor, in: Capsule())
            .overlay(Capsule().stroke(borderColor, lineWidth: borderWidth))
            .foregroundStyle(foregroundColor)
    }

    private var backgroundColor: Color {
        isSelected ? Color.sageButton.opacity(0.30) : Color.deepInk.opacity(0.52)
    }

    private var borderColor: Color {
        isSelected ? Color.sageButton.opacity(0.96) : Color.white.opacity(0.18)
    }

    private var borderWidth: CGFloat {
        isSelected ? 1.5 : 1
    }

    private var foregroundColor: Color {
        isSelected ? Color.sageButton : Color.ivory.opacity(0.94)
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

    private var cleanedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        if !cleanedText.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(Color.gold)
                Text(cleanedText)
                    .font(.system(size: 17))
                    .foregroundStyle(Color.softText)
                    .lineSpacing(5)
            }
            .padding(16)
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
        }
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
private final class PassageNarrationService: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isSpeaking = false

    private let speechService = RemoteAISpeechService()
    private var player: AVAudioPlayer?
    private var playbackTask: Task<Void, Never>?
    private var activeSpeechText = ""

    func toggle(text: String) {
        if isSpeaking, activeSpeechText == preparedSpeechText(text) {
            stop()
        } else {
            speak(text)
        }
    }

    func stop() {
        playbackTask?.cancel()
        playbackTask = nil
        player?.stop()
        player = nil
        activeSpeechText = ""
        isSpeaking = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func speak(_ text: String) {
        stop()

        let prepared = preparedSpeechText(text)
        guard !prepared.isEmpty else { return }
        activeSpeechText = prepared
        isSpeaking = true
        let service = speechService

        playbackTask = Task { [weak self] in
            do {
                let audio = try await service.audioData(for: prepared)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self?.play(audio)
                }
            } catch {
                await MainActor.run {
                    self?.activeSpeechText = ""
                    self?.isSpeaking = false
                }
            }
        }
    }

    private func play(_ data: Data) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)

            let audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
            player = audioPlayer
            audioPlayer.play()
        } catch {
            activeSpeechText = ""
            isSpeaking = false
        }
    }

    private func preparedSpeechText(_ text: String) -> String {
        var prepared = text
            .replacingOccurrences(of: "APPs", with: "aplicativos")
            .replacingOccurrences(of: "apps", with: "aplicativos")
            .replacingOccurrences(of: "IA", with: "inteligência artificial")
            .replacingOccurrences(of: " / ", with: ", ")
            .replacingOccurrences(of: "—", with: ", ")
            .replacingOccurrences(of: "–", with: ", ")
            .replacingOccurrences(of: "###", with: "")
            .replacingOccurrences(of: "```", with: "")
            .replacingOccurrences(of: "`", with: "")
            .replacingOccurrences(of: "{", with: "")
            .replacingOccurrences(of: "}", with: "")
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "“", with: "")
            .replacingOccurrences(of: "”", with: "")

        prepared = prepared.replacingOccurrences(
            of: #"(?m)^\s*[-•]\s*"#,
            with: "",
            options: .regularExpression
        )
        prepared = prepared.replacingOccurrences(
            of: #"(?m)^\s*#{1,6}\s*"#,
            with: "",
            options: .regularExpression
        )
        prepared = prepared.replacingOccurrences(
            of: #""[A-Za-z0-9_]+":\s*"#,
            with: "",
            options: .regularExpression
        )
        prepared = prepared.replacingOccurrences(
            of: #"\b[a-zA-Z]+_[a-zA-Z0-9_]+\b"#,
            with: "",
            options: .regularExpression
        )
        prepared = prepared.replacingOccurrences(
            of: #"(?m)^[ \t]+"#,
            with: "",
            options: .regularExpression
        )
        prepared = prepared.replacingOccurrences(
            of: #"\n{3,}"#,
            with: "\n\n",
            options: .regularExpression
        )
        prepared = prepared.replacingOccurrences(
            of: #"([.!?])\s+"#,
            with: "$1\n\n",
            options: .regularExpression
        )
        return prepared.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            self?.activeSpeechText = ""
            self?.isSpeaking = false
            self?.player = nil
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor [weak self] in
            self?.player = nil
            self?.activeSpeechText = ""
            self?.isSpeaking = false
        }
    }

    deinit {
        playbackTask?.cancel()
        player?.stop()
        activeSpeechText = ""
    }
}

private struct LimiarPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 22, weight: .regular, design: .serif))
            .padding(.horizontal, 12)
            .frame(width: 148, height: 58)
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

extension View {
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

extension Color {
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
