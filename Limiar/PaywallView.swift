import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    // Sem valor padrão de propósito: cada tela de oferta declara sua origem,
    // senão o funil mistura origens silenciosamente (foi assim que o D7
    // passou a contar em dobro).
    let analyticsOrigin: LimiarAnalytics.PaywallOrigin
    var continueEssential: (() -> Void)? = nil

    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private let privacyURL = URL(string: "https://applimiar.com.br/privacy")!

    var body: some View {
        @Bindable var subscription = subscription

        ZStack {
            LimiarBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    ConversionHeader(
                        eyebrow: "LIMIAR PREMIUM",
                        title: "Quero voltar a ser premium",
                        subtitle: nil
                    )

                    ConversionLossBlock(
                        title: "No plano essencial, você está sem:",
                        finalItem: "Pausa limpa — anúncios nos trechos e no dashboard"
                    )

                    ConversionTestimonials(startingIndex: 1)

                    ConversionPlanPicker(selection: $subscription.selectedPlan)

                    ConversionPurchaseSection(
                        buttonTitle: "Voltar ao Limiar completo",
                        escapeTitle: "Continuar no Essencial",
                        analyticsOrigin: analyticsOrigin,
                        escapeAction: {
                            if let continueEssential {
                                continueEssential()
                            } else {
                                dismiss()
                            }
                        }
                    )

                    ConversionLegalLinks(termsURL: termsURL, privacyURL: privacyURL)
                }
                .padding(.horizontal, 30)
                .padding(.top, 52)
                .padding(.bottom, 30)
            }
        }
        .preferredColorScheme(.dark)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .task {
            MetaAppEvents.trackPaywallViewed()
            LimiarAnalytics.trackPaywallViewed(origin: analyticsOrigin)
            subscription.start()
            await subscription.prepareProductsIfNeeded()
        }
    }
}

struct SubscriptionGateView: View {
    @Environment(LimiarAppModel.self) private var model
    @Environment(SubscriptionManager.self) private var subscription

    private let termsURL = URL(string: "https://applimiar.com.br/terms")!
    private let privacyURL = URL(string: "https://applimiar.com.br/privacy")!

    private var forcesTrialEligibilityForDebugging: Bool {
#if DEBUG
        ProcessInfo.processInfo.arguments.contains("-LimiarGateTrialEligible")
#else
        false
#endif
    }

    var body: some View {
        @Bindable var subscription = subscription

        ZStack {
            LimiarBackground()

            if subscription.showsGateRecovery {
                SubscriptionGateRecoveryView(
                    termsURL: termsURL,
                    privacyURL: privacyURL,
                    forcesTrialEligibilityForDebugging: forcesTrialEligibilityForDebugging
                )
                .transition(.opacity)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 14) {
                            OnboardingTitle(eyebrow: "ÚLTIMO PASSO", title: gateTitle)
                            SubscriptionGateLead(showsEligibleTrial: showsEligibleTrial)
                        }

                        if showsRestoreFirstBanner {
                            SubscriptionGateVerifyingBanner()
                        }

                        if showsEligibleTrial {
                            SubscriptionGateTrialTimeline()
                        }

                        SubscriptionGatePlanPicker(
                            selection: $subscription.selectedPlan,
                            forcesTrialEligibilityForDebugging: forcesTrialEligibilityForDebugging
                        )

                        SubscriptionGatePurchaseSection(
                            forcesTrialEligibilityForDebugging: forcesTrialEligibilityForDebugging
                        )

                        SubscriptionGateSocialProof()

                        SubscriptionGateBenefits(
                            profile: model.faithProfile,
                            turn: model.pauseCycleTurn,
                            title: showsEligibleTrial
                                ? "Tudo incluído nos seus 7 dias grátis"
                                : "Tudo incluído na sua assinatura"
                        )

                        ConversionTestimonials(startingIndex: 0, usesSmoothTransition: true)

                        SubscriptionGateFooterLinks(
                            termsURL: termsURL,
                            privacyURL: privacyURL
                        )
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .padding(.bottom, 30)
                    .containerRelativeFrame(.horizontal)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: subscription.showsGateRecovery)
        .preferredColorScheme(.dark)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .task {
            MetaAppEvents.trackPaywallViewed()
            LimiarAnalytics.trackGateViewed(
                plan: subscription.selectedPlan,
                offerEligibility: subscription.introductoryOfferEligibility(
                    for: subscription.selectedPlan
                )
            )
            subscription.start()
            await subscription.prepareProductsIfNeeded()
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-LimiarForceGateRecovery") {
                subscription.forceGateRecoveryForDebugging()
            }
#endif
        }
    }

    /// O mesmo título para as duas situações: a tela é a última do onboarding
    /// e fala da travessia, não do "premium".
    private var gateTitle: String {
        "Tudo pronto para sua primeira travessia."
    }

    private var showsEligibleTrial: Bool {
        forcesTrialEligibilityForDebugging
            || subscription.hasEligibleFreeTrial(for: subscription.selectedPlan)
    }

    /// Quem já teve assinatura neste aparelho (marcador do Keychain) não deve
    /// abrir o portão direto como venda: primeiro verificamos a assinatura.
    private var showsRestoreFirstBanner: Bool {
        subscription.hadSubscriptionBefore
            && !subscription.hasActiveSubscription
            && subscription.isVerifyingInitialEntitlements
    }
}

