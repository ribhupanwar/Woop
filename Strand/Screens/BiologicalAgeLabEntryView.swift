import SwiftUI
import StrandDesign
import StrandAnalytics

/// Separate, locally stored blood-biomarker biological-age estimate. This is not the activity-derived
/// AgeLess score and does not overwrite it.
struct BiologicalAgeSection: View {
    @EnvironmentObject private var profile: ProfileStore
    @State private var presentsEntry = false

    @AppStorage("biologicalAge.kdm.albumin") private var albumin = 0.0
    @AppStorage("biologicalAge.kdm.alp") private var alp = 0.0
    @AppStorage("biologicalAge.kdm.bun") private var bun = 0.0
    @AppStorage("biologicalAge.kdm.creatinine") private var creatinine = 0.0
    @AppStorage("biologicalAge.kdm.hba1c") private var hba1c = 0.0
    @AppStorage("biologicalAge.kdm.crp") private var crp = 0.0
    @AppStorage("biologicalAge.kdm.lymphocytes") private var lymphocytes = 0.0
    @AppStorage("biologicalAge.kdm.mcv") private var mcv = 0.0
    @AppStorage("biologicalAge.kdm.glucose") private var glucose = 0.0
    @AppStorage("biologicalAge.kdm.rdw") private var rdw = 0.0
    @AppStorage("biologicalAge.kdm.cholesterol") private var cholesterol = 0.0
    @AppStorage("biologicalAge.kdm.sbp") private var sbp = 0.0
    @AppStorage("biologicalAge.kdm.wbc") private var wbc = 0.0

    private var result: BiologicalAgeKDM.Result? {
        BiologicalAgeKDM.estimate(chronologicalAge: Double(profile.age), biomarkers: .init(
            albuminGdL: albumin, alkalinePhosphataseUL: alp, bloodUreaNitrogenMgDL: bun,
            creatinineMgDL: creatinine, hemoglobinA1cPct: hba1c, crpMgL: crp,
            lymphocytesPct: lymphocytes, meanCorpuscularVolumeFL: mcv, glucoseMgDL: glucose,
            redCellDistributionWidthPct: rdw, totalCholesterolMgDL: cholesterol,
            systolicBloodPressureMmHg: sbp, whiteBloodCellCount10e3PerUL: wbc))
    }

    var body: some View {
        Button { presentsEntry = true } label: {
            HStack(spacing: NoopMetrics.space3) {
                Image(systemName: "testtube.2")
                    .font(.title2)
                    .foregroundStyle(StrandPalette.agelessYoungDeep)
                    .frame(width: 42, height: 42)
                    .background(StrandPalette.agelessYoung.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Biological Age · KDM")
                        .font(StrandFont.subhead.weight(.semibold))
                        .foregroundStyle(StrandPalette.textPrimary)
                    if let result {
                        Text("\(result.biologicalAge.formatted(.number.precision(.fractionLength(1)))) years · \(result.ageAcceleration >= 0 ? "+" : "")\(result.ageAcceleration.formatted(.number.precision(.fractionLength(1)))) vs actual")
                            .font(StrandFont.footnote)
                            .foregroundStyle(StrandPalette.textSecondary)
                    } else {
                        Text("Add blood-test values to calculate")
                            .font(StrandFont.footnote)
                            .foregroundStyle(StrandPalette.textSecondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(StrandFont.caption)
                    .foregroundStyle(StrandPalette.textTertiary)
            }
            .padding(NoopMetrics.space4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { FrostedCardSurface(tint: StrandPalette.agelessYoungDeep, cornerRadius: NoopMetrics.cardRadius) }
            .clipShape(RoundedRectangle(cornerRadius: NoopMetrics.cardRadius, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: NoopMetrics.cardRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $presentsEntry) {
            NavigationStack { BiologicalAgeLabEntryView() }
                .tint(StrandPalette.agelessYoungDeep)
        }
    }
}

struct BiologicalAgeLabEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var profile: ProfileStore

    @AppStorage("biologicalAge.kdm.albumin") private var albumin = 0.0
    @AppStorage("biologicalAge.kdm.alp") private var alp = 0.0
    @AppStorage("biologicalAge.kdm.bun") private var bun = 0.0
    @AppStorage("biologicalAge.kdm.creatinine") private var creatinine = 0.0
    @AppStorage("biologicalAge.kdm.hba1c") private var hba1c = 0.0
    @AppStorage("biologicalAge.kdm.crp") private var crp = 0.0
    @AppStorage("biologicalAge.kdm.lymphocytes") private var lymphocytes = 0.0
    @AppStorage("biologicalAge.kdm.mcv") private var mcv = 0.0
    @AppStorage("biologicalAge.kdm.glucose") private var glucose = 0.0
    @AppStorage("biologicalAge.kdm.rdw") private var rdw = 0.0
    @AppStorage("biologicalAge.kdm.cholesterol") private var cholesterol = 0.0
    @AppStorage("biologicalAge.kdm.sbp") private var sbp = 0.0
    @AppStorage("biologicalAge.kdm.wbc") private var wbc = 0.0

    private var result: BiologicalAgeKDM.Result? {
        BiologicalAgeKDM.estimate(chronologicalAge: Double(profile.age), biomarkers: .init(
            albuminGdL: albumin, alkalinePhosphataseUL: alp, bloodUreaNitrogenMgDL: bun,
            creatinineMgDL: creatinine, hemoglobinA1cPct: hba1c, crpMgL: crp,
            lymphocytesPct: lymphocytes, meanCorpuscularVolumeFL: mcv, glucoseMgDL: glucose,
            redCellDistributionWidthPct: rdw, totalCholesterolMgDL: cholesterol,
            systolicBloodPressureMmHg: sbp, whiteBloodCellCount10e3PerUL: wbc))
    }

    var body: some View {
        Form {
            Section {
                Text("Enter the values exactly as printed on your lab report. Units are shown beside each test. All 13 markers are required; missing values are not guessed.")
                    .font(StrandFont.footnote)
                    .foregroundStyle(StrandPalette.textSecondary)
                LabeledContent("Chronological age", value: "\(profile.age) years")
                biomarkerField("Albumin", unit: "g/dL", value: $albumin)
                biomarkerField("Alkaline phosphatase", unit: "U/L", value: $alp)
                biomarkerField("Blood urea nitrogen (BUN)", unit: "mg/dL", value: $bun)
                biomarkerField("Creatinine", unit: "mg/dL", value: $creatinine)
                biomarkerField("HbA1c", unit: "%", value: $hba1c)
                biomarkerField("C-reactive protein (CRP)", unit: "mg/L", value: $crp)
                biomarkerField("Lymphocytes", unit: "%", value: $lymphocytes)
                biomarkerField("Mean corpuscular volume", unit: "fL", value: $mcv)
                biomarkerField("Glucose", unit: "mg/dL", value: $glucose)
                biomarkerField("Red cell distribution width", unit: "%", value: $rdw)
                biomarkerField("Total cholesterol", unit: "mg/dL", value: $cholesterol)
                biomarkerField("Systolic blood pressure", unit: "mmHg", value: $sbp)
                biomarkerField("White blood cell count", unit: "10³/µL", value: $wbc)
            } header: {
                Text("Blood biomarkers")
            }

            Section {
                if let result {
                    VStack(alignment: .leading, spacing: NoopMetrics.space2) {
                        Text("Biological Age")
                            .font(StrandFont.footnote)
                            .foregroundStyle(StrandPalette.textSecondary)
                        Text(result.biologicalAge.formatted(.number.precision(.fractionLength(1))) + " years")
                            .font(StrandFont.heroNumber)
                            .foregroundStyle(StrandPalette.textPrimary)
                        Text("Age acceleration: \(result.ageAcceleration >= 0 ? "+" : "")\(result.ageAcceleration.formatted(.number.precision(.fractionLength(1)))) years")
                            .font(StrandFont.subhead)
                            .foregroundStyle(StrandPalette.textSecondary)
                    }
                    .padding(.vertical, NoopMetrics.space2)
                } else {
                    Text("Complete all 13 valid biomarker values to calculate your KDM age.")
                        .font(StrandFont.footnote)
                        .foregroundStyle(StrandPalette.textSecondary)
                }
                Text("NHANES-derived KDM calibration. A research estimate, not a diagnosis or a universally accepted medical standard.")
                    .font(StrandFont.caption)
                    .foregroundStyle(StrandPalette.textTertiary)
            } header: {
                Text("Estimate")
            }
        }
        .navigationTitle("Biological Age")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Clear") { clearValues() }
            }
        }
    }

    private func biomarkerField(_ title: String, unit: String, value: Binding<Double>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("—", value: value, format: .number.precision(.fractionLength(0...3)))
                .multilineTextAlignment(.trailing)
                .frame(width: 104)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
            Text(unit)
                .font(StrandFont.caption)
                .foregroundStyle(StrandPalette.textTertiary)
                .frame(minWidth: 54, alignment: .leading)
        }
    }

    private func clearValues() {
        albumin = 0; alp = 0; bun = 0; creatinine = 0; hba1c = 0; crp = 0
        lymphocytes = 0; mcv = 0; glucose = 0; rdw = 0; cholesterol = 0; sbp = 0; wbc = 0
    }
}
