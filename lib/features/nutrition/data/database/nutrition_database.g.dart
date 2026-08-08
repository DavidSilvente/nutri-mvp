// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrition_database.dart';

// ignore_for_file: type=lint
class $PlannedMealsTable extends PlannedMeals
    with TableInfo<$PlannedMealsTable, PlannedMealRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlannedMealsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slotIdMeta = const VerificationMeta('slotId');
  @override
  late final GeneratedColumn<String> slotId = GeneratedColumn<String>(
    'slot_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayEpochMeta = const VerificationMeta(
    'dayEpoch',
  );
  @override
  late final GeneratedColumn<int> dayEpoch = GeneratedColumn<int>(
    'day_epoch',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _energyKcalMeta = const VerificationMeta(
    'energyKcal',
  );
  @override
  late final GeneratedColumn<double> energyKcal = GeneratedColumn<double>(
    'energy_kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
    'carbs_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
    'fat_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    slotId,
    dayEpoch,
    energyKcal,
    proteinG,
    carbsG,
    fatG,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'planned_meals';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlannedMealRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('slot_id')) {
      context.handle(
        _slotIdMeta,
        slotId.isAcceptableOrUnknown(data['slot_id']!, _slotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_slotIdMeta);
    }
    if (data.containsKey('day_epoch')) {
      context.handle(
        _dayEpochMeta,
        dayEpoch.isAcceptableOrUnknown(data['day_epoch']!, _dayEpochMeta),
      );
    }
    if (data.containsKey('energy_kcal')) {
      context.handle(
        _energyKcalMeta,
        energyKcal.isAcceptableOrUnknown(data['energy_kcal']!, _energyKcalMeta),
      );
    } else if (isInserting) {
      context.missing(_energyKcalMeta);
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinGMeta);
    }
    if (data.containsKey('carbs_g')) {
      context.handle(
        _carbsGMeta,
        carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta),
      );
    } else if (isInserting) {
      context.missing(_carbsGMeta);
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    } else if (isInserting) {
      context.missing(_fatGMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {slotId, dayEpoch},
  ];
  @override
  PlannedMealRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlannedMealRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      slotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot_id'],
      )!,
      dayEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_epoch'],
      ),
      energyKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}energy_kcal'],
      )!,
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      )!,
      carbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_g'],
      )!,
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g'],
      )!,
    );
  }

  @override
  $PlannedMealsTable createAlias(String alias) {
    return $PlannedMealsTable(attachedDatabase, alias);
  }
}

