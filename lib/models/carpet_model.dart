class CarpetModel {
  final String id;
  final String orderId;
  final double width;
  final double height;
  final double area;
  final double price;

  const CarpetModel({
    required this.id,
    required this.orderId,
    required this.width,
    required this.height,
    required this.area,
    required this.price,
  });

  factory CarpetModel.fromMap(Map<String, dynamic> map) => CarpetModel(
        id: map['id'].toString(),
        orderId: map['order_id'].toString(),
        width: (map['width'] as num).toDouble(),
        height: (map['height'] as num).toDouble(),
        area: (map['area'] as num).toDouble(),
        price: (map['price'] as num).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'order_id': orderId,
        'width': width,
        'height': height,
        'area': area,
        'price': price,
      };
}
