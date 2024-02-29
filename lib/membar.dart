class Membar {
  final int? id;
  int tapCount;
  final String shopName;
  final String memo;
  final String date;
  final int color;
  final String? branchName;
  final String? userName;
  final String? barcodeData;
  final String? picPath;

  Membar({
    this.id,
    required this.tapCount,
    required this.shopName,
    required this.memo,
    required this.date,
    required this.color,
    this.branchName,
    this.userName,
    this.barcodeData,
    this.picPath,
  });

  factory Membar.withAutoIncrement(
      {int? id,
      required tapCount,
      required String shopName,
      required String memo,
      required String date,
      required int color,
      String? picPath,
      String? barcodeData}) {
    return Membar(
        id: id,
        tapCount: tapCount,
        shopName: shopName,
        memo: memo,
        date: date,
        color: color,
        picPath: picPath,
        barcodeData: barcodeData);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tapCount': tapCount,
      'shopName': shopName,
      'memo': memo,
      'date': date,
      'color': color,
      'branchName': branchName,
      'userName': userName,
      'barcodeData': barcodeData,
      'picPath': picPath,
    };
  }
}
