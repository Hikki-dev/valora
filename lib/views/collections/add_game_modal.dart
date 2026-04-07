import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';

import '../../models/game.dart';
import '../../models/wishlist_item.dart';
import '../../repositories/game_repository.dart';
import '../../repositories/wishlist_repository.dart';
import '../../controllers/home_controller.dart';
import 'widgets/game_box_3d.dart';
import '../../core/currency_provider.dart';
import '../../services/price_service.dart';
import '../../services/barcode_service.dart';
import 'barcode_scanner_view.dart';
import '../../services/search_alias_service.dart';



class AddGameModal extends ConsumerStatefulWidget {
  final bool isWishlistMode;
  final WishlistItem? prefillItem;
  
  const AddGameModal({super.key, this.isWishlistMode = false, this.prefillItem});


  @override
  ConsumerState<AddGameModal> createState() => _AddGameModalState();
}

class _AddGameModalState extends ConsumerState<AddGameModal> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _estimatedValueController = TextEditingController();
  final TextEditingController _publisherController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _customImageUrlController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _targetPriceController = TextEditingController();
  final _aliasService = SearchAliasService();
  String? _searchModeLabel;



  
  bool _isSearching = false;
  bool _isScraping = false;
  List<dynamic> _searchResults = [];
  
  bool _configuring = false;
  dynamic _selectedGame;
  bool _isSaving = false;

  String _format = 'Physical';
  String _uiPlatform = 'PlayStation 5';
  String _region = 'R1 (USA)';
  GameCondition _conditionValue = GameCondition.cib;
  
  String _inputCurrency = 'USD';

  @override
  void initState() {
    super.initState();
    if (widget.prefillItem != null) {
      _targetPriceController.text = widget.prefillItem!.targetPrice?.toString() ?? '';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _preFillFromItem(widget.prefillItem!);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _priceController.dispose();
    _estimatedValueController.dispose();
    _publisherController.dispose();
    _yearController.dispose();
    _customImageUrlController.dispose();
    _titleController.dispose();
    _targetPriceController.dispose();
    super.dispose();
  }


  void _preFillFromItem(WishlistItem item) {
    setState(() {
      _selectedGame = {
        'external': item.title,
        'gameID': item.externalId ?? 'manual_${DateTime.now().millisecondsSinceEpoch}',
        'thumb': item.coverUrl ?? '',
      };
      _titleController.text = item.title;
      _format = 'Physical';
      _uiPlatform = _platformToUI(item.platform);
      _region = 'R1 (USA)';
      _conditionValue = GameCondition.cib;
      _inputCurrency = 'USD';
      _priceController.text = item.targetPrice?.toString() ?? '';
      _customImageUrlController.text = item.coverUrl ?? '';
      _configuring = true;
    });
  }

  String _platformToUI(AppPlatform p) {
    if (p.value.contains('ps4')) return 'PlayStation 4';
    if (p.value.contains('ps5')) return 'PlayStation 5';
    if (p == AppPlatform.nintendo) return 'Nintendo';
    if (p == AppPlatform.steam) return 'Steam';
    return 'Epic Games';
  }
  Future<void> _performSearch(String query) async {
    final cleanQuery = query.trim();
    debugPrint('[Search] Starting search for: "$cleanQuery"');
    
    if (cleanQuery.length <= 2) {
      debugPrint('[Search] Query too short, skipping.');
      if (mounted) {
        setState(() { 
        _isSearching = false; 
        _searchResults = []; 
        _searchModeLabel = null;
      });
      }
      return;
    }

    setState(() {
      _isSearching = true;
      _searchModeLabel = null;
    });

    try {
      // 1. Try Direct Search
      final firstResults = await _fetchCheapShark(cleanQuery);
      
      if (firstResults.isNotEmpty) {
        if (mounted) {
          setState(() {
            _searchResults = firstResults;
            _isSearching = false;
          });
        }
        return;
      }

      // 2. Fallback to Alias Expansion
      final expandedQuery = _aliasService.expandQuery(cleanQuery);
      if (expandedQuery != cleanQuery) {
        debugPrint('[Search] No results for "$cleanQuery", trying expanded: "$expandedQuery"');
        final secondResults = await _fetchCheapShark(expandedQuery);
        
        if (mounted) {
          setState(() {
            _searchResults = secondResults;
            _isSearching = false;
            _searchModeLabel = secondResults.isNotEmpty ? 'Results for "$expandedQuery"' : null;
          });
        }
        return;
      }

      // 3. No results found
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('[Search] Exception: $e');
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<List<dynamic>> _fetchCheapShark(String title) async {
    try {
      final url = 'https://www.cheapshark.com/api/1.0/games?title=${Uri.encodeComponent(title)}&limit=15';
      debugPrint('[Search] Hitting API: $url');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
    } catch (e) {
      debugPrint('[Search] Fetch error: $e');
    }
    return [];
  }



  Future<void> _scrapePhysicalPrice(Game tempGame) async {
    setState(() => _isScraping = true);
    try {
      final ebayService = ref.read(priceServiceProvider).ebayService;
      final priceData = await ebayService.fetchMarketPrice(tempGame);
      
      if (priceData != null && mounted) {
        final price = priceData.priceForCondition(_conditionValue);
        if (price != null) {
          setState(() {
            _estimatedValueController.text = price.toStringAsFixed(2);
          });
        }
      }
    } catch (e) {
      debugPrint('Scrape error: $e');
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
       case 'PlayStation 4': return isPhys ? AppPlatform.ps4Physical : AppPlatform.ps4Digital;
       case 'PlayStation 5': return isPhys ? AppPlatform.ps5Physical : AppPlatform.ps5Digital;
       case 'Nintendo': return AppPlatform.nintendo;
       case 'Steam': return AppPlatform.steam;
       case 'Epic Games': return AppPlatform.epic;
       default: return AppPlatform.steam;
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


      final String? steamAppId = _selectedGame['steamAppID'];
      String finalCoverUrl = steamAppId != null && steamAppId.isNotEmpty
          ? 'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/$steamAppId/library_600x900.jpg'
          : _selectedGame['thumb'] ?? '';
      
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
           externalId: _selectedGame['gameID'],
           targetPrice: rawTarget > 0 ? rawTarget.toDouble() : null,
           currentPrice: _selectedGame['cheapest'] != null ? double.tryParse(_selectedGame['cheapest'].toString()) : null,
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
          externalId: _selectedGame['gameID'],
          format: _format,
          region: isPhys ? _region : null,
          condition: _conditionValue,
          purchasePrice: rawPrice > 0 ? rawPrice.toDouble() : null,
          estimatedValue: !isPhys && _selectedGame['cheapest'] != null 
              ? double.tryParse(_selectedGame['cheapest'].toString()) 
              : (rawEstimated > 0 ? rawEstimated.toDouble() : null),
          publisher: _publisherController.text.isNotEmpty ? _publisherController.text : null,
          releaseYear: int.tryParse(_yearController.text),
        );
        
        await ref.read(gameRepositoryProvider).addGame(newGame);
        ref.invalidate(allGamesProvider);

        ref.invalidate(homeControllerProvider);
      }
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(

          content: Text(widget.isWishlistMode ? 'Game added to Wishlist!' : 'Game added to Collection!'), 
          backgroundColor: Colors.cyan
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D14).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8);
    final textColor = isDark ? Colors.white : Colors.black87;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _configuring ? _buildConfigurator(textColor) : _buildSearchPhase(textColor),
          ),
        ),
      ),
    );
  }

  void _startManualEntry() {
    setState(() {
      _selectedGame = {
        'external': _searchController.text.isNotEmpty ? _searchController.text : '',
        'gameID': 'manual_${DateTime.now().millisecondsSinceEpoch}',
        'thumb': '',
      };
      _titleController.text = _selectedGame['external'];
      _format = 'Physical';
      _uiPlatform = 'PlayStation 5';
      _region = 'R1 (USA)';
      _conditionValue = GameCondition.cib;
      _inputCurrency = 'USD'; 
      _priceController.clear();
      _estimatedValueController.clear();
      _customImageUrlController.text = '';
      _targetPriceController.clear();
      _configuring = true;

    });
  }


  Future<void> _scanBarcode() async {
    final String? upc = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerView()),
    );

    if (upc != null && upc.isNotEmpty) {
      // Show loading
      setState(() => _isSearching = true);
      
      final service = BarcodeService();
      final result = await service.fetchGameByUPC(upc);
      
      if (result != null && mounted) {
        setState(() {
          _isSearching = false;
          _selectedGame = {
            'external': result['title'],
            'gameID': 'upc_$upc',
            'thumb': result['thumb'],
          };
          _titleController.text = result['title'];
          _format = 'Physical';
          _region = 'R1 (USA)';
          _conditionValue = GameCondition.cib;
          _inputCurrency = 'USD'; 
          _priceController.clear();
          _estimatedValueController.clear();
          _customImageUrlController.text = result['thumb'];
          _configuring = true;
        });

        // Trigger an automatic price scrape if it's a physical disc
        final tempGame = Game(
          id: '',
          collectionId: '',
          userId: '',
          title: result['title'],
          platform: AppPlatform.ps5Physical, // Default for disc scanning
          condition: GameCondition.cib,
        );
        _scrapePhysicalPrice(tempGame);
      } else {
        if (mounted) {
          setState(() => _isSearching = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not identify game from barcode. Try searching manually.')),
          );
        }
      }
    }
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
              widget.isWishlistMode ? 'ADD TO WISHLIST' : 'DISCOVER',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: textColor,
              ),
            ),
            IconButton(icon: Icon(Icons.close, color: textColor.withValues(alpha: 0.5)), onPressed: () => Navigator.pop(context))
          ],
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          autofocus: true,
          style: TextStyle(color: textColor, fontSize: 18),

          decoration: InputDecoration(
            hintText: 'Search CheapShark...',
            hintStyle: TextStyle(color: textColor.withValues(alpha: 0.3)),
            prefixIcon: Icon(Icons.search, color: Theme.of(context).primaryColor),
            suffixIcon: widget.isWishlistMode 
                ? null 
                : IconButton(
                    icon: Icon(Icons.barcode_reader, color: Theme.of(context).primaryColor),
                    onPressed: _scanBarcode,
                    tooltip: 'Scan Physical Disc',
                  ),

            filled: true,
            fillColor: textColor.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),

        ),
        const SizedBox(height: 12),
        if (_searchModeLabel != null)
           Padding(
             padding: const EdgeInsets.only(bottom: 8.0),
             child: Text(_searchModeLabel!, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 13, fontStyle: FontStyle.italic)),
           ),
        SizedBox(

          height: 300,
          child: _isSearching
              ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
              : _searchController.text.length > 2
                   ? Column(
                     children: [
                       Expanded(
                         child: _searchResults.isEmpty 
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('No direct results found.', style: TextStyle(color: textColor.withValues(alpha: 0.5))),
                                    if (_searchController.text.toLowerCase().contains('gta 6') || _searchController.text.toLowerCase().contains('gta vi')) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
                                        ),
                                        child: Column(
                                          children: [
                                            const Text('🔥 ANTICIPATED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),

                                            const SizedBox(height: 4),
                                            const Text('Grand Theft Auto VI', style: TextStyle(fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 8),
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  _titleController.text = 'Grand Theft Auto VI';
                                                  _customImageUrlController.text = 'https://media-rockstargames-com.akamaized.net/m0/games/GTAVI/GTAVI_Logo.png';
                                                  _configuring = true;
                                                  _format = 'Digital';
                                                });
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Theme.of(context).primaryColor,
                                                foregroundColor: Colors.white,
                                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                              child: const Text('QUICK ADD TO WISHLIST'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              )
                            : ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                itemCount: _searchResults.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) => _buildSearchResultRow(_searchResults[index], textColor, index),
                              ),
                       ),
                       const SizedBox(height: 16),
                       TextButton.icon(
                         onPressed: _startManualEntry,
                         icon: const Icon(Icons.add_circle_outline, size: 18),
                         label: const Text('Can\'t find it? Add Manually'),
                         style: TextButton.styleFrom(
                           foregroundColor: Theme.of(context).primaryColor,
                           padding: const EdgeInsets.symmetric(vertical: 12),
                         ),
                       ),
                     ],
                   )
                   : Center(child: Text('Your next masterpiece awaits.', style: TextStyle(color: textColor.withValues(alpha: 0.2), fontStyle: FontStyle.italic))),
        ),
      ],
    );
  }


  Widget _buildSearchResultRow(dynamic game, Color textColor, int index) {
    String? steamAppId = game['steamAppID'];
    String? thumb = steamAppId != null && steamAppId.isNotEmpty 
        ? 'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/$steamAppId/library_600x900.jpg'
        : game['thumb'];
    String title = game['external'] ?? 'Unknown Title';
    
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
            tag: 'search_preview_${game['gameID']}',
            child: GameBox3D(coverUrl: thumb, title: title),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: game['cheapest'] != null 
            ? Text(
                'Market Price: \$${game['cheapest']}',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: Container(

          decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).primaryColor.withValues(alpha: 0.1)),
          child: IconButton(
            icon: Icon(Icons.arrow_forward_ios, color: Theme.of(context).primaryColor, size: 18),
            onPressed: () {
                setState(() {
                  _selectedGame = game;
                  _titleController.text = game['external'] ?? 'Unknown Title';
                  _format = 'Digital'; 
                  _region = 'R1 (USA)';

                  _conditionValue = GameCondition.cib;
                  _inputCurrency = 'USD'; 
                  _priceController.clear();
                  _estimatedValueController.clear();
                  _customImageUrlController.text = thumb ?? '';
                  _configuring = true;
                });
                
                if (_resolvedPlatform.isPhysical) {
                   setState(() {
                     _format = 'Physical';
                     _estimatedValueController.text = 'Scraping...';
                   });
                   
                   final tempGame = Game(
                     id: '',
                     collectionId: '',
                     userId: '',
                     title: game['external'] ?? '',
                     platform: _resolvedPlatform,
                     condition: _conditionValue,
                   );
                   _scrapePhysicalPrice(tempGame);
                } else if (_resolvedPlatform.isDigital) {
                   if (game['cheapest'] != null) {
                      _estimatedValueController.text = game['cheapest'].toString();
                   }
                }
              },
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildConfigurator(Color textColor) {
    bool isPhys = _format == 'Physical';
    
    String? steamAppId = _selectedGame['steamAppID'];
    String? thumb = steamAppId != null && steamAppId.isNotEmpty 
        ? 'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/$steamAppId/library_600x900.jpg'
        : _selectedGame['thumb'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () => setState(() => _configuring = false)),
            Expanded(child: Text('Configure Details', style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w900))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
             SizedBox(width: 80, height: 110, child: GameBox3D(coverUrl: _customImageUrlController.text.isNotEmpty ? _customImageUrlController.text : thumb, title: _titleController.text)),
             const SizedBox(width: 16),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   TextField(
                      controller: _titleController,
                      style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Game Title',
                        labelStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                        isDense: true,
                        border: InputBorder.none,
                      ),
                      onChanged: (_) => setState(() {}),
                   ),
                   const SizedBox(height: 8),
                   TextField(
                      controller: _customImageUrlController,

                     style: TextStyle(color: textColor, fontSize: 12),
                     onChanged: (_) => setState(() {}),
                     decoration: InputDecoration(
                        labelText: 'Custom Image URL',
                        labelStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                     ),
                   ),
                 ],
               ),
             ),
          ],
        ),
        const SizedBox(height: 24),
        
        Row(
          children: [
            Expanded(child: _buildDropdown(textColor, 'Format', ['Physical', 'Digital'], _format, (v) => setState(() {
              _format = v!;
              if (_format == 'Physical' && _estimatedValueController.text.isEmpty) {
                final tempGame = Game(
                   id: '',
                   collectionId: '',
                   userId: '',
                   title: _selectedGame['external'] ?? '',
                   platform: _resolvedPlatform,
                   condition: _conditionValue,
                 );
                 _scrapePhysicalPrice(tempGame);
              }
            }))),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Platform', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12)),
                  DropdownButton<String>(
                    value: _uiPlatform,
                    isExpanded: true,
                    dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                    style: TextStyle(color: textColor),
                    items: ['PlayStation 4', 'PlayStation 5', 'Nintendo', 'Steam', 'Epic Games'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (v) => setState(() {
                      _uiPlatform = v!;
                      bool isPs = _uiPlatform.startsWith('PlayStation');
                      final List<String> rCodes = ['R1 (USA)', 'R2 (PAL/Japan)', 'R3 (Asia)', 'R4 (LATAM/Aus)', 'Region Free'];
                      final List<String> ntsc = ['NTSC-U', 'PAL', 'NTSC-J', 'Region Free'];
                      if (isPs && !rCodes.contains(_region)) _region = rCodes.first;
                      if (!isPs && !ntsc.contains(_region)) _region = ntsc.first;
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (isPhys) Row(
          children: [
            Expanded(child: _buildDropdown(textColor, 'Region', 
              _uiPlatform.startsWith('PlayStation') 
                  ? ['R1 (USA)', 'R2 (PAL/Japan)', 'R3 (Asia)', 'R4 (LATAM/Aus)', 'Region Free']
                  : ['NTSC-U', 'PAL', 'NTSC-J', 'Region Free'], 
              _region, (v) => setState(() => _region = v!))),
            const SizedBox(width: 16),
            Expanded(child: _buildDropdown(
              textColor, 
              'Condition', 
              GameCondition.values.map((e) => e.label).toList(), 
              _conditionValue.label, 
              (v) => setState(() {
                _conditionValue = GameCondition.fromString(v);
                final tempGame = Game(
                   id: '',
                   collectionId: '',
                   userId: '',
                   title: _selectedGame['external'] ?? '',
                   platform: _resolvedPlatform,
                   condition: _conditionValue,
                 );
                 _scrapePhysicalPrice(tempGame);
              })
            )),
          ],
        ),
        const SizedBox(height: 16),

        Consumer(
          builder: (context, ref, child) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: widget.isWishlistMode ? _targetPriceController : _priceController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: widget.isWishlistMode ? 'Target Price (Alert me below this)' : 'Purchase Price (Optional)',
                          labelStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                          prefixIcon: Icon(
                            widget.isWishlistMode ? Icons.notifications_active : (_inputCurrency == 'USD' ? Icons.attach_money : Icons.money), 
                            color: Theme.of(context).primaryColor
                          ),
                          filled: true,
                          fillColor: textColor.withValues(alpha: 0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: textColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _inputCurrency,
                            isExpanded: true,
                            dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                            items: ['USD', 'LKR'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (v) => setState(() => _inputCurrency = v!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (isPhys) ...[
                  const SizedBox(height: 16),
                  Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      TextField(
                        controller: _estimatedValueController,
                        keyboardType: TextInputType.text,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'eBay Market Average (Optional)',
                          labelStyle:
                              TextStyle(color: textColor.withValues(alpha: 0.5)),
                          prefixIcon: Icon(
                              Icons.trending_up,
                              color: Theme.of(context).primaryColor),
                          filled: true,
                          fillColor: textColor.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                      ),
                      if (_isScraping)
                        const Padding(
                          padding: EdgeInsets.only(right: 16.0),
                          child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _publisherController,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Publisher',
                            labelStyle: TextStyle(
                                color: textColor.withValues(alpha: 0.5)),
                            filled: true,
                            fillColor: textColor.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _yearController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Year',
                            labelStyle: TextStyle(
                                color: textColor.withValues(alpha: 0.5)),
                            filled: true,
                            fillColor: textColor.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 32),

        _isSaving ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)) : 
        ElevatedButton(
          onPressed: _saveGame,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(widget.isWishlistMode ? 'Add to Wishlist' : 'Confirm & Save', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

        ),
      ],
    );
  }

  Widget _buildDropdown(Color textColor, String label, List<String> options, String currentValue, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12)),
        DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          dropdownColor: Theme.of(context).scaffoldBackgroundColor,
          style: TextStyle(color: textColor),
          items: options.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
