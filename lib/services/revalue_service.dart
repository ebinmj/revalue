import '../models/waste_item.dart';

abstract class ReValueService {
  Future<WasteItem?> identifyItem();
}

class MockReValueService implements ReValueService {
  @override
  Future<WasteItem?> identifyItem() async => null;
}
