import 'package:flutter/cupertino.dart';
import 'package:invoicemaker/models/item_model.dart';

class ItemProvider extends ChangeNotifier {
  List<ItemModel> item = [];

  int lastId = 0; // This tracks the last used ID

  addItems(ItemModel itemModel) {
    lastId += 1;
    itemModel.id = lastId;
    item.add(itemModel);
    notifyListeners();
  }

  updateItems(
    String iName,
    String? iPrice,
    String? iQty,
    String? iNote,
    ItemModel? itemModel, {
    double? discount,
    String? discountType,
  }) {
    itemModel!.itemName = iName;
    itemModel.price = double.parse(iPrice.toString());
    itemModel.note = iNote;
    itemModel.qty = int.parse(iQty.toString());
    itemModel.discount = (discount != null && discount > 0) ? discount : null;
    itemModel.discountType = (discount != null && discount > 0) ? discountType : null;

    notifyListeners();
  }

  deleteItems(ItemModel itemModel, int id) {
    item.removeWhere((element) => id == element.id);

    notifyListeners();
  }
}
