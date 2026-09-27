import 'package:flutter/material.dart';

import '../models/marketplace_listing.dart';
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
    'RAM',
    'Storage',
    'Display',
    'Components',
    'Electronics',
  ];

  late final ApiService _apiService;
  late Future<List<MarketplaceListing>> _marketplaceFuture;
  List<MarketplaceListing> _listings = const [];
  final _searchController = TextEditingController();
  String? _selectedCategory;
  bool _showMine = false;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory;
    }
    _marketplaceFuture = _fetchListings();
  }

  Future<List<MarketplaceListing>> _fetchListings() async {
    final listings = await _apiService.getMarketplaceListings(
      query: _searchController.text,
      category: _selectedCategory,
      mine: _showMine,
    );
    _listings = listings;
    return listings;
  }

  void _refreshListings() {
    setState(() => _marketplaceFuture = _fetchListings());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MarketplaceListing> get _filteredListings {
    return _listings;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reuse Marketplace'),
        actions: [
          IconButton(
            tooltip: 'Refresh listings',
            onPressed: _refreshListings,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Create listing',
            onPressed: _showCreateListing,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder<List<MarketplaceListing>>(
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
              onRetry: _refreshListings,
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
                onSubmitted: (_) => _refreshListings(),
                decoration: InputDecoration(
                  hintText: 'Search listings',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? IconButton(
                          tooltip: 'Search listings',
                          onPressed: _refreshListings,
                          icon: const Icon(Icons.search),
                        )
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            _refreshListings();
                          },
                          icon: const Icon(Icons.clear),
                        ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('All listings')),
                  ButtonSegment(value: true, label: Text('My listings')),
                ],
                selected: {_showMine},
                onSelectionChanged: (selection) {
                  setState(() {
                    _showMine = selection.single;
                    _marketplaceFuture = _fetchListings();
                  });
                },
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
                        onSelected: (_) => setState(() {
                          _selectedCategory = null;
                          _marketplaceFuture = _fetchListings();
                        }),
                      ),
                    ),
                    ..._categories.map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: _selectedCategory == category,
                          onSelected: (selected) => setState(() {
                            _selectedCategory = selected ? category : null;
                            _marketplaceFuture = _fetchListings();
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (listings.isEmpty)
                _EmptyListings(onCreate: _showMine ? _showCreateListing : null)
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

  Future<void> _showCreateListing() async {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController();
    final description = TextEditingController();
    final category = TextEditingController(text: 'RAM');
    final condition = TextEditingController(text: 'Used - Working');
    final price = TextEditingController();
    final imageUrl = TextEditingController();
    var isSaving = false;
    String? error;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Create listing'),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _listingField(title, 'Title'),
                    _listingField(description, 'Description', maxLines: 3),
                    _listingField(category, 'Category'),
                    _listingField(condition, 'Condition'),
                    _listingField(
                      price,
                      'Price (INR)',
                      keyboardType: TextInputType.number,
                    ),
                    _listingField(
                      imageUrl,
                      'Image URL (optional)',
                      required: false,
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(dialogContext).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setDialogState(() {
                        isSaving = true;
                        error = null;
                      });
                      try {
                        await _apiService.createMarketplaceListing(
                          title: title.text.trim(),
                          description: description.text.trim(),
                          category: category.text.trim(),
                          condition: condition.text.trim(),
                          price: double.parse(price.text.trim()),
                          imageUrl: imageUrl.text.trim().isEmpty
                              ? null
                              : imageUrl.text.trim(),
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        if (!mounted) return;
                        setState(() {
                          _showMine = true;
                          _marketplaceFuture = _fetchListings();
                        });
                      } catch (exception) {
                        if (!dialogContext.mounted) return;
                        setDialogState(() {
                          isSaving = false;
                          error = exception.toString().replaceFirst(
                            'Exception: ',
                            '',
                          );
                        });
                      }
                    },
              child: Text(isSaving ? 'Saving...' : 'Publish listing'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    description.dispose();
    category.dispose();
    condition.dispose();
    price.dispose();
    imageUrl.dispose();
  }

  Widget _listingField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return 'This field is required.';
          }
          if (keyboardType == TextInputType.number &&
              double.tryParse(value?.trim() ?? '') == null) {
            return 'Enter a valid price.';
          }
          return null;
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
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Interested in this listing?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${listing.title} · ${_formatPrice(listing.price)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Seller: ${listing.seller}. ReValue does not process messages or payments yet.',
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _EmptyListings extends StatelessWidget {
  const _EmptyListings({this.onCreate});

  final VoidCallback? onCreate;

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
            if (onCreate != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Create listing'),
              ),
            ],
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
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool loading;
  final VoidCallback? onRetry;

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
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
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