/// O benefício do teste abre a oferta; a confirmação de cobrança zero vem
/// logo abaixo como resposta à principal objeção.
private struct SubscriptionGateLead: View {
    let showsEligibleTrial: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if showsEligibleTrial {
                Text("Teste tudo por 7 dias, grátis.")
                    .limiarFont(18, weight: .semibold, relativeTo: .headline)
                    .foregroundStyle(Color.ivory)
                Text("Você não paga nada hoje.")
                    .limiarFont(16, weight: .medium, relativeTo: .body)
                    .foregroundStyle(Color.softText)
            } else {
                Text("Escolha seu plano e entre no Limiar.")
                    .limiarFont(16, weight: .medium, relativeTo: .body)
                    .foregroundStyle(Color.softText)
            }
        }
        .lineSpacing(4)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// Hoje / dia 5 / dia 7: transparência sobre *quando* a cobrança acontece é o
/// que mais reduz o cancelamento na folha da App Store.
private struct SubscriptionGateTrialTimeline: View {
    private struct Step: Identifiable {
        let id: Int
        let symbol: String
        let day: String
        let text: String
    }

    private let steps = [
        Step(id: 0, symbol: "lock.open", day: "Hoje", text: "Acesso completo liberado"),
        Step(id: 1, symbol: "bell", day: "Dia 5", text: "Avisamos antes de qualquer cobrança"),
        Step(id: 2, symbol: "calendar", day: "Dia 7", text: "Assinatura começa. Cancele antes e não pague nada")
    ]

    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(Color.warmGold.opacity(0.45))
                .frame(width: 1)
                .padding(.vertical, 17)
                .offset(x: 16.5)

            VStack(alignment: .leading, spacing: 22) {
                ForEach(steps) { step in
                    HStack(alignment: .center, spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.deepInk)
                            Circle()
                                .stroke(Color.warmGold.opacity(0.8), lineWidth: 1.2)
                            Image(systemName: step.symbol)
                                .limiarFont(14, weight: .medium, relativeTo: .footnote)
                                .foregroundStyle(Color.warmGold)
                        }
                        .frame(width: 34, height: 34)

                        (Text(step.day).foregroundStyle(Color.ivory).fontWeight(.semibold)
                            + Text(" — ").foregroundStyle(Color.softText)
                            + Text(step.text).foregroundStyle(Color.softText))
                            .limiarFont(15, weight: .medium, relativeTo: .subheadline)
                            .lineSpacing(1)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct SubscriptionGateVerifyingBanner: View {
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
                .tint(Color.sageButton)
            Text("Verificando sua assinatura anterior... Se você já assinou, use \"Restaurar compras\" abaixo.")
                .conversionFont(13, weight: .medium, relativeTo: .footnote)
                .foregroundStyle(Color.ivory.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.conversionPanel, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.sageButton.opacity(0.4), lineWidth: 1))
    }
}

private struct SubscriptionGateBenefits: View {
    let profile: UserFaithProfile
    let turn: PauseCycleTurn
    let title: String

    private var benefits: [String] {
        [
            "Seus apps bloqueados até a pausa da \(turn.title.lowercased())",
            "Leituras na tradição \(profile.tradition.title.lowercased()), no seu ritmo: \(depthDescription)",
            "Narração com voz natural",
            "Trechos salvos para revisitar quando quiser",
            "Sem anúncios"
        ]
    }

    private var depthDescription: String {
        switch profile.explanationDepth {
        case .short: "reflexão curta"
        case .medium: "reflexão média"
        case .deep: "reflexão mais profunda"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .conversionFont(14, weight: .semibold)
                .foregroundStyle(Color.ivory)

            VStack(spacing: 0) {
                ForEach(Array(benefits.enumerated()), id: \.offset) { index, benefit in
                    ConversionListRow(symbol: "checkmark", color: Color.sageButton, text: benefit)
                    if index < benefits.count - 1 {
                        Divider().overlay(Color.conversionDivider)
                    }
                }
            }
            .background(Color.conversionPanel, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.conversionBorder, lineWidth: 1))
        }
    }
}

/// Pílula sálvia em largura total, agora inserida no fluxo de rolagem.
private struct SubscriptionGateHeroButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .limiarFont(19, design: .serif, relativeTo: .title3)
            .lineLimit(1)
            .minimumScaleFactor(0.62)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Color.sageButton.opacity(configuration.isPressed ? 0.76 : 1), in: RoundedRectangle(cornerRadius: 24))
            .foregroundStyle(Color.deepInk)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    LimiarHaptics.tap()
                }
            }
    }
}

private struct SubscriptionGatePlanPicker: View {
    @Environment(SubscriptionManager.self) private var subscription
    @Binding var selection: SubscriptionPlan
    let forcesTrialEligibilityForDebugging: Bool

    var body: some View {
        VStack(spacing: 10) {
            ForEach([SubscriptionPlan.monthly, .yearly]) { plan in
                Button {
                    guard selection != plan else { return }
                    LimiarHaptics.select()
                    selection = plan
                    subscription.noteUserSelectedPlan()
                    LimiarAnalytics.trackGatePlanSelected(
                        plan,
                        offerEligibility: subscription.introductoryOfferEligibility(for: plan)
                    )
                } label: {
                    SubscriptionGatePlanRow(
                        plan: plan,
                        isSelected: selection == plan,
                        priceLine: priceLine(for: plan),
                        detailLine: detailLine(for: plan),
                        badge: badge(for: plan)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == plan ? .isSelected : [])
            }
        }
    }

    private func priceLine(for plan: SubscriptionPlan) -> String {
        guard subscription.product(for: plan) != nil else {
            return subscription.storeDisplayPrice(for: plan)
        }
        return "\(subscription.storeDisplayPrice(for: plan))/\(period(for: plan))"
    }

    private func detailLine(for plan: SubscriptionPlan) -> String {
        if !forcesTrialEligibilityForDebugging,
           subscription.introductoryOfferEligibility(for: plan) == .unknown {
            return "Verificando oferta com a App Store"
        }

        switch plan {
        case .monthly, .monthlyWelcome:
            return showsEligibleTrial(for: plan)
                ? "Cancele quando quiser"
                : "Assinatura por \(priceLine(for: plan)) · cancele quando quiser"
        case .yearly:
            var parts: [String] = []
            if let equivalent = subscription.monthlyEquivalentDisplayPrice(for: .yearly) {
                parts.append("Equivale a \(equivalent)/mês")
            }
            if let savings = subscription.yearlySavingsDisplayPrice() {
                parts.append("Economize \(savings)")
            }
            if parts.isEmpty {
                return "Cobrado uma vez por ano"
            }
            return parts.joined(separator: " · ")
        }
    }

    private func badge(for plan: SubscriptionPlan) -> SubscriptionGatePlanRow.Badge? {
        switch plan {
        case .monthly: .init(text: "Mais escolhido", isAccent: true)
        case .yearly: .init(text: "Melhor valor", isAccent: false)
        case .monthlyWelcome: .init(text: "Boas-vindas", isAccent: true)
        }
    }

    private func showsEligibleTrial(for plan: SubscriptionPlan) -> Bool {
        forcesTrialEligibilityForDebugging || subscription.hasEligibleFreeTrial(for: plan)
    }

    private func period(for plan: SubscriptionPlan) -> String {
        switch plan {
        case .monthly, .monthlyWelcome: "mês"
        case .yearly: "ano"
        }
    }
}

/// Linha de plano contida (borda fina, fundo translúcido): o destaque fica na
/// seleção dourada, não em cartões gritantes que quebram a atmosfera.
private struct SubscriptionGatePlanRow: View {
    struct Badge {
        let text: String
        let isAccent: Bool
    }

    let plan: SubscriptionPlan
    let isSelected: Bool
    var previousPriceLine: String? = nil
    let priceLine: String
    let detailLine: String
    let badge: Badge?

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .stroke(isSelected ? Color.warmGold : Color.softText.opacity(0.6), lineWidth: 1.4)
                    .frame(width: 22, height: 22)
                if isSelected {
                    Circle()
                        .fill(Color.warmGold)
                        .frame(width: 11, height: 11)
                }
            }
            .padding(.top, 6)

            VStack(alignment: .leading, spacing: 5) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        planTitle
                        Spacer(minLength: 8)
                        planPrice
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        planTitle
                        planPrice
                    }
                }

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: 8) {
                        planDetail
                        Spacer(minLength: 6)
                        if let badge {
                            planBadge(badge)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        planDetail
                        if let badge {
                            planBadge(badge)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            Color.conversionPanel.opacity(isSelected ? 0.85 : 0.6),
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isSelected ? Color.warmGold.opacity(0.85) : Color.conversionBorder,
                    lineWidth: isSelected ? 1.4 : 1
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 14))
    }

    private var planTitle: some View {
        Text(plan.title)
            .limiarFont(24, design: .serif, relativeTo: .title2)
            .foregroundStyle(Color.ivory)
    }

    private var planPrice: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            if let previousPriceLine {
                Text(previousPriceLine)
                    .limiarFont(13, weight: .medium, relativeTo: .footnote)
                    .foregroundStyle(Color.softText)
                    .strikethrough(true, color: Color.softText)
            }
            Text(priceLine)
                .limiarFont(16, weight: .medium, relativeTo: .headline)
                .foregroundStyle(Color.ivory)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
        }
    }

    private var planDetail: some View {
        Text(detailLine)
            .limiarFont(13, weight: .medium, relativeTo: .footnote)
            .foregroundStyle(Color.softText)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func planBadge(_ badge: Badge) -> some View {
        Text(badge.text)
            .limiarFont(11, weight: .semibold, relativeTo: .caption)
            .foregroundStyle(badge.isAccent ? Color.warmGold : Color.softText)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .overlay(
                Capsule().stroke(
                    badge.isAccent ? Color.warmGold.opacity(0.7) : Color.softText.opacity(0.5),
                    lineWidth: 1
                )
            )
            .fixedSize()
    }
}

