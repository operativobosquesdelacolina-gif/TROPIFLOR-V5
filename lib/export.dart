import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'db.dart';

/// Evita comas en cadenas exportadas para mantener consistencia con punto decimal.
String _cleanText(Object? v) => '${v ?? ''}'.replaceAll(',', '.');

CellValue _c(Object? v) {
  if (v == null) return TextCellValue('');
  if (v is int) return IntCellValue(v);
  if (v is num) {
    final rounded = double.parse(v.toDouble().toStringAsFixed(2));
    return DoubleCellValue(rounded);
  }
  return TextCellValue(_cleanText(v));
}

Future<void> exportExcel() async {
  final ex = Excel.createExcel();
  ex.rename('Sheet1', 'RESUMEN');

  Future<void> sheet(String name, List<String> head, String sql) async {
    final s = ex[name];
    s.appendRow(head.map<CellValue>((h) => TextCellValue(_cleanText(h))).toList());
    for (final r in await q(sql)) {
      s.appendRow(r.values.map(_c).toList());
    }
  }

  await sheet(
    'RESUMEN',
    ['Fecha informe', 'Recepciones', 'Kg recibidos', 'Kg mermas', 'Kg producidos', 'Pacas', 'Bolsas conos'],
    "SELECT '${today()}',(SELECT COUNT(*) FROM receptions),(SELECT COALESCE(ROUND(SUM(kg),2),0) FROM receptions),(SELECT COALESCE(ROUND(SUM(kg),2),0) FROM wastes),(SELECT COALESCE(ROUND(SUM(kg),2),0) FROM compactions),(SELECT COALESCE(SUM(bales),0) FROM compactions WHERE kind='paca'),(SELECT COALESCE(SUM(bales),0) FROM compactions WHERE kind='conos')",
  );

  await sheet(
    'RECEPCIONES',
    ['Fecha recepción', 'Hora llegada', 'Código', 'Título', 'Boleta/ID', 'Empresa', 'Materiales', 'Bolsas', 'Kg recibidos', 'Kg mermas', 'Kg neto', 'Kg producido', 'Saldo kg', 'Estado'],
    "SELECT SUBSTR(r.arrived,1,10),SUBSTR(r.arrived,12,5),r.code,CASE WHEN r.no_boleta=1 THEN 'Sin boleta' ELSE r.boleta END||' - '||r.supplier,r.boleta,r.supplier,REPLACE(COALESCE(r.material,''),',','.'),r.bags,ROUND(r.kg,2),ROUND(COALESCE(a.w,0),2),ROUND(r.kg-COALESCE(a.w,0),2),ROUND(COALESCE(b.c,0),2),ROUND(r.kg-COALESCE(a.w,0)-COALESCE(b.c,0),2),r.status FROM receptions r LEFT JOIN (SELECT reception_id,SUM(kg) w FROM wastes GROUP BY reception_id) a ON a.reception_id=r.id LEFT JOIN (SELECT reception_id,SUM(kg) c FROM compactions GROUP BY reception_id) b ON b.reception_id=r.id ORDER BY r.arrived",
  );

  await sheet(
    'ITEMS RECEPCION',
    ['Fecha recepción', 'Recepción', 'Empresa', 'Material', 'Kg'],
    'SELECT SUBSTR(r.arrived,1,10),r.code,r.supplier,i.material,ROUND(i.kg,2) FROM reception_items i JOIN receptions r ON r.id=i.reception_id ORDER BY r.arrived',
  );

  await sheet(
    'MERMAS',
    ['Fecha recepción', 'Fecha clasificación', 'Recepción', 'Empresa', 'Tipo', 'Detalle', 'Kg'],
    "SELECT SUBSTR(r.arrived,1,10),COALESCE((SELECT SUBSTR(c.finished,1,10) FROM classifications c WHERE c.reception_id=r.id LIMIT 1),'Pendiente'),r.code,r.supplier,w.type,REPLACE(COALESCE(w.notes,''),',','.'),ROUND(w.kg,2) FROM wastes w JOIN receptions r ON r.id=w.reception_id ORDER BY (w.type='Valorizable') DESC, r.arrived",
  );

  await sheet(
    'CLASIFICACIONES',
    ['Fecha recepción', 'Fecha inicio clasif.', 'Hora inicio', 'Fecha fin clasif.', 'Hora fin', 'Recepción', 'Empresa', 'Operario', 'Observaciones'],
    "SELECT SUBSTR(r.arrived,1,10),SUBSTR(c.started,1,10),SUBSTR(c.started,12,5),SUBSTR(c.finished,1,10),SUBSTR(c.finished,12,5),r.code,r.supplier,c.operator,REPLACE(COALESCE(c.notes,''),',','.') FROM classifications c JOIN receptions r ON r.id=c.reception_id ORDER BY r.arrived",
  );

  await sheet(
    'PRODUCCION',
    ['Fecha producción', 'Fecha recepción', 'Código', 'Tipo', 'Material', 'Recepción', 'Empresa', 'Trabajador', 'Hora inicio', 'Hora fin', 'Minutos', 'Pacas/Bolsas', 'Kg', 'Min por paca'],
    "SELECT SUBSTR(c.start,1,10),COALESCE(SUBSTR(r.arrived,1,10),'Sin recepción'),c.code,CASE WHEN c.kind='conos' THEN 'Corte y trituración de conos' ELSE 'Paca' END,c.material,COALESCE(r.code,'—'),COALESCE(r.supplier,'—'),c.operator,SUBSTR(c.start,12,5),SUBSTR(c.finish,12,5),ROUND(c.minutes,1),c.bales,ROUND(c.kg,2),CASE WHEN c.kind='paca' AND c.bales>0 THEN ROUND(c.minutes*1.0/c.bales,1) ELSE NULL END FROM compactions c LEFT JOIN receptions r ON r.id=c.reception_id ORDER BY c.start",
  );

  await sheet(
    'ASISTENCIAS',
    ['Fecha asistencia', 'Trabajador', 'Cargo', 'Estado', 'Hora ingreso', 'Horas extras', 'Boleta HE firmada'],
    "SELECT a.date,w.name,w.role,a.status,COALESCE(SUBSTR(a.time_in,12,5),'--'),ROUND(a.overtime,2),CASE WHEN a.overtime>0 THEN (CASE WHEN a.ot_signed=1 THEN 'Sí' ELSE 'No' END) ELSE '' END FROM attendance a JOIN workers w ON w.id=a.worker_id ORDER BY a.date",
  );

  await sheet(
    'PENDIENTES',
    ['Fecha creación', 'Fecha límite', 'Pendiente', 'Detalle', 'Estado'],
    "SELECT SUBSTR(created,1,10),COALESCE(due_date,'Sin fecha límite'),title,REPLACE(COALESCE(notes,''),',','.'),CASE WHEN done=1 THEN 'Completado' ELSE 'Pendiente' END FROM pending ORDER BY done, CASE WHEN due_date IS NULL OR due_date='' THEN 1 ELSE 0 END, due_date, id DESC",
  );

  await sheet(
    'PLANO LEYENDA',
    ['Color ID', 'Tipo', 'Empresa / Zona', 'Material / Nota', 'Cuadros asignados'],
    "SELECT l.color_idx, CASE WHEN l.color_idx=0 THEN 'Estructura' ELSE 'Carga' END, l.label, REPLACE(COALESCE(l.notes,''),',','.'), (SELECT COUNT(*) FROM floor_cells fc WHERE fc.color_idx=l.color_idx) FROM floor_legend l ORDER BY l.color_idx",
  );

  await sheet(
    'PLANO CELDAS',
    ['Fila', 'Columna', 'Color ID', 'Empresa / Zona'],
    'SELECT fc.r+1, fc.c+1, fc.color_idx, COALESCE(l.label,'') FROM floor_cells fc LEFT JOIN floor_legend l ON l.color_idx=fc.color_idx ORDER BY fc.r, fc.c',
  );

  final bytes = ex.save();
  final dir = await getTemporaryDirectory();
  final f = File('${dir.path}/TROPIFLOR_informe_${today()}.xlsx')..writeAsBytesSync(bytes!);
  await Share.shareXFiles([XFile(f.path)]);
}

