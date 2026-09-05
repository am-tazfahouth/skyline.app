import 'package:sky_line/core/enums/app_error_source.dart';

/// Immutable error code combining source + key.
/// Use const instances as map keys.
class AppErrorCode {
  final AppErrorSource source;
  final String key;

  const AppErrorCode(this.source, this.key);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppErrorCode &&
          runtimeType == other.runtimeType &&
          source == other.source &&
          key == other.key;

  @override
  int get hashCode => Object.hash(source, key);

  @override
  String toString() => '${source.name}:$key';
}
