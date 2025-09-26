import 'package:get_storage/get_storage.dart';

class Details {
  static final GetStorage _box = GetStorage();
  static int? get userId => _box.read('userId');
  static String? get userName => _box.read('userName');
  static String? get currency => _box.read('currency');
  static String? get printerIp => _box.read('printerIp');
  static int? get storeId => _box.read('storeId');
  static int? get registerId => _box.read('registerId');
  String? get round_off => _box.read<String>('round_off');
  static int? get cashregId => _box.read('cashregId');
}

