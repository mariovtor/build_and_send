library build_and_send;

import '../build_config.dart';
import 'android_builder.dart';
import 'builder.dart';
import 'ios_builder.dart';

class BuildService {
  static Builder createAndroidBuilder({
    required FlavorConfig flavor,
    required bool verbose,
  }) {
    return AndroidBuilder(
      buildMethod: flavor.method,
      verbose: verbose,
    );
  }

  static Builder createIOSBuilder({
    required FlavorConfig flavor,
    required bool noPodSync,
    required bool verbose,
  }) {
    return IOSBuilder(
      buildMethod: flavor.method,
      noPodSync: noPodSync,
      verbose: verbose,
    );
  }
}