String _cellStr(List<Data?> row, int idx) {
  if (idx < 0 || idx >= row.length) return '';
  final v = row[idx]?.value;
  if (v == null) return '';
  return v.toString().trim();
}

double _cellNum(List<Data?> row, int idx) {
  if (idx < 0 || idx >= row.length) return 0;
  final v = row[idx]?.value;
  if (v == null) return 0;
  if (v is IntCellValue) return v.value.toDouble();
  if (v is DoubleCellValue) return v.value;
  return d(v.toString());
}

String _normTime(String raw, [String fallback = '08:00']) {
  final s = raw.trim();
  if (s.length >= 5 && s.contains(':')) {
    final p = s.split(':');
    final h = int.tryParse(p[0].replaceAll(RegExp(r'[^0-9]'), '')) ?? 8;
    final m = int.tryParse(p[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return '${h.clamp(0, 23).toString().padLeft(2, '0')}:${m.clamp(0, 59).toString().padLeft(2, '0')}';
  }
  return fallback;
}

String _normDate(String raw, [String? fallback]) {
  final s = raw.trim();
  if (s.length >= 10 && RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s)) {
    return s.substring(0, 10);
  }
  return fallback ?? today();
}

/// Importa los datos de un Excel generado por TROPIFLOR para sincronizar otro dispositivo sin duplicar registros existentes.
Future<void> importExcel(BuildContext c) async {
  final res = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['xlsx'],
    withData: true,
  );
  if (res == null || res.files.isEmpty) return;

  final file = res.files.first;
  final bytes = file.bytes ?? (file.path != null ? await File(file.path!).readAsBytes() : null);
  if (bytes == null) {
    if (c.mounted) {
      ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('No se pudo leer el archivo Excel seleccionado')));
    }
    return;
  }

  final ex = Excel.decodeBytes(bytes);
  final database = await db;

  int addedRec = 0, addedItems = 0, addedWastes = 0, addedClass = 0, addedProd = 0, addedWorkers = 0, addedAtt = 0, addedPend = 0, importedCells = 0;

  // Mapa de código de recepción (ej. REC-0001) -> ID local en la BD actual
  final recCodeToId = <String, int>{};
  for (final r in await database.query('receptions', columns: ['id', 'code'])) {
    final code = '${r['code'] ?? ''}';
    if (code.isNotEmpty) recCodeToId[code] = r['id'] as int;
  }

  // 1. RECEPCIONES
  final recSheet = ex.tables['RECEPCIONES'];
  final importedRecCodes = <String>{};
  if (recSheet != null && recSheet.rows.length > 1) {
    for (var i = 1; i < recSheet.rows.length; i++) {
      final row = recSheet.rows[i];
      final date = _normDate(_cellStr(row, 0));
      final hour = _normTime(_cellStr(row, 1), '08:00');
      final code = _cellStr(row, 2);
      final boleta = _cellStr(row, 4);
      final supplier = _cellStr(row, 5);
      final material = _cellStr(row, 6);
      final bags = _cellNum(row, 7).toInt();
      final kg = _cellNum(row, 8);
      final statusRaw = _cellStr(row, 13).toLowerCase();
      final status = statusRaw.contains('comp') ? 'completada' : 'pendiente';

      if (supplier.isEmpty && code.isEmpty) continue;
      if (code.isNotEmpty && recCodeToId.containsKey(code)) continue;

      final noBoleta = boleta.startsWith('SB-') || boleta.isEmpty ? 1 : 0;
      if (noBoleta == 0 && boleta.isNotEmpty) {
        final byBol = await database.query('receptions', where: 'boleta=?', whereArgs: [boleta]);
        if (byBol.isNotEmpty) {
          if (code.isNotEmpty) recCodeToId[code] = byBol.first['id'] as int;
          continue;
        }
      }

      final newId = await database.insert('receptions', {
        'code': code,
        'boleta': boleta.isEmpty ? 'SB-${DateTime.now().millisecondsSinceEpoch % 10000}' : boleta,
        'no_boleta': noBoleta,
        'supplier': supplier,
        'material': material,
        'bags': bags,
        'kg': kg,
        'arrived': '${date}T$hour:00',
        'notes': '',
        'status': status,
      });
      final finalCode = code.isEmpty ? 'REC-${newId.toString().padLeft(4, '0')}' : code;
      if (code.isEmpty) {
        await database.update('receptions', {'code': finalCode}, where: 'id=?', whereArgs: [newId]);
      }
      recCodeToId[finalCode] = newId;
      importedRecCodes.add(finalCode);
      addedRec++;
    }
  }

  // 2. ITEMS RECEPCION
  final itemSheet = ex.tables['ITEMS RECEPCION'];
  if (itemSheet != null && itemSheet.rows.length > 1) {
    for (var i = 1; i < itemSheet.rows.length; i++) {
      final row = itemSheet.rows[i];
      final recCode = _cellStr(row, 1);
      final mat = _cellStr(row, 3);
      final kg = _cellNum(row, 4);
      final recId = recCodeToId[recCode];
      if (recId == null || (mat.isEmpty && kg <= 0)) continue;
      if (!importedRecCodes.contains(recCode)) continue;
      await database.insert('reception_items', {
        'reception_id': recId,
        'material': mat,
        'kg': kg,
      });
      addedItems++;
    }
  }

  // 3. MERMAS
  final wasteSheet = ex.tables['MERMAS'];
  if (wasteSheet != null && wasteSheet.rows.length > 1) {
    for (var i = 1; i < wasteSheet.rows.length; i++) {
      final row = wasteSheet.rows[i];
      final recCode = _cellStr(row, 2);
      final type = _cellStr(row, 4);
      final notes = _cellStr(row, 5);
      final kg = _cellNum(row, 6);
      final recId = recCodeToId[recCode];
      if (recId == null || type.isEmpty) continue;
      final dup = await database.query(
        'wastes',
        where: 'reception_id=? AND type=? AND ABS(kg - ?) < 0.01 AND COALESCE(notes,'')=?',
        whereArgs: [recId, type, kg, notes],
      );
      if (dup.isNotEmpty) continue;
      await database.insert('wastes', {
        'reception_id': recId,
        'type': type,
        'kg': kg,
        'notes': notes,
      });
      addedWastes++;
    }
  }

  // 4. CLASIFICACIONES
  final classSheet = ex.tables['CLASIFICACIONES'];
  if (classSheet != null && classSheet.rows.length > 1) {
    for (var i = 1; i < classSheet.rows.length; i++) {
      final row = classSheet.rows[i];
      final startD = _normDate(_cellStr(row, 1));
      final startH = _normTime(_cellStr(row, 2), '08:00');
      final endD = _normDate(_cellStr(row, 3), startD);
      final endH = _normTime(_cellStr(row, 4), startH);
      final recCode = _cellStr(row, 5);
      final operatorName = _cellStr(row, 7);
      final notes = _cellStr(row, 8);
      final recId = recCodeToId[recCode];
      if (recId == null) continue;
      final dup = await database.query('classifications', where: 'reception_id=?', whereArgs: [recId]);
      if (dup.isNotEmpty) continue;
      await database.insert('classifications', {
        'reception_id': recId,
        'started': '${startD}T$startH:00',
        'finished': '${endD}T$endH:00',
        'operator': operatorName,
        'notes': notes,
      });
      await database.update('receptions', {'status': 'completada'}, where: 'id=?', whereArgs: [recId]);
      addedClass++;
    }
  }

  // 5. PRODUCCION
  final prodSheet = ex.tables['PRODUCCION'];
  if (prodSheet != null && prodSheet.rows.length > 1) {
    for (var i = 1; i < prodSheet.rows.length; i++) {
      final row = prodSheet.rows[i];
      final prodDate = _normDate(_cellStr(row, 0));
      final code = _cellStr(row, 2);
      final tipoStr = _cellStr(row, 3).toLowerCase();
      final kind = tipoStr.contains('cono') ? 'conos' : 'paca';
      final material = _cellStr(row, 4);
      final recCode = _cellStr(row, 5);
      final worker = _cellStr(row, 7);
      final startH = _normTime(_cellStr(row, 8), '08:00');
      final endH = _normTime(_cellStr(row, 9), startH);
      final mins = _cellNum(row, 10);
      final bales = _cellNum(row, 11).toInt();
      final kg = _cellNum(row, 12);

      if (worker.isEmpty && code.isEmpty) continue;
      if (code.isNotEmpty) {
        final dupCode = await database.query('compactions', where: 'code=?', whereArgs: [code]);
        if (dupCode.isNotEmpty) continue;
      }

      final startIso = '${prodDate}T$startH:00';
      var endDt = at(prodDate, endH);
      final startDt = at(prodDate, startH);
      if (endDt.isBefore(startDt)) endDt = endDt.add(const Duration(days: 1));
      final finishIso = endDt.toIso8601String();

      final dupSame = await database.query(
        'compactions',
        where: 'operator=? AND start=? AND ABS(kg - ?) < 0.01',
        whereArgs: [worker, startIso, kg],
      );
      if (dupSame.isNotEmpty) continue;

      final recId = recCodeToId[recCode];
      final newId = await database.insert('compactions', {
        'code': code,
        'reception_id': recId,
        'operator': worker,
        'start': startIso,
        'finish': finishIso,
        'minutes': mins > 0 ? mins : endDt.difference(startDt).inMinutes.toDouble(),
        'kg': kg,
        'bales': bales,
        'notes': '',
        'kind': kind,
        'material': material,
      });
      if (code.isEmpty) {
        await database.update(
          'compactions',
          {'code': '${kind == 'paca' ? 'PAC' : 'CON'}-${newId.toString().padLeft(4, '0')}'},
          where: 'id=?',
          whereArgs: [newId],
        );
      }
      addedProd++;
    }
  }

  // 6. ASISTENCIAS (y trabajadores faltantes)
  final attSheet = ex.tables['ASISTENCIAS'];
  if (attSheet != null && attSheet.rows.length > 1) {
    final workerMap = <String, int>{};
    for (final w in await database.query('workers')) {
      workerMap['${w['name']}'.trim().toLowerCase()] = w['id'] as int;
    }

    for (var i = 1; i < attSheet.rows.length; i++) {
      final row = attSheet.rows[i];
      final date = _normDate(_cellStr(row, 0));
      final wName = _cellStr(row, 1);
      final role = _cellStr(row, 2);
      final status = _cellStr(row, 3);
      final timeInRaw = _cellStr(row, 4);
      final ot = _cellNum(row, 5);
      final signedStr = _cellStr(row, 6).toLowerCase();

      if (wName.isEmpty) continue;
      final key = wName.toLowerCase();
      int? wid = workerMap[key];
      if (wid == null) {
        wid = await database.insert('workers', {'name': wName, 'role': role, 'active': 1});
        workerMap[key] = wid;
        addedWorkers++;
      }

      final dupAtt = await database.query('attendance', where: 'worker_id=? AND date=?', whereArgs: [wid, date]);
      if (dupAtt.isNotEmpty) continue;

      final timeIn = (timeInRaw.isNotEmpty && timeInRaw != '--') ? '${date}T${_normTime(timeInRaw)}:00' : null;
      await database.insert('attendance', {
        'worker_id': wid,
        'date': date,
        'status': status.isEmpty ? 'Presente' : status,
        'time_in': timeIn,
        'overtime': ot,
        'ot_signed': (signedStr == 'sí' || signedStr == 'si' || signedStr == '1') ? 1 : 0,
      });
      addedAtt++;
    }
  }

  // 7. PENDIENTES
  final pendSheet = ex.tables['PENDIENTES'];
  if (pendSheet != null && pendSheet.rows.length > 1) {
    for (var i = 1; i < pendSheet.rows.length; i++) {
      final row = pendSheet.rows[i];
      final createdD = _normDate(_cellStr(row, 0));
      final dueRaw = _cellStr(row, 1);
      final dueDate = (dueRaw.isEmpty || dueRaw.toLowerCase().contains('sin')) ? null : _normDate(dueRaw);
      final title = _cellStr(row, 2);
      final notes = _cellStr(row, 3);
      final done = _cellStr(row, 4).toLowerCase().contains('comp') ? 1 : 0;

      if (title.isEmpty) continue;
      final dup = await database.query('pending', where: 'title=? AND COALESCE(notes,'')=?', whereArgs: [title, notes]);
      if (dup.isNotEmpty) continue;

      await database.insert('pending', {
        'title': title,
        'notes': notes,
        'done': done,
        'created': '${createdD}T08:00:00',
        'due_date': dueDate,
      });
      addedPend++;
    }
  }

  // 8. PLANO LEYENDA y PLANO CELDAS
  final legendSheet = ex.tables['PLANO LEYENDA'];
  if (legendSheet != null && legendSheet.rows.length > 1) {
    for (var i = 1; i < legendSheet.rows.length; i++) {
      final row = legendSheet.rows[i];
      final colorIdx = _cellNum(row, 0).toInt();
      final label = _cellStr(row, 2);
      final notes = _cellStr(row, 3);
      if (colorIdx < 0 || colorIdx > 10 || label.isEmpty) continue;
      await database.insert(
        'floor_legend',
        {'color_idx': colorIdx, 'label': label, 'notes': notes},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  final cellsSheet = ex.tables['PLANO CELDAS'];
  if (cellsSheet != null && cellsSheet.rows.length > 1) {
    for (var i = 1; i < cellsSheet.rows.length; i++) {
      final row = cellsSheet.rows[i];
      final rIdx = _cellNum(row, 0).toInt() - 1;
      final cIdx = _cellNum(row, 1).toInt() - 1;
      final colorIdx = _cellNum(row, 2).toInt();
      if (rIdx < 0 || rIdx >= 30 || cIdx < 0 || cIdx >= 20 || colorIdx < 0 || colorIdx > 10) continue;
      await database.insert(
        'floor_cells',
        {'r': rIdx, 'c': cIdx, 'color_idx': colorIdx},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      importedCells++;
    }
  }

  tick.value++;

  if (c.mounted) {
    final total = addedRec + addedWastes + addedClass + addedProd + addedWorkers + addedAtt + addedPend + importedCells;
    showDialog(
      context: c,
      builder: (ctx) => AlertDialog(
        title: const Text('Importación completada', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          total == 0
              ? 'Todos los registros del archivo Excel ya existían en este dispositivo.'
              : 'Se agregaron los siguientes registros nuevos:\n\n'
                  '• Recepciones: $addedRec (ítems: $addedItems)\n'
                  '• Mermas: $addedWastes\n'
                  '• Clasificaciones: $addedClass\n'
                  '• Producción: $addedProd\n'
                  '• Trabajadores nuevos: $addedWorkers\n'
                  '• Asistencias: $addedAtt\n'
                  '• Pendientes: $addedPend\n'
                  '• Cuadros del plano: $importedCells',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Listo')),
        ],
      ),
    );
  }
}
