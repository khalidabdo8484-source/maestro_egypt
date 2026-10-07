import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(MaterialApp(debugShowCheckedModeBanner: false, home: SellemGameV2()));

class FloorData {
  String name; String shopEmoji; String orderEmoji; String orderName; Color color;
  FloorData(this.name, this.shopEmoji, this.orderEmoji, this.orderName, this.color);
}

class Obstacle {
  double x; double y; String emoji; String type; double speed; int lane;
  Obstacle({required this.x, required this.y, required this.emoji, required this.type, required this.speed, required this.lane});
}

class SellemGameV2 extends StatefulWidget { @override State<SellemGameV2> createState() => _SState(); }

class _SState extends State<SellemGameV2> {
  int lane = 1;
  List<Obstacle> obs = [];
  int floor = 1;
  int lives = 3;
  int score = 0;
  int highFloor = 1;
  bool playing = false;
  bool delivering = false;
  Timer? loop; Timer? spawn;
  Random r = Random();
  double speed = 0.018;
  int timeInFloor = 0;
  final AudioPlayer player = AudioPlayer();

  final floors = [
    FloorData("بقالة الحاج", "🥖", "🥖", "عيش", Color(0xFFFDE68A)),
    FloorData("كلب الحراسة", "🦴", "🦴", "عظمة للكلب", Color(0xFFFECACA)),
    FloorData("غسيل أم أحمد", "👕", "🧷", "مشبك", Color(0xFFBFDBFE)),
    FloorData("قهوة المعلم", "☕", "☕", "شاي", Color(0xFFD6C7B8)),
    FloorData("خضري عم عبده", "🍅", "🍅", "طماطم", Color(0xFFBBF7D0)),
    FloorData("دش و تليفزيون", "📺", "🔋", "حجارة", Color(0xFFE9D5FF)),
    FloorData("مسحوق غسيل", "🧼", "🧼", "اريال", Color(0xFFA7F3D0)),
    FloorData("عطار", "🌶️", "🌶️", "شطة", Color(0xFFFDBA74)),
    FloorData("صبار", "🌵", "💧", "مية للصبار", Color(0xFF86EFAC)),
    FloorData("عشة الحمام", "🕊️", "🌾", "قمح للحمام", Color(0xFF93C5FD)),
  ];

  Future<void> playSound(String file) async {
    try { await player.play(AssetSource('sounds/$file')); } catch(e){ /* لو مفيش ملفات هيعمل هزاز بس */ }
  }

  void start(){
    lane=1; obs.clear(); floor=1; lives=3; score=0; timeInFloor=0; speed=0.018; playing=true; delivering=false;
    loadHigh();
    loop?.cancel(); spawn?.cancel();
    loop = Timer.periodic(Duration(milliseconds: 16), (t){
      if(!playing || delivering) return;
      setState((){
        timeInFloor++;
        for(var o in obs) o.y += o.speed;
        obs.removeWhere((o)=> o.y > 1.2);
        obs.removeWhere((o){
          bool hit = o.lane == lane && o.y > 0.65 && o.y < 0.9;
          if(hit){
            if(o.type=="heart"){ lives=(lives+1).clamp(0,5); score+=20; playSound('ding.mp3'); HapticFeedback.mediumImpact(); }
            else {
              lives--; 
              if(o.emoji=="🐕") playSound('bark.mp3');
              else if(o.emoji=="🪣") playSound('splash.mp3');
              else if(o.emoji=="👶") playSound('baby.mp3');
              else HapticFeedback.heavyImpact();
            }
            return true;
          }
          return false;
        });
        if(timeInFloor > 400){ startDelivery(); }
        if(lives<=0) gameOver();
      });
    });
    spawn = Timer.periodic(Duration(milliseconds: 750), (t){
      if(!playing || delivering) return;
      int l = r.nextInt(3);
      String emoji = "🐕"; String type="bad";
      double rr = r.nextDouble();
      if(rr < 0.3) emoji="🐕";
      else if(rr < 0.5) emoji="🪣";
      else if(rr < 0.65) emoji="👕";
      else if(rr < 0.75) emoji="👶";
      else if(rr < 0.85) { emoji="❤️"; type="heart"; }
      else emoji="🧹";
      setState(()=> obs.add(Obstacle(x: -0.7 + l*0.7, y: -1.2, emoji: emoji, type: type, speed: speed + r.nextDouble()*0.012, lane: l)));
    });
  }

  void startDelivery() async {
    delivering = true;
    await playSound('ding.mp3');
    setState((){ score+=100; });
    await Future.delayed(Duration(milliseconds: 1200));
    if(!playing) return;
    setState((){
      // لو وصلت ومعاك الأوردر الصح
      score+=200; // بونص المحل
      floor++;
      timeInFloor=0;
      speed+=0.004;
      obs.clear();
      delivering=false;
      if(floor>10) win();
    });
  }

