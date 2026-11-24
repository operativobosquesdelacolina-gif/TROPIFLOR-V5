import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'db.dart';
import 'export.dart';

void main() => runApp(const App());

// Paleta moderna Rojo Carmesí + Naranja Vibrante + Blanco Puro
const brandRed = Color(0xFFD32F2F);
const brandRedDark = Color(0xFFB71C1C);
const brandOrange = Color(0xFFFF6D00);
const brandOrangeSoft = Color(0xFFFF9100);
const surfaceWarm = Color(0xFFFFFAF7);
const cardBorderWarm = Color(0xFFF3E5DC);

const wasteTypes = ['Valorizable', 'Papel', 'Líquidos', 'Chatarra', 'Material contaminado', 'Otros'];
const statuses = ['Presente', 'Falta', 'Atraso', 'Permiso', 'Vacaciones', 'Descanso'];
const none = '— Ninguna —';

// Colores del plano 20x30:
// 0 = Negro (exclusivo para paredes y áreas segmentadas)
// 1..10 = Colores para carga acomodada por empresa
const floorPalette = <Color>[
  Color(0xFF1A1A1A), // 0: Negro -> Paredes y áreas segmentadas
  Color(0xFFD32F2F), // 1: Rojo
  Color(0xFFFF6D00), // 2: Naranja
  Color(0xFF1976D2), // 3: Azul
  Color(0xFF2E7D32), // 4: Verde
  Color(0xFF7B1FA2), // 5: Morado
  Color(0xFF00838F), // 6: Turquesa
  Color(0xFFC2185B), // 7: Fucsia
  Color(0xFFFBC02D), // 8: Amarillo
  Color(0xFF5D4037), // 9: Café
  Color(0xFF455A64), // 10: Gris pizarra
];

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext c) {
    final scheme = ColorScheme.fromSeed(
      seedColor: brandRed,
      primary: brandRed,
      secondary: brandOrange,
      surface: surfaceWarm,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    );
    return MaterialApp(
      title: 'TROPIFLOR Production Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: surfaceWarm,
        appBarTheme: const AppBarTheme(
          backgroundColor: brandRed,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: cardBorderWarm, width: 1.2),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: cardBorderWarm, width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: cardBorderWarm, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: brandOrange, width: 2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: brandRed,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        ),
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HS();
}

class _HS extends State<Home> {
  int i = 6;
  Timer? t;
  @override
  void initState() {
    super.initState();
    t = Timer.periodic(const Duration(minutes: 1), (_) => tick.value++);
  }

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    final pages = <Widget>[
      const AttPage(),
      const RecPage(),
      const ClassPage(),
      const ProdPage(),
      const PendPage(),
      const FloorPlanPage(),
      const DashPage(),
    ];
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(66),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [brandRedDark, brandRed, brandOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: Color(0x33D32F2F), blurRadius: 12, offset: Offset(0, 4)),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 8),
                const Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('TROPIFLOR', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 0.6, color: Colors.white)),
                      Text('Control de Producción', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Subir Excel de otro dispositivo',
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 20),
                ),
                onPressed: () => importExcel(c),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: brandRed,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                  ),
                  icon: const Icon(Icons.table_view_rounded, size: 17),
                  label: const Text('Excel', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  onPressed: () => exportExcel(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: tick,
        builder: (_, v, __) => KeyedSubtree(key: ValueKey('$i-$v'), child: pages[i]),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: cardBorderWarm, width: 1.2)),
          boxShadow: [
            BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, -2)),
          ],
        ),
        child: NavigationBar(
          selectedIndex: i,
          height: 68,
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: brandOrange.withOpacity(0.15),
          onDestinationSelected: (v) => setState(() => i = v),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.badge_outlined, size: 21), selectedIcon: Icon(Icons.badge_rounded, color: brandRed, size: 22), label: 'Asist.'),
            NavigationDestination(icon: Icon(Icons.local_shipping_outlined, size: 21), selectedIcon: Icon(Icons.local_shipping_rounded, color: brandRed, size: 22), label: 'Recep.'),
            NavigationDestination(icon: Icon(Icons.fact_check_outlined, size: 21), selectedIcon: Icon(Icons.fact_check_rounded, color: brandRed, size: 22), label: 'Clasif.'),
            NavigationDestination(icon: Icon(Icons.precision_manufacturing_outlined, size: 21), selectedIcon: Icon(Icons.precision_manufacturing_rounded, color: brandRed, size: 22), label: 'Prod.'),
            NavigationDestination(icon: Icon(Icons.checklist_outlined, size: 21), selectedIcon: Icon(Icons.checklist_rounded, color: brandRed, size: 22), label: 'Pend.'),
            NavigationDestination(icon: Icon(Icons.grid_on_outlined, size: 21), selectedIcon: Icon(Icons.grid_on_rounded, color: brandRed, size: 22), label: 'Plano'),
            NavigationDestination(icon: Icon(Icons.dashboard_outlined, size: 21), selectedIcon: Icon(Icons.dashboard_rounded, color: brandRed, size: 22), label: 'Resumen'),
          ],
        ),
      ),
    );
  }
}

Widget fut(Future<List<R>> f, Widget Function(List<R>) b) => FutureBuilder<List<R>>(
      future: f,
      builder: (c, s) => s.hasData ? b(s.data!) : const Center(child: CircularProgressIndicator(color: brandOrange)),
    );

Widget futs(List<Future<List<R>>> f, Widget Function(List<List<R>>) b) => FutureBuilder<List<List<R>>>(
      future: Future.wait(f),
      builder: (c, s) => s.hasData ? b(s.data!) : const Center(child: CircularProgressIndicator(color: brandOrange)),
    );

void snack(BuildContext c, String m) => ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brandRedDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(m, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );

Widget sectionTitle(String t, {IconData? icon}) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [brandRed, brandOrange], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          if (icon != null) ...[Icon(icon, size: 18, color: brandRed), const SizedBox(width: 6)],
          Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.6, color: Color(0xFF2B1B17))),
        ],
      ),
    );

Widget badge(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
    );

Future<bool> confirm(BuildContext c, String m) async =>
    await showDialog<bool>(
      context: c,
      builder: (ctx) => AlertDialog(
        content: Text(m, style: const TextStyle(fontWeight: FontWeight.w500)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sí, eliminar')),
        ],
      ),
    ) ??
    false;

/// Formulario genérico: texto libre, selectores, números, horas, valores iniciales y botón Eliminar.
Future<Map<String, String>?> form(
  BuildContext c,
  String title,
  List<String> fields, {
  Map<String, List<String>> pick = const {},
  Set<String> nums = const {},
  Set<String> times = const {},
  Map<String, String> init = const {},
  bool deletable = false,
}) {
  final v = <String, String>{};
  for (final f in fields) {
    final o = pick[f];
    v[f] = init[f] ?? ((o != null && o.isNotEmpty) ? o.first : (times.contains(f) ? nowHM() : ''));
  }
  return showDialog<Map<String, String>>(
    context: c,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: brandRedDark)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final f in fields) ...[
              if (pick.containsKey(f))
                StatefulBuilder(builder: (_, set) {
                  final opts = [...pick[f]!];
                  if (!opts.contains(v[f])) opts.insert(0, v[f]!);
                  return DropdownButtonFormField<String>(
                    value: v[f],
                    isExpanded: true,
                    decoration: InputDecoration(labelText: f),
                    items: [for (final o in opts) DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis))],
                    onChanged: (x) => set(() => v[f] = x!),
                  );
                })
              else if (times.contains(f))
                StatefulBuilder(
                  builder: (_, set) => Container(
                    decoration: BoxDecoration(color: surfaceWarm, borderRadius: BorderRadius.circular(14), border: Border.all(color: cardBorderWarm)),
                    child: ListTile(
                      leading: const Icon(Icons.access_time_filled, color: brandOrange),
                      title: Text(f, style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: Text(v[f]!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: brandRed)),
                      onTap: () async {
                        final t = await showTimePicker(context: ctx, initialTime: TimeOfDay(hour: int.parse(v[f]!.substring(0, 2)), minute: int.parse(v[f]!.substring(3, 5))));
                        if (t != null) set(() => v[f] = fmtT(t));
                      },
                    ),
                  ),
                )
              else
                TextFormField(
                  initialValue: v[f],
                  decoration: InputDecoration(labelText: f),
                  keyboardType: nums.contains(f) ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
                  onChanged: (x) => v[f] = x,
                ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
      actions: [
        if (deletable) TextButton(onPressed: () => Navigator.pop(ctx, {'__del': '1'}), child: const Text('Eliminar', style: TextStyle(color: brandRed, fontWeight: FontWeight.w700))),
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, v), child: const Text('GUARDAR')),
      ],
    ),
  );
}

