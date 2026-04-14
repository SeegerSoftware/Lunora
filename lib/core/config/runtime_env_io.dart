import 'dart:io';

String? readRuntimeEnv(String name) => Platform.environment[name];

bool readRuntimeEnvFlag(String name) {
  final v = readRuntimeEnv(name)?.toLowerCase();
  return v == 'true' || v == '1' || v == 'yes';
}