class PlannedMealRow extends DataClass implements Insertable<PlannedMealRow> {
  final String id;
  final String slotId;
  final int? dayEpoch;
  final double energyKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  const PlannedMealRow({
    required this.id,
    required this.slotId,
    this.dayEpoch,
    required this.energyKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['slot_id'] = Variable<String>(slotId);
    if (!nullToAbsent || dayEpoch != null) {
      map['day_epoch'] = Variable<int>(dayEpoch);
    }
    map['energy_kcal'] = Variable<double>(energyKcal);
    map['protein_g'] = Variable<double>(proteinG);
    map['carbs_g'] = Variable<double>(carbsG);
    map['fat_g'] = Variable<double>(fatG);
    return map;
  }

  PlannedMealsCompanion toCompanion(bool nullToAbsent) {
    return PlannedMealsCompanion(
      id: Value(id),
      slotId: Value(slotId),
      dayEpoch: dayEpoch == null && nullToAbsent
          ? const Value.absent()
          : Value(dayEpoch),
      energyKcal: Value(energyKcal),
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      fatG: Value(fatG),
    );
  }

  factory PlannedMealRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlannedMealRow(
      id: serializer.fromJson<String>(json['id']),
      slotId: serializer.fromJson<String>(json['slotId']),
      dayEpoch: serializer.fromJson<int?>(json['dayEpoch']),
      energyKcal: serializer.fromJson<double>(json['energyKcal']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      carbsG: serializer.fromJson<double>(json['carbsG']),
      fatG: serializer.fromJson<double>(json['fatG']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'slotId': serializer.toJson<String>(slotId),
      'dayEpoch': serializer.toJson<int?>(dayEpoch),
      'energyKcal': serializer.toJson<double>(energyKcal),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbsG': serializer.toJson<double>(carbsG),
      'fatG': serializer.toJson<double>(fatG),
    };
  }

  PlannedMealRow copyWith({
    String? id,
    String? slotId,
    Value<int?> dayEpoch = const Value.absent(),
    double? energyKcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
  }) => PlannedMealRow(
    id: id ?? this.id,
    slotId: slotId ?? this.slotId,
    dayEpoch: dayEpoch.present ? dayEpoch.value : this.dayEpoch,
    energyKcal: energyKcal ?? this.energyKcal,
    proteinG: proteinG ?? this.proteinG,
    carbsG: carbsG ?? this.carbsG,
    fatG: fatG ?? this.fatG,
  );
  PlannedMealRow copyWithCompanion(PlannedMealsCompanion data) {
    return PlannedMealRow(
      id: data.id.present ? data.id.value : this.id,
      slotId: data.slotId.present ? data.slotId.value : this.slotId,
      dayEpoch: data.dayEpoch.present ? data.dayEpoch.value : this.dayEpoch,
      energyKcal: data.energyKcal.present
          ? data.energyKcal.value
          : this.energyKcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlannedMealRow(')
          ..write('id: $id, ')
          ..write('slotId: $slotId, ')
          ..write('dayEpoch: $dayEpoch, ')
          ..write('energyKcal: $energyKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, slotId, dayEpoch, energyKcal, proteinG, carbsG, fatG);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlannedMealRow &&
          other.id == this.id &&
          other.slotId == this.slotId &&
          other.dayEpoch == this.dayEpoch &&
          other.energyKcal == this.energyKcal &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.fatG == this.fatG);
}

class PlannedMealsCompanion extends UpdateCompanion<PlannedMealRow> {
  final Value<String> id;
  final Value<String> slotId;
  final Value<int?> dayEpoch;
  final Value<double> energyKcal;
  final Value<double> proteinG;
  final Value<double> carbsG;
  final Value<double> fatG;
  final Value<int> rowid;
  const PlannedMealsCompanion({
    this.id = const Value.absent(),
    this.slotId = const Value.absent(),
    this.dayEpoch = const Value.absent(),
    this.energyKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlannedMealsCompanion.insert({
    required String id,
    required String slotId,
    this.dayEpoch = const Value.absent(),
    required double energyKcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       slotId = Value(slotId),
       energyKcal = Value(energyKcal),
       proteinG = Value(proteinG),
       carbsG = Value(carbsG),
       fatG = Value(fatG);
  static Insertable<PlannedMealRow> custom({
    Expression<String>? id,
    Expression<String>? slotId,
    Expression<int>? dayEpoch,
    Expression<double>? energyKcal,
    Expression<double>? proteinG,
    Expression<double>? carbsG,
    Expression<double>? fatG,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (slotId != null) 'slot_id': slotId,
      if (dayEpoch != null) 'day_epoch': dayEpoch,
      if (energyKcal != null) 'energy_kcal': energyKcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlannedMealsCompanion copyWith({
    Value<String>? id,
    Value<String>? slotId,
    Value<int?>? dayEpoch,
    Value<double>? energyKcal,
    Value<double>? proteinG,
    Value<double>? carbsG,
    Value<double>? fatG,
    Value<int>? rowid,
  }) {
    return PlannedMealsCompanion(
      id: id ?? this.id,
      slotId: slotId ?? this.slotId,
      dayEpoch: dayEpoch ?? this.dayEpoch,
      energyKcal: energyKcal ?? this.energyKcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (slotId.present) {
      map['slot_id'] = Variable<String>(slotId.value);
    }
    if (dayEpoch.present) {
      map['day_epoch'] = Variable<int>(dayEpoch.value);
    }
    if (energyKcal.present) {
      map['energy_kcal'] = Variable<double>(energyKcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlannedMealsCompanion(')
          ..write('id: $id, ')
          ..write('slotId: $slotId, ')
          ..write('dayEpoch: $dayEpoch, ')
          ..write('energyKcal: $energyKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NutritionEntriesTable extends NutritionEntries
    with TableInfo<$NutritionEntriesTable, NutritionEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NutritionEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayEpochMeta = const VerificationMeta(
    'dayEpoch',
  );
  @override
  late final GeneratedColumn<int> dayEpoch = GeneratedColumn<int>(
    'day_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _energyKcalMeta = const VerificationMeta(
    'energyKcal',
  );
  @override
  late final GeneratedColumn<double> energyKcal = GeneratedColumn<double>(
    'energy_kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
    'carbs_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
    'fat_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedMealIdMeta = const VerificationMeta(
    'plannedMealId',
  );
  @override
  late final GeneratedColumn<String> plannedMealId = GeneratedColumn<String>(
    'planned_meal_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES planned_meals (id) ON DELETE SET NULL',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recordedAt,
    dayEpoch,
    energyKcal,
    proteinG,
    carbsG,
    fatG,
    plannedMealId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nutrition_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<NutritionEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('day_epoch')) {
      context.handle(
        _dayEpochMeta,
        dayEpoch.isAcceptableOrUnknown(data['day_epoch']!, _dayEpochMeta),
      );
    } else if (isInserting) {
      context.missing(_dayEpochMeta);
    }
    if (data.containsKey('energy_kcal')) {
      context.handle(
        _energyKcalMeta,
        energyKcal.isAcceptableOrUnknown(data['energy_kcal']!, _energyKcalMeta),
      );
    } else if (isInserting) {
      context.missing(_energyKcalMeta);
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinGMeta);
    }
    if (data.containsKey('carbs_g')) {
      context.handle(
        _carbsGMeta,
        carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta),
      );
    } else if (isInserting) {
      context.missing(_carbsGMeta);
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    } else if (isInserting) {
      context.missing(_fatGMeta);
    }
    if (data.containsKey('planned_meal_id')) {
      context.handle(
        _plannedMealIdMeta,
        plannedMealId.isAcceptableOrUnknown(
          data['planned_meal_id']!,
          _plannedMealIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NutritionEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NutritionEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      dayEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_epoch'],
      )!,
      energyKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}energy_kcal'],
      )!,
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      )!,
      carbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_g'],
      )!,
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g'],
      )!,
      plannedMealId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}planned_meal_id'],
      ),
    );
  }

  @override
  $NutritionEntriesTable createAlias(String alias) {
    return $NutritionEntriesTable(attachedDatabase, alias);
  }
}

class NutritionEntryRow extends DataClass
    implements Insertable<NutritionEntryRow> {
  final String id;
  final DateTime recordedAt;

  /// Stable integer key for the calendar day, sourced from
  /// `NutritionDay.epochDay` — never recomputed inline here.
  final int dayEpoch;
  final double energyKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  /// Optional link to the [PlannedMeals] row this intake was logged against.
  ///
  /// Nullable because unplanned intake must still be recordable. The delete
  /// action is `setNull`, NOT `cascade`: un-planning a meal must never erase
  /// the historical fact that food was eaten — the entry survives and simply
  /// stops counting towards adherence.
  final String? plannedMealId;
  const NutritionEntryRow({
    required this.id,
    required this.recordedAt,
    required this.dayEpoch,
    required this.energyKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.plannedMealId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['day_epoch'] = Variable<int>(dayEpoch);
    map['energy_kcal'] = Variable<double>(energyKcal);
    map['protein_g'] = Variable<double>(proteinG);
    map['carbs_g'] = Variable<double>(carbsG);
    map['fat_g'] = Variable<double>(fatG);
    if (!nullToAbsent || plannedMealId != null) {
      map['planned_meal_id'] = Variable<String>(plannedMealId);
    }
    return map;
  }

  NutritionEntriesCompanion toCompanion(bool nullToAbsent) {
    return NutritionEntriesCompanion(
      id: Value(id),
      recordedAt: Value(recordedAt),
      dayEpoch: Value(dayEpoch),
      energyKcal: Value(energyKcal),
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      fatG: Value(fatG),
      plannedMealId: plannedMealId == null && nullToAbsent
          ? const Value.absent()
          : Value(plannedMealId),
    );
  }

  factory NutritionEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NutritionEntryRow(
      id: serializer.fromJson<String>(json['id']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      dayEpoch: serializer.fromJson<int>(json['dayEpoch']),
      energyKcal: serializer.fromJson<double>(json['energyKcal']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      carbsG: serializer.fromJson<double>(json['carbsG']),
      fatG: serializer.fromJson<double>(json['fatG']),
      plannedMealId: serializer.fromJson<String?>(json['plannedMealId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'dayEpoch': serializer.toJson<int>(dayEpoch),
      'energyKcal': serializer.toJson<double>(energyKcal),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbsG': serializer.toJson<double>(carbsG),
      'fatG': serializer.toJson<double>(fatG),
      'plannedMealId': serializer.toJson<String?>(plannedMealId),
    };
  }

  NutritionEntryRow copyWith({
    String? id,
    DateTime? recordedAt,
    int? dayEpoch,
    double? energyKcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
    Value<String?> plannedMealId = const Value.absent(),
  }) => NutritionEntryRow(
    id: id ?? this.id,
    recordedAt: recordedAt ?? this.recordedAt,
    dayEpoch: dayEpoch ?? this.dayEpoch,
    energyKcal: energyKcal ?? this.energyKcal,
    proteinG: proteinG ?? this.proteinG,
    carbsG: carbsG ?? this.carbsG,
    fatG: fatG ?? this.fatG,
    plannedMealId: plannedMealId.present
        ? plannedMealId.value
        : this.plannedMealId,
  );
  NutritionEntryRow copyWithCompanion(NutritionEntriesCompanion data) {
    return NutritionEntryRow(
      id: data.id.present ? data.id.value : this.id,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      dayEpoch: data.dayEpoch.present ? data.dayEpoch.value : this.dayEpoch,
      energyKcal: data.energyKcal.present
          ? data.energyKcal.value
          : this.energyKcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      plannedMealId: data.plannedMealId.present
          ? data.plannedMealId.value
          : this.plannedMealId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NutritionEntryRow(')
          ..write('id: $id, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('dayEpoch: $dayEpoch, ')
          ..write('energyKcal: $energyKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('plannedMealId: $plannedMealId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    recordedAt,
    dayEpoch,
    energyKcal,
    proteinG,
    carbsG,
    fatG,
    plannedMealId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NutritionEntryRow &&
          other.id == this.id &&
          other.recordedAt == this.recordedAt &&
          other.dayEpoch == this.dayEpoch &&
          other.energyKcal == this.energyKcal &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.fatG == this.fatG &&
          other.plannedMealId == this.plannedMealId);
}

class NutritionEntriesCompanion extends UpdateCompanion<NutritionEntryRow> {
  final Value<String> id;
  final Value<DateTime> recordedAt;
  final Value<int> dayEpoch;
  final Value<double> energyKcal;
  final Value<double> proteinG;
  final Value<double> carbsG;
  final Value<double> fatG;
  final Value<String?> plannedMealId;
  final Value<int> rowid;
  const NutritionEntriesCompanion({
    this.id = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.dayEpoch = const Value.absent(),
    this.energyKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.plannedMealId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NutritionEntriesCompanion.insert({
    required String id,
    required DateTime recordedAt,
    required int dayEpoch,
    required double energyKcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
    this.plannedMealId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       recordedAt = Value(recordedAt),
       dayEpoch = Value(dayEpoch),
       energyKcal = Value(energyKcal),
       proteinG = Value(proteinG),
       carbsG = Value(carbsG),
       fatG = Value(fatG);
  static Insertable<NutritionEntryRow> custom({
    Expression<String>? id,
    Expression<DateTime>? recordedAt,
    Expression<int>? dayEpoch,
    Expression<double>? energyKcal,
    Expression<double>? proteinG,
    Expression<double>? carbsG,
    Expression<double>? fatG,
    Expression<String>? plannedMealId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (dayEpoch != null) 'day_epoch': dayEpoch,
      if (energyKcal != null) 'energy_kcal': energyKcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (plannedMealId != null) 'planned_meal_id': plannedMealId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NutritionEntriesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? recordedAt,
    Value<int>? dayEpoch,
    Value<double>? energyKcal,
    Value<double>? proteinG,
    Value<double>? carbsG,
    Value<double>? fatG,
    Value<String?>? plannedMealId,
    Value<int>? rowid,
  }) {
    return NutritionEntriesCompanion(
      id: id ?? this.id,
      recordedAt: recordedAt ?? this.recordedAt,
      dayEpoch: dayEpoch ?? this.dayEpoch,
      energyKcal: energyKcal ?? this.energyKcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      plannedMealId: plannedMealId ?? this.plannedMealId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (dayEpoch.present) {
      map['day_epoch'] = Variable<int>(dayEpoch.value);
    }
    if (energyKcal.present) {
      map['energy_kcal'] = Variable<double>(energyKcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (plannedMealId.present) {
      map['planned_meal_id'] = Variable<String>(plannedMealId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NutritionEntriesCompanion(')
          ..write('id: $id, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('dayEpoch: $dayEpoch, ')
          ..write('energyKcal: $energyKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('plannedMealId: $plannedMealId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HydrationEntriesTable extends HydrationEntries
    with TableInfo<$HydrationEntriesTable, HydrationEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HydrationEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayEpochMeta = const VerificationMeta(
    'dayEpoch',
  );
  @override
  late final GeneratedColumn<int> dayEpoch = GeneratedColumn<int>(
    'day_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _waterMlMeta = const VerificationMeta(
    'waterMl',
  );
  @override
  late final GeneratedColumn<double> waterMl = GeneratedColumn<double>(
    'water_ml',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, recordedAt, dayEpoch, waterMl];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hydration_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<HydrationEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('day_epoch')) {
      context.handle(
        _dayEpochMeta,
        dayEpoch.isAcceptableOrUnknown(data['day_epoch']!, _dayEpochMeta),
      );
    } else if (isInserting) {
      context.missing(_dayEpochMeta);
    }
    if (data.containsKey('water_ml')) {
      context.handle(
        _waterMlMeta,
        waterMl.isAcceptableOrUnknown(data['water_ml']!, _waterMlMeta),
      );
    } else if (isInserting) {
      context.missing(_waterMlMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HydrationEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HydrationEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      dayEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_epoch'],
      )!,
      waterMl: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}water_ml'],
      )!,
    );
  }

  @override
  $HydrationEntriesTable createAlias(String alias) {
    return $HydrationEntriesTable(attachedDatabase, alias);
  }
}

class HydrationEntryRow extends DataClass
    implements Insertable<HydrationEntryRow> {
  final String id;
  final DateTime recordedAt;

  /// Stable integer key for the calendar day, sourced from
  /// `NutritionDay.epochDay` — never recomputed inline here.
  final int dayEpoch;
  final double waterMl;
  const HydrationEntryRow({
    required this.id,
    required this.recordedAt,
    required this.dayEpoch,
    required this.waterMl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['day_epoch'] = Variable<int>(dayEpoch);
    map['water_ml'] = Variable<double>(waterMl);
    return map;
  }

  HydrationEntriesCompanion toCompanion(bool nullToAbsent) {
    return HydrationEntriesCompanion(
      id: Value(id),
      recordedAt: Value(recordedAt),
      dayEpoch: Value(dayEpoch),
      waterMl: Value(waterMl),
    );
  }

  factory HydrationEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HydrationEntryRow(
      id: serializer.fromJson<String>(json['id']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      dayEpoch: serializer.fromJson<int>(json['dayEpoch']),
      waterMl: serializer.fromJson<double>(json['waterMl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'dayEpoch': serializer.toJson<int>(dayEpoch),
      'waterMl': serializer.toJson<double>(waterMl),
    };
  }

  HydrationEntryRow copyWith({
    String? id,
    DateTime? recordedAt,
    int? dayEpoch,
    double? waterMl,
  }) => HydrationEntryRow(
    id: id ?? this.id,
    recordedAt: recordedAt ?? this.recordedAt,
    dayEpoch: dayEpoch ?? this.dayEpoch,
    waterMl: waterMl ?? this.waterMl,
  );
  HydrationEntryRow copyWithCompanion(HydrationEntriesCompanion data) {
    return HydrationEntryRow(
      id: data.id.present ? data.id.value : this.id,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      dayEpoch: data.dayEpoch.present ? data.dayEpoch.value : this.dayEpoch,
      waterMl: data.waterMl.present ? data.waterMl.value : this.waterMl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HydrationEntryRow(')
          ..write('id: $id, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('dayEpoch: $dayEpoch, ')
          ..write('waterMl: $waterMl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, recordedAt, dayEpoch, waterMl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HydrationEntryRow &&
          other.id == this.id &&
          other.recordedAt == this.recordedAt &&
          other.dayEpoch == this.dayEpoch &&
          other.waterMl == this.waterMl);
}

class HydrationEntriesCompanion extends UpdateCompanion<HydrationEntryRow> {
  final Value<String> id;
  final Value<DateTime> recordedAt;
  final Value<int> dayEpoch;
  final Value<double> waterMl;
  final Value<int> rowid;
  const HydrationEntriesCompanion({
    this.id = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.dayEpoch = const Value.absent(),
    this.waterMl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HydrationEntriesCompanion.insert({
    required String id,
    required DateTime recordedAt,
    required int dayEpoch,
    required double waterMl,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       recordedAt = Value(recordedAt),
       dayEpoch = Value(dayEpoch),
       waterMl = Value(waterMl);
  static Insertable<HydrationEntryRow> custom({
    Expression<String>? id,
    Expression<DateTime>? recordedAt,
    Expression<int>? dayEpoch,
    Expression<double>? waterMl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (dayEpoch != null) 'day_epoch': dayEpoch,
      if (waterMl != null) 'water_ml': waterMl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HydrationEntriesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? recordedAt,
    Value<int>? dayEpoch,
    Value<double>? waterMl,
    Value<int>? rowid,
  }) {
    return HydrationEntriesCompanion(
      id: id ?? this.id,
      recordedAt: recordedAt ?? this.recordedAt,
      dayEpoch: dayEpoch ?? this.dayEpoch,
      waterMl: waterMl ?? this.waterMl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (dayEpoch.present) {
      map['day_epoch'] = Variable<int>(dayEpoch.value);
    }
    if (waterMl.present) {
      map['water_ml'] = Variable<double>(waterMl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HydrationEntriesCompanion(')
          ..write('id: $id, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('dayEpoch: $dayEpoch, ')
          ..write('waterMl: $waterMl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealSubstitutesTable extends MealSubstitutes
    with TableInfo<$MealSubstitutesTable, MealSubstituteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealSubstitutesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedMealIdMeta = const VerificationMeta(
    'plannedMealId',
  );
  @override
  late final GeneratedColumn<String> plannedMealId = GeneratedColumn<String>(
    'planned_meal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES planned_meals (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _energyKcalMeta = const VerificationMeta(
    'energyKcal',
  );
  @override
  late final GeneratedColumn<double> energyKcal = GeneratedColumn<double>(
    'energy_kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
    'carbs_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
    'fat_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    plannedMealId,
    label,
    energyKcal,
    proteinG,
    carbsG,
    fatG,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_substitutes';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealSubstituteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('planned_meal_id')) {
      context.handle(
        _plannedMealIdMeta,
        plannedMealId.isAcceptableOrUnknown(
          data['planned_meal_id']!,
          _plannedMealIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedMealIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('energy_kcal')) {
      context.handle(
        _energyKcalMeta,
        energyKcal.isAcceptableOrUnknown(data['energy_kcal']!, _energyKcalMeta),
      );
    } else if (isInserting) {
      context.missing(_energyKcalMeta);
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinGMeta);
    }
    if (data.containsKey('carbs_g')) {
      context.handle(
        _carbsGMeta,
        carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta),
      );
    } else if (isInserting) {
      context.missing(_carbsGMeta);
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    } else if (isInserting) {
      context.missing(_fatGMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealSubstituteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealSubstituteRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      plannedMealId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}planned_meal_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      energyKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}energy_kcal'],
      )!,
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      )!,
      carbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_g'],
      )!,
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g'],
      )!,
    );
  }

  @override
  $MealSubstitutesTable createAlias(String alias) {
    return $MealSubstitutesTable(attachedDatabase, alias);
  }
}

class MealSubstituteRow extends DataClass
    implements Insertable<MealSubstituteRow> {
  final String id;
  final String plannedMealId;
  final String label;
  final double energyKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  const MealSubstituteRow({
    required this.id,
    required this.plannedMealId,
    required this.label,
    required this.energyKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['planned_meal_id'] = Variable<String>(plannedMealId);
    map['label'] = Variable<String>(label);
    map['energy_kcal'] = Variable<double>(energyKcal);
    map['protein_g'] = Variable<double>(proteinG);
    map['carbs_g'] = Variable<double>(carbsG);
    map['fat_g'] = Variable<double>(fatG);
    return map;
  }

  MealSubstitutesCompanion toCompanion(bool nullToAbsent) {
    return MealSubstitutesCompanion(
      id: Value(id),
      plannedMealId: Value(plannedMealId),
      label: Value(label),
      energyKcal: Value(energyKcal),
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      fatG: Value(fatG),
    );
  }

  factory MealSubstituteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealSubstituteRow(
      id: serializer.fromJson<String>(json['id']),
      plannedMealId: serializer.fromJson<String>(json['plannedMealId']),
      label: serializer.fromJson<String>(json['label']),
      energyKcal: serializer.fromJson<double>(json['energyKcal']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      carbsG: serializer.fromJson<double>(json['carbsG']),
      fatG: serializer.fromJson<double>(json['fatG']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'plannedMealId': serializer.toJson<String>(plannedMealId),
      'label': serializer.toJson<String>(label),
      'energyKcal': serializer.toJson<double>(energyKcal),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbsG': serializer.toJson<double>(carbsG),
      'fatG': serializer.toJson<double>(fatG),
    };
  }

  MealSubstituteRow copyWith({
    String? id,
    String? plannedMealId,
    String? label,
    double? energyKcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
  }) => MealSubstituteRow(
    id: id ?? this.id,
    plannedMealId: plannedMealId ?? this.plannedMealId,
    label: label ?? this.label,
    energyKcal: energyKcal ?? this.energyKcal,
    proteinG: proteinG ?? this.proteinG,
    carbsG: carbsG ?? this.carbsG,
    fatG: fatG ?? this.fatG,
  );
  MealSubstituteRow copyWithCompanion(MealSubstitutesCompanion data) {
    return MealSubstituteRow(
      id: data.id.present ? data.id.value : this.id,
      plannedMealId: data.plannedMealId.present
          ? data.plannedMealId.value
          : this.plannedMealId,
      label: data.label.present ? data.label.value : this.label,
      energyKcal: data.energyKcal.present
          ? data.energyKcal.value
          : this.energyKcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealSubstituteRow(')
          ..write('id: $id, ')
          ..write('plannedMealId: $plannedMealId, ')
          ..write('label: $label, ')
          ..write('energyKcal: $energyKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, plannedMealId, label, energyKcal, proteinG, carbsG, fatG);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealSubstituteRow &&
          other.id == this.id &&
          other.plannedMealId == this.plannedMealId &&
          other.label == this.label &&
          other.energyKcal == this.energyKcal &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.fatG == this.fatG);
}

class MealSubstitutesCompanion extends UpdateCompanion<MealSubstituteRow> {
  final Value<String> id;
  final Value<String> plannedMealId;
  final Value<String> label;
  final Value<double> energyKcal;
  final Value<double> proteinG;
  final Value<double> carbsG;
  final Value<double> fatG;
  final Value<int> rowid;
  const MealSubstitutesCompanion({
    this.id = const Value.absent(),
    this.plannedMealId = const Value.absent(),
    this.label = const Value.absent(),
    this.energyKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealSubstitutesCompanion.insert({
    required String id,
    required String plannedMealId,
    required String label,
    required double energyKcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       plannedMealId = Value(plannedMealId),
       label = Value(label),
       energyKcal = Value(energyKcal),
       proteinG = Value(proteinG),
       carbsG = Value(carbsG),
       fatG = Value(fatG);
  static Insertable<MealSubstituteRow> custom({
    Expression<String>? id,
    Expression<String>? plannedMealId,
    Expression<String>? label,
    Expression<double>? energyKcal,
    Expression<double>? proteinG,
    Expression<double>? carbsG,
    Expression<double>? fatG,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plannedMealId != null) 'planned_meal_id': plannedMealId,
      if (label != null) 'label': label,
      if (energyKcal != null) 'energy_kcal': energyKcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealSubstitutesCompanion copyWith({
    Value<String>? id,
    Value<String>? plannedMealId,
    Value<String>? label,
    Value<double>? energyKcal,
    Value<double>? proteinG,
    Value<double>? carbsG,
    Value<double>? fatG,
    Value<int>? rowid,
  }) {
    return MealSubstitutesCompanion(
      id: id ?? this.id,
      plannedMealId: plannedMealId ?? this.plannedMealId,
      label: label ?? this.label,
      energyKcal: energyKcal ?? this.energyKcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (plannedMealId.present) {
      map['planned_meal_id'] = Variable<String>(plannedMealId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (energyKcal.present) {
      map['energy_kcal'] = Variable<double>(energyKcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealSubstitutesCompanion(')
          ..write('id: $id, ')
          ..write('plannedMealId: $plannedMealId, ')
          ..write('label: $label, ')
          ..write('energyKcal: $energyKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MenuPhotosTable extends MenuPhotos
    with TableInfo<$MenuPhotosTable, MenuPhotoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MenuPhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localUriMeta = const VerificationMeta(
    'localUri',
  );
  @override
  late final GeneratedColumn<String> localUri = GeneratedColumn<String>(
    'local_uri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, localUri, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'menu_photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<MenuPhotoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('local_uri')) {
      context.handle(
        _localUriMeta,
        localUri.isAcceptableOrUnknown(data['local_uri']!, _localUriMeta),
      );
    } else if (isInserting) {
      context.missing(_localUriMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MenuPhotoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MenuPhotoRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      localUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_uri'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MenuPhotosTable createAlias(String alias) {
    return $MenuPhotosTable(attachedDatabase, alias);
  }
}

class MenuPhotoRow extends DataClass implements Insertable<MenuPhotoRow> {
  final String id;
  final String localUri;
  final DateTime createdAt;
  const MenuPhotoRow({
    required this.id,
    required this.localUri,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['local_uri'] = Variable<String>(localUri);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MenuPhotosCompanion toCompanion(bool nullToAbsent) {
    return MenuPhotosCompanion(
      id: Value(id),
      localUri: Value(localUri),
      createdAt: Value(createdAt),
    );
  }

  factory MenuPhotoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MenuPhotoRow(
      id: serializer.fromJson<String>(json['id']),
      localUri: serializer.fromJson<String>(json['localUri']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'localUri': serializer.toJson<String>(localUri),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MenuPhotoRow copyWith({String? id, String? localUri, DateTime? createdAt}) =>
      MenuPhotoRow(
        id: id ?? this.id,
        localUri: localUri ?? this.localUri,
        createdAt: createdAt ?? this.createdAt,
      );
  MenuPhotoRow copyWithCompanion(MenuPhotosCompanion data) {
    return MenuPhotoRow(
      id: data.id.present ? data.id.value : this.id,
      localUri: data.localUri.present ? data.localUri.value : this.localUri,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MenuPhotoRow(')
          ..write('id: $id, ')
          ..write('localUri: $localUri, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, localUri, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MenuPhotoRow &&
          other.id == this.id &&
          other.localUri == this.localUri &&
          other.createdAt == this.createdAt);
}

class MenuPhotosCompanion extends UpdateCompanion<MenuPhotoRow> {
  final Value<String> id;
  final Value<String> localUri;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MenuPhotosCompanion({
    this.id = const Value.absent(),
    this.localUri = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MenuPhotosCompanion.insert({
    required String id,
    required String localUri,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       localUri = Value(localUri),
       createdAt = Value(createdAt);
  static Insertable<MenuPhotoRow> custom({
    Expression<String>? id,
    Expression<String>? localUri,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localUri != null) 'local_uri': localUri,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MenuPhotosCompanion copyWith({
    Value<String>? id,
    Value<String>? localUri,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MenuPhotosCompanion(
      id: id ?? this.id,
      localUri: localUri ?? this.localUri,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (localUri.present) {
      map['local_uri'] = Variable<String>(localUri.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MenuPhotosCompanion(')
          ..write('id: $id, ')
          ..write('localUri: $localUri, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MenuItemsTable extends MenuItems
    with TableInfo<$MenuItemsTable, MenuItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MenuItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoIdMeta = const VerificationMeta(
    'photoId',
  );
  @override
  late final GeneratedColumn<String> photoId = GeneratedColumn<String>(
    'photo_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES menu_photos (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _energyKcalMeta = const VerificationMeta(
    'energyKcal',
  );
  @override
  late final GeneratedColumn<double> energyKcal = GeneratedColumn<double>(
    'energy_kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
    'carbs_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
    'fat_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    photoId,
    label,
    energyKcal,
    proteinG,
    carbsG,
    fatG,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'menu_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<MenuItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('photo_id')) {
      context.handle(
        _photoIdMeta,
        photoId.isAcceptableOrUnknown(data['photo_id']!, _photoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_photoIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('energy_kcal')) {
      context.handle(
        _energyKcalMeta,
        energyKcal.isAcceptableOrUnknown(data['energy_kcal']!, _energyKcalMeta),
      );
    } else if (isInserting) {
      context.missing(_energyKcalMeta);
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinGMeta);
    }
    if (data.containsKey('carbs_g')) {
      context.handle(
        _carbsGMeta,
        carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta),
      );
    } else if (isInserting) {
      context.missing(_carbsGMeta);
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    } else if (isInserting) {
      context.missing(_fatGMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MenuItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MenuItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      photoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      energyKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}energy_kcal'],
      )!,
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      )!,
      carbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_g'],
      )!,
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g'],
      )!,
    );
  }

  @override
  $MenuItemsTable createAlias(String alias) {
    return $MenuItemsTable(attachedDatabase, alias);
  }
}

class MenuItemRow extends DataClass implements Insertable<MenuItemRow> {
  final String id;
  final String photoId;
  final String label;
  final double energyKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  const MenuItemRow({
    required this.id,
    required this.photoId,
    required this.label,
    required this.energyKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['photo_id'] = Variable<String>(photoId);
    map['label'] = Variable<String>(label);
    map['energy_kcal'] = Variable<double>(energyKcal);
    map['protein_g'] = Variable<double>(proteinG);
    map['carbs_g'] = Variable<double>(carbsG);
    map['fat_g'] = Variable<double>(fatG);
    return map;
  }

  MenuItemsCompanion toCompanion(bool nullToAbsent) {
    return MenuItemsCompanion(
      id: Value(id),
      photoId: Value(photoId),
      label: Value(label),
      energyKcal: Value(energyKcal),
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      fatG: Value(fatG),
    );
  }

  factory MenuItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MenuItemRow(
      id: serializer.fromJson<String>(json['id']),
      photoId: serializer.fromJson<String>(json['photoId']),
      label: serializer.fromJson<String>(json['label']),
      energyKcal: serializer.fromJson<double>(json['energyKcal']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      carbsG: serializer.fromJson<double>(json['carbsG']),
      fatG: serializer.fromJson<double>(json['fatG']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'photoId': serializer.toJson<String>(photoId),
      'label': serializer.toJson<String>(label),
      'energyKcal': serializer.toJson<double>(energyKcal),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbsG': serializer.toJson<double>(carbsG),
      'fatG': serializer.toJson<double>(fatG),
    };
  }

  MenuItemRow copyWith({
    String? id,
    String? photoId,
    String? label,
    double? energyKcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
  }) => MenuItemRow(
    id: id ?? this.id,
    photoId: photoId ?? this.photoId,
    label: label ?? this.label,
    energyKcal: energyKcal ?? this.energyKcal,
    proteinG: proteinG ?? this.proteinG,
    carbsG: carbsG ?? this.carbsG,
    fatG: fatG ?? this.fatG,
  );
  MenuItemRow copyWithCompanion(MenuItemsCompanion data) {
    return MenuItemRow(
      id: data.id.present ? data.id.value : this.id,
      photoId: data.photoId.present ? data.photoId.value : this.photoId,
      label: data.label.present ? data.label.value : this.label,
      energyKcal: data.energyKcal.present
          ? data.energyKcal.value
          : this.energyKcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MenuItemRow(')
          ..write('id: $id, ')
          ..write('photoId: $photoId, ')
          ..write('label: $label, ')
          ..write('energyKcal: $energyKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, photoId, label, energyKcal, proteinG, carbsG, fatG);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MenuItemRow &&
          other.id == this.id &&
          other.photoId == this.photoId &&
          other.label == this.label &&
          other.energyKcal == this.energyKcal &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.fatG == this.fatG);
}

class MenuItemsCompanion extends UpdateCompanion<MenuItemRow> {
  final Value<String> id;
  final Value<String> photoId;
  final Value<String> label;
  final Value<double> energyKcal;
  final Value<double> proteinG;
  final Value<double> carbsG;
  final Value<double> fatG;
  final Value<int> rowid;
  const MenuItemsCompanion({
    this.id = const Value.absent(),
    this.photoId = const Value.absent(),
    this.label = const Value.absent(),
    this.energyKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MenuItemsCompanion.insert({
    required String id,
    required String photoId,
    required String label,
    required double energyKcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       photoId = Value(photoId),
       label = Value(label),
       energyKcal = Value(energyKcal),
       proteinG = Value(proteinG),
       carbsG = Value(carbsG),
       fatG = Value(fatG);
  static Insertable<MenuItemRow> custom({
    Expression<String>? id,
    Expression<String>? photoId,
    Expression<String>? label,
    Expression<double>? energyKcal,
    Expression<double>? proteinG,
    Expression<double>? carbsG,
    Expression<double>? fatG,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (photoId != null) 'photo_id': photoId,
      if (label != null) 'label': label,
      if (energyKcal != null) 'energy_kcal': energyKcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MenuItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? photoId,
    Value<String>? label,
    Value<double>? energyKcal,
    Value<double>? proteinG,
    Value<double>? carbsG,
    Value<double>? fatG,
    Value<int>? rowid,
  }) {
    return MenuItemsCompanion(
      id: id ?? this.id,
      photoId: photoId ?? this.photoId,
      label: label ?? this.label,
      energyKcal: energyKcal ?? this.energyKcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (photoId.present) {
      map['photo_id'] = Variable<String>(photoId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (energyKcal.present) {
      map['energy_kcal'] = Variable<double>(energyKcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MenuItemsCompanion(')
          ..write('id: $id, ')
          ..write('photoId: $photoId, ')
          ..write('label: $label, ')
          ..write('energyKcal: $energyKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DietPlanRecordsTable extends DietPlanRecords
    with TableInfo<$DietPlanRecordsTable, DietPlanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DietPlanRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _documentMeta = const VerificationMeta(
    'document',
  );
  @override
  late final GeneratedColumn<String> document = GeneratedColumn<String>(
    'document',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _declaredDailyEnergyKcalMeta =
      const VerificationMeta('declaredDailyEnergyKcal');
  @override
  late final GeneratedColumn<double> declaredDailyEnergyKcal =
      GeneratedColumn<double>(
        'declared_daily_energy_kcal',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sourceLabelMeta = const VerificationMeta(
    'sourceLabel',
  );
  @override
  late final GeneratedColumn<String> sourceLabel = GeneratedColumn<String>(
    'source_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    document,
    declaredDailyEnergyKcal,
    isDefault,
    sourceLabel,
    importedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'diet_plan_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<DietPlanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('document')) {
      context.handle(
        _documentMeta,
        document.isAcceptableOrUnknown(data['document']!, _documentMeta),
      );
    } else if (isInserting) {
      context.missing(_documentMeta);
    }
    if (data.containsKey('declared_daily_energy_kcal')) {
      context.handle(
        _declaredDailyEnergyKcalMeta,
        declaredDailyEnergyKcal.isAcceptableOrUnknown(
          data['declared_daily_energy_kcal']!,
          _declaredDailyEnergyKcalMeta,
        ),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('source_label')) {
      context.handle(
        _sourceLabelMeta,
        sourceLabel.isAcceptableOrUnknown(
          data['source_label']!,
          _sourceLabelMeta,
        ),
      );
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DietPlanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DietPlanRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      document: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document'],
      )!,
      declaredDailyEnergyKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}declared_daily_energy_kcal'],
      ),
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      sourceLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_label'],
      ),
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      )!,
    );
  }

  @override
  $DietPlanRecordsTable createAlias(String alias) {
    return $DietPlanRecordsTable(attachedDatabase, alias);
  }
}

class DietPlanRow extends DataClass implements Insertable<DietPlanRow> {
  final String id;
  final String name;

  /// The normalized plan JSON, as decoded by `DietPlanCodec`.
  final String document;

  /// Headline daily energy the source plan advertised, for display only.
  final double? declaredDailyEnergyKcal;
  final bool isDefault;

  /// Where the plan came from, e.g. the imported file name.
  final String? sourceLabel;
  final DateTime importedAt;
  const DietPlanRow({
    required this.id,
    required this.name,
    required this.document,
    this.declaredDailyEnergyKcal,
    required this.isDefault,
    this.sourceLabel,
    required this.importedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['document'] = Variable<String>(document);
    if (!nullToAbsent || declaredDailyEnergyKcal != null) {
      map['declared_daily_energy_kcal'] = Variable<double>(
        declaredDailyEnergyKcal,
      );
    }
    map['is_default'] = Variable<bool>(isDefault);
    if (!nullToAbsent || sourceLabel != null) {
      map['source_label'] = Variable<String>(sourceLabel);
    }
    map['imported_at'] = Variable<DateTime>(importedAt);
    return map;
  }

  DietPlanRecordsCompanion toCompanion(bool nullToAbsent) {
    return DietPlanRecordsCompanion(
      id: Value(id),
      name: Value(name),
      document: Value(document),
      declaredDailyEnergyKcal: declaredDailyEnergyKcal == null && nullToAbsent
          ? const Value.absent()
          : Value(declaredDailyEnergyKcal),
      isDefault: Value(isDefault),
      sourceLabel: sourceLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceLabel),
      importedAt: Value(importedAt),
    );
  }

  factory DietPlanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DietPlanRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      document: serializer.fromJson<String>(json['document']),
      declaredDailyEnergyKcal: serializer.fromJson<double?>(
        json['declaredDailyEnergyKcal'],
      ),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      sourceLabel: serializer.fromJson<String?>(json['sourceLabel']),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'document': serializer.toJson<String>(document),
      'declaredDailyEnergyKcal': serializer.toJson<double?>(
        declaredDailyEnergyKcal,
      ),
      'isDefault': serializer.toJson<bool>(isDefault),
      'sourceLabel': serializer.toJson<String?>(sourceLabel),
      'importedAt': serializer.toJson<DateTime>(importedAt),
    };
  }

  DietPlanRow copyWith({
    String? id,
    String? name,
    String? document,
    Value<double?> declaredDailyEnergyKcal = const Value.absent(),
    bool? isDefault,
    Value<String?> sourceLabel = const Value.absent(),
    DateTime? importedAt,
  }) => DietPlanRow(
    id: id ?? this.id,
    name: name ?? this.name,
    document: document ?? this.document,
    declaredDailyEnergyKcal: declaredDailyEnergyKcal.present
        ? declaredDailyEnergyKcal.value
        : this.declaredDailyEnergyKcal,
    isDefault: isDefault ?? this.isDefault,
    sourceLabel: sourceLabel.present ? sourceLabel.value : this.sourceLabel,
    importedAt: importedAt ?? this.importedAt,
  );
  DietPlanRow copyWithCompanion(DietPlanRecordsCompanion data) {
    return DietPlanRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      document: data.document.present ? data.document.value : this.document,
      declaredDailyEnergyKcal: data.declaredDailyEnergyKcal.present
          ? data.declaredDailyEnergyKcal.value
          : this.declaredDailyEnergyKcal,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      sourceLabel: data.sourceLabel.present
          ? data.sourceLabel.value
          : this.sourceLabel,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DietPlanRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('document: $document, ')
          ..write('declaredDailyEnergyKcal: $declaredDailyEnergyKcal, ')
          ..write('isDefault: $isDefault, ')
          ..write('sourceLabel: $sourceLabel, ')
          ..write('importedAt: $importedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    document,
    declaredDailyEnergyKcal,
    isDefault,
    sourceLabel,
    importedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DietPlanRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.document == this.document &&
          other.declaredDailyEnergyKcal == this.declaredDailyEnergyKcal &&
          other.isDefault == this.isDefault &&
          other.sourceLabel == this.sourceLabel &&
          other.importedAt == this.importedAt);
}

class DietPlanRecordsCompanion extends UpdateCompanion<DietPlanRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> document;
  final Value<double?> declaredDailyEnergyKcal;
  final Value<bool> isDefault;
  final Value<String?> sourceLabel;
  final Value<DateTime> importedAt;
  final Value<int> rowid;
  const DietPlanRecordsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.document = const Value.absent(),
    this.declaredDailyEnergyKcal = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.sourceLabel = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DietPlanRecordsCompanion.insert({
    required String id,
    required String name,
    required String document,
    this.declaredDailyEnergyKcal = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.sourceLabel = const Value.absent(),
    required DateTime importedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       document = Value(document),
       importedAt = Value(importedAt);
  static Insertable<DietPlanRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? document,
    Expression<double>? declaredDailyEnergyKcal,
    Expression<bool>? isDefault,
    Expression<String>? sourceLabel,
    Expression<DateTime>? importedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (document != null) 'document': document,
      if (declaredDailyEnergyKcal != null)
        'declared_daily_energy_kcal': declaredDailyEnergyKcal,
      if (isDefault != null) 'is_default': isDefault,
      if (sourceLabel != null) 'source_label': sourceLabel,
      if (importedAt != null) 'imported_at': importedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DietPlanRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? document,
    Value<double?>? declaredDailyEnergyKcal,
    Value<bool>? isDefault,
    Value<String?>? sourceLabel,
    Value<DateTime>? importedAt,
    Value<int>? rowid,
  }) {
    return DietPlanRecordsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      document: document ?? this.document,
      declaredDailyEnergyKcal:
          declaredDailyEnergyKcal ?? this.declaredDailyEnergyKcal,
      isDefault: isDefault ?? this.isDefault,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      importedAt: importedAt ?? this.importedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (document.present) {
      map['document'] = Variable<String>(document.value);
    }
    if (declaredDailyEnergyKcal.present) {
      map['declared_daily_energy_kcal'] = Variable<double>(
        declaredDailyEnergyKcal.value,
      );
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (sourceLabel.present) {
      map['source_label'] = Variable<String>(sourceLabel.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DietPlanRecordsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('document: $document, ')
          ..write('declaredDailyEnergyKcal: $declaredDailyEnergyKcal, ')
          ..write('isDefault: $isDefault, ')
          ..write('sourceLabel: $sourceLabel, ')
          ..write('importedAt: $importedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ComponentSelectionsTable extends ComponentSelections
    with TableInfo<$ComponentSelectionsTable, ComponentSelectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ComponentSelectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayEpochMeta = const VerificationMeta(
    'dayEpoch',
  );
  @override
  late final GeneratedColumn<int> dayEpoch = GeneratedColumn<int>(
    'day_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _componentIdMeta = const VerificationMeta(
    'componentId',
  );
  @override
  late final GeneratedColumn<String> componentId = GeneratedColumn<String>(
    'component_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _optionIdMeta = const VerificationMeta(
    'optionId',
  );
  @override
  late final GeneratedColumn<String> optionId = GeneratedColumn<String>(
    'option_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [dayEpoch, componentId, optionId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'component_selections';
  @override
  VerificationContext validateIntegrity(
    Insertable<ComponentSelectionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day_epoch')) {
      context.handle(
        _dayEpochMeta,
        dayEpoch.isAcceptableOrUnknown(data['day_epoch']!, _dayEpochMeta),
      );
    } else if (isInserting) {
      context.missing(_dayEpochMeta);
    }
    if (data.containsKey('component_id')) {
      context.handle(
        _componentIdMeta,
        componentId.isAcceptableOrUnknown(
          data['component_id']!,
          _componentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_componentIdMeta);
    }
    if (data.containsKey('option_id')) {
      context.handle(
        _optionIdMeta,
        optionId.isAcceptableOrUnknown(data['option_id']!, _optionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_optionIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dayEpoch, componentId};
  @override
  ComponentSelectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ComponentSelectionRow(
      dayEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_epoch'],
      )!,
      componentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}component_id'],
      )!,
      optionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}option_id'],
      )!,
    );
  }

  @override
  $ComponentSelectionsTable createAlias(String alias) {
    return $ComponentSelectionsTable(attachedDatabase, alias);
  }
}

class ComponentSelectionRow extends DataClass
    implements Insertable<ComponentSelectionRow> {
  /// Day the choice applies to, as a `NutritionDay` epoch day.
  final int dayEpoch;

  /// The `MealComponent.id` being decided.
  final String componentId;

  /// The chosen `ComponentOption.id`.
  final String optionId;
  const ComponentSelectionRow({
    required this.dayEpoch,
    required this.componentId,
    required this.optionId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day_epoch'] = Variable<int>(dayEpoch);
    map['component_id'] = Variable<String>(componentId);
    map['option_id'] = Variable<String>(optionId);
    return map;
  }

  ComponentSelectionsCompanion toCompanion(bool nullToAbsent) {
    return ComponentSelectionsCompanion(
      dayEpoch: Value(dayEpoch),
      componentId: Value(componentId),
      optionId: Value(optionId),
    );
  }

  factory ComponentSelectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ComponentSelectionRow(
      dayEpoch: serializer.fromJson<int>(json['dayEpoch']),
      componentId: serializer.fromJson<String>(json['componentId']),
      optionId: serializer.fromJson<String>(json['optionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dayEpoch': serializer.toJson<int>(dayEpoch),
      'componentId': serializer.toJson<String>(componentId),
      'optionId': serializer.toJson<String>(optionId),
    };
  }

  ComponentSelectionRow copyWith({
    int? dayEpoch,
    String? componentId,
    String? optionId,
  }) => ComponentSelectionRow(
    dayEpoch: dayEpoch ?? this.dayEpoch,
    componentId: componentId ?? this.componentId,
    optionId: optionId ?? this.optionId,
  );
  ComponentSelectionRow copyWithCompanion(ComponentSelectionsCompanion data) {
    return ComponentSelectionRow(
      dayEpoch: data.dayEpoch.present ? data.dayEpoch.value : this.dayEpoch,
      componentId: data.componentId.present
          ? data.componentId.value
          : this.componentId,
      optionId: data.optionId.present ? data.optionId.value : this.optionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ComponentSelectionRow(')
          ..write('dayEpoch: $dayEpoch, ')
          ..write('componentId: $componentId, ')
          ..write('optionId: $optionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(dayEpoch, componentId, optionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ComponentSelectionRow &&
          other.dayEpoch == this.dayEpoch &&
          other.componentId == this.componentId &&
          other.optionId == this.optionId);
}

class ComponentSelectionsCompanion
    extends UpdateCompanion<ComponentSelectionRow> {
  final Value<int> dayEpoch;
  final Value<String> componentId;
  final Value<String> optionId;
  final Value<int> rowid;
  const ComponentSelectionsCompanion({
    this.dayEpoch = const Value.absent(),
    this.componentId = const Value.absent(),
    this.optionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ComponentSelectionsCompanion.insert({
    required int dayEpoch,
    required String componentId,
    required String optionId,
    this.rowid = const Value.absent(),
  }) : dayEpoch = Value(dayEpoch),
       componentId = Value(componentId),
       optionId = Value(optionId);
  static Insertable<ComponentSelectionRow> custom({
    Expression<int>? dayEpoch,
    Expression<String>? componentId,
    Expression<String>? optionId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dayEpoch != null) 'day_epoch': dayEpoch,
      if (componentId != null) 'component_id': componentId,
      if (optionId != null) 'option_id': optionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ComponentSelectionsCompanion copyWith({
    Value<int>? dayEpoch,
    Value<String>? componentId,
    Value<String>? optionId,
    Value<int>? rowid,
  }) {
    return ComponentSelectionsCompanion(
      dayEpoch: dayEpoch ?? this.dayEpoch,
      componentId: componentId ?? this.componentId,
      optionId: optionId ?? this.optionId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dayEpoch.present) {
      map['day_epoch'] = Variable<int>(dayEpoch.value);
    }
    if (componentId.present) {
      map['component_id'] = Variable<String>(componentId.value);
    }
    if (optionId.present) {
      map['option_id'] = Variable<String>(optionId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ComponentSelectionsCompanion(')
          ..write('dayEpoch: $dayEpoch, ')
          ..write('componentId: $componentId, ')
          ..write('optionId: $optionId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedMealsTable extends SavedMeals
    with TableInfo<$SavedMealsTable, SavedMealRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedMealsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _portionNoteMeta = const VerificationMeta(
    'portionNote',
  );
  @override
  late final GeneratedColumn<String> portionNote = GeneratedColumn<String>(
    'portion_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _energyKcalMeta = const VerificationMeta(
    'energyKcal',
  );
  @override
  late final GeneratedColumn<double> energyKcal = GeneratedColumn<double>(
    'energy_kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
    'carbs_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
    'fat_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    portionNote,
    energyKcal,
    proteinG,
    carbsG,
    fatG,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_meals';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedMealRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('portion_note')) {
      context.handle(
        _portionNoteMeta,
        portionNote.isAcceptableOrUnknown(
          data['portion_note']!,
          _portionNoteMeta,
        ),
      );
    }
    if (data.containsKey('energy_kcal')) {
      context.handle(
        _energyKcalMeta,
        energyKcal.isAcceptableOrUnknown(data['energy_kcal']!, _energyKcalMeta),
      );
    } else if (isInserting) {
      context.missing(_energyKcalMeta);
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinGMeta);
    }
    if (data.containsKey('carbs_g')) {
      context.handle(
        _carbsGMeta,
        carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta),
      );
    } else if (isInserting) {
      context.missing(_carbsGMeta);
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    } else if (isInserting) {
      context.missing(_fatGMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedMealRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedMealRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      portionNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}portion_note'],
      ),
      energyKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}energy_kcal'],
      )!,
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      )!,
      carbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_g'],
      )!,
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SavedMealsTable createAlias(String alias) {
    return $SavedMealsTable(attachedDatabase, alias);
  }
}

class SavedMealRow extends DataClass implements Insertable<SavedMealRow> {
  final String id;
  final String name;
  final String? portionNote;
  final double energyKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final DateTime createdAt;
  const SavedMealRow({
    required this.id,
    required this.name,
    this.portionNote,
    required this.energyKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || portionNote != null) {
      map['portion_note'] = Variable<String>(portionNote);
    }
    map['energy_kcal'] = Variable<double>(energyKcal);
    map['protein_g'] = Variable<double>(proteinG);
    map['carbs_g'] = Variable<double>(carbsG);
    map['fat_g'] = Variable<double>(fatG);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SavedMealsCompanion toCompanion(bool nullToAbsent) {
    return SavedMealsCompanion(
      id: Value(id),
      name: Value(name),
      portionNote: portionNote == null && nullToAbsent
          ? const Value.absent()
          : Value(portionNote),
      energyKcal: Value(energyKcal),
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      fatG: Value(fatG),
      createdAt: Value(createdAt),
    );
  }

  factory SavedMealRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedMealRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      portionNote: serializer.fromJson<String?>(json['portionNote']),
      energyKcal: serializer.fromJson<double>(json['energyKcal']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      carbsG: serializer.fromJson<double>(json['carbsG']),
      fatG: serializer.fromJson<double>(json['fatG']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'portionNote': serializer.toJson<String?>(portionNote),
      'energyKcal': serializer.toJson<double>(energyKcal),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbsG': serializer.toJson<double>(carbsG),
      'fatG': serializer.toJson<double>(fatG),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SavedMealRow copyWith({
    String? id,
    String? name,
    Value<String?> portionNote = const Value.absent(),
    double? energyKcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
    DateTime? createdAt,
  }) => SavedMealRow(
    id: id ?? this.id,
    name: name ?? this.name,
    portionNote: portionNote.present ? portionNote.value : this.portionNote,
    energyKcal: energyKcal ?? this.energyKcal,
    proteinG: proteinG ?? this.proteinG,
    carbsG: carbsG ?? this.carbsG,
    fatG: fatG ?? this.fatG,
    createdAt: createdAt ?? this.createdAt,
  );
  SavedMealRow copyWithCompanion(SavedMealsCompanion data) {
    return SavedMealRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      portionNote: data.portionNote.present
          ? data.portionNote.value
          : this.portionNote,
      energyKcal: data.energyKcal.present
          ? data.energyKcal.value
          : this.energyKcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedMealRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('portionNote: $portionNote, ')
          ..write('energyKcal: $energyKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    portionNote,
    energyKcal,
    proteinG,
    carbsG,
    fatG,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedMealRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.portionNote == this.portionNote &&
          other.energyKcal == this.energyKcal &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.fatG == this.fatG &&
          other.createdAt == this.createdAt);
}

class SavedMealsCompanion extends UpdateCompanion<SavedMealRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> portionNote;
  final Value<double> energyKcal;
  final Value<double> proteinG;
  final Value<double> carbsG;
  final Value<double> fatG;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SavedMealsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.portionNote = const Value.absent(),
    this.energyKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedMealsCompanion.insert({
    required String id,
    required String name,
    this.portionNote = const Value.absent(),
    required double energyKcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       energyKcal = Value(energyKcal),
       proteinG = Value(proteinG),
       carbsG = Value(carbsG),
       fatG = Value(fatG),
       createdAt = Value(createdAt);
  static Insertable<SavedMealRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? portionNote,
    Expression<double>? energyKcal,
    Expression<double>? proteinG,
    Expression<double>? carbsG,
    Expression<double>? fatG,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (portionNote != null) 'portion_note': portionNote,
      if (energyKcal != null) 'energy_kcal': energyKcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedMealsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? portionNote,
    Value<double>? energyKcal,
    Value<double>? proteinG,
    Value<double>? carbsG,
    Value<double>? fatG,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SavedMealsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      portionNote: portionNote ?? this.portionNote,
      energyKcal: energyKcal ?? this.energyKcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (portionNote.present) {
      map['portion_note'] = Variable<String>(portionNote.value);
    }
    if (energyKcal.present) {
      map['energy_kcal'] = Variable<double>(energyKcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedMealsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('portionNote: $portionNote, ')
          ..write('energyKcal: $energyKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ComponentDefaultsTable extends ComponentDefaults
    with TableInfo<$ComponentDefaultsTable, ComponentDefaultRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ComponentDefaultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _componentIdMeta = const VerificationMeta(
    'componentId',
  );
  @override
  late final GeneratedColumn<String> componentId = GeneratedColumn<String>(
    'component_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _optionIdMeta = const VerificationMeta(
    'optionId',
  );
  @override
  late final GeneratedColumn<String> optionId = GeneratedColumn<String>(
    'option_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [componentId, optionId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'component_defaults';
  @override
  VerificationContext validateIntegrity(
    Insertable<ComponentDefaultRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('component_id')) {
      context.handle(
        _componentIdMeta,
        componentId.isAcceptableOrUnknown(
          data['component_id']!,
          _componentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_componentIdMeta);
    }
    if (data.containsKey('option_id')) {
      context.handle(
        _optionIdMeta,
        optionId.isAcceptableOrUnknown(data['option_id']!, _optionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_optionIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {componentId};
  @override
  ComponentDefaultRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ComponentDefaultRow(
      componentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}component_id'],
      )!,
      optionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}option_id'],
      )!,
    );
  }

  @override
  $ComponentDefaultsTable createAlias(String alias) {
    return $ComponentDefaultsTable(attachedDatabase, alias);
  }
}

class ComponentDefaultRow extends DataClass
    implements Insertable<ComponentDefaultRow> {
  /// The `MealComponent.id` this preference applies to.
  final String componentId;

  /// The preferred `ComponentOption.id`.
  final String optionId;
  const ComponentDefaultRow({
    required this.componentId,
    required this.optionId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['component_id'] = Variable<String>(componentId);
    map['option_id'] = Variable<String>(optionId);
    return map;
  }

  ComponentDefaultsCompanion toCompanion(bool nullToAbsent) {
    return ComponentDefaultsCompanion(
      componentId: Value(componentId),
      optionId: Value(optionId),
    );
  }

  factory ComponentDefaultRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ComponentDefaultRow(
      componentId: serializer.fromJson<String>(json['componentId']),
      optionId: serializer.fromJson<String>(json['optionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'componentId': serializer.toJson<String>(componentId),
      'optionId': serializer.toJson<String>(optionId),
    };
  }

  ComponentDefaultRow copyWith({String? componentId, String? optionId}) =>
      ComponentDefaultRow(
        componentId: componentId ?? this.componentId,
        optionId: optionId ?? this.optionId,
      );
  ComponentDefaultRow copyWithCompanion(ComponentDefaultsCompanion data) {
    return ComponentDefaultRow(
      componentId: data.componentId.present
          ? data.componentId.value
          : this.componentId,
      optionId: data.optionId.present ? data.optionId.value : this.optionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ComponentDefaultRow(')
          ..write('componentId: $componentId, ')
          ..write('optionId: $optionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(componentId, optionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ComponentDefaultRow &&
          other.componentId == this.componentId &&
          other.optionId == this.optionId);
}

class ComponentDefaultsCompanion extends UpdateCompanion<ComponentDefaultRow> {
  final Value<String> componentId;
  final Value<String> optionId;
  final Value<int> rowid;
  const ComponentDefaultsCompanion({
    this.componentId = const Value.absent(),
    this.optionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ComponentDefaultsCompanion.insert({
    required String componentId,
    required String optionId,
    this.rowid = const Value.absent(),
  }) : componentId = Value(componentId),
       optionId = Value(optionId);
  static Insertable<ComponentDefaultRow> custom({
    Expression<String>? componentId,
    Expression<String>? optionId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (componentId != null) 'component_id': componentId,
      if (optionId != null) 'option_id': optionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ComponentDefaultsCompanion copyWith({
    Value<String>? componentId,
    Value<String>? optionId,
    Value<int>? rowid,
  }) {
    return ComponentDefaultsCompanion(
      componentId: componentId ?? this.componentId,
      optionId: optionId ?? this.optionId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (componentId.present) {
      map['component_id'] = Variable<String>(componentId.value);
    }
    if (optionId.present) {
      map['option_id'] = Variable<String>(optionId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ComponentDefaultsCompanion(')
          ..write('componentId: $componentId, ')
          ..write('optionId: $optionId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IntakeIngredientsTable extends IntakeIngredients
    with TableInfo<$IntakeIngredientsTable, IntakeIngredientRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IntakeIngredientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES nutrition_entries (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<String> foodId = GeneratedColumn<String>(
    'food_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  @override
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
    'grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<double> count = GeneratedColumn<double>(
    'count',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    entryId,
    foodId,
    grams,
    count,
    unit,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'intake_ingredients';
  @override
  VerificationContext validateIntegrity(
    Insertable<IntakeIngredientRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    } else if (isInserting) {
      context.missing(_foodIdMeta);
    }
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    } else if (isInserting) {
      context.missing(_gramsMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entryId, position};
  @override
  IntakeIngredientRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IntakeIngredientRow(
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_id'],
      )!,
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}count'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $IntakeIngredientsTable createAlias(String alias) {
    return $IntakeIngredientsTable(attachedDatabase, alias);
  }
}

class IntakeIngredientRow extends DataClass
    implements Insertable<IntakeIngredientRow> {
  final String entryId;
  final String foodId;
  final double grams;
  final double? count;
  final String? unit;
  final int position;
  const IntakeIngredientRow({
    required this.entryId,
    required this.foodId,
    required this.grams,
    this.count,
    this.unit,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<String>(entryId);
    map['food_id'] = Variable<String>(foodId);
    map['grams'] = Variable<double>(grams);
    if (!nullToAbsent || count != null) {
      map['count'] = Variable<double>(count);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['position'] = Variable<int>(position);
    return map;
  }

  IntakeIngredientsCompanion toCompanion(bool nullToAbsent) {
    return IntakeIngredientsCompanion(
      entryId: Value(entryId),
      foodId: Value(foodId),
      grams: Value(grams),
      count: count == null && nullToAbsent
          ? const Value.absent()
          : Value(count),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      position: Value(position),
    );
  }

  factory IntakeIngredientRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IntakeIngredientRow(
      entryId: serializer.fromJson<String>(json['entryId']),
      foodId: serializer.fromJson<String>(json['foodId']),
      grams: serializer.fromJson<double>(json['grams']),
      count: serializer.fromJson<double?>(json['count']),
      unit: serializer.fromJson<String?>(json['unit']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entryId': serializer.toJson<String>(entryId),
      'foodId': serializer.toJson<String>(foodId),
      'grams': serializer.toJson<double>(grams),
      'count': serializer.toJson<double?>(count),
      'unit': serializer.toJson<String?>(unit),
      'position': serializer.toJson<int>(position),
    };
  }

  IntakeIngredientRow copyWith({
    String? entryId,
    String? foodId,
    double? grams,
    Value<double?> count = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    int? position,
  }) => IntakeIngredientRow(
    entryId: entryId ?? this.entryId,
    foodId: foodId ?? this.foodId,
    grams: grams ?? this.grams,
    count: count.present ? count.value : this.count,
    unit: unit.present ? unit.value : this.unit,
    position: position ?? this.position,
  );
  IntakeIngredientRow copyWithCompanion(IntakeIngredientsCompanion data) {
    return IntakeIngredientRow(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      grams: data.grams.present ? data.grams.value : this.grams,
      count: data.count.present ? data.count.value : this.count,
      unit: data.unit.present ? data.unit.value : this.unit,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IntakeIngredientRow(')
          ..write('entryId: $entryId, ')
          ..write('foodId: $foodId, ')
          ..write('grams: $grams, ')
          ..write('count: $count, ')
          ..write('unit: $unit, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(entryId, foodId, grams, count, unit, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IntakeIngredientRow &&
          other.entryId == this.entryId &&
          other.foodId == this.foodId &&
          other.grams == this.grams &&
          other.count == this.count &&
          other.unit == this.unit &&
          other.position == this.position);
}

class IntakeIngredientsCompanion extends UpdateCompanion<IntakeIngredientRow> {
  final Value<String> entryId;
  final Value<String> foodId;
  final Value<double> grams;
  final Value<double?> count;
  final Value<String?> unit;
  final Value<int> position;
  final Value<int> rowid;
  const IntakeIngredientsCompanion({
    this.entryId = const Value.absent(),
    this.foodId = const Value.absent(),
    this.grams = const Value.absent(),
    this.count = const Value.absent(),
    this.unit = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IntakeIngredientsCompanion.insert({
    required String entryId,
    required String foodId,
    required double grams,
    this.count = const Value.absent(),
    this.unit = const Value.absent(),
    required int position,
    this.rowid = const Value.absent(),
  }) : entryId = Value(entryId),
       foodId = Value(foodId),
       grams = Value(grams),
       position = Value(position);
  static Insertable<IntakeIngredientRow> custom({
    Expression<String>? entryId,
    Expression<String>? foodId,
    Expression<double>? grams,
    Expression<double>? count,
    Expression<String>? unit,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (foodId != null) 'food_id': foodId,
      if (grams != null) 'grams': grams,
      if (count != null) 'count': count,
      if (unit != null) 'unit': unit,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IntakeIngredientsCompanion copyWith({
    Value<String>? entryId,
    Value<String>? foodId,
    Value<double>? grams,
    Value<double?>? count,
    Value<String?>? unit,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return IntakeIngredientsCompanion(
      entryId: entryId ?? this.entryId,
      foodId: foodId ?? this.foodId,
      grams: grams ?? this.grams,
      count: count ?? this.count,
      unit: unit ?? this.unit,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (foodId.present) {
      map['food_id'] = Variable<String>(foodId.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    if (count.present) {
      map['count'] = Variable<double>(count.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IntakeIngredientsCompanion(')
          ..write('entryId: $entryId, ')
          ..write('foodId: $foodId, ')
          ..write('grams: $grams, ')
          ..write('count: $count, ')
          ..write('unit: $unit, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedMealIngredientsTable extends SavedMealIngredients
    with TableInfo<$SavedMealIngredientsTable, SavedMealIngredientRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedMealIngredientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _savedMealIdMeta = const VerificationMeta(
    'savedMealId',
  );
  @override
  late final GeneratedColumn<String> savedMealId = GeneratedColumn<String>(
    'saved_meal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES saved_meals (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<String> foodId = GeneratedColumn<String>(
    'food_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  @override
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
    'grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<double> count = GeneratedColumn<double>(
    'count',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    savedMealId,
    foodId,
    grams,
    count,
    unit,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_meal_ingredients';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedMealIngredientRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('saved_meal_id')) {
      context.handle(
        _savedMealIdMeta,
        savedMealId.isAcceptableOrUnknown(
          data['saved_meal_id']!,
          _savedMealIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_savedMealIdMeta);
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    } else if (isInserting) {
      context.missing(_foodIdMeta);
    }
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    } else if (isInserting) {
      context.missing(_gramsMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {savedMealId, position};
  @override
  SavedMealIngredientRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedMealIngredientRow(
      savedMealId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}saved_meal_id'],
      )!,
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_id'],
      )!,
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}count'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $SavedMealIngredientsTable createAlias(String alias) {
    return $SavedMealIngredientsTable(attachedDatabase, alias);
  }
}

class SavedMealIngredientRow extends DataClass
    implements Insertable<SavedMealIngredientRow> {
  final String savedMealId;
  final String foodId;
  final double grams;
  final double? count;
  final String? unit;
  final int position;
  const SavedMealIngredientRow({
    required this.savedMealId,
    required this.foodId,
    required this.grams,
    this.count,
    this.unit,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['saved_meal_id'] = Variable<String>(savedMealId);
    map['food_id'] = Variable<String>(foodId);
    map['grams'] = Variable<double>(grams);
    if (!nullToAbsent || count != null) {
      map['count'] = Variable<double>(count);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['position'] = Variable<int>(position);
    return map;
  }

  SavedMealIngredientsCompanion toCompanion(bool nullToAbsent) {
    return SavedMealIngredientsCompanion(
      savedMealId: Value(savedMealId),
      foodId: Value(foodId),
      grams: Value(grams),
      count: count == null && nullToAbsent
          ? const Value.absent()
          : Value(count),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      position: Value(position),
    );
  }

  factory SavedMealIngredientRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedMealIngredientRow(
      savedMealId: serializer.fromJson<String>(json['savedMealId']),
      foodId: serializer.fromJson<String>(json['foodId']),
      grams: serializer.fromJson<double>(json['grams']),
      count: serializer.fromJson<double?>(json['count']),
      unit: serializer.fromJson<String?>(json['unit']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'savedMealId': serializer.toJson<String>(savedMealId),
      'foodId': serializer.toJson<String>(foodId),
      'grams': serializer.toJson<double>(grams),
      'count': serializer.toJson<double?>(count),
      'unit': serializer.toJson<String?>(unit),
      'position': serializer.toJson<int>(position),
    };
  }

  SavedMealIngredientRow copyWith({
    String? savedMealId,
    String? foodId,
    double? grams,
    Value<double?> count = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    int? position,
  }) => SavedMealIngredientRow(
    savedMealId: savedMealId ?? this.savedMealId,
    foodId: foodId ?? this.foodId,
    grams: grams ?? this.grams,
    count: count.present ? count.value : this.count,
    unit: unit.present ? unit.value : this.unit,
    position: position ?? this.position,
  );
  SavedMealIngredientRow copyWithCompanion(SavedMealIngredientsCompanion data) {
    return SavedMealIngredientRow(
      savedMealId: data.savedMealId.present
          ? data.savedMealId.value
          : this.savedMealId,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      grams: data.grams.present ? data.grams.value : this.grams,
      count: data.count.present ? data.count.value : this.count,
      unit: data.unit.present ? data.unit.value : this.unit,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedMealIngredientRow(')
          ..write('savedMealId: $savedMealId, ')
          ..write('foodId: $foodId, ')
          ..write('grams: $grams, ')
          ..write('count: $count, ')
          ..write('unit: $unit, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(savedMealId, foodId, grams, count, unit, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedMealIngredientRow &&
          other.savedMealId == this.savedMealId &&
          other.foodId == this.foodId &&
          other.grams == this.grams &&
          other.count == this.count &&
          other.unit == this.unit &&
          other.position == this.position);
}

class SavedMealIngredientsCompanion
    extends UpdateCompanion<SavedMealIngredientRow> {
  final Value<String> savedMealId;
  final Value<String> foodId;
  final Value<double> grams;
  final Value<double?> count;
  final Value<String?> unit;
  final Value<int> position;
  final Value<int> rowid;
  const SavedMealIngredientsCompanion({
    this.savedMealId = const Value.absent(),
    this.foodId = const Value.absent(),
    this.grams = const Value.absent(),
    this.count = const Value.absent(),
    this.unit = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedMealIngredientsCompanion.insert({
    required String savedMealId,
    required String foodId,
    required double grams,
    this.count = const Value.absent(),
    this.unit = const Value.absent(),
    required int position,
    this.rowid = const Value.absent(),
  }) : savedMealId = Value(savedMealId),
       foodId = Value(foodId),
       grams = Value(grams),
       position = Value(position);
  static Insertable<SavedMealIngredientRow> custom({
    Expression<String>? savedMealId,
    Expression<String>? foodId,
    Expression<double>? grams,
    Expression<double>? count,
    Expression<String>? unit,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (savedMealId != null) 'saved_meal_id': savedMealId,
      if (foodId != null) 'food_id': foodId,
      if (grams != null) 'grams': grams,
      if (count != null) 'count': count,
      if (unit != null) 'unit': unit,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedMealIngredientsCompanion copyWith({
    Value<String>? savedMealId,
    Value<String>? foodId,
    Value<double>? grams,
    Value<double?>? count,
    Value<String?>? unit,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return SavedMealIngredientsCompanion(
      savedMealId: savedMealId ?? this.savedMealId,
      foodId: foodId ?? this.foodId,
      grams: grams ?? this.grams,
      count: count ?? this.count,
      unit: unit ?? this.unit,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (savedMealId.present) {
      map['saved_meal_id'] = Variable<String>(savedMealId.value);
    }
    if (foodId.present) {
      map['food_id'] = Variable<String>(foodId.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    if (count.present) {
      map['count'] = Variable<double>(count.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedMealIngredientsCompanion(')
          ..write('savedMealId: $savedMealId, ')
          ..write('foodId: $foodId, ')
          ..write('grams: $grams, ')
          ..write('count: $count, ')
          ..write('unit: $unit, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealSubstituteIngredientsTable extends MealSubstituteIngredients
    with
        TableInfo<
          $MealSubstituteIngredientsTable,
          MealSubstituteIngredientRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealSubstituteIngredientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _substituteIdMeta = const VerificationMeta(
    'substituteId',
  );
  @override
  late final GeneratedColumn<String> substituteId = GeneratedColumn<String>(
    'substitute_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES meal_substitutes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<String> foodId = GeneratedColumn<String>(
    'food_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  @override
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
    'grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<double> count = GeneratedColumn<double>(
    'count',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    substituteId,
    foodId,
    grams,
    count,
    unit,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_substitute_ingredients';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealSubstituteIngredientRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('substitute_id')) {
      context.handle(
        _substituteIdMeta,
        substituteId.isAcceptableOrUnknown(
          data['substitute_id']!,
          _substituteIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_substituteIdMeta);
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    } else if (isInserting) {
      context.missing(_foodIdMeta);
    }
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    } else if (isInserting) {
      context.missing(_gramsMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {substituteId, position};
  @override
  MealSubstituteIngredientRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealSubstituteIngredientRow(
      substituteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}substitute_id'],
      )!,
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_id'],
      )!,
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}count'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $MealSubstituteIngredientsTable createAlias(String alias) {
    return $MealSubstituteIngredientsTable(attachedDatabase, alias);
  }
}

class MealSubstituteIngredientRow extends DataClass
    implements Insertable<MealSubstituteIngredientRow> {
  final String substituteId;
  final String foodId;
  final double grams;
  final double? count;
  final String? unit;
  final int position;
  const MealSubstituteIngredientRow({
    required this.substituteId,
    required this.foodId,
    required this.grams,
    this.count,
    this.unit,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['substitute_id'] = Variable<String>(substituteId);
    map['food_id'] = Variable<String>(foodId);
    map['grams'] = Variable<double>(grams);
    if (!nullToAbsent || count != null) {
      map['count'] = Variable<double>(count);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['position'] = Variable<int>(position);
    return map;
  }

  MealSubstituteIngredientsCompanion toCompanion(bool nullToAbsent) {
    return MealSubstituteIngredientsCompanion(
      substituteId: Value(substituteId),
      foodId: Value(foodId),
      grams: Value(grams),
      count: count == null && nullToAbsent
          ? const Value.absent()
          : Value(count),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      position: Value(position),
    );
  }

  factory MealSubstituteIngredientRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealSubstituteIngredientRow(
      substituteId: serializer.fromJson<String>(json['substituteId']),
      foodId: serializer.fromJson<String>(json['foodId']),
      grams: serializer.fromJson<double>(json['grams']),
      count: serializer.fromJson<double?>(json['count']),
      unit: serializer.fromJson<String?>(json['unit']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'substituteId': serializer.toJson<String>(substituteId),
      'foodId': serializer.toJson<String>(foodId),
      'grams': serializer.toJson<double>(grams),
      'count': serializer.toJson<double?>(count),
      'unit': serializer.toJson<String?>(unit),
      'position': serializer.toJson<int>(position),
    };
  }

  MealSubstituteIngredientRow copyWith({
    String? substituteId,
    String? foodId,
    double? grams,
    Value<double?> count = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    int? position,
  }) => MealSubstituteIngredientRow(
    substituteId: substituteId ?? this.substituteId,
    foodId: foodId ?? this.foodId,
    grams: grams ?? this.grams,
    count: count.present ? count.value : this.count,
    unit: unit.present ? unit.value : this.unit,
    position: position ?? this.position,
  );
  MealSubstituteIngredientRow copyWithCompanion(
    MealSubstituteIngredientsCompanion data,
  ) {
    return MealSubstituteIngredientRow(
      substituteId: data.substituteId.present
          ? data.substituteId.value
          : this.substituteId,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      grams: data.grams.present ? data.grams.value : this.grams,
      count: data.count.present ? data.count.value : this.count,
      unit: data.unit.present ? data.unit.value : this.unit,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealSubstituteIngredientRow(')
          ..write('substituteId: $substituteId, ')
          ..write('foodId: $foodId, ')
          ..write('grams: $grams, ')
          ..write('count: $count, ')
          ..write('unit: $unit, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(substituteId, foodId, grams, count, unit, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealSubstituteIngredientRow &&
          other.substituteId == this.substituteId &&
          other.foodId == this.foodId &&
          other.grams == this.grams &&
          other.count == this.count &&
          other.unit == this.unit &&
          other.position == this.position);
}

class MealSubstituteIngredientsCompanion
    extends UpdateCompanion<MealSubstituteIngredientRow> {
  final Value<String> substituteId;
  final Value<String> foodId;
  final Value<double> grams;
  final Value<double?> count;
  final Value<String?> unit;
  final Value<int> position;
  final Value<int> rowid;
  const MealSubstituteIngredientsCompanion({
    this.substituteId = const Value.absent(),
    this.foodId = const Value.absent(),
    this.grams = const Value.absent(),
    this.count = const Value.absent(),
    this.unit = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealSubstituteIngredientsCompanion.insert({
    required String substituteId,
    required String foodId,
    required double grams,
    this.count = const Value.absent(),
    this.unit = const Value.absent(),
    required int position,
    this.rowid = const Value.absent(),
  }) : substituteId = Value(substituteId),
       foodId = Value(foodId),
       grams = Value(grams),
       position = Value(position);
  static Insertable<MealSubstituteIngredientRow> custom({
    Expression<String>? substituteId,
    Expression<String>? foodId,
    Expression<double>? grams,
    Expression<double>? count,
    Expression<String>? unit,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (substituteId != null) 'substitute_id': substituteId,
      if (foodId != null) 'food_id': foodId,
      if (grams != null) 'grams': grams,
      if (count != null) 'count': count,
      if (unit != null) 'unit': unit,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealSubstituteIngredientsCompanion copyWith({
    Value<String>? substituteId,
    Value<String>? foodId,
    Value<double>? grams,
    Value<double?>? count,
    Value<String?>? unit,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return MealSubstituteIngredientsCompanion(
      substituteId: substituteId ?? this.substituteId,
      foodId: foodId ?? this.foodId,
      grams: grams ?? this.grams,
      count: count ?? this.count,
      unit: unit ?? this.unit,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (substituteId.present) {
      map['substitute_id'] = Variable<String>(substituteId.value);
    }
    if (foodId.present) {
      map['food_id'] = Variable<String>(foodId.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    if (count.present) {
      map['count'] = Variable<double>(count.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealSubstituteIngredientsCompanion(')
          ..write('substituteId: $substituteId, ')
          ..write('foodId: $foodId, ')
          ..write('grams: $grams, ')
          ..write('count: $count, ')
          ..write('unit: $unit, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$NutritionDatabase extends GeneratedDatabase {
  _$NutritionDatabase(QueryExecutor e) : super(e);
  $NutritionDatabaseManager get managers => $NutritionDatabaseManager(this);
  late final $PlannedMealsTable plannedMeals = $PlannedMealsTable(this);
  late final $NutritionEntriesTable nutritionEntries = $NutritionEntriesTable(
    this,
  );
  late final $HydrationEntriesTable hydrationEntries = $HydrationEntriesTable(
    this,
  );
  late final $MealSubstitutesTable mealSubstitutes = $MealSubstitutesTable(
    this,
  );
  late final $MenuPhotosTable menuPhotos = $MenuPhotosTable(this);
  late final $MenuItemsTable menuItems = $MenuItemsTable(this);
  late final $DietPlanRecordsTable dietPlanRecords = $DietPlanRecordsTable(
    this,
  );
  late final $ComponentSelectionsTable componentSelections =
      $ComponentSelectionsTable(this);
  late final $SavedMealsTable savedMeals = $SavedMealsTable(this);
  late final $ComponentDefaultsTable componentDefaults =
      $ComponentDefaultsTable(this);
  late final $IntakeIngredientsTable intakeIngredients =
      $IntakeIngredientsTable(this);
  late final $SavedMealIngredientsTable savedMealIngredients =
      $SavedMealIngredientsTable(this);
  late final $MealSubstituteIngredientsTable mealSubstituteIngredients =
      $MealSubstituteIngredientsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    plannedMeals,
    nutritionEntries,
    hydrationEntries,
    mealSubstitutes,
    menuPhotos,
    menuItems,
    dietPlanRecords,
    componentSelections,
    savedMeals,
    componentDefaults,
    intakeIngredients,
    savedMealIngredients,
    mealSubstituteIngredients,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'planned_meals',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('nutrition_entries', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'planned_meals',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('meal_substitutes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'menu_photos',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('menu_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'nutrition_entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('intake_ingredients', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'saved_meals',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('saved_meal_ingredients', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'meal_substitutes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('meal_substitute_ingredients', kind: UpdateKind.delete),
      ],
    ),
  ]);
}

typedef $$PlannedMealsTableCreateCompanionBuilder =
    PlannedMealsCompanion Function({
      required String id,
      required String slotId,
      Value<int?> dayEpoch,
      required double energyKcal,
      required double proteinG,
      required double carbsG,
      required double fatG,
      Value<int> rowid,
    });
typedef $$PlannedMealsTableUpdateCompanionBuilder =
    PlannedMealsCompanion Function({
      Value<String> id,
      Value<String> slotId,
      Value<int?> dayEpoch,
      Value<double> energyKcal,
      Value<double> proteinG,
      Value<double> carbsG,
      Value<double> fatG,
      Value<int> rowid,
    });

final class $$PlannedMealsTableReferences
    extends
        BaseReferences<
          _$NutritionDatabase,
          $PlannedMealsTable,
          PlannedMealRow
        > {
  $$PlannedMealsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$NutritionEntriesTable, List<NutritionEntryRow>>
  _nutritionEntriesRefsTable(_$NutritionDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.nutritionEntries,
        aliasName: 'planned_meals__id__nutrition_entries__planned_meal_id',
      );

  $$NutritionEntriesTableProcessedTableManager get nutritionEntriesRefs {
    final manager = $$NutritionEntriesTableTableManager(
      $_db,
      $_db.nutritionEntries,
    ).filter((f) => f.plannedMealId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _nutritionEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MealSubstitutesTable, List<MealSubstituteRow>>
  _mealSubstitutesRefsTable(_$NutritionDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.mealSubstitutes,
        aliasName: 'planned_meals__id__meal_substitutes__planned_meal_id',
      );

  $$MealSubstitutesTableProcessedTableManager get mealSubstitutesRefs {
    final manager = $$MealSubstitutesTableTableManager(
      $_db,
      $_db.mealSubstitutes,
    ).filter((f) => f.plannedMealId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _mealSubstitutesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlannedMealsTableFilterComposer
    extends Composer<_$NutritionDatabase, $PlannedMealsTable> {
  $$PlannedMealsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slotId => $composableBuilder(
    column: $table.slotId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayEpoch => $composableBuilder(
    column: $table.dayEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> nutritionEntriesRefs(
    Expression<bool> Function($$NutritionEntriesTableFilterComposer f) f,
  ) {
    final $$NutritionEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nutritionEntries,
      getReferencedColumn: (t) => t.plannedMealId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NutritionEntriesTableFilterComposer(
            $db: $db,
            $table: $db.nutritionEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> mealSubstitutesRefs(
    Expression<bool> Function($$MealSubstitutesTableFilterComposer f) f,
  ) {
    final $$MealSubstitutesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mealSubstitutes,
      getReferencedColumn: (t) => t.plannedMealId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealSubstitutesTableFilterComposer(
            $db: $db,
            $table: $db.mealSubstitutes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlannedMealsTableOrderingComposer
    extends Composer<_$NutritionDatabase, $PlannedMealsTable> {
  $$PlannedMealsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slotId => $composableBuilder(
    column: $table.slotId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayEpoch => $composableBuilder(
    column: $table.dayEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlannedMealsTableAnnotationComposer
    extends Composer<_$NutritionDatabase, $PlannedMealsTable> {
  $$PlannedMealsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get slotId =>
      $composableBuilder(column: $table.slotId, builder: (column) => column);

  GeneratedColumn<int> get dayEpoch =>
      $composableBuilder(column: $table.dayEpoch, builder: (column) => column);

  GeneratedColumn<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  Expression<T> nutritionEntriesRefs<T extends Object>(
    Expression<T> Function($$NutritionEntriesTableAnnotationComposer a) f,
  ) {
    final $$NutritionEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nutritionEntries,
      getReferencedColumn: (t) => t.plannedMealId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NutritionEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.nutritionEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> mealSubstitutesRefs<T extends Object>(
    Expression<T> Function($$MealSubstitutesTableAnnotationComposer a) f,
  ) {
    final $$MealSubstitutesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mealSubstitutes,
      getReferencedColumn: (t) => t.plannedMealId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealSubstitutesTableAnnotationComposer(
            $db: $db,
            $table: $db.mealSubstitutes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlannedMealsTableTableManager
    extends
        RootTableManager<
          _$NutritionDatabase,
          $PlannedMealsTable,
          PlannedMealRow,
          $$PlannedMealsTableFilterComposer,
          $$PlannedMealsTableOrderingComposer,
          $$PlannedMealsTableAnnotationComposer,
          $$PlannedMealsTableCreateCompanionBuilder,
          $$PlannedMealsTableUpdateCompanionBuilder,
          (PlannedMealRow, $$PlannedMealsTableReferences),
          PlannedMealRow,
          PrefetchHooks Function({
            bool nutritionEntriesRefs,
            bool mealSubstitutesRefs,
          })
        > {
  $$PlannedMealsTableTableManager(
    _$NutritionDatabase db,
    $PlannedMealsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlannedMealsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlannedMealsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlannedMealsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> slotId = const Value.absent(),
                Value<int?> dayEpoch = const Value.absent(),
                Value<double> energyKcal = const Value.absent(),
                Value<double> proteinG = const Value.absent(),
                Value<double> carbsG = const Value.absent(),
                Value<double> fatG = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlannedMealsCompanion(
                id: id,
                slotId: slotId,
                dayEpoch: dayEpoch,
                energyKcal: energyKcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String slotId,
                Value<int?> dayEpoch = const Value.absent(),
                required double energyKcal,
                required double proteinG,
                required double carbsG,
                required double fatG,
                Value<int> rowid = const Value.absent(),
              }) => PlannedMealsCompanion.insert(
                id: id,
                slotId: slotId,
                dayEpoch: dayEpoch,
                energyKcal: energyKcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlannedMealsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({nutritionEntriesRefs = false, mealSubstitutesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (nutritionEntriesRefs) db.nutritionEntries,
                    if (mealSubstitutesRefs) db.mealSubstitutes,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (nutritionEntriesRefs)
                        await $_getPrefetchedData<
                          PlannedMealRow,
                          $PlannedMealsTable,
                          NutritionEntryRow
                        >(
                          currentTable: table,
                          referencedTable: $$PlannedMealsTableReferences
                              ._nutritionEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlannedMealsTableReferences(
                                db,
                                table,
                                p0,
                              ).nutritionEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.plannedMealId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (mealSubstitutesRefs)
                        await $_getPrefetchedData<
                          PlannedMealRow,
                          $PlannedMealsTable,
                          MealSubstituteRow
                        >(
                          currentTable: table,
                          referencedTable: $$PlannedMealsTableReferences
                              ._mealSubstitutesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlannedMealsTableReferences(
                                db,
                                table,
                                p0,
                              ).mealSubstitutesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.plannedMealId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PlannedMealsTableProcessedTableManager =
    ProcessedTableManager<
      _$NutritionDatabase,
      $PlannedMealsTable,
      PlannedMealRow,
      $$PlannedMealsTableFilterComposer,
      $$PlannedMealsTableOrderingComposer,
      $$PlannedMealsTableAnnotationComposer,
      $$PlannedMealsTableCreateCompanionBuilder,
      $$PlannedMealsTableUpdateCompanionBuilder,
      (PlannedMealRow, $$PlannedMealsTableReferences),
      PlannedMealRow,
      PrefetchHooks Function({
        bool nutritionEntriesRefs,
        bool mealSubstitutesRefs,
      })
    >;
typedef $$NutritionEntriesTableCreateCompanionBuilder =
    NutritionEntriesCompanion Function({
      required String id,
      required DateTime recordedAt,
      required int dayEpoch,
      required double energyKcal,
      required double proteinG,
      required double carbsG,
      required double fatG,
      Value<String?> plannedMealId,
      Value<int> rowid,
    });
typedef $$NutritionEntriesTableUpdateCompanionBuilder =
    NutritionEntriesCompanion Function({
      Value<String> id,
      Value<DateTime> recordedAt,
      Value<int> dayEpoch,
      Value<double> energyKcal,
      Value<double> proteinG,
      Value<double> carbsG,
      Value<double> fatG,
      Value<String?> plannedMealId,
      Value<int> rowid,
    });

final class $$NutritionEntriesTableReferences
    extends
        BaseReferences<
          _$NutritionDatabase,
          $NutritionEntriesTable,
          NutritionEntryRow
        > {
  $$NutritionEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlannedMealsTable _plannedMealIdTable(_$NutritionDatabase db) => db
      .plannedMeals
      .createAlias('nutrition_entries__planned_meal_id__planned_meals__id');

  $$PlannedMealsTableProcessedTableManager? get plannedMealId {
    final $_column = $_itemColumn<String>('planned_meal_id');
    if ($_column == null) return null;
    final manager = $$PlannedMealsTableTableManager(
      $_db,
      $_db.plannedMeals,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_plannedMealIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$IntakeIngredientsTable, List<IntakeIngredientRow>>
  _intakeIngredientsRefsTable(_$NutritionDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.intakeIngredients,
        aliasName: 'nutrition_entries__id__intake_ingredients__entry_id',
      );

  $$IntakeIngredientsTableProcessedTableManager get intakeIngredientsRefs {
    final manager = $$IntakeIngredientsTableTableManager(
      $_db,
      $_db.intakeIngredients,
    ).filter((f) => f.entryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _intakeIngredientsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$NutritionEntriesTableFilterComposer
    extends Composer<_$NutritionDatabase, $NutritionEntriesTable> {
  $$NutritionEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayEpoch => $composableBuilder(
    column: $table.dayEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnFilters(column),
  );

  $$PlannedMealsTableFilterComposer get plannedMealId {
    final $$PlannedMealsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plannedMealId,
      referencedTable: $db.plannedMeals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedMealsTableFilterComposer(
            $db: $db,
            $table: $db.plannedMeals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> intakeIngredientsRefs(
    Expression<bool> Function($$IntakeIngredientsTableFilterComposer f) f,
  ) {
    final $$IntakeIngredientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.intakeIngredients,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IntakeIngredientsTableFilterComposer(
            $db: $db,
            $table: $db.intakeIngredients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NutritionEntriesTableOrderingComposer
    extends Composer<_$NutritionDatabase, $NutritionEntriesTable> {
  $$NutritionEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayEpoch => $composableBuilder(
    column: $table.dayEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlannedMealsTableOrderingComposer get plannedMealId {
    final $$PlannedMealsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plannedMealId,
      referencedTable: $db.plannedMeals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedMealsTableOrderingComposer(
            $db: $db,
            $table: $db.plannedMeals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NutritionEntriesTableAnnotationComposer
    extends Composer<_$NutritionDatabase, $NutritionEntriesTable> {
  $$NutritionEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dayEpoch =>
      $composableBuilder(column: $table.dayEpoch, builder: (column) => column);

  GeneratedColumn<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  $$PlannedMealsTableAnnotationComposer get plannedMealId {
    final $$PlannedMealsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plannedMealId,
      referencedTable: $db.plannedMeals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedMealsTableAnnotationComposer(
            $db: $db,
            $table: $db.plannedMeals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> intakeIngredientsRefs<T extends Object>(
    Expression<T> Function($$IntakeIngredientsTableAnnotationComposer a) f,
  ) {
    final $$IntakeIngredientsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.intakeIngredients,
          getReferencedColumn: (t) => t.entryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$IntakeIngredientsTableAnnotationComposer(
                $db: $db,
                $table: $db.intakeIngredients,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$NutritionEntriesTableTableManager
    extends
        RootTableManager<
          _$NutritionDatabase,
          $NutritionEntriesTable,
          NutritionEntryRow,
          $$NutritionEntriesTableFilterComposer,
          $$NutritionEntriesTableOrderingComposer,
          $$NutritionEntriesTableAnnotationComposer,
          $$NutritionEntriesTableCreateCompanionBuilder,
          $$NutritionEntriesTableUpdateCompanionBuilder,
          (NutritionEntryRow, $$NutritionEntriesTableReferences),
          NutritionEntryRow,
          PrefetchHooks Function({
            bool plannedMealId,
            bool intakeIngredientsRefs,
          })
        > {
  $$NutritionEntriesTableTableManager(
    _$NutritionDatabase db,
    $NutritionEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NutritionEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NutritionEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NutritionEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<int> dayEpoch = const Value.absent(),
                Value<double> energyKcal = const Value.absent(),
                Value<double> proteinG = const Value.absent(),
                Value<double> carbsG = const Value.absent(),
                Value<double> fatG = const Value.absent(),
                Value<String?> plannedMealId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NutritionEntriesCompanion(
                id: id,
                recordedAt: recordedAt,
                dayEpoch: dayEpoch,
                energyKcal: energyKcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                plannedMealId: plannedMealId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime recordedAt,
                required int dayEpoch,
                required double energyKcal,
                required double proteinG,
                required double carbsG,
                required double fatG,
                Value<String?> plannedMealId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NutritionEntriesCompanion.insert(
                id: id,
                recordedAt: recordedAt,
                dayEpoch: dayEpoch,
                energyKcal: energyKcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                plannedMealId: plannedMealId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$NutritionEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({plannedMealId = false, intakeIngredientsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (intakeIngredientsRefs) db.intakeIngredients,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (plannedMealId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.plannedMealId,
                                    referencedTable:
                                        $$NutritionEntriesTableReferences
                                            ._plannedMealIdTable(db),
                                    referencedColumn:
                                        $$NutritionEntriesTableReferences
                                            ._plannedMealIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (intakeIngredientsRefs)
                        await $_getPrefetchedData<
                          NutritionEntryRow,
                          $NutritionEntriesTable,
                          IntakeIngredientRow
                        >(
                          currentTable: table,
                          referencedTable: $$NutritionEntriesTableReferences
                              ._intakeIngredientsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NutritionEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).intakeIngredientsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.entryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$NutritionEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$NutritionDatabase,
      $NutritionEntriesTable,
      NutritionEntryRow,
      $$NutritionEntriesTableFilterComposer,
      $$NutritionEntriesTableOrderingComposer,
      $$NutritionEntriesTableAnnotationComposer,
      $$NutritionEntriesTableCreateCompanionBuilder,
      $$NutritionEntriesTableUpdateCompanionBuilder,
      (NutritionEntryRow, $$NutritionEntriesTableReferences),
      NutritionEntryRow,
      PrefetchHooks Function({bool plannedMealId, bool intakeIngredientsRefs})
    >;
typedef $$HydrationEntriesTableCreateCompanionBuilder =
    HydrationEntriesCompanion Function({
      required String id,
      required DateTime recordedAt,
      required int dayEpoch,
      required double waterMl,
      Value<int> rowid,
    });
typedef $$HydrationEntriesTableUpdateCompanionBuilder =
    HydrationEntriesCompanion Function({
      Value<String> id,
      Value<DateTime> recordedAt,
      Value<int> dayEpoch,
      Value<double> waterMl,
      Value<int> rowid,
    });

class $$HydrationEntriesTableFilterComposer
    extends Composer<_$NutritionDatabase, $HydrationEntriesTable> {
  $$HydrationEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayEpoch => $composableBuilder(
    column: $table.dayEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get waterMl => $composableBuilder(
    column: $table.waterMl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HydrationEntriesTableOrderingComposer
    extends Composer<_$NutritionDatabase, $HydrationEntriesTable> {
  $$HydrationEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayEpoch => $composableBuilder(
    column: $table.dayEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get waterMl => $composableBuilder(
    column: $table.waterMl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HydrationEntriesTableAnnotationComposer
    extends Composer<_$NutritionDatabase, $HydrationEntriesTable> {
  $$HydrationEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dayEpoch =>
      $composableBuilder(column: $table.dayEpoch, builder: (column) => column);

  GeneratedColumn<double> get waterMl =>
      $composableBuilder(column: $table.waterMl, builder: (column) => column);
}

class $$HydrationEntriesTableTableManager
    extends
        RootTableManager<
          _$NutritionDatabase,
          $HydrationEntriesTable,
          HydrationEntryRow,
          $$HydrationEntriesTableFilterComposer,
          $$HydrationEntriesTableOrderingComposer,
          $$HydrationEntriesTableAnnotationComposer,
          $$HydrationEntriesTableCreateCompanionBuilder,
          $$HydrationEntriesTableUpdateCompanionBuilder,
          (
            HydrationEntryRow,
            BaseReferences<
              _$NutritionDatabase,
              $HydrationEntriesTable,
              HydrationEntryRow
            >,
          ),
          HydrationEntryRow,
          PrefetchHooks Function()
        > {
  $$HydrationEntriesTableTableManager(
    _$NutritionDatabase db,
    $HydrationEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HydrationEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HydrationEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HydrationEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<int> dayEpoch = const Value.absent(),
                Value<double> waterMl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HydrationEntriesCompanion(
                id: id,
                recordedAt: recordedAt,
                dayEpoch: dayEpoch,
                waterMl: waterMl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime recordedAt,
                required int dayEpoch,
                required double waterMl,
                Value<int> rowid = const Value.absent(),
              }) => HydrationEntriesCompanion.insert(
                id: id,
                recordedAt: recordedAt,
                dayEpoch: dayEpoch,
                waterMl: waterMl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HydrationEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$NutritionDatabase,
      $HydrationEntriesTable,
      HydrationEntryRow,
      $$HydrationEntriesTableFilterComposer,
      $$HydrationEntriesTableOrderingComposer,
      $$HydrationEntriesTableAnnotationComposer,
      $$HydrationEntriesTableCreateCompanionBuilder,
      $$HydrationEntriesTableUpdateCompanionBuilder,
      (
        HydrationEntryRow,
        BaseReferences<
          _$NutritionDatabase,
          $HydrationEntriesTable,
          HydrationEntryRow
        >,
      ),
      HydrationEntryRow,
      PrefetchHooks Function()
    >;
typedef $$MealSubstitutesTableCreateCompanionBuilder =
    MealSubstitutesCompanion Function({
      required String id,
      required String plannedMealId,
      required String label,
      required double energyKcal,
      required double proteinG,
      required double carbsG,
      required double fatG,
      Value<int> rowid,
    });
typedef $$MealSubstitutesTableUpdateCompanionBuilder =
    MealSubstitutesCompanion Function({
      Value<String> id,
      Value<String> plannedMealId,
      Value<String> label,
      Value<double> energyKcal,
      Value<double> proteinG,
      Value<double> carbsG,
      Value<double> fatG,
      Value<int> rowid,
    });

final class $$MealSubstitutesTableReferences
    extends
        BaseReferences<
          _$NutritionDatabase,
          $MealSubstitutesTable,
          MealSubstituteRow
        > {
  $$MealSubstitutesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlannedMealsTable _plannedMealIdTable(_$NutritionDatabase db) => db
      .plannedMeals
      .createAlias('meal_substitutes__planned_meal_id__planned_meals__id');

  $$PlannedMealsTableProcessedTableManager get plannedMealId {
    final $_column = $_itemColumn<String>('planned_meal_id')!;

    final manager = $$PlannedMealsTableTableManager(
      $_db,
      $_db.plannedMeals,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_plannedMealIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $MealSubstituteIngredientsTable,
    List<MealSubstituteIngredientRow>
  >
  _mealSubstituteIngredientsRefsTable(_$NutritionDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.mealSubstituteIngredients,
        aliasName:
            'meal_substitutes__id__meal_substitute_ingredients__substitute_id',
      );

  $$MealSubstituteIngredientsTableProcessedTableManager
  get mealSubstituteIngredientsRefs {
    final manager = $$MealSubstituteIngredientsTableTableManager(
      $_db,
      $_db.mealSubstituteIngredients,
    ).filter((f) => f.substituteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _mealSubstituteIngredientsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MealSubstitutesTableFilterComposer
    extends Composer<_$NutritionDatabase, $MealSubstitutesTable> {
  $$MealSubstitutesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnFilters(column),
  );

  $$PlannedMealsTableFilterComposer get plannedMealId {
    final $$PlannedMealsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plannedMealId,
      referencedTable: $db.plannedMeals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedMealsTableFilterComposer(
            $db: $db,
            $table: $db.plannedMeals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> mealSubstituteIngredientsRefs(
    Expression<bool> Function($$MealSubstituteIngredientsTableFilterComposer f)
    f,
  ) {
    final $$MealSubstituteIngredientsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.mealSubstituteIngredients,
          getReferencedColumn: (t) => t.substituteId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MealSubstituteIngredientsTableFilterComposer(
                $db: $db,
                $table: $db.mealSubstituteIngredients,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$MealSubstitutesTableOrderingComposer
    extends Composer<_$NutritionDatabase, $MealSubstitutesTable> {
  $$MealSubstitutesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlannedMealsTableOrderingComposer get plannedMealId {
    final $$PlannedMealsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plannedMealId,
      referencedTable: $db.plannedMeals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedMealsTableOrderingComposer(
            $db: $db,
            $table: $db.plannedMeals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MealSubstitutesTableAnnotationComposer
    extends Composer<_$NutritionDatabase, $MealSubstitutesTable> {
  $$MealSubstitutesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  $$PlannedMealsTableAnnotationComposer get plannedMealId {
    final $$PlannedMealsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plannedMealId,
      referencedTable: $db.plannedMeals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedMealsTableAnnotationComposer(
            $db: $db,
            $table: $db.plannedMeals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> mealSubstituteIngredientsRefs<T extends Object>(
    Expression<T> Function($$MealSubstituteIngredientsTableAnnotationComposer a)
    f,
  ) {
    final $$MealSubstituteIngredientsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.mealSubstituteIngredients,
          getReferencedColumn: (t) => t.substituteId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MealSubstituteIngredientsTableAnnotationComposer(
                $db: $db,
                $table: $db.mealSubstituteIngredients,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$MealSubstitutesTableTableManager
    extends
        RootTableManager<
          _$NutritionDatabase,
          $MealSubstitutesTable,
          MealSubstituteRow,
          $$MealSubstitutesTableFilterComposer,
          $$MealSubstitutesTableOrderingComposer,
          $$MealSubstitutesTableAnnotationComposer,
          $$MealSubstitutesTableCreateCompanionBuilder,
          $$MealSubstitutesTableUpdateCompanionBuilder,
          (MealSubstituteRow, $$MealSubstitutesTableReferences),
          MealSubstituteRow,
          PrefetchHooks Function({
            bool plannedMealId,
            bool mealSubstituteIngredientsRefs,
          })
        > {
  $$MealSubstitutesTableTableManager(
    _$NutritionDatabase db,
    $MealSubstitutesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealSubstitutesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealSubstitutesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealSubstitutesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> plannedMealId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<double> energyKcal = const Value.absent(),
                Value<double> proteinG = const Value.absent(),
                Value<double> carbsG = const Value.absent(),
                Value<double> fatG = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealSubstitutesCompanion(
                id: id,
                plannedMealId: plannedMealId,
                label: label,
                energyKcal: energyKcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String plannedMealId,
                required String label,
                required double energyKcal,
                required double proteinG,
                required double carbsG,
                required double fatG,
                Value<int> rowid = const Value.absent(),
              }) => MealSubstitutesCompanion.insert(
                id: id,
                plannedMealId: plannedMealId,
                label: label,
                energyKcal: energyKcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MealSubstitutesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({plannedMealId = false, mealSubstituteIngredientsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (mealSubstituteIngredientsRefs)
                      db.mealSubstituteIngredients,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (plannedMealId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.plannedMealId,
                                    referencedTable:
                                        $$MealSubstitutesTableReferences
                                            ._plannedMealIdTable(db),
                                    referencedColumn:
                                        $$MealSubstitutesTableReferences
                                            ._plannedMealIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (mealSubstituteIngredientsRefs)
                        await $_getPrefetchedData<
                          MealSubstituteRow,
                          $MealSubstitutesTable,
                          MealSubstituteIngredientRow
                        >(
                          currentTable: table,
                          referencedTable: $$MealSubstitutesTableReferences
                              ._mealSubstituteIngredientsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MealSubstitutesTableReferences(
                                db,
                                table,
                                p0,
                              ).mealSubstituteIngredientsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.substituteId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MealSubstitutesTableProcessedTableManager =
    ProcessedTableManager<
      _$NutritionDatabase,
      $MealSubstitutesTable,
      MealSubstituteRow,
      $$MealSubstitutesTableFilterComposer,
      $$MealSubstitutesTableOrderingComposer,
      $$MealSubstitutesTableAnnotationComposer,
      $$MealSubstitutesTableCreateCompanionBuilder,
      $$MealSubstitutesTableUpdateCompanionBuilder,
      (MealSubstituteRow, $$MealSubstitutesTableReferences),
      MealSubstituteRow,
      PrefetchHooks Function({
        bool plannedMealId,
        bool mealSubstituteIngredientsRefs,
      })
    >;
typedef $$MenuPhotosTableCreateCompanionBuilder =
    MenuPhotosCompanion Function({
      required String id,
      required String localUri,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$MenuPhotosTableUpdateCompanionBuilder =
    MenuPhotosCompanion Function({
      Value<String> id,
      Value<String> localUri,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$MenuPhotosTableReferences
    extends
        BaseReferences<_$NutritionDatabase, $MenuPhotosTable, MenuPhotoRow> {
  $$MenuPhotosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MenuItemsTable, List<MenuItemRow>>
  _menuItemsRefsTable(_$NutritionDatabase db) => MultiTypedResultKey.fromTable(
    db.menuItems,
    aliasName: 'menu_photos__id__menu_items__photo_id',
  );

  $$MenuItemsTableProcessedTableManager get menuItemsRefs {
    final manager = $$MenuItemsTableTableManager(
      $_db,
      $_db.menuItems,
    ).filter((f) => f.photoId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_menuItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MenuPhotosTableFilterComposer
    extends Composer<_$NutritionDatabase, $MenuPhotosTable> {
  $$MenuPhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localUri => $composableBuilder(
    column: $table.localUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> menuItemsRefs(
    Expression<bool> Function($$MenuItemsTableFilterComposer f) f,
  ) {
    final $$MenuItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.menuItems,
      getReferencedColumn: (t) => t.photoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuItemsTableFilterComposer(
            $db: $db,
            $table: $db.menuItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MenuPhotosTableOrderingComposer
    extends Composer<_$NutritionDatabase, $MenuPhotosTable> {
  $$MenuPhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localUri => $composableBuilder(
    column: $table.localUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MenuPhotosTableAnnotationComposer
    extends Composer<_$NutritionDatabase, $MenuPhotosTable> {
  $$MenuPhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localUri =>
      $composableBuilder(column: $table.localUri, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> menuItemsRefs<T extends Object>(
    Expression<T> Function($$MenuItemsTableAnnotationComposer a) f,
  ) {
    final $$MenuItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.menuItems,
      getReferencedColumn: (t) => t.photoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.menuItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MenuPhotosTableTableManager
    extends
        RootTableManager<
          _$NutritionDatabase,
          $MenuPhotosTable,
          MenuPhotoRow,
          $$MenuPhotosTableFilterComposer,
          $$MenuPhotosTableOrderingComposer,
          $$MenuPhotosTableAnnotationComposer,
          $$MenuPhotosTableCreateCompanionBuilder,
          $$MenuPhotosTableUpdateCompanionBuilder,
          (MenuPhotoRow, $$MenuPhotosTableReferences),
          MenuPhotoRow,
          PrefetchHooks Function({bool menuItemsRefs})
        > {
  $$MenuPhotosTableTableManager(_$NutritionDatabase db, $MenuPhotosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MenuPhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MenuPhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MenuPhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> localUri = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MenuPhotosCompanion(
                id: id,
                localUri: localUri,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String localUri,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => MenuPhotosCompanion.insert(
                id: id,
                localUri: localUri,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MenuPhotosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({menuItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (menuItemsRefs) db.menuItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (menuItemsRefs)
                    await $_getPrefetchedData<
                      MenuPhotoRow,
                      $MenuPhotosTable,
                      MenuItemRow
                    >(
                      currentTable: table,
                      referencedTable: $$MenuPhotosTableReferences
                          ._menuItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$MenuPhotosTableReferences(
                            db,
                            table,
                            p0,
                          ).menuItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.photoId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$MenuPhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$NutritionDatabase,
      $MenuPhotosTable,
      MenuPhotoRow,
      $$MenuPhotosTableFilterComposer,
      $$MenuPhotosTableOrderingComposer,
      $$MenuPhotosTableAnnotationComposer,
      $$MenuPhotosTableCreateCompanionBuilder,
      $$MenuPhotosTableUpdateCompanionBuilder,
      (MenuPhotoRow, $$MenuPhotosTableReferences),
      MenuPhotoRow,
      PrefetchHooks Function({bool menuItemsRefs})
    >;
typedef $$MenuItemsTableCreateCompanionBuilder =
    MenuItemsCompanion Function({
      required String id,
      required String photoId,
      required String label,
      required double energyKcal,
      required double proteinG,
      required double carbsG,
      required double fatG,
      Value<int> rowid,
    });
typedef $$MenuItemsTableUpdateCompanionBuilder =
    MenuItemsCompanion Function({
      Value<String> id,
      Value<String> photoId,
      Value<String> label,
      Value<double> energyKcal,
      Value<double> proteinG,
      Value<double> carbsG,
      Value<double> fatG,
      Value<int> rowid,
    });

final class $$MenuItemsTableReferences
    extends BaseReferences<_$NutritionDatabase, $MenuItemsTable, MenuItemRow> {
  $$MenuItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MenuPhotosTable _photoIdTable(_$NutritionDatabase db) =>
      db.menuPhotos.createAlias('menu_items__photo_id__menu_photos__id');

  $$MenuPhotosTableProcessedTableManager get photoId {
    final $_column = $_itemColumn<String>('photo_id')!;

    final manager = $$MenuPhotosTableTableManager(
      $_db,
      $_db.menuPhotos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_photoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MenuItemsTableFilterComposer
    extends Composer<_$NutritionDatabase, $MenuItemsTable> {
  $$MenuItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnFilters(column),
  );

  $$MenuPhotosTableFilterComposer get photoId {
    final $$MenuPhotosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.photoId,
      referencedTable: $db.menuPhotos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuPhotosTableFilterComposer(
            $db: $db,
            $table: $db.menuPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MenuItemsTableOrderingComposer
    extends Composer<_$NutritionDatabase, $MenuItemsTable> {
  $$MenuItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnOrderings(column),
  );

  $$MenuPhotosTableOrderingComposer get photoId {
    final $$MenuPhotosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.photoId,
      referencedTable: $db.menuPhotos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuPhotosTableOrderingComposer(
            $db: $db,
            $table: $db.menuPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MenuItemsTableAnnotationComposer
    extends Composer<_$NutritionDatabase, $MenuItemsTable> {
  $$MenuItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  $$MenuPhotosTableAnnotationComposer get photoId {
    final $$MenuPhotosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.photoId,
      referencedTable: $db.menuPhotos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuPhotosTableAnnotationComposer(
            $db: $db,
            $table: $db.menuPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MenuItemsTableTableManager
    extends
        RootTableManager<
          _$NutritionDatabase,
          $MenuItemsTable,
          MenuItemRow,
          $$MenuItemsTableFilterComposer,
          $$MenuItemsTableOrderingComposer,
          $$MenuItemsTableAnnotationComposer,
          $$MenuItemsTableCreateCompanionBuilder,
          $$MenuItemsTableUpdateCompanionBuilder,
          (MenuItemRow, $$MenuItemsTableReferences),
          MenuItemRow,
          PrefetchHooks Function({bool photoId})
        > {
  $$MenuItemsTableTableManager(_$NutritionDatabase db, $MenuItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MenuItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MenuItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MenuItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> photoId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<double> energyKcal = const Value.absent(),
                Value<double> proteinG = const Value.absent(),
                Value<double> carbsG = const Value.absent(),
                Value<double> fatG = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MenuItemsCompanion(
                id: id,
                photoId: photoId,
                label: label,
                energyKcal: energyKcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String photoId,
                required String label,
                required double energyKcal,
                required double proteinG,
                required double carbsG,
                required double fatG,
                Value<int> rowid = const Value.absent(),
              }) => MenuItemsCompanion.insert(
                id: id,
                photoId: photoId,
                label: label,
                energyKcal: energyKcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MenuItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({photoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (photoId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.photoId,
                                referencedTable: $$MenuItemsTableReferences
                                    ._photoIdTable(db),
                                referencedColumn: $$MenuItemsTableReferences
                                    ._photoIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MenuItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$NutritionDatabase,
      $MenuItemsTable,
      MenuItemRow,
      $$MenuItemsTableFilterComposer,
      $$MenuItemsTableOrderingComposer,
      $$MenuItemsTableAnnotationComposer,
      $$MenuItemsTableCreateCompanionBuilder,
      $$MenuItemsTableUpdateCompanionBuilder,
      (MenuItemRow, $$MenuItemsTableReferences),
      MenuItemRow,
      PrefetchHooks Function({bool photoId})
    >;
typedef $$DietPlanRecordsTableCreateCompanionBuilder =
    DietPlanRecordsCompanion Function({
      required String id,
      required String name,
      required String document,
      Value<double?> declaredDailyEnergyKcal,
      Value<bool> isDefault,
      Value<String?> sourceLabel,
      required DateTime importedAt,
      Value<int> rowid,
    });
typedef $$DietPlanRecordsTableUpdateCompanionBuilder =
    DietPlanRecordsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> document,
      Value<double?> declaredDailyEnergyKcal,
      Value<bool> isDefault,
      Value<String?> sourceLabel,
      Value<DateTime> importedAt,
      Value<int> rowid,
    });

class $$DietPlanRecordsTableFilterComposer
    extends Composer<_$NutritionDatabase, $DietPlanRecordsTable> {
  $$DietPlanRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get document => $composableBuilder(
    column: $table.document,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get declaredDailyEnergyKcal => $composableBuilder(
    column: $table.declaredDailyEnergyKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceLabel => $composableBuilder(
    column: $table.sourceLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DietPlanRecordsTableOrderingComposer
    extends Composer<_$NutritionDatabase, $DietPlanRecordsTable> {
  $$DietPlanRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get document => $composableBuilder(
    column: $table.document,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get declaredDailyEnergyKcal => $composableBuilder(
    column: $table.declaredDailyEnergyKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceLabel => $composableBuilder(
    column: $table.sourceLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DietPlanRecordsTableAnnotationComposer
    extends Composer<_$NutritionDatabase, $DietPlanRecordsTable> {
  $$DietPlanRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get document =>
      $composableBuilder(column: $table.document, builder: (column) => column);

  GeneratedColumn<double> get declaredDailyEnergyKcal => $composableBuilder(
    column: $table.declaredDailyEnergyKcal,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<String> get sourceLabel => $composableBuilder(
    column: $table.sourceLabel,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );
}

class $$DietPlanRecordsTableTableManager
    extends
        RootTableManager<
          _$NutritionDatabase,
          $DietPlanRecordsTable,
          DietPlanRow,
          $$DietPlanRecordsTableFilterComposer,
          $$DietPlanRecordsTableOrderingComposer,
          $$DietPlanRecordsTableAnnotationComposer,
          $$DietPlanRecordsTableCreateCompanionBuilder,
          $$DietPlanRecordsTableUpdateCompanionBuilder,
          (
            DietPlanRow,
            BaseReferences<
              _$NutritionDatabase,
              $DietPlanRecordsTable,
              DietPlanRow
            >,
          ),
          DietPlanRow,
          PrefetchHooks Function()
        > {
  $$DietPlanRecordsTableTableManager(
    _$NutritionDatabase db,
    $DietPlanRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DietPlanRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DietPlanRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DietPlanRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> document = const Value.absent(),
                Value<double?> declaredDailyEnergyKcal = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<String?> sourceLabel = const Value.absent(),
                Value<DateTime> importedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DietPlanRecordsCompanion(
                id: id,
                name: name,
                document: document,
                declaredDailyEnergyKcal: declaredDailyEnergyKcal,
                isDefault: isDefault,
                sourceLabel: sourceLabel,
                importedAt: importedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String document,
                Value<double?> declaredDailyEnergyKcal = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<String?> sourceLabel = const Value.absent(),
                required DateTime importedAt,
                Value<int> rowid = const Value.absent(),
              }) => DietPlanRecordsCompanion.insert(
                id: id,
                name: name,
                document: document,
                declaredDailyEnergyKcal: declaredDailyEnergyKcal,
                isDefault: isDefault,
                sourceLabel: sourceLabel,
                importedAt: importedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DietPlanRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$NutritionDatabase,
      $DietPlanRecordsTable,
      DietPlanRow,
      $$DietPlanRecordsTableFilterComposer,
      $$DietPlanRecordsTableOrderingComposer,
      $$DietPlanRecordsTableAnnotationComposer,
      $$DietPlanRecordsTableCreateCompanionBuilder,
      $$DietPlanRecordsTableUpdateCompanionBuilder,
      (
        DietPlanRow,
        BaseReferences<_$NutritionDatabase, $DietPlanRecordsTable, DietPlanRow>,
      ),
      DietPlanRow,
      PrefetchHooks Function()
    >;
typedef $$ComponentSelectionsTableCreateCompanionBuilder =
    ComponentSelectionsCompanion Function({
      required int dayEpoch,
      required String componentId,
      required String optionId,
      Value<int> rowid,
    });
typedef $$ComponentSelectionsTableUpdateCompanionBuilder =
    ComponentSelectionsCompanion Function({
      Value<int> dayEpoch,
      Value<String> componentId,
      Value<String> optionId,
      Value<int> rowid,
    });

class $$ComponentSelectionsTableFilterComposer
    extends Composer<_$NutritionDatabase, $ComponentSelectionsTable> {
  $$ComponentSelectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get dayEpoch => $composableBuilder(
    column: $table.dayEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get componentId => $composableBuilder(
    column: $table.componentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get optionId => $composableBuilder(
    column: $table.optionId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ComponentSelectionsTableOrderingComposer
    extends Composer<_$NutritionDatabase, $ComponentSelectionsTable> {
  $$ComponentSelectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get dayEpoch => $composableBuilder(
    column: $table.dayEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get componentId => $composableBuilder(
    column: $table.componentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get optionId => $composableBuilder(
    column: $table.optionId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ComponentSelectionsTableAnnotationComposer
    extends Composer<_$NutritionDatabase, $ComponentSelectionsTable> {
  $$ComponentSelectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get dayEpoch =>
      $composableBuilder(column: $table.dayEpoch, builder: (column) => column);

  GeneratedColumn<String> get componentId => $composableBuilder(
    column: $table.componentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get optionId =>
      $composableBuilder(column: $table.optionId, builder: (column) => column);
}

class $$ComponentSelectionsTableTableManager
    extends
        RootTableManager<
          _$NutritionDatabase,
          $ComponentSelectionsTable,
          ComponentSelectionRow,
          $$ComponentSelectionsTableFilterComposer,
          $$ComponentSelectionsTableOrderingComposer,
          $$ComponentSelectionsTableAnnotationComposer,
          $$ComponentSelectionsTableCreateCompanionBuilder,
          $$ComponentSelectionsTableUpdateCompanionBuilder,
          (
            ComponentSelectionRow,
            BaseReferences<
              _$NutritionDatabase,
              $ComponentSelectionsTable,
              ComponentSelectionRow
            >,
          ),
          ComponentSelectionRow,
          PrefetchHooks Function()
        > {
  $$ComponentSelectionsTableTableManager(
    _$NutritionDatabase db,
    $ComponentSelectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ComponentSelectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ComponentSelectionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ComponentSelectionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> dayEpoch = const Value.absent(),
                Value<String> componentId = const Value.absent(),
                Value<String> optionId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ComponentSelectionsCompanion(
                dayEpoch: dayEpoch,
                componentId: componentId,
                optionId: optionId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int dayEpoch,
                required String componentId,
                required String optionId,
                Value<int> rowid = const Value.absent(),
              }) => ComponentSelectionsCompanion.insert(
                dayEpoch: dayEpoch,
                componentId: componentId,
                optionId: optionId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ComponentSelectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$NutritionDatabase,
      $ComponentSelectionsTable,
      ComponentSelectionRow,
      $$ComponentSelectionsTableFilterComposer,
      $$ComponentSelectionsTableOrderingComposer,
      $$ComponentSelectionsTableAnnotationComposer,
      $$ComponentSelectionsTableCreateCompanionBuilder,
      $$ComponentSelectionsTableUpdateCompanionBuilder,
      (
        ComponentSelectionRow,
        BaseReferences<
          _$NutritionDatabase,
          $ComponentSelectionsTable,
          ComponentSelectionRow
        >,
      ),
      ComponentSelectionRow,
      PrefetchHooks Function()
    >;
typedef $$SavedMealsTableCreateCompanionBuilder =
    SavedMealsCompanion Function({
      required String id,
      required String name,
      Value<String?> portionNote,
      required double energyKcal,
      required double proteinG,
      required double carbsG,
      required double fatG,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$SavedMealsTableUpdateCompanionBuilder =
    SavedMealsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> portionNote,
      Value<double> energyKcal,
      Value<double> proteinG,
      Value<double> carbsG,
      Value<double> fatG,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$SavedMealsTableReferences
    extends
        BaseReferences<_$NutritionDatabase, $SavedMealsTable, SavedMealRow> {
  $$SavedMealsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $SavedMealIngredientsTable,
    List<SavedMealIngredientRow>
  >
  _savedMealIngredientsRefsTable(_$NutritionDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.savedMealIngredients,
        aliasName: 'saved_meals__id__saved_meal_ingredients__saved_meal_id',
      );

  $$SavedMealIngredientsTableProcessedTableManager
  get savedMealIngredientsRefs {
    final manager = $$SavedMealIngredientsTableTableManager(
      $_db,
      $_db.savedMealIngredients,
    ).filter((f) => f.savedMealId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _savedMealIngredientsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SavedMealsTableFilterComposer
    extends Composer<_$NutritionDatabase, $SavedMealsTable> {
  $$SavedMealsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get portionNote => $composableBuilder(
    column: $table.portionNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> savedMealIngredientsRefs(
    Expression<bool> Function($$SavedMealIngredientsTableFilterComposer f) f,
  ) {
    final $$SavedMealIngredientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.savedMealIngredients,
      getReferencedColumn: (t) => t.savedMealId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavedMealIngredientsTableFilterComposer(
            $db: $db,
            $table: $db.savedMealIngredients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SavedMealsTableOrderingComposer
    extends Composer<_$NutritionDatabase, $SavedMealsTable> {
  $$SavedMealsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get portionNote => $composableBuilder(
    column: $table.portionNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedMealsTableAnnotationComposer
    extends Composer<_$NutritionDatabase, $SavedMealsTable> {
  $$SavedMealsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get portionNote => $composableBuilder(
    column: $table.portionNote,
    builder: (column) => column,
  );

  GeneratedColumn<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> savedMealIngredientsRefs<T extends Object>(
    Expression<T> Function($$SavedMealIngredientsTableAnnotationComposer a) f,
  ) {
    final $$SavedMealIngredientsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.savedMealIngredients,
          getReferencedColumn: (t) => t.savedMealId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SavedMealIngredientsTableAnnotationComposer(
                $db: $db,
                $table: $db.savedMealIngredients,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SavedMealsTableTableManager
    extends
        RootTableManager<
          _$NutritionDatabase,
          $SavedMealsTable,
          SavedMealRow,
          $$SavedMealsTableFilterComposer,
          $$SavedMealsTableOrderingComposer,
          $$SavedMealsTableAnnotationComposer,
          $$SavedMealsTableCreateCompanionBuilder,
          $$SavedMealsTableUpdateCompanionBuilder,
          (SavedMealRow, $$SavedMealsTableReferences),
          SavedMealRow,
          PrefetchHooks Function({bool savedMealIngredientsRefs})
        > {
  $$SavedMealsTableTableManager(_$NutritionDatabase db, $SavedMealsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedMealsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedMealsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedMealsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> portionNote = const Value.absent(),
                Value<double> energyKcal = const Value.absent(),
                Value<double> proteinG = const Value.absent(),
                Value<double> carbsG = const Value.absent(),
                Value<double> fatG = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedMealsCompanion(
                id: id,
                name: name,
                portionNote: portionNote,
                energyKcal: energyKcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> portionNote = const Value.absent(),
                required double energyKcal,
                required double proteinG,
                required double carbsG,
                required double fatG,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SavedMealsCompanion.insert(
                id: id,
                name: name,
                portionNote: portionNote,
                energyKcal: energyKcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SavedMealsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({savedMealIngredientsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (savedMealIngredientsRefs) db.savedMealIngredients,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (savedMealIngredientsRefs)
                    await $_getPrefetchedData<
                      SavedMealRow,
                      $SavedMealsTable,
                      SavedMealIngredientRow
                    >(
                      currentTable: table,
                      referencedTable: $$SavedMealsTableReferences
                          ._savedMealIngredientsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SavedMealsTableReferences(
                            db,
                            table,
                            p0,
                          ).savedMealIngredientsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.savedMealId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SavedMealsTableProcessedTableManager =
    ProcessedTableManager<
      _$NutritionDatabase,
      $SavedMealsTable,
      SavedMealRow,
      $$SavedMealsTableFilterComposer,
      $$SavedMealsTableOrderingComposer,
      $$SavedMealsTableAnnotationComposer,
      $$SavedMealsTableCreateCompanionBuilder,
      $$SavedMealsTableUpdateCompanionBuilder,
      (SavedMealRow, $$SavedMealsTableReferences),
      SavedMealRow,
      PrefetchHooks Function({bool savedMealIngredientsRefs})
    >;
typedef $$ComponentDefaultsTableCreateCompanionBuilder =
    ComponentDefaultsCompanion Function({
      required String componentId,
      required String optionId,
      Value<int> rowid,
    });
typedef $$ComponentDefaultsTableUpdateCompanionBuilder =
    ComponentDefaultsCompanion Function({
      Value<String> componentId,
      Value<String> optionId,
      Value<int> rowid,
    });

class $$ComponentDefaultsTableFilterComposer
    extends Composer<_$NutritionDatabase, $ComponentDefaultsTable> {
  $$ComponentDefaultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get componentId => $composableBuilder(
    column: $table.componentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get optionId => $composableBuilder(
    column: $table.optionId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ComponentDefaultsTableOrderingComposer
    extends Composer<_$NutritionDatabase, $ComponentDefaultsTable> {
  $$ComponentDefaultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get componentId => $composableBuilder(
    column: $table.componentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get optionId => $composableBuilder(
    column: $table.optionId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ComponentDefaultsTableAnnotationComposer
    extends Composer<_$NutritionDatabase, $ComponentDefaultsTable> {
  $$ComponentDefaultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get componentId => $composableBuilder(
    column: $table.componentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get optionId =>
      $composableBuilder(column: $table.optionId, builder: (column) => column);
}

class $$ComponentDefaultsTableTableManager
    extends
        RootTableManager<
          _$NutritionDatabase,
          $ComponentDefaultsTable,
          ComponentDefaultRow,
          $$ComponentDefaultsTableFilterComposer,
          $$ComponentDefaultsTableOrderingComposer,
          $$ComponentDefaultsTableAnnotationComposer,
          $$ComponentDefaultsTableCreateCompanionBuilder,
          $$ComponentDefaultsTableUpdateCompanionBuilder,
          (
            ComponentDefaultRow,
            BaseReferences<
              _$NutritionDatabase,
              $ComponentDefaultsTable,
              ComponentDefaultRow
            >,
          ),
          ComponentDefaultRow,
          PrefetchHooks Function()
        > {
  $$ComponentDefaultsTableTableManager(
    _$NutritionDatabase db,
    $ComponentDefaultsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ComponentDefaultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ComponentDefaultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ComponentDefaultsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> componentId = const Value.absent(),
                Value<String> optionId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ComponentDefaultsCompanion(
                componentId: componentId,
                optionId: optionId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String componentId,
                required String optionId,
                Value<int> rowid = const Value.absent(),
              }) => ComponentDefaultsCompanion.insert(
                componentId: componentId,
                optionId: optionId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ComponentDefaultsTableProcessedTableManager =
    ProcessedTableManager<
      _$NutritionDatabase,
      $ComponentDefaultsTable,
      ComponentDefaultRow,
      $$ComponentDefaultsTableFilterComposer,
      $$ComponentDefaultsTableOrderingComposer,
      $$ComponentDefaultsTableAnnotationComposer,
      $$ComponentDefaultsTableCreateCompanionBuilder,
      $$ComponentDefaultsTableUpdateCompanionBuilder,
      (
        ComponentDefaultRow,
        BaseReferences<
          _$NutritionDatabase,
          $ComponentDefaultsTable,
          ComponentDefaultRow
        >,
      ),
      ComponentDefaultRow,
      PrefetchHooks Function()
    >;
typedef $$IntakeIngredientsTableCreateCompanionBuilder =
    IntakeIngredientsCompanion Function({
      required String entryId,
      required String foodId,
      required double grams,
      Value<double?> count,
      Value<String?> unit,
      required int position,
      Value<int> rowid,
    });
typedef $$IntakeIngredientsTableUpdateCompanionBuilder =
    IntakeIngredientsCompanion Function({
      Value<String> entryId,
      Value<String> foodId,
      Value<double> grams,
      Value<double?> count,
      Value<String?> unit,
      Value<int> position,
      Value<int> rowid,
    });

final class $$IntakeIngredientsTableReferences
    extends
        BaseReferences<
          _$NutritionDatabase,
          $IntakeIngredientsTable,
          IntakeIngredientRow
        > {
  $$IntakeIngredientsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $NutritionEntriesTable _entryIdTable(_$NutritionDatabase db) => db
      .nutritionEntries
      .createAlias('intake_ingredients__entry_id__nutrition_entries__id');

  $$NutritionEntriesTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<String>('entry_id')!;

    final manager = $$NutritionEntriesTableTableManager(
      $_db,
      $_db.nutritionEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IntakeIngredientsTableFilterComposer
    extends Composer<_$NutritionDatabase, $IntakeIngredientsTable> {
  $$IntakeIngredientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$NutritionEntriesTableFilterComposer get entryId {
    final $$NutritionEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.nutritionEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NutritionEntriesTableFilterComposer(
            $db: $db,
            $table: $db.nutritionEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntakeIngredientsTableOrderingComposer
    extends Composer<_$NutritionDatabase, $IntakeIngredientsTable> {
  $$IntakeIngredientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$NutritionEntriesTableOrderingComposer get entryId {
    final $$NutritionEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.nutritionEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NutritionEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.nutritionEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntakeIngredientsTableAnnotationComposer
    extends Composer<_$NutritionDatabase, $IntakeIngredientsTable> {
  $$IntakeIngredientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get foodId =>
      $composableBuilder(column: $table.foodId, builder: (column) => column);

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  GeneratedColumn<double> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$NutritionEntriesTableAnnotationComposer get entryId {
    final $$NutritionEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.nutritionEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NutritionEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.nutritionEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntakeIngredientsTableTableManager
    extends
        RootTableManager<
          _$NutritionDatabase,
          $IntakeIngredientsTable,
          IntakeIngredientRow,
          $$IntakeIngredientsTableFilterComposer,
          $$IntakeIngredientsTableOrderingComposer,
          $$IntakeIngredientsTableAnnotationComposer,
          $$IntakeIngredientsTableCreateCompanionBuilder,
          $$IntakeIngredientsTableUpdateCompanionBuilder,
          (IntakeIngredientRow, $$IntakeIngredientsTableReferences),
          IntakeIngredientRow,
          PrefetchHooks Function({bool entryId})
        > {
  $$IntakeIngredientsTableTableManager(
    _$NutritionDatabase db,
    $IntakeIngredientsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IntakeIngredientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IntakeIngredientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IntakeIngredientsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> entryId = const Value.absent(),
                Value<String> foodId = const Value.absent(),
                Value<double> grams = const Value.absent(),
                Value<double?> count = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IntakeIngredientsCompanion(
                entryId: entryId,
                foodId: foodId,
                grams: grams,
                count: count,
                unit: unit,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entryId,
                required String foodId,
                required double grams,
                Value<double?> count = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => IntakeIngredientsCompanion.insert(
                entryId: entryId,
                foodId: foodId,
                grams: grams,
                count: count,
                unit: unit,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$IntakeIngredientsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (entryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.entryId,
                                referencedTable:
                                    $$IntakeIngredientsTableReferences
                                        ._entryIdTable(db),
                                referencedColumn:
                                    $$IntakeIngredientsTableReferences
                                        ._entryIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$IntakeIngredientsTableProcessedTableManager =
    ProcessedTableManager<
      _$NutritionDatabase,
      $IntakeIngredientsTable,
      IntakeIngredientRow,
      $$IntakeIngredientsTableFilterComposer,
      $$IntakeIngredientsTableOrderingComposer,
      $$IntakeIngredientsTableAnnotationComposer,
      $$IntakeIngredientsTableCreateCompanionBuilder,
      $$IntakeIngredientsTableUpdateCompanionBuilder,
      (IntakeIngredientRow, $$IntakeIngredientsTableReferences),
      IntakeIngredientRow,
      PrefetchHooks Function({bool entryId})
    >;
typedef $$SavedMealIngredientsTableCreateCompanionBuilder =
    SavedMealIngredientsCompanion Function({
      required String savedMealId,
      required String foodId,
      required double grams,
      Value<double?> count,
      Value<String?> unit,
      required int position,
      Value<int> rowid,
    });
typedef $$SavedMealIngredientsTableUpdateCompanionBuilder =
    SavedMealIngredientsCompanion Function({
      Value<String> savedMealId,
      Value<String> foodId,
      Value<double> grams,
      Value<double?> count,
      Value<String?> unit,
      Value<int> position,
      Value<int> rowid,
    });

final class $$SavedMealIngredientsTableReferences
    extends
        BaseReferences<
          _$NutritionDatabase,
          $SavedMealIngredientsTable,
          SavedMealIngredientRow
        > {
  $$SavedMealIngredientsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SavedMealsTable _savedMealIdTable(_$NutritionDatabase db) => db
      .savedMeals
      .createAlias('saved_meal_ingredients__saved_meal_id__saved_meals__id');

  $$SavedMealsTableProcessedTableManager get savedMealId {
    final $_column = $_itemColumn<String>('saved_meal_id')!;

    final manager = $$SavedMealsTableTableManager(
      $_db,
      $_db.savedMeals,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_savedMealIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SavedMealIngredientsTableFilterComposer
    extends Composer<_$NutritionDatabase, $SavedMealIngredientsTable> {
  $$SavedMealIngredientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$SavedMealsTableFilterComposer get savedMealId {
    final $$SavedMealsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.savedMealId,
      referencedTable: $db.savedMeals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavedMealsTableFilterComposer(
            $db: $db,
            $table: $db.savedMeals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SavedMealIngredientsTableOrderingComposer
    extends Composer<_$NutritionDatabase, $SavedMealIngredientsTable> {
  $$SavedMealIngredientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$SavedMealsTableOrderingComposer get savedMealId {
    final $$SavedMealsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.savedMealId,
      referencedTable: $db.savedMeals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavedMealsTableOrderingComposer(
            $db: $db,
            $table: $db.savedMeals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SavedMealIngredientsTableAnnotationComposer
    extends Composer<_$NutritionDatabase, $SavedMealIngredientsTable> {
  $$SavedMealIngredientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get foodId =>
      $composableBuilder(column: $table.foodId, builder: (column) => column);

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  GeneratedColumn<double> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$SavedMealsTableAnnotationComposer get savedMealId {
    final $$SavedMealsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.savedMealId,
      referencedTable: $db.savedMeals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavedMealsTableAnnotationComposer(
            $db: $db,
            $table: $db.savedMeals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SavedMealIngredientsTableTableManager
    extends
        RootTableManager<
          _$NutritionDatabase,
          $SavedMealIngredientsTable,
          SavedMealIngredientRow,
          $$SavedMealIngredientsTableFilterComposer,
          $$SavedMealIngredientsTableOrderingComposer,
          $$SavedMealIngredientsTableAnnotationComposer,
          $$SavedMealIngredientsTableCreateCompanionBuilder,
          $$SavedMealIngredientsTableUpdateCompanionBuilder,
          (SavedMealIngredientRow, $$SavedMealIngredientsTableReferences),
          SavedMealIngredientRow,
          PrefetchHooks Function({bool savedMealId})
        > {
  $$SavedMealIngredientsTableTableManager(
    _$NutritionDatabase db,
    $SavedMealIngredientsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedMealIngredientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedMealIngredientsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SavedMealIngredientsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> savedMealId = const Value.absent(),
                Value<String> foodId = const Value.absent(),
                Value<double> grams = const Value.absent(),
                Value<double?> count = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedMealIngredientsCompanion(
                savedMealId: savedMealId,
                foodId: foodId,
                grams: grams,
                count: count,
                unit: unit,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String savedMealId,
                required String foodId,
                required double grams,
                Value<double?> count = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => SavedMealIngredientsCompanion.insert(
                savedMealId: savedMealId,
                foodId: foodId,
                grams: grams,
                count: count,
                unit: unit,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SavedMealIngredientsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({savedMealId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (savedMealId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.savedMealId,
                                referencedTable:
                                    $$SavedMealIngredientsTableReferences
                                        ._savedMealIdTable(db),
                                referencedColumn:
                                    $$SavedMealIngredientsTableReferences
                                        ._savedMealIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SavedMealIngredientsTableProcessedTableManager =
    ProcessedTableManager<
      _$NutritionDatabase,
      $SavedMealIngredientsTable,
      SavedMealIngredientRow,
      $$SavedMealIngredientsTableFilterComposer,
      $$SavedMealIngredientsTableOrderingComposer,
      $$SavedMealIngredientsTableAnnotationComposer,
      $$SavedMealIngredientsTableCreateCompanionBuilder,
      $$SavedMealIngredientsTableUpdateCompanionBuilder,
      (SavedMealIngredientRow, $$SavedMealIngredientsTableReferences),
      SavedMealIngredientRow,
      PrefetchHooks Function({bool savedMealId})
    >;
typedef $$MealSubstituteIngredientsTableCreateCompanionBuilder =
    MealSubstituteIngredientsCompanion Function({
      required String substituteId,
      required String foodId,
      required double grams,
      Value<double?> count,
      Value<String?> unit,
      required int position,
      Value<int> rowid,
    });
typedef $$MealSubstituteIngredientsTableUpdateCompanionBuilder =
    MealSubstituteIngredientsCompanion Function({
      Value<String> substituteId,
      Value<String> foodId,
      Value<double> grams,
      Value<double?> count,
      Value<String?> unit,
      Value<int> position,
      Value<int> rowid,
    });

final class $$MealSubstituteIngredientsTableReferences
    extends
        BaseReferences<
          _$NutritionDatabase,
          $MealSubstituteIngredientsTable,
          MealSubstituteIngredientRow
        > {
  $$MealSubstituteIngredientsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MealSubstitutesTable _substituteIdTable(_$NutritionDatabase db) =>
      db.mealSubstitutes.createAlias(
        'meal_substitute_ingredients__substitute_id__meal_substitutes__id',
      );

  $$MealSubstitutesTableProcessedTableManager get substituteId {
    final $_column = $_itemColumn<String>('substitute_id')!;

    final manager = $$MealSubstitutesTableTableManager(
      $_db,
      $_db.mealSubstitutes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_substituteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MealSubstituteIngredientsTableFilterComposer
    extends Composer<_$NutritionDatabase, $MealSubstituteIngredientsTable> {
  $$MealSubstituteIngredientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$MealSubstitutesTableFilterComposer get substituteId {
    final $$MealSubstitutesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.substituteId,
      referencedTable: $db.mealSubstitutes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealSubstitutesTableFilterComposer(
            $db: $db,
            $table: $db.mealSubstitutes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MealSubstituteIngredientsTableOrderingComposer
    extends Composer<_$NutritionDatabase, $MealSubstituteIngredientsTable> {
  $$MealSubstituteIngredientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$MealSubstitutesTableOrderingComposer get substituteId {
    final $$MealSubstitutesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.substituteId,
      referencedTable: $db.mealSubstitutes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealSubstitutesTableOrderingComposer(
            $db: $db,
            $table: $db.mealSubstitutes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MealSubstituteIngredientsTableAnnotationComposer
    extends Composer<_$NutritionDatabase, $MealSubstituteIngredientsTable> {
  $$MealSubstituteIngredientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get foodId =>
      $composableBuilder(column: $table.foodId, builder: (column) => column);

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  GeneratedColumn<double> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$MealSubstitutesTableAnnotationComposer get substituteId {
    final $$MealSubstitutesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.substituteId,
      referencedTable: $db.mealSubstitutes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealSubstitutesTableAnnotationComposer(
            $db: $db,
            $table: $db.mealSubstitutes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MealSubstituteIngredientsTableTableManager
    extends
        RootTableManager<
          _$NutritionDatabase,
          $MealSubstituteIngredientsTable,
          MealSubstituteIngredientRow,
          $$MealSubstituteIngredientsTableFilterComposer,
          $$MealSubstituteIngredientsTableOrderingComposer,
          $$MealSubstituteIngredientsTableAnnotationComposer,
          $$MealSubstituteIngredientsTableCreateCompanionBuilder,
          $$MealSubstituteIngredientsTableUpdateCompanionBuilder,
          (
            MealSubstituteIngredientRow,
            $$MealSubstituteIngredientsTableReferences,
          ),
          MealSubstituteIngredientRow,
          PrefetchHooks Function({bool substituteId})
        > {
  $$MealSubstituteIngredientsTableTableManager(
    _$NutritionDatabase db,
    $MealSubstituteIngredientsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealSubstituteIngredientsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MealSubstituteIngredientsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MealSubstituteIngredientsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> substituteId = const Value.absent(),
                Value<String> foodId = const Value.absent(),
                Value<double> grams = const Value.absent(),
                Value<double?> count = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealSubstituteIngredientsCompanion(
                substituteId: substituteId,
                foodId: foodId,
                grams: grams,
                count: count,
                unit: unit,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String substituteId,
                required String foodId,
                required double grams,
                Value<double?> count = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => MealSubstituteIngredientsCompanion.insert(
                substituteId: substituteId,
                foodId: foodId,
                grams: grams,
                count: count,
                unit: unit,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MealSubstituteIngredientsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({substituteId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (substituteId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.substituteId,
                                referencedTable:
                                    $$MealSubstituteIngredientsTableReferences
                                        ._substituteIdTable(db),
                                referencedColumn:
                                    $$MealSubstituteIngredientsTableReferences
                                        ._substituteIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MealSubstituteIngredientsTableProcessedTableManager =
    ProcessedTableManager<
      _$NutritionDatabase,
      $MealSubstituteIngredientsTable,
      MealSubstituteIngredientRow,
      $$MealSubstituteIngredientsTableFilterComposer,
      $$MealSubstituteIngredientsTableOrderingComposer,
      $$MealSubstituteIngredientsTableAnnotationComposer,
      $$MealSubstituteIngredientsTableCreateCompanionBuilder,
      $$MealSubstituteIngredientsTableUpdateCompanionBuilder,
      (MealSubstituteIngredientRow, $$MealSubstituteIngredientsTableReferences),
      MealSubstituteIngredientRow,
      PrefetchHooks Function({bool substituteId})
    >;

class $NutritionDatabaseManager {
  final _$NutritionDatabase _db;
  $NutritionDatabaseManager(this._db);
  $$PlannedMealsTableTableManager get plannedMeals =>
      $$PlannedMealsTableTableManager(_db, _db.plannedMeals);
  $$NutritionEntriesTableTableManager get nutritionEntries =>
      $$NutritionEntriesTableTableManager(_db, _db.nutritionEntries);
  $$HydrationEntriesTableTableManager get hydrationEntries =>
      $$HydrationEntriesTableTableManager(_db, _db.hydrationEntries);
  $$MealSubstitutesTableTableManager get mealSubstitutes =>
      $$MealSubstitutesTableTableManager(_db, _db.mealSubstitutes);
  $$MenuPhotosTableTableManager get menuPhotos =>
      $$MenuPhotosTableTableManager(_db, _db.menuPhotos);
  $$MenuItemsTableTableManager get menuItems =>
      $$MenuItemsTableTableManager(_db, _db.menuItems);
  $$DietPlanRecordsTableTableManager get dietPlanRecords =>
      $$DietPlanRecordsTableTableManager(_db, _db.dietPlanRecords);
  $$ComponentSelectionsTableTableManager get componentSelections =>
      $$ComponentSelectionsTableTableManager(_db, _db.componentSelections);
  $$SavedMealsTableTableManager get savedMeals =>
      $$SavedMealsTableTableManager(_db, _db.savedMeals);
  $$ComponentDefaultsTableTableManager get componentDefaults =>
      $$ComponentDefaultsTableTableManager(_db, _db.componentDefaults);
  $$IntakeIngredientsTableTableManager get intakeIngredients =>
      $$IntakeIngredientsTableTableManager(_db, _db.intakeIngredients);
  $$SavedMealIngredientsTableTableManager get savedMealIngredients =>
      $$SavedMealIngredientsTableTableManager(_db, _db.savedMealIngredients);
  $$MealSubstituteIngredientsTableTableManager get mealSubstituteIngredients =>
      $$MealSubstituteIngredientsTableTableManager(
        _db,
        _db.mealSubstituteIngredients,
      );
}
