import SwiftUI

struct CalorieCalculatorView: View {

    // MARK: - Inputs
    enum Gender: String, CaseIterable, Identifiable { case weiblich, männlich, divers; var id: String { rawValue } }
    enum Units: String, CaseIterable, Identifiable { case metrisch, imperial; var id: String { rawValue } }
    enum Formula: String, CaseIterable, Identifiable {
        case auto = "Auto"
        case mifflin = "Mifflin-St Jeor"
        case harris = "Harris-Benedict (revidiert)"
        case katch = "Katch-McArdle"
        var id: String { rawValue }
    }
    enum Goal: String, CaseIterable, Identifiable {
        case halten = "Gewicht halten"
        case cut10 = "Abnehmen (-10 %)"
        case cut20 = "Abnehmen (-20 %)"
        case bulk10 = "Zunehmen (+10 %)"
        case bulk20 = "Zunehmen (+20 %)"
        var id: String { rawValue }

        var factor: Double {
            switch self {
            case .halten: return 1.0
            case .cut10: return 0.9
            case .cut20: return 0.8
            case .bulk10: return 1.1
            case .bulk20: return 1.2
            }
        }
    }

    // PAL-Auswahl (ohne Sport) – wie auf deiner Seite beschrieben :contentReference[oaicite:1]{index=1}
    struct PalOption: Identifiable {
        let id = UUID()
        let title: String
        let value: Double
    }
    let palOptions: [PalOption] = [
        .init(title: "Sehr sitzend (Büro, kaum Bewegung)", value: 1.2),
        .init(title: "Überwiegend sitzend (gelegentliches Gehen)", value: 1.35),
        .init(title: "Stehend/gehend (Einzelhandel, Service)", value: 1.55),
        .init(title: "Mäßig körperlich (Handwerk leicht)", value: 1.7),
        .init(title: "Körperlich anstrengend (Bau/Schicht)", value: 1.9),
        .init(title: "Sehr anstrengend (Tagesgeschäft körperlich)", value: 2.1),
    ]

    struct SportEntry: Identifiable, Codable {
        var id = UUID()
        var name: String = "Sport"
        var sessionsPerWeek: Int = 3
        var minutesPerSession: Int = 45
        var met: Double = 6.0   // grober MET-Wert, Nutzer kann anpassen
    }

    // MARK: - Persist (optional, lokal speichern/laden)
    @AppStorage("tdee_gender") private var sGender: String = Gender.weiblich.rawValue
    @AppStorage("tdee_units") private var sUnits: String = Units.metrisch.rawValue
    @AppStorage("tdee_age") private var age: Int = 30
    @AppStorage("tdee_height_cm") private var heightCm: Double = 170
    @AppStorage("tdee_weight_kg") private var weightKg: Double = 70
    @AppStorage("tdee_bodyfat") private var bodyFatPercent: Double = 0 // 0 = nicht angegeben
    @AppStorage("tdee_formula") private var sFormula: String = Formula.auto.rawValue
    @AppStorage("tdee_palIndex") private var palIndex: Int = 1
    @AppStorage("tdee_steps") private var stepsPerDay: Int = 5000
    @AppStorage("tdee_goal") private var sGoal: String = Goal.halten.rawValue
    @AppStorage("tdee_protein_gkg") private var proteinGPerKg: Double = 0 // optional

    @State private var sport: [SportEntry] = [
        SportEntry(name: "Training", sessionsPerWeek: 3, minutesPerSession: 45, met: 6.0)
    ]

    // MARK: - Derived enums
    private var gender: Gender { Gender(rawValue: sGender) ?? .weiblich }
    private var units: Units { Units(rawValue: sUnits) ?? .metrisch }
    private var formula: Formula { Formula(rawValue: sFormula) ?? .auto }
    private var goal: Goal { Goal(rawValue: sGoal) ?? .halten }

