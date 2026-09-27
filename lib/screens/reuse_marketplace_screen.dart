import 'package:flutter/material.dart';

import '../models/marketplace_listing.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';
import '../widgets/listing_card.dart';

class ReuseMarketplaceScreen extends StatefulWidget {
  const ReuseMarketplaceScreen({
    this.initialQuery,
    this.initialCategory,
    this.apiService,
    super.key,
  });

  final String? initialQuery;
  final String? initialCategory;
  final ApiService? apiService;

  @override
  State<ReuseMarketplaceScreen> createState() => _ReuseMarketplaceScreenState();
}

class _ReuseMarketplaceScreenState extends State<ReuseMarketplaceScreen> {
  static const _categories = [
    'Components',
    'Electronics',
    'Tools',
    'Household',
    'Clothing',
  ];

  late final Future<ApiMarketplaceResponse> _marketplaceFuture;
  List<MarketplaceListing> _listings = const [];
  final _searchController = TextEditingController();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory;
    }
    _marketplaceFuture = (widget.apiService ?? ApiService())
        .getMarketplaceMatches()
        .then((response) {
          _listings = response.listings;
          return response;
        });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MarketplaceListing> get _filteredListings {
    final query = _searchController.text.trim().toLowerCase();
    return _listings.where((listing) {
      final matchesSearch =
          query.isEmpty ||
          listing.title.toLowerCase().contains(query) ||
          listing.description.toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategory == null || listing.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Reuse Marketplace')),
      body: FutureBuilder<ApiMarketplaceResponse>(
        future: _marketplaceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _MarketplaceStatus(
              icon: Icons.storefront_outlined,
              title: 'Loading marketplace',
              message: 'Finding recovery listings...',
              loading: true,
            );
          }
          if (snapshot.hasError) {
            return _MarketplaceStatus(
              icon: Icons.cloud_off_outlined,
              title: 'Marketplace unavailable',
              message: snapshot.error.toString().replaceFirst(
                'Exception: ',
                '',
              ),
            );
          }
          final listings = _filteredListings;
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              Text(
                'Give useful things another life',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Browse recovery listings. No payments or shipping are handled here yet.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search listings',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear),
                        ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('All'),
                        selected: _selectedCategory == null,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = null),
                      ),
                    ),
                    ..._categories.map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: _selectedCategory == category,
                          onSelected: (selected) => setState(
                            () =>
                                _selectedCategory = selected ? category : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (listings.isEmpty)
                const _EmptyListings()
              else
                ...listings.map(
                  (listing) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ListingCard(
                      listing: listing,
                      onTap: () => _showListing(context, listing),
                      onContactSeller: () => _contactSeller(context, listing),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showListing(BuildContext context, MarketplaceListing listing) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                listing.title,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('${_formatPrice(listing.price)} · ${listing.condition}'),
              const SizedBox(height: 12),
              Text(listing.description),
              const SizedBox(height: 8),
              Text('Seller: ${listing.seller}'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _contactSeller(this.context, listing);
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Contact Seller'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _contactSeller(BuildContext context, MarketplaceListing listing) {
    final messageController = TextEditingController(
      text:
          'Hi ${listing.seller}, is this ${listing.title} still available on ReValue?',
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Contact ${listing.seller}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item: ${listing.title} (${_formatPrice(listing.price)})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Your inquiry message',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Direct peer-to-peer communication. No payment or shipping is processed on ReValue.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Message sent to ${listing.seller}!'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              );
            },
            child: const Text('Send Message'),
          ),
        ],
      ),
    );
  }
}

class _EmptyListings extends StatelessWidget {
  const _EmptyListings();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 36,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No listings match your search or category.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketplaceStatus extends StatelessWidget {
  const _MarketplaceStatus({
    required this.icon,
    required this.title,
    required this.message,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (loading) ...[
              const SizedBox(height: 18),
              const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatPrice(num price) {
  final formatted = price.toString().replaceAllMapped(
    RegExp(r'(?<=\d)(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '₹$formatted';
}
