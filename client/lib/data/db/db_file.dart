import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Name drift builds the database file from, see `AppDatabase._openConnection`.
const databaseName = 'defguard';

/// The file drift stores the database in.
///
/// Everything that has to reason about the database outside of drift itself
/// derives the path from here - the fresh install detection in
/// `initSecureStorage` keys off its existence, so a rename that only landed in
/// one of the copies would silently wipe the stored secrets.
Future<File> databaseFile() async {
  final directory = await getApplicationSupportDirectory();
  return File(p.join(directory.path, '$databaseName.sqlite'));
}
