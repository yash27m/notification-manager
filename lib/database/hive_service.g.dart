// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_service.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SelectedAppModelAdapter extends TypeAdapter<SelectedAppModel> {
  @override
  final int typeId = 0;

  @override
  SelectedAppModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SelectedAppModel(
      packageName: fields[0] as String,
      appName: fields[1] as String,
      icon: fields[2] as Uint8List?,
    );
  }

  @override
  void write(BinaryWriter writer, SelectedAppModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.packageName)
      ..writeByte(1)
      ..write(obj.appName)
      ..writeByte(2)
      ..write(obj.icon);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectedAppModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DialHistoryEntryModelAdapter extends TypeAdapter<DialHistoryEntryModel> {
  @override
  final int typeId = 3;

  @override
  DialHistoryEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DialHistoryEntryModel(
      phoneNumber: fields[0] as String,
      message: fields[1] as String,
      calledAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DialHistoryEntryModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.phoneNumber)
      ..writeByte(1)
      ..write(obj.message)
      ..writeByte(2)
      ..write(obj.calledAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DialHistoryEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
