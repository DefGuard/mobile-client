import 'package:mobile/data/db/db_file.dart';

Future<void> deleteDbForDev() async {
  final dbFile = await databaseFile();
  if (await dbFile.exists()) {
    await dbFile.delete();
    print("Local DB Deleted");
  }
}