Future<void> showRec(BuildContext c, R r) async {
  final cs = await q('SELECT * FROM compactions WHERE reception_id=?', [r['id']]);
  final ws = await q("SELECT * FROM wastes WHERE reception_id=? ORDER BY (type='Valorizable') DESC", [r['id']]);
  final its = await q('SELECT * FROM reception_items WHERE reception_id=?', [r['id']]);
  if (!c.mounted) return;
  final il = its.map((e) => '• ${e['material']}: ${dotNum(n(e['kg']))} kg').join('\n');
  final wl = ws.map((e) => '• ${e['type']}${(e['notes'] ?? '') == '' ? '' : ' (${e['notes']})'}: ${dotNum(n(e['kg']))} kg').join('\n');
  final cl = cs.map((e) => '• ${e['code']} ${e['material'] ?? ''}: ${dotNum(n(e['kg']))} kg (${e['operator']})').join('\n');
  showDialog(
    context: c,
    builder: (ctx) => AlertDialog(
      title: Text(recName(r), style: const TextStyle(fontWeight: FontWeight.w800, color: brandRedDark)),
      content: SingleChildScrollView(
        child: Text(
          '${r['code']} · ${r['boleta']} · ${r['bags']} bolsas\nLlegada: ${fdt(r['arrived'])}\nEstado: ${r['status']} · ${rem(r)}\n\nÍtems recibidos:\n$il\n\n${bal(r)}\n\nMermas:\n$wl\n\nProducción:\n$cl',
          style: const TextStyle(height: 1.45),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            Navigator.push(c, MaterialPageRoute(builder: (_) => RecFormPage(old: r)));
          },
          child: const Text('Editar', style: TextStyle(color: brandOrange, fontWeight: FontWeight.w700)),
        ),
        FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
      ],
    ),
  );
}

// ================= ASISTENCIAS =================
String attDate = today();

Future<void> mark(int wid, String date, {String? status, String? timeIn, double? ot}) async {
  final old = await q('SELECT * FROM attendance WHERE worker_id=? AND date=?', [wid, date]);
  final now = DateTime.now().toIso8601String();
  final st = status ?? (old.isEmpty ? 'Presente' : null);
  final vals = <String, Object?>{};
  if (st != null) {
    vals['status'] = st;
    final withIn = st == 'Presente' || st == 'Atraso';
    if (timeIn == null && withIn && (old.isEmpty || old.first['time_in'] == null) && date == today()) vals['time_in'] = now;
  }
  if (timeIn != null) vals['time_in'] = timeIn;
  if (ot != null) {
    vals['overtime'] = ot;
    if (ot > 0) vals['ot_signed'] = 0;
  }
  if (old.isEmpty) {
    await ins('attendance', {'worker_id': wid, 'date': date, ...vals});
  } else {
    await upd('attendance', vals, 'id=?', [old.first['id']]);
  }
}

Future<List<R>> otPending() => q('SELECT a.id,a.date,a.overtime,w.name FROM attendance a JOIN workers w ON w.id=a.worker_id WHERE a.overtime>0 AND a.ot_signed=0 AND a.date<? ORDER BY a.date', [today()]);

Widget otTile(R e) => ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: brandRed.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.assignment_late_rounded, color: brandRed),
      ),
      title: const Text('Emitir y firmar boleta de horas extras', style: TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('${e['name']} · ${e['date']} · ${dotNum(n(e['overtime']))} h'),
      trailing: FilledButton(onPressed: () => upd('attendance', {'ot_signed': 1}, 'id=?', [e['id']]), child: const Text('FIRMADA')),
    );

class AttPage extends StatelessWidget {
  const AttPage({super.key});
  void go(int dd) {
    final p = DateTime.parse(attDate);
    attDate = DateTime(p.year, p.month, p.day + dd).toIso8601String().substring(0, 10);
    tick.value++;
  }

  Future<void> action(BuildContext c, R r, String s) async {
    final id = r['id'] as int;
    if (s == 'Hora de ingreso') {
      final t = await showTimePicker(context: c, initialTime: TimeOfDay.now());
      if (t != null) await mark(id, attDate, timeIn: '${attDate}T${fmtT(t)}:00');
    } else if (s == 'Horas extras') {
      final v = await form(
        c,
        'Horas extras · ${r['name']}',
        ['Horas extras (0 = ninguna)'],
        nums: {'Horas extras (0 = ninguna)'},
        init: {'Horas extras (0 = ninguna)': n(r['overtime']) > 0 ? dotNum(n(r['overtime'])) : ''},
      );
      if (v != null) await mark(id, attDate, ot: d(v['Horas extras (0 = ninguna)']));
    } else {
      await mark(id, attDate, status: s);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: brandOrange,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add_rounded),
          label: const Text('Trabajador', style: TextStyle(fontWeight: FontWeight.w700)),
          onPressed: () async {
            final v = await form(c, 'Nuevo trabajador', ['Nombre', 'Cargo']);
            if (v != null && v['Nombre']!.trim().isNotEmpty) await ins('workers', {'name': v['Nombre']!.trim(), 'role': v['Cargo'], 'active': 1});
          },
        ),
        body: futs([
          q('SELECT w.id,w.name,w.role,a.status,a.time_in,a.overtime FROM workers w LEFT JOIN attendance a ON a.worker_id=w.id AND a.date=? WHERE w.active=1 ORDER BY w.name', [attDate]),
          otPending(),
        ], (res) {
          final rows = res[0];
          final pres = rows.where((r) => r['status'] == 'Presente' || r['status'] == 'Atraso').length;
          return ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 95),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(backgroundColor: brandOrange.withOpacity(0.12), foregroundColor: brandRed),
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: () => go(-1),
                      ),
                      Column(
                        children: [
                          Text(attDate, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: brandRed)),
                          const SizedBox(height: 2),
                          badge('Presentes: $pres de ${rows.length}', brandOrange),
                        ],
                      ),
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(backgroundColor: brandOrange.withOpacity(0.12), foregroundColor: brandRed),
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: () => go(1),
                      ),
                    ],
                  ),
                ),
              ),
              for (final e in res[1]) Card(color: const Color(0xFFFFEBEE), child: otTile(e)),
              for (final r in rows)
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: r['status'] == null
                          ? Colors.grey.shade400
                          : (r['status'] == 'Presente' ? brandOrange : (r['status'] == 'Falta' ? brandRed : brandOrangeSoft)),
                      child: const Icon(Icons.person_rounded, color: Colors.white),
                    ),
                    title: Text('${r['name']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${r['role'] ?? 'Sin cargo'} · Ingreso ${hm(r['time_in'])}${n(r['overtime']) > 0 ? ' · HE ${dotNum(n(r['overtime']))} h' : ''}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        badge(
                          '${r['status'] ?? 'Sin registro'}',
                          r['status'] == 'Presente' ? brandOrange : (r['status'] == 'Falta' ? brandRed : Colors.deepOrange),
                        ),
                        PopupMenuButton<String>(
                          iconColor: brandRed,
                          onSelected: (s) => action(c, r, s),
                          itemBuilder: (_) => [for (final s in [...statuses, 'Hora de ingreso', 'Horas extras']) PopupMenuItem(value: s, child: Text(s))],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        }),
      );
}