/// Linha com o logo da Apple logo depois do botão: antecipa o que a folha da
/// App Store vai mostrar e reforça que o valor de hoje é zero.
private struct SubscriptionGateAppleReassurance: View {
    @Environment(SubscriptionManager.self) private var subscription

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "apple.logo")
                .limiarFont(14, relativeTo: .footnote)
                .foregroundStyle(Color.ivory)
            Text("A Apple pede sua confirmação · \(subscription.zeroDisplayPrice()) hoje")
                .limiarFont(13, weight: .medium, relativeTo: .footnote)
                .foregroundStyle(Color.softText)
                .lineLimit(2)
                .layoutPriority(1)
        }
    }
}

private struct SubscriptionGateSocialProof: View {
    var body: some View {
        Text("Mais de 5 mil pessoas usam o Limiar para desacelerar, refletir e viver com mais presença.")
            .limiarFont(13, weight: .medium, relativeTo: .footnote)
            .foregroundStyle(Color.softText)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
    }
}

/// Links discretos de rodapé: Restaurar · Termos · Privacidade.
private struct SubscriptionGateFooterLinks: View {
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(\.openURL) private var openURL
    let termsURL: URL
    let privacyURL: URL
    var restoreOrigin: SubscriptionPurchaseOrigin = .subscriptionGate

    var body: some View {
        HStack(spacing: 14) {
            Button("Restaurar compras") {
                Task { await subscription.restorePurchases(origin: restoreOrigin) }
            }
            .disabled(subscription.isBusy)
            Text("·")
            Button("Termos") { openURL(termsURL) }
            Text("·")
            Button("Privacidade") { openURL(privacyURL) }
        }
        .limiarFont(12, weight: .medium, relativeTo: .caption)
        .foregroundStyle(Color.softText)
        .frame(maxWidth: .infinity)
    }
}

private struct SubscriptionGatePurchaseSection: View {
    @Environment(SubscriptionManager.self) private var subscription
    let forcesTrialEligibilityForDebugging: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                Task {
                    await subscription.purchaseSelectedPlan(origin: .subscriptionGate)
                }
            } label: {
                HStack(spacing: 10) {
                    if subscription.state == .purchasing {
                        ProgressView().tint(Color.deepInk)
                    }
                    Text(buttonTitle)
                    Image(systemName: "arrow.right")
                        .limiarFont(17, relativeTo: .headline)
                }
            }
            .buttonStyle(SubscriptionGateHeroButtonStyle())
            .disabled(!canSubscribe)
            .opacity(canSubscribe ? 1 : 0.62)

            if showsEligibleTrial {
                SubscriptionGateAppleReassurance()
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            if let statusText {
                Text(statusText)
                    .conversionFont(12, weight: .medium, relativeTo: .footnote)
                    .foregroundStyle(Color.softText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            if showsRetryButton {
                Button {
                    Task { await subscription.recoverIfNeeded() }
                } label: {
                    Label("Tentar novamente", systemImage: "arrow.clockwise")
                        .conversionFont(14, weight: .semibold, relativeTo: .footnote)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.sageButton.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.sageButton.opacity(0.5), lineWidth: 1)
                        )
                        .foregroundStyle(Color.sageButton)
                }
                .accessibilityLabel("Tentar carregar os planos novamente")
            }

        }
        .frame(maxWidth: .infinity)
    }

    private var showsEligibleTrial: Bool {
        forcesTrialEligibilityForDebugging
            || subscription.hasEligibleFreeTrial(for: subscription.selectedPlan)
    }

    private var canSubscribe: Bool {
        subscription.canPurchase(subscription.selectedPlan)
            && subscription.introductoryOfferEligibility(for: subscription.selectedPlan) != .unknown
    }

    /// A primeira carga de produtos pode falhar (sem rede no fim do
    /// onboarding). O portão não tem bypass, então precisa oferecer uma
    /// saída explícita em vez de ficar com o CTA desabilitado para sempre.
    private var showsRetryButton: Bool {
        guard !subscription.isBusy else { return false }
        if subscription.products.isEmpty { return true }
        if case .failed = subscription.state { return true }
        return false
    }

    private var buttonTitle: String {
        let plan = subscription.selectedPlan
        if forcesTrialEligibilityForDebugging || subscription.hasEligibleFreeTrial(for: plan) {
            return "Começar 7 dias grátis"
        }
        if subscription.introductoryOfferEligibility(for: plan) == .unknown,
           subscription.product(for: plan) != nil {
            return "Verificando oferta..."
        }
        guard subscription.product(for: plan) != nil else {
            return subscription.products.isEmpty ? "Carregando planos" : "Plano indisponível"
        }
        return "Assinar por \(subscription.storeDisplayPrice(for: plan))"
    }

    private var statusText: String? {
        switch subscription.state {
        case .purchased, .restored, .pending, .productsUnavailable, .failed:
            return subscription.statusText
        case .idle, .loadingProducts, .purchasing, .active, .expired, .cancelled:
            // .cancelled vira a tela de recuperação; não repete a mensagem aqui.
            return nil
        }
    }
}

