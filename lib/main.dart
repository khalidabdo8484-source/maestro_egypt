import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MaterialApp(debugShowCheckedModeBanner: false, home: BuildingGame()));

class ObstacleItem {
  int lane; double y; IconData icon; Color color; String type; double speed;
  ObstacleItem({required this.lane, required this.y, required this.icon, required this.color, required this.type, required this.speed});
}

class BuildingGame extends StatefulWidget { @override State<BuildingGame> createState() => _BState(); }

class _BState extends State<BuildingGame> {
  int lane = 1;
  List<ObstacleItem> obstacles = [];
  int floor = 1;
  int lives = 3;
  int score = 0;
  int bestFloor = 1;
  bool playing = false;
  bool delivering = false;
  Timer? gameLoop; Timer? spawnLoop;
  Random rand = Random();
  double baseSpeed = 0.008; // أبطأ بكتير من الأول كان 0.018
  int floorTimer = 0;

  final floorData = [
    {"name": "بقالة الحاج", "order": "عيش", "icon": Icons.bakery_dining},
    {"name": "كلب الحراسة", "order": "عظمة", "icon": Icons.pets},
    {"name": "غسيل أم أحمد", "order": "مشبك", "icon": Icons.checkroom},
    {"name": "قهوة المعلم", "order": "شاي", "icon": Icons.local_cafe},
    {"name": "خضري عم عبده", "order": "طماطم", "icon": Icons.shopping_basket},
    {"name": "دش", "order": "حجارة", "icon": Icons.tv},
    {"name": "مسحوق", "order": "اريال", "icon": Icons.local_laundry_service},
    {"name": "عطار", "order": "شطة", "icon": Icons.spa},
    {"name": "صبار", "order": "مية", "icon": Icons.water_drop},
    {"name": "عشة الحمام", "order": "قمح", "icon": Icons.egg},
  ];

  void startGame(){
    lane=1; obstacles.clear(); floor=1; lives=3; score=0; floorTimer=0; baseSpeed=0.008; playing=true; delivering=false;
    loadBest();
    gameLoop?.cancel(); spawnLoop?.cancel();
    gameLoop = Timer.periodic(Duration(milliseconds: 20), (t){
      if(!playing || delivering) return;
      setState((){
        floorTimer++;
        for(var o in obstacles) o.y += o.speed;
        obstacles.removeWhere((o)=> o.y > 1.3);
        // تصادم
        obstacles.removeWhere((o){
          bool hit = o.lane == lane && o.y > 0.6 && o.y < 0.92;
          if(hit){
            if(o.type=="heart"){ lives = (lives+1).clamp(0,5); score+=30; }
            else { lives--; }
            return true;
          }
          return false;
        });
        if(floorTimer > 500){ // كل دور بياخد وقت أطول
          doDelivery();
        }
        if(lives<=0) endGame();
      });
    });
    spawnLoop = Timer.periodic(Duration(milliseconds: 1300), (t){ // كان 750 بقى 1300 أبطأ
      if(!playing || delivering) return;
      int l = rand.nextInt(3);
      IconData ic = Icons.pets;
      Color col = Colors.brown;
      String type="bad";
      double rr = rand.nextDouble();
      if(rr < 0.25){ ic = Icons.pets; col=Colors.brown; }
      else if(rr < 0.45){ ic = Icons.water_drop; col=Colors.blue; }
      else if(rr < 0.65){ ic = Icons.child_care; col=Colors.orange; }
      else if(rr < 0.78){ ic = Icons.cleaning_services; col=Colors.grey; }
      else { ic = Icons.favorite; col=Colors.red; type="heart"; }
      setState(()=> obstacles.add(ObstacleItem(lane: l, y: -1.2, icon: ic, color: col, type: type, speed: baseSpeed + rand.nextDouble()*0.005)));
    });
  }

  Future<void> doDelivery() async {
    setState((){ delivering=true; });
    await Future.delayed(Duration(milliseconds: 1500));
    if(!playing) return;
    setState((){
      score+=150;
      floor++;
      floorTimer=0;
      obstacles.clear();
      baseSpeed += 0.0015; // بيزيد ببطء شديد
      delivering=false;
      if(floor>10) winGame();
    });
  }

  void endGame(){ playing=false; delivering=false; gameLoop?.cancel(); spawnLoop?.cancel(); saveBest(); }
  void winGame(){ playing=false; delivering=false; gameLoop?.cancel(); spawnLoop?.cancel(); score+=500; saveBest(); }
  Future<void> loadBest() async { var p=await SharedPreferences.getInstance(); setState(()=> bestFloor = p.getInt('best')??1); }
  Future<void> saveBest() async { var p=await SharedPreferences.getInstance(); if(floor>bestFloor){ p.setInt('best', floor); setState(()=> bestFloor=floor); } }