// ================= RECEPCIONES =================
class RecPage extends StatelessWidget {
  const RecPage({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: brandRed,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Recepción', style: TextStyle(fontWeight: FontWeight.w700)),
          onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const RecFormPage())),
        ),
        body: fut(recs(), (rs) {
          final l = rs.reversed.toList();
          if (l.isEmpty) return const Center(child: Text('Sin recepciones. Toca + Recepción.'));
          return ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 95),
            children: [
              for (final r in l)
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: prColor(r),
                      child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 20),
                    ),
                    title: Text(recName(r), style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${r['code']}${r['no_boleta'] == 1 ? ' · ${r['boleta']}' : ''} · ${r['material']}\n${r['bags']} bolsas · ${dotNum(n(r['kg']))} kg · ${fdt(r['arrived'])}\n${rem(r)}',
                        style: const TextStyle(height: 1.38),
                      ),
                    ),
                    isThreeLine: true,
                    onTap: () => showRec(c, r),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_rounded, color: brandOrange),
                      onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => RecFormPage(old: r))),
                    ),
                  ),
                ),
            ],
          );
        }),
      );
}

class _Item {
  final m = TextEditingController();
  final k = TextEditingController();
}

class RecFormPage extends StatefulWidget {
  final R? old;
  const RecFormPage({super.key, this.old});
  @override
  State<RecFormPage> createState() => _RF();
}

class _RF extends State<RecFormPage> {
  bool sin = false, ready = false;
  final bol = TextEditingController(), emp = TextEditingController(), bag = TextEditingController(), obs = TextEditingController();
  final items = <_Item>[];
  DateTime when = DateTime.now();

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final o = widget.old;
    if (o != null) {
      sin = o['no_boleta'] == 1;
      bol.text = sin ? '' : '${o['boleta']}';
      emp.text = '${o['supplier'] ?? ''}';
      bag.text = '${o['bags'] ?? 0}';
      obs.text = '${o['notes'] ?? ''}';
      when = DateTime.parse('${o['arrived']}');
      for (final i in await q('SELECT * FROM reception_items WHERE reception_id=?', [o['id']])) {
        items.add(_Item()
          ..m.text = '${i['material']}'
          ..k.text = dotNum(n(i['kg'])));
      }
    }
    if (items.isEmpty) items.add(_Item());
    if (mounted) setState(() => ready = true);
  }

  Future<void> pickWhen() async {
    final dt = await showDatePicker(context: context, initialDate: when, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 1)));
    if (dt == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(when));
    if (t == null) return;
    setState(() => when = DateTime(dt.year, dt.month, dt.day, t.hour, t.minute));
  }

  Future<void> save() async {
    final its = items.where((i) => i.m.text.trim().isNotEmpty || d(i.k.text) > 0).toList();
    if (emp.text.trim().isEmpty || its.isEmpty || (!sin && bol.text.trim().isEmpty)) {
      snack(context, 'Completa empresa, boleta (o Sin boleta) y al menos un ítem');
      return;
    }
    final o = widget.old;
    var boleta = bol.text.trim();
    if (sin) {
      if (o != null && o['no_boleta'] == 1) {
        boleta = '${o['boleta']}';
      } else {
        final m = await q('SELECT COALESCE(MAX(CAST(SUBSTR(boleta,4) AS INTEGER)),0) AS m FROM receptions WHERE no_boleta=1');
        boleta = 'SB-${(n(m.first['m']).toInt() + 1).toString().padLeft(4, '0')}';
      }
    } else {
      final dup = await q('SELECT 1 FROM receptions WHERE boleta=? AND id<>?', [boleta, o?['id'] ?? -1]);
      if (dup.isNotEmpty) {
        if (mounted) snack(context, 'Ya existe una recepción con esa boleta');
        return;
      }
    }
    final total = its.fold<double>(0, (a, i) => a + d(i.k.text));
    final mats = its.map((i) => i.m.text.trim()).where((s) => s.isNotEmpty).toSet().join(', ');
    final vals = <String, Object?>{'boleta': boleta, 'no_boleta': sin ? 1 : 0, 'supplier': emp.text.trim(), 'material': mats, 'bags': int.tryParse(bag.text) ?? 0, 'kg': total, 'arrived': when.toIso8601String(), 'notes': obs.text};
    int id;
    if (o == null) {
      id = await ins('receptions', {...vals, 'status': 'pendiente'});
      await upd('receptions', {'code': 'REC-${id.toString().padLeft(4, '0')}'}, 'id=?', [id]);
    } else {
      id = o['id'] as int;
      await upd('receptions', vals, 'id=?', [id]);
      await del('reception_items', 'reception_id=?', [id]);
    }
    for (final i in its) {
      await ins('reception_items', {'reception_id': id, 'material': i.m.text.trim(), 'kg': d(i.k.text)});
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext c) {
    if (!ready) return Scaffold(appBar: AppBar(title: const Text('Recepción')), body: const Center(child: CircularProgressIndicator(color: brandOrange)));
    final total = items.fold<double>(0, (a, i) => a + d(i.k.text));
    return Scaffold(
      appBar: AppBar(title: Text(widget.old == null ? 'Nueva recepción' : 'Editar ${widget.old!['code']}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: SwitchListTile(
              activeColor: brandOrange,
              title: const Text('Sin boleta', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Se genera un identificador automático'),
              value: sin,
              onChanged: (x) => setState(() => sin = x),
            ),
          ),
          const SizedBox(height: 12),
          if (!sin) ...[
            TextField(controller: bol, decoration: const InputDecoration(labelText: 'Número de boleta')),
            const SizedBox(height: 12),
          ],
          TextField(controller: emp, decoration: const InputDecoration(labelText: 'Empresa')),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.edit_calendar_rounded, color: brandOrange),
              title: const Text('Fecha y hora de llegada', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(fdt(when.toIso8601String()), style: const TextStyle(fontWeight: FontWeight.w700, color: brandRed)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: pickWhen,
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: bag, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cantidad de bolsas')),
          const SizedBox(height: 18),
          const Text('Ítems recibidos', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: brandRedDark)),
          const SizedBox(height: 8),
          for (var i = 0; i < items.length; i++) ...[
            Row(children: [
              Expanded(flex: 3, child: TextField(controller: items[i].m, decoration: InputDecoration(labelText: 'Material ${i + 1}'))),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: TextField(controller: items[i].k, onChanged: (_) => setState(() {}), keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Peso kg'))),
              IconButton(icon: const Icon(Icons.delete_outline, color: brandRed), onPressed: items.length > 1 ? () => setState(() => items.removeAt(i)) : null),
            ]),
            const SizedBox(height: 10),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: brandOrange),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Agregar ítem', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () => setState(() => items.add(_Item())),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [brandRed.withOpacity(0.08), brandOrange.withOpacity(0.10)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: brandOrange.withOpacity(0.35)),
            ),
            child: Text('Peso total: ${dotNum(total)} kg', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: brandRed)),
          ),
          const SizedBox(height: 12),
          TextField(controller: obs, decoration: const InputDecoration(labelText: 'Observaciones')),
          const SizedBox(height: 20),
          FilledButton.icon(icon: const Icon(Icons.save_rounded), label: const Text('GUARDAR RECEPCIÓN'), onPressed: save),
        ],
      ),
    );
  }
}

