import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import '../../open_file_safely.dart';
import 'macos.dart' as mac;
import 'windows.dart' as windows;
import 'linux.dart' as linux;

class OpenFile {
  static const MethodChannel _channel = MethodChannel('open_file_safe');

  OpenFile._();

  ///linuxDesktopName like 'xdg'/'gnome'
  static Future<OpenResult> open(String? filePath,
      {String? type,
      String? uti,
      String linuxDesktopName = "xdg",
      bool linuxByProcess = false}) async {
    assert(filePath != null);
    if (!Platform.isIOS && !Platform.isAndroid) {
      int result;
      // ignore: prefer_typing_uninitialized_variables
      var windowsResult;
      if (Platform.isMacOS) {
        result = mac.system(['open', '$filePath']);
      } else if (Platform.isLinux) {
        var filePathLinux = Uri.file(filePath!);
        if (linuxByProcess) {
          result = Process.runSync('xdg-open', [filePathLinux.toString()])
              .exitCode;
        } else {
          result = linux.system(
              ['$linuxDesktopName-open', filePathLinux.toString()]);
        }
      } else if (Platform.isWindows) {
        windowsResult = windows.shellExecute('open', filePath!);
        result = windowsResult <= 32 ? 1 : 0;
      } else {
        result = -1;
      }
      return OpenResult(
          type: result == 0 ? ResultType.done : ResultType.error,
          message: result == 0
              ? "done"
              : result == -1
                  ? "This operating system is not currently supported"
                  : "there are some errors when open $filePath${Platform.isWindows ? "   HINSTANCE=$windowsResult" : ""}");
    }

    Map<String, String?> map = {
      "file_path": filePath!,
      "type": type,
      "uti": uti,
    };
    final result1 = await _channel.invokeMethod('open_file_safe', map);
    final resultMap = json.decode(result1) as Map<String, dynamic>;
    return OpenResult.fromJson(resultMap);
  }
}