  void gameOver(){ playing=false; delivering=false; loop?.cancel(); spawn?.cancel(); saveHigh(); }
  void win(){ playing=false; delivering=false; loop?.cancel(); spawn?.cancel(); score+=500; saveHigh(); }
  Future<void> loadHigh() async { var p=await SharedPreferences.getInstance(); setState(()=> highFloor = p.getInt('highFloor')??1); }
  Future<void> saveHigh() async { var p=await SharedPreferences.getInstance(); if(floor>highFloor){ p.setInt('highFloor', floor); setState(()=> highFloor=floor); } }

  @override Widget build(BuildContext context){
    double stairLeft(int l) => -0.75 + l*0.75;
    var cur = floors[(floor-1).clamp(0,9)];
    return Scaffold(
      backgroundColor: cur.color,
      body: GestureDetector(
        onTapDown: (d){ if(!playing) return; if(d.localPosition.dx < MediaQuery.of(context).size.width/2) setState(()=> lane=(lane-1).clamp(0,2)); else setState(()=> lane=(lane+1).clamp(0,2)); },
        child: Stack(children: [
          // خلفية
          Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [cur.color, Colors.white]))),
          Align(alignment: Alignment(0,0), child: Container(width: 320, height: double.infinity, decoration: BoxDecoration(color: Color(0xFFE7C9A9)), child: CustomPaint(painter: StairsPainter()))),
          if(playing) ...obs.map((o)=> Align(alignment: Alignment(stairLeft(o.lane), o.y), child: Text(o.emoji, style: TextStyle(fontSize: 34, shadows: [Shadow(blurRadius: 4, color: Colors.black26)])))),
          Align(alignment: Alignment(stairLeft(lane), 0.8), child: AnimatedScale(scale: delivering?1.3:1.0, duration: Duration(milliseconds: 200), child: Column(mainAxisSize: MainAxisSize.min, children: [
            if(delivering) Container(padding: EdgeInsets.symmetric(horizontal:8, vertical:2), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)), child: Text('وصلت! ${cur.orderEmoji}', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
            Text('🧑‍🍳', style: TextStyle(fontSize: 50)),
            Container(padding: EdgeInsets.all(3), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all()), child: Text(cur.orderEmoji, style: TextStyle(fontSize: 16))),
          ]))),
          SafeArea(child: Column(children: [
            Container(margin: EdgeInsets.all(12), padding: EdgeInsets.all(14), decoration: BoxDecoration(color: Color(0xFF111827), borderRadius: BorderRadius.circular(18)), child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${cur.shopEmoji} ${cur.name}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('الدور $floor / 10 - وصل: ${cur.orderName} ${cur.orderEmoji}', style: TextStyle(color: Colors.white60, fontSize: 11)),
                ]),
                Column(children: [Row(children: List.generate(3, (i)=> Icon(Icons.favorite, color: i<lives?Colors.red:Colors.white10, size: 18))), Text('⭐ $score', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))]),
              ]),
              SizedBox(height:8),
              LinearProgressIndicator(value: timeInFloor/400, color: Colors.amber, backgroundColor: Colors.white12, minHeight: 6, borderRadius: BorderRadius.circular(10)),
            ])),
            if(delivering) Container(margin: EdgeInsets.only(top:20), padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check, color: Colors.white), SizedBox(width:6), Text('بتسلم الأوردر لـ ${cur.name}...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])),
            Spacer(),
            if(!playing) Container(margin: EdgeInsets.all(16), padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(blurRadius: 20, color: Colors.black26)]), child: Column(children: [
              Text(floor>10?'🎉 خلصت العمارة!':'🏢 السلم والدور V2', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              SizedBox(height:8),
              Text(floor>10?'انت بطل التوصيل في المنطقة!':'كل دور محل حقيقي ولازم توصل طلبه\n🐕 ادي الكلب عظمة\n🪣 خلي بالك من جردل المية\n👶 متخبطش العيال', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, height: 1.4)),
              SizedBox(height:14),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: start, style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Text(floor>10?'العب تاني':'اطلع يا بطل 🚀', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))),
            ])),
          ])),
        ]),
      ),
    );
  }
}

class StairsPainter extends CustomPainter {
  @override void paint(Canvas c, Size s){ var p=Paint()..color=Colors.black.withOpacity(0.1)..strokeWidth=1.5..style=PaintingStyle.stroke; for(double y=0; y<s.height; y+=45) c.drawLine(Offset(0,y), Offset(s.width,y), p); c.drawLine(Offset(s.width/3,0), Offset(s.width/3,s.height), p); c.drawLine(Offset(s.width*2/3,0), Offset(s.width*2/3,s.height), p); }
  @override bool shouldRepaint(covariant CustomPainter old)=> false;
}
