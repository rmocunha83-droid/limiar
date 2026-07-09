@preconcurrency import AVFoundation
import FamilyControls
import ManagedSettings
import SwiftUI

struct EssentialModeIntroView: View {
    @Environment(SubscriptionManager.self) private var subscription
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

                        Text("Seu acesso inicial terminou. Você ainda pode continuar usando o Limiar com trechos e explicações essenciais. A versão essencial exibe anúncios e não inclui narração.")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.softText)
                            .lineSpacing(5)

                        Text("Para remover anúncios, narrar os textos e ter maior variedade de trechos, assine o Limiar completo.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.sageButton)
                            .lineSpacing(4)
                    }

                    VStack(alignment: .leading, spacing: 13) {
                        TrialDisclosureRow(icon: "book.closed", text: "3 trechos e explicações essenciais continuam disponíveis")
                        TrialDisclosureRow(icon: "rectangle.3.group", text: "Anúncios aparecem apenas no Modo Essencial")
                        TrialDisclosureRow(icon: "speaker.wave.2", text: "Narração dos textos na versão completa")
                        TrialDisclosureRow(icon: "arrow.triangle.2.circlepath", text: "Maior variedade e experiência sem anúncios na versão completa")
                    }
                    .padding(16)
                    .limiarPanel()

                    if subscription.canShowPaywall {
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

struct FreeTrialStartView: View {
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
                        Text("ACESSO INICIAL")
                            .font(.system(size: 13, weight: .bold))
                            .tracking(1.3)
                            .foregroundStyle(Color.warmGold)

                        Text("Comece com 7 dias de acesso completo")
                            .font(.system(size: 44, weight: .regular, design: .serif))
                            .foregroundStyle(Color.ivory)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Use o Limiar completo por 7 dias. Depois desse período, será necessária uma assinatura mensal ou anual para continuar usando as pausas, leituras e reflexões personalizadas.")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.softText)
                            .lineSpacing(5)
                    }

                    VStack(alignment: .leading, spacing: 13) {
                        TrialDisclosureRow(icon: "calendar.badge.clock", text: "7 dias de acesso completo")
                        TrialDisclosureRow(icon: "creditcard", text: subscription.marketingPricingLine)
                        TrialDisclosureRow(icon: "xmark.circle", text: "Cancelamento a qualquer momento")
                        TrialDisclosureRow(icon: "checkmark.shield", text: "Nenhuma assinatura é iniciada nesta etapa")
                        TrialDisclosureRow(icon: "lock.open", text: "Assinatura necessária depois para continuar na versão completa")
                    }
                    .padding(16)
                    .limiarPanel()

                    Button {
                        subscription.startFreeTrial()
                    } label: {
                        HStack(spacing: 12) {
                            Text("Começar acesso inicial")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.sageButton, in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(Color.deepInk)
                    }

                    Text("Você não está assinando agora. O acesso inicial começa localmente e o app pedirá assinatura somente depois dos 7 dias.")
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

struct TrialConversionView: View {
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

                        Text("Você já começou a recuperar seu foco e criar uma rotina espiritual. Para continuar usando as pausas, leituras e reflexões personalizadas após o acesso inicial, assine o Limiar Premium.")
                            .font(.system(size: 17))
                            .foregroundStyle(Color.softText)
                            .lineSpacing(5)
                    }

                    TrialMetricsPanel()

                    if subscription.canShowPaywall {
                        NavigationLink {
                            PaywallView()
                        } label: {
                            HStack(spacing: 12) {
                                Text("Ver planos Premium")
                                Image(systemName: "arrow.right")
                            }
                            .font(.system(size: 18, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(Color.sageButton, in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(Color.deepInk)
                        }
                        .disabled(subscription.isBusy)
                    }

                    Button("Continuar por enquanto") {
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

struct TrialDisclosureRow: View {
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
                icon: "sunrise",
                value: model.estimatedFocusTimeText,
                label: model.history.count == 1 ? "travessia matinal" : "travessias matinais"
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

struct TrialMetricRow: View {
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
