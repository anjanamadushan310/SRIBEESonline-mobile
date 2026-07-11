// Product parsing tests.
//
// This file used to be the stock `flutter create` counter smoke test: it pumped
// a `MyApp` widget that has never existed in this project and asserted on a
// counter incrementing. It could not compile — nothing noticed, because CI had
// never analyzed `test/`. Replaced with tests covering the part of the client
// most likely to break silently: how a product's price is read off the wire.
//
// The backend merges the branch override over the global catalog
// (branch_price ?? product.price) BEFORE serializing, so `price` is always the
// effective, branch-correct price. The app must read it, not re-derive it.

import 'package:flutter_test/flutter_test.dart';
import 'package:sribees_mobile/features/products/models/product_model.dart';

void main() {
  group('Product.fromJson', () {
    test('reads the effective price the backend already merged', () {
      final product = Product.fromJson({
        'product_id': 'p1',
        'name': 'Organic Whole Milk 1L',
        'description': null,
        // This branch sells at 85.50; the global catalog price is 100.00.
        'price': 85.50,
        'global_price': 100.00,
        'stock_quantity': 3,
      });

      expect(product.price, 85.50);
      expect(product.globalPrice, 100.00);
      expect(product.stockQuantity, 3);
    });

    test('falls back to global_price when price is absent', () {
      final product = Product.fromJson({
        'product_id': 'p2',
        'name': 'Rice 5kg',
        'description': null,
        'global_price': 250.0,
      });

      expect(product.price, 250.0);
    });

    test('reads categoryId from the flat id, and from the nested object', () {
      // Regression: fromJson used to read json['category_id'], which the API
      // never sent — it returned only a nested `category` — so categoryId was
      // always ''. Both shapes must work now.
      final flat = Product.fromJson({
        'product_id': 'p3',
        'name': 'Tea',
        'description': null,
        'price': 10.0,
        'category_id': 'cat-1',
        'subcategory_id': 'sub-1',
      });
      expect(flat.categoryId, 'cat-1');
      expect(flat.subcategoryId, 'sub-1');

      final nested = Product.fromJson({
        'product_id': 'p4',
        'name': 'Coffee',
        'description': null,
        'price': 12.0,
        'category': {'category_id': 'cat-2', 'name': 'Beverages'},
        'subcategory': {'category_id': 'sub-2', 'name': 'Hot Drinks'},
      });
      expect(nested.categoryId, 'cat-2');
      expect(nested.categoryName, 'Beverages');
      expect(nested.subcategoryId, 'sub-2');
      expect(nested.subcategoryName, 'Hot Drinks');
    });

    test('exposes discount_price as the sale price', () {
      final product = Product.fromJson({
        'product_id': 'p5',
        'name': 'Biscuits',
        'description': null,
        'price': 80.0,
        'discount_price': 60.0,
        'stock_quantity': 5,
      });

      expect(product.salePrice, 60.0);
      expect(product.effectivePrice, 60.0); // the sale price wins
      expect(product.isOnSale, isTrue);
      expect(product.isInStock, isTrue);
    });

    test('without a discount, the effective price is just the price', () {
      final product = Product.fromJson({
        'product_id': 'p6',
        'name': 'Salt',
        'description': null,
        'price': 40.0,
        'stock_quantity': 0,
      });

      expect(product.salePrice, isNull);
      expect(product.effectivePrice, 40.0);
      expect(product.isOnSale, isFalse);
      expect(product.isInStock, isFalse);
    });
  });
}
