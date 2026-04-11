import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';

import 'library_sync_view.dart';
import '../../models/game.dart';
import '../../repositories/game_repository.dart';
import '../../repositories/wishlist_repository.dart';
import '../../services/price_service.dart';
import '../../services/search_alias_service.dart';
import '../../services/barcode_service.dart';
import '../../core/currency_provider.dart';
import '../../controllers/home_controller.dart';
import '../../models/wishlist_item.dart';
import '../collections/widgets/game_box_3d.dart';
import 'barcode_scanner_view.dart';

class AddGameModal extends ConsumerStatefulWidget {
  final bool isWishlistMode;
  final String? initialQuery;
  final AppPlatform? initialPlatform;
  final WishlistItem? prefillItem;

  const AddGameModal({
    super.key,
    this.isWishlistMode = false,
    this.initialQuery,
    this.initialPlatform,
    this.prefillItem,
  });

  @override
  ConsumerState<AddGameModal> createState() => _AddGameModalState();
}

class _AddGameModalState extends ConsumerState<AddGameModal> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _estimatedValueController = TextEditingController();
  final _targetPriceController = TextEditingController();
  final _publisherController = TextEditingController();
  final _yearController = TextEditingController();
  final _customImageUrlController = TextEditingController();

  String _format = 'Physical';
  String _region = 'R1 (USA)';
  GameCondition _conditionValue = GameCondition.cib;
  String _uiPlatform = 'PlayStation 5';
  String _inputCurrency = 'USD';

  bool _isSaving = false;
  bool _isSearching = false;
  bool _configuring = false;
  bool _isScraping = false;

  List<dynamic> _searchResults = [];
  dynamic _selectedGame;
  String? _searchModeLabel;

  final SearchAliasService _aliasService = SearchAliasService();

  @override
  void initState() {
    super.initState();

    if (widget.prefillItem != null) {
      final item = widget.prefillItem!;
      _titleController.text = item.title;
      _uiPlatform = _platformToUiString(item.platform);
      _format = item.platform.isDigital ? 'Digital' : 'Physical';
      _customImageUrlController.text = item.coverUrl ?? '';
      if (item.currentPrice != null) {
        _estimatedValueController.text = item.currentPrice!.toStringAsFixed(2);
      }
      if (item.targetPrice != null) {
        _targetPriceController.text = item.targetPrice!.toStringAsFixed(2);
      }
      _selectedGame = {
        'gameID': item.externalId,
        'external': item.title,
        'thumb': item.coverUrl,
      };
      _configuring = true;
    } else if (widget.initialQuery != null) {
      _titleController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }

    if (widget.initialPlatform != null) {
      _uiPlatform = _platformToUiString(widget.initialPlatform!);
      _format = widget.initialPlatform!.isDigital ? 'Digital' : 'Physical';
    }
  }

  String _platformToUiString(AppPlatform platform) {
    if (platform == AppPlatform.ps4Physical ||
        platform == AppPlatform.ps4Digital) return 'PlayStation 4';
    if (platform == AppPlatform.ps5Physical ||
        platform == AppPlatform.ps5Digital) return 'PlayStation 5';
    if (platform == AppPlatform.nintendo) return 'Nintendo';
    if (platform == AppPlatform.steam) return 'Steam';
    if (platform == AppPlatform.epic) return 'Epic Games';
    return 'PlayStation 5';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _estimatedValueController.dispose();
    _targetPriceController.dispose();
    _publisherController.dispose();
    _yearController.dispose();
    _customImageUrlController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchModeLabel = null;
    });

    try {
      // 1. Try Direct Search
      final firstResults = await _fetchCheapShark(cleanQuery);

      final ownedIds = ref
              .read(libraryStreamProvider)
              .value
              ?.map((g) => g.externalId)
              .whereType<String>()
              .toSet() ??
          {};

      if (firstResults.isNotEmpty) {
        firstResults.sort((a, b) {
          final aMap = a as Map<String, dynamic>;
          final bMap = b as Map<String, dynamic>;
          final aOwned = ownedIds.contains(aMap['gameID']?.toString());
          final bOwned = ownedIds.contains(bMap['gameID']?.toString());
          if (aOwned && !bOwned) return -1;
          if (!aOwned && bOwned) return 1;
          return 0;
        });

        if (mounted) {
          setState(() {
            _searchResults = firstResults;
          });
        }
        return;
      }

      // 2. Fallback to Alias Expansion
      final expandedQuery = _aliasService.expandQuery(cleanQuery);
      if (expandedQuery != cleanQuery) {
        debugPrint(
            '[Search] No results for "$cleanQuery", trying expanded: "$expandedQuery"');
        final secondResults = await _fetchCheapShark(expandedQuery);

        secondResults.sort((a, b) {
          final aMap = a as Map<String, dynamic>;
          final bMap = b as Map<String, dynamic>;
          final aOwned = ownedIds.contains(aMap['gameID']?.toString());
          final bOwned = ownedIds.contains(bMap['gameID']?.toString());
          if (aOwned && !bOwned) return -1;
          if (!aOwned && bOwned) return 1;
          return 0;
        });

        if (mounted) {
          setState(() {
            _searchResults = secondResults;
            _searchModeLabel = secondResults.isNotEmpty
                ? 'Results for "$expandedQuery"'
                : null;
          });
        }
        return;
      }

      // 3. No results found
      if (mounted) {
        setState(() {
          _searchResults = [];
        });
      }
    } catch (e) {
      debugPrint('[Search] Exception: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<List<dynamic>> _fetchCheapShark(String title) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'search-games',
        body: {'query': title, 'limit': 15},
      );
      if (response.status == 200) {
        return List<dynamic>.from(response.data as List);
      }
    } catch (e) {
      debugPrint('[Search] Edge function error: $e');
    }
    return [];
  }

  Future<void> _scrapePhysicalPrice(Game tempGame) async {
    setState(() => _isScraping = true);
    try {
      final priceService = ref.read(priceServiceProvider);
      final priceData = await priceService.fetchPrices(tempGame, force: true);

      if (priceData != null && mounted) {
        final price = priceData.priceForCondition(_conditionValue);
        if (price != null) {
          setState(() {
            _estimatedValueController.text = price.toStringAsFixed(2);
          });
        }
      }
    } catch (e) {
      debugPrint('Price fetch error: $e');
    } finally {
      if (mounted) setState(() => _isScraping = false);
    }
  }

  void _onSearchChanged(String query) {
    if (query.length > 2) {
      _performSearch(query);
    } else {
      setState(() => _searchResults.clear());
    }
  }

  AppPlatform get _resolvedPlatform {
    bool isPhys = _format == 'Physical';
    switch (_uiPlatform) {
      case 'PlayStation 4':
        return isPhys ? AppPlatform.ps4Physical : AppPlatform.ps4Digital;
      case 'PlayStation 5':
        return isPhys ? AppPlatform.ps5Physical : AppPlatform.ps5Digital;
      case 'Nintendo':
        return AppPlatform.nintendo;
      case 'Steam':
        return AppPlatform.steam;
      case 'Epic Games':
        return AppPlatform.epic;
      default:
        return AppPlatform.steam;
    }
  }

  Future<void> _saveGame() async {
    setState(() => _isSaving = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final gameId = const Uuid().v4();

      final isPhys = _format == 'Physical';

      num rawPrice = double.tryParse(_priceController.text) ?? 0;
      num rawEstimated = double.tryParse(_estimatedValueController.text) ?? 0;
      num rawTarget = double.tryParse(_targetPriceController.text) ?? 0;

      if (_inputCurrency == 'LKR') {
        final currencyState = ref.read(currencyProvider);
        rawPrice = rawPrice / currencyState.lkrRate;
        rawEstimated = rawEstimated / currencyState.lkrRate;
        rawTarget = rawTarget / currencyState.lkrRate;
      }

      final selected = _selectedGame as Map<String, dynamic>;
      final String? steamAppId = selected['steamAppID']?.toString();
      String finalCoverUrl = steamAppId != null && steamAppId.isNotEmpty
          ? 'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/$steamAppId/library_600x900.jpg'
          : selected['thumb']?.toString() ?? '';

      if (_customImageUrlController.text.isNotEmpty) {
        finalCoverUrl = _customImageUrlController.text.trim();
      }

      if (widget.isWishlistMode) {
        final newItem = WishlistItem(
          id: gameId,
          userId: userId,
          title: _titleController.text,
          coverUrl: finalCoverUrl,
          platform: _resolvedPlatform,
          externalId: selected['gameID']?.toString(),
          targetPrice: rawTarget > 0 ? rawTarget.toDouble() : null,
          currentPrice: selected['cheapest'] != null
              ? double.tryParse(selected['cheapest'].toString())
              : null,
        );
        await ref.read(wishlistRepositoryProvider).addWishlistItem(newItem);
      } else {
        final newGame = Game(
          id: gameId,
          collectionId: userId,
          userId: userId,
          title: _titleController.text,
          coverUrl: finalCoverUrl,
          platform: _resolvedPlatform,
          externalId: selected['gameID']?.toString(),
          format: _format,
          region: isPhys ? _region : null,
          condition: _conditionValue,
          purchasePrice: rawPrice > 0 ? rawPrice.toDouble() : null,
          estimatedValue: !isPhys && selected['cheapest'] != null
              ? double.tryParse(selected['cheapest'].toString())
              : (rawEstimated > 0 ? rawEstimated.toDouble() : null),
          publisher: _publisherController.text.isNotEmpty
              ? _publisherController.text
              : null,
          releaseYear: int.tryParse(_yearController.text),
        );

        await ref.read(gameRepositoryProvider).addGame(newGame);
        ref.invalidate(allGamesProvider);
        ref.invalidate(homeControllerProvider);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(widget.isWishlistMode
                ? 'Game added to Wishlist!'
                : 'Game added to Collection!'),
            backgroundColor: Colors.cyan));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 32,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: 300.ms,
        child: _configuring
            ? _buildConfigurator(textColor, isDark)
            : _buildSearchPhase(textColor),
      ),
    );
  }

  Widget _buildSearchPhase(Color textColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.isWishlistMode ? 'SAVE FOR LATER' : 'FIND NEW GEMS',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: textColor,
              ),
            ),
            if (_uiPlatform != 'Steam' && _uiPlatform != 'Epic Games')
              IconButton(
                icon: Icon(Icons.qr_code_scanner, color: textColor),
                onPressed: _scanBarcode,
                tooltip: 'Scan Barcode',
              ),
          ],
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _titleController,
          onChanged: _onSearchChanged,
          autofocus: true,
          style: TextStyle(color: textColor, fontSize: 18),
          decoration: InputDecoration(
            hintText: 'Search for a game title...',
            hintStyle: TextStyle(color: textColor.withValues(alpha: 0.3)),
            prefixIcon:
                Icon(Icons.search, color: textColor.withValues(alpha: 0.5)),
            filled: true,
            fillColor: textColor.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: Center(child: CircularProgressIndicator(color: Colors.cyan)),
          ),
        if (!_isSearching && _searchResults.isNotEmpty) ...[
          const SizedBox(height: 16),
          if (_searchModeLabel != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(_searchModeLabel!,
                  style: TextStyle(
                      color: textColor.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontStyle: FontStyle.italic)),
            ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 350),
            child: ListView.separated(
              itemCount: _searchResults.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _buildSearchResultRow(
                  _searchResults[index], textColor, index),
            ),
          ),
        ],
        if (!_isSearching &&
            _searchResults.isEmpty &&
            _titleController.text.length > 2)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Column(
              children: [
                Icon(Icons.search_off,
                    size: 48, color: textColor.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                Text('No matches found. Try expanding your search.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textColor.withValues(alpha: 0.4))),
                const SizedBox(height: 32),
                const Text('HAVE A STEAM ACCOUNT?',
                    style: TextStyle(
                        color: Colors.white24,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => const LibrarySyncView(),
                    );
                  },
                  icon: const FaIcon(FontAwesomeIcons.steam,
                      size: 16, color: Colors.blueAccent),
                  label: const Text('SYNC YOUR ENTIRE STEAM LIBRARY',
                      style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSearchResultRow(dynamic gameObj, Color textColor, int index) {
    final game = gameObj as Map<String, dynamic>;
    final String? steamAppId = game['steamAppID']?.toString();
    final String? thumb = steamAppId != null && steamAppId.isNotEmpty
        ? 'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/$steamAppId/library_600x900.jpg'
        : game['thumb']?.toString();
    final String title = game['external']?.toString() ?? 'Unknown Title';
    final String gameId = game['gameID']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: SizedBox(
          width: 50,
          child: Hero(
            tag: 'search_preview_$gameId',
            child: GameBox3D(coverUrl: thumb, title: title),
          ),
        ),
        title: Text(title,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        onTap: () {
          _titleController.text = title;
          setState(() {
            _selectedGame = game;
            _configuring = true;
          });
          if (_resolvedPlatform.isPlayStation ||
              _resolvedPlatform == AppPlatform.nintendo) {
            final tempGame = Game(
              id: '',
              collectionId: '',
              userId: '',
              title: title,
              platform: _resolvedPlatform,
              condition: _conditionValue,
            );
            unawaited(_scrapePhysicalPrice(tempGame));
          } else if (_resolvedPlatform.isDigital) {
            final cheapest = game['cheapest'];
            if (cheapest != null) {
              _estimatedValueController.text = cheapest.toString();
            }
          }
        },
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: (index * 50).ms)
        .slideX(begin: 0.1, end: 0);
  }

  Widget _buildConfigurator(Color textColor, bool isDark) {
    bool isPhys = _format == 'Physical';
    final selected = _selectedGame as Map<String, dynamic>;

    String? steamAppId = selected['steamAppID']?.toString();
    String? thumb = steamAppId != null && steamAppId.isNotEmpty
        ? 'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/$steamAppId/library_600x900.jpg'
        : selected['thumb']?.toString();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
                icon: Icon(Icons.arrow_back, color: textColor),
                onPressed: () => setState(() => _configuring = false)),
            Expanded(
                child: Text('Configure Details',
                    style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w900))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
                width: 80,
                height: 110,
                child: GameBox3D(
                    coverUrl: _customImageUrlController.text.isNotEmpty
                        ? _customImageUrlController.text
                        : thumb,
                    title: _titleController.text)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    style: TextStyle(
                        color: textColor, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                        labelText: 'Title', border: InputBorder.none),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: _uiPlatform,
                          dropdownColor:
                              isDark ? const Color(0xFF1A1A1A) : Colors.white,
                          style: TextStyle(color: textColor),
                          items: [
                            'PlayStation 5',
                            'PlayStation 4',
                            'Nintendo',
                            'Steam',
                            'Epic Games'
                          ]
                              .map((p) =>
                                  DropdownMenuItem(value: p, child: Text(p)))
                              .toList(),
                          onChanged: (v) => setState(() => _uiPlatform = v!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _format,
                        dropdownColor:
                            isDark ? const Color(0xFF1A1A1A) : Colors.white,
                        style: TextStyle(color: textColor),
                        items: ['Physical', 'Digital']
                            .map((f) =>
                                DropdownMenuItem(value: f, child: Text(f)))
                            .toList(),
                        onChanged: (v) => setState(() => _format = v!),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (isPhys) ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('REGION',
                        style: TextStyle(
                            color: Colors.white24,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: _region,
                      dropdownColor:
                          isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      items: ['R1 (USA)', 'R2 (UK/EU)', 'R3 (Asia)', 'Japan']
                          .map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (v) => setState(() => _region = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CONDITION',
                        style: TextStyle(
                            color: Colors.white24,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    DropdownButton<GameCondition>(
                      isExpanded: true,
                      value: _conditionValue,
                      dropdownColor:
                          isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      items: GameCondition.values
                          .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                  c.toString().split('.').last.toUpperCase())))
                          .toList(),
                      onChanged: (v) => setState(() {
                        _conditionValue = v!;
                        final tempGame = Game(
                          id: '',
                          collectionId: '',
                          userId: '',
                          title: _titleController.text,
                          platform: _resolvedPlatform,
                          condition: _conditionValue,
                        );
                        unawaited(_scrapePhysicalPrice(tempGame));
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CURRENCY',
                      style: TextStyle(
                          color: Colors.white24,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: _inputCurrency,
                    dropdownColor:
                        isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    items: ['USD', 'LKR']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _inputCurrency = v!),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText:
                      widget.isWishlistMode ? 'TARGET PRICE' : 'PURCHASE PRICE',
                  prefixText: _inputCurrency == 'USD' ? '\$ ' : 'Rs. ',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _estimatedValueController,
          keyboardType: TextInputType.number,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: 'MARKET VALUE (AUTO)',
            suffixIcon: _isScraping
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : null,
            prefixText: _inputCurrency == 'USD' ? '\$ ' : 'Rs. ',
          ),
        ),
        const SizedBox(height: 24),
        ExpansionTile(
          title: const Text('Advanced Options',
              style: TextStyle(fontSize: 14, color: Colors.white54)),
          childrenPadding: const EdgeInsets.only(bottom: 16),
          children: [
            TextField(
              controller: _publisherController,
              decoration: const InputDecoration(labelText: 'Publisher'),
              style: TextStyle(color: textColor),
            ),
            TextField(
              controller: _yearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Release Year'),
              style: TextStyle(color: textColor),
            ),
            TextField(
              controller: _customImageUrlController,
              decoration: const InputDecoration(labelText: 'Custom Image URL'),
              style: TextStyle(color: textColor),
            ),
          ],
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveGame,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black))
              : Text(
                  widget.isWishlistMode
                      ? 'SAVE TO WISHLIST'
                      : 'ADD TO MY COLLECTION',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        ),
      ],
    );
  }

  Future<void> _scanBarcode() async {
    final String? upc = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerView()),
    );

    if (upc != null && upc.isNotEmpty) {
      final service = BarcodeService();
      final resultObj = await service.fetchGameByUPC(upc);

      if (mounted && resultObj != null) {
        final result = resultObj;
        await HapticFeedback.mediumImpact();
        setState(() {
          _selectedGame = {
            'external': result['title']?.toString(),
            'gameID': 'upc_$upc',
            'thumb': result['thumb']?.toString(),
          };
          _titleController.text = result['title']?.toString() ?? '';
          _format = 'Physical';
          _region = 'R1 (USA)';
          _conditionValue = GameCondition.cib;
          _inputCurrency = 'USD';
          _priceController.clear();
          _estimatedValueController.clear();
          _customImageUrlController.text = result['thumb']?.toString() ?? '';
          _configuring = true;
        });

        // Trigger an automatic price scrape if it's a physical disc
        final tempGame = Game(
          id: '',
          collectionId: '',
          userId: '',
          title: result['title']?.toString() ?? '',
          platform: AppPlatform.ps5Physical, // Default for disc scanning
          condition: GameCondition.cib,
        );
        unawaited(_scrapePhysicalPrice(tempGame));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Could not identify game from barcode. Try searching manually.')),
        );
      }
    }
  }
}
