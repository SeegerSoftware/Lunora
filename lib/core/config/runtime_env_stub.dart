/// Web / VM sans `dart:io`.
String? readRuntimeEnv(String name) => null;

bool readRuntimeEnvFlag(String name) {
  final v = readRuntimeEnv(name)?.toLowerCase();
  return v == 'true' || v == '1' || v == 'yes';
}
