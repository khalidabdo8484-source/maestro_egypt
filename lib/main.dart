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

  Map<String, dynamic> getNextTier(double c){
    if(c <= 50) return {'next': 'الثانية', 'limit': 50, 'remain': 50 - c, 'priceNext': 0.78, 'priceNow': 0.68};
    if(c <= 100) return {'next': 'الثالثة', 'limit': 100, 'remain': 100 - c, 'priceNext': 0.95, 'priceNow': 0.78};
    if(c <= 200) return {'next': 'الرابعة', 'limit': 200, 'remain': 200 - c, 'priceNext': 1.55, 'priceNow': 0.95};
    if(c <= 350) return {'next': 'الخامسة', 'limit': 350, 'remain': 350 - c, 'priceNext': 1.95, 'priceNow': 1.55};
    if(c <= 650) return {'next': 'السادسة', 'limit': 650, 'remain': 650 - c, 'priceNext': 2.10, 'priceNow': 1.95};
    if(c <= 1000) return {'next': 'السابعة', 'limit': 1000, 'remain': 1000 - c, 'priceNext': 2.23, 'priceNow': 2.10};
    return {'next': 'الأخيرة', 'limit': 1000, 'remain': 0, 'priceNext': 2.23, 'priceNow': 2.23};
  }

  double calcKwhFromMoney(double money){
    for(int i=1;i<2000;i++){ if(calc(i.toDouble())['total'] >= money) return i.toDouble(); }
    return money / 2.23;
  }

  void doCalc(){
    double c = double.tryParse(kwhCtrl.text)??0;
    setState(()=>result=calc(c));
    double m = double.tryParse(amountCtrl.text)??0;
    if(m>0){ setState(()=>resultFromMoney={'money':m,'kwh':calcKwhFromMoney(m)}); }
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('قرأت: ${nums.last.toInt()} كيلو'), backgroundColor: Colors.green));
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
        Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)), child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('الاستهلاك هذا الشهر (ك.و.س)', style: TextStyle(color: Colors.white70, fontSize: 13)), Icon(Icons.credit_card, color: Colors.amber)]),
          SizedBox(height:10),
          TextField(controller: kwhCtrl, keyboardType: TextInputType.number, onChanged: (_)=>doCalc(), style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold), decoration: InputDecoration(hintText: 'مثال: 200', hintStyle: TextStyle(color: Colors.white24), suffixIcon: IconButton(icon: Icon(Icons.camera_alt, color: Colors.amber, size: 28), onPressed: pickImage), filled: true, fillColor: Colors.black26, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          SizedBox(height:12),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: doCalc, style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: EdgeInsets.all(14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(scanning?'بقرأ العداد... 🔍':'احسب الفاتورة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)))),
        ])),

        if(result!=null) ...
