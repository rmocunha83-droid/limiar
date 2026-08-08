@preconcurrency import AVFoundation
import FamilyControls
import ManagedSettings
import SwiftUI

func narrationExplanationSegments(_ parts: [String]) -> [String] {
    parts.flatMap { part in
        part
            .replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

struct ContentView: View {
    @Environment(LimiarAppModel.self) private var model
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(LimiarNotificationCoordinator.self) private var notifications
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(
        ConversionFunnelPersistence.d6DismissedKey,
        store: UserDefaults(suiteName: ScreenTimePolicyStore.appGroupIdentifier) ?? .standard
    ) private var dismissedTrialConversion = false
    @AppStorage(
        ConversionFunnelPersistence.d7DismissedKey,
        store: UserDefaults(suiteName: ScreenTimePolicyStore.appGroupIdentifier) ?? .standard
    ) private var dismissedEssentialModeIntro = false
    @AppStorage(
        ConversionFunnelPersistence.d8DismissedKey,
        store: UserDefaults(suiteName: ScreenTimePolicyStore.appGroupIdentifier) ?? .standard
    ) private var dismissedPostTrialPaywall = false
    @State private var presentedFunnelInterstitialThisSession = false
    @State private var attemptedNextCyclePrewarmThisForeground = false

    private static var forcePaywallForReviewScreenshot: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-LimiarForcePaywall")
        #else
        false
        #endif
    }

    private static var forceEssentialModeForDebugging: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-LimiarForceEssential")
        #else
        false
        #endif
    }

    private static var forceFreeTrialStartForDebugging: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-LimiarForceFreeTrialStart")
        #else
        false
        #endif
    }

    private static var forceSubscriptionGateForDebugging: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-LimiarForceSubscriptionGate")
        #else
        false
        #endif
    }

    private static var forceCompletionScreenForDebugging: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-LimiarForceCompletionScreen")
        #else
        false
        #endif
    }

    private static var forceLocalSessionForDebugging: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-LimiarForceLocalSession")
        #else
        false
        #endif
    }

    private var effectiveHasPremiumAccess: Bool {
        if Self.forceLocalSessionForDebugging { return true }
        return Self.forceEssentialModeForDebugging ? false : subscription.hasPremiumAccess
    }

    private var effectiveIsEssentialMode: Bool {
        Self.forceEssentialModeForDebugging ? true : subscription.isEssentialMode
    }

    private static var forcedConversionScreen: String? {
        #if DEBUG
        guard let index = ProcessInfo.processInfo.arguments.firstIndex(of: "-LimiarConversionScreen"),
              ProcessInfo.processInfo.arguments.indices.contains(index + 1) else {
            return nil
        }
        return ProcessInfo.processInfo.arguments[index + 1]
        #else
        return nil
        #endif
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            Group {
                if Self.forceCompletionScreenForDebugging {
                    DashboardView()
                } else if Self.forceLocalSessionForDebugging {
                    DashboardView()
                } else if Self.forceSubscriptionGateForDebugging {
                    SubscriptionGateView()
                        .transition(onboardingForwardTransition)
                } else if Self.forceFreeTrialStartForDebugging {
                    FreeTrialStartView()
                } else if Self.forcedConversionScreen == "D6" {
                    TrialConversionView {}
                } else if Self.forcedConversionScreen == "D7" {
                    EssentialModeIntroView {}
                } else if Self.forcedConversionScreen == "D8" {
                    PaywallView(analyticsOrigin: .d8)
                } else if Self.forcePaywallForReviewScreenshot {
                    PaywallView()
                } else if Self.forceEssentialModeForDebugging {
                    DashboardView()
                } else if !model.hasCompletedOnboarding {
                    OnboardingView()
                        .transition(onboardingForwardTransition)
                } else if subscription.requiresSubscriptionGate {
                    SubscriptionGateView()
                        .transition(onboardingForwardTransition)
                } else if notifications.shieldBridgeRouteID != nil {
                    // O toque na ponte do shield é uma intenção explícita de
                    // atravessar. Para usuários com acesso ele entra direto no
                    // dashboard e não é interceptado pelo funil legado.
                    DashboardView()
                } else if subscription.cohort == .legacy,
                          subscription.accessState == .trialNotStarted {
                    FreeTrialStartView()
                } else if !presentedFunnelInterstitialThisSession,
                          subscription.shouldShowTrialConversion,
                          !dismissedTrialConversion {
                    TrialConversionView {
                        dismissedTrialConversion = true
                        presentedFunnelInterstitialThisSession = true
                    }
                } else if !presentedFunnelInterstitialThisSession,
                          subscription.shouldShowPostTrialPaywall,
                          !dismissedPostTrialPaywall {
                    PaywallView(analyticsOrigin: .d8) {
                        dismissedPostTrialPaywall = true
                        presentedFunnelInterstitialThisSession = true
                    }
                } else if !presentedFunnelInterstitialThisSession,
                          subscription.isEssentialMode,
                          !dismissedEssentialModeIntro {
                    EssentialModeIntroView {
                        dismissedEssentialModeIntro = true
                        presentedFunnelInterstitialThisSession = true
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
                notifications.handleAppDidBecomeActive()
                subscription.refreshAccessState()
                Task { await subscription.recoverIfNeeded() }
                model.updateAccess(
                    hasPremiumAccess: effectiveHasPremiumAccess,
                    isEssentialMode: effectiveIsEssentialMode
                )
                model.prepareFreshPassageForForeground()
                attemptNextCyclePrewarmForForeground()
            } else if phase == .background {
                attemptedNextCyclePrewarmThisForeground = false
                LimiarPrewarmCoordinator.shared.schedule()
            } else if phase == .inactive {
                // A próxima ativação (inclusive após interrupções do sistema)
                // recebe no máximo uma nova tentativa silenciosa.
                attemptedNextCyclePrewarmThisForeground = false
            }
        }
        .task {
            subscription.start()
            if model.hasCompletedOnboarding {
                MetaAppEvents.requestTrackingPermissionIfNeeded()
            }
            model.updateAccess(
                hasPremiumAccess: effectiveHasPremiumAccess,
                isEssentialMode: effectiveIsEssentialMode
            )
            syncAnalyticsUserProperties()
            if scenePhase == .active {
                attemptNextCyclePrewarmForForeground()
            }
        }
        .onChange(of: subscription.accessState) { _, _ in
            // A trava efêmera acima impede que outro interstício do funil seja
            // empilhado nesta abertura; flags persistentes só mudam no dismiss.
            model.updateAccess(
                hasPremiumAccess: effectiveHasPremiumAccess,
                isEssentialMode: effectiveIsEssentialMode
            )
            syncAnalyticsUserProperties()
        }
        .onChange(of: model.faithProfile) { _, _ in
            syncAnalyticsUserProperties()
        }
    }

    private var onboardingForwardTransition: AnyTransition {
        OnboardingPageMotion.transition(
            direction: .forward,
            reduceMotion: reduceMotion
        )
    }

    private func attemptNextCyclePrewarmForForeground() {
        guard !attemptedNextCyclePrewarmThisForeground else { return }
        attemptedNextCyclePrewarmThisForeground = true
        model.prewarmNextCycleFromForeground()
    }

    private func syncAnalyticsUserProperties() {
        LimiarAnalytics.syncUserProperties(
            profile: model.faithProfile,
            cohort: subscription.cohort,
            access: subscription.analyticsAccess
        )
    }
}

