// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_model_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SongModelHiveAdapter extends TypeAdapter<SongModelHive> {
  @override
  final int typeId = 1;

  @override
  SongModelHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SongModelHive(
      id: fields[0] as String,
      title: fields[1] as String,
      artist: fields[2] as String,
      album: fields[3] as String,
      duration: fields[4] as String,
      uri: fields[5] as String,
      artworkPath: fields[6] as String?,
      lastScanned: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SongModelHive obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.artist)
      ..writeByte(3)
      ..write(obj.album)
      ..writeByte(4)
      ..write(obj.duration)
      ..writeByte(5)
      ..write(obj.uri)
      ..writeByte(6)
      ..write(obj.artworkPath)
      ..writeByte(7)
      ..write(obj.lastScanned);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongModelHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