// ================= CLASIFICACIÓN =================
class ClassPage extends StatelessWidget {
  const ClassPage({super.key});
  @override
  Widget build(BuildContext c) => fut(recs(), (rs) {
        final pend = rs.where((r) => r['status'] == 'pendiente').toList();
        final done = rs.where((r) => r['status'] == 'completada').toList().reversed.toList();
        void open(R r) => Navigator.push(c, MaterialPageRoute(builder: (_) => ClassifyPage(r)));
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          children: [
            sectionTitle('PENDIENTES DE CLASIFICAR', icon: Icons.pending_actions_rounded),
            if (pend.isEmpty)
              const Card(margin: EdgeInsets.zero, child: ListTile(title: Text('No hay recepciones pendientes de clasificar'))),
            for (final r in pend)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(backgroundColor: prColor(r), child: const Icon(Icons.schedule_rounded, color: Colors.white, size: 20)),
                  title: Text(recName(r), style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${r['code']} · ${r['material']}\n${r['bags']} bolsas · ${dotNum(n(r['kg']))} kg · ${rem(r)}', style: const TextStyle(height: 1.38)),
                  isThreeLine: true,
                  trailing: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: brandOrange),
                    onPressed: () => open(r),
                    child: const Text('CLASIFICAR'),
                  ),
                ),
              ),
            sectionTitle('CLASIFICADAS', icon: Icons.verified_rounded),
            for (final r in done)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: brandOrange, child: Icon(Icons.check_rounded, color: Colors.white)),
                  title: Text(recName(r), style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${r['code']} · mermas ${dotNum(n(r['waste']))} kg · neto ${dotNum(n(r['kg']) - n(r['waste']))} kg'),
                  trailing: const Icon(Icons.edit_rounded, color: brandRed),
                  onTap: () => open(r),
                ),
              ),
          ],
        );
      });
}

class ClassifyPage extends StatefulWidget {
  final R r;
  const ClassifyPage(this.r, {super.key});
  @override
  State<ClassifyPage> createState() => _CS();
}

class _CS extends State<ClassifyPage> {
  final start = DateTime.now().toIso8601String();

  Future<void> wasteForm(BuildContext c, R? old) async {
    final v = await form(
      c,
      old == null ? 'Registrar merma' : 'Editar merma',
      ['Categoría', 'Material / detalle', 'Peso kg', 'Comentarios'],
      pick: {'Categoría': wasteTypes},
      nums: {'Peso kg'},
      init: old == null ? {} : {'Categoría': '${old['type']}', 'Material / detalle': '${old['notes'] ?? ''}', 'Peso kg': dotNum(n(old['kg'])), 'Comentarios': ''},
      deletable: old != null,
    );
    if (v == null) return;
    if (v.containsKey('__del')) {
      if (c.mounted && await confirm(c, '¿Eliminar esta merma?')) await del('wastes', 'id=?', [old!['id']]);
    } else {
      final vals = <String, Object?>{'type': v['Categoría'], 'kg': d(v['Peso kg']), 'notes': [v['Material / detalle'], v['Comentarios']].where((s) => s != null && s.trim().isNotEmpty).join(' · ')};
      if (old == null) {
        await ins('wastes', {'reception_id': widget.r['id'], ...vals});
      } else {
        await upd('wastes', vals, 'id=?', [old['id']]);
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext c) {
    final id = widget.r['id'];
    final isDone = widget.r['status'] == 'completada';
    return Scaffold(
      appBar: AppBar(title: Text('Clasificar ${widget.r['code']}')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: brandOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Merma', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () => wasteForm(c, null),
      ),
      body: fut(q("SELECT * FROM wastes WHERE reception_id=? ORDER BY (type='Valorizable') DESC, id", [id]), (ws) {
        final kg = n(widget.r['kg']);
        final w = ws.fold<double>(0, (a, e) => a + n(e['kg']));
        final val = ws.where((e) => e['type'] == 'Valorizable').fold<double>(0, (a, e) => a + n(e['kg']));
        final pct = kg > 0 ? w / kg * 100 : 0;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recName(widget.r), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('${widget.r['material']} · ${widget.r['bags']} bolsas'),
                    const SizedBox(height: 8),
                    badge('Peso original recibido: ${dotNum(kg)} kg', brandRed),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            for (final e in ws)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: e['type'] == 'Valorizable' ? const Color(0xFFFFF3E0) : Colors.white,
                child: ListTile(
                  leading: e['type'] == 'Valorizable' ? const Icon(Icons.star_rounded, color: brandOrange) : const Icon(Icons.delete_outline, color: brandRed),
                  title: Text('${e['type']}', style: TextStyle(fontWeight: e['type'] == 'Valorizable' ? FontWeight.w800 : FontWeight.w600)),
                  subtitle: Text('${e['notes'] ?? ''}'),
                  trailing: Text('${dotNum(n(e['kg']))} kg', style: const TextStyle(fontWeight: FontWeight.w800, color: brandRedDark)),
                  onTap: () => wasteForm(c, e),
                ),
              ),
            const SizedBox(height: 10),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (val > 0) Text('Valorizable: ${dotNum(val)} kg', style: const TextStyle(fontWeight: FontWeight.bold, color: brandOrange)),
                    Text('Total mermas: ${dotNum(w)} kg (${dotNum(pct)}%)'),
                    Text('Aprovechamiento: ${dotNum(100 - pct)}%'),
                    const SizedBox(height: 8),
                    Text('PESO NETO APROVECHABLE: ${dotNum(kg - w)} kg', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: brandRed)),
                    if (w > kg) const Padding(padding: EdgeInsets.only(top: 6), child: Text('¡Las mermas superan el peso recibido!', style: TextStyle(color: brandRed, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              icon: const Icon(Icons.check_rounded),
              label: Text(isDone ? 'GUARDAR CAMBIOS' : 'COMPLETAR CLASIFICACIÓN'),
              onPressed: w > kg
                  ? null
                  : () async {
                      final ops = await q('SELECT name FROM workers WHERE active=1 ORDER BY name');
                      final old = await q('SELECT * FROM classifications WHERE reception_id=?', [id]);
                      if (!c.mounted) return;
                      final v = await form(
                        c,
                        isDone ? 'Editar clasificación' : 'Completar clasificación',
                        ['Operario', 'Observaciones'],
                        pick: {'Operario': ops.map((e) => '${e['name']}').toList()},
                        init: old.isEmpty ? {} : {'Operario': '${old.first['operator']}', 'Observaciones': '${old.first['notes'] ?? ''}'},
                      );
                      if (v == null) return;
                      if (old.isEmpty) {
                        await ins('classifications', {'reception_id': id, 'started': start, 'finished': DateTime.now().toIso8601String(), 'operator': v['Operario'], 'notes': v['Observaciones']});
                      } else {
                        await upd('classifications', {'operator': v['Operario'], 'notes': v['Observaciones']}, 'id=?', [old.first['id']]);
                      }
                      await upd('receptions', {'status': 'completada'}, 'id=?', [id]);
                      if (c.mounted) Navigator.pop(c);
                    },
            ),
          ],
        );
      }),
    );
  }
}

