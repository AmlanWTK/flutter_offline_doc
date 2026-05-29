import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

bool get isMobilePlatform =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

bool get supportsCameraCapture => isMobilePlatform;

bool get supportsOcrCapture => isMobilePlatform;

/// Native FFI platforms where [llamadart] can run (not web).
bool get supportsLocalLlm =>
    !kIsWeb &&
    (Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isWindows ||
        Platform.isMacOS ||
        Platform.isLinux);
