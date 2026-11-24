import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

typedef R = Map<String, Object?>;
final tick = ValueNotifier<int>(0);
Database? _db;

Future<void> _seedFloorPlan(Database d) async {
  // Índice 0 reservado exclusivamente para negro = paredes y áreas segmentadas
  const defaults = <int, String>{
    0: 'Paredes / Áreas segmentadas',
    1: 'Empresa 1',
    2: 'Empresa 2',
    3: 'Empresa 3',
    4: 'Empresa 4',
    5: 'Empresa 5',
    6: 'Empresa 6',
    7: 'Empresa 7',
    8: 'Empresa 8',
    9: 'Empresa 9',
    10: 'Empresa 10',
  };
  for (final e in defaults.entries) {
    await d.insert(
      'floor_legend',
      {'color_idx': e.key, 'label': e.value, 'notes': ''},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
}

Future<void> _create(Database d) async {
  await d.execute('CREATE TABLE workers(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT,role TEXT,active INTEGER DEFAULT 1)');
  await d.execute('CREATE TABLE attendance(id INTEGER PRIMARY KEY AUTOINCREMENT,worker_id INTEGER,date TEXT,status TEXT,time_in TEXT,time_out TEXT,overtime REAL DEFAULT 0,ot_signed INTEGER DEFAULT 0,UNIQUE(worker_id,date))');
  await d.execute('CREATE TABLE receptions(id INTEGER PRIMARY KEY AUTOINCREMENT,code TEXT,boleta TEXT,supplier TEXT,material TEXT,bags INTEGER,kg REAL,arrived TEXT,notes TEXT,status TEXT,no_boleta INTEGER DEFAULT 0)');
  await d.execute('CREATE TABLE reception_items(id INTEGER PRIMARY KEY AUTOINCREMENT,reception_id INTEGER,material TEXT,kg REAL)');
  await d.execute('CREATE TABLE classifications(id INTEGER PRIMARY KEY AUTOINCREMENT,reception_id INTEGER,started TEXT,finished TEXT,operator TEXT,notes TEXT)');
  await d.execute('CREATE TABLE wastes(id INTEGER PRIMARY KEY AUTOINCREMENT,reception_id INTEGER,type TEXT,kg REAL,notes TEXT)');
  await d.execute("CREATE TABLE compactions(id INTEGER PRIMARY KEY AUTOINCREMENT,code TEXT,reception_id INTEGER,operator TEXT,start TEXT,finish TEXT,minutes REAL,kg REAL,bales INTEGER,notes TEXT,kind TEXT DEFAULT 'paca',material TEXT)");
  await d.execute('CREATE TABLE pending(id INTEGER PRIMARY KEY AUTOINCREMENT,title TEXT,notes TEXT,done INTEGER DEFAULT 0,created TEXT,due_date TEXT)');
  await d.execute('CREATE TABLE floor_legend(color_idx INTEGER PRIMARY KEY,label TEXT,notes TEXT)');
  await d.execute('CREATE TABLE floor_cells(r INTEGER,c INTEGER,color_idx INTEGER,PRIMARY KEY(r,c))');
  await _seedFloorPlan(d);
}

Future<Database> get db async => _db ??= await openDatabase(
      join(await getDatabasesPath(), 'tropiflor.db'),
      version: 4,
      onCreate: (d, v) => _create(d),
      onUpgrade: (d, o, v) async {
        if (o < 2) {
          await d.execute('ALTER TABLE receptions ADD COLUMN no_boleta INTEGER DEFAULT 0');
          await d.execute('CREATE TABLE reception_items(id INTEGER PRIMARY KEY AUTOINCREMENT,reception_id INTEGER,material TEXT,kg REAL)');
          await d.execute('INSERT INTO reception_items(reception_id,material,kg) SELECT id,material,kg FROM receptions');
          await d.execute('ALTER TABLE compactions ADD COLUMN finish TEXT');
          await d.execute("ALTER TABLE compactions ADD COLUMN kind TEXT DEFAULT 'paca'");
          await d.execute('ALTER TABLE compactions ADD COLUMN material TEXT');
          await d.execute("UPDATE compactions SET kind='paca', material=(SELECT material FROM receptions r WHERE r.id=compactions.reception_id), finish=strftime('%Y-%m-%dT%H:%M:%S',start,'+'||CAST(COALESCE(minutes,0) AS INTEGER)||' minutes')");
          await d.execute('ALTER TABLE attendance ADD COLUMN overtime REAL DEFAULT 0');
          await d.execute('ALTER TABLE attendance ADD COLUMN ot_signed INTEGER DEFAULT 0');
          await d.execute('CREATE TABLE pending(id INTEGER PRIMARY KEY AUTOINCREMENT,title TEXT,notes TEXT,done INTEGER DEFAULT 0,created TEXT,due_date TEXT)');
        }
        if (o < 3) {
          final cols = await d.rawQuery('PRAGMA table_info(pending)');
          final hasDue = cols.any((c) => c['name'] == 'due_date');
          if (!hasDue) {
            await d.execute('ALTER TABLE pending ADD COLUMN due_date TEXT');
          }
        }
        if (o < 4) {
          await d.execute('CREATE TABLE IF NOT EXISTS floor_legend(color_idx INTEGER PRIMARY KEY,label TEXT,notes TEXT)');
          await d.execute('CREATE TABLE IF NOT EXISTS floor_cells(r INTEGER,c INTEGER,color_idx INTEGER,PRIMARY KEY(r,c))');
          await _seedFloorPlan(d);
        }
      },
    );

Future<int> ins(String t, R v) async {
  final id = await (await db).insert(t, v);
  tick.value++;
  return id;
}

Future<void> upd(String t, R v, String w, List<Object?> a) async {
  if (v.isNotEmpty) await (await db).update(t, v, where: w, whereArgs: a);
  tick.value++;
}

Future<void> del(String t, String w, List<Object?> a) async {
  await (await db).delete(t, where: w, whereArgs: a);
  tick.value++;
}

Future<List<R>> q(String sql, [List<Object?>? a]) async => (await db).rawQuery(sql, a);

Future<List<R>> recs() => q(
    'SELECT r.*, COALESCE((SELECT SUM(kg) FROM wastes WHERE reception_id=r.id),0) AS waste, COALESCE((SELECT SUM(kg) FROM compactions WHERE reception_id=r.id),0) AS compacted FROM receptions r ORDER BY r.arrived');

String today() => DateTime.now().toIso8601String().substring(0, 10);
String hm(Object? iso) => iso == null ? '--' : '$iso'.substring(11, 16);
String fdt(Object? iso) => '$iso'.substring(0, 16).replaceFirst('T', ' ');
String fmtT(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
String nowHM() => hm(DateTime.now().toIso8601String());
double n(Object? v) => ((v as num?) ?? 0).toDouble();
double d(String? s) => double.tryParse((s ?? '').trim().replaceAll(',', '.')) ?? 0;

/// Formatea números usando siempre punto decimal y sin comas.
String dotNum(num v, {int dec = 1}) => v.toDouble().toStringAsFixed(dec).replaceAll(',', '.');

DateTime at(String date, String h) => DateTime(
      int.parse(date.substring(0, 4)),
      int.parse(date.substring(5, 7)),
      int.parse(date.substring(8, 10)),
      int.parse(h.substring(0, 2)),
      int.parse(h.substring(3, 5)),
    );

String recName(R r) => '${r['no_boleta'] == 1 ? 'Sin boleta' : r['boleta']} - ${r['supplier']}';
String recTitle(R r) => '${r['code']} - ${r['supplier']}';

Duration remaining(R r) => DateTime.parse('${r['arrived']}').add(const Duration(hours: 72)).difference(DateTime.now());

Color prColor(R r) {
  if (r['status'] == 'completada') return const Color(0xFFE65100);
  final x = remaining(r);
  return x.isNegative ? const Color(0xFFD32F2F) : (x.inHours <= 24 ? const Color(0xFFF57C00) : const Color(0xFFFF9800));
}

String rem(R r) {
  if (r['status'] == 'completada') return 'Clasificada';
  final x = remaining(r);
  return x.isNegative ? 'VENCIDA hace ${(-x.inHours)} h' : '${x.inDays} d ${x.inHours % 24} h restantes';
}

String bal(R r) {
  final kg = n(r['kg']), w = n(r['waste']), c = n(r['compacted']), net = kg - w;
  final pct = kg > 0 ? w / kg * 100 : 0;
  return 'Recibido: ${dotNum(kg)} kg\nMermas: ${dotNum(w)} kg (${dotNum(pct)}%)\nNeto aprovechable: ${dotNum(net)} kg\nProducido: ${dotNum(c)} kg\nSaldo pendiente: ${dotNum(net - c)} kg';
}
