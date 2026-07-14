import SwiftUI
import UIKit
@preconcurrency import GoogleMobileAds

enum LimiarAdMobConfiguration {
    static let appID = "ca-app-pub-7717198050770102~4802998011"

    #if DEBUG
    static let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    #else
    static let bannerAdUnitID = "ca-app-pub-7717198050770102/8580637095"
    #endif
}

struct LimiarAdBannerSlot: View {
    var label = "Publicidade"

    @State private var reservedBannerHeight: CGFloat = 50

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Color.softText.opacity(0.7))

            GeometryReader { proxy in
                let width = max(1, proxy.size.width)
                let adaptiveSize = currentOrientationAnchoredAdaptiveBanner(width: width)

                Group {
                    LimiarAdaptiveBannerView(
                        adUnitID: LimiarAdMobConfiguration.bannerAdUnitID,
                        availableWidth: width
                    )
                    .frame(width: width, height: adaptiveSize.size.height)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .onAppear {
                    reserveHeight(adaptiveSize.size.height)
                }
                .onChange(of: width) { _, _ in
                    reserveHeight(adaptiveSize.size.height)
                }
            }
            .frame(height: reservedBannerHeight)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Publicidade")
    }

    private func reserveHeight(_ height: CGFloat) {
        guard abs(height - reservedBannerHeight) > 0.5 else { return }
        DispatchQueue.main.async {
            reservedBannerHeight = height
        }
    }
}

private struct LimiarAdaptiveBannerView: UIViewRepresentable {
    let adUnitID: String
    let availableWidth: CGFloat

    final class Coordinator {
        var configuredWidth: CGFloat = 0
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> BannerView {
        let width = max(1, availableWidth)
        let banner = BannerView(adSize: currentOrientationAnchoredAdaptiveBanner(width: width))
        banner.adUnitID = adUnitID
        banner.backgroundColor = .clear
        banner.setContentHuggingPriority(.defaultLow, for: .horizontal)
        banner.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        banner.rootViewController = UIApplication.shared.limiarRootViewController
        context.coordinator.configuredWidth = width
        banner.load(Request())
        return banner
    }

    func updateUIView(_ banner: BannerView, context: Context) {
        let width = max(1, availableWidth)

        // A largura recebida do container e a unica fonte de verdade. Nunca use
        // bounds/intrinsicContentSize do proprio anuncio aqui: isso reintroduz um
        // ciclo de realimentacao no layout do dashboard.
        if abs(context.coordinator.configuredWidth - width) > 1 {
            banner.adSize = currentOrientationAnchoredAdaptiveBanner(width: width)
            context.coordinator.configuredWidth = width
            banner.load(Request())
        }

        banner.rootViewController = UIApplication.shared.limiarRootViewController
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: BannerView,
        context: Context
    ) -> CGSize? {
        CGSize(
            width: min(proposal.width ?? availableWidth, availableWidth),
            height: uiView.adSize.size.height
        )
    }
}

private extension UIApplication {
    var limiarRootViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}
