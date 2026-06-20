import '../../models/enums.dart';
import '../../models/sale.dart';
import 'marketplace_api.dart';

/// Placeholder Amazon SP-API client. Not yet wired to the network — it throws
/// [UnimplementedError] from [fetchOrders] so the rest of the app can depend on
/// the [MarketplaceApi] contract today and switch to live sync later.
///
/// To complete this: register a developer profile in Seller Central, create an
/// SP-API app, perform LWA OAuth to obtain a refresh token, then call the
/// Orders API (getOrders / getOrderItems) and Finances API for settled fees.
class AmazonSpApi implements MarketplaceApi {
  final ApiCredentials credentials;

  AmazonSpApi(this.credentials);

  @override
  Marketplace get marketplace => Marketplace.amazon;

  @override
  bool get isConfigured => credentials.isComplete;

  @override
  Future<List<Sale>> fetchOrders({
    required DateTime from,
    required DateTime to,
  }) async {
    throw UnimplementedError(
      'Amazon SP-API live sync is not configured yet. '
      'Use CSV import from Seller Central for now.',
    );
  }
}
