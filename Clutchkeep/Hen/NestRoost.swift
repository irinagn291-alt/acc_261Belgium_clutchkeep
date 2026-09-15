import SwiftUI

/// Role: Hen. Named hen tiles filling remaining height. A nest tap writes one Credit.
struct NestRoost: View {
    var watch: RoostWatch
    var hens: [Hen]
    var columns: Int

    /// Phone packs five hens as 3+2. Wide canvas spreads them across so Production can use remaining height.
    static func laneCount(henCount: Int, wide: Bool) -> Int {
        if wide {
            min(max(henCount, 1), 5)
        } else {
            switch henCount {
            case ...1:
                1
            case 2, 4:
                2
            case 3, 5, 6:
                3
            default:
                2
            }
        }
    }

    static func rowCount(henCount: Int, wide: Bool) -> Int {
        let columns = laneCount(henCount: henCount, wide: wide)
        return max(1, Int(ceil(Double(max(henCount, 1)) / Double(max(columns, 1)))))
    }

    /// Compact roost band. Phone tiles stay nest-sized so Production, Mash, and Dose keep a usable board.
    static func bandHeight(henCount: Int, wide: Bool) -> CGFloat {
        let rows = rowCount(henCount: henCount, wide: wide)
        let tile = wide ? RoostRail.space(21) : RoostRail.space(12)
        return CGFloat(rows) * tile + RoostRail.space(1) * CGFloat(max(rows - 1, 0)) + RoostRail.space(2)
    }

    /// Smallest roost that still keeps every hen tag at 44pt.
    static func roostFloor(henCount: Int, wide: Bool) -> CGFloat {
        let rows = rowCount(henCount: henCount, wide: wide)
        return CGFloat(rows) * RoostRail.tap + RoostRail.space(1) * CGFloat(max(rows - 1, 0)) + RoostRail.space(2)
    }

    /// Production / Mash / Dose floor so the fused page is a board, not a stub sliver.
    static let boardFloor = RoostRail.space(26)

    /// Share roost vs the fused board. The board keeps `boardFloor` when the canvas allows it.
    static func split(
        henCount: Int,
        wide: Bool,
        in height: CGFloat,
        gutter: CGFloat = RoostRail.space(1)
    ) -> (roost: CGFloat, board: CGFloat) {
        let usable = max(0, height - gutter)
        let idealRoost = bandHeight(henCount: henCount, wide: wide)
        let floorRoost = roostFloor(henCount: henCount, wide: wide)
        guard usable > 0 else { return (0, 0) }
        if usable >= idealRoost + boardFloor {
            return (idealRoost, usable - idealRoost)
        }
        let roost = min(idealRoost, max(floorRoost, usable - min(boardFloor, usable * 0.58)))
        return (roost, max(0, usable - roost))
    }

    var body: some View {
        GeometryReader { geo in
            let spacing = RoostRail.space(1)
            let rowList = rows
            let rowCount = max(1, rowList.count)
            let verticalPad = RoostRail.space(2)
            let cellHeight = max(
                RoostRail.tap,
                (geo.size.height - verticalPad - spacing * CGFloat(rowCount - 1)) / CGFloat(rowCount)
            )
            VStack(spacing: spacing) {
                ForEach(rowList) { row in
                    HStack(spacing: spacing) {
                        ForEach(row.hens) { hen in
                            NestTile(watch: watch, hen: hen)
                                .frame(maxWidth: .infinity, minHeight: cellHeight, maxHeight: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(RoostRail.space(1))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            ZStack {
                RoostDune.surface
                Image(RoostPlate.cardBackdrop)
                    .resizable()
                    .scaledToFill()
                    .opacity(0.22)
                    .clipped()
                RoostRailStroke()
                    .stroke(RoostDune.muted.opacity(0.45), lineWidth: RoostRail.hairline)
                    .padding(.horizontal, RoostRail.space(1))
            }
            .accessibilityHidden(true)
        }
        .clipShape(RoostRail.cardShape)
        .overlay {
            RoostRail.cardShape.stroke(RoostDune.muted.opacity(0.35), lineWidth: RoostRail.hairline)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Roost")
    }

    private var rows: [NestRow] {
        stride(from: 0, to: hens.count, by: columns).map { start in
            NestRow(hens: Array(hens[start ..< min(start + columns, hens.count)]))
        }
    }
}

private struct NestRow: Identifiable {
    var hens: [Hen]
    var id: UUID { hens[0].id }
}

/// Role: Hen. One glass nest tile. Custom cup drawing stays on this roost.
struct NestTile: View {
    var watch: RoostWatch
    var hen: Hen
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let count = watch.credits(for: hen.id)
        Button {
            RoostKeyboard.dismiss()
            watch.creditHen(hen.id)
        } label: {
            ZStack {
                NestCup()
                    .fill(RoostDune.background.opacity(0.9))
                    .overlay {
                        NestCup().stroke(RoostDune.muted.opacity(0.55), lineWidth: RoostRail.hairline)
                    }
                    .padding(.horizontal, RoostRail.space(1))
                    .padding(.vertical, RoostRail.space(1))
                VStack(spacing: RoostRail.space(1)) {
                    Image(RoostPlate.controlFace)
                        .resizable()
                        .scaledToFit()
                        .frame(width: RoostRail.space(4), height: RoostRail.space(4))
                        .accessibilityHidden(true)
                    Text(hen.name)
                        .font(RoostFace.font(.body).weight(.semibold))
                        .foregroundStyle(RoostDune.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                    LayBead(role: hen.role)
                    Text(RoostFigures.qty(count))
                        .font(RoostFace.font(.heading).monospacedDigit())
                        .foregroundStyle(RoostDune.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .layoutPriority(1)
                }
                .padding(.horizontal, RoostRail.space(1))
                .padding(.vertical, RoostRail.space(1))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(RoostDune.surface)
            .clipShape(RoostRail.cardShape)
            .overlay {
                RoostRail.cardShape.stroke(RoostDune.muted.opacity(0.4), lineWidth: RoostRail.hairline)
            }
            .contentShape(RoostRail.cardShape)
        }
        .buttonStyle(RoostPressStyle(enabled: watch.creditEnabled && !watch.isCommitting))
        .disabled(!watch.creditEnabled || watch.isCommitting)
        .contextMenu {
            Button("Cull from the roost", role: .destructive) {
                watch.cullTarget = hen
            }
        }
        .accessibilityLabel(
            "\(hen.name), \(watch.roleLabel(hen)), \(RoostFigures.qty(count)) credits. Logs one egg."
        )
        .accessibilityHint("Writes one credit on this hen")
        .animation(reduceMotion ? RoostRail.fade : RoostRail.motion, value: count)
        .animation(reduceMotion ? RoostRail.fade : RoostRail.motion, value: hen.role)
    }
}