/// "A porta continua aberta." — mostrada quando a pessoa fecha a folha da
/// App Store sem concluir. Sem urgência, sem vermelho: responde às objeções
/// (nada foi cobrado, aviso no dia 5, cancelar é fácil) e oferece o plano de
/// menor compromisso como segunda chance.
private struct SubscriptionGateRecoveryView: View {
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.scenePhase) private var scenePhase
    @State private var didAttemptRestore = false
    let termsURL: URL
    let privacyURL: URL
    let forcesTrialEligibilityForDebugging: Bool

    private var alternativePlan: SubscriptionPlan {
        switch subscription.selectedPlan {
        case .monthly:
            .yearly
        case .yearly, .monthlyWelcome:
            .monthly
        }
    }

    private var showsEligibleTrial: Bool {
        forcesTrialEligibilityForDebugging
            || subscription.hasEligibleFreeTrial(for: subscription.selectedPlan)
    }

    var body: some View {
        Group {
            if subscription.welcomeOfferState == .available {
                welcomeOfferLayout
            } else {
                standardRecoveryLayout
            }
        }
        .onAppear {
            LimiarAnalytics.trackGateRecoveryViewed()
            if subscription.welcomeOfferState == .available {
                LimiarAnalytics.trackGateOfferViewed()
            }
        }
        .onChange(of: subscription.welcomeOfferState) { oldValue, newValue in
            if oldValue != .available, newValue == .available {
                LimiarAnalytics.trackGateOfferViewed()
            }
        }
        .onChange(of: scenePhase) { oldValue, newValue in
            if oldValue == .active,
               newValue == .background,
               subscription.welcomeOfferState == .available {
                subscription.declineWelcomeOffer(reason: .background)
            }
        }
    }

    private var standardRecoveryLayout: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 14) {
                        OnboardingTitle(eyebrow: "SEM PRESSA", title: "A porta continua aberta.")

                        Text(showsEligibleTrial
                            ? "Nada foi cobrado. Se a confirmação da Apple te pegou de surpresa, é assim que funciona:"
                            : "Nada foi cobrado. Quando quiser, é só tentar de novo:")
                            .limiarFont(16, weight: .medium, relativeTo: .body)
                            .foregroundStyle(Color.softText)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        if showsEligibleTrial {
                            SubscriptionGateRecoveryCheck(text: "\(subscription.zeroDisplayPrice()) hoje — a Apple só confirma, não cobra")
                            SubscriptionGateRecoveryCheck(text: "Avisamos no dia 5, antes de qualquer cobrança")
                        } else {
                            SubscriptionGateRecoveryCheck(text: "A Apple só cobra depois da sua confirmação")
                        }
                        SubscriptionGateRecoveryCheck(text: "Cancele em 2 toques em Ajustes › Assinaturas")
                    }

                    SubscriptionGatePlanRow(
                        plan: subscription.selectedPlan,
                        isSelected: true,
                        priceLine: priceLine(for: subscription.selectedPlan),
                        detailLine: detailLine(for: subscription.selectedPlan),
                        badge: nil
                    )

                    Button {
                        let plan = alternativePlan
                        guard subscription.selectedPlan != plan else { return }
                        LimiarHaptics.select()
                        subscription.selectedPlan = plan
                        subscription.noteUserSelectedPlan()
                        LimiarAnalytics.trackGatePlanSelected(
                            plan,
                            offerEligibility: subscription.introductoryOfferEligibility(for: plan)
                        )
                    } label: {
                        Text(alternativeLinkTitle)
                            .limiarFont(14, weight: .medium, relativeTo: .footnote)
                            .foregroundStyle(Color.softText)
                            .underline(true, color: Color.softText.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 18)
                .containerRelativeFrame(.horizontal)
            }

            VStack(spacing: 10) {
                recoveryActions

                if let statusText {
                    Text(statusText)
                        .conversionFont(12, weight: .medium, relativeTo: .footnote)
                        .foregroundStyle(Color.softText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }

                Button {
                    LimiarAnalytics.trackGateRecoveryDismissed()
                    subscription.dismissGateRecovery()
                } label: {
                    Text("Ver todos os planos")
                        .limiarFont(13, weight: .medium, relativeTo: .caption)
                        .foregroundStyle(Color.sageButton)
                }
                .buttonStyle(.plain)

                Text(showsEligibleTrial
                    ? "Renova automaticamente após os 7 dias. Cancele em Ajustes › Assinaturas até 24h antes do fim do período vigente."
                    : "A assinatura renova automaticamente. Cancele em Ajustes › Assinaturas até 24h antes do fim do período vigente.")
                    .conversionFont(11, relativeTo: .caption)
                    .foregroundStyle(Color.softText.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)

                SubscriptionGateFooterLinks(termsURL: termsURL, privacyURL: privacyURL)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .background(Color.deepInk.opacity(0.97))
            .overlay(alignment: .top) {
                Divider().overlay(Color.conversionBorder)
            }
        }
    }

    private var welcomeOfferLayout: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 14) {
                    OnboardingTitle(
                        eyebrow: "OFERTA DE BOAS-VINDAS",
                        title: "Fique pelo preço do anual, sem o compromisso do anual."
                    )

                    Text("Nada foi cobrado. Para você conhecer o Limiar com calma, o mensal fica pelo valor que custaria no plano anual.")
                        .limiarFont(16, weight: .medium, relativeTo: .body)
                        .foregroundStyle(Color.softText)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 14) {
                    SubscriptionGateRecoveryCheck(text: "\(subscription.zeroDisplayPrice()) hoje — a Apple só confirma, não cobra")
                    SubscriptionGateRecoveryCheck(text: "Avisamos no dia 5, antes de qualquer cobrança")
                    SubscriptionGateRecoveryCheck(text: "Cancele em 2 toques em Ajustes › Assinaturas")
                }

                SubscriptionGatePlanRow(
                    plan: .monthlyWelcome,
                    isSelected: true,
                    previousPriceLine: subscription.storeDisplayPrice(for: .monthly),
                    priceLine: "\(subscription.storeDisplayPrice(for: .monthlyWelcome))/mês",
                    detailLine: "7 dias grátis primeiro · cancele quando quiser",
                    badge: .init(text: "Boas-vindas", isAccent: true)
                )

                Text("Esta oferta aparece uma vez. Se fechar, o plano volta a \(subscription.storeDisplayPrice(for: .monthly)).")
                    .limiarFont(13, weight: .medium, relativeTo: .footnote)
                    .foregroundStyle(Color.softText)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 10) {
                    welcomeOfferActions

                    if let statusText {
                        Text(statusText)
                            .conversionFont(12, weight: .medium, relativeTo: .footnote)
                            .foregroundStyle(Color.softText)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }

                    Text(welcomeLegalText)
                        .conversionFont(11, relativeTo: .caption)
                        .foregroundStyle(Color.softText.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)

                    SubscriptionGateFooterLinks(termsURL: termsURL, privacyURL: privacyURL)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 30)
            .containerRelativeFrame(.horizontal)
        }
    }

    @ViewBuilder
    private var recoveryActions: some View {
        if dynamicTypeSize >= .xxLarge {
            VStack(spacing: 10) {
                retryButton
                restoreButton
            }
        } else {
            HStack(spacing: 8) {
                restoreButton
                Spacer(minLength: 8)
                retryButton
            }
        }
    }

    private var restoreButton: some View {
        Button {
            didAttemptRestore = true
            Task { await subscription.restorePurchases(origin: .subscriptionGate) }
        } label: {
            Text("Já sou assinante")
                .limiarFont(14, weight: .medium, relativeTo: .footnote)
                .foregroundStyle(Color.softText)
                .underline(true, color: Color.softText.opacity(0.5))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .buttonStyle(.plain)
        .disabled(subscription.isBusy)
    }

    @ViewBuilder
    private var welcomeOfferActions: some View {
        if dynamicTypeSize >= .xxLarge {
            VStack(spacing: 10) {
                acceptWelcomeOfferButton
                restoreButton
            }
        } else {
            HStack(spacing: 8) {
                restoreButton
                Spacer(minLength: 8)
                acceptWelcomeOfferButton
            }
        }
    }

    private var acceptWelcomeOfferButton: some View {
        Button {
            Task { await subscription.acceptWelcomeOffer() }
        } label: {
            HStack(spacing: 10) {
                if subscription.state == .purchasing {
                    ProgressView().tint(Color.deepInk)
                }
                Text("Aceitar e começar grátis")
                Image(systemName: "arrow.right")
                    .limiarFont(17, relativeTo: .headline)
            }
        }
        .buttonStyle(SubscriptionGateHeroButtonStyle())
        .frame(maxWidth: 284)
        .disabled(!subscription.canPurchase(.monthlyWelcome))
    }

    private var retryButton: some View {
        Button {
            LimiarAnalytics.trackGateRecoveryRetry(subscription.selectedPlan)
            Task {
                await subscription.purchaseSelectedPlan(origin: .subscriptionGate)
            }
        } label: {
            HStack(spacing: 10) {
                if subscription.state == .purchasing {
                    ProgressView().tint(Color.deepInk)
                }
                Text(showsEligibleTrial ? "Tentar de novo, grátis" : "Tentar de novo")
                Image(systemName: "arrow.right")
                    .limiarFont(17, relativeTo: .headline)
            }
        }
        .buttonStyle(SubscriptionGateHeroButtonStyle())
        .frame(maxWidth: 272)
        .disabled(!subscription.canPurchase(subscription.selectedPlan))
    }

    private var alternativeLinkTitle: String {
        switch alternativePlan {
        case .yearly:
            if let equivalent = subscription.monthlyEquivalentDisplayPrice(for: .yearly) {
                return "Prefiro o anual · \(equivalent)/mês"
            }
            return "Prefiro o anual"
        case .monthly:
            return "Prefiro o mensal · \(subscription.storeDisplayPrice(for: .monthly))/mês"
        case .monthlyWelcome:
            return "Prefiro o mensal"
        }
    }

    private var welcomeLegalText: String {
        "7 dias grátis. Depois, \(subscription.storeDisplayPrice(for: .monthlyWelcome))/mês, com renovação automática mensal. Cancele em Ajustes › Assinaturas até 24h antes do fim do período vigente."
    }

    private var statusText: String? {
        switch subscription.state {
        case .purchased, .restored, .pending, .productsUnavailable, .failed:
            return subscription.statusText
        case .expired where didAttemptRestore:
            return subscription.statusText
        case .idle, .loadingProducts, .purchasing, .active, .expired, .cancelled:
            return nil
        }
    }

    private func priceLine(for plan: SubscriptionPlan) -> String {
        guard subscription.product(for: plan) != nil else {
            return subscription.storeDisplayPrice(for: plan)
        }
        let period: String
        switch plan {
        case .monthly, .monthlyWelcome:
            period = "mês"
        case .yearly:
            period = "ano"
        }
        return "\(subscription.storeDisplayPrice(for: plan))/\(period)"
    }

    private func detailLine(for plan: SubscriptionPlan) -> String {
        switch plan {
        case .monthly:
            return "Menor compromisso · cancele quando quiser"
        case .yearly:
            if let equivalent = subscription.monthlyEquivalentDisplayPrice(for: .yearly) {
                return "Equivale a \(equivalent)/mês · cancele quando quiser"
            }
            return "Cobrado uma vez por ano · cancele quando quiser"
        case .monthlyWelcome:
            return "7 dias grátis primeiro · cancele quando quiser"
        }
    }
}

