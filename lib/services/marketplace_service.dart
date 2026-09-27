import '../models/marketplace_listing.dart';

abstract class MarketplaceService {
  List<MarketplaceListing> getListings();
}

class MockMarketplaceService implements MarketplaceService {
  const MockMarketplaceService();

  @override
  List<MarketplaceListing> getListings() => const [
    MarketplaceListing(
      title: '16GB DDR4 RAM',
      price: 1800,
      condition: 'Good condition',
      category: 'Components',
      description:
          'Potentially reusable memory module from a recovered laptop.',
      seller: 'Mock seller 01',
    ),
    MarketplaceListing(
      title: 'Laptop Display Panel',
      price: 2500,
      condition: 'Working',
      category: 'Components',
      description: 'Working display panel. Compatibility must be checked before purchase.',
      seller: 'Mock seller 02',
    ),
    MarketplaceListing(
      title: '65W Laptop Charger',
      price: 900,
      condition: 'Good condition',
      category: 'Electronics',
      description:
          'Used charger with compatibility and connector details to verify.',
      seller: 'Mock seller 03',
    ),
    MarketplaceListing(
      title: 'SSD 512GB',
      price: 2800,
      condition: 'Used',
      category: 'Components',
      description:
          'Used SSD. Health and data erasure status should be confirmed.',
      seller: 'Mock seller 04',
    ),
  ];
}