// ================= PRODUCCIÓN =================
Future<void> prodForm(BuildContext c, String kind, {R? old}) async {
  final all = await recs();
  final done = all.where((r) => r['status'] == 'completada').toList();
  final ws = await q('SELECT name FROM workers WHERE active=1 ORDER BY name');
  if (!c.mounted) return;
  if (ws.isEmpty && old == null) {
    snack(c, 'Primero agrega trabajadores en Asistencias');
    return;
  }

  final ql = kind == 'paca' ? 'Pacas' : 'Bolsas llenadas';
  DateTime selectedDate = old != null ? DateTime.parse('${old['start']}') : DateTime.now();
  TimeOfDay startTime = old != null
      ? TimeOfDay.fromDateTime(DateTime.parse('${old['start']}'))
      : TimeOfDay.now();
  TimeOfDay endTime = old != null && old['finish'] != null
      ? TimeOfDay.fromDateTime(DateTime.parse('${old['finish']}'))
      : TimeOfDay.now();

  final opsList = ws.map((e) => '${e['name']}').toList();
  final curRec = old != null ? all.where((r) => r['id'] == old['reception_id']).firstOrNull : null;

  String material = old != null
      ? '${old['material'] ?? ''}'
      : (kind == 'conos' ? 'Conos triturados' : '');
  String selectedRec = curRec == null ? none : recTitle(curRec);
  String selectedOp = old != null && '${old['operator']}'.isNotEmpty
      ? '${old['operator']}'
      : (opsList.isNotEmpty ? opsList.first : '');
  String qtyText = old != null ? '${old['bales'] ?? ''}' : (kind == 'paca' ? '1' : '');
  String kgText = old != null ? dotNum(n(old['kg'])) : '';
  String notesText = old != null ? '${old['notes'] ?? ''}' : '';

  final recOpts = [none, ...done.map(recTitle)];
  if (!recOpts.contains(selectedRec)) recOpts.insert(0, selectedRec);
  final opOpts = [...opsList];
  if (selectedOp.isNotEmpty && !opOpts.contains(selectedOp)) opOpts.insert(0, selectedOp);

  final saved = await showDialog<bool>(
    context: c,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) {
        String dateStr() => selectedDate.toIso8601String().substring(0, 10);
        return AlertDialog(
          title: Text('${old == null ? 'Nueva' : 'Editar'} ${kind == 'paca' ? 'paca' : 'corte y trituración de conos'}', style: const TextStyle(fontWeight: FontWeight.w800, color: brandRedDark)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: brandOrange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: brandOrange.withOpacity(0.35)),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_month_rounded, color: brandRed),
                    title: const Text('Fecha de producción', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    subtitle: Text(dateStr(), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: brandRed)),
                    trailing: const Icon(Icons.edit_rounded, color: brandOrange),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        set(() => selectedDate = DateTime(picked.year, picked.month, picked.day));
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: material,
                  decoration: const InputDecoration(labelText: 'Material'),
                  onChanged: (x) => material = x,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRec,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Empresa / Recepción (opcional)'),
                  items: [for (final o in recOpts) DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis))],
                  onChanged: (x) => set(() => selectedRec = x!),
                ),
                const SizedBox(height: 12),
                if (opOpts.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedOp,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Operario'),
                    items: [for (final o in opOpts) DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis))],
                    onChanged: (x) => set(() => selectedOp = x!),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final t = await showTimePicker(context: ctx, initialTime: startTime);
                          if (t != null) set(() => startTime = t);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Inicio'),
                          child: Text(fmtT(startTime), style: const TextStyle(fontWeight: FontWeight.w800, color: brandRed)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final t = await showTimePicker(context: ctx, initialTime: endTime);
                          if (t != null) set(() => endTime = t);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Fin'),
                          child: Text(fmtT(endTime), style: const TextStyle(fontWeight: FontWeight.w800, color: brandRed)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: qtyText,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: ql),
                  onChanged: (x) => qtyText = x,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: kgText,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Peso kg'),
                  onChanged: (x) => kgText = x,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: notesText,
                  decoration: const InputDecoration(labelText: 'Observaciones'),
                  onChanged: (x) => notesText = x,
                ),
              ],
            ),
          ),
          actions: [
            if (old != null)
              TextButton(
                onPressed: () async {
                  if (ctx.mounted && await confirm(ctx, '¿Eliminar este registro?')) {
                    await del('compactions', 'id=?', [old['id']]);
                    if (ctx.mounted) Navigator.pop(ctx, false);
                  }
                },
                child: const Text('Eliminar', style: TextStyle(color: brandRed, fontWeight: FontWeight.w700)),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('GUARDAR')),
          ],
        );
      },
    ),
  );

  if (saved != true || !c.mounted) return;

  final dateStr = selectedDate.toIso8601String().substring(0, 10);
  final s = at(dateStr, fmtT(startTime));
  var e = at(dateStr, fmtT(endTime));
  if (e.isBefore(s)) e = e.add(const Duration(days: 1));
  final mins = e.difference(s).inMinutes.toDouble();
  final rec = selectedRec == none ? null : all.firstWhere((r) => recTitle(r) == selectedRec);
  final kg = d(kgText);

  if (rec != null && kg > 0 && kind == 'paca') {
    final saldo = n(rec['kg']) - n(rec['waste']) - n(rec['compacted']) + (old != null && old['reception_id'] == rec['id'] ? n(old['kg']) : 0);
    if (kg > saldo + 0.001) {
      if (c.mounted) snack(c, 'El peso excede el saldo de la recepción (${dotNum(saldo)} kg)');
      return;
    }
  }

  final vals = <String, Object?>{
    'reception_id': rec?['id'],
    'operator': selectedOp,
    'start': s.toIso8601String(),
    'finish': e.toIso8601String(),
    'minutes': mins,
    'kg': kg,
    'bales': int.tryParse(qtyText.trim().split('.').first.replaceAll(',', '')) ?? 0,
    'notes': notesText,
    'kind': kind,
    'material': material,
  };

  if (old == null) {
    final id = await ins('compactions', vals);
    await upd('compactions', {'code': '${kind == 'paca' ? 'PAC' : 'CON'}-${id.toString().padLeft(4, '0')}'}, 'id=?', [id]);
  } else {
    await upd('compactions', vals, 'id=?', [old['id']]);
  }
}

class ProdPage extends StatelessWidget {
  const ProdPage({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              heroTag: 'conos',
              backgroundColor: brandOrange,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.content_cut_rounded),
              label: const Text('Corte y trituración de conos', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () => prodForm(c, 'conos'),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              heroTag: 'paca',
              backgroundColor: brandRed,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Paca', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () => prodForm(c, 'paca'),
            ),
          ],
        ),
        body: fut(q('SELECT c.*, r.code AS rcode, r.supplier FROM compactions c LEFT JOIN receptions r ON r.id=c.reception_id ORDER BY c.start DESC'), (rows) {
          final pac = rows.where((e) => e['kind'] != 'conos');
          final kg = rows.fold<double>(0, (a, e) => a + n(e['kg']));
          final h = rows.fold<double>(0, (a, e) => a + n(e['minutes'])) / 60;
          return ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 165),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(children: [
                        Text('${pac.fold<double>(0, (a, e) => a + n(e['bales'])).toInt()}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: brandRed)),
                        const Text('Pacas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                      Container(width: 1, height: 30, color: cardBorderWarm),
                      Column(children: [
                        Text('${dotNum(kg)} kg', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: brandOrange)),
                        const Text('Producido', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                      Container(width: 1, height: 30, color: cardBorderWarm),
                      Column(children: [
                        Text('${dotNum(h)} h', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: brandRedDark)),
                        const Text('Tiempo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    ],
                  ),
                ),
              ),
              for (final e in rows)
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: e['kind'] == 'conos' ? brandOrange.withOpacity(0.15) : brandRed.withOpacity(0.12),
                      child: Icon(e['kind'] == 'conos' ? Icons.content_cut_rounded : Icons.inventory_2_rounded, color: e['kind'] == 'conos' ? brandOrange : brandRed, size: 20),
                    ),
                    title: Text('${e['code']} · ${e['kind'] == 'conos' ? 'Conos' : 'Paca'} · ${e['material'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${'${e['start']}'.substring(0, 10)} · ${e['operator']} · ${hm(e['start'])}–${hm(e['finish'])} · ${dotNum(n(e['minutes']), dec: 0)} min'
                        '${e['kind'] != 'conos' && n(e['bales']) > 0 ? ' · ${dotNum(n(e['minutes']) / n(e['bales']))} min/paca' : ''}'
                        '${e['kind'] == 'conos' ? ' · ${e['bales']} bolsas' : ' · ${e['bales']} pacas'}'
                        '${e['rcode'] != null ? '\n${e['rcode']} - ${e['supplier']}' : ''}',
                        style: const TextStyle(height: 1.38),
                      ),
                    ),
                    isThreeLine: e['rcode'] != null,
                    trailing: Text('${dotNum(n(e['kg']))} kg', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: brandRed)),
                    onTap: () => prodForm(c, '${e['kind'] ?? 'paca'}', old: e),
                  ),
                ),
            ],
          );
        }),
      );
}

