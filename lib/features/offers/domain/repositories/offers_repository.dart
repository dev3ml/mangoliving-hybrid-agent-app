import '../models/property_action.dart';

abstract interface class OffersRepository {
  Future<List<PropertyAction>> list({OfferBoardState? state});

  Future<PropertyAction> sendOffer({
    required String id,
    required Map<String, dynamic> body,
    String? documentPath,
  });

  Future<PropertyAction> applyAction({
    required String id,
    required String action,
  });
}
