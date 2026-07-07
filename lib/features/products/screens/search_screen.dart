/// SRIBEESonline - Product Search
///
/// Debounced full-text search against GET /api/v1/products/search (branch
/// scoped). Results are real products — tapping one opens Product Details with
/// the real product id. Handles idle, loading, empty and error states.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/sribees_design.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/product_provider.dart';
import '../models/product_model.dart';
import '../widgets/product_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  void _addProduct(Product p) {
    ref.read(cartProvider.notifier).addItem(
          productId: p.id,
          price: p.effectivePrice,
          name: p.name,
          imageUrl: p.primaryImageUrl,
          sku: p.sku,
        );
    showToast(context, '${p.name} added to cart');
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _query.length >= 2;
    final results = hasQuery ? ref.watch(searchProductsProvider(_query)) : null;

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _searchBar(),
          Expanded(child: _body(results)),
        ],
      ),
    );
  }

  Widget _searchBar() {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.9, -0.5),
          end: Alignment(0.9, 0.5),
          colors: [kMagentaAppbarStart, kMagenta],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      color: Color(0xFF9B97A1), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      textInputAction: TextInputAction.search,
                      onChanged: _onChanged,
                      onSubmitted: (v) => setState(() => _query = v.trim()),
                      decoration: const InputDecoration(
                        hintText: 'Search for products…',
                        border: InputBorder.none,
                        isCollapsed: true,
                        hintStyle: TextStyle(color: kPlaceholder, fontSize: 15),
                      ),
                    ),
                  ),
                  if (_controller.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _controller.clear();
                        setState(() => _query = '');
                        _focus.requestFocus();
                      },
                      child: const Icon(Icons.close_rounded,
                          color: kMuted, size: 20),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(AsyncValue<List<Product>>? results) {
    if (results == null) {
      return _hint(
        icon: Icons.search_rounded,
        title: 'Search the catalog',
        subtitle: 'Type at least 2 characters to begin.',
      );
    }
    return results.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: kMagenta)),
      error: (e, _) => _hint(
        icon: Icons.wifi_off_rounded,
        title: 'Search failed',
        subtitle: 'Please check your connection and try again.',
        action: TextButton(
          onPressed: () => ref.invalidate(searchProductsProvider(_query)),
          child: const Text('Retry', style: TextStyle(color: kMagenta)),
        ),
      ),
      data: (products) {
        if (products.isEmpty) {
          return _hint(
            icon: Icons.sentiment_dissatisfied_outlined,
            title: 'No results for “$_query”',
            subtitle: 'Try a different keyword.',
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.72,
          ),
          itemCount: products.length,
          itemBuilder: (_, i) => ProductGridCard(
            product: products[i],
            onOpen: () => openProductDetails(context, products[i]),
            onAdd: () => _addProduct(products[i]),
          ),
        );
      },
    );
  }

  Widget _hint({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: const Color(0xFFC9C5D0)),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: kInk)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: kMuted)),
            ],
            if (action != null) ...[
              const SizedBox(height: 10),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
