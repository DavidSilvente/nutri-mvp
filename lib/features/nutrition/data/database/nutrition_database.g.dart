// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrition_database.dart';

// ignore_for_file: type=lint
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recordedAt,
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
  const NutritionEntryRow({
    required this.id,
    required this.recordedAt,
    required this.dayEpoch,
    required this.energyKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
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
  }) => NutritionEntryRow(
    id: id ?? this.id,
    recordedAt: recordedAt ?? this.recordedAt,
    dayEpoch: dayEpoch ?? this.dayEpoch,
    energyKcal: energyKcal ?? this.energyKcal,
    proteinG: proteinG ?? this.proteinG,
    carbsG: carbsG ?? this.carbsG,
    fatG: fatG ?? this.fatG,
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
          ..write('fatG: $fatG')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, recordedAt, dayEpoch, energyKcal, proteinG, carbsG, fatG);
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
          other.fatG == this.fatG);
}

class NutritionEntriesCompanion extends UpdateCompanion<NutritionEntryRow> {
  final Value<String> id;
  final Value<DateTime> recordedAt;
  final Value<int> dayEpoch;
  final Value<double> energyKcal;
  final Value<double> proteinG;
  final Value<double> carbsG;
  final Value<double> fatG;
  final Value<int> rowid;
  const NutritionEntriesCompanion({
    this.id = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.dayEpoch = const Value.absent(),
    this.energyKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
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

class $DietTemplatesTable extends DietTemplates
    with TableInfo<$DietTemplatesTable, DietTemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DietTemplatesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    energyKcal,
    proteinG,
    carbsG,
    fatG,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'diet_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<DietTemplateRow> instance, {
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DietTemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DietTemplateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
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
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DietTemplatesTable createAlias(String alias) {
    return $DietTemplatesTable(attachedDatabase, alias);
  }
}

class DietTemplateRow extends DataClass implements Insertable<DietTemplateRow> {
  final String id;
  final String name;
  final double energyKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DietTemplateRow({
    required this.id,
    required this.name,
    required this.energyKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['energy_kcal'] = Variable<double>(energyKcal);
    map['protein_g'] = Variable<double>(proteinG);
    map['carbs_g'] = Variable<double>(carbsG);
    map['fat_g'] = Variable<double>(fatG);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DietTemplatesCompanion toCompanion(bool nullToAbsent) {
    return DietTemplatesCompanion(
      id: Value(id),
      name: Value(name),
      energyKcal: Value(energyKcal),
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      fatG: Value(fatG),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DietTemplateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DietTemplateRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      energyKcal: serializer.fromJson<double>(json['energyKcal']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      carbsG: serializer.fromJson<double>(json['carbsG']),
      fatG: serializer.fromJson<double>(json['fatG']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'energyKcal': serializer.toJson<double>(energyKcal),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbsG': serializer.toJson<double>(carbsG),
      'fatG': serializer.toJson<double>(fatG),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DietTemplateRow copyWith({
    String? id,
    String? name,
    double? energyKcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DietTemplateRow(
    id: id ?? this.id,
    name: name ?? this.name,
    energyKcal: energyKcal ?? this.energyKcal,
    proteinG: proteinG ?? this.proteinG,
    carbsG: carbsG ?? this.carbsG,
    fatG: fatG ?? this.fatG,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DietTemplateRow copyWithCompanion(DietTemplatesCompanion data) {
    return DietTemplateRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      energyKcal: data.energyKcal.present
          ? data.energyKcal.value
          : this.energyKcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DietTemplateRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('energyKcal: $energyKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    energyKcal,
    proteinG,
    carbsG,
    fatG,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DietTemplateRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.energyKcal == this.energyKcal &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.fatG == this.fatG &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DietTemplatesCompanion extends UpdateCompanion<DietTemplateRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<double> energyKcal;
  final Value<double> proteinG;
  final Value<double> carbsG;
  final Value<double> fatG;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DietTemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.energyKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DietTemplatesCompanion.insert({
    required String id,
    required String name,
    required double energyKcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       energyKcal = Value(energyKcal),
       proteinG = Value(proteinG),
       carbsG = Value(carbsG),
       fatG = Value(fatG),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DietTemplateRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? energyKcal,
    Expression<double>? proteinG,
    Expression<double>? carbsG,
    Expression<double>? fatG,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (energyKcal != null) 'energy_kcal': energyKcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DietTemplatesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<double>? energyKcal,
    Value<double>? proteinG,
    Value<double>? carbsG,
    Value<double>? fatG,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DietTemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      energyKcal: energyKcal ?? this.energyKcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DietTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('energyKcal: $energyKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DietMealSlotsTable extends DietMealSlots
    with TableInfo<$DietMealSlotsTable, DietMealSlotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DietMealSlotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES diet_templates (id) ON DELETE CASCADE',
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
    templateId,
    label,
    position,
    energyKcal,
    proteinG,
    carbsG,
    fatG,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'diet_meal_slots';
  @override
  VerificationContext validateIntegrity(
    Insertable<DietMealSlotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
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
    {templateId, position},
  ];
  @override
  DietMealSlotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DietMealSlotRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
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
  $DietMealSlotsTable createAlias(String alias) {
    return $DietMealSlotsTable(attachedDatabase, alias);
  }
}

class DietMealSlotRow extends DataClass implements Insertable<DietMealSlotRow> {
  final String id;
  final String templateId;
  final String label;
  final int position;
  final double energyKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  const DietMealSlotRow({
    required this.id,
    required this.templateId,
    required this.label,
    required this.position,
    required this.energyKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['template_id'] = Variable<String>(templateId);
    map['label'] = Variable<String>(label);
    map['position'] = Variable<int>(position);
    map['energy_kcal'] = Variable<double>(energyKcal);
    map['protein_g'] = Variable<double>(proteinG);
    map['carbs_g'] = Variable<double>(carbsG);
    map['fat_g'] = Variable<double>(fatG);
    return map;
  }

  DietMealSlotsCompanion toCompanion(bool nullToAbsent) {
    return DietMealSlotsCompanion(
      id: Value(id),
      templateId: Value(templateId),
      label: Value(label),
      position: Value(position),
      energyKcal: Value(energyKcal),
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      fatG: Value(fatG),
    );
  }

  factory DietMealSlotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DietMealSlotRow(
      id: serializer.fromJson<String>(json['id']),
      templateId: serializer.fromJson<String>(json['templateId']),
      label: serializer.fromJson<String>(json['label']),
      position: serializer.fromJson<int>(json['position']),
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
      'templateId': serializer.toJson<String>(templateId),
      'label': serializer.toJson<String>(label),
      'position': serializer.toJson<int>(position),
      'energyKcal': serializer.toJson<double>(energyKcal),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbsG': serializer.toJson<double>(carbsG),
      'fatG': serializer.toJson<double>(fatG),
    };
  }

  DietMealSlotRow copyWith({
    String? id,
    String? templateId,
    String? label,
    int? position,
    double? energyKcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
  }) => DietMealSlotRow(
    id: id ?? this.id,
    templateId: templateId ?? this.templateId,
    label: label ?? this.label,
    position: position ?? this.position,
    energyKcal: energyKcal ?? this.energyKcal,
    proteinG: proteinG ?? this.proteinG,
    carbsG: carbsG ?? this.carbsG,
    fatG: fatG ?? this.fatG,
  );
  DietMealSlotRow copyWithCompanion(DietMealSlotsCompanion data) {
    return DietMealSlotRow(
      id: data.id.present ? data.id.value : this.id,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      label: data.label.present ? data.label.value : this.label,
      position: data.position.present ? data.position.value : this.position,
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
    return (StringBuffer('DietMealSlotRow(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('label: $label, ')
          ..write('position: $position, ')
          ..write('energyKcal: $energyKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    templateId,
    label,
    position,
    energyKcal,
    proteinG,
    carbsG,
    fatG,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DietMealSlotRow &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.label == this.label &&
          other.position == this.position &&
          other.energyKcal == this.energyKcal &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.fatG == this.fatG);
}

class DietMealSlotsCompanion extends UpdateCompanion<DietMealSlotRow> {
  final Value<String> id;
  final Value<String> templateId;
  final Value<String> label;
  final Value<int> position;
  final Value<double> energyKcal;
  final Value<double> proteinG;
  final Value<double> carbsG;
  final Value<double> fatG;
  final Value<int> rowid;
  const DietMealSlotsCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.label = const Value.absent(),
    this.position = const Value.absent(),
    this.energyKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DietMealSlotsCompanion.insert({
    required String id,
    required String templateId,
    required String label,
    required int position,
    required double energyKcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       templateId = Value(templateId),
       label = Value(label),
       position = Value(position),
       energyKcal = Value(energyKcal),
       proteinG = Value(proteinG),
       carbsG = Value(carbsG),
       fatG = Value(fatG);
  static Insertable<DietMealSlotRow> custom({
    Expression<String>? id,
    Expression<String>? templateId,
    Expression<String>? label,
    Expression<int>? position,
    Expression<double>? energyKcal,
    Expression<double>? proteinG,
    Expression<double>? carbsG,
    Expression<double>? fatG,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (label != null) 'label': label,
      if (position != null) 'position': position,
      if (energyKcal != null) 'energy_kcal': energyKcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DietMealSlotsCompanion copyWith({
    Value<String>? id,
    Value<String>? templateId,
    Value<String>? label,
    Value<int>? position,
    Value<double>? energyKcal,
    Value<double>? proteinG,
    Value<double>? carbsG,
    Value<double>? fatG,
    Value<int>? rowid,
  }) {
    return DietMealSlotsCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      label: label ?? this.label,
      position: position ?? this.position,
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
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
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
    return (StringBuffer('DietMealSlotsCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('label: $label, ')
          ..write('position: $position, ')
          ..write('energyKcal: $energyKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES diet_meal_slots (id) ON DELETE CASCADE',
    ),
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

abstract class _$NutritionDatabase extends GeneratedDatabase {
  _$NutritionDatabase(QueryExecutor e) : super(e);
  $NutritionDatabaseManager get managers => $NutritionDatabaseManager(this);
  late final $NutritionEntriesTable nutritionEntries = $NutritionEntriesTable(
    this,
  );
  late final $HydrationEntriesTable hydrationEntries = $HydrationEntriesTable(
    this,
  );
  late final $DietTemplatesTable dietTemplates = $DietTemplatesTable(this);
  late final $DietMealSlotsTable dietMealSlots = $DietMealSlotsTable(this);
  late final $PlannedMealsTable plannedMeals = $PlannedMealsTable(this);
  late final $MealSubstitutesTable mealSubstitutes = $MealSubstitutesTable(
    this,
  );
  late final $MenuPhotosTable menuPhotos = $MenuPhotosTable(this);
  late final $MenuItemsTable menuItems = $MenuItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    nutritionEntries,
    hydrationEntries,
    dietTemplates,
    dietMealSlots,
    plannedMeals,
    mealSubstitutes,
    menuPhotos,
    menuItems,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'diet_templates',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('diet_meal_slots', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'diet_meal_slots',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('planned_meals', kind: UpdateKind.delete)],
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
  ]);
}

typedef $$NutritionEntriesTableCreateCompanionBuilder =
    NutritionEntriesCompanion Function({
      required String id,
      required DateTime recordedAt,
      required int dayEpoch,
      required double energyKcal,
      required double proteinG,
      required double carbsG,
      required double fatG,
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
      Value<int> rowid,
    });

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
          (
            NutritionEntryRow,
            BaseReferences<
              _$NutritionDatabase,
              $NutritionEntriesTable,
              NutritionEntryRow
            >,
          ),
          NutritionEntryRow,
          PrefetchHooks Function()
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
                Value<int> rowid = const Value.absent(),
              }) => NutritionEntriesCompanion(
                id: id,
                recordedAt: recordedAt,
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
                required DateTime recordedAt,
                required int dayEpoch,
                required double energyKcal,
                required double proteinG,
                required double carbsG,
                required double fatG,
                Value<int> rowid = const Value.absent(),
              }) => NutritionEntriesCompanion.insert(
                id: id,
                recordedAt: recordedAt,
                dayEpoch: dayEpoch,
                energyKcal: energyKcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
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
      (
        NutritionEntryRow,
        BaseReferences<
          _$NutritionDatabase,
          $NutritionEntriesTable,
          NutritionEntryRow
        >,
      ),
      NutritionEntryRow,
      PrefetchHooks Function()
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
typedef $$DietTemplatesTableCreateCompanionBuilder =
    DietTemplatesCompanion Function({
      required String id,
      required String name,
      required double energyKcal,
      required double proteinG,
      required double carbsG,
      required double fatG,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$DietTemplatesTableUpdateCompanionBuilder =
    DietTemplatesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<double> energyKcal,
      Value<double> proteinG,
      Value<double> carbsG,
      Value<double> fatG,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$DietTemplatesTableReferences
    extends
        BaseReferences<
          _$NutritionDatabase,
          $DietTemplatesTable,
          DietTemplateRow
        > {
  $$DietTemplatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$DietMealSlotsTable, List<DietMealSlotRow>>
  _dietMealSlotsRefsTable(_$NutritionDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.dietMealSlots,
        aliasName: 'diet_templates__id__diet_meal_slots__template_id',
      );

  $$DietMealSlotsTableProcessedTableManager get dietMealSlotsRefs {
    final manager = $$DietMealSlotsTableTableManager(
      $_db,
      $_db.dietMealSlots,
    ).filter((f) => f.templateId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_dietMealSlotsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DietTemplatesTableFilterComposer
    extends Composer<_$NutritionDatabase, $DietTemplatesTable> {
  $$DietTemplatesTableFilterComposer({
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

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> dietMealSlotsRefs(
    Expression<bool> Function($$DietMealSlotsTableFilterComposer f) f,
  ) {
    final $$DietMealSlotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dietMealSlots,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DietMealSlotsTableFilterComposer(
            $db: $db,
            $table: $db.dietMealSlots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DietTemplatesTableOrderingComposer
    extends Composer<_$NutritionDatabase, $DietTemplatesTable> {
  $$DietTemplatesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DietTemplatesTableAnnotationComposer
    extends Composer<_$NutritionDatabase, $DietTemplatesTable> {
  $$DietTemplatesTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> dietMealSlotsRefs<T extends Object>(
    Expression<T> Function($$DietMealSlotsTableAnnotationComposer a) f,
  ) {
    final $$DietMealSlotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dietMealSlots,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DietMealSlotsTableAnnotationComposer(
            $db: $db,
            $table: $db.dietMealSlots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DietTemplatesTableTableManager
    extends
        RootTableManager<
          _$NutritionDatabase,
          $DietTemplatesTable,
          DietTemplateRow,
          $$DietTemplatesTableFilterComposer,
          $$DietTemplatesTableOrderingComposer,
          $$DietTemplatesTableAnnotationComposer,
          $$DietTemplatesTableCreateCompanionBuilder,
          $$DietTemplatesTableUpdateCompanionBuilder,
          (DietTemplateRow, $$DietTemplatesTableReferences),
          DietTemplateRow,
          PrefetchHooks Function({bool dietMealSlotsRefs})
        > {
  $$DietTemplatesTableTableManager(
    _$NutritionDatabase db,
    $DietTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DietTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DietTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DietTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> energyKcal = const Value.absent(),
                Value<double> proteinG = const Value.absent(),
                Value<double> carbsG = const Value.absent(),
                Value<double> fatG = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DietTemplatesCompanion(
                id: id,
                name: name,
                energyKcal: energyKcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required double energyKcal,
                required double proteinG,
                required double carbsG,
                required double fatG,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DietTemplatesCompanion.insert(
                id: id,
                name: name,
                energyKcal: energyKcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DietTemplatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({dietMealSlotsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (dietMealSlotsRefs) db.dietMealSlots,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (dietMealSlotsRefs)
                    await $_getPrefetchedData<
                      DietTemplateRow,
                      $DietTemplatesTable,
                      DietMealSlotRow
                    >(
                      currentTable: table,
                      referencedTable: $$DietTemplatesTableReferences
                          ._dietMealSlotsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$DietTemplatesTableReferences(
                            db,
                            table,
                            p0,
                          ).dietMealSlotsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.templateId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DietTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$NutritionDatabase,
      $DietTemplatesTable,
      DietTemplateRow,
      $$DietTemplatesTableFilterComposer,
      $$DietTemplatesTableOrderingComposer,
      $$DietTemplatesTableAnnotationComposer,
      $$DietTemplatesTableCreateCompanionBuilder,
      $$DietTemplatesTableUpdateCompanionBuilder,
      (DietTemplateRow, $$DietTemplatesTableReferences),
      DietTemplateRow,
      PrefetchHooks Function({bool dietMealSlotsRefs})
    >;
typedef $$DietMealSlotsTableCreateCompanionBuilder =
    DietMealSlotsCompanion Function({
      required String id,
      required String templateId,
      required String label,
      required int position,
      required double energyKcal,
      required double proteinG,
      required double carbsG,
      required double fatG,
      Value<int> rowid,
    });
typedef $$DietMealSlotsTableUpdateCompanionBuilder =
    DietMealSlotsCompanion Function({
      Value<String> id,
      Value<String> templateId,
      Value<String> label,
      Value<int> position,
      Value<double> energyKcal,
      Value<double> proteinG,
      Value<double> carbsG,
      Value<double> fatG,
      Value<int> rowid,
    });

final class $$DietMealSlotsTableReferences
    extends
        BaseReferences<
          _$NutritionDatabase,
          $DietMealSlotsTable,
          DietMealSlotRow
        > {
  $$DietMealSlotsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DietTemplatesTable _templateIdTable(_$NutritionDatabase db) => db
      .dietTemplates
      .createAlias('diet_meal_slots__template_id__diet_templates__id');

  $$DietTemplatesTableProcessedTableManager get templateId {
    final $_column = $_itemColumn<String>('template_id')!;

    final manager = $$DietTemplatesTableTableManager(
      $_db,
      $_db.dietTemplates,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PlannedMealsTable, List<PlannedMealRow>>
  _plannedMealsRefsTable(_$NutritionDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.plannedMeals,
        aliasName: 'diet_meal_slots__id__planned_meals__slot_id',
      );

  $$PlannedMealsTableProcessedTableManager get plannedMealsRefs {
    final manager = $$PlannedMealsTableTableManager(
      $_db,
      $_db.plannedMeals,
    ).filter((f) => f.slotId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_plannedMealsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DietMealSlotsTableFilterComposer
    extends Composer<_$NutritionDatabase, $DietMealSlotsTable> {
  $$DietMealSlotsTableFilterComposer({
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

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
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

  $$DietTemplatesTableFilterComposer get templateId {
    final $$DietTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.dietTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DietTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.dietTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> plannedMealsRefs(
    Expression<bool> Function($$PlannedMealsTableFilterComposer f) f,
  ) {
    final $$PlannedMealsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plannedMeals,
      getReferencedColumn: (t) => t.slotId,
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
    return f(composer);
  }
}

class $$DietMealSlotsTableOrderingComposer
    extends Composer<_$NutritionDatabase, $DietMealSlotsTable> {
  $$DietMealSlotsTableOrderingComposer({
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

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
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

  $$DietTemplatesTableOrderingComposer get templateId {
    final $$DietTemplatesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.dietTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DietTemplatesTableOrderingComposer(
            $db: $db,
            $table: $db.dietTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DietMealSlotsTableAnnotationComposer
    extends Composer<_$NutritionDatabase, $DietMealSlotsTable> {
  $$DietMealSlotsTableAnnotationComposer({
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

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

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

  $$DietTemplatesTableAnnotationComposer get templateId {
    final $$DietTemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.dietTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DietTemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.dietTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> plannedMealsRefs<T extends Object>(
    Expression<T> Function($$PlannedMealsTableAnnotationComposer a) f,
  ) {
    final $$PlannedMealsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plannedMeals,
      getReferencedColumn: (t) => t.slotId,
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
    return f(composer);
  }
}

class $$DietMealSlotsTableTableManager
    extends
        RootTableManager<
          _$NutritionDatabase,
          $DietMealSlotsTable,
          DietMealSlotRow,
          $$DietMealSlotsTableFilterComposer,
          $$DietMealSlotsTableOrderingComposer,
          $$DietMealSlotsTableAnnotationComposer,
          $$DietMealSlotsTableCreateCompanionBuilder,
          $$DietMealSlotsTableUpdateCompanionBuilder,
          (DietMealSlotRow, $$DietMealSlotsTableReferences),
          DietMealSlotRow,
          PrefetchHooks Function({bool templateId, bool plannedMealsRefs})
        > {
  $$DietMealSlotsTableTableManager(
    _$NutritionDatabase db,
    $DietMealSlotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DietMealSlotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DietMealSlotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DietMealSlotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<double> energyKcal = const Value.absent(),
                Value<double> proteinG = const Value.absent(),
                Value<double> carbsG = const Value.absent(),
                Value<double> fatG = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DietMealSlotsCompanion(
                id: id,
                templateId: templateId,
                label: label,
                position: position,
                energyKcal: energyKcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String templateId,
                required String label,
                required int position,
                required double energyKcal,
                required double proteinG,
                required double carbsG,
                required double fatG,
                Value<int> rowid = const Value.absent(),
              }) => DietMealSlotsCompanion.insert(
                id: id,
                templateId: templateId,
                label: label,
                position: position,
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
                  $$DietMealSlotsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({templateId = false, plannedMealsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (plannedMealsRefs) db.plannedMeals,
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
                        if (templateId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.templateId,
                                    referencedTable:
                                        $$DietMealSlotsTableReferences
                                            ._templateIdTable(db),
                                    referencedColumn:
                                        $$DietMealSlotsTableReferences
                                            ._templateIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (plannedMealsRefs)
                        await $_getPrefetchedData<
                          DietMealSlotRow,
                          $DietMealSlotsTable,
                          PlannedMealRow
                        >(
                          currentTable: table,
                          referencedTable: $$DietMealSlotsTableReferences
                              ._plannedMealsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DietMealSlotsTableReferences(
                                db,
                                table,
                                p0,
                              ).plannedMealsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.slotId == item.id,
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

typedef $$DietMealSlotsTableProcessedTableManager =
    ProcessedTableManager<
      _$NutritionDatabase,
      $DietMealSlotsTable,
      DietMealSlotRow,
      $$DietMealSlotsTableFilterComposer,
      $$DietMealSlotsTableOrderingComposer,
      $$DietMealSlotsTableAnnotationComposer,
      $$DietMealSlotsTableCreateCompanionBuilder,
      $$DietMealSlotsTableUpdateCompanionBuilder,
      (DietMealSlotRow, $$DietMealSlotsTableReferences),
      DietMealSlotRow,
      PrefetchHooks Function({bool templateId, bool plannedMealsRefs})
    >;
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

  static $DietMealSlotsTable _slotIdTable(_$NutritionDatabase db) => db
      .dietMealSlots
      .createAlias('planned_meals__slot_id__diet_meal_slots__id');

  $$DietMealSlotsTableProcessedTableManager get slotId {
    final $_column = $_itemColumn<String>('slot_id')!;

    final manager = $$DietMealSlotsTableTableManager(
      $_db,
      $_db.dietMealSlots,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_slotIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
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

  $$DietMealSlotsTableFilterComposer get slotId {
    final $$DietMealSlotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.slotId,
      referencedTable: $db.dietMealSlots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DietMealSlotsTableFilterComposer(
            $db: $db,
            $table: $db.dietMealSlots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
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

  $$DietMealSlotsTableOrderingComposer get slotId {
    final $$DietMealSlotsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.slotId,
      referencedTable: $db.dietMealSlots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DietMealSlotsTableOrderingComposer(
            $db: $db,
            $table: $db.dietMealSlots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  $$DietMealSlotsTableAnnotationComposer get slotId {
    final $$DietMealSlotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.slotId,
      referencedTable: $db.dietMealSlots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DietMealSlotsTableAnnotationComposer(
            $db: $db,
            $table: $db.dietMealSlots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
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
          PrefetchHooks Function({bool slotId, bool mealSubstitutesRefs})
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
              ({slotId = false, mealSubstitutesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (mealSubstitutesRefs) db.mealSubstitutes,
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
                        if (slotId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.slotId,
                                    referencedTable:
                                        $$PlannedMealsTableReferences
                                            ._slotIdTable(db),
                                    referencedColumn:
                                        $$PlannedMealsTableReferences
                                            ._slotIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
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
      PrefetchHooks Function({bool slotId, bool mealSubstitutesRefs})
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
          PrefetchHooks Function({bool plannedMealId})
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
          prefetchHooksCallback: ({plannedMealId = false}) {
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
                return [];
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
      PrefetchHooks Function({bool plannedMealId})
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

class $NutritionDatabaseManager {
  final _$NutritionDatabase _db;
  $NutritionDatabaseManager(this._db);
  $$NutritionEntriesTableTableManager get nutritionEntries =>
      $$NutritionEntriesTableTableManager(_db, _db.nutritionEntries);
  $$HydrationEntriesTableTableManager get hydrationEntries =>
      $$HydrationEntriesTableTableManager(_db, _db.hydrationEntries);
  $$DietTemplatesTableTableManager get dietTemplates =>
      $$DietTemplatesTableTableManager(_db, _db.dietTemplates);
  $$DietMealSlotsTableTableManager get dietMealSlots =>
      $$DietMealSlotsTableTableManager(_db, _db.dietMealSlots);
  $$PlannedMealsTableTableManager get plannedMeals =>
      $$PlannedMealsTableTableManager(_db, _db.plannedMeals);
  $$MealSubstitutesTableTableManager get mealSubstitutes =>
      $$MealSubstitutesTableTableManager(_db, _db.mealSubstitutes);
  $$MenuPhotosTableTableManager get menuPhotos =>
      $$MenuPhotosTableTableManager(_db, _db.menuPhotos);
  $$MenuItemsTableTableManager get menuItems =>
      $$MenuItemsTableTableManager(_db, _db.menuItems);
}
