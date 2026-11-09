import SwiftUI
import StrandDesign
import StrandAnalytics
import WhoopStore

struct RecordedBloodPressure: Equatable {
    let systolic: Double
    let diastolic: Double
    let takenAt: Int
    let source: String
    static func latest(_ rows: [LabMarkerRow]) -> Self? {
        for sys in rows.filter({ $0.markerKey == LabBookProjection.bpSystolicKey }).sorted(by: { $0.takenAt > $1.takenAt }) {
            guard let systolic = sys.value, systolic.isFinite, systolic > 0, sys.unit == "mmHg",
                  let dia = rows.first(where: { $0.markerKey == LabBookProjection.bpDiastolicKey &&
                      $0.takenAt == sys.takenAt && $0.day == sys.day && $0.source == sys.source && $0.unit == "mmHg" }),
                  let diastolic = dia.value, diastolic.isFinite, diastolic > 0 else { continue }
            return .init(systolic: systolic, diastolic: diastolic, takenAt: sys.takenAt, source: sys.source)
        }
        return nil
    }
}

struct RecordedBloodPressureCard: View {
    @EnvironmentObject private var repo: Repository
    @Environment(\.dashboardIsActive) private var active
    @State private var reading: RecordedBloodPressure?
    var body: some View {
        NavigationLink(value: TabRoute.labBook) {
            NoopCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("BLOOD PRESSURE INSIGHTS").font(WhoopReferenceFont.label(13)).tracking(1)
                        Spacer(); Image(systemName: "chevron.right")
                    }
                    if let reading {
                        Text(String(format: "%.0f/%.0f mmHg", reading.systolic, reading.diastolic))
                            .font(WhoopReferenceFont.heading(30).bold())
                        Text(Date(timeIntervalSince1970: Double(reading.takenAt)).formatted(date: .abbreviated, time: .shortened))
                            .font(WhoopReferenceFont.body(11)).foregroundStyle(StrandPalette.textSecondary)
                        Text(verbatim: reading.source).font(WhoopReferenceFont.body(10))
                            .foregroundStyle(StrandPalette.textSecondary)
                    } else {
                        Text("Add a measured blood pressure reading")
                            .font(WhoopReferenceFont.heading(20))
                    }
                    Text("Recorded measurements from your Health Records. Woop does not generate WHOOP MG blood pressure estimates from heart rate.")
                        .font(WhoopReferenceFont.body(11)).foregroundStyle(StrandPalette.textSecondary)
                }
            }
        }.buttonStyle(.plain)
        .task(id: "\(repo.refreshSeq)|\(active)") {
            guard active, let store = await repo.storeHandle() else { return }
            let owner = repo.deviceId
            let rows = (try? await store.labMarkers(deviceId: owner, category: "bloodPressure")) ?? []
            guard !Task.isCancelled, owner == repo.deviceId else { return }
            reading = RecordedBloodPressure.latest(rows)
        }
    }
}
