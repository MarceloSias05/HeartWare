# Entrega final: datos reales, onboarding y Apple Watch — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Entregar Hearthware completo (nombre, ícono, statement, summary, repo, TestFlight, frameworks) con datos reales en SwiftData, un onboarding que pide el nombre y deja escribir una meta propia ("Other"), y una app de Apple Watch que acompaña el paso y le pasa el pulso máximo y la recuperación al iPhone.

**Architecture:** SwiftData guarda dos modelos, `Profile` (uno solo) y `StepRecord` (uno por paso). `AppModel` recibe el `ModelContext`, expone lo que leen las vistas y es el único que inserta y guarda. `Coach` sigue siendo un conjunto de reglas puras sobre `[StepRecord]`. El Watch corre un `HKWorkoutSession` y manda un `WatchResult` por WatchConnectivity. El iPhone lo guarda en el `StepRecord`.

**Tech Stack:** SwiftUI, Observation, SwiftData, HealthKit, WatchConnectivity, WatchKit (hápticos), Swift Testing. iOS 27.2, watchOS 27.

**Spec:** no hay documento de spec. Este plan se basa en:
- la lista de entrega del Academy (App Name, App Icon, App Statement, App Summary Template, Git link, TestFlight link, Frameworks);
- lo que pidió Marcelo el 2026-11-23: opción "Other" con texto en las metas, el nombre en el onboarding, nada de datos de ejemplo y todo en SwiftData;
- el código actual (`StepFlowView`: "With you" stands in for the Apple Watch; `DoctorSummaryView` muestra "Not yet");
- el Sketch de Heartware (9 pantallas de Watch, que no se leyeron para este plan).

## Estado (actualizado 2026-11-23)

| Parte | Tarea | Estado |
|---|---|---|
| A | A1 Decisiones | ❌ Pendiente: nombre, statement, "Slow down", Signing |
| A | A2 TestFlight build 1 | ❌ Pendiente |
| A | A3 Repo, summary, frameworks | ❌ Pendiente (repo sigue privado) |
| B | B1 Target de tests | ⏭️ Saltada: los chequeos corren con `Checks/run.sh` (21 chequeos, todos pasan) |
| B | B2 SwiftData | ✅ Hecha: `6f1c805`, en `main` |
| B | B3 Onboarding nombre + "Other" | ✅ Hecha: `6bc62bd`, en `main` (falta probarla a mano en el simulador) |
| C | C1 WatchResult + recuperación | ✅ Hecha: `ed7e629` (rama `feat/apple-watch`) |
| C | C2 Target de watchOS | ✅ Hecha: target "HearthwareWatch Watch App" (Marcelo) + conexión (`ea05bcf`): HealthKit en los dos targets, textos de permiso, `workout-processing`, ícono. Los dos esquemas compilan |
| C | C3 Sesión en el Watch | 🟡 Compila en el target. No se ha corrido: no hay runtime de simulador de watchOS en la Mac, y el pulso real solo se prueba en un Watch |
| C | C4 iPhone ↔ Watch | 🟡 El lado del iPhone compila y tiene respaldo sin Watch (`9aca6cc`); falta probarlo con un Watch real |
| C | C5 TestFlight build 2 | ❌ Pendiente |
| C | C6 Datos de Apple Health en el resumen (pedido por Marcelo) | ✅ Hecha: `a137eec`. Corazón + movimiento/cansancio, "30 días antes de unirse" contra "últimos 7 días" con % de cambio; el preview del PDF quedó arreglado. Sin probar con datos reales de Salud |
| C | C7 PDF con sentido (pedido por Marcelo) | ✅ Hecha: `18c616f` en `feat/pdf-summary`. At a glance, miedo y escalón, síntomas guardados (antes la ayuda no guardaba nada) con aviso de una hora después, fechas de cada columna, varias páginas |
| C | C8 Gráficas en el PDF (Swift Charts) | ✅ Hecha: `1742520` en `feat/pdf-charts`. Página "Trends": miedo antes/después, pulso máximo por paso, y día por día de pasos, pulso en reposo, presión, HRV, velocidad al caminar y oxígeno, con línea del día en que se unió |
| C | C9 Párrafo para el doctor con Foundation Models | ✅ Hecha en `feat/pdf-charts`. Apple Intelligence en el iPhone escribe 3–4 frases solo con los datos del PDF; si no está disponible, no hay párrafo. Agregar **FoundationModels** y **Swift Charts** a la lista de Frameworks de la entrega |
| C | C10 Sentimiento con cara y slider (pedido por Marcelo) | ✅ Hecha en `feat/feeling-slider` (desde main). `FeelingPage`: cara que cambia de asustada a tranquila, fondo ámbar → menta, palabra grande, slider que se ajusta a 4 sentimientos, háptica y VoiceOver. Reemplaza la lista antes y después del paso |
| C | C11 Colores por sentimiento y notas | ✅ Hecha. Naranja, amarillo, verde y menta; "Add note" antes y después del paso, las notas salen en el PDF |
| C | C12 Onboarding: sentimiento inicial, condición sin preseleccionar, Apple Health | ✅ Hecha. 5 páginas; el sentimiento de hoy es el inicio de la tendencia de miedo; permiso de Salud explicado al final |

