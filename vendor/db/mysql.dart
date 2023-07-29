import 'package:mysql1/mysql1.dart';

import 'db_connect.dart';

class DB {
  static String? _table;
  static final List<List<dynamic>> _conditions = [];
  static String? _orderByField;
  static String? _orderByDirection;
  static int? _limit;
  static String? _groupByField;
  static String? _groupByRaw;

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

    if (_groupByField != null) {
      query += ' GROUP BY $_groupByField';
    }

    if (_groupByRaw != null) {
      query += ' GROUP BY $_groupByRaw';
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
    _groupByField = null;
    _groupByRaw = null;
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

  DB groupBy(String field) {
    _groupByField = field;
    return this;
  }

  DB groupByRaw(String rawQuery) {
    _groupByRaw = rawQuery;
    return this;
  }

  static Future<List<ResultRow>> query(String rawQuery) async {
    final conn = await DbConnector().connect();
    var results = await conn.query(rawQuery);
    await conn.close();
    return results.toList();
  }

  static Future<void> migrate(Schema schema) async {
    final conn = await DbConnector().connect();
    await conn.query(schema.build());
    await conn.close();
  }
}

class Schema {
  final String _table;
  List<String> _columns = [];

  Schema.create(this._table, void Function(Blueprint table) builder) {
    var table = Blueprint();
    builder(table);
    _columns = table.columns;
  }

  String build() {
    return 'CREATE TABLE $_table (${_columns.join(', ')});';
  }
}

class Blueprint {
  List<String> columns = [];

  void id() {
    columns.add('id INT PRIMARY KEY AUTO_INCREMENT');
  }

  void string(String name) {
    columns.add('$name VARCHAR(255)');
  }

  void timestamps() {
    columns.add('created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP');
    columns.add(
        'updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP');
  }
}

void main() async {
  List<ResultRow> users = await DB
      .table('users')
      .where('age', '>=', 22)
      // .groupBy('id')
      .groupByRaw('name, id')
      .orderBy("id", "desc")
      .limit(1)
      .get();
  for (var user in users) {
    print(user["name"]);
  }

  List<ResultRow> users2 = await DB.query("select * from users LIMIT 1");
  print(users2);

  // var lastInsertId = await DB.table('users').insert({
  //   "name": "Alex",
  //   "email": "alex@gmail.com",
  //   "age": 23,
  // });

  // await DB.table('users').where("id", "=", lastInsertId).update({
  //   "name": "Budi",
  //   "email": "alex@gmail.com",
  //   "age": 23,
  // });

  // await DB.table('users').where("id", "=", lastInsertId).delete();

  // // await DB.migrate(Schema.create('flights', (table) {
  // //   table.id();
  // //   table.string('name');
  // //   table.string('airline');
  // //   table.timestamps();
  // // }));
}
