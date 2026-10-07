import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: BuildingGame()));
}

class ObstacleItem {
  int lane; double y; IconData icon; Color color; String type; double speed;
  ObstacleItem({required this.lane, required this.y, required this.icon, required this.color, required this.type, required this.speed});
}

class BuildingGame extends StatefulWidget {
  const BuildingGame({super.key});
  @override
  State<BuildingGame> createState() => _BState();
}

class _BState extends State<BuildingGame> {
  int lane = 1;
  List<ObstacleItem> obstacles = [];
  int floor = 1;
  int lives = 3;
  int score = 0;
  bool playing = false;
  bool delivering = false;
  Timer? gameLoop;
  Timer? spawnLoop;
  Random rand = Random();
  double baseSpeed = 0.006;
  int floorTimer = 0;

  final floorData = [
    {"name": "بقالة الحاج", "order": "عيش"},
    {"name": "كلب الحراسة", "order": "عظمة"},
    {"name": "غسيل ام احمد", "order": "مشبك"},
    {"name": "قهوة المعلم", "order": "شاي"},
    {"name": "خضري عم عبده", "order": "طماطم"},
    {"name": "دش", "order": "حجارة"},
    {"name": "مسحوق", "order": "اريال"},
    {"name": "عطار", "order": "شطة"},
    {"name": "صبار", "order": "مية"},
    {"name": "عشة الحمام", "order": "قمح"},
  ];

  void startGame() {
    lane = 1;
    obstacles.clear();
    floor = 1;
    lives = 3;
    score = 0;
    floorTimer = 0;
    baseSpeed = 0.006;
    playing = true;
    delivering = false;
    gameLoop?.cancel();
    spawnLoop?.cancel();
    gameLoop = Timer.periodic(const Duration(milliseconds: 20), (t) {
      if (!playing || delivering) return;
      setState(() {
        floorTimer++;
        for (var o in obstacles) { o.y += o.speed; }
        obstacles.removeWhere((o) => o.y > 1.3);
        obstacles.removeWhere((o) {
          bool hit = o.lane == lane && o.y > 0.6 && o.y < 0.92;
          if (hit) {
            if (o.type == "heart") { lives = lives + 1; if(lives>5) lives=5; score += 30; }
            else { lives--; }
            return true;
          }
          return false;
        });
        if (floorTimer > 500) { doDelivery(); }
        if (lives <= 0) { endGame(); }
      });
    });
    spawnLoop = Timer.periodic(const Duration(milliseconds: 1400), (t) {
      if (!playing || delivering) return;
      int l = rand.nextInt(3);
      IconData ic = Icons.pets;
      Color col = Colors.brown;
      String type = "bad";
      double rr = rand.nextDouble();
      if (rr < 0.25) { ic = Icons.pets; col = Colors.brown; }
      else if (rr < 0.45) { ic = Icons.water_drop; col = Colors.blue; }
      else if (rr < 0.65) { ic = Icons.child_care; col = Colors.orange; }
      else if (rr < 0.78) { ic = Icons.cleaning_services; col = Colors.grey; }
      else { ic = Icons.favorite; col = Colors.red; type = "heart"; }
      setState(() {
        obstacles.add(ObstacleItem(lane: l, y: -1.2, icon: ic, color: col, type: type, speed: baseSpeed + rand.nextDouble() * 0.004));
      });
    });
  }

  void doDelivery() async {
    setState(() { delivering = true; });
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!playing) return;
    setState(() {
      score += 150;
      floor++;
      floorTimer = 0;
      obstacles.clear();
      baseSpeed += 0.001;
      delivering = false;
      if (floor > 10) { winGame(); }
    });
  }

  void endGame() { setState((){ playing = false; delivering = false; }); gameLoop?.cancel(); spawnLoop?.cancel(); }
  void winGame() { setState((){ playing = false; delivering = false; }); score += 500; gameLoop?.cancel(); spawnLoop?.cancel(); }

  @override
  Widget build(BuildContext context) {
    var curFloor = floorData[(floor - 1).clamp(0, 9)];
    List<Widget> stackChildren = [];

    stackChildren.add(Center(child: Container(width: 340, height: double.infinity, color: const Color(0xFFD2B48C), child: Column(children: List.generate(10, (index) {
      int f = 10 - index;
      bool isCurrent = f == floor;
      return Expanded(child: Container(decoration: BoxDecoration(color: isCurrent ? Colors.amber.shade100 : const Color(0xFFD2B48C), border: Border(top: BorderSide(color: Colors.brown.shade400, width: 2))), child: Row(children: [
        Container(width: 40, color: Colors.brown.shade200, child: Center(child: Text('$f', style: const TextStyle(fontWeight: FontWeight.bold)))),
        Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Icon(Icons.window, color: Colors.lightBlue.shade800, size: 22),
          Container(width: 36, height: 30, decoration: BoxDecoration(color: Colors.brown.shade700, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))), child: const Icon(Icons.door_front_door, color: Colors.black54, size: 20)),
          const Icon(Icons.balcony, color: Colors.white70, size: 22),
        ])),
      ])));
    })))));

    for (var o in obstacles) {
      double xPos = -0.6 + o.lane * 0.6;
      stackChildren.add(Align(alignment: Alignment(xPos, o.y), child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)]), child: Icon(o.icon, color: o.color, size: 28))));
    }

    stackChildren.add(Align(alignment: Alignment(-0.6 + lane * 0.6, 0.82), child: Column(mainAxisSize: MainAxisSize.min, children: [
      if (delivering) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)), child: const Text('وصلت!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(width: 2, color: Colors.black)), child: Icon(Icons.delivery_dining, size: 36, color: Colors.orange.shade800)),
      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)), child: Text(curFloor["order"]!, style: const TextStyle(color: Colors.white, fontSize: 10))),
    ])));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF87CEEB), Color(0xFFE0F6FF)])),
        child: Stack(children: stackChildren + [
          SafeArea(child: Column(children: [
            Container(margin: const EdgeInsets.all(12), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(18)), child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(curFloor["name"]!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('الدور $floor / 10 - وصل: ${curFloor["order"]}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ]),
                Column(children: [
                  Row(children: List.generate(3, (i) => Icon(Icons.favorite, color: i < lives ? Colors.red : Colors.white12, size: 20))),
                  Text('$score نقطة', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                ]),
              ]),
              const SizedBox(height: 10),
              ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: floorTimer / 500, color: Colors.amber, backgroundColor: Colors.white12, minHeight: 8)),
            ])),
            const Spacer(),
            if (!playing) Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)), child: Column(children: [
              const Icon(Icons.apartment, size: 40, color: Colors.brown),
              const SizedBox(height: 8),
              Text(floor > 10 ? 'خلصت العمارة! بطل!' : 'السلم والدور - عمارة حقيقية', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              SizedBox(height: 8),
              Text(floor > 10 ? 'جبت $score نقطة' : 'عمارة 10 ادوار بجد\nكل دور باب وشباك\nاتحرك يمين وشمال\nابعد عن الكلاب والميه', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, height: 1.5)),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: startGame, style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Text(floor > 10 ? 'العب تاني' : 'ابدأ الطلوع', style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)))),
            ])),
            if (playing) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: Row(children: [
              Expanded(child: ElevatedButton(onPressed: () => setState(() { if(lane>0) lane--; }), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.all(18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Icon(Icons.arrow_back, color: Colors.black, size: 30))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () => setState(() { if(lane<2) lane++; }), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.all(18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Icon(Icons.arrow_forward, color: Colors.black, size: 30))),
            ])),
          ])),
        ]),
      ),
    );
  }
}