private struct SubscriptionGateRecoveryCheck: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.warmGold.opacity(0.8), lineWidth: 1.2)
                    .frame(width: 26, height: 26)
                Image(systemName: "checkmark")
                    .limiarFont(12, weight: .semibold, relativeTo: .caption)
                    .foregroundStyle(Color.warmGold)
            }
            Text(text)
                .limiarFont(15, weight: .medium, relativeTo: .subheadline)
                .foregroundStyle(Color.ivory.opacity(0.92))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 3)
        }
    }
}

struct ConversionHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow)
                .conversionFont(12, weight: .bold, relativeTo: .caption)
                .tracking(2)
                .foregroundStyle(Color.warmGold)

            Text(title)
                .conversionFont(27, design: .serif, relativeTo: .title)
                .foregroundStyle(Color.ivory)
                .fixedSize(horizontal: false, vertical: true)

            if let subtitle {
                Text(subtitle)
                    .conversionFont(15)
                    .foregroundStyle(Color.softText)
                    .lineSpacing(4)
            }
        }
    }
}

struct ConversionContrastLine: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "checkmark")
                .conversionFont(13, weight: .bold)
                .foregroundStyle(Color.sageButton)
            Text(text)
                .conversionFont(14, weight: .medium)
                .foregroundStyle(Color.softText)
                .lineSpacing(3)
        }
    }
}

