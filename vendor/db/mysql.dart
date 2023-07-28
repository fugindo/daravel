import 'package:mysql1/mysql1.dart';

import 'db_connect.dart';

class DB {
  static String? _table;
  static final List<List<dynamic>> _conditions = [];
  static String? _orderByField;
  static String? _orderByDirection;
  static int? _limit;

  static DB table(String tableName) {
    _table = tableName;
    return DB();
  }

  DB where(String field, String operator, dynamic value) {
    _conditions.add([field, operator, value]);
    return this;
  }

  DB orderBy(String field, String direction) {
    _orderByField = field;
    _orderByDirection = direction;
    return this;
  }

  DB limit(int value) {
    _limit = value;
    return this;
  }

  Future<List<ResultRow>> get() async {
    final conn = await DbConnector().connect();

    if (_table == null) {
      throw Exception('Table name must not be null.');
    }

    var query = 'SELECT * FROM $_table';
    List<dynamic> values = [];

    if (_conditions.isNotEmpty) {
      query += ' WHERE ';

      for (var i = 0; i < _conditions.length; i++) {
        query += '${_conditions[i][0]} ${_conditions[i][1]} ?';
        values.add(_conditions[i][2]);

        if (i != _conditions.length - 1) {
          query += ' AND ';
        }
      }
    }

    if (_orderByField != null && _orderByDirection != null) {
      query += ' ORDER BY $_orderByField $_orderByDirection';
    }

    if (_limit != null) {
      query += ' LIMIT $_limit';
    }

    var results = await conn.query(query, values);

    await conn.close();

    // Reset the state
    _conditions.clear();
    _orderByField = null;
    _orderByDirection = null;
    _limit = null;

    return results.toList();
  }

  Future<int?> insert(Map<String, dynamic> data) async {
    final conn = await DbConnector().connect();

    if (_table == null) {
      throw Exception('Table name must not be null.');
    }

    String query =
        'INSERT INTO $_table (${data.keys.join(', ')}) VALUES (${List.filled(data.values.length, '?').join(', ')})';
    var result = await conn.query(query, data.values.toList());

    await conn.close();
    _conditions.clear();

    return result.insertId;
  }

  Future<void> update(Map<String, dynamic> data) async {
    final conn = await DbConnector().connect();

    if (_table == null || _conditions.isEmpty) {
      throw Exception('Table name and conditions must not be null.');
    }

    String query =
        'UPDATE $_table SET ${data.entries.map((e) => '${e.key} = ?').join(', ')} WHERE ${_conditions[0][0]} ${_conditions[0][1]} ?';
    await conn.query(query, [...data.values.toList(), _conditions[0][2]]);

    await conn.close();
    _conditions.clear();
  }

  Future<void> delete() async {
    final conn = await DbConnector().connect();

    if (_table == null || _conditions.isEmpty) {
      throw Exception('Table name and conditions must not be null.');
    }

    String query =
        'DELETE FROM $_table WHERE ${_conditions[0][0]} ${_conditions[0][1]} ?';
    await conn.query(query, [_conditions[0][2]]);

    await conn.close();
    _conditions.clear();
  }
}

void main() async {
  List<ResultRow> users = await DB
      .table('users')
      .where('age', '>=', 22)
      .orderBy("id", "desc")
      .limit(1)
      .get();

  var lastInsertId = await DB.table('users').insert({
    "name": "Alex",
    "email": "alex@gmail.com",
    "age": 23,
  });

  await DB.table('users').where("id", "=", lastInsertId).update({
    "name": "Budi",
    "email": "alex@gmail.com",
    "age": 23,
  });

  await DB.table('users').where("id", "=", lastInsertId).delete();

  print(users);
  print(users.length);
}
