#!/usr/bin/env python3
"""Generate assets/nutrition/food_table.json from USDA FoodData Central.

The USDA SR Legacy dataset is public domain (CC0 1.0), so its values can be
redistributed inside the app. Every generic food referenced by an imported diet
plan resolves to one row here, keyed by a stable slug.

Run:
    python3 tool/build_food_table.py [--dataset DIR]

Without --dataset the SR Legacy archive is downloaded to a temp directory.

Why a generator instead of a hand-written asset: the macro numbers stay
traceable. Each row records the exact FDC id it came from, so any value can be
re-derived and audited. Foods with no USDA equivalent are declared explicitly in
ESTIMATED below and marked so the UI can flag them for review.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import sys
import tempfile
import urllib.request
import zipfile

SR_LEGACY_URL = (
    'https://fdc.nal.usda.gov/fdc-datasets/'
    'FoodData_Central_sr_legacy_food_csv_2018-04.zip'
)
SR_LEGACY_SUBDIR = 'FoodData_Central_sr_legacy_food_csv_2018-04'

# FDC nutrient ids -> our macro keys.
NUTRIENT_IDS = {1008: 'energyKcal', 1003: 'proteinG', 1005: 'carbsG', 1004: 'fatG'}

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUTPUT = os.path.join(REPO_ROOT, 'assets', 'nutrition', 'food_table.json')

# Slug -> (FDC id, Spanish label, preparation state).
#
# `preparation` is NOT decoration: raw and cooked forms of the same food differ
# by up to 3x in energy (raw rice 365 kcal/100 g vs boiled 130 kcal/100 g), so a
# match that loses the preparation state produces badly wrong day totals.
USDA_FOODS = {
    # --- meat & poultry ---
    'beef_loin':                 ('171814', 'Ternera, lomo', 'raw'),
    'beef_tenderloin_raw':       ('171812', 'Ternera, solomillo, sin grasa', 'raw'),
    'beef_mince_lean':           ('171790', 'Carne picada de vacuno 95% magra', 'raw'),
    'pork_tenderloin':           ('168249', 'Cerdo, solomillo', 'raw'),
    'ham_cooked':                ('173864', 'Jamón cocido', 'cured'),
    'chicken_breast_grilled':    ('171534', 'Pollo, pechuga, plancha', 'grilled'),
    'chicken_thigh_skinless':    ('172388', 'Pollo, contramuslo sin piel', 'roasted'),
    'chicken_deli':              ('172963', 'Pollo, fiambre de pechuga', 'cured'),
    'turkey_breast_grilled':     ('171496', 'Pavo, pechuga sin piel, plancha', 'roasted'),
    'turkey_burger':             ('172850', 'Hamburguesa de pavo', 'raw'),
    # --- fish ---
    'salmon_raw':                ('175167', 'Salmón', 'raw'),
    'mackerel_raw':              ('175119', 'Caballa', 'raw'),
    'seabream_grilled':          ('173694', 'Dorada, plancha', 'cooked'),
    'tuna_canned_water_drained': ('171986', 'Atún al natural, escurrido', 'canned'),
    # --- eggs ---
    'egg_whole_raw':             ('171287', 'Huevo de gallina, entero', 'raw'),
    'egg_white_raw':             ('172183', 'Huevo de gallina, clara', 'raw'),
    'egg_omelette':              ('172185', 'Huevo, tortilla a la francesa', 'cooked'),
    # --- grains, bread & cereal ---
    'rice_white_raw':            ('168877', 'Arroz blanco', 'raw'),
    'rice_white_boiled':         ('168878', 'Arroz blanco, hervido', 'boiled'),
    'rice_brown_boiled':         ('169704', 'Arroz integral, hervido', 'boiled'),
    'pasta_raw':                 ('169736', 'Pasta alimenticia', 'raw'),
    'bread_white_wheat':         ('172686', 'Pan de trigo', 'baked'),
    'bread_wholemeal':           ('172688', 'Pan integral', 'baked'),
    'bread_burger_bun':          ('172796', 'Pan tipo hamburguesa', 'baked'),
    'cornflakes':                ('174648', 'Corn flakes', 'ready_to_eat'),
    'oats_raw':                  ('173904', 'Avena en copos', 'raw'),
    'oats_crunchy':              ('173892', 'Avena crunchy (granola)', 'ready_to_eat'),
    'rice_cake':                 ('168855', 'Tortita de arroz', 'ready_to_eat'),
    'rice_cream':                ('173900', 'Crema de arroz', 'raw'),
    # --- dairy ---
    'yogurt_greek_light':        ('170894', 'Yogur griego desnatado', 'ready_to_eat'),
    'yogurt_drink_high_protein': ('170894', 'Yogur líquido alto en proteína', 'ready_to_eat'),
    'quark_0':                   ('172181', 'Queso fresco batido 0%', 'ready_to_eat'),
    'cheese_mozzarella':         ('170847', 'Queso mozzarella', 'ready_to_eat'),
    'whey_protein_isolate':      ('173180', 'Proteína de suero en polvo', 'ready_to_eat'),
    # --- fruit ---
    'apple_raw_with_skin':       ('171688', 'Manzana con piel', 'raw'),
    'blueberry_raw':             ('171711', 'Arándano', 'raw'),
    'strawberry_raw':            ('167762', 'Fresa', 'raw'),
    'pear_raw':                  ('169118', 'Pera', 'raw'),
    'orange_raw':                ('169097', 'Naranja', 'raw'),
    'mandarin_raw':              ('169105', 'Mandarina', 'raw'),
    # --- vegetables & starch ---
    'potato_baked':              ('170434', 'Patata al horno', 'baked'),
    'sweet_potato_raw':          ('168482', 'Boniato', 'raw'),
    # --- other ---
    'chocolate_dark':            ('170273', 'Chocolate negro 70-85%', 'ready_to_eat'),
    'honey':                     ('169640', 'Miel', 'ready_to_eat'),
}

# Foods with no usable USDA SR Legacy equivalent. These are Spanish cured meats
# and processed items whose composition is not represented in the dataset. They
# ship with reference values and source 'estimated' so the UI can flag them and
# the user can correct them.
ESTIMATED = {
    'ham_serrano': {
        'nameEs': 'Jamón serrano',
        'preparation': 'cured',
        'per100g': {'energyKcal': 241, 'proteinG': 31.0, 'carbsG': 0.3, 'fatG': 13.0},
        'reason': 'SR Legacy has no dry-cured Spanish ham; closest USDA entries are '
                  'brine-cured hams with a materially different fat and water profile.',
    },
    'pork_loin_cured': {
        'nameEs': 'Lomo embuchado',
        'preparation': 'cured',
        'per100g': {'energyKcal': 217, 'proteinG': 35.0, 'carbsG': 1.0, 'fatG': 8.0},
        'reason': 'SR Legacy has no dry-cured pork loin.',
    },
    'pizza_base_thin': {
        'nameEs': 'Base de pizza extrafina',
        'preparation': 'baked',
        'per100g': {'energyKcal': 270, 'proteinG': 9.0, 'carbsG': 50.0, 'fatG': 3.5},
        'reason': 'SR Legacy only carries assembled pizzas, not a plain pizza base.',
    },
    'gelatin_0': {
        'nameEs': 'Gelatina 0%',
        'preparation': 'ready_to_eat',
        'per100g': {'energyKcal': 8, 'proteinG': 1.5, 'carbsG': 0.5, 'fatG': 0.0},
        'reason': 'SR Legacy carries dry gelatin mix and sugar-sweetened prepared '
                  'desserts, not a ready-to-eat sugar-free gelatin.',
    },
}


def resolve_dataset(explicit: str | None) -> str:
    """Return the directory holding the SR Legacy CSV files."""
    if explicit:
        base = explicit
        if os.path.isdir(os.path.join(base, SR_LEGACY_SUBDIR)):
            base = os.path.join(base, SR_LEGACY_SUBDIR)
        if not os.path.isfile(os.path.join(base, 'food.csv')):
            sys.exit(f'error: {base} does not contain food.csv')
        return base

    tmp = os.path.join(tempfile.gettempdir(), 'nutri_mvp_sr_legacy')
    target = os.path.join(tmp, SR_LEGACY_SUBDIR)
    if os.path.isfile(os.path.join(target, 'food.csv')):
        print(f'using cached dataset at {target}')
        return target

    os.makedirs(tmp, exist_ok=True)
    archive = os.path.join(tmp, 'sr_legacy.zip')
    print(f'downloading {SR_LEGACY_URL}')
    urllib.request.urlretrieve(SR_LEGACY_URL, archive)
    with zipfile.ZipFile(archive) as zf:
        zf.extractall(tmp)
    return target


def read_macros(dataset: str, wanted: set[str]) -> dict[str, dict]:
    """Return {fdc_id: {'desc': str, 'macros': {...}}} for the wanted ids."""
    csv.field_size_limit(10 ** 7)
    out: dict[str, dict] = {}
    with open(os.path.join(dataset, 'food.csv'), newline='', encoding='utf-8') as fh:
        for row in csv.DictReader(fh):
            if row['fdc_id'] in wanted:
                out[row['fdc_id']] = {'desc': row['description'], 'macros': {}}

    missing = wanted - out.keys()
    if missing:
        sys.exit(f'error: FDC ids not found in dataset: {sorted(missing)}')

    with open(os.path.join(dataset, 'food_nutrient.csv'), newline='', encoding='utf-8') as fh:
        for row in csv.DictReader(fh):
            entry = out.get(row['fdc_id'])
            if entry is None:
                continue
            nid = row['nutrient_id']
            if not nid.isdigit():
                continue
            key = NUTRIENT_IDS.get(int(nid))
            if key is None:
                continue
            try:
                entry['macros'][key] = round(float(row['amount']), 2)
            except ValueError:
                pass

    incomplete = {k: v['macros'].keys() for k, v in out.items()
                  if len(v['macros']) != len(NUTRIENT_IDS)}
    if incomplete:
        sys.exit(f'error: incomplete macro profiles: {incomplete}')
    return out


def build(dataset: str) -> dict:
    usda = read_macros(dataset, {fdc for fdc, _, _ in USDA_FOODS.values()})

    foods = []
    for slug, (fdc_id, name_es, preparation) in sorted(USDA_FOODS.items()):
        entry = usda[fdc_id]
        foods.append({
            'id': slug,
            'nameEs': name_es,
            'preparation': preparation,
            'per100g': {k: entry['macros'][k] for k in
                        ('energyKcal', 'proteinG', 'carbsG', 'fatG')},
            'source': 'usda_sr_legacy',
            'sourceRef': fdc_id,
            'sourceDescription': entry['desc'],
        })

    for slug, spec in sorted(ESTIMATED.items()):
        foods.append({
            'id': slug,
            'nameEs': spec['nameEs'],
            'preparation': spec['preparation'],
            'per100g': spec['per100g'],
            'source': 'estimated',
            'sourceRef': None,
            'estimationReason': spec['reason'],
        })

    return {
        'schemaVersion': 1,
        'generatedBy': 'tool/build_food_table.py',
        'sources': [
            {
                'id': 'usda_sr_legacy',
                'name': 'USDA FoodData Central, SR Legacy (April 2018)',
                'license': 'CC0 1.0 (public domain)',
                'url': 'https://fdc.nal.usda.gov/',
                'attribution': 'U.S. Department of Agriculture, Agricultural Research '
                               'Service. FoodData Central.',
            },
            {
                'id': 'estimated',
                'name': 'Reference values for foods absent from SR Legacy',
                'license': None,
                'url': None,
                'attribution': 'Flagged in-app for user review.',
            },
        ],
        'foods': foods,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--dataset', help='directory holding the SR Legacy CSV files')
    args = parser.parse_args()

    table = build(resolve_dataset(args.dataset))
    os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
    with open(OUTPUT, 'w', encoding='utf-8') as fh:
        json.dump(table, fh, ensure_ascii=False, indent=2)
        fh.write('\n')

    by_source: dict[str, int] = {}
    for food in table['foods']:
        by_source[food['source']] = by_source.get(food['source'], 0) + 1
    print(f"wrote {len(table['foods'])} foods to "
          f"{os.path.relpath(OUTPUT, REPO_ROOT)}  {by_source}")


if __name__ == '__main__':
    main()