struct ConversionLossBlock: View {
    let title: String
    let finalItem: String

    private var items: [String] {
        [
            "Reflexão completa: significado, aplicação e pergunta",
            "Narração com voz natural",
            "Tradição, profundidade e livros do seu jeito",
            "Salvar trechos e rever seu histórico",
            finalItem
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .conversionFont(14, weight: .semibold)
                .foregroundStyle(Color.ivory)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    ConversionListRow(symbol: "xmark", color: Color.conversionCoral, text: item)
                    if index < items.count - 1 {
                        Divider().overlay(Color.conversionDivider)
                    }
                }
            }
            .background(Color.conversionPanel, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.conversionBorder, lineWidth: 1))
        }
    }
}

struct ConversionListRow: View {
    let symbol: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .conversionFont(15, weight: .bold)
                .foregroundStyle(color)
                .frame(width: 18)
            Text(text)
                .conversionFont(15)
                .foregroundStyle(Color(red: 0.79, green: 0.81, blue: 0.79))
                .lineSpacing(3)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }
}

struct ConversionPlanPicker: View {
    @Environment(SubscriptionManager.self) private var subscription
    @Binding var selection: SubscriptionPlan

    var body: some View {
        VStack(spacing: 12) {
            ForEach(SubscriptionPlan.standardPlans.sorted { $0.sortOrder < $1.sortOrder }) { plan in
                Button {
                    selection = plan
                } label: {
                    VStack(alignment: .leading, spacing: 7) {
                        if plan == .yearly {
                            Text("MAIS ESCOLHIDO")
                                .conversionFont(11, weight: .bold, relativeTo: .caption)
                                .tracking(1)
                                .foregroundStyle(Color.deepInk)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Color.sageButton, in: Capsule())
                        }

                        HStack(spacing: 8) {
                            Image(systemName: selection == plan ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selection == plan ? Color.sageButton : Color.softText)
                            Text(plan.title)
                                .conversionFont(17, weight: .semibold, relativeTo: .headline)
                                .foregroundStyle(Color.ivory)
                            Spacer(minLength: 8)
                            Text(mainPrice(for: plan))
                                .conversionFont(16, weight: .semibold, relativeTo: .headline)
                                .foregroundStyle(Color.ivory)
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                                .layoutPriority(1)
                        }

                        Text(detail(for: plan))
                            .conversionFont(13, weight: .medium, relativeTo: .footnote)
                            .foregroundStyle(Color.softText)
                            .padding(.leading, 31)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .background(selection == plan ? Color(red: 0.086, green: 0.13, blue: 0.12) : Color.conversionPanel, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(selection == plan ? Color.sageButton : Color.conversionBorder, lineWidth: selection == plan ? 2 : 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func mainPrice(for plan: SubscriptionPlan) -> String {
        switch plan {
        case .yearly:
            return "\(subscription.displayPrice(for: plan))/ano"
        case .monthly, .monthlyWelcome:
            return "\(subscription.displayPrice(for: plan))/mês"
        }
    }

    private func detail(for plan: SubscriptionPlan) -> String {
        switch plan {
        case .yearly:
            guard let daily = subscription.dailyEquivalentPrice(for: plan) else {
                return "Cobrado uma vez por ano"
            }
            return "Menos de \(daily) por dia · cobrado uma vez por ano"
        case .monthly, .monthlyWelcome:
            return "Renovação mensal · cancele quando quiser"
        }
    }
}

struct ConversionPurchaseSection: View {
    @Environment(SubscriptionManager.self) private var subscription
    let buttonTitle: String
    let escapeTitle: String
    let analyticsOrigin: LimiarAnalytics.PaywallOrigin
    var escapeAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    await subscription.purchaseSelectedPlan(
                        legacyPaywallOrigin: analyticsOrigin
                    )
                }
            } label: {
                HStack(spacing: 10) {
                    if subscription.state == .purchasing {
                        ProgressView().tint(Color.deepInk)
                    }
                    Text(buttonTitle)
                    Image(systemName: "arrow.right")
                }
                .conversionFont(17, weight: .semibold, relativeTo: .headline)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.sageButton, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(Color.deepInk)
            }
            .disabled(!subscription.canPurchase(subscription.selectedPlan))
            .opacity(subscription.canPurchase(subscription.selectedPlan) ? 1 : 0.62)

            Button { escapeAction?() } label: {
                ConversionSecondaryActionLabel(title: escapeTitle)
            }

            Text("Cancele quando quiser · A App Store confirma antes de cobrar")
                .conversionFont(12, relativeTo: .footnote)
                .foregroundStyle(Color.softText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Text(subscription.renewalDisclosure(for: subscription.selectedPlan))
                .conversionFont(12, relativeTo: .footnote)
                .foregroundStyle(Color.softText.opacity(0.85))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            if !subscription.statusText.isEmpty {
                Text(subscription.statusText)
                    .conversionFont(14, weight: .medium)
                    .foregroundStyle(Color.softText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct ConversionSecondaryActionLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .conversionFont(15, weight: .semibold)
            .foregroundStyle(Color.sageButton)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.conversionPanel, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.sageButton.opacity(0.75), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ConversionLegalLinks: View {
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(\.openURL) private var openURL
    let termsURL: URL
    let privacyURL: URL

    var body: some View {
        VStack(spacing: 12) {
            Button {
                Task { await subscription.restorePurchases() }
            } label: {
                Label("Restaurar compra", systemImage: "arrow.clockwise")
                    .conversionFont(13, weight: .semibold, relativeTo: .footnote)
            }
            .disabled(subscription.isBusy)

            HStack(spacing: 18) {
                Button("Termos de Uso") { openURL(termsURL) }
                Button("Política de Privacidade") { openURL(privacyURL) }
            }
            .conversionFont(13, weight: .medium, relativeTo: .footnote)
            .foregroundStyle(Color.sageButton)
            .frame(maxWidth: .infinity)
        }
    }
}

extension Color {
    static let conversionPanel = Color(red: 0.067, green: 0.106, blue: 0.11)
    static let conversionBorder = Color(red: 0.141, green: 0.192, blue: 0.184)
    static let conversionDivider = Color(red: 0.114, green: 0.157, blue: 0.153)
    static let conversionCoral = Color(red: 0.847, green: 0.541, blue: 0.478)
}

#Preview {
    PaywallView(analyticsOrigin: .settings)
        .environment(LimiarAppModel())
        .environment(SubscriptionManager())
}