  @override Widget build(BuildContext context){
    var curFloor = floorData[(floor-1).clamp(0,9)];
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF87CEEB), Color(0xFFE0F6FF)])),
        child: Stack(children: [
          // العمارة الحقيقية
          Center(child: Container(width: 340, height: double.infinity, decoration: BoxDecoration(color: Color(0xFFD2B48C), border: Border(left: BorderSide(width:3, color: Colors.brown.shade300), right: BorderSide(width:3, color: Colors.brown.shade300))), child: Column(children: List.generate(10, (index){
            int f = 10-index;
            bool isCurrent = f==floor;
            return Expanded(child: Container(decoration: BoxDecoration(color: isCurrent? Colors.amber.shade100 : Color(0xFFD2B48C), border: Border(top: BorderSide(color: Colors.brown.shade400, width: 2))), child: Row(children: [
              Container(width: 40, color: Colors.brown.shade200, child: Center(child: Text('$f', style: TextStyle(fontWeight: FontWeight.bold)))),
              Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                Icon(Icons.window, color: Colors.lightBlue.shade800, size: 22),
                Container(width: 36, height: 30, decoration: BoxDecoration(color: Colors.brown.shade700, borderRadius: BorderRadius.vertical(top: Radius.circular(6))), child: Icon(Icons.door_front_door, color: Colors.black54, size: 20)),
                Icon(Icons.balcony, color: Colors.white70, size: 22),
              ])),
            ])));
          })))),
          // الممرات
          Center(child: Container(width: 300, child: Row(children: List.generate(3, (i)=> Expanded(child: Container(margin: EdgeInsets.symmetric(horizontal:4), decoration: BoxDecoration(border: Border.symmetric(vertical: BorderSide(color: Colors.white.withOpacity(0.3))))))))),
          // العوائق
          if(playing) ...obstacles.map((o){
            double xPos = -0.6 + o.lane*0.6;
            return Align(alignment: Alignment(xPos, o.y), child: Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)]), child: Icon(o.icon, color: o.color, size: 28)));
          }),
          // اللاعب - راجل توصيل
          Align(alignment: Alignment(-0.6 + lane*0.6, 0.82), child: Column(children: [
            if(delivering) Container(padding: EdgeInsets.symmetric(horizontal:10, vertical:4), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)), child: Text('وصلت!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
            Container(padding: EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(width:2, color: Colors.black)), child: Icon(Icons.delivery_dining, size: 36, color: Colors.orange.shade800)),
            Container(padding: EdgeInsets.symmetric(horizontal:6, vertical:2), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)), child: Text(curFloor["order"] as String, style: TextStyle(color: Colors.white, fontSize: 10))),
          ])),

          // UI فوق
          SafeArea(child: Column(children: [
            Container(margin: EdgeInsets.all(12), padding: EdgeInsets.all(14), decoration: BoxDecoration(color: Color(0xFF111827), borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)]), child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Icon(curFloor["icon"] as IconData, color: Colors.amber, size: 18), SizedBox(width:6), Text(curFloor["name"] as String, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]),
                  Text('الدور $floor / 10 - وصل: ${curFloor["order"]}', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ]),
                Column(children: [
                  Row(children: List.generate(3, (i)=> Icon(Icons.favorite, color: i<lives?Colors.red:Colors.white12, size: 20))),
                  Text('$score نقطة', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                ]),
              ]),
              SizedBox(height:10),
              ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: floorTimer/500, color: Colors.amber, backgroundColor: Colors.white12, minHeight: 8)),
            ])),
            if(delivering) Container(margin: EdgeInsets.only(top:16), padding: EdgeInsets.symmetric(horizontal:16, vertical:10), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(30)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle, color: Colors.white, size: 20), SizedBox(width:8), Text('بتسلم الأوردر لـ ${curFloor["name"]}...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])),
            Spacer(),
            if(!playing) Container(margin: EdgeInsets.all(16), padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(blurRadius: 20, color: Colors.black26)]), child: Column(children: [
              Icon(Icons.apartment, size: 40, color: Colors.brown),
              SizedBox(height:8),
              Text(floor>10?'خلصت العمارة! بطل!':'السلم والدور - عمارة حقيقية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              SizedBox(height:8),
              Text(floor>10?'جبت $score نقطة':'عمارة 10 أدوار بجد\nكل دور باب وشباك\nاتحرك يمين وشمال\nابعد عن الكلاب والميه', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, height: 1.5)),
              SizedBox(height:14),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: startGame, style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Text(floor>10?'العب تاني':'ابدأ الطلوع', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)))),
              SizedBox(height:6),
              Text('أعلى دور: $bestFloor', style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
            ])),
            if(playing) Padding(padding: EdgeInsets.fromLTRB(16,0,16,16), child: Row(children: [
              Expanded(child: ElevatedButton(onPressed: ()=> setState(()=> lane=(lane-1).clamp(0,2)), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, padding: EdgeInsets.all(18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: Icon(Icons.arrow_back, color: Colors.black, size: 30))),
              SizedBox(width:12),
              Expanded(child: ElevatedButton(onPressed: ()=> setState(()=> lane=(lane+1).clamp(0,2)), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, padding: EdgeInsets.all(18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: Icon(Icons.arrow_forward, color: Colors.black, size: 30))),
            ])),
          ])),
        ]),
      ),
    );
  }
}
