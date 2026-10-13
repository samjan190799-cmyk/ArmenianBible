import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Свеча в Dynamic Island и на экране блокировки
@available(iOS 16.2, *)
struct CandleLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CandleActivityAttributes.self) { context in
            CandleLockScreenView(attributes: context.attributes)
                .activityBackgroundTint(CandleIslandPalette.background)
                .activitySystemActionForegroundColor(CandleIslandPalette.amberSoft)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    IslandCandleView(attributes: context.attributes)
                        .frame(width: 54, height: 80)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    CandleBurnRing(attributes: context.attributes)
                        .frame(width: 40, height: 40)
                        .padding(.top, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    CandleIslandTitle(attributes: context.attributes, alignment: .center)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        CandleBurnBar(attributes: context.attributes)
                        CandleRemainingText(attributes: context.attributes)
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                IslandCandleView(attributes: context.attributes)
                    .frame(width: 20, height: 30)
            } compactTrailing: {
                CandleBurnRing(attributes: context.attributes)
                    .frame(width: 22, height: 22)
            } minimal: {
                IslandCandleView(attributes: context.attributes)
                    .frame(width: 18, height: 28)
            }
            .keylineTint(CandleIslandPalette.amber)
        }
    }
}
