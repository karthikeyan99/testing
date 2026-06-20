import '../../models/enums.dart';
import '../../models/sale.dart';

/// Contract for live marketplace integrations.
///
/// The app currently runs on manual entry + CSV import. When official seller
/// APIs are wired up, implement this interface (one per marketplace) and feed
/// the returned [Sale] list through the same repository used by CSV import —
/// no UI or storage changes required.
///
/// Reference docs for the eventual implementations:
///   - Amazon Selling Partner API (SP-API):
///     https://developer-docs.amazon.com/sp-api/  (Orders + Finances reports)
///   - Flipkart Marketplace Seller API:
///     https://seller.flipkart.com/api-docs/      (Orders + Settlement)
abstract class MarketplaceApi {
  Marketplace get marketplace;

  /// Whether valid OAuth/credentials are configured.
  bool get isConfigured;

  /// Pull orders updated within the given window.
  Future<List<Sale>> fetchOrders({
    required DateTime from,
    required DateTime to,
  });
}

/// Credentials persisted (e.g. via secure storage) for a marketplace.
class ApiCredentials {
  final Marketplace marketplace;
  final String? clientId;
  final String? clientSecret;
  final String? refreshToken;
  final String? sellerId;

  const ApiCredentials({
    required this.marketplace,
    this.clientId,
    this.clientSecret,
    this.refreshToken,
    this.sellerId,
  });

  bool get isComplete =>
      (clientId?.isNotEmpty ?? false) &&
      (clientSecret?.isNotEmpty ?? false) &&
      (refreshToken?.isNotEmpty ?? false);
}
