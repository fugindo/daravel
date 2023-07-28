import 'package:mysql1/mysql1.dart';

class DbConnector {
  Future<MySqlConnection> connect() async {
    final conn = await MySqlConnection.connect(ConnectionSettings(
      host: 'localhost',
      port: 3306,
      user: 'rootd',
      password: 'rootd',
      db: 'daravel_db',
    ));
    return conn;
  }
}
