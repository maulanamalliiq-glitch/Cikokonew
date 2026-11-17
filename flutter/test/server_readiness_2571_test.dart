import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/api.dart';
import 'package:cikoko/cikoko_reviews.dart';
import 'package:cikoko/integrated_services.dart';

class _BrokenReviewApi extends CikokoApi {
 @override
 Future<Map<String,dynamic>> call(String action,
   {Map<String,dynamic>? body,bool authorized=false})async{
  if(action=='review_public')throw ApiError('Endpoint tidak tersedia (HTTP 401)');
  return {'ok':false,'error':'not ready'};
 }
}
void main(){
 testWidgets('Unavailable reviews show server error rather than claiming zero reviews',
   (tester)async{
  await tester.pumpWidget(MaterialApp(home:Scaffold(
   body:CikokoReviewSummary(api:_BrokenReviewApi(),onAll:(){}))));
  await tester.pumpAndSettle();
  expect(find.textContaining('Layanan ulasan belum tersedia di server'),findsOneWidget);
  expect(find.text('0/5'),findsNothing);
  expect(find.text('0 ulasan'),findsNothing);
 });
 testWidgets('Review form reports endpoint failure and does not invent ratings',
   (tester)async{
  await tester.pumpWidget(MaterialApp(home:CikokoReviewPage(api:_BrokenReviewApi())));
  await tester.pumpAndSettle();
  expect(find.textContaining('Daftar ulasan gagal dimuat'),findsOneWidget);
  expect(find.textContaining('Rata-rata 0/5'),findsNothing);
 });
 testWidgets('Service with no published image renders honest category pictogram',
   (tester)async{
  await tester.pumpWidget(const MaterialApp(home:Scaffold(
   body:CikokoServiceLogo(entry:{'id':'puskesmas','logo_url':''}))));
  expect(find.byIcon(Icons.local_hospital_outlined),findsOneWidget);
 });
}