// ================= PENDIENTES =================
class PendPage extends StatelessWidget {
  const PendPage({super.key});

  Future<void> edit(BuildContext c, R? old) async {
    String title = old != null ? '${old['title'] ?? ''}' : '';
    String notes = old != null ? '${old['notes'] ?? ''}' : '';
    String dueDate = old != null && '${old['due_date'] ?? ''}'.isNotEmpty ? '${old['due_date']}' : '';

    final saved = await showDialog<bool>(
      context: c,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(old == null ? 'Nuevo pendiente' : 'Editar pendiente', style: const TextStyle(fontWeight: FontWeight.w800, color: brandRedDark)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: title,
                  decoration: const InputDecoration(labelText: 'Pendiente'),
                  onChanged: (x) => title = x,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: notes,
                  decoration: const InputDecoration(labelText: 'Detalle'),
                  onChanged: (x) => notes = x,
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: surfaceWarm,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cardBorderWarm),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.event_available_rounded, color: brandOrange),
                    title: const Text('Fecha límite', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text(dueDate.isEmpty ? 'Sin fecha límite' : dueDate, style: TextStyle(fontWeight: FontWeight.w800, color: dueDate.isEmpty ? Colors.grey : brandRed)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (dueDate.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: brandRed),
                            onPressed: () => set(() => dueDate = ''),
                          ),
                        const Icon(Icons.calendar_today_rounded, size: 18, color: brandOrange),
                      ],
                    ),
                    onTap: () async {
                      final init = dueDate.isNotEmpty ? DateTime.tryParse(dueDate) ?? DateTime.now() : DateTime.now();
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: init,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        set(() => dueDate = picked.toIso8601String().substring(0, 10));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (old != null)
              TextButton(
                onPressed: () async {
                  if (ctx.mounted && await confirm(ctx, '¿Eliminar este pendiente?')) {
                    await del('pending', 'id=?', [old['id']]);
                    if (ctx.mounted) Navigator.pop(ctx, false);
                  }
                },
                child: const Text('Eliminar', style: TextStyle(color: brandRed, fontWeight: FontWeight.w700)),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('GUARDAR')),
          ],
        ),
      ),
    );

    if (saved != true || title.trim().isEmpty) return;
    final vals = <String, Object?>{
      'title': title.trim(),
      'notes': notes,
      'due_date': dueDate.isEmpty ? null : dueDate,
    };
    if (old == null) {
      await ins('pending', {...vals, 'done': 0, 'created': DateTime.now().toIso8601String()});
    } else {
      await upd('pending', vals, 'id=?', [old['id']]);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: brandRed,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Pendiente', style: TextStyle(fontWeight: FontWeight.w700)),
          onPressed: () => edit(c, null),
        ),
        body: fut(q("SELECT * FROM pending ORDER BY done, CASE WHEN due_date IS NULL OR due_date='' THEN 1 ELSE 0 END, due_date, id DESC"), (rows) {
          if (rows.isEmpty) return const Center(child: Text('Sin pendientes. Toca + Pendiente.'));
          final t = today();
          return ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 95),
            children: [
              for (final p in rows) ...[
                () {
                  final isDone = p['done'] == 1;
                  final due = '${p['due_date'] ?? ''}';
                  Color dueCol = Colors.grey.shade600;
                  String dueLabel = '';
                  if (due.isNotEmpty) {
                    if (!isDone && due.compareTo(t) < 0) {
                      dueCol = brandRed;
                      dueLabel = 'Vencido: $due';
                    } else if (!isDone && due == t) {
                      dueCol = brandOrange;
                      dueLabel = 'Vence hoy: $due';
                    } else {
                      dueCol = Colors.deepOrange;
                      dueLabel = 'Límite: $due';
                    }
                  }
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      leading: Checkbox(
                        activeColor: brandOrange,
                        value: isDone,
                        onChanged: (x) => upd('pending', {'done': x! ? 1 : 0}, 'id=?', [p['id']]),
                      ),
                      title: Text(
                        '${p['title']}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          color: isDone ? Colors.grey : const Color(0xFF2B1B17),
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((p['notes'] ?? '') != '') Text('${p['notes']}'),
                          if (dueLabel.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            badge(dueLabel, dueCol),
                          ],
                        ],
                      ),
                      onTap: () => edit(c, p),
                    ),
                  );
                }(),
              ],
            ],
          );
        }),
      );
}

// ================= PLANO CUADRICULADO 20x30 =================
class FloorPlanPage extends StatefulWidget {
  const FloorPlanPage({super.key});
  @override
  State<FloorPlanPage> createState() => _FloorPlanState();
}

class _FloorPlanState extends State<FloorPlanPage> {
  static const int cols = 20;
  static const int rows = 30;

  // -1 = Borrador (deja el cuadro en blanco), 0 = Negro (paredes), 1..10 = Carga por empresa
  int selectedTool = 1;
  bool loading = true;
  bool paintMode = true; // true = pintar tocando/arrastrando, false = solo mover/hacer zoom