**Entregables hoy:**
- **App Name:** sin decidir (Heartware / Hearthware).
- **App Icon:** ✅ orbe teal en `Assets.xcassets/AppIcon.appiconset` (light, dark, tinted).
- **App Statement:** borrador en A1, sin aprobar.
- **App Summary Template:** ❌ falta llenarlo.
- **Git:** https://github.com/MarceloSias05/Hearthware (privado).
- **TestFlight:** ❌ falta.
- **Frameworks hoy:** SwiftUI, Observation, SwiftData, HealthKit, WatchConnectivity, WatchKit.

**Cambios respecto al plan original (decididos al implementar):**
- `AppModel.init(container: ModelContainer)` en vez de `init(context:)`, y la clase es `@MainActor`: un `ModelContext` no retiene a su contenedor, así que `ModelContainer.empty.mainContext` tronaba en el primer fetch. Previews y chequeos usan `AppModel(container: .empty)`.
- El resumen para el doctor y el PDF muestran también la meta ("Goal: <goalTitle>"), para que la meta escrita en "Other" sirva de algo.
- El botón pill se ve atenuado cuando está deshabilitado.
- Bundle ID actual: `com.marcelo.academy.Heartware`; team del target `N2TLVFPKL4`, pero el proyecto todavía dice `VWUWR4BNBX`. Hay que unificarlos antes de archivar.
- El texto ya no promete un Watch que no existe: sin Watch, el botón dice "Start your step" y `WithYouView` dice "Take it at your own pace".
- El iPhone abre la app del Watch con `HKHealthStore.startWatchApp` y le pasa el paso por application context. Cada paso tiene un id, y se ignora cualquier resultado o cancelación de otro paso.
- No hay "Slow down" automático: A1 sigue sin decidirse y el plan recomienda no avisar.
- `WatchResult.swift` vive en `Shared/`, con membresía de carpeta en `project.xcproj`. `WatchLink` vive en `Hearthware/Services/`.

## Global Constraints

