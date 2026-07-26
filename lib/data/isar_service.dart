import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../services/notification_service.dart';
import '../utils/daily_stats.dart';
import '../utils/workout_stats_data.dart';
import 'models/exercise_badge.dart';
import 'models/exercise_schema.dart';
import 'models/workout_log.dart';
import 'models/workout_plan.dart';

class IsarService {
  late final Isar _isar;
  IsarService._internal();

  static final IsarService _instance = IsarService._internal();
  static IsarService get instance => _instance;

  Isar get db => _isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();

    _isar = await Isar.open(
      [
        ExerciseSchemaSchema,
        WorkoutPlanSchema,
        ExerciseBadgeSchema,
        WorkoutLogSchema,
      ],
      directory: dir.path,
    );

    await _seedExercisesIfNeeded();
    await _seedBadgesIfNeeded();
  }

  Future<ExerciseSchema?> getExerciseById(String exerciseId) async {
    return await _isar.exerciseSchemas
        .filter()
        .exerciseIdEqualTo(exerciseId)
        .findFirst();
  }

  Future<List<ExerciseSchema>> getAllExercises() async {
    return await _isar.exerciseSchemas.where().findAll();
  }

  Future<void> _seedExercisesIfNeeded() async {
    final count = await _isar.exerciseSchemas.count();

    //if (count > 0) return;

    final List<ExerciseSchema> defaultExercises = [
      ExerciseSchema()
        ..exerciseId = "1"
        ..title = "Genoflexiuni (Squats)"
        ..description = "Antrenament pentru picioare și fesieri. Monitorizare unghi genunchi."
        ..iconName = "airline_seat_legroom_normal"
        ..accentColorHex = 0xFF448AFF // Colors.blueAccent
        ..requiresLandscape = false
        ..isTimerBased = false
        ..sideStrategy = "DYNAMIC_BEST_SIDE"
        ..requiredLandmarks = ["hip", "knee", "ankle"]
        ..fallbackFeedback = "Poziționează-te din profil.\nAparatul nu vede tot piciorul."
        ..trackingType = "REPETARI_SIMPLE"
        ..geometries = [
          GeometryConfig()
            ..id = "unghi_genunchi"
            ..type = "ANGLE"
            ..inputPoints = ["hip", "knee", "ankle"]
            ..invertXOnRightSide = false
        ]
        ..transitions = [
          TransitionRule()
            ..fromState = "UP"
            ..toState = "DOWN"
            ..geometryId = "unghi_genunchi"
            ..operatorType = "LESS_THAN"
            ..thresholdMin = 110.0
            ..thresholdMax = 0.0
            ..action = "NONE"
            ..feedback = "Coboară controlat..."
            ..gateGeometryId = null
            ..gateOperatorType = null
            ..gateThreshold = null,
          TransitionRule()
            ..fromState = "DOWN"
            ..toState = "UP"
            ..geometryId = "unghi_genunchi"
            ..operatorType = "GREATER_THAN"
            ..thresholdMin = 160.0
            ..thresholdMax = 0.0
            ..action = "INCREMENT"
            ..feedback = "Repetare completă!"
            ..gateGeometryId = null
            ..gateOperatorType = null
            ..gateThreshold = null
        ]
        ..warnings = [],
      ExerciseSchema()
        ..exerciseId = "2"
        ..title = "Flexii Biceps - Braț Stâng"
        ..description = "Antrenament pentru brațe. Monitorizare unghi cot și fază de contracție."
        ..iconName = "fitness_center_outlined"
        ..accentColorHex = 0xFFFFC107 // Colors.amber
        ..requiresLandscape = false
        ..isTimerBased = false
        ..sideStrategy = "LEFT_ONLY"
        ..requiredLandmarks = ["shoulder", "elbow", "wrist"]
        ..fallbackFeedback = "Stai cu fața la cameră.\nAsigură-te că brațul Stâng este vizibil."
        ..trackingType = "REPETARI_SIMPLE"
        ..geometries = [
          GeometryConfig()
            ..id = "unghi_cot"
            ..type = "ANGLE"
            ..inputPoints = ["shoulder", "elbow", "wrist"]
            ..invertXOnRightSide = false
        ]
        ..transitions = [
          TransitionRule()
            ..fromState = "DOWN"
            ..toState = "UP"
            ..geometryId = "unghi_cot"
            ..operatorType = "LESS_THAN"
            ..thresholdMin = 35.0
            ..thresholdMax = 0.0
            ..action = "NONE"
            ..feedback = "Strânge bicepsul! Coboară încet..."
            ..gateGeometryId = null
            ..gateOperatorType = null
            ..gateThreshold = null,
          TransitionRule()
            ..fromState = "UP"
            ..toState = "DOWN"
            ..geometryId = "unghi_cot"
            ..operatorType = "GREATER_THAN"
            ..thresholdMin = 160.0
            ..thresholdMax = 0.0
            ..action = "INCREMENT"
            ..feedback = "Repetare completă! Menține controlul."
            ..gateGeometryId = null
            ..gateOperatorType = null
            ..gateThreshold = null
        ]
        ..warnings = [
          WarningRule()
            ..geometryId = "unghi_cot"
            ..operatorType = "OUTSIDE_INTERVAL" // Avertizează dacă în starea UP (când coboară) rămâne blocat la jumătate
            ..thresholdMin = 90.0
            ..thresholdMax = 130.0
            ..activeInState = "UP"
            ..warningMessage = "⚠️ Întinde brațul complet în poziția de jos!"
        ],
      ExerciseSchema()
        ..exerciseId = "3"
        ..title = "Flexii Biceps - Braț Drept"
        ..description = "Antrenament pentru brațe. Monitorizare unghi cot și fază de contracție."
        ..iconName = "fitness_center_outlined"
        ..accentColorHex = 0xFFFF6E40 // Colors.deepOrangeAccent
        ..requiresLandscape = false
        ..isTimerBased = false
        ..sideStrategy = "RIGHT_ONLY"
        ..requiredLandmarks = ["shoulder", "elbow", "wrist"]
        ..fallbackFeedback = "Stai cu fața la cameră.\nAsigură-te că brațul Drept este vizibil."
        ..trackingType = "REPETARI_SIMPLE"
        ..geometries = [
          GeometryConfig()
            ..id = "unghi_cot"
            ..type = "ANGLE"
            ..inputPoints = ["shoulder", "elbow", "wrist"]
            ..invertXOnRightSide = false
        ]
        ..transitions = [
          TransitionRule()
            ..fromState = "DOWN"
            ..toState = "UP"
            ..geometryId = "unghi_cot"
            ..operatorType = "LESS_THAN"
            ..thresholdMin = 35.0
            ..thresholdMax = 0.0
            ..action = "NONE"
            ..feedback = "Strânge bicepsul! Coboară încet..."
            ..gateGeometryId = null
            ..gateOperatorType = null
            ..gateThreshold = null,
          TransitionRule()
            ..fromState = "UP"
            ..toState = "DOWN"
            ..geometryId = "unghi_cot"
            ..operatorType = "GREATER_THAN"
            ..thresholdMin = 160.0
            ..thresholdMax = 0.0
            ..action = "INCREMENT"
            ..feedback = "Repetare completă! Menține controlul."
            ..gateGeometryId = null
            ..gateOperatorType = null
            ..gateThreshold = null
        ]
        ..warnings = [
          WarningRule()
            ..geometryId = "unghi_cot"
            ..operatorType = "OUTSIDE_INTERVAL"
            ..thresholdMin = 90.0
            ..thresholdMax = 130.0
            ..activeInState = "UP"
            ..warningMessage = "⚠️ Întinde brațul complet în poziția de jos!"
        ],
      // --- 4. Jumping Jacks ---
      ExerciseSchema()
        ..exerciseId = "4"
        ..title = "Jumping Jacks"
        ..description = "Antrenament cardio excelent pentru tot corpul. Monitorizare coordonate mâini și picioare."
        ..iconName = "sports_gymnastics"
        ..accentColorHex = 0xFF69F0AE // Colors.greenAccent
        ..requiresLandscape = false
        ..isTimerBased = false
        ..sideStrategy = "FULL_BODY" // Necesită vizibilitatea ambelor laturi ale corpului
        ..requiredLandmarks = ["leftShoulder", "rightShoulder", "leftWrist", "rightWrist", "leftAnkle", "rightAnkle"]
        ..fallbackFeedback = "Poziționează-te cu fața la cameră.\nAparatul trebuie să îți vadă tot corpul."
        ..trackingType = "REPETARI_COMPLEXE"
        ..geometries = [
          // 1. Distanța relativă dintre glezne raportată la umeri (Legs Open Ratio)
          GeometryConfig()
            ..id = "distanta_picioare_procent"
            ..type = "DISTANCE_RATIO" // Calculează distanța (leftAnkle <-> rightAnkle) / (leftShoulder <-> rightShoulder)
            ..inputPoints = ["leftAnkle", "rightAnkle", "leftShoulder", "rightShoulder"]
            ..invertXOnRightSide = false,

          // 2. Poziția pe axa Y a mâinii stângi față de umărul stâng (Negativ înseamnă Mâna mai sus ca umărul)
          GeometryConfig()
            ..id = "maini_sus_stanga"
            ..type = "VERTICAL_DISTANCE"
            ..inputPoints = ["leftWrist", "leftShoulder"] // wrist.y - shoulder.y
            ..invertXOnRightSide = false,

          // 3. Poziția pe axa Y a mâinii drepte față de umărul drept
          GeometryConfig()
            ..id = "maini_sus_dreapta"
            ..type = "VERTICAL_DISTANCE"
            ..inputPoints = ["rightWrist", "rightShoulder"] // wrist.y - shoulder.y
            ..invertXOnRightSide = false
        ]
        ..transitions = [
          // Trecerea în starea OPEN (mâinile sunt sus ȘI picioarele sunt depărtate)
          // Pragul de 1.3 înseamnă 130% din lățimea umerilor
          TransitionRule()
            ..fromState = "CLOSED"
            ..toState = "OPEN"
            ..geometryId = "distanta_picioare_procent"
            ..operatorType = "GREATER_THAN"
            ..thresholdMin = 1.3
            ..thresholdMax = 0.0
            ..action = "NONE"
            ..feedback = "Sari și adu picioarele la loc!"
            ..gateGeometryId = "maini_sus_stanga" // Mâna stângă trebuie să fie deasupra umărului (y mai mic în coordonate ecran)
            ..gateOperatorType = "LESS_THAN"
            ..gateThreshold = 0.0, // wrist.y - shoulder.y < 0

          // Trecerea în starea CLOSED și contorizarea repetării (mâinile jos ȘI picioarele apropiate)
          TransitionRule()
            ..fromState = "OPEN"
            ..toState = "CLOSED"
            ..geometryId = "distanta_picioare_procent"
            ..operatorType = "LESS_THAN"
            ..thresholdMin = 1.3
            ..thresholdMax = 0.0
            ..action = "INCREMENT"
            ..feedback = "Repetare completă! Continuă ritmul."
            ..gateGeometryId = "maini_sus_stanga"
            ..gateOperatorType = "GREATER_THAN"
            ..gateThreshold = 0.0 // Mâinile au coborât sub nivelul umerilor
        ]
        ..warnings = [],
      // --- 5. Flotări (Push-ups) ---
      ExerciseSchema()
        ..exerciseId = "5"
        ..title = "Flotări (Push-ups)"
        ..description = "Antrenament pentru piept, umeri și stabilitate core. Monitorizare unghi cot și aliniere spate."
        ..iconName = "straighten"
        ..accentColorHex = 0xFFFF5252 // Colors.redAccent
        ..requiresLandscape = true // Solicită modul Landscape
        ..isTimerBased = false
        ..sideStrategy = "DYNAMIC_BEST_SIDE" // Se poate analiza fie de pe profilul stâng, fie de pe cel drept
        ..requiredLandmarks = ["shoulder", "elbow", "wrist", "hip", "knee"]
        ..fallbackFeedback = "Poziționează-te în planșă, din profil.\nAparatul trebuie să îți vadă tot corpul."
        ..trackingType = "REPETARI_COMPLEXE"
        ..geometries = [
          // 1. Unghiul cotului pentru detectarea coborârii/ridicării
          GeometryConfig()
            ..id = "unghi_cot"
            ..type = "ANGLE"
            ..inputPoints = ["shoulder", "elbow", "wrist"]
            ..invertXOnRightSide = false,

          // 2. Unghiul corpului (Aliniere umăr -> șold -> genunchi) pentru postură
          GeometryConfig()
            ..id = "aliniere_corp"
            ..type = "ANGLE"
            ..inputPoints = ["shoulder", "hip", "knee"]
            ..invertXOnRightSide = false
        ]
        ..transitions = [
          // Trecerea în starea DOWN (doar dacă spatele este drept > 145°)
          TransitionRule()
            ..fromState = "UP"
            ..toState = "DOWN"
            ..geometryId = "unghi_cot"
            ..operatorType = "LESS_THAN"
            ..thresholdMin = 95.0
            ..thresholdMax = 0.0
            ..action = "NONE"
            ..feedback = "Coboară pieptul aproape de sol..."
            ..gateGeometryId = "aliniere_corp"
            ..gateOperatorType = "GREATER_THAN"
            ..gateThreshold = 145.0,

          // Trecerea în starea UP și incrementare (doar dacă spatele rămâne drept > 145°)
          TransitionRule()
            ..fromState = "DOWN"
            ..toState = "UP"
            ..geometryId = "unghi_cot"
            ..operatorType = "GREATER_THAN"
            ..thresholdMin = 150.0
            ..thresholdMax = 0.0
            ..action = "INCREMENT"
            ..feedback = "Repetare completă! Postură excelentă."
            ..gateGeometryId = "aliniere_corp"
            ..gateOperatorType = "GREATER_THAN"
            ..gateThreshold = 145.0
        ]
        ..warnings = [
          // Avertizare continuă în cazul în care bazinul se prăbușește sau este prea ridicat
          WarningRule()
            ..geometryId = "aliniere_corp"
            ..operatorType = "LESS_THAN"
            ..thresholdMin = 145.0
            ..thresholdMax = 0.0
            ..activeInState = "ANY" // Valabil atât în starea UP cât și în DOWN
            ..warningMessage = "⚠️ Îndreaptă spatele/bazinul!"
        ],
      // --- 6. Plank (Scândură) ---
      ExerciseSchema()
        ..exerciseId = "6"
        ..title = "Plank (Scândură)"
        ..description = "Exercițiu izometric pentru forța abdominală. Menține spatele drept și bazinul aliniat."
        ..iconName = "hourglass_empty"
        ..accentColorHex = 0xFFFFC107 // Colors.amber
        ..requiresLandscape = true // Solicită modul Landscape (vedere din profil)
        ..isTimerBased = true // Activează UI-ul de tip cronometru / timp acumulat
        ..sideStrategy = "DYNAMIC_BEST_SIDE" // Alege automat profilul cel mai vizibil (stângul sau dreptul)
        ..requiredLandmarks = ["shoulder", "hip", "knee"]
        ..fallbackFeedback = "Așază-te complet în cadru..."
        ..trackingType = "IZOMETRIC_TIMP"
        ..geometries = [
          // 1. Unghiul șoldului (Aliniere umăr -> șold -> genunchi)
          GeometryConfig()
            ..id = "unghi_sold"
            ..type = "ANGLE"
            ..inputPoints = ["shoulder", "hip", "knee"]
            ..invertXOnRightSide = false,

          // 2. Geometrie auxiliară pentru detectarea înălțimii șoldului pe axa Y față de linia umeri-genunchi
          GeometryConfig()
            ..id = "pozitie_relativa_bazins"
            ..type = "MIDPOINT_Y_DIST"
            ..inputPoints = ["hip", "shoulder", "knee"]
            ..invertXOnRightSide = false
        ]
        ..transitions = [
          // Regula de bază: Cât timp ești în intervalul 160°-180°, cronometrul pornește/acumulează
          TransitionRule()
            ..fromState = "START"
            ..toState = "HOLDING"
            ..geometryId = "unghi_sold"
            ..operatorType = "BETWEEN"
            ..thresholdMin = 160.0
            ..thresholdMax = 180.0
            ..action = "TIMER_ACCUMULATE" // Semnalizează motorului să adauge timp real
            ..feedback = "Postură excelentă! Menține..."
        ]
        ..warnings = [
          // Avertizare 1: Unghiul e greșit, iar bazinul e prea sus (hip.y este mai mic în pixeli pe ecran)
          WarningRule()
            ..geometryId = "unghi_sold"
            ..operatorType = "LESS_THAN"
            ..thresholdMin = 160.0
            ..thresholdMax = 0.0
            ..activeInState = "ANY"
            ..warningMessage = "⚠️ Ridică bazinul! Ține spatele drept!",

          // Notă: În motorul tău generic, dacă unghiul iese din 160-180, cronometrul se oprește automat.
          // Pentru a simula cu exactitate condiția ta de Y-delta (hip.y < midY - 20):
          WarningRule()
            ..geometryId = "pozitie_relativa_bazins"
            ..operatorType = "LESS_THAN"
            ..thresholdMin = -20.0 // În coordonate ecrane, o valoare puternic negativă înseamnă bazin prea sus
            ..thresholdMax = 0.0
            ..activeInState = "ANY"
            ..warningMessage = "⚠️ Coboară bazinul!"
        ],
      // --- 7. Fandări (Lunges) ---
      ExerciseSchema()
        ..exerciseId = "7"
        ..title = "Fandări (Lunges)"
        ..description = "Antrenament intens pentru picioare și echilibru"
        ..iconName = "directions_walk"
        ..accentColorHex = 0xFF69F0AE // Colors.greenAccent
        ..requiresLandscape = true
        ..isTimerBased = false
        ..sideStrategy = "DYNAMIC_BEST_SIDE" // Selectează automat piciorul cel mai vizibil (cel din față/spre cameră)
        ..requiredLandmarks = ["shoulder", "hip", "knee", "ankle"]
        ..fallbackFeedback = "Poziționează-te din profil.\nAparatul trebuie să îți vadă șoldul, genunchiul și glezna."
        ..trackingType = "REPETARI_COMPLEXE"
        ..geometries = [
          // 1. Măsurarea unghiului genunchiului (pentru fazele UP / DOWN)
          GeometryConfig()
            ..id = "unghi_genunchi"
            ..type = "ANGLE"
            ..inputPoints = ["hip", "knee", "ankle"]
            ..invertXOnRightSide = false,

          // 2. Alinierea trunchiului (pentru a verifica dacă spatele e vertical)
          GeometryConfig()
            ..id = "unghi_trunchi"
            ..type = "ANGLE"
            ..inputPoints = ["shoulder", "hip", "knee"]
            ..invertXOnRightSide = false,

          // 3. Deviația orizontală pe axa X între genunchi și gleznă (Drift)
          GeometryConfig()
            ..id = "deviatie_orizontala_genunchi"
            ..type = "HORIZONTAL_DELTA" // Calculează (knee.x - ankle.x).abs()
            ..inputPoints = ["knee", "ankle"]
            ..invertXOnRightSide = false
        ]
        ..transitions = [
          // Trecerea în starea DOWN când genunchiul coboară sub 100 de grade
          TransitionRule()
            ..fromState = "UP"
            ..toState = "DOWN"
            ..geometryId = "unghi_genunchi"
            ..operatorType = "LESS_THAN"
            ..thresholdMin = 100.0
            ..thresholdMax = 0.0
            ..action = "NONE"
            ..feedback = "Coboară spatele drept..."
            ..gateGeometryId = null
            ..gateOperatorType = null
            ..gateThreshold = null,

          // Trecerea în starea UP și incrementarea când piciorul se îndreaptă peste 160 de grade
          TransitionRule()
            ..fromState = "DOWN"
            ..toState = "UP"
            ..geometryId = "unghi_genunchi"
            ..operatorType = "GREATER_THAN"
            ..thresholdMin = 160.0
            ..thresholdMax = 0.0
            ..action = "INCREMENT"
            ..feedback = "Repetare completă!"
            ..gateGeometryId = null
            ..gateOperatorType = null
            ..gateThreshold = null
        ]
        ..warnings = [
          // Avertizare postură: Trunchiul este prea aplecat în față (unghiul scade sub 140°)
          WarningRule()
            ..geometryId = "unghi_trunchi"
            ..operatorType = "LESS_THAN"
            ..thresholdMin = 140.0
            ..thresholdMax = 0.0
            ..activeInState = "ANY"
            ..warningMessage = "⚠️ Încearcă să ții trunchiul mai vertical.",

          // Avertizare biomecanică: Genunchiul depășește proiecția degetelor (drift X mai mare de 45px), activă doar pe coborâre
          WarningRule()
            ..geometryId = "deviatie_orizontala_genunchi"
            ..operatorType = "GREATER_THAN"
            ..thresholdMin = 45.0
            ..thresholdMax = 0.0
            ..activeInState = "DOWN"
            ..warningMessage = "⚠️ Nu duce genunchiul în fața degetelor!"
        ],
      // --- 8. Întinderi Gât ---
      ExerciseSchema()
        ..exerciseId = "8"
        ..title = "Întinderi Gât"
        ..description = "Eliberează tensiunea cervicală"
        ..iconName = "person"
        ..accentColorHex = 0xFFFF4081 // Colors.pinkAccent
        ..requiresLandscape = false
        ..isTimerBased = false
        ..sideStrategy = "FULL_BODY" // Punctele stângi și drepte se citesc în paralel
        ..requiredLandmarks = ["leftEar", "rightEar", "leftShoulder", "rightShoulder", "nose"]
        ..fallbackFeedback = "Stai cu fața la cameră.\nAsigură-te că fața și umerii sunt vizibili."
        ..trackingType = "REPETARI_SPLIT" // Semnalizează afișarea separată Stânga/Dreapta în ecran
        ..geometries = [
          // 1. Unghiul gâtului pe partea stângă (Ear -> Nose -> Shoulder)
          GeometryConfig()
            ..id = "unghi_gat_stanga"
            ..type = "ANGLE"
            ..inputPoints = ["leftEar", "nose", "leftShoulder"]
            ..invertXOnRightSide = false,

          // 2. Unghiul gâtului pe partea dreaptă (Ear -> Nose -> Shoulder)
          GeometryConfig()
            ..id = "unghi_gat_dreapta"
            ..type = "ANGLE"
            ..inputPoints = ["rightEar", "nose", "rightShoulder"]
            ..invertXOnRightSide = false,

          // 3. Diferența de înălțime a umerilor pe axa Y pentru postură
          GeometryConfig()
            ..id = "balans_umeri"
            ..type = "ABS_DIFF_Y" // Calculează (leftShoulder.y - rightShoulder.y).abs()
            ..inputPoints = ["leftShoulder", "rightShoulder"]
            ..invertXOnRightSide = false
        ]
        ..transitions = [
          // --- Ramura Stângă ---
          TransitionRule()
            ..fromState = "CENTER"
            ..toState = "LEFT"
            ..geometryId = "unghi_gat_stanga"
            ..operatorType = "LESS_THAN"
            ..thresholdMin = 45.0
            ..thresholdMax = 0.0
            ..action = "NONE"
            ..feedback = "Întindere pe Stânga detectată.",
          TransitionRule()
            ..fromState = "LEFT"
            ..toState = "CENTER"
            ..geometryId = "unghi_gat_stanga"
            ..operatorType = "GREATER_THAN"
            ..thresholdMin = 65.0
            ..thresholdMax = 0.0
            ..action = "INCREMENT_LEFT" // Incrementează exclusiv contorul din stânga
            ..feedback = "Menține umerii jos și întinde gâtul...",

          // --- Ramura Dreaptă ---
          TransitionRule()
            ..fromState = "CENTER"
            ..toState = "RIGHT"
            ..geometryId = "unghi_gat_dreapta"
            ..operatorType = "LESS_THAN"
            ..thresholdMin = 45.0
            ..thresholdMax = 0.0
            ..action = "NONE"
            ..feedback = "Întindere pe Dreapta detectată.",
          TransitionRule()
            ..fromState = "RIGHT"
            ..toState = "CENTER"
            ..geometryId = "unghi_gat_dreapta"
            ..operatorType = "GREATER_THAN"
            ..thresholdMin = 65.0
            ..thresholdMax = 0.0
            ..action = "INCREMENT_RIGHT" // Incrementează exclusiv contorul din dreapta
            ..feedback = "Menține umerii jos și întinde gâtul..."
        ]
        ..warnings = [
          // Avertizare postură: Umerii nu sunt paraleli / se ridică spre urechi
          WarningRule()
            ..geometryId = "balans_umeri"
            ..operatorType = "GREATER_THAN"
            ..thresholdMin = 35.0
            ..thresholdMax = 0.0
            ..activeInState = "ANY"
            ..warningMessage = "⚠️ Relaxează umerii! Nu îi ridica spre urechi."
        ],
      // --- 9. Rotiri Braț - Stâng ---
      ExerciseSchema()
        ..exerciseId = "9"
        ..title = "Rotiri Braț - Stâng"
        ..description = "Mobilitate completă pentru umărul stâng"
        ..iconName = "sync"
        ..accentColorHex = 0xFFFFFF00 // Colors.yellowAccent
        ..requiresLandscape = false
        ..isTimerBased = false
        ..sideStrategy = "LEFT_ONLY"
        ..requiredLandmarks = ["shoulder", "elbow", "wrist"]
        ..fallbackFeedback = "Stai cu fața la cameră.\nAsigură-te că brațul Stâng este vizibil."
        ..trackingType = "REPETARI_COMPLEXE"
        ..geometries = [
          // 1. Delta Y: wrist.y - shoulder.y
          GeometryConfig()
            ..id = "delta_y"
            ..type = "RELATIVE_Y"
            ..inputPoints = ["wrist", "shoulder"]
            ..invertXOnRightSide = false,

          // 2. Delta X: wrist.x - shoulder.x
          GeometryConfig()
            ..id = "delta_x"
            ..type = "RELATIVE_X"
            ..inputPoints = ["wrist", "shoulder"]
            ..invertXOnRightSide = false, // Pe stânga rămâne natural

          // 3. Unghiul cotului pentru avertizare
          GeometryConfig()
            ..id = "unghi_cot"
            ..type = "ANGLE"
            ..inputPoints = ["shoulder", "elbow", "wrist"]
            ..invertXOnRightSide = false
        ]
        ..transitions = [
          // START -> FRONT (dy < 20 ȘI dx > 40)
          TransitionRule()
            ..fromState = "START"
            ..toState = "FRONT"
            ..geometryId = "delta_y"
            ..operatorType = "LESS_THAN"
            ..thresholdMin = 20.0
            ..thresholdMax = 0.0
            ..action = "NONE"
            ..feedback = "Brațul trece prin față..."
            ..gateGeometryId = "delta_x"
            ..gateOperatorType = "GREATER_THAN"
            ..gateThreshold = 40.0,

          // FRONT -> TOP (dy < -50)
          TransitionRule()
            ..fromState = "FRONT"
            ..toState = "TOP"
            ..geometryId = "delta_y"
            ..operatorType = "LESS_THAN"
            ..thresholdMin = -50.0
            ..thresholdMax = 0.0
            ..action = "NONE"
            ..feedback = "Excelent! Sus deasupra capului...",

          // TOP -> BACK (dy > -20 ȘI dx < -30)
          TransitionRule()
            ..fromState = "TOP"
            ..toState = "BACK"
            ..geometryId = "delta_y"
            ..operatorType = "GREATER_THAN"
            ..thresholdMin = -20.0
            ..thresholdMax = 0.0
            ..action = "NONE"
            ..feedback = "Coboară brațul prin spate..."
            ..gateGeometryId = "delta_x"
            ..gateOperatorType = "LESS_THAN"
            ..gateThreshold = -30.0,

          // BACK -> START (dy > 50) -> INCREMENT
          TransitionRule()
            ..fromState = "BACK"
            ..toState = "START"
            ..geometryId = "delta_y"
            ..operatorType = "GREATER_THAN"
            ..thresholdMin = 50.0
            ..thresholdMax = 0.0
            ..action = "INCREMENT"
            ..feedback = "Rotire completă reușită!"
        ]
        ..warnings = [
          WarningRule()
            ..geometryId = "unghi_cot"
            ..operatorType = "LESS_THAN"
            ..thresholdMin = 140.0
            ..thresholdMax = 0.0
            ..activeInState = "NOT_START" // Activă în FRONT, TOP, BACK (oricând nu ești pe loc)
            ..warningMessage = "⚠️ Întinde brațul! Nu îndoi cotul în timpul rotației."
        ],
      // --- 10. Rotiri Braț - Drept ---
      ExerciseSchema()
        ..exerciseId = "10"
        ..title = "Rotiri Braț - Drept"
        ..description = "Mobilitate completă pentru umărul drept"
        ..iconName = "sync"
        ..accentColorHex = 0xFFE040FB // Colors.purpleAccent
        ..requiresLandscape = false
        ..isTimerBased = false
        ..sideStrategy = "RIGHT_ONLY"
        ..requiredLandmarks = ["shoulder", "elbow", "wrist"]
        ..fallbackFeedback = "Stai cu fața la cameră.\nAsigură-te că brațul Drept este vizibil."
        ..trackingType = "REPETARI_COMPLEXE"
        ..geometries = [
          GeometryConfig()
            ..id = "delta_y"
            ..type = "RELATIVE_Y"
            ..inputPoints = ["wrist", "shoulder"]
            ..invertXOnRightSide = false,

          GeometryConfig()
            ..id = "delta_x"
            ..type = "RELATIVE_X"
            ..inputPoints = ["wrist", "shoulder"]
            ..invertXOnRightSide = true, // <--- Oglindește axa X automat pentru brațul drept!

          GeometryConfig()
            ..id = "unghi_cot"
            ..type = "ANGLE"
            ..inputPoints = ["shoulder", "elbow", "wrist"]
            ..invertXOnRightSide = false
        ]
        ..transitions = [
          TransitionRule()
            ..fromState = "START"
            ..toState = "FRONT"
            ..geometryId = "delta_y"
            ..operatorType = "LESS_THAN"
            ..thresholdMin = 20.0
            ..thresholdMax = 0.0
            ..action = "NONE"
            ..feedback = "Brațul trece prin față..."
            ..gateGeometryId = "delta_x"
            ..gateOperatorType = "GREATER_THAN"
            ..gateThreshold = 40.0, // Datorită invertX, condiția rămâne neschimbată geometric!

          TransitionRule()
            ..fromState = "FRONT"
            ..toState = "TOP"
            ..geometryId = "delta_y"
            ..operatorType = "LESS_THAN"
            ..thresholdMin = -50.0
            ..thresholdMax = 0.0
            ..action = "NONE"
            ..feedback = "Excelent! Sus deasupra capului...",

          TransitionRule()
            ..fromState = "TOP"
            ..toState = "BACK"
            ..geometryId = "delta_y"
            ..operatorType = "GREATER_THAN"
            ..thresholdMin = -20.0
            ..thresholdMax = 0.0
            ..action = "NONE"
            ..feedback = "Coboară brațul prin spate..."
            ..gateGeometryId = "delta_x"
            ..gateOperatorType = "LESS_THAN"
            ..gateThreshold = -30.0,

          TransitionRule()
            ..fromState = "BACK"
            ..toState = "START"
            ..geometryId = "delta_y"
            ..operatorType = "GREATER_THAN"
            ..thresholdMin = 50.0
            ..thresholdMax = 0.0
            ..action = "INCREMENT"
            ..feedback = "Rotire completă reușită!"
        ]
        ..warnings = [
          WarningRule()
            ..geometryId = "unghi_cot"
            ..operatorType = "LESS_THAN"
            ..thresholdMin = 140.0
            ..thresholdMax = 0.0
            ..activeInState = "NOT_START"
            ..warningMessage = "⚠️ Întinde brațul! Nu îndoi cotul în timpul rotației."
        ],
      ExerciseSchema()
        ..exerciseId = "11"
        ..title = "Ridicări Laterale - Braț Stâng"
        ..description = "Tonifiere și mobilitate pentru deltoidul stâng"
        ..iconName = "accessibility"
        ..accentColorHex = 0xFF00E5FF // Colors.lightBlueAccent
        ..requiresLandscape = false
        ..isTimerBased = false
        ..sideStrategy = "LEFT_ONLY"
        ..requiredLandmarks = ["hip", "shoulder", "elbow", "wrist"]
        ..fallbackFeedback = "Stai cu fața la cameră.\nAsigură-te că brațul Stâng este complet vizibil."
        ..trackingType = "REPETARI_SIMPLE"
        ..geometries = [
          GeometryConfig()
            ..id = "unghi_ridicare"
            ..type = "ANGLE"
            ..inputPoints = ["hip", "shoulder", "wrist"]
            ..invertXOnRightSide = false,
          GeometryConfig()
            ..id = "unghi_cot"
            ..type = "ANGLE"
            ..inputPoints = ["shoulder", "elbow", "wrist"]
            ..invertXOnRightSide = false
        ]
        ..transitions = [
          TransitionRule()
            ..fromState = "DOWN"
            ..toState = "UP"
            ..geometryId = "unghi_ridicare"
            ..operatorType = "GREATER_THAN"
            ..thresholdMin = 80.0
            ..thresholdMax = 0.0
            ..action = "NONE"
            ..feedback = "Braț ridicat! Coboară controlat...",

          // Revenirea în starea DOWN și incrementare sub 25 de grade
          TransitionRule()
            ..fromState = "UP"
            ..toState = "DOWN"
            ..geometryId = "unghi_ridicare"
            ..operatorType = "LESS_THAN"
            ..thresholdMin = 25.0
            ..thresholdMax = 0.0
            ..action = "INCREMENT"
            ..feedback = "Repetare corectă!"
        ]
        ..warnings = [
          // Avertizare 1: Brațul este ridicat prea sus (peste 110°) în faza UP
          WarningRule()
            ..geometryId = "unghi_ridicare"
            ..operatorType = "GREATER_THAN"
            ..thresholdMin = 110.0
            ..thresholdMax = 0.0
            ..activeInState = "UP"
            ..warningMessage = "⚠️ Oprește brațul la nivelul umărului (la 90°)!",

          // Avertizare 2: Cotul se îndoaie (sub 150°) când brațul este activ (unghi ridicare > 45°)
          WarningRule()
            ..geometryId = "unghi_cot"
            ..operatorType = "LESS_THAN"
            ..thresholdMin = 150.0
            ..thresholdMax = 0.0
            ..activeInState = "ANY" // Controlat prin poartă sau logică secundară dacă e cazul
            ..warningMessage = "⚠️ Întinde brațul! Nu folosi doar antebrațul."
        ],

// --- 12. Ridicări Laterale - Braț Drept ---
      ExerciseSchema()
        ..exerciseId = "12"
        ..title = "Ridicări Laterale - Braț Drept"
        ..description = "Tonifiere și mobilitate pentru deltoidul drept"
        ..iconName = "accessibility"
        ..accentColorHex = 0xFFCDDC39 // Colors.lime
        ..requiresLandscape = false
        ..isTimerBased = false
        ..sideStrategy = "RIGHT_ONLY"
        ..requiredLandmarks = ["hip", "shoulder", "elbow", "wrist"]
        ..fallbackFeedback = "Stai cu fața la cameră.\nAsigură-te că brațul Drept este complet vizibil."
        ..trackingType = "REPETARI_SIMPLE"
        ..geometries = [
          GeometryConfig()
            ..id = "unghi_ridicare"
            ..type = "ANGLE"
            ..inputPoints = ["hip", "shoulder", "wrist"]
            ..invertXOnRightSide = false,

          GeometryConfig()
            ..id = "unghi_cot"
            ..type = "ANGLE"
            ..inputPoints = ["shoulder", "elbow", "wrist"]
            ..invertXOnRightSide = false
        ]
        ..transitions = [
          TransitionRule()
            ..fromState = "DOWN"
            ..toState = "UP"
            ..geometryId = "unghi_ridicare"
            ..operatorType = "GREATER_THAN"
            ..thresholdMin = 80.0
            ..thresholdMax = 0.0
            ..action = "NONE"
            ..feedback = "Braț ridicat! Coboară controlat...",

          TransitionRule()
            ..fromState = "UP"
            ..toState = "DOWN"
            ..geometryId = "unghi_ridicare"
            ..operatorType = "LESS_THAN"
            ..thresholdMin = 25.0
            ..thresholdMax = 0.0
            ..action = "INCREMENT"
            ..feedback = "Repetare corectă!"
        ]
        ..warnings = [
          WarningRule()
            ..geometryId = "unghi_ridicare"
            ..operatorType = "GREATER_THAN"
            ..thresholdMin = 110.0
            ..thresholdMax = 0.0
            ..activeInState = "UP"
            ..warningMessage = "⚠️ Oprește brațul la nivelul umărului (la 90°)!",

          WarningRule()
            ..geometryId = "unghi_cot"
            ..operatorType = "LESS_THAN"
            ..thresholdMin = 150.0
            ..thresholdMax = 0.0
            ..activeInState = "ANY"
            ..warningMessage = "⚠️ Întinde brațul! Nu folosi doar antebrațul."
        ],
    ];

    await _isar.writeTxn(() async {
      await _isar.exerciseSchemas.clear();
      await _isar.exerciseSchemas.putAll(defaultExercises);
    });
  }

  Future<List<WorkoutPlan>> getAllWorkoutPlans() async {
    return await _isar.workoutPlans.where().findAll();
  }

