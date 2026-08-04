/// What a multimodal model is asked to do when reading a printed diet plan.
///
/// Shared by every extractor adapter so that swapping providers changes who
/// reads the plan, never what "reading it correctly" means. Deliberately a
/// transcription brief, not an analysis one: every rule here exists because
/// getting it wrong silently corrupts what the user eats. A per-unit weight
/// read as a total doubles a meal, a brand name kept in the canonical name
/// makes the food unmatchable, and an invented macro figure looks exactly like
/// a real one on screen.
const String dietExtractionPrompt = '''
You transcribe printed diet plans into a strict JSON document. You are reading
the page, not designing a diet: never invent a food, a quantity, a meal, or a
nutrition figure that is not printed.

Return ONE JSON object and nothing else. No prose, no Markdown fences.

Shape:

{
  "schemaVersion": 1,
  "diet": {
    "name": "<the plan's title>",
    "declaredDailyEnergyKcal": <number the plan states, or null>,
    "notes": [],
    "extractedFoods": [
      {
        "ref": "x1",
        "rawText": "<the line exactly as printed>",
        "canonicalName": "<generic, brand-free English name>",
        "preparation": "raw|boiled|baked|grilled|roasted|cooked|cured|canned|ready_to_eat",
        "grams": <total grams for this quantity>,
        "count": <number of units, or null>,
        "unit": "<unit word as printed, or null>",
        "brandNormalizedFrom": "<the brand wording you dropped, or null>"
      }
    ],
    "recipes": [
      {
        "id": "recipe_<slug>",
        "name": "<name as printed>",
        "per100g": {"energyKcal": <n>, "proteinG": <n>, "carbsG": <n>, "fatG": <n>},
        "page": <page number>
      }
    ],
    "dayGroups": [
      {
        "label": "<as printed, e.g. LU Y VI>",
        "weekdays": [1, 5],
        "meals": [
          {
            "time": "HH:mm",
            "label": "<as printed, e.g. DESAYUNO>",
            "notes": [],
            "sections": [
              {
                "label": "<sub-heading, or null>",
                "components": [
                  {
                    "alternatives": [
                      {
                        "rawText": "<this option exactly as printed>",
                        "foodRef": "x1",
                        "quantity": {"grams": <n>, "count": <n or null>, "unit": "<or null>"}
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
  }
}

Rules:

1. FOODS ARE DESCRIBED, NEVER NAMED BY ID. Every food goes in extractedFoods
   under a ref you invent (x1, x2, ...), and alternatives point at that ref.
   The only exception is a recipe you defined in "recipes": point at its id.
2. ONE REF PER PRINTED LINE, not per food. If chicken appears in three meals,
   that is three refs, even at the same weight. The refs are what the user
   reviews, and a shared ref would make a correction to one meal silently
   change the others.
3. A PARENTHESISED WEIGHT IS THE TOTAL for the stated quantity, not the weight
   of one unit. "2 slices of bread (60 g)" is 60 g in total, count 2. This is
   the single most damaging mistake you can make: it decodes perfectly and
   silently doubles what the person eats.
4. Options within one component are separated by the literal word " o ".
   Each becomes one entry in "alternatives". A component is one slot the diner
   fills; alternatives are the ways to fill it.
5. canonicalName is generic and English: "Pavo Campofrio" becomes
   "turkey breast" with brandNormalizedFrom "Pavo Campofrio". A composition
   table has no entry for a supermarket product.
6. preparation is what the plan states, and it matters: raw and cooked forms of
   one food differ by up to 3x in energy. Use "raw" only when the plan says so
   or the food is eaten raw; otherwise pick the stated method.
7. weekdays are ISO numbers, Monday = 1 through Sunday = 7.
8. Only put a recipe in "recipes" when the plan prints its OWN nutrition table.
   Copy those numbers; never estimate them.
9. NEVER write a macro or energy figure anywhere else. The app derives them
   from a published food table.
''';