    // MARK: - Body
    var body: some View {
        Form {
            Section("1) Körperdaten") {
                Picker("Geschlecht", selection: $sGender) {
                    ForEach(Gender.allCases) { g in Text(g.rawValue).tag(g.rawValue) }
                }

                Stepper("Alter: \(age) Jahre", value: $age, in: 10...100)

                Picker("Einheiten", selection: $sUnits) {
                    Text("Metrisch (cm, kg)").tag(Units.metrisch.rawValue)
                    Text("Imperial (ft/in, lb)").tag(Units.imperial.rawValue)
                }

                if units == .metrisch {
                    HStack {
                        Text("Größe (cm)")
                        Spacer()
                        TextField("170", value: $heightCm, formatter: NumberFormatter.decimal)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Gewicht (kg)")
                        Spacer()
                        TextField("70", value: $weightKg, formatter: NumberFormatter.decimal)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                } else {
                    // simple imperial input: user enters ft/in and lb; we convert to cm/kg internally
                    ImperialInput(heightCm: $heightCm, weightKg: $weightKg)
                }

                HStack {
                    Text("Körperfett % (optional)")
                    Spacer()
                    TextField("z.B. 20", value: $bodyFatPercent, formatter: NumberFormatter.decimal)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                .help("Wenn gesetzt, kann Katch-McArdle genutzt werden.")

                Picker("BMR-Formel", selection: $sFormula) {
                    ForEach(Formula.allCases) { f in Text(f.rawValue).tag(f.rawValue) }
                }
            }

            Section("2) Alltagsaktivität (ohne Sport)") {
                Picker("Job/Alltag (PAL)", selection: $palIndex) {
                    ForEach(Array(palOptions.enumerated()), id: \.offset) { idx, opt in
                        Text(opt.title).tag(idx)
                    }
                }

                Stepper("Schritte: \(stepsPerDay) / Tag", value: $stepsPerDay, in: 0...30000, step: 500)
                Text("Hinweis: Schritte werden zusätzlich (ab 3.000/Tag) grob berücksichtigt.").font(.footnote).foregroundStyle(.secondary)
            }

            Section("3) Sport pro Woche") {
                ForEach($sport) { $entry in
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Aktivität", text: $entry.name)
                        Stepper("Einheiten/Woche: \(entry.sessionsPerWeek)", value: $entry.sessionsPerWeek, in: 0...14)
                        Stepper("Minuten/Einheit: \(entry.minutesPerSession)", value: $entry.minutesPerSession, in: 0...300, step: 5)
                        HStack {
                            Text("Intensität (MET)")
                            Spacer()
                            TextField("6.0", value: $entry.met, formatter: NumberFormatter.decimal)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                        Text("MET grob: Gehen 3–4, Joggen 7–10, Kraft 4–6.").font(.footnote).foregroundStyle(.secondary)
                    }
                }
                .onDelete { idxSet in sport.remove(atOffsets: idxSet) }

                Button {
                    sport.append(SportEntry(name: "Aktivität", sessionsPerWeek: 2, minutesPerSession: 30, met: 5.0))
                } label: {
                    Label("Aktivität hinzufügen", systemImage: "plus")
                }

                if !sport.isEmpty {
                    Button(role: .destructive) { sport.removeAll() } label: {
                        Label("Aktivitäten leeren", systemImage: "trash")
                    }
                }

                Text("Sport wird zusätzlich zum PAL addiert (keine Doppelzählung).").font(.footnote).foregroundStyle(.secondary)
            }

            Section("4) Ziel") {
                Picker("Ziel", selection: $sGoal) {
                    ForEach(Goal.allCases) { g in Text(g.rawValue).tag(g.rawValue) }
                }
                HStack {
                    Text("Protein-Ziel (g/kg) optional")
                    Spacer()
                    TextField("z.B. 1.6", value: $proteinGPerKg, formatter: NumberFormatter.decimal)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section("Ergebnis") {
                let result = compute()

                ResultRow(title: "BMR (Grundumsatz)", value: "\(Int(result.bmr)) kcal/Tag", subtitle: "Formel: \(result.formulaLabel)")
                ResultRow(title: "TDEE Erhaltung", value: "\(Int(result.tdee)) kcal/Tag", subtitle: "inkl. Schritte & Sport: \(Int(result.tdeeWithStepsAndSport)) kcal/Tag")
                ResultRow(title: "Ziel-Kalorien", value: "\(Int(result.target)) kcal/Tag", subtitle: goal.rawValue)

                if proteinGPerKg > 0 {
                    let proteinG = proteinGPerKg * max(weightKg, 1)
                    Text("Protein grob: \(Int(proteinG)) g/Tag").font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Kalorienrechner")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Calculation

    struct CalcResult {
        let bmr: Double
        let formulaLabel: String
        let tdee: Double
        let tdeeWithStepsAndSport: Double
        let target: Double
    }

    private func compute() -> CalcResult {
        let w = max(weightKg, 1)
        let h = max(heightCm, 1)
        let a = max(age, 10)

        // 1) BMR
        let chosenFormula: Formula = {
            if formula == .auto {
                if bodyFatPercent > 0 { return .katch }
                return .mifflin
            }
            return formula
        }()

        let bmr: Double = {
            switch chosenFormula {
            case .mifflin:
                // Mifflin-St Jeor
                // male: 10w + 6.25h - 5a + 5
                // female: 10w + 6.25h - 5a - 161
                // divers: neutraler Mittelwert (oder Nutzer kann Formel umstellen)
                let base = 10*w + 6.25*h - 5*Double(a)
                switch gender {
                case .männlich: return base + 5
                case .weiblich: return base - 161
                case .divers: return base - 78 // grob mittig
                }
            case .harris:
                // Harris-Benedict revidiert (vereinfacht)
                // male: 88.362 + 13.397w + 4.799h - 5.677a
                // female: 447.593 + 9.247w + 3.098h - 4.330a
                switch gender {
                case .männlich:
                    return 88.362 + 13.397*w + 4.799*h - 5.677*Double(a)
                case .weiblich:
                    return 447.593 + 9.247*w + 3.098*h - 4.330*Double(a)
                case .divers:
                    let m = 88.362 + 13.397*w + 4.799*h - 5.677*Double(a)
                    let f = 447.593 + 9.247*w + 3.098*h - 4.330*Double(a)
                    return (m+f)/2
                }
            case .katch, .auto:
                // Katch-McArdle: BMR = 370 + 21.6 * LBM(kg)
                // LBM = weight * (1 - BF)
                let bf = min(max(bodyFatPercent, 0), 60) / 100.0
                let lbm = w * (1 - bf)
                return 370 + 21.6 * lbm
            }
        }()

        // 2) PAL (ohne Sport)
        let pal = palOptions.indices.contains(palIndex) ? palOptions[palIndex].value : 1.35
        let tdeeBase = bmr * pal

        // 3) Steps extra (wie auf deiner Seite: grob 1 kcal/kg/km, 1400 Schritte/km; ab 3000/Tag) :contentReference[oaicite:2]{index=2}
        let stepsExtra = max(stepsPerDay - 3000, 0)
        let km = Double(stepsExtra) / 1400.0
        let kcalSteps = km * w * 1.0

        // 4) Sport (MET): kcal/min ≈ MET * 3.5 * kg / 200
        let kcalSportPerDay = sport.reduce(0.0) { acc, e in
            guard e.sessionsPerWeek > 0, e.minutesPerSession > 0, e.met > 0 else { return acc }
            let kcalPerMin = e.met * 3.5 * w / 200.0
            let weekly = kcalPerMin * Double(e.minutesPerSession) * Double(e.sessionsPerWeek)
            return acc + (weekly / 7.0)
        }

        let tdeeWithExtras = tdeeBase + kcalSteps + kcalSportPerDay
        let target = tdeeWithExtras * goal.factor

        return CalcResult(
            bmr: bmr,
            formulaLabel: chosenFormula.rawValue,
            tdee: tdeeBase,
            tdeeWithStepsAndSport: tdeeWithExtras,
            target: target
        )
    }
}

// MARK: - Small helper views

private struct ResultRow: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).bold()
                Spacer()
                Text(value).monospacedDigit()
            }
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct ImperialInput: View {
    @Binding var heightCm: Double
    @Binding var weightKg: Double

    @State private var ft: Int = 5
    @State private var inch: Int = 7
    @State private var lb: Double = 154

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Größe (ft/in)")
                Spacer()
                Stepper("\(ft) ft", value: $ft, in: 3...8)
                Stepper("\(inch) in", value: $inch, in: 0...11)
            }
            HStack {
                Text("Gewicht (lb)")
                Spacer()
                TextField("154", value: $lb, formatter: NumberFormatter.decimal)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }
            Button("In cm/kg übernehmen") {
                let totalInches = ft * 12 + inch
                heightCm = Double(totalInches) * 2.54
                weightKg = lb * 0.45359237
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - NumberFormatter helper
private extension NumberFormatter {
    static var decimal: NumberFormatter {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.decimalSeparator = Locale.current.decimalSeparator ?? ","
        nf.maximumFractionDigits = 2
        return nf
    }
}
