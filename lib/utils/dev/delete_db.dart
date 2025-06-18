import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

Future<void> deleteDbForDev() async {
  final directory = await getApplicationSupportDirectory();
  final dbPath = path.join(directory.path, 'defguard.sqlite');
  final dbFile = File(dbPath);
  if(await dbFile.exists()) {
    await dbFile.delete();
    print("Local DB Deleted");
  }
}