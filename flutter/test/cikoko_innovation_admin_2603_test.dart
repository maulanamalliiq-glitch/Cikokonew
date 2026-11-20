import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/cikoko_innovation_admin_editor.dart';

void main() {
  test('Nomor WhatsApp editor sama dengan validasi server', () {
    expect(cikokoInnovationPhoneValid('081234567890'), isTrue);
    expect(cikokoInnovationPhoneValid('6281234567890'), isTrue);
    expect(cikokoInnovationPhoneValid('abc'), isTrue); // can be cleared by user
    expect(cikokoInnovationPhoneValid('62'), isFalse);
    expect(cikokoInnovationPhoneValid('123'), isFalse);
  });
  test('Endpoint editor terpisah dari Mobile API utama', () {
    expect(CikokoInnovationAdminApi.endpoint.path,
        '/mobile-api/inovasi-editor-2603.php');
  });
}
