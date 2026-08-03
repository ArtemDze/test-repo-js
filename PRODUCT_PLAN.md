# Jestora — Product Plan (P1–P6)
# Locked decisions for implementation. Not shipped to users.

## 1. Product understanding (P1)
- Problem: Creators need a focused, offline tool to explore geometric pattern, symmetry, optical tension, and color harmony without pro-tool overhead or generative-AI opacity.
- Product type: Creative studio (immersive canvas + peripheral inspector).
- Audience: Mixed — curious hobbyists + designers who want precise, reproducible craft.
- Motivation: Daily micro-sessions of visual play; save/export finished compositions.
- Success moment: First balanced composition from symmetry + one accent, saved in under 2 minutes.
- Constraints: iOS 17+, SwiftUI, SwiftData, offline, no auth/ads/IAP, no gambling/Joker IP, broad-audience calm theatrical tone.
- Tone: Theatrical, intelligent, artistic, precise, slightly unpredictable — never childish or casino.

## 2. Assumptions
- Bundle stays in existing Xcode target `newFirstApp`; display name Jestora.
- “Profile” tab = local preferences/about (no accounts).
- Parametric generative Studio (deterministic seed engine) is primary; freehand drawing is out of scope for v1.
- Sample projects exist only in `#Preview` / PreviewContent — never seeded into production store.
- ShareLink export avoids Photos permission unless user chooses a system path that requires it.
- Haptics honor a user preference toggle.
- iPad uses NavigationSplitView / inspector sidebar; iPhone uses bottom tool rail + sheets.

## 3–4. Design DNA + personality (P3)
- Product: Jestora — Creative Pattern Studio
- Audience: mixed
- Promise: Turn geometric intuition into finished, exportable compositions — with reproducible craft.
- Domain: Creative
- Personality: Theatrical · Precise · Layered · Curious · Restrained
- Emotion: Inspired focus
- Visual thesis: Stage depth + layered paper + diamond/curve motifs + controlled asymmetry — recognizable in grayscale via silhouette & rhythm, not color.
- Motion thesis: Calm theatrical (curtain / align / spotlight) — not playful bounce.
- Layout thesis: Canvas-first; sparse chrome; inspector as supporting actor.
- Do: Prioritize artwork; semantic tokens; seed-reproducible generation.
- Don’t: Casino cues; DC/Joker likeness; card-grid dashboards; purple glass AI kits.
- Signature: Launch “fragment alignment” into Studio + live parameter echo on canvas.
- Elevations (≤2): (1) Focus Mode — chrome retreats to artwork. (2) Seed Lock — freeze seed while exploring other parameters.

## 5. Information architecture
Tabs: Studio | Experiments | Collection | Profile
- Studio: canvas + inspector + daily cue ribbon + focus/export/save
- Experiments: 5 interactive labs → Save as Project
- Collection: library grid/list, search/sort/filter, detail, reopen
- Profile: appearance, defaults, haptics, motion, export quality, a11y shortcuts, clear data, about

## 6. Main user journeys
1. First launch → alignment load → onboarding → Studio blank/parametric
2. Tweak params → see live canvas → save → Collection
3. Experiment → adjust → Save as Project → Studio refine → export
4. Daily cue → constrained Studio session
5. Return user → short/no load → last project or new
6. Failure → SwiftData/export errors with recovery actions

## 7. Screen map
LaunchAlignment · Onboarding(3) · Studio · ExportPreview · ExperimentsHome · SymmetryChamber · ContrastTheatre · ControlledChaos · MotionIllusion · ColorDuality · Collection · ProjectDetail · Profile/Settings · Confirmations/Toasts/Empty/Error

## 8. Visual system (P5)
Colors: ink bg · ivory surface · muted burgundy accent · antique gold highlight · desaturated teal secondary · semantic success/warning/danger/separator/fill
Type: system roles display/title/headline/body/callout/caption/footnote — tracking + small-caps motif labels
Space: 4/8/12/16/24/32/48 · Radius: control/container/sheet/motif · Motion tokens · Canvas metrics
Components: JSRPrimaryAction, JSRIconAction, JSRSectionLabel, JSRParameterSlider, JSRSegmentedControl, JSRInspectorGroup, JSRProjectThumbnail, JSRExperimentHeader, JSREmptyState, JSRToast, JSRConfirmationPanel, StageFrame

## 9. Motion language (P8)
Curtain reveal · fragment align · spotlight focus · paper shift · order↔asymmetry morph
Reduce Motion → opacity/instant. No slider haptics spam.

## 10. SwiftUI architecture (P6)
Feature folders · @Observable VMs · Environment deps · NavigationStack typed routes · PatternEngine pure · ProjectStore SwiftData · no logic in body · no AnyView · no singletons

## 11. File tree
App/ Core/ DesignSystem/ Models/ Services/ Features/{Launch,Onboarding,Studio,Experiments,Collection,Settings} Resources/ PreviewContent/ + JestoraTests/

## 12. Implementation plan
1) Wipe prior mismatched feature code 2) Tokens+components 3) Models+PatternEngine+tests 4) Launch/Onboarding 5) Studio vertical slice 6) Experiments 7) Collection 8) Profile 9) Motion/a11y 10) Review gate+build
