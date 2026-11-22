import 'package:flutter/material.dart';

/// Bank Sampah personal weighing statement. This component NEVER fetches
/// another member's data: caller passes only the authenticated user's
/// "personal_entries" response from the server.
class BankSampahPersonalDetails2618 extends StatefulWidget {
  final int year;
  final Map<String,dynamic> data;
  const BankSampahPersonalDetails2618({
    super.key,required this.year,required this.data,
  });
  @override
  State<BankSampahPersonalDetails2618> createState()=>
      _BankSampahPersonalDetails2618State();
}

class _BankSampahPersonalDetails2618State
    extends State<BankSampahPersonalDetails2618> {
  static const navy=Color(0xff123762);
  static const green=Color(0xff147343);
  static const muted=Color(0xff64748b);
  int month=0; // 0 = full year; 1..12 = selected month
  static const months=['Semua Bulan','Januari','Februari','Maret','April',
    'Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'];

  @override
  void didUpdateWidget(covariant BankSampahPersonalDetails2618 old){
    super.didUpdateWidget(old);
    if(old.year!=widget.year)month=0;
  }

  static String kg(Object? v){
    final d=double.tryParse((v??'0').toString())??0;
    return d.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'),'');
  }
  static String rupiah(Object? v){
    final n=int.tryParse((v??'0').toString())??0;
    return n.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),(_)=>'.');
  }
  static String dateLabel(String iso){
    final d=DateTime.tryParse(iso);
    if(d==null)return iso;
    return d.day.toString()+' '+months[d.month]+' '+d.year.toString();
  }

  List<Map<String,dynamic>> get items {
    final source=widget.data['items'];
    if(source is! List)return [];
    final list=source.whereType<Map>().map(
      (e)=>Map<String,dynamic>.from(e)).where((r){
        final date=DateTime.tryParse((r['session_date']??'').toString());
        return date!=null&&date.year==widget.year&&
          (month==0||date.month==month);
      }).toList();
    list.sort((a,b)=>(b['session_date']??'').toString().compareTo(
      (a['session_date']??'').toString()));
    return list;
  }

  Widget _sectionHeader(List<Map<String,dynamic>> filtered){
    final weightGrams=filtered.fold<int>(0,(sum,e)=>sum+
      ((double.tryParse((e['weight_kg']??'0').toString())??0)*1000).round());
    final totalRp=filtered.fold<int>(0,(sum,e)=>sum+
      (int.tryParse((e['amount_rp']??'0').toString())??0));
    return Container(
      padding:const EdgeInsets.all(13),
      decoration:BoxDecoration(color:const Color(0xffeef7f2),
        borderRadius:BorderRadius.circular(12)),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(month==0?'Ringkasan rincian '+widget.year.toString():
          'Ringkasan '+months[month]+' '+widget.year.toString(),
          style:const TextStyle(fontSize:11.8,color:muted)),
        const SizedBox(height:5),
        Text(kg(weightGrams/1000)+' Kg  |  Rp '+rupiah(totalRp),
          key:const Key('personal_bank_sampah_filtered_total_2618'),
          style:const TextStyle(fontWeight:FontWeight.w900,
            fontSize:17,color:green)),
        Text(filtered.length.toString()+' rincian barang',
          style:const TextStyle(fontSize:11.5,color:muted)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context){
    final filtered=items;
    final groups=<String,List<Map<String,dynamic>>>{};
    for(final row in filtered){
      final date=(row['session_date']??'').toString();
      groups.putIfAbsent(date,()=>[]).add(row);
    }
    return Card(
      key:const Key('bank_sampah_personal_details_2618'),
      margin:const EdgeInsets.only(top:10,bottom:7),
      shape:RoundedRectangleBorder(
        borderRadius:BorderRadius.circular(14),
        side:const BorderSide(color:Color(0xffdfe9f3))),
      elevation:0,
      child:Padding(padding:const EdgeInsets.all(13),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Row(children:[
            Icon(Icons.receipt_long_outlined,color:navy,size:21),
            SizedBox(width:8),
            Expanded(child:Text('Rincian Penimbangan Saya',
              style:TextStyle(fontWeight:FontWeight.w900,
                color:navy,fontSize:16))),
          ]),
          const SizedBox(height:5),
          const Text('Tanggal, jenis barang, berat, dan uang hasil penimbangan '
            'milik akun Anda sendiri.',
            style:TextStyle(fontSize:11.6,color:muted)),
          const SizedBox(height:12),
          DropdownButtonFormField<int>(
            key:ValueKey('bank_filter_month_'+widget.year.toString()),
            initialValue:month,isExpanded:true,
            decoration:const InputDecoration(
              labelText:'Pilih bulan',
              prefixIcon:Icon(Icons.calendar_month_outlined),
              isDense:true,border:OutlineInputBorder()),
            items:[
              for(var i=0;i<months.length;i++)
                DropdownMenuItem<int>(value:i,child:Text(months[i])),
            ],
            onChanged:(v){if(v!=null)setState(()=>month=v);},
          ),
          const SizedBox(height:10),
          _sectionHeader(filtered),
          if(filtered.isEmpty)
            const Padding(padding:EdgeInsets.symmetric(vertical:18),
              child:Center(child:Text(
                'Belum ada rincian penimbangan pada periode ini.',
                style:TextStyle(color:muted,fontSize:12)))),
          for(final entry in groups.entries)...[
            const SizedBox(height:12),
            Container(
              key:ValueKey('bank_sampah_date_'+entry.key+'_2618'),
              decoration:BoxDecoration(
                border:Border.all(color:const Color(0xffdfe9f3)),
                borderRadius:BorderRadius.circular(10)),
              child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
                Container(
                  padding:const EdgeInsets.symmetric(
                    horizontal:10,vertical:10),
                  decoration:const BoxDecoration(
                    color:Color(0xffedf4fc),
                    borderRadius:BorderRadius.vertical(top:Radius.circular(9))),
                  child:Row(children:[
                    const Icon(Icons.event_outlined,size:18,color:navy),
                    const SizedBox(width:7),
                    Expanded(child:Text(dateLabel(entry.key),
                      style:const TextStyle(color:navy,fontWeight:FontWeight.w800,
                        fontSize:12.5))),
                    Text(entry.value.length.toString()+' barang',
                      style:const TextStyle(color:muted,fontSize:11)),
                  ]),
                ),
                for(var i=0;i<entry.value.length;i++)...[
                  if(i>0)const Divider(height:1,indent:10,endIndent:10),
                  Padding(
                    padding:const EdgeInsets.symmetric(
                      vertical:9,horizontal:10),
                    child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
                      Expanded(child:Column(
                        crossAxisAlignment:CrossAxisAlignment.start,
                        children:[
                          Text((entry.value[i]['item_name']??'Barang').toString(),
                            style:const TextStyle(fontWeight:FontWeight.w700,
                              color:navy,fontSize:12.6)),
                          const SizedBox(height:3),
                          Text(kg(entry.value[i]['weight_kg'])+' Kg'+
                            (entry.value[i]['source']=='arsip_2026'?
                              ' · Arsip 2026':''),
                            style:const TextStyle(color:muted,fontSize:11.3)),
                        ],
                      )),
                      const SizedBox(width:6),
                      Text('Rp '+rupiah(entry.value[i]['amount_rp']),
                        style:const TextStyle(color:green,fontWeight:FontWeight.w900,
                          fontSize:12.8)),
                    ]),
                  ),
                ],
                Builder(builder:(_){
                  final weight=entry.value.fold<int>(0,(sum,v)=>sum+
                    ((double.tryParse((v['weight_kg']??'0').toString())??0)*1000).round());
                  final amount=entry.value.fold<int>(0,(sum,v)=>sum+
                    (int.tryParse((v['amount_rp']??'0').toString())??0));
                  return Container(
                    padding:const EdgeInsets.symmetric(
                      vertical:9,horizontal:10),
                    decoration:const BoxDecoration(
                      color:Color(0xfff2faf5),
                      borderRadius:BorderRadius.vertical(
                        bottom:Radius.circular(9))),
                    child:Row(children:[
                      const Expanded(child:Text('Total tanggal ini',
                        style:TextStyle(fontWeight:FontWeight.w700,
                          color:navy,fontSize:11.2))),
                      Text(kg(weight/1000)+' Kg  |  Rp '+rupiah(amount),
                        style:const TextStyle(fontWeight:FontWeight.w800,
                          color:green,fontSize:11.5)),
                    ]),
                  );
                }),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}
