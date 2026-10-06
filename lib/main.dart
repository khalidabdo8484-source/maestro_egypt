import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

void main() => runApp(MaterialApp(debugShowCheckedModeBanner: false, home: BillApp()));

class BillApp extends StatefulWidget { @override State<BillApp> createState() => _BillState(); }

class _BillState extends State<BillApp> {
  final currCtrl = TextEditingController(text: '350');
  final prevCtrl = TextEditingController(text: '150');
  Map<String, dynamic>? result;
  bool scanning = false;
  final picker = ImagePicker();
  final textRec = TextRecognizer(script: TextRecognitionScript.latin);

  Map<String,dynamic> calc(double c){
    double t=0,s=0; String sh='';
    if(c<=50){t=c*0.68; sh='الأولى'; s=1;}
    else if(c<=100){t=50*0.68+(c-50)*0.78; sh='الثانية'; s=2;}
    else if(c<=200){t=c*0.95; sh='الثالثة (0-200)'; s=6;}
    else if(c<=350){t=200*0.95+(c-200)*1.55; sh='الرابعة'; s=11;}
    else if(c<=650){t=200*0.95+150*1.55+(c-350)*1.95; sh='الخامسة'; s=15;}
    else if(c<=1000){t=200*0.95+150*1.55+300*1.95+(c-650)*2.10; sh='السادسة'; s=25;}
    else {t=c*2.23; sh='السابعة - فوق 1000'; s=40;}
    double nf = c<=200?3:c<=650?5:10;
    return {'kwh':c,'energy':t,'service':s,'nzafa':nf,'total':t+s+nf,'shariha':sh};
  }

  void doCalc(){
    double curr = double.tryParse(currCtrl.text)??0;
    double prev = double.tryParse(prevCtrl.text)??0;
    double cons = (curr-prev).abs();
    if(cons==0) cons=curr;
    setState(()=>result=calc(cons));
  }

  Future<void> pickImage(bool isCurrent) async {
    final XFile? img = await picker.pickImage(source: ImageSource.camera);
    if(img==null) return;
    setState(()=>scanning=true);
    try{
      final input = InputImage.fromFilePath(img.path);
      final RecognizedText rec = await textRec.processImage(input);
      String all = rec.text.replaceAll(RegExp(r'[^0-9]'), ' ');
      // طلع أكبر رقم في الصورة هو قراءة العداد
      var nums = all.split(' ').where((e)=>e.length>=2 && e.length<=6).map((e)=>int.tryParse(e)).whereType<int>().toList();
      nums.sort();
      if(nums.isNotEmpty){
        int best = nums.last;
        setState((){
          if(isCurrent) currCtrl.text = best.toString();
          else prevCtrl.text = best.toString();
        });
        doCalc();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('قرأت العداد: $best'), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('معرفتش أقرأ الرقم، اكتبه يدوي'), backgroundColor: Colors.orange));
      }
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
    setState(()=>scanning=false);
  }

  @override void initState(){ super.initState(); doCalc(); }
  @override void dispose(){ textRec.close(); super.dispose(); }

  @override Widget build(BuildContext c){
    return Scaffold(
      backgroundColor: Color(0xFF0F172A),
      appBar: AppBar(backgroundColor: Colors.black, centerTitle: true, title: Text('⚡ فاتورة العداد', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))),
      body: ListView(padding: EdgeInsets.all(16), children: [
        Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)), child: Column(children: [
          Row(children: [
            Expanded(child: _inputWithCam('الحالية', currCtrl, ()=>pickImage(true))),
            SizedBox(width:12),
            Expanded(child: _inputWithCam('السابقة', prevCtrl, ()=>pickImage(false))),
          ]),
          SizedBox(height:12),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: doCalc, style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: EdgeInsets.all(14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(scanning?'بقرأ العداد... 🔍':'احسب الفاتورة 💡', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)))),
          if(result!=null) Padding(padding: EdgeInsets.only(top:10), child: Text('الاستهلاك: ${result!['kwh'].toInt()} ك.و.س', style: TextStyle(color: Colors.white70)))
        ])),
        if(result!=null) ...[
          SizedBox(height:16),
          Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]), borderRadius: BorderRadius.circular(16)), child: Column(children: [
            Text('إجمالي الفاتورة', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
            Text('${result!['total'].toStringAsFixed(2)} جنيه', style: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.w900)),
            Container(margin: EdgeInsets.only(top:8), padding: EdgeInsets.symmetric(horizontal:12, vertical:6), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)), child: Text('الشريحة ${result!['shariha']}', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))),
          ])),
          SizedBox(height:12),
          Row(children: [
            Expanded(child: _detail('الطاقة', '${result!['energy'].toStringAsFixed(2)} ج')),
            SizedBox(width:8),
            Expanded(child: _detail('خدمة', '${result!['service']} ج')),
            SizedBox(width:8),
            Expanded(child: _detail('نظافة', '${result!['nzafa']} ج')),
          ]),
        ]
      ]),
    );
  }
  Widget _inputWithCam(String label, TextEditingController ctrl, VoidCallback onCam)=>Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('القراءة $label', style: TextStyle(color: Colors.white54, fontSize: 11)),
    SizedBox(height:6),
    TextField(controller: ctrl, keyboardType: TextInputType.number, style: TextStyle(color: Colors.white, fontSize: 18), decoration: InputDecoration(suffixIcon: IconButton(icon: Icon(Icons.camera_alt, color: Colors.amber), onPressed: onCam), filled: true, fillColor: Colors.black26, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
  ]);
  Widget _detail(String t,String v)=>Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)), child: Column(children: [Text(t, style: TextStyle(color: Colors.white54, fontSize:10)), SizedBox(height:4), Text(v, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]));
}
