import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

final Logger log = Logger('MyAppLogger');

Future<void> setupLogging() async {
  Logger.root.level = Level.ALL;

  final directory = await getApplicationDocumentsDirectory();
  final logFile = File('${directory.path}/app.log');

  Logger.root.onRecord.listen((record) async {
    final logMessage =
        '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}\n';

    // Optional: also print to console
    print(logMessage);

    await logFile.writeAsString(logMessage, mode: FileMode.append);
  });
}
