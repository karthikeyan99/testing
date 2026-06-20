import '../../models/enums.dart';
import '../../models/sale.dart';
import 'marketplace_api.dart';

/// Placeholder Flipkart Marketplace API client. Same shape as [AmazonSpApi]:
/// it satisfies the [MarketplaceApi] contract but defers live sync.
///
/// To complete this: obtain API access from Flipkart Seller Hub, perform the
/// OAuth client-credentials flow for an access token, then call the Orders
/// search/shipments endpoints and the Settlement report for fee breakdowns.
class FlipkartApi implements MarketplaceApi {
  final ApiCredentials credentials;

  FlipkartApi(this.credentials);

  @override
  Marketplace get marketplace => Marketplace.flipkart;

  @override
  bool get isConfigured => credentials.isComplete;

  @override
  Future<List<Sale>> fetchOrders({
    required DateTime from,
    required DateTime to,
  }) async {
    throw UnimplementedError(
      'Flipkart API live sync is not configured yet. '
      'Use CSV import from Seller Hub for now.',
    );
  }
}
