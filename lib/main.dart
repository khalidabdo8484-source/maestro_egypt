import 'package:flutter/material.dart';
import 'dart:math';
void main()=>runApp(MaterialApp(debugShowCheckedModeBanner:false, home:MaestroApp()));
class MaestroApp extends StatefulWidget{const MaestroApp({super.key});@override State<MaestroApp> createState()=>_MaestroState();}
class _MaestroState extends State<MaestroApp>{
 double density=78;
 double get co2=>density*0.92;
 double get waste=>density*1.1;
 @override Widget build(BuildContext c){
  return Scaffold(backgroundColor:Color(0xFF0F172A), appBar:AppBar(backgroundColor:Colors.black, centerTitle:true, title:Text('🇪🇬 MAESTRO Egypt', style:TextStyle(color:Colors.amber, fontWeight:FontWeight.bold))), body:ListView(padding:EdgeInsets.all(14), children:[
   Container(height:240, decoration:BoxDecoration(color:Colors.black, borderRadius:BorderRadius.circular(16), border:Border.all(color:Colors.amber.withOpacity(0.3))), child:CustomPaint(painter:TrafficPainter(density), size:Size.infinite)),
   SizedBox(height:16),
   Container(padding:EdgeInsets.all(14), decoration:BoxDecoration(color:Color(0xFF1E293B), borderRadius:BorderRadius.circular(12)), child:Column(children:[
     Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[Text('كثافة الزحام', style:TextStyle(color:Colors.white70)), Text('${density.toInt()}%', style:TextStyle(color:density>70?Colors.red:Colors.green, fontWeight:FontWeight.bold, fontSize:18))]),
     Slider(value:density, min:10, max:100, activeColor:Colors.amber, onChanged:(v)=>setState(()=>density=v)),
   ])),
   SizedBox(height:12),
   Row(children:[
    Expanded(child:_card('CO2 المنبعث', '${co2.toStringAsFixed(1)} طن/يوم', Colors.orange)),
    SizedBox(width:10),
    Expanded(child:_card('الهدر الاقتصادي', '${waste.toStringAsFixed(1)} م/يوم', Colors.red)),
   ]),
   SizedBox(height:16),
   ElevatedButton(onPressed:(){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تم التحليل ✅ CO2: ${co2.toStringAsFixed(1)} طن')));}, style:ElevatedButton.styleFrom(backgroundColor:Colors.amber, padding:EdgeInsets.all(16), shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12))), child:Text('🤖 تحليل بالذكاء الاصطناعي', style:TextStyle(color:Colors.black, fontWeight:FontWeight.bold))),
  ]));
 }
 Widget _card(String t, String v, Color c)=>Container(padding:EdgeInsets.all(12), decoration:BoxDecoration(color:Color(0xFF1E293B), borderRadius:BorderRadius.circular(12), border:Border.all(color:c.withOpacity(0.3))), child:Column(children:[Text(t, style:TextStyle(color:Colors.white60, fontSize:11)), SizedBox(height:6), Text(v, style:TextStyle(color:c, fontWeight:FontWeight.bold, fontSize:14))] ));
}
class TrafficPainter extends CustomPainter{double d;TrafficPainter(this.d);@override void paint(Canvas canvas, Size size){var bg=Paint()..color=Color(0xFF1E293B);canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0,0,size.width,size.height), Radius.circular(16)), bg); var r=Random(42); var p=Paint()..strokeWidth=3..style=PaintingStyle.stroke; for(int i=0;i<20;i++){bool jam=r.nextDouble()*100<d; p.color=jam?Colors.red.withOpacity(0.8):Colors.green.withOpacity(0.7); var x1=r.nextDouble()*size.width; var y1=r.nextDouble()*size.height; var x2=x1+(r.nextDouble()*60-30); var y2=y1+(r.nextDouble()*60-30); canvas.drawLine(Offset(x1,y1), Offset(x2,y2), p); if(jam) canvas.drawCircle(Offset(x1,y1), 3, Paint()..color=Colors.red);}}@override bool shouldRepaint(covariant CustomPainter o)=>true;}
