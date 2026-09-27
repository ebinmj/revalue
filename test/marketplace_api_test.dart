import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:re_value/services/api_service.dart';

void main() {
  test('listing creation sends the Supabase token without seller_id', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/marketplace/listings');
      expect(request.headers['Authorization'], 'Bearer user-access-token');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body.containsKey('seller_id'), isFalse);
      expect(body['title'], '8GB DDR4 Laptop RAM');
      return http.Response(
        jsonEncode({
          'id': 'listing-1',
          'seller_id': 'authenticated-user-id',
          'seller_name': 'User A',
          'title': '8GB DDR4 Laptop RAM',
          'description': 'Working RAM removed from a damaged laptop.',
          'category': 'RAM',
          'condition': 'Used - Working',
          'price': 800,
          'currency': 'INR',
          'status': 'available',
        }),
        201,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = ApiService(
      baseUrl: 'http://localhost:8000',
      client: client,
      accessTokenProvider: () => 'user-access-token',
    );

    final listing = await service.createMarketplaceListing(
      title: '8GB DDR4 Laptop RAM',
      description: 'Working RAM removed from a damaged laptop.',
      category: 'RAM',
      condition: 'Used - Working',
      price: 800,
    );

    expect(listing.sellerId, 'authenticated-user-id');
    expect(listing.status, 'available');
  });
}
