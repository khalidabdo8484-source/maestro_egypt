import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

void main() => runApp(MaterialApp(debugShowCheckedModeBanner: false, home: BillApp()));

class BillApp extends StatefulWidget { @override State<BillApp> createState() => _BillState(); }

class _BillState extends State<BillApp> {
  final kwhCtrl = TextEditingController(text: '200');
  final amountCtrl = TextEditingController(text: '500');
  Map<String, dynamic>? result;
  Map<String, dynamic>? resultFromMoney;
  bool scanning = false;
  bool isCardMode = true; // true = عداد كارت
  final picker = ImagePicker();
  final textRec = TextRecognizer(script: TextRecognitionScript.latin);

  Map<String,dynamic> calc(double c){
    double t=0,s=0; String sh='';
    if(c<=50){t=c*0.68; sh='الأولى (موفر)'; s=1;}
    else if(c<=100){t=50*0.68+(c-50)*0.78; sh='الثانية (موفر)'; s=2;}
    else if(c<=200){t=c*0.95; sh='الثالثة'; s=6;}
    else if(c<=350){t=200*0.95+(c-200)*1.55; sh='الرابعة'; s=11;}
    else if(c<=650){t=200*0.95+150*1.55+(c-350)*1.95; sh='الخامسة'; s=15;}
    else if(c<=1000){t=200*0.95+150*1.55+300*1.95+(c-650)*2.10; sh='السادسة (عالي)'; s=25;}
    else {t=c*2.23; sh='السابعة (خراب بيوت)'; s=40;}
    double nf = c<=200?3:c<=650?5:10;
    return {'kwh':c,'energy':t,'service':s,'nzafa':nf,'total':t+s+nf,'shariha':sh};
  }

  // يحسب كام كيلو هتاخد بفلوس معينة
  double calcKwhFromMoney(double money){
    // بنجرب من 1 لحد 2000 كيلو
    for(int i=1;i<2000;i++){
      if(calc(i.toDouble())['total'] >= money) return i.toDouble();
    }
    return money / 2.23;
  }

  void doCalc(){
    double c = double.tryParse(kwhCtrl.text)??0;
    setState(()=>result=calc(c));
    double m = double.tryParse(amountCtrl.text)??0;
    if(m>0){
      setState(()=>resultFromMoney={'money':m,'kwh':calcKwhFromMoney(m)});
    }
  }

  Future<void> pickImage() async {
    final XFile? img = await picker.pickImage(source: ImageSource.camera);
    if(img==null) return;
    setState(()=>scanning=true);
    try{
      final input = InputImage.fromFilePath(img.path);
      final rec = await textRec.processImage(input);
      String all = rec.text.replaceAll(RegExp(r'[^0-9.]'), ' ');
      var nums = all.split(' ').where((e)=>e.length>=1 && e.length<=6).map((e)=>double.tryParse(e)).whereType<double>().toList();
      nums.sort();
      if(nums.isNotEmpty){
        setState(()=>kwhCtrl.text = nums.last.toInt().toString());
        doCalc();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('قرأت: ${nums.last.toInt()} ك.و.س'), backgroundColor: Colors.green));
      }
    }catch(e){}
    setState(()=>scanning=false);
  }

  @override void initState(){ super.initState(); doCalc(); }
  @override void dispose(){ textRec.close(); super.dispose(); }

  @override Widget build(BuildContext c){
    return Scaffold(
      backgroundColor: Color(0xFF0F172A),
      appBar: AppBar(backgroundColor: Colors.black, centerTitle: true, title: Text('⚡ عداد الكارت', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))),
      body: ListView(padding: EdgeInsets.all(16), children: [
        // خانة الاستهلاك بالكاميرا
        Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)), child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('الاستهلاك هذا الشهر (ك.و.س)', style: TextStyle(color: Colors.white70)),
            Icon(Icons.credit_card, color: Colors.amber)
          ]),
          SizedBox(height:10),
          TextField(controller: kwhCtrl, keyboardType: TextInputType.number, onChanged: (_)=>doCalc(), style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), decoration: InputDecoration(
            hintText: 'مثال: 200',
            hintStyle: TextStyle(color: Colors.white24),
            suffixIcon: IconButton(icon: Icon(Icons.camera_alt, color: Colors.amber, size: 28), onPressed: pickImage),
            filled: true, fillColor: Colors.black26, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
          )),
          SizedBox(height:12),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: doCalc, style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: EdgeInsets.all(14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(scanning?'بقرأ العداد...':'احسب الفاتورة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)))),
        ])),

        if(result!=null) ...[
          SizedBox(height:16),
          Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]), borderRadius: BorderRadius.circular(16)), child: Column(children: [
            Text('هتدفع', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
            Text('${result!['total'].toStringAsFixed(2)} جنيه', style: TextStyle(color: Colors.black, fontSize: 36, fontWeight: FontWeight.w900)),
            Container(margin: EdgeInsets.only(top:8), padding: EdgeInsets.symmetric(horizontal:14, vertical:6), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)), child: Text('الشريحة ${result!['shariha']}', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))),
            SizedBox(height:10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              Text('طاقة: ${result!['energy'].toStringAsFixed(0)}ج', style: TextStyle(color: Colors.black87)),
              Text('خدمة: ${result!['service']}ج', style: TextStyle(color: Colors.black87)),
              Text('نظافة: ${result!['nzafa']}ج', style: TextStyle(color: Colors.black87)),
            ])
          ])),
        ],

        SizedBox(height:16),
        // ميزة الكارت - اشحن بكام يديك كام كيلو
        Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.amber.withOpacity(0.3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('💳 لو هتشحن بكام؟', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          SizedBox(height:10),
          Row(children: [
            Expanded(child: TextField(controller: amountCtrl, keyboardType: TextInputType.number, onChanged: (_)=>doCalc(), style: TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'المبلغ جنيه', labelStyle: TextStyle(color: Colors.white54), filled: true, fillColor: Colors.black26, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)))),
            SizedBox(width:10),
            if(resultFromMoney!=null) Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: Text('≈ ${resultFromMoney!['kwh'].toInt()} كيلو', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)))
          ])
        ]))
      ]),
    );
  }
}