private struct DashboardView: View {
    @Environment(LimiarAppModel.self) private var model
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(\.requestReview) private var requestReview
    @StateObject private var narration = PassageNarrationService()
    @State private var showingPicker = false
    @State private var showingSettings = false
    @State private var showingPaywall = false
    @State private var showingCompletionScreen = false

    private static var forceCompletionScreenForDebugging: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-LimiarForceCompletionScreen")
        #else
        false
        #endif
    }

    private static var forceEssentialBannerScreenshot: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-LimiarEssentialBannerScreenshot")
        #else
        false
        #endif
    }

    private static var forceEssentialMiddleScreenshot: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-LimiarEssentialMiddleScreenshot")
        #else
        false
        #endif
    }

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
                                ProfileAvatarView(
                                    store: model.profileImageStore,
                                    size: 46
                                )
                            }
                            .accessibilityLabel("Abrir perfil")
                        }

                        blockedAppsStrip
                        trialStatusBadge
                        readingRequirementHeader
                        essentialModeNotice
                        readingItemsList
                        if model.showsAds {
                            LimiarMRECAdSlot()
                                .id("essentialMREC")
                        }
                        chooseAppsButton
                        completionExplanation
                        unlockButton
                        footer
                    }
                    .padding(.horizontal, 24)
                    .containerRelativeFrame(.horizontal, alignment: .leading)
                    .padding(.top, 58)
                    .padding(.bottom, 30)
                }
                .onAppear {
                    proxy.scrollTo("readingTop", anchor: .top)
                    if Self.forceCompletionScreenForDebugging {
                        showingCompletionScreen = true
                    }
                }
                .task {
                    guard Self.forceEssentialBannerScreenshot || Self.forceEssentialMiddleScreenshot else { return }
                    if Self.forceEssentialBannerScreenshot {
                        // O MREC pode levar mais tempo para responder no primeiro
                        // boot de um simulador novo; a espera existe apenas no
                        // caminho DEBUG usado pelas capturas automatizadas.
                        try? await Task.sleep(for: .seconds(24))
                        proxy.scrollTo("essentialMREC", anchor: .center)
                    } else {
                        try? await Task.sleep(for: .seconds(7))
                        proxy.scrollTo("essentialMiddle", anchor: .center)
                    }
                }
                .onChange(of: model.readingTopResetID) { _, _ in
                    showingCompletionScreen = false
                    withAnimation(.easeOut(duration: 0.28)) {
                        proxy.scrollTo("readingTop", anchor: .top)
                    }
                }
            }

            if showingCompletionScreen {
                completionScreen
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if model.showsAds && !showingCompletionScreen {
                // O safeAreaInset mantem o anuncio fixo e reduz a area rolavel
                // pela altura real do slot. Assim o CTA nunca fica encoberto.
                LimiarAnchoredAdSlot()
                    .background(Color.deepInk.opacity(0.98))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationDestination(isPresented: $showingSettings) {
            SettingsView()
        }
        .navigationDestination(isPresented: $showingPaywall) {
            PaywallView()
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
            LimiarAnalytics.trackTraversalStarted(
                turn: model.pauseCycleTurn,
                cycleKey: ScreenTimePolicyStore.cycleDayKey(
                    hour: model.pauseCycleTurn.rawValue
                )
            )
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

                    Text("Acesso inicial: \(subscription.trialRemainingText)")
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
                    let categoryTokens = Array(model.selection.categoryTokens)
                        .sorted { "\($0)" < "\($1)" }
                    let applicationTokens = Array(model.selection.applicationTokens)
                        .sorted { "\($0)" < "\($1)" }
                    let webDomainTokens = Array(model.selection.webDomainTokens)
                        .sorted { "\($0)" < "\($1)" }

                    if categoryTokens.isEmpty,
                       applicationTokens.isEmpty,
                       webDomainTokens.isEmpty {
                        BlockedAppsPlaceholderIcon()
                    } else {
                        ForEach(categoryTokens, id: \.self) { token in
                            BlockedCategoryIcon(token: token)
                        }

                        ForEach(applicationTokens, id: \.self) { token in
                            BlockedApplicationIcon(token: token)
                        }

                        ForEach(webDomainTokens, id: \.self) { token in
                            BlockedWebDomainIcon(token: token)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(18)
        .limiarPanel()
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            showingPicker = true
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Toque para ajustar os apps que ativam o Limiar.")
        .accessibilityAction {
            showingPicker = true
        }
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
            if model.isPreparingReadingContent {
                AIReadingPreparationView()
            } else if model.aiContentState == .fallback && model.currentSpiritualReadingItems.isEmpty {
                AIReadingRetryView {
                    model.retryReadingGeneration()
                }
            } else {
                if model.aiContentState == .localSession {
                    AIReadingLocalSessionNotice(
                        isRetrying: model.isRetryingLocalSession,
                        retry: model.retryReadingGeneration
                    )
                }

                ForEach(Array(model.currentSpiritualReadingItems.enumerated()), id: \.element.id) { index, item in
                    let narrationSegments = [
                        canonicalPassageNarrationText(reference: item.reference, text: item.text)
                    ] + narrationExplanationSegments([item.homily, item.practicalConclusion])

                    SpiritualReadingCard(
                        item: item,
                        isSaved: model.isFavorite(item),
                        saveAction: {
                            // No Essencial o toque SEMPRE abre o paywall — sem
                            // depender de canShowPaywall (que só liga no dia
                            // seguinte ao fim do trial). Nunca muta favoritos.
                            if model.isEssentialMode {
                                showingPaywall = true
                            } else {
                                model.toggleFavorite(item)
                            }
                        },
                        listenAction: {
                            if model.isEssentialMode {
                                showingPaywall = true
                            } else {
                                narration.toggle(segments: narrationSegments)
                            }
                        },
                        narrationState: model.isEssentialMode ? .idle : narration.state(for: narrationSegments),
                        showsReflection: (model.hasPremiumAccess || model.isEssentialMode) && item.hasExplanationContent,
                        showsNarration: model.canNarrateCurrentReading || model.isEssentialMode,
                        isSaveLocked: model.isEssentialMode,
                        isNarrationLocked: model.isEssentialMode
                    )
                    .id(index == 1 ? "essentialMiddle" : "reading-\(item.id)")

                }

                if model.hasPremiumAccess && model.hasVisibleReflection {
                    reflectionSection
                } else if model.isEssentialMode,
                          !model.currentReflection.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    essentialReflectionTeaser
                }
            }
        }
    }

    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if model.currentSpiritualReadingItems.count > 1 {
                Label("Reflexão breve", systemImage: "sparkle")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Color.warmGold)
                    .padding(.top, 4)
                ReadingBlock(title: "Entenda o significado", text: model.currentReflection.summary)
            }
            ReadingBlock(title: "Sentido espiritual", text: model.currentReflection.spiritualMeaning)
                .padding(.top, model.currentSpiritualReadingItems.count == 1 ? 4 : 0)
            ReadingBlock(title: "Para levar para o dia", text: model.currentReflection.practicalApplication)
            ReadingBlock(title: "Pergunta para refletir", text: model.currentReflection.meditationQuestion)
        }
    }

    private var essentialReflectionTeaser: some View {
        Button {
            showingPaywall = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Label("Reflexão breve", systemImage: "lock.fill")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Color.warmGold)
                Text(model.currentReflection.summary)
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .foregroundStyle(Color.ivory.opacity(0.58))
                    .lineLimit(1)
                    .blur(radius: 3)
                    .mask(LinearGradient(colors: [.black, .black.opacity(0.35), .clear], startPoint: .leading, endPoint: .trailing))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .limiarPanel()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Reflexão breve bloqueada. Abrir Limiar completo")
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

                    Text("Você está lendo os trechos principais com explicações essenciais. Narração, maior variedade e experiência sem anúncios ficam no Limiar completo.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.softText)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if model.isEssentialMode {
                        NavigationLink {
                            PaywallView()
                        } label: {
                            Text("Ver planos")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.sageButton)
                        }
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.sageButton.opacity(0.18), lineWidth: 1)
                )
                .frame(maxWidth: .infinity, alignment: .leading)
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
                    Text("Editar apps da pausa")
                        .font(.system(size: 19, weight: .regular, design: .serif))
                        .foregroundStyle(Color.ivory)
                    Text("Escolha quais apps vão abrir com a pausa do Limiar.")
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
        Text("Após concluir a leitura, os apps selecionados ficarão disponíveis até o próximo ciclo.")
            .font(.system(size: 14))
            .foregroundStyle(Color.softText)
            .lineSpacing(5)
            .padding(.horizontal, 2)
    }

    private var unlockButton: some View {
        Button {
            completeReading()
        } label: {
            HStack(spacing: 18) {
                Image(systemName: "sunrise.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.deepInk.opacity(0.70))
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Despausar apps, continuar")
                        .font(.system(size: 22, weight: .regular, design: .serif))
                        .foregroundStyle(Color.deepInk)
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(Color.deepInk)
            }
            .padding(.horizontal, 34)
            .frame(height: 104)
            .background(Color.sageButton, in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.ivory.opacity(0.26), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.20), radius: 8, x: 0, y: 10)
        }
        .disabled(showingCompletionScreen)
        .accessibilityLabel("Despausar apps, continuar")
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

    private var completionScreen: some View {
        let presentation = completionPresentation

        return ZStack {
            LimiarBackground()

            VStack(spacing: 24) {
                Spacer()

                ZStack(alignment: .topTrailing) {
                    Image(systemName: presentation.iconName)
                        .font(.system(size: 46, weight: .regular))
                        .foregroundStyle(Color.warmGold)
                        .symbolEffect(.bounce, value: showingCompletionScreen)

                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.deepInk)
                        .frame(width: 22, height: 22)
                        .background(Color.sageButton, in: Circle())
                        .overlay(Circle().stroke(Color.ivory.opacity(0.35), lineWidth: 1))
                        .offset(x: 10, y: -7)
                        .accessibilityHidden(true)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Travessia concluída no turno da \(presentation.turn.title.lowercased())")

                Text("Travessia concluída")
                    .font(.system(size: 40, weight: .regular, design: .serif))
                    .foregroundStyle(Color.ivory)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    Text("Seus apps estão liberados até o próximo ciclo, \(presentation.nextCycleReference).")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.ivory)

                    Text("Pode fechar o Limiar e seguir seu dia. Leve a leitura de hoje com você.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color.softText)
                }
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.horizontal, 36)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showingCompletionScreen = false
                    }
                } label: {
                    Text("Permanecer no Limiar")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.sageButton)
                }
                .accessibilityHint("Fecha a tela de conclusão e volta para a leitura")
                .padding(.bottom, 44)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    private var completionPresentation: CompletionScreenPresentation {
        let now = Date()
        let calendar = ScreenTimePolicyStore.cycleCalendar
        let turn = debugCompletionTurn ?? model.pauseCycleTurn
        let nextCycleStart: Date

        if let debugTiming = debugCompletionTiming {
            let dayOffset = debugTiming == "today" ? 0 : 1
            let day = calendar.date(byAdding: .day, value: dayOffset, to: now) ?? now
            nextCycleStart = calendar.date(
                bySettingHour: turn.rawValue,
                minute: 0,
                second: 0,
                of: day
            ) ?? day
        } else {
            nextCycleStart = ScreenTimePolicyStore.nextCycleStart(after: now, calendar: calendar)
        }

        return CompletionScreenPresentation(
            turn: turn,
            now: now,
            nextCycleStart: nextCycleStart,
            calendar: calendar
        )
    }

    private var debugCompletionTurn: PauseCycleTurn? {
        #if DEBUG
        guard let value = Self.debugArgument(after: "-LimiarCompletionTurn") else { return nil }
        switch value {
        case "morning": return .morning
        case "afternoon": return .afternoon
        case "evening": return .evening
        default: return nil
        }
        #else
        return nil
        #endif
    }

    private var debugCompletionTiming: String? {
        #if DEBUG
        Self.debugArgument(after: "-LimiarCompletionTiming")
        #else
        nil
        #endif
    }

    private static func debugArgument(after flag: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: flag),
              arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }

    private func completeReading() {
        guard !showingCompletionScreen else { return }

        narration.stop()
        model.finishReading()
        requestTrackingPermissionAfterCompletion()
        requestReviewIfEligibleAfterCompletion()

        withAnimation(.easeInOut(duration: 0.8)) {
            showingCompletionScreen = true
        }
    }

    /// Pede a permissão de rastreamento na travessia concluída — o momento de
    /// maior boa vontade, quando a pessoa acabou de receber o que veio buscar
    /// e vê os apps liberados. O alerta do sistema só aparece uma vez por
    /// instalação, então esta é a única chance de perguntar; oferecê-la aqui,
    /// e não numa abertura futura, alcança também quem instala pelo anúncio e
    /// não volta no dia seguinte.
    private func requestTrackingPermissionAfterCompletion() {
        // Espera o encerramento visual da travessia (0.8s de animação) para o
        // alerta não subir por cima da transição.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            MetaAppEvents.requestTrackingPermissionIfNeeded()
        }
    }

    private func requestReviewIfEligibleAfterCompletion() {
        let history = model.history
        let readingWasHealthy = model.aiContentState != .fallback && model.aiContentState != .localSession

        // Aguarda o encerramento visual da travessia para não interromper a
        // ação de concluir a leitura. Quando o alerta de rastreamento ainda
        // está pendente, ele tem a vez: só aparece uma vez por instalação,
        // enquanto o pedido de avaliação volta a ficar elegível em outra
        // travessia. Sem essa folga o iOS descartaria um dos dois.
        let delay: TimeInterval = MetaAppEvents.isTrackingPromptPending ? 12.0 : 3.0

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard !MetaAppEvents.isTrackingPromptPending else { return }
            guard subscription.claimReviewRequestIfEligible(
                history: history,
                readingWasHealthy: readingWasHealthy
            ) else {
                return
            }

            requestReview()
        }
    }
}
