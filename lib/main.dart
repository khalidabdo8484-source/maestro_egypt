import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MaestroUltimate(),
    );
  }
}

class Scenario {
  String title, desc, icon;
  int cost, trafficReduce, co2Reduce, timeSave;
  Color color;
  Scenario(this.title, this.desc, this.icon, this.cost, this.trafficReduce,
      this.co2Reduce, this.timeSave, this.color);
}

class MaestroUltimate extends StatefulWidget {
  const MaestroUltimate({super.key});
  @override
  State<MaestroUltimate> createState() => _MaestroUltimateState();
}

class _MaestroUltimateState extends State<MaestroUltimate> {
  GoogleMapController? mapController;
  static const LatLng cairoCenter = LatLng(30.0444, 31.2357);
  Set<Polyline> polylines = {};
  Set<Marker> markers = {};
  String engineType = 'بنزين';
  double distanceKm = 18.5;
  double avgSpeed = 22;
  double density = 82;
  int selArea = 0;
  List<String> areas = ['القاهرة الكبرى', 'الاسكندرية', 'العين السخنة', 'الساحل'];
  Scenario? best;

  List<Scenario> scs = [
    Scenario('كوبري الرماية', 'كوبري 2 اتجاه عند الرماية', '🌉', 150, 35, 18, 20, Colors.blue),
    Scenario('توسعة الدائري', 'اضافة حارتين للدائري', '🛣️', 80, 25, 12, 15, Colors.orange),
    Scenario('مترو رابع', 'خط مترو جديد مدينة نصر', '🚇', 300, 50, 40, 35, Colors.green),
    Scenario('BRT ترددي', 'اتوبيس كهربا على الدائري', '🚌', 40, 30, 35, 18, Colors.purple),
    Scenario('نفق التحرير', 'نفق تحت ميدان التحرير', '🚧', 120, 28, 15, 22, Colors.red),
    Scenario('إشارة ذكية', 'إشارات AI تتأقلم', '🚦', 10, 15, 10, 10, Colors.teal),
  ];

  double get fuelConsumption {
    double base = engineType == 'بنزين'? 8.5 : engineType == 'ديزل'? 6.5 : engineType == 'هجين'? 4.5 : 0;
    double trafficFactor = avgSpeed < 20? 1.6 : avgSpeed < 40? 1.2 : 1.0;
    return base * trafficFactor;
  }

  double get co2Kg {
    if (engineType == 'كهربا') return distanceKm * 0.05;
    double emissionFactor = engineType == 'ديزل'? 2.68 : 2.31;
    double fuelUsed = (distanceKm * fuelConsumption / 100);
    return fuelUsed * emissionFactor;
  }

  double get fuelCost => (distanceKm * fuelConsumption / 100) * 11.5;
  double get dailyCo2Tons => co2Kg * 1200000 / 1000;
  double get fuelLoss => density * 1.2;

  @override
  void initState() {
    super.initState();
    _addTrafficPolylines();
    _addMarkers();
  }

  void _addTrafficPolylines() {
    polylines = {
      const Polyline(polylineId: PolylineId('ring_heavy'), points: [LatLng(30.1, 31.2), LatLng(30.05, 31.25), LatLng(30.0, 31.3)], color: Colors.red, width: 6),
      const Polyline(polylineId: PolylineId('nile_moderate'), points: [LatLng(30.06, 31.21), LatLng(30.03, 31.23)], color: Colors.orange, width: 6),
      const Polyline(polylineId: PolylineId('nasr_heavy'), points: [LatLng(30.07, 31.34), LatLng(30.05, 31.33)], color: Colors.red, width: 6),
      const Polyline(polylineId: PolylineId('october_light'), points: [LatLng(29.96, 30.92), LatLng(30.0, 31.0)], color: Colors.green, width: 6),
    };
  }

  void _addMarkers() {
    markers = {
      const Marker(markerId: MarkerId('tahrir'), position: LatLng(30.0444, 31.2357), infoWindow: InfoWindow(title: 'ميدان التحرير - زحمة خانقة 🔴')),
      const Marker(markerId: MarkerId('nasr'), position: LatLng(30.06, 31.34), infoWindow: InfoWindow(title: 'مدينة نصر - زحمة 🔴')),
      const Marker(markerId: MarkerId('newcairo'), position: LatLng(30.03, 31.47), infoWindow: InfoWindow(title: 'القاهرة الجديدة - فاضي 🟢')),
    };
  }

  void analyze() {
    var sorted = [...scs]..sort((a, b) => (b.trafficReduce + b.co2Reduce - b.cost / 20).compareTo(a.trafficReduce + a.co2Reduce - a.cost / 20));
    setState(() => best = sorted.first);
    showDialog(context: context, builder: (c) => AlertDialog(
      title: Text('🤖 توصية مايسترو: ${best!.title}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(best!.icon, style: const TextStyle(fontSize: 50)),
        Text(best!.desc, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10)), child: Column(children: [
          Text('يقلل الزحمة: ${best!.trafficReduce}%'),
          Text('يقلل CO2: ${best!.co2Reduce}% = ${(dailyCo2Tons * best!.co2Reduce / 100).toStringAsFixed(0)} طن/يوم'),
          Text('يوفر: ${best!.timeSave} دقيقة'),
          Text('التكلفة: ${best!.cost} مليون'),
          const Divider(),
          Text('هدر حالي: ${fuelLoss.toStringAsFixed(1)} مليون/يوم - CO2: ${dailyCo2Tons.toStringAsFixed(0)} طن/يوم', style: const TextStyle(fontSize: 10, color: Colors.red)),
        ])),
      ]),
      actions: [ElevatedButton(onPressed: ()=>Navigator.pop(c), child: const Text('اعتماد كمشروع قومي'))],
    ));
  }

  Widget chip(String t, Color c) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(12)), child: Text(t, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)));

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 4, child: Scaffold(backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(backgroundColor: Colors.black, title: const Text('🇪🇬 MAESTRO Egypt ULTIMATE + Maps', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)), bottom: const TabBar(isScrollable: true, tabs: [Tab(text: '🗺️ الخريطة الحية'), Tab(text: '💡 السيناريوهات'), Tab(text: '🌿 CO2'), Tab(text: '💰 التكلفة')], labelColor: Colors.amber, unselectedLabelColor: Colors.white70)),
      body: TabBarView(children: [
        Column(children: [
          SizedBox(height: 35, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: areas.length, itemBuilder: (c,i){ bool sel=i==selArea; return GestureDetector(onTap: ()=>setState(()=>selArea=i), child: Container(margin: const EdgeInsets.all(4), padding: const EdgeInsets.symmetric(horizontal:12), decoration: BoxDecoration(color: sel? Colors.amber:Colors.white24, borderRadius: BorderRadius.circular(20)), child: Center(child: Text(areas[i], style: TextStyle(fontSize:11, fontWeight: FontWeight.bold, color: sel? Colors.black:Colors.white))))); })),
          Expanded(flex:3, child: GoogleMap(initialCameraPosition: const CameraPosition(target: cairoCenter, zoom: 11), polylines: polylines, markers: markers, trafficEnabled: true, onMapCreated: (c)=> mapController=c)),
          Expanded(flex:2, child: Container(color: const Color(0xFF1E293B), padding: const EdgeInsets.all(8), child: ListView(children: [
            Row(children: [chip('🚗 ${distanceKm}كم', Colors.white24), const SizedBox(width:5), chip('⏱️ ${(distanceKm/avgSpeed*60).toStringAsFixed(0)}د', Colors.white24), const SizedBox(width:5), chip('⛽ ${fuelConsumption.toStringAsFixed(1)} ل/100', Colors.amber)]),
            const SizedBox(height:6),
            Row(children: ['بنزين','ديزل','هجين','كهربا'].map((e){ bool sel=engineType==e; return GestureDetector(onTap: ()=>setState(()=>engineType=e), child: Container(margin: const EdgeInsets.only(right:5, top:4), padding: const EdgeInsets.symmetric(horizontal:10, vertical:5), decoration: BoxDecoration(color: sel? Colors.green:Colors.white24, borderRadius: BorderRadius.circular(15)), child: Text(e, style: TextStyle(fontSize:10, color: sel? Colors.white:Colors.white70, fontWeight: FontWeight.bold)))); }).toList()),
            const SizedBox(height:6),
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('CO2 للرحلة:', style: TextStyle(fontSize:12)), Text('${co2Kg.toStringAsFixed(2)} كجم', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.red, fontSize:12))]),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('تكلفة:', style: TextStyle(fontSize:12)), Text('${fuelCost.toStringAsFixed(1)} جنيه', style: const TextStyle(fontWeight: FontWeight.bold, fontSize:12))]),
              Text('لو كهربا/BRT هتوفر ${(co2Kg*0.5).toStringAsFixed(1)} كجم CO2 (50% زي جوجل)', style: const TextStyle(fontSize:9, color: Colors.green, fontWeight: FontWeight.bold)),
            ])),
            const SizedBox(height:6),
            ElevatedButton(onPressed: analyze, style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, minimumSize: const Size(double.infinity, 35)), child: const Text('🤖 حلل بالذكاء الاصطناعي', style: TextStyle(color: Colors.black, fontSize:12, fontWeight: FontWeight.bold))),
          ]))),
        ]),
        ListView(padding: const EdgeInsets.all(8), children: scs.map((s)=>Card(color: best==s? Colors.amber[100]:Colors.white, child: ListTile(leading: Text(s.icon, style: const TextStyle(fontSize:28)), title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize:12)), subtitle: Text('${s.desc}\n💰 ${s.cost}م | 🚗 -${s.trafficReduce}% | 🌿 -${s.co2Reduce}% | ⏱️ -${s.timeSave}د', style: const TextStyle(fontSize:10)), trailing: IconButton(icon: const Icon(Icons.play_circle, size:28), onPressed: (){ setState(()=>best=s); analyze(); }), isThreeLine: true))).toList()),
        ListView(padding: const EdgeInsets.all(10), children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(gradient: const LinearGradient(colors:[Colors.green, Colors.teal]), borderRadius: BorderRadius.circular(10)), child: Column(children: [
            const Text('🌿 انبعاثات القاهرة - رؤية 2030', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height:8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Column(children:[Text(dailyCo2Tons.toStringAsFixed(0), style: const TextStyle(color:Colors.white, fontSize:24, fontWeight: FontWeight.bold)), const Text('طن CO2/يوم', style: TextStyle(color:Colors.white70, fontSize:9))]), Column(children:[Text('${(dailyCo2Tons*365/1000).toStringAsFixed(1)}k', style: const TextStyle(color:Colors.white, fontSize:20, fontWeight: FontWeight.bold)), const Text('الف طن/سنة', style: TextStyle(color:Colors.white70, fontSize:9))])]),
          ])),
          const SizedBox(height:8),
         ...scs.map((s)=>Card(child: ListTile(title: Text(s.title, style: const TextStyle(fontSize:11)), subtitle: LinearProgressIndicator(value: s.co2Reduce/50, color: Colors.green), trailing: Text('-${s.co2Reduce}% CO2', style: const TextStyle(color:Colors.green, fontWeight: FontWeight.bold, fontSize:11))))),
        ]),
        ListView(padding: const EdgeInsets.all(10), children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('💰 دراسة الجدوى', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('هدر يومي: ${fuelLoss.toStringAsFixed(1)} مليون جنيه - سنوي: ${(fuelLoss*365).toStringAsFixed(0)} مليون 😱', style: const TextStyle(color:Colors.red, fontWeight: FontWeight.bold, fontSize:11)),
            const Divider(),
           ...scs.map((s){ double roi = (fuelLoss*365 * s.trafficReduce/100) / s.cost; return ListTile(dense:true, title: Text(s.title, style: const TextStyle(fontSize:11)), subtitle: Text('يرجع في ${(s.cost/(fuelLoss*s.trafficReduce/100)).toStringAsFixed(1)} شهر - ROI ${roi.toStringAsFixed(1)}x', style: const TextStyle(fontSize:10)), trailing: Text(roi>5?'ممتاز 🟢': roi>2?'جيد 🟡':'ضعيف 🔴', style: const TextStyle(fontSize:10))); }),
          ])),
        ]),
      ]),
    ));
  }