- Sin datos de ejemplo: se borran `SampleData.swift`, el nombre fijo "Marco" y `AppModel.preview()`. Los previews usan un contenedor de SwiftData en memoria y vacío.
- Persistencia solo con SwiftData. Se borra `StateStore.swift` (UserDefaults) y no se migran datos, porque la app no tiene usuarios todavía.
- El paciente nunca ve números. El pulso y la recuperación solo salen en el resumen para el doctor.
- El rojo `hwRed` es solo para ayuda y emergencias. El teal `hwMint` (#00C2A8) es el color de marca.
- Si Reduce Motion está activo, el orbe no se anima.
- Sin Watch, sin permiso de HealthKit o sin conexión, el paso tiene que funcionar igual (el fallback es `WithYouView`).
- No inventar umbrales médicos: "Slow down" automático solo con la decisión explícita de A1.
- Los commits no llevan líneas de atribución a Claude.
- Para compilar desde la terminal: `export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.

## Review Focus

1. **Nombre vacío o solo espacios, o meta "Other" sin texto:** "Continue" se queda deshabilitado y nunca se guarda un `Profile` incompleto. → tests en B3.
2. **Matar la app justo después de registrar un paso:** el paso sigue ahí al relanzar, porque cada acción llama a `context.save()`. → test en B2 (contexto nuevo sobre el mismo contenedor) + prueba manual.
3. **El Watch no está emparejado o no responde:** el paso cae en `WithYouView` y se guarda sin pulso. → test en C1 (`log` con `watch: nil`) + prueba manual en C4.
4. **HealthKit denegado o el pulso nunca vuelve al basal:** los valores quedan en `nil` y el resumen dice "Not yet". → tests en C1.
5. **Se cierra la hoja del iPhone o la app del Watch a mitad del paso:** no queda ningún workout abierto ni se guarda un resultado a medias. → pruebas manuales en C3 y C4.

---

## Parte A — Entrega (lo hace Marcelo, sin código salvo A2)

### Task A1: Decisiones que bloquean

- [ ] **Nombre de la app:** Heartware (Sketch, decks) o Hearthware (Xcode).
- [ ] **App Statement:** aprobar o reescribir: *"For people recovering from a heart event who are afraid to move again, Heartware turns the life they want back into small, calm steps, using words, never numbers, and gives their doctor a clear summary of the progress."*
- [ ] **"Slow down" en el Watch:**
  - (a) Sin aviso automático: el Watch solo acompaña y mide (recomendado).
  - (b) Límite de pulso que escribe el paciente "según su doctor".
- [ ] **Team y bundle ID:** unificar el team (`N2TLVFPKL4` en el target, `VWUWR4BNBX` en el proyecto) y registrar `com.marcelo.academy.Heartware` en App Store Connect.

### Task A2: TestFlight build 1, para tener el link ya

El link público de TestFlight no cambia entre builds. Se puede hacer antes de la Parte B (con lo que hay hoy) o justo después de B3.

- [ ] **Step 1:** Poner `INFOPLIST_KEY_CFBundleDisplayName` = nombre de A1 en `Hearthware.xcodeproj/project.xcproj` (Debug y Release). Compilar → `BUILD SUCCEEDED`. Commit: `"Set display name"`.
- [ ] **Step 2:** En App Store Connect: crear la app (nombre, bundle ID, SKU `hearthware`).
- [ ] **Step 3:** En Xcode: Any iOS Device → Product → Archive → Distribute → TestFlight & App Store → Upload.
- [ ] **Step 4:** En TestFlight: grupo externo "Academy", Beta App Description, What to Test, Beta App Review y **Public Link**. Anotar el link aquí.

### Task A3: Repo, summary y frameworks

- [ ] **Step 1:** `gh repo edit MarceloSias05/Hearthware --visibility public --accept-visibility-change-consequences` (o invitar a los evaluadores).
- [ ] **Step 2:** Llenar el App Summary Template (Confluence o Dropbox) con lo de A1 y A2.
- [ ] **Step 3:** Frameworks finales: SwiftUI, Observation, SwiftData, HealthKit, WatchConnectivity y WatchKit (quitar los de la Parte C si no llega).

---

## Parte B — Datos reales y onboarding

### Task B1: Target de tests con Swift Testing (⏭️ saltada por ahora)

Mientras no exista el target, todo test de este plan va en `Checks/main.swift` y se corre con `Checks/run.sh` (Expected: `all checks OK`).


**Files:**
- Create (Xcode UI): target `HearthwareTests` (Unit Testing Bundle, Swift Testing), host app Hearthware.
- Create: `HearthwareTests/CoachTests.swift`
- Delete: `Checks/main.swift`, `Checks/run.sh`

- [ ] **Step 1:** File → New → Target → Unit Testing Bundle, testing system Swift Testing.
- [ ] **Step 2:** Pasar a `@Test` los chequeos de `Checks/main.swift` que no dependen de datos de ejemplo ni de UserDefaults: `nextStepStartsAtFirstRung`, `nextStepClimbsOnlyOnCalmSteps`, `nextStepCapsAtLastRung`, `dayStateWithoutRecords`, `dayStateAfterHardStep`, `fearShrinksWhenLastBeforeIsLower` (dos records creados en el test: `.veryScared` y luego `.calm`), `fearNotShrinkingWithOneRecord`.
- [ ] **Step 3:** `xcodebuild test -project Hearthware.xcodeproj -scheme Hearthware -destination 'platform=iOS Simulator,name=iPhone 17'` → `** TEST SUCCEEDED **`, 7 tests.
- [ ] **Step 4:** Borrar `Checks/`. Commit: `"Move checks to Swift Testing target"`.

### Task B2: SwiftData (✅ hecha, `6f1c805`)

**Files:**
- Modify: `Hearthware/Domain/StepRecord.swift` (de struct a `@Model`)
- Create: `Hearthware/Domain/Profile.swift`
- Modify: `Hearthware/Data/AppModel.swift`
- Modify: `Hearthware/App/HearthwareApp.swift`
- Create: `Hearthware/Data/PreviewContainer.swift`
- Delete: `Hearthware/Data/StateStore.swift`, `Hearthware/Data/SampleData.swift`
- Modify: todas las vistas que usan `AppModel.preview(...)` y `TodayView` y `DoctorSummaryView` (el nombre)
- Test: `HearthwareTests/AppModelTests.swift`

**Interfaces:**
- Produces:
  - `@Model final class StepRecord { var id: UUID; var date: Date; var title: String; var before: Feeling; var after: Feeling; var peakHeartRate: Int?; var recoverySeconds: Int?; init(date: Date, title: String, before: Feeling, after: Feeling, peakHeartRate: Int? = nil, recoverySeconds: Int? = nil) }`. Las vistas que usan `ForEach(records)` siguen funcionando porque `@Model` es `Identifiable`.
  - `@Model final class Profile { var name: String; var goal: Goal; var customGoal: String?; var condition: HeartCondition; var createdAt: Date }` y `var goalTitle: String`, que devuelve `customGoal` si `goal == .other` y si no `goal.title`.
  - `AppModel.init(container: ModelContainer)` (`@MainActor`). Lee el `Profile` y los `StepRecord` ordenados por `date` ascendente.
  - `AppModel`: `private(set) var profile: Profile?`, `private(set) var records: [StepRecord]`, `var hasOnboarded: Bool { profile != nil }`, `var name: String { profile?.name ?? "" }`, `var goal: Goal?`, `var condition: HeartCondition?`. `todayStep`, `todayState`, `fearIsShrinking` y `explanation(for:)` no cambian.
  - `func completeOnboarding(name: String, goal: Goal, customGoal: String?, condition: HeartCondition)` y `@discardableResult func log(title: String, before: Feeling, after: Feeling) -> StepRecord`. Las dos insertan, llaman a `save()` y vuelven a leer.
  - `private func save()`: `try context.save()`; en el `catch`, `assertionFailure` con el error.
  - `extension ModelContainer { @MainActor static var empty: ModelContainer }` en `PreviewContainer.swift`: un contenedor en memoria (`isStoredInMemoryOnly: true`) para previews y tests.
- `HearthwareApp`: `.modelContainer(for: [Profile.self, StepRecord.self])` y `AppModel(container: container)` en `@State`.

- [x] **Step 1: Tests que fallan**

```swift
@MainActor @Test func startsEmpty() {
    let m = AppModel(container: .empty)
    #expect(!m.hasOnboarded && m.records.isEmpty && m.name == "")
}
@MainActor @Test func onboardingCreatesProfile() {
    let m = AppModel(container: .empty)
    m.completeOnboarding(name: "Ana", goal: .market, customGoal: nil, condition: .surgery)
    #expect(m.hasOnboarded && m.name == "Ana" && m.condition == .surgery)
}
@MainActor @Test func stepSurvivesNewContext() {
    let c = ModelContainer.empty
    AppModel(container: c).log(title: "Walk", before: .nervous, after: .calm)
    #expect((try? ModelContext(c).fetch(FetchDescriptor<StepRecord>()))?.map(\.title) == ["Walk"])
}
@MainActor @Test func recordsAreOldestFirst() {
    let m = AppModel(container: .empty)
    m.log(title: "a", before: .calm, after: .calm); m.log(title: "b", before: .calm, after: .calm)
    #expect(m.records.map(\.title) == ["a", "b"])
}
```

- [x] **Step 2:** Correr → FAIL (`AppModel(context:)` no existe).
- [x] **Step 3:** Implementar las interfaces de arriba, borrar `StateStore.swift` y `SampleData.swift`, y cambiar los previews a `.environment(AppModel(container: .empty))`. `TodayView` saluda "Good morning,\n\(model.name)".
- [x] **Step 4:** Correr → PASS (11 tests). Compilar → `BUILD SUCCEEDED`. `grep -rn "Marco\|sample\|preview(" Hearthware` no devuelve nada.
- [ ] **Step 5:** En el simulador: hacer el onboarding, registrar un paso, matar la app y relanzarla; el paso sigue en la Story.
- [x] **Step 6:** Commit: `"Persist profile and steps with SwiftData, remove sample data"`.

### Task B3: Onboarding con nombre y meta "Other" (✅ hecha, `6bc62bd`)

**Files:**
- Modify: `Hearthware/Domain/Goal.swift` (`case other`)
- Modify: `Hearthware/Features/Onboarding/OnboardingView.swift`
- Create: `Hearthware/Domain/OnboardingInput.swift`
- Test: `HearthwareTests/OnboardingInputTests.swift`

**Interfaces:**
- Produces:
  - `Goal.other`: `title` = "Something else". Sus `steps` (texto propuesto, Marcelo lo puede cambiar):
    - "Try it for a few minutes" / "Stop whenever you want."
    - "Do it a little longer" / "Rest whenever you need to."
    - "Do it like before" / "Take someone with you the first time."
  - `struct OnboardingInput { var name = ""; var goal: Goal = .stairs; var customGoal = ""; var condition: HeartCondition = .heartAttack; var trimmedName: String; var trimmedCustomGoal: String?; var nameIsValid: Bool; var goalIsValid: Bool }`:
    - `trimmedName` quita espacios y saltos de línea en las orillas.
    - `nameIsValid` es true si `trimmedName` tiene entre 1 y 40 caracteres.
    - `trimmedCustomGoal` es nil salvo cuando `goal == .other`; entonces es el texto recortado o nil si queda vacío.
    - `goalIsValid` es `goal != .other || trimmedCustomGoal != nil`.
- Flujo: welcome → "1 of 3" **What should we call you?** (`TextField`, `.textContentType(.givenName)`, `.submitLabel(.continue)`) → "2 of 3" metas (al elegir "Something else" aparece debajo un `TextField` con el placeholder "What do you want to get back to?") → "3 of 3" condición. "Continue" se deshabilita (`.disabled`) mientras el paso no es válido.
- `QuestionPage` gana `var buttonDisabled: Bool = false` (`DesignSystem/QuestionPage.swift`).
- Donde la app muestre la meta, usar `profile.goalTitle`, no `goal.title`.

- [x] **Step 1: Tests que fallan**

```swift
@Test func blankNameIsInvalid() { #expect(!OnboardingInput(name: "   ").nameIsValid) }
@Test func nameIsTrimmed() { #expect(OnboardingInput(name: "  Ana \n").trimmedName == "Ana") }
@Test func longNameIsInvalid() { #expect(!OnboardingInput(name: String(repeating: "a", count: 41)).nameIsValid) }
@Test func otherGoalNeedsText() { #expect(!OnboardingInput(goal: .other, customGoal: "  ").goalIsValid) }
@Test func otherGoalKeepsTrimmedText() { #expect(OnboardingInput(goal: .other, customGoal: " Gardening ").trimmedCustomGoal == "Gardening") }
@Test func listedGoalIgnoresText() { #expect(OnboardingInput(goal: .market, customGoal: "x").trimmedCustomGoal == nil) }
@Test func otherGoalHasGenericLadder() { #expect(Goal.other.steps.first?.title == "Try it for a few minutes") }
```

- [x] **Step 2:** Correr → FAIL.
- [x] **Step 3:** Implementar `OnboardingInput`, `Goal.other` y las pantallas. `finish()` llama a `model.completeOnboarding(name: input.trimmedName, goal: input.goal, customGoal: input.trimmedCustomGoal, condition: input.condition)`.
- [x] **Step 4:** Correr → PASS (18 tests).
- [ ] **Step 5:** En el simulador, con VoiceOver y Dynamic Type XXL: el campo de nombre tiene etiqueta, el teclado no tapa "Continue" y con "Something else" + "Gardening" el resumen y la Story muestran "Gardening".
- [ ] **Step 6:** El nombre escrito sale en todas partes: `grep -rn "model.name\|profile.name" Hearthware` lista Today ("Good morning, <name>"), `DoctorSummaryView` y `DoctorPDFPage`. Exportar el PDF del resumen y confirmar que el encabezado dice el nombre del onboarding.
- [x] **Step 7:** Commit: `"Onboarding asks for name and allows a custom goal"`.

---

## Parte C — Apple Watch

### Task C1: Resultado del Watch en el dominio

**Files:**
- Create: `Hearthware/Domain/WatchResult.swift` (solo Foundation; se comparte con el Watch)
- Modify: `Hearthware/Data/AppModel.swift` (`log`)
- Test: `Checks/main.swift` (o `HearthwareTests/WatchResultTests.swift` si B1 ya existe)

**Interfaces:**
- Produces:
  - `struct WatchResult: Codable, Equatable { var peakHeartRate: Int?; var recoverySeconds: Int? }`
  - `enum Recovery { static let window: TimeInterval = 120; static let margin: Double = 10; static func seconds(baseline: Double, endedAt: Date, samples: [(date: Date, bpm: Double)]) -> Int? }`: segundos desde `endedAt` hasta la primera muestra posterior con `bpm <= baseline + margin`. Es `nil` si no hay ninguna dentro de `window`.
  - `AppModel.log(title:before:after:watch: WatchResult? = nil) -> StepRecord`

- [ ] **Step 1: Tests que fallan**

```swift
@Test func recoveryFirstSampleBackNearBaseline() {
    let end = Date(timeIntervalSince1970: 0)
    #expect(Recovery.seconds(baseline: 80, endedAt: end, samples: [(end + 30, 120), (end + 65, 88), (end + 90, 80)]) == 65)
}
@Test func recoveryNilWhenNeverBackInWindow() {
    let end = Date(timeIntervalSince1970: 0)
    #expect(Recovery.seconds(baseline: 80, endedAt: end, samples: [(end + 60, 110), (end + 130, 82)]) == nil)
}
@Test func recoveryIgnoresSamplesBeforeEnd() {
    let end = Date(timeIntervalSince1970: 100)
    #expect(Recovery.seconds(baseline: 80, endedAt: end, samples: [(end - 5, 81), (end + 40, 85)]) == 40)
}
@MainActor @Test func logStoresWatchValues() {
    let r = AppModel(container: .empty)
        .log(title: "t", before: .nervous, after: .calm, watch: WatchResult(peakHeartRate: 112, recoverySeconds: 65))
    #expect(r.peakHeartRate == 112 && r.recoverySeconds == 65)
}
@MainActor @Test func logWithoutWatchLeavesNil() {
    let r = AppModel(container: .empty).log(title: "t", before: .nervous, after: .calm)
    #expect(r.peakHeartRate == nil && r.recoverySeconds == nil)
}
```

- [ ] **Step 2:** Correr → FAIL.
- [ ] **Step 3:** Implementar.
- [ ] **Step 4:** `Checks/run.sh` → `all checks OK` (26 chequeos). Commit: `"Add WatchResult and recovery rule"`.

### Task C2: Target de watchOS con HealthKit

**Files:**
- Create (Xcode UI): target `HearthwareWatch` (watchOS App, companion), carpeta `HearthwareWatch/`.
- Modify (Xcode UI): agregar `Hearthware/Domain/WatchResult.swift` al target del Watch. El Watch no usa SwiftData: el iPhone es el dueño de los datos.
- Modify (Xcode UI): capability HealthKit en los dos targets; Background Modes → Workout Processing en el Watch.
- Info keys (los dos targets): `NSHealthShareUsageDescription` = "Hearthware reads your heart rate during a step so your doctor can see how your heart responded.", `NSHealthUpdateUsageDescription` = "Hearthware saves each step as a walking workout in Health."

- [ ] **Step 1:** File → New → Target → watchOS → App, embebido en Hearthware.
- [ ] **Step 2:** Agregar capabilities, Info keys, `WatchResult.swift` y el AppIcon de 1024.
- [ ] **Step 3:** Compilar `-scheme Hearthware` y `-scheme HearthwareWatch -destination 'generic/platform=watchOS Simulator'` → `BUILD SUCCEEDED`.
- [ ] **Step 4:** Commit: `"Add watchOS target with HealthKit"`.

### Task C3: Sesión de paso en el Watch

**Files:**
- Create: `HearthwareWatch/StepWorkout.swift`, `HearthwareWatch/WatchStepView.swift`, `HearthwareWatch/WatchOrb.swift`
- Modify (Xcode UI): agregar `Hearthware/Domain/Recovery` al target del Watch. Si `Recovery` vive en `WatchResult.swift`, ya está.

**Interfaces:**
- Consumes: `WatchResult`, `Recovery.seconds` (C1).
- Produces: `@Observable final class StepWorkout { enum Phase { case idle, moving, resting }; var phase: Phase; var title: String; func start(title: String) async; func endStep(); func doneResting(); func cancel(); var onFinish: ((WatchResult) -> Void)? }`

Comportamiento:
- `start`: pide permiso de HealthKit (leer heartRate, escribir workout) y arranca `HKWorkoutSession(.walking, .indoor)` con `HKLiveWorkoutBuilder`. El basal es la primera muestra. Si se niega el permiso, sigue igual pero sin datos.
- `.moving`: guarda el pico y da `WKInterfaceDevice.current().play(.click)` cada 60 s.
- `endStep`: pasa a `.resting`, que dura hasta `Recovery.window` o hasta `doneResting()`. Después termina el workout, arma el `WatchResult`, llama a `onFinish` y vuelve a `.idle`.
- `cancel`: termina el workout sin `onFinish`.
- Al lanzar: `recoverActiveWorkoutSession` y, si hay una sesión huérfana, terminarla.
- "Slow down" solo si A1 eligió (b).
- Copy, sin números en pantalla: `.moving` → "You're doing well" / "Stop anytime." + "End step"; `.resting` → "Rest and breathe" / "Your heart is settling." + "Done resting"; `.idle` → "Start a step from your iPhone".

- [ ] **Step 1:** Implementar, con un botón de debug que llame a `start`.
- [ ] **Step 2:** En el simulador: start → end → done; `onFinish` recibe `WatchResult(peakHeartRate: nil, recoverySeconds: nil)`.
- [ ] **Step 3:** En un Watch real: caminar 2 min y descansar; el pico y la recuperación tienen sentido y el workout aparece en Salud.
- [ ] **Step 4:** Matar la app a mitad del paso y relanzarla: no queda ningún workout abierto.
- [ ] **Step 5:** Commit: `"Watch step session with HealthKit workout"`.

### Task C4: iPhone ↔ Watch

**Files:**
- Create: `Hearthware/Data/WatchLink.swift` (iOS), `HearthwareWatch/PhoneLink.swift` (watchOS)
- Modify: `Hearthware/App/HearthwareApp.swift` (crear `WatchLink` y pasarlo con `.environment`)
- Modify: `Hearthware/Features/Step/StepFlowView.swift` (fase `.onWatch`, los comentarios de "stands in" y el texto del botón)

**Interfaces:**
- Mensajes:
  - iPhone → Watch: `["kind": "start", "title": String]` y `["kind": "cancel"]`.
  - Watch → iPhone: `["kind": "result", "result": Data]` (`WatchResult` en JSON). Si no hay alcance, usar `transferUserInfo`.
- Produces: `@Observable final class WatchLink { var isReachable: Bool; func start(title: String) -> Bool; func cancel(); var onResult: ((WatchResult) -> Void)? }`

Flujo en `StepFlowView`:
- Con el Watch al alcance, el botón dice "Start on Apple Watch" y lleva a `.onWatch` ("Follow your Watch", orbe en calma).
- Sin el Watch, el botón dice "Start your step" y lleva a `WithYouView`.
- `onResult` guarda el resultado en `@State` y pasa a `.after`. "See what your body did" llama a `log(..., watch:)`.
- Cerrar la hoja en `.onWatch` llama a `cancel()`.

- [ ] **Step 1:** Implementar.
- [ ] **Step 2:** iPhone y Watch reales: paso completo; la Story muestra el paso y el resumen para el doctor muestra pulso y recuperación.
- [ ] **Step 3:** Watch apagado: `WithYouView`; el resumen dice "Not yet".
- [ ] **Step 4:** Cerrar la hoja a mitad del paso: el Watch vuelve a idle, sin workout abierto.
- [ ] **Step 5:** Tests → PASS. Commit: `"Connect iPhone step flow to Watch"`.

### Task C5: TestFlight build 2 con Watch

- [ ] **Step 1:** Subir el build number, archivar y subir (como en A2). La app del Watch va dentro del build de iOS.
- [ ] **Step 2:** What to Test: "Set up your profile, then take a step from Today with your Apple Watch on. Afterwards the doctor summary shows your heart rate."
- [ ] **Step 3:** Revisar la lista de frameworks (A3) y hacer push a `main`.
