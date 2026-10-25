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
import '../collections/widgets/search_result_tile.dart';
import 'barcode_scanner_view.dart';
import '../../core/tokens.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/comic.dart';
import '../../widgets/v_form.dart';

class AddGameModal extends ConsumerStatefulWidget {
  final bool isWishlistMode;
  final String? initialQuery;
  final AppPlatform? initialPlatform;
  final WishlistItem? prefillItem;

  /// Open the camera straight away (Home's "Scan barcode" shortcut).
  final bool autoScan;

  const AddGameModal({
    super.key,
    this.isWishlistMode = false,
    this.initialQuery,
    this.initialPlatform,
    this.prefillItem,
    this.autoScan = false,
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
  bool _searchFailed = false;
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

    if (widget.autoScan) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scanBarcode();
      });
    }

    if (widget.initialPlatform != null) {
      _uiPlatform = _platformToUiString(widget.initialPlatform!);
      _format = widget.initialPlatform!.isDigital ? 'Digital' : 'Physical';
    }
  }

  String _platformToUiString(AppPlatform platform) {
    if (platform == AppPlatform.ps4Physical ||
        platform == AppPlatform.ps4Digital) {
      return 'PlayStation 4';
    }
    if (platform == AppPlatform.ps5Physical ||
        platform == AppPlatform.ps5Digital) {
      return 'PlayStation 5';
    }
    if (platform == AppPlatform.nintendo) {
      return 'Nintendo';
    }
    if (platform == AppPlatform.steam) {
      return 'Steam';
    }
    if (platform == AppPlatform.epic) {
      return 'Epic Games';
    }
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
      _searchFailed = false;
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
      debugPrint('[Search] search-games answered ${response.status}');
    } catch (e) {
      debugPrint('[Search] Edge function error: $e');
    }
    // An empty list means "no matches". A failure must not look the same.
    if (mounted) setState(() => _searchFailed = true);
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
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Couldn\u2019t save. Check your connection and try again.')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    final configuring = _configuring;
    return VSheetFrame(
      eyebrow: widget.isWishlistMode ? 'WISHLIST' : 'LIBRARY',
      title: configuring
          ? 'Confirm details'
          : (widget.isWishlistMode ? 'Save for later' : 'Add a game'),
      onClose: () => Navigator.pop(context),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey(configuring),
          child: configuring ? _buildConfigurator(t) : _buildSearchPhase(t),
        ),
      ),
    );
  }

  Widget _chip(VTokens t, String label, bool on, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        selected: on,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
              color: on ? t.money : t.bg,
              border: Border.all(color: on ? t.line : t.soft, width: 2)),
          child: Text(label,
              style: VText.body(13, on ? t.onMoney : t.text,
                  weight: FontWeight.w900)),
        ),
      ),
    );
  }

  Widget _label(VTokens t, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child:
            Text(text, style: VText.body(13, t.text, weight: FontWeight.w900)),
      );

  Widget _buildSearchPhase(VTokens t) {
    final q = _titleController.text.trim();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: VField(
                label: 'Game title',
                controller: _titleController,
                hint: 'e.g. Persona 5 Royal',
                onChanged: _onSearchChanged,
              ),
            ),
            if (_uiPlatform != 'Steam' && _uiPlatform != 'Epic Games') ...[
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: PressableBox(
                  onTap: _scanBarcode,
                  semanticLabel: 'Scan barcode',
                  shadowOffset: 3,
                  minHeight: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.qr_code_scanner, color: t.text),
                ),
              ),
            ],
          ],
        ),
        if (_isSearching)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator(color: t.text)),
          ),
        if (!_isSearching && _searchResults.isNotEmpty) ...[
          const SizedBox(height: 14),
          if (_searchModeLabel != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(_searchModeLabel!,
                  style: VText.body(12, t.muted, weight: FontWeight.w500)),
            ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 340),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _buildSearchResultRow(_searchResults[index], t, index),
            ),
          ),
        ],
        if (!_isSearching && q.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                    'Type a title and pick it from the list, or scan the barcode on the case.',
                    style: VText.body(13, t.muted, weight: FontWeight.w500)),
                const SizedBox(height: 18),
                PressableBox(
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => const LibrarySyncView(),
                    );
                  },
                  shadowOffset: 3,
                  semanticLabel: 'Sync Steam library',
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(FontAwesomeIcons.steam, size: 16, color: t.text),
                        const SizedBox(width: 10),
                        Text('Import my whole Steam library',
                            style: VText.body(14, t.text,
                                weight: FontWeight.w900)),
                      ]),
                ),
              ],
            ),
          ),
        if (!_isSearching && _searchFailed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Semantics(
              liveRegion: true,
              child: Text(
                  'Search isn’t working right now. Check your connection and try again in a moment.',
                  textAlign: TextAlign.center,
                  style: VText.body(14, t.lossInk, weight: FontWeight.w700)),
            ),
          ),
        if (!_isSearching &&
            !_searchFailed &&
            _searchResults.isEmpty &&
            q.length > 2)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('No matches. Try fewer words, or check the spelling.',
                textAlign: TextAlign.center,
                style: VText.body(14, t.muted, weight: FontWeight.w500)),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSearchResultRow(dynamic gameObj, VTokens t, int index) {
    final game = gameObj as Map<String, dynamic>;
    final String? steamAppId = game['steamAppID']?.toString();
    final String? thumb = steamAppId != null && steamAppId.isNotEmpty
        ? 'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/$steamAppId/library_600x900.jpg'
        : game['thumb']?.toString();
    final String title = game['external']?.toString() ?? 'Unknown Title';

    final row = SearchResultTile(
      title: title,
      thumbUrl: thumb,
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
    );
    if (index > 5) return row;
    return row
        .animate()
        .fadeIn(duration: 220.ms, delay: (index * 40).ms)
        .slideY(begin: 0.04, end: 0, duration: 220.ms, delay: (index * 40).ms);
  }

  Widget _buildConfigurator(VTokens t) {
    final isPhys = _format == 'Physical';
    final selected = _selectedGame as Map<String, dynamic>;
    final steamAppId = selected['steamAppID']?.toString();
    final thumb = steamAppId != null && steamAppId.isNotEmpty
        ? 'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/$steamAppId/library_600x900.jpg'
        : selected['thumb']?.toString();
    final prefix = _inputCurrency == 'USD' ? '\$ ' : 'Rs. ';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _configuring = false),
            style: TextButton.styleFrom(
                foregroundColor: t.text, minimumSize: const Size(44, 44)),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text('Back to search',
                style: VText.body(13, t.text, weight: FontWeight.w900)),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 84,
                height: 116,
                child: GameBox3D(
                    coverUrl: _customImageUrlController.text.isNotEmpty
                        ? _customImageUrlController.text
                        : thumb,
                    title: _titleController.text)),
            const SizedBox(width: 16),
            Expanded(
              child: VField(label: 'Title', controller: _titleController),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _label(t, 'Platform'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final p in const [
            'PlayStation 5',
            'PlayStation 4',
            'Nintendo',
            'Steam',
            'Epic Games'
          ])
            _chip(
                t, p, _uiPlatform == p, () => setState(() => _uiPlatform = p)),
        ]),
        const SizedBox(height: 20),
        _label(t, 'Format'),
        Wrap(spacing: 8, children: [
          for (final f in const ['Physical', 'Digital'])
            _chip(t, f, _format == f, () => setState(() => _format = f)),
        ]),
        if (isPhys) ...[
          const SizedBox(height: 20),
          VConditionPicker(
            value: _conditionValue,
            onChanged: (c) => setState(() {
              _conditionValue = c;
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
          const SizedBox(height: 20),
          _label(t, 'Region'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final r in const [
              'R1 (USA)',
              'R2 (UK/EU)',
              'R3 (Asia)',
              'Japan'
            ])
              _chip(t, r, _region == r, () => setState(() => _region = r)),
          ]),
        ],
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Currency',
                style: VText.body(13, t.text, weight: FontWeight.w900)),
            const Spacer(),
            VSegmented(
              semanticLabel: 'Currency',
              options: const ['USD', 'LKR'],
              index: _inputCurrency == 'USD' ? 0 : 1,
              onChanged: (i) =>
                  setState(() => _inputCurrency = i == 0 ? 'USD' : 'LKR'),
              height: 36,
            ),
          ],
        ),
        const SizedBox(height: 16),
        VField(
          label: widget.isWishlistMode ? 'Target price' : 'What you paid',
          controller: _priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefixText: prefix,
          hint: '0.00',
          optional: true,
          helper: widget.isWishlistMode
              ? 'We\u2019ll flag the game when the price drops to this.'
              : 'Used to work out your profit or loss.',
        ),
        const SizedBox(height: 16),
        VField(
          label: 'Market value',
          controller: _estimatedValueController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefixText: prefix,
          helper: _isScraping
              ? 'Checking live prices\u2026'
              : 'Filled in from live prices. Change it only if you know better.',
        ),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text('More options',
                style: VText.body(14, t.muted, weight: FontWeight.w900)),
            childrenPadding: const EdgeInsets.only(bottom: 8),
            children: [
              VField(
                  label: 'Publisher',
                  controller: _publisherController,
                  optional: true),
              const SizedBox(height: 14),
              VField(
                  label: 'Release year',
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  optional: true),
              const SizedBox(height: 14),
              VField(
                  label: 'Cover image link',
                  controller: _customImageUrlController,
                  hint: 'https://\u2026',
                  optional: true,
                  onChanged: (_) => setState(() {})),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PressableBox(
          onTap: _isSaving ? null : _saveGame,
          color: t.money,
          minHeight: 54,
          semanticLabel:
              widget.isWishlistMode ? 'Save to wishlist' : 'Add to library',
          child: _isSaving
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: t.onMoney))
              : Text(
                  widget.isWishlistMode ? 'Save to wishlist' : 'Add to library',
                  style: VText.body(15, t.onMoney, weight: FontWeight.w900)),
        ),
        const SizedBox(height: 8),
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