// Salvare sau editare rutină
  Future<void> saveWorkoutPlan(WorkoutPlan plan) async {
    await _isar.writeTxn(() async {
      await _isar.workoutPlans.put(plan);
    });
    await NotificationService.instance.scheduleWorkoutNotifications(plan);
  }

// Ștergerea unei rutine după ID-ul Isar
  Future<void> deleteWorkoutPlan(int id) async {
    await _isar.writeTxn(() async {
      await _isar.workoutPlans.delete(id);
    });
  }

  Future<void> logWorkoutSession({
    required String exerciseId,
    required int completedReps,
    required int durationSeconds,
  }) async {
    final log = WorkoutLog()
      ..exerciseId = exerciseId
      ..completedReps = completedReps
      ..durationSeconds = durationSeconds
      ..timestamp = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.workoutLogs.put(log);
    });
  }

  Future<WorkoutStatsData> getWorkoutStatistics() async {
    final logs = await _isar.workoutLogs.where().findAll();

    int totalReps = 0;
    final Map<String, int> repsPerExercise = {};
    final Map<DateTime, int> dailyReps = {};

    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      dailyReps[day] = 0;
    }

    for (var log in logs) {
      int effectiveReps = log.completedReps;

      if (effectiveReps == 0 && log.durationSeconds > 0) {
        effectiveReps = (log.durationSeconds / 3).floor();
      }

      if (effectiveReps > 0) {
        totalReps += effectiveReps;

        final exName = log.exerciseId.toUpperCase();
        repsPerExercise[exName] = (repsPerExercise[exName] ?? 0) + effectiveReps;

        final logDate = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
        if (dailyReps.containsKey(logDate)) {
          dailyReps[logDate] = (dailyReps[logDate] ?? 0) + effectiveReps;
        }
      }
    }

    String topExercise = "-";
    int maxReps = 0;
    repsPerExercise.forEach((name, reps) {
      if (reps > maxReps) {
        maxReps = reps;
        topExercise = name;
      }
    });
    return WorkoutStatsData(
      totalReps: totalReps,
      topExerciseName: topExercise,
      repsPerExercise: repsPerExercise,
      dailyReps: dailyReps,
    );
  }

  Future<DailyStats> getTotalStatsForDay(String exerciseId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    // Filtrăm logurile din Isar pentru exercițiul și ziua respectivă
    final logs = await _isar.workoutLogs
        .filter()
        .exerciseIdEqualTo(exerciseId, caseSensitive: false)
        .timestampBetween(startOfDay, endOfDay)
        .findAll();

    int totalReps = 0;
    int totalDuration = 0;

    for (var log in logs) {
      totalReps += log.completedReps;
      totalDuration += log.durationSeconds;
    }

    return DailyStats(
      reps: totalReps,
      durationSeconds: totalDuration,
    );
  }

  Future<List<ExerciseBadge>> getBadgesForExercise(String exerciseId) async {
    return await _isar.exerciseBadges
        .filter()
        .exerciseIdEqualTo(exerciseId)
        .findAll();
  }

  Future<List<ExerciseBadge>> getAllBadges() async {
    return await _isar.exerciseBadges.where().findAll();
  }

  Future<void> saveBadge(ExerciseBadge badge) async {
    await _isar.writeTxn(() async {
      await _isar.exerciseBadges.put(badge);
    });
  }

  Future<void> _seedBadgesIfNeeded() async {
    final count = await _isar.exerciseBadges.count();
    if (count > 0) return; // Se populează o singură dată

    final exercises = await getAllExercises();
    final List<ExerciseBadge> defaultBadges = [];

    for (var ex in exercises) {
      final isTimer = ex.isTimerBased ?? false;
      final exId = ex.exerciseId ?? "unknown";
      final title = ex.title ?? "Exercițiu";

      if (isTimer) {
        // --- BADGE-URI PENTRU EXERCIȚII CU TIMP (ex: Plank) ---
        defaultBadges.addAll([
          // Instant (1 Sesiune)
          ExerciseBadge()
            ..badgeId = "${exId}_30s"
            ..exerciseId = exId
            ..title = "$title: Începător"
            ..description = "Menține poziția timp de 30 de secunde."
            ..iconName = "bronze_medal"
            ..criteriaType = "TOTAL_DURATION"
            ..targetValue = 30
            ..requiredDaysStreak = 0,
          ExerciseBadge()
            ..badgeId = "${exId}_90s"
            ..exerciseId = exId
            ..title = "$title: Avansat"
            ..description = "Menține poziția timp de 1 minut și 30 secunde."
            ..iconName = "silver_medal"
            ..criteriaType = "TOTAL_DURATION"
            ..targetValue = 90
            ..requiredDaysStreak = 0,
          ExerciseBadge()
            ..badgeId = "${exId}_180s"
            ..exerciseId = exId
            ..title = "$title: Maestru"
            ..description = "Menține poziția timp de 3 minute."
            ..iconName = "gold_medal"
            ..criteriaType = "TOTAL_DURATION"
            ..targetValue = 180
            ..requiredDaysStreak = 0,

          // Streak-uri de 7 zile
          ExerciseBadge()
            ..badgeId = "${exId}_30s_7days"
            ..exerciseId = exId
            ..title = "$title: Rutină Bronze"
            ..description = "Execută câte 30s de $title zilnic, timp de 7 zile la rând."
            ..iconName = "fire_bronze"
            ..criteriaType = "DURATION_STREAK"
            ..targetValue = 30
            ..requiredDaysStreak = 7,
          ExerciseBadge()
            ..badgeId = "${exId}_60s_7days"
            ..exerciseId = exId
            ..title = "$title: Rutină Silver"
            ..description = "Execută câte 60s de $title zilnic, timp de 7 zile la rând."
            ..iconName = "fire_silver"
            ..criteriaType = "DURATION_STREAK"
            ..targetValue = 60
            ..requiredDaysStreak = 7,
          ExerciseBadge()
            ..badgeId = "${exId}_180s_7days"
            ..exerciseId = exId
            ..title = "$title: Rutină Gold"
            ..description = "Execută câte 3 min de $title zilnic, timp de 7 zile la rând."
            ..iconName = "fire_gold"
            ..criteriaType = "DURATION_STREAK"
            ..targetValue = 180
            ..requiredDaysStreak = 7,
        ]);
      } else {
        // --- BADGE-URI PENTRU EXERCIȚII CU REPETĂRI (ex: Genuflexiuni, Flotări) ---
        defaultBadges.addAll([
          // Instant (1 Sesiune)
          ExerciseBadge()
            ..badgeId = "${exId}_10reps"
            ..exerciseId = exId
            ..title = "$title: Primele 10"
            ..description = "Finalizează 10 repetări într-o singură sesiune."
            ..iconName = "bronze_medal"
            ..criteriaType = "TOTAL_REPS"
            ..targetValue = 10
            ..requiredDaysStreak = 0,
          ExerciseBadge()
            ..badgeId = "${exId}_50reps"
            ..exerciseId = exId
            ..title = "$title: Fortăreța"
            ..description = "Finalizează 50 de repetări într-o singură sesiune."
            ..iconName = "silver_medal"
            ..criteriaType = "TOTAL_REPS"
            ..targetValue = 50
            ..requiredDaysStreak = 0,
          ExerciseBadge()
            ..badgeId = "${exId}_100reps"
            ..exerciseId = exId
            ..title = "$title: Imparabil"
            ..description = "Finalizează 100 de repetări într-o singură sesiune."
            ..iconName = "gold_medal"
            ..criteriaType = "TOTAL_REPS"
            ..targetValue = 100
            ..requiredDaysStreak = 0,

          // Streak-uri de 7 zile
          ExerciseBadge()
            ..badgeId = "${exId}_10reps_7days"
            ..exerciseId = exId
            ..title = "$title: Perseverent Bronze"
            ..description = "Execută câte 10 repetări zilnic, timp de 7 zile la rând."
            ..iconName = "fire_bronze"
            ..criteriaType = "REPS_STREAK"
            ..targetValue = 10
            ..requiredDaysStreak = 7,
          ExerciseBadge()
            ..badgeId = "${exId}_20reps_7days"
            ..exerciseId = exId
            ..title = "$title: Perseverent Silver"
            ..description = "Execută câte 20 de repetări zilnic, timp de 7 zile la rând."
            ..iconName = "fire_silver"
            ..criteriaType = "REPS_STREAK"
            ..targetValue = 20
            ..requiredDaysStreak = 7,
          ExerciseBadge()
            ..badgeId = "${exId}_50reps_7days"
            ..exerciseId = exId
            ..title = "$title: Perseverent Gold"
            ..description = "Execută câte 50 de repetări zilnic, timp de 7 zile la rând."
            ..iconName = "fire_gold"
            ..criteriaType = "REPS_STREAK"
            ..targetValue = 50
            ..requiredDaysStreak = 7,
        ]);
      }
    }

    if (defaultBadges.isNotEmpty) {
      await _isar.writeTxn(() async {
        await _isar.exerciseBadges.putAll(defaultBadges);
      });
    }
  }

  Future<List<ExerciseBadge>> getRecentUnlockedBadges({int limit = 5}) async {
    final allUnlocked = await _isar.exerciseBadges
        .filter()
        .isUnlockedEqualTo(true)
        .findAll();

    allUnlocked.sort((a, b) {
      if (a.unlockedAt == null) return 1;
      if (b.unlockedAt == null) return -1;
      return b.unlockedAt!.compareTo(a.unlockedAt!);
    });

    return allUnlocked.take(limit).toList();
  }

  Future<void> resetAllUserData() async {
    await _isar.writeTxn(() async {
      await _isar.workoutLogs.clear();
      await _isar.workoutPlans.clear();
      final allBadges = await _isar.exerciseBadges.where().findAll();
      for (var badge in allBadges) {
        badge.isUnlocked = false;
        badge.unlockedAt = null;
        badge.screenshotPath = null;
        await _isar.exerciseBadges.put(badge);
      }
    });
  }
}