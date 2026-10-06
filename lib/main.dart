import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(debugShowCheckedModeBanner: false, home: BillApp(), theme: ThemeData(fontFamily: 'Cairo')));

class BillApp extends StatefulWidget { @override State<BillApp> createState() => _BillState(); }

class _BillState extends State<BillApp> {
  final currCtrl = TextEditingController(text: '350');
  final prevCtrl = TextEditingController(text: '150');
  double kwh = 200;
  Map<String, dynamic>? result;

  // أسعار 2024-2025 الرسمية للكهرباء المنزلي
  final tiers = [
    {'from':0,'to':50,'price':0.68,'service':1.0},
    {'from':51,'to':100,'price':0.78,'service':2.0},
    {'from':0,'to':200,'price':0.95,'service':6.0},
    {'from':201,'to':350,'price':1.55,'service':11.0},
    {'from':351,'to':650,'price':1.95,'service':15.0},
    {'from':651,'to':1000,'price':2.10,'service':25.0},
    {'from':1001,'to':999999,'price':2.23,'service':40.0},
  ];

  Map<String,dynamic> calc(double consumption){
    double total = 0;
    String shariha = '';
    double service = 0;
    if(consumption <= 50){ total = consumption * 0.68; shariha='الأولى'; service=1; }
    else if(consumption <= 100){ total = 50*0.68 + (consumption-50)*0.78; shariha='الثانية'; service=2; }
    else if(consumption <= 200){ total = consumption * 0.95; shariha='الثالثة (0-200)'; service=6; }
    else if(consumption <= 350){ total = 200*0.95 + (consumption-200)*1.55; shariha='الرابعة'; service=11; }
    else if(consumption <= 650){ total = 200*0.95 + 150*1.55 + (consumption-350)*1.95; shariha='الخامسة'; service=15; }
    else if(consumption <= 1000){ total = 200*0.95 + 150*1.55 + 300*1.95 + (consumption-650)*2.10; shariha='السادسة'; service=25; }
    else { total = consumption * 2.23; shariha='السابعة - فوق 1000'; service=40; }
    
    double nzafa = consumption <= 650 ? (consumption <= 200 ? 3 : 5) : 10;
    double finalTotal = total + service + nzafa;

    return {'kwh':consumption, 'energy':total, 'service':service, 'nzafa':nzafa.toDouble(), 'total':finalTotal, 'shariha':shariha};
  }

  void doCalc(){
    double curr = double.tryParse(currCtrl.text) ?? 0;
    double prev = double.tryParse(prevCtrl.text) ?? 0;
    double cons = (curr - prev).abs();
    if(cons == 0) cons = curr; // لو كتب الاستهلاك مباشر
    setState((){ kwh = cons; result = calc(cons); });
  }

  @override void initState(){ super.initState(); doCalc(); }

  @override Widget build(BuildContext c){
    return Scaffold(
      backgroundColor: Color(0xFF0F172A),
      appBar: AppBar(backgroundColor: Colors.black, centerTitle: true, title: Text('⚡ فاتورة العداد', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))),
      body: ListView(padding: EdgeInsets.all(16), children: [
        Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)), child: Column(children: [
          Row(children: [
            Expanded(child: _input('القراءة الحالية', currCtrl)),
            SizedBox(width: 12),
            Expanded(child: _input('القراءة السابقة', prevCtrl)),
          ]),
          SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: doCalc, style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: EdgeInsets.all(14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text('احسب الفاتورة 💡', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)))),
          if(kwh>0) Padding(padding: EdgeInsets.only(top:10), child: Text('الاستهلاك: ${kwh.toInt()} ك.و.س', style: TextStyle(color: Colors.white70)))
        ])),

        if(result != null) ...[
          SizedBox(height: 16),
          Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]), borderRadius: BorderRadius.circular(16)), child: Column(children: [
            Text('إجمالي الفاتورة', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
            SizedBox(height:4),
            Text('${result!['total'].toStringAsFixed(2)} جنيه', style: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.w900)),
            Container(margin: EdgeInsets.only(top:8), padding: EdgeInsets.symmetric(horizontal:12, vertical:6), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)), child: Text('الشريحة ${result!['shariha']}', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))),
          ])),
          SizedBox(height:12),
          Row(children: [
            Expanded(child: _detail('سعر الطاقة', '${result!['energy'].toStringAsFixed(2)} ج', Icons.bolt)),
            SizedBox(width:8),
            Expanded(child: _detail('خدمة عملاء', '${result!['service']} ج', Icons.support_agent)),
            SizedBox(width:8),
            Expanded(child: _detail('نظافة', '${result!['nzafa']} ج', Icons.cleaning_services)),
          ]),
          SizedBox(height:16),
          _tipBox(),
          SizedBox(height:12),
          Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('💡 ازاي توفر؟', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            SizedBox(height:8),
            Text(result!['kwh']>650 ? '• انت في شريحة عالية! قلل التكييف درجة واحدة هتوفر 150 جنيه\n• افصل السخان بعد ما يسخن' : result!['kwh']>350 ? '• قربت تدخل شريحة أعلى! قلل استهلاكك ${ (651-result!['kwh']).toInt()} كيلو عشان متدفعش زيادة\n• استخدم اللمبات الليد' : '• استهلاكك ممتاز! استمر كده وهتفضل في الشريحة الرخيصة', style: TextStyle(color: Colors.white70, height: 1.5)),
          ]))
        ]
      ]),
    );
  }

  Widget _input(String label, TextEditingController ctrl) => TextField(controller: ctrl, keyboardType: TextInputType.number, style: TextStyle(color: Colors.white), decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: Colors.white54, fontSize: 12), filled: true, fillColor: Colors.black26, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)));
  Widget _detail(String t, String v, IconData ic) => Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)), child: Column(children: [Icon(ic, color: Colors.amber, size: 20), SizedBox(height:6), Text(t, style: TextStyle(color: Colors.white54, fontSize:10)), Text(v, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize:13))]));
  Widget _tipBox() => Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: result!['kwh']>350 ? Colors.red.withOpacity(0.15) : Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: result!['kwh']>350 ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3))), child: Row(children: [Icon(result!['kwh']>350 ? Icons.warning : Icons.check_circle, color: result!['kwh']>350 ? Colors.red : Colors.green), SizedBox(width:8), Expanded(child: Text(result!['kwh']>350 ? 'استهلاك عالي! هتدفع كتير الشهر ده' : 'استهلاك اقتصادي برافو عليك', style: TextStyle(color: Colors.white))) ]));
}
