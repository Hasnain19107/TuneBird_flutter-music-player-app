// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'directory_info_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DirectoryInfoModelAdapter extends TypeAdapter<DirectoryInfoModel> {
  @override
  final int typeId = 0;

  @override
  DirectoryInfoModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DirectoryInfoModel(
      path: fields[0] as String,
      name: fields[1] as String,
      audioFileCount: fields[2] as int,
      audioFilePaths: (fields[3] as List).cast<String>(),
      lastScanned: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DirectoryInfoModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.path)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.audioFileCount)
      ..writeByte(3)
      ..write(obj.audioFilePaths)
      ..writeByte(4)
      ..write(obj.lastScanned);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DirectoryInfoModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