  final Map<int, int> cells = {}; // key = r * cols + c, value = color_idx
  final Map<int, Map<String, String>> legend = {};
  final TransformationController zoomCtrl = TransformationController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    zoomCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final lRows = await q('SELECT * FROM floor_legend ORDER BY color_idx');
    final cRows = await q('SELECT * FROM floor_cells');
    legend.clear();
    for (final r in lRows) {
      final idx = (r['color_idx'] as num).toInt();
      legend[idx] = {
        'label': '${r['label'] ?? ''}',
        'notes': '${r['notes'] ?? ''}',
      };
    }
    // Garantiza que existan entradas del 0 al 10
    for (int idx = 0; idx < floorPalette.length; idx++) {
      legend.putIfAbsent(
        idx,
        () => {
          'label': idx == 0 ? 'Paredes / Áreas segmentadas' : 'Empresa $idx',
          'notes': '',
        },
      );
    }
    cells.clear();
    for (final r in cRows) {
      final ri = (r['r'] as num).toInt();
      final ci = (r['c'] as num).toInt();
      final col = (r['color_idx'] as num).toInt();
      if (ri >= 0 && ri < rows && ci >= 0 && ci < cols) {
        cells[ri * cols + ci] = col;
      }
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _applyCell(int r, int c) async {
    if (r < 0 || r >= rows || c < 0 || c >= cols) return;
    final k = r * cols + c;
    final database = await db;
    if (selectedTool == -1) {
      if (!cells.containsKey(k)) return;
      setState(() => cells.remove(k));
      await database.delete('floor_cells', where: 'r=? AND c=?', whereArgs: [r, c]);
    } else {
      if (cells[k] == selectedTool) return;
      setState(() => cells[k] = selectedTool);
      await database.insert(
        'floor_cells',
        {'r': r, 'c': c, 'color_idx': selectedTool},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _editLegend(int idx) async {
    final cur = legend[idx] ?? {'label': idx == 0 ? 'Paredes / Áreas segmentadas' : 'Empresa $idx', 'notes': ''};
    String label = cur['label']!;
    String notes = cur['notes']!;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: floorPalette[idx],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black26),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                idx == 0 ? 'Paredes y áreas (Negro)' : 'Asignar empresa al color',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: brandRedDark),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: label,
              decoration: InputDecoration(
                labelText: idx == 0 ? 'Descripción estructura' : 'Nombre de la empresa',
              ),
              onChanged: (x) => label = x,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: notes,
              decoration: InputDecoration(
                labelText: idx == 0 ? 'Detalle de sectores (opcional)' : 'Material / Boleta / Nota (opcional)',
              ),
              onChanged: (x) => notes = x,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('GUARDAR')),
        ],
      ),
    );

    if (ok == true && label.trim().isNotEmpty) {
      final cleanLabel = label.trim();
      final cleanNotes = notes.trim();
      final database = await db;
      await database.insert(
        'floor_legend',
        {'color_idx': idx, 'label': cleanLabel, 'notes': cleanNotes},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (mounted) {
        setState(() {
          legend[idx] = {'label': cleanLabel, 'notes': cleanNotes};
        });
      }
    }
  }

  Future<void> _clearLoadsOnly() async {
    final ok = await confirm(context, '¿Borrar toda la carga coloreada del plano? (Las paredes negras se conservarán)');
    if (!ok) return;
    final database = await db;
    await database.delete('floor_cells', where: 'color_idx > 0');
    if (mounted) {
      setState(() {
        cells.removeWhere((_, v) => v > 0);
      });
    }
  }

  void _stepZoom(double factor) {
    final curScale = zoomCtrl.value.getMaxScaleOnAxis();
    final nextScale = (curScale * factor).clamp(1.0, 5.0);
    zoomCtrl.value = Matrix4.identity()..scale(nextScale);
  }

  void _resetZoom() {
    zoomCtrl.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: brandOrange));

    final curInfo = selectedTool >= 0 ? legend[selectedTool] : null;
    final wallCount = cells.values.where((v) => v == 0).length;
    final loadCount = cells.values.where((v) => v > 0).length;

    return Column(
      children: [
        // Barra de herramientas superior: Modo Pintar/Zoom, Botones Zoom +/- y Limpiar cargas
        Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorderWarm, width: 1.2),
          ),
          child: Row(
            children: [
              ChoiceChip(
                selected: paintMode,
                selectedColor: brandRed,
                labelStyle: TextStyle(
                  color: paintMode ? Colors.white : const Color(0xFF2B1B17),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
                avatar: Icon(Icons.brush_rounded, size: 16, color: paintMode ? Colors.white : brandRed),
                label: const Text('Pintar'),
                onSelected: (_) => setState(() => paintMode = true),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                selected: !paintMode,
                selectedColor: brandOrange,
                labelStyle: TextStyle(
                  color: !paintMode ? Colors.white : const Color(0xFF2B1B17),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
                avatar: Icon(Icons.pinch_rounded, size: 16, color: !paintMode ? Colors.white : brandOrange),
                label: const Text('Zoom/Mover'),
                onSelected: (_) => setState(() => paintMode = false),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Alejar',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.zoom_out_rounded, color: brandRed),
                onPressed: () => _stepZoom(0.75),
              ),
              IconButton(
                tooltip: 'Restablecer vista',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.center_focus_strong_rounded, color: brandOrange),
                onPressed: _resetZoom,
              ),
              IconButton(
                tooltip: 'Acercar',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.zoom_in_rounded, color: brandRed),
                onPressed: () => _stepZoom(1.35),
              ),
              IconButton(
                tooltip: 'Limpiar cargas (conserva paredes)',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.cleaning_services_rounded, color: brandRedDark),
                onPressed: _clearLoadsOnly,
              ),
            ],
          ),
        ),

        // Selector de Borrador, Negro (Paredes) y Colores por Empresa
        SizedBox(
          height: 54,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            children: [
              // Herramienta Borrador
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() {
                    selectedTool = -1;
                    paintMode = true;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: selectedTool == -1 ? const Color(0xFFFFEBEE) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selectedTool == -1 ? brandRed : cardBorderWarm,
                        width: selectedTool == -1 ? 2 : 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_fix_normal_rounded, size: 18, color: selectedTool == -1 ? brandRed : Colors.grey.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Borrar',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: selectedTool == -1 ? brandRed : const Color(0xFF2B1B17),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Negro (0 = Paredes) y Colores (1..10 = Empresas)
              for (int idx = 0; idx < floorPalette.length; idx++)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() {
                      selectedTool = idx;
                      paintMode = true;
                    }),
                    onLongPress: () => _editLegend(idx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: selectedTool == idx ? floorPalette[idx].withOpacity(0.14) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selectedTool == idx ? floorPalette[idx] : cardBorderWarm,
                          width: selectedTool == idx ? 2.2 : 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: floorPalette[idx],
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: idx == 0
                                ? const Icon(Icons.wall_for_fire_rounded, size: 12, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 115),
                            child: Text(
                              idx == 0 ? 'Pared (Negro)' : (legend[idx]?['label'] ?? 'Empresa $idx'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: idx == 0 ? Colors.black87 : const Color(0xFF2B1B17),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Barra activa: muestra qué herramienta/empresa está seleccionada y permite editar su nombre
        Container(
          margin: const EdgeInsets.fromLTRB(12, 2, 12, 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selectedTool == -1
                ? const Color(0xFFFFF3E0)
                : floorPalette[selectedTool].withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selectedTool == -1 ? brandOrange.withOpacity(0.4) : floorPalette[selectedTool].withOpacity(0.4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: selectedTool == -1 ? Colors.white : floorPalette[selectedTool],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black38),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedTool == -1
                          ? 'Modo Borrador: toca o desliza para limpiar cuadros'
                          : (selectedTool == 0
                              ? 'Negro: ${curInfo?['label'] ?? 'Paredes / Áreas segmentadas'}'
                              : 'Carga: ${curInfo?['label'] ?? ''}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                    ),
                    Text(
                      selectedTool >= 0 && (curInfo?['notes'] ?? '').isNotEmpty
                          ? '${curInfo!['notes']} · Paredes: $wallCount · Carga: $loadCount cuadros'
                          : 'Plano 20×30 · Paredes: $wallCount · Carga: $loadCount cuadros',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              if (selectedTool >= 0)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: brandRed,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.edit_rounded, size: 15),
                  label: const Text('Nombre', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  onPressed: () => _editLegend(selectedTool),
                ),
            ],
          ),
        ),

        // Área principal del Plano 20x30 con Zoom (InteractiveViewer) y pintado táctil
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cardBorderWarm, width: 1.5),
              boxShadow: const [
                BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                transformationController: zoomCtrl,
                minScale: 1.0,
                maxScale: 5.0,
                panEnabled: !paintMode,
                scaleEnabled: true,
                boundaryMargin: const EdgeInsets.all(24),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: cols / rows, // 20 columnas x 30 filas
                    child: LayoutBuilder(
                      builder: (ctx, box) {
                        final cellW = box.maxWidth / cols;
                        final cellH = box.maxHeight / rows;

                        void handleTouch(Offset localPos) {
                          if (!paintMode) return;
                          final cIdx = (localPos.dx / cellW).floor();
                          final rIdx = (localPos.dy / cellH).floor();
                          _applyCell(rIdx, cIdx);
                        }

                        return GestureDetector(
                          onTapDown: paintMode ? (d) => handleTouch(d.localPosition) : null,
                          onPanStart: paintMode ? (d) => handleTouch(d.localPosition) : null,
                          onPanUpdate: paintMode ? (d) => handleTouch(d.localPosition) : null,
                          child: CustomPaint(
                            size: Size(box.maxWidth, box.maxHeight),
                            painter: _FloorGridPainter(
                              rows: rows,
                              cols: cols,
                              cells: cells,
                              palette: floorPalette,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FloorGridPainter extends CustomPainter {
  final int rows;
  final int cols;
  final Map<int, int> cells;
  final List<Color> palette;

  _FloorGridPainter({
    required this.rows,
    required this.cols,
    required this.cells,
    required this.palette,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / cols;
    final cellH = size.height / rows;

    // Fondo blanco limpio
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.white,
    );

    // Pintar celdas coloreadas y paredes negras
    final fillPaint = Paint()..style = PaintingStyle.fill;
    cells.forEach((key, colorIdx) {
      if (colorIdx < 0 || colorIdx >= palette.length) return;
      final r = key ~/ cols;
      final c = key % cols;
      fillPaint.color = palette[colorIdx];
      canvas.drawRect(
        Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH),
        fillPaint,
      );
    });

    // Líneas de cuadrícula finas
    final gridPaint = Paint()
      ..color = const Color(0xFFE0D6CF)
      ..strokeWidth = 0.6;

    for (int c = 0; c <= cols; c++) {
      final x = c * cellW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (int r = 0; r <= rows; r++) {
      final y = r * cellH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Líneas guía cada 5 cuadros para orientarse mejor al hacer zoom
    final guidePaint = Paint()
      ..color = const Color(0xFFBDB0A8)
      ..strokeWidth = 1.0;

    for (int c = 5; c < cols; c += 5) {
      final x = c * cellW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), guidePaint);
    }
    for (int r = 5; r < rows; r += 5) {
      final y = r * cellH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guidePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FloorGridPainter oldDelegate) => true;
}

// ================= RESUMEN =================
Widget kpiCard(String t, String v, IconData icon, Color accent) => Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(v, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: accent)),
                  Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );

class DashPage extends StatelessWidget {
  const DashPage({super.key});
  @override
  Widget build(BuildContext c) => futs([
        recs(),
        q("SELECT (SELECT COUNT(*) FROM workers WHERE active=1) AS w,(SELECT COUNT(*) FROM attendance WHERE date=? AND status IN ('Presente','Atraso')) AS p,(SELECT COUNT(*) FROM pending WHERE done=0) AS pe", [today()]),
        q('SELECT * FROM compactions ORDER BY start DESC'),
        otPending(),
      ], (res) {
        final rs = res[0], a = res[1].first, prod = res[2], ot = res[3];
        final month = DateTime.now().toIso8601String().substring(0, 7);
        final mr = rs.where((r) => '${r['arrived']}'.startsWith(month)).toList();
        double sum(Iterable<R> l, String k) => l.fold(0.0, (x, e) => x + n(e[k]));
        final pend = rs.where((r) => r['status'] == 'pendiente').toList();
        final done = rs.where((r) => r['status'] == 'completada').toList();
        final exp = pend.where((r) => remaining(r).isNegative).toList();
        final near = pend.where((r) => !remaining(r).isNegative && remaining(r).inHours <= 24).toList();
        final net = sum(done, 'kg') - sum(done, 'waste');

        final alerts = <(Color, String, R)>[];
        for (final r in rs) {
          if (r['status'] == 'pendiente') {
            if (remaining(r).isNegative) {
              alerts.add((brandRed, 'Superó las 72 h (${rem(r)})', r));
            } else if (remaining(r).inHours <= 24) {
              alerts.add((brandOrange, 'Vence en ${remaining(r).inHours} h', r));
            } else {
              alerts.add((brandOrangeSoft, 'Pendiente de clasificar · ${rem(r)}', r));
            }
          } else {
            final s = n(r['kg']) - n(r['waste']) - n(r['compacted']);
            if (s > 0.001) alerts.add((Colors.deepOrange, 'Saldo sin producir: ${dotNum(s)} kg', r));
          }
        }
        alerts.sort((x, y) => '${x.$3['arrived']}'.compareTo('${y.$3['arrived']}'));

        final byOp = <String, List<double>>{};
        for (final e in prod) {
          final l = byOp.putIfAbsent('${e['operator']}', () => [0, 0, 0, 0]);
          if (e['kind'] == 'conos') {
            l[2] += n(e['bales']);
            l[3] += n(e['minutes']);
          } else {
            l[0] += n(e['bales']);
            l[1] += n(e['minutes']);
          }
        }
        final pacas = prod.where((e) => e['kind'] != 'conos').toList();

        final kpis = <Widget>[
          kpiCard('Trabajadores', '${a['w']}', Icons.groups_rounded, brandRedDark),
          kpiCard('Presentes hoy', '${a['p']}', Icons.how_to_reg_rounded, brandOrange),
          kpiCard('Recepciones del mes', '${mr.length}', Icons.local_shipping_rounded, brandRed),
          kpiCard('Kg recibidos (mes)', dotNum(sum(mr, 'kg'), dec: 0), Icons.scale_rounded, brandOrange),
          kpiCard('Pendientes clasificar', '${pend.length}', Icons.hourglass_bottom_rounded, brandOrangeSoft),
          kpiCard('Próximas a vencer', '${near.length}', Icons.notification_important_rounded, brandOrange),
          kpiCard('Vencidas (+72 h)', '${exp.length}', Icons.error_rounded, brandRed),
          kpiCard('Clasificadas', '${done.length}', Icons.verified_rounded, Colors.deepOrange),
          kpiCard('Total mermas kg', dotNum(sum(rs, 'waste')), Icons.delete_sweep_rounded, brandRedDark),
          kpiCard('Neto aprovechable kg', dotNum(net), Icons.eco_rounded, brandOrange),
          kpiCard('Kg producidos', dotNum(sum(rs, 'compacted')), Icons.precision_manufacturing_rounded, brandRed),
          kpiCard('Pacas', '${sum(pacas, 'bales').toInt()}', Icons.inventory_2_rounded, brandOrange),
          kpiCard('Pendientes (tareas)', '${a['pe']}', Icons.checklist_rounded, brandRed),
        ];

        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 36),
          children: [
            SizedBox(
              height: 152,
              child: GridView.count(
                scrollDirection: Axis.horizontal,
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.42,
                children: kpis,
              ),
            ),
            sectionTitle('ALERTAS DE PRODUCCIÓN', icon: Icons.warning_amber_rounded),
            if (alerts.isEmpty && ot.isEmpty) const Card(margin: EdgeInsets.zero, child: ListTile(title: Text('Sin alertas'))),
            for (final e in ot) Card(margin: const EdgeInsets.symmetric(vertical: 5), color: const Color(0xFFFFEBEE), child: otTile(e)),
            for (final al in alerts)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  leading: Icon(Icons.warning_rounded, color: al.$1),
                  title: Text(recTitle(al.$3), style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(al.$2),
                  onTap: () => showRec(c, al.$3),
                ),
              ),
            sectionTitle('PRODUCCIÓN POR TRABAJADOR', icon: Icons.engineering_rounded),
            if (byOp.isEmpty) const Card(margin: EdgeInsets.zero, child: ListTile(title: Text('Sin registros de producción'))),
            for (final en in byOp.entries)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  title: Text(en.key, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(
                    '${en.value[0].toInt()} pacas · ${en.value[0] > 0 ? dotNum(en.value[1] / en.value[0]) : '0.0'} min/paca · ${dotNum(en.value[1] / 60)} h\nConos: ${en.value[2].toInt()} bolsas · ${dotNum(en.value[3] / 60)} h',
                    style: const TextStyle(height: 1.38),
                  ),
                  isThreeLine: true,
                ),
              ),
            sectionTitle('TIEMPO POR PACA (ÚLTIMAS)', icon: Icons.timer_rounded),
            for (final e in pacas.take(15))
              Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  dense: true,
                  title: Text('${e['code']} · ${e['operator']} · ${e['material'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(
                    '${'${e['start']}'.substring(0, 10)} · ${hm(e['start'])}–${hm(e['finish'])} · ${dotNum(n(e['minutes']), dec: 0)} min · ${n(e['bales']) > 0 ? dotNum(n(e['minutes']) / n(e['bales'])) : '-'} min por paca',
                  ),
                ),
              ),
          ],
        );
      });
}
