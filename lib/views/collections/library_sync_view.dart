import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/library_sync_service.dart';
import '../../models/game.dart';
import '../../repositories/game_repository.dart';
import '../../controllers/home_controller.dart';
import 'widgets/game_box_3d.dart';

class LibrarySyncView extends ConsumerStatefulWidget {
  const LibrarySyncView({super.key});

  @override
  ConsumerState<LibrarySyncView> createState() => _LibrarySyncViewState();
}

class _LibrarySyncViewState extends ConsumerState<LibrarySyncView> {
  bool _isLoading = false;
  List<Game> _discoveredGames = [];
  Map<String, Game> _conflicts = {};
  final Set<String> _selectedToOverwrite = {};
  
  final TextEditingController _steamIdController = TextEditingController();

  Future<void> _fetchSteamLibrary() async {
    final steamId = _steamIdController.text.trim();
    if (steamId.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mind sharing your Steam ID first?')));
       return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      
      final games = await ref.read(librarySyncServiceProvider).syncSteam(userId, steamId);
      
      // Look for conflicts
      final repo = ref.read(gameRepositoryProvider);
      final externalIds = games.map((g) => g.externalId!).toList();
      final existingGames = await repo.getExistingGamesByExternalIds(userId, AppPlatform.steam, externalIds);

      if (mounted) {
        setState(() {
          _discoveredGames = games;
          _conflicts = existingGames;
          _isLoading = false;
          // By default, let's not overwrite anything to stay safe
          _selectedToOverwrite.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Oops! Something went wrong: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _finalizeSync() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(gameRepositoryProvider);
      
      final List<Game> toInsert = [];
      final List<Game> toUpdate = [];

      for (final game in _discoveredGames) {
        if (_conflicts.containsKey(game.externalId)) {
          if (_selectedToOverwrite.contains(game.externalId)) {
            // Update with new data but keep the existing UUID!
            final existing = _conflicts[game.externalId]!;
            toUpdate.add(game.copyWithLocalId(existing.id));
          }
        } else {
          toInsert.add(game);
        }
      }

      // 1. Batch insert new games
      if (toInsert.isNotEmpty) {
        await repo.addGamesBatch(toInsert);
      }
      
      // 2. Batch update resolved games (using upsert logic)
      if (toUpdate.isNotEmpty) {
        await repo.addGamesBatch(toUpdate);
      }

      ref.invalidate(allGamesProvider);
      ref.invalidate(homeControllerProvider);

      if (mounted) {
        Navigator.pop(context, true);
        final count = toInsert.length + toUpdate.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All set! Imported $count games into your collection.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Couldn\'t save those games: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.6),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(icon: Icon(Icons.close, color: textColor), onPressed: () => Navigator.pop(context)),
          title: Text(
            'CONNECT YOUR LIBRARY',
            style: TextStyle(color: textColor, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 14),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _discoveredGames.isEmpty ? _buildSteamInput(textColor) : _buildReviewList(textColor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSteamInput(Color textColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FaIcon(FontAwesomeIcons.steam, color: Colors.white, size: 64).animate().scale(delay: 200.ms),
        const SizedBox(height: 32),
        Text(
          'Sync your Steam library in seconds.',
          style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'We\'ll only see your public game list. No passwords or sensitive data are ever touched.',
          style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        TextField(
          controller: _steamIdController,
          decoration: InputDecoration(
            labelText: 'Your Steam ID (64-bit)',
            hintText: 'e.g. 76561198...',
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.person_outline, color: Colors.blueAccent),
          ),
          style: TextStyle(color: textColor),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.help_outline, color: Colors.blueAccent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'How to find your Steam ID?',
                    style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 12, height: 1.5),
                  children: [
                    const TextSpan(text: '1. Go to your Steam Profile\n2. Right-click and "Copy Page URL"\n3. Paste it at '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: GestureDetector(
                        onTap: () async {
                          final url = Uri.parse('https://steamid.io');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Text(
                          'steamid.io',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.blueAccent.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    const TextSpan(text: ' to get your "SteamID64"'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _fetchSteamLibrary,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('FIND MY GAMES', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildReviewList(Color textColor) {
    final conflictCount = _conflicts.length;
    final newCount = _discoveredGames.length - conflictCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WE FOUND ${_discoveredGames.length} GAMES',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 18),
                ),
                Text(
                  '$newCount new, $conflictCount already in collection',
                  style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 14),
                ),
              ],
            ),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() {
                _discoveredGames = [];
                _conflicts = {};
              }),
              child: const Text('Restart'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.separated(
            itemCount: _discoveredGames.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final game = _discoveredGames[index];
              final hasConflict = _conflicts.containsKey(game.externalId);
              final isOverwriting = _selectedToOverwrite.contains(game.externalId);

              return _buildGameSyncTile(game, hasConflict, isOverwriting, textColor);
            },
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              if (conflictCount > 0) ...[
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blueAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'We found some duplicates. Tap them to choose which details to keep.',
                        style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _finalizeSync,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          conflictCount > 0 ? 'FINALIZE & IMPORT' : 'SAVE TO COLLECTION',
                          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildGameSyncTile(Game game, bool hasConflict, bool isOverwriting, Color textColor) {
    return GestureDetector(
      onTap: hasConflict ? () => _showConflictResolution(game) : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasConflict 
              ? (isOverwriting ? Colors.orange.withValues(alpha: 0.1) : Colors.blueAccent.withValues(alpha: 0.05))
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: hasConflict && isOverwriting 
              ? Border.all(color: Colors.orange.withValues(alpha: 0.3)) 
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 66,
              child: GameBox3D(coverUrl: game.coverUrl, title: game.title),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(game.title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  if (hasConflict)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOverwriting ? Colors.orange : Colors.blueAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isOverwriting ? 'UPDATING DATA' : 'KEEPING YOURS',
                        style: TextStyle(color: isOverwriting ? Colors.black : Colors.blueAccent, fontSize: 9, fontWeight: FontWeight.w900),
                      ),
                    )
                  else
                    const Text('New Game • Steam', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            if (hasConflict)
              Icon(Icons.chevron_right, color: textColor.withValues(alpha: 0.2), size: 16),
          ],
        ),
      ),
    );
  }

  void _showConflictResolution(Game newGame) {
    final existingGame = _conflicts[newGame.externalId]!;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isCurrentlyOverwriting = _selectedToOverwrite.contains(newGame.externalId);

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Which version should we keep?',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                  child: Text(
                    'We found "${newGame.title}" in your collection already.',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current Version
                        Expanded(
                          child: _buildVersionCard(
                            'Your Version', 
                            existingGame, 
                            !isCurrentlyOverwriting, 
                            () {
                              if (newGame.externalId != null) {
                                setState(() => _selectedToOverwrite.remove(newGame.externalId!));
                              }
                              setModalState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // New Version
                        Expanded(
                          child: _buildVersionCard(
                            'Latest from Steam', 
                            newGame, 
                            isCurrentlyOverwriting, 
                            () {
                              if (newGame.externalId != null) {
                                setState(() => _selectedToOverwrite.add(newGame.externalId!));
                              }
                              setModalState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildVersionCard(String title, Game game, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? Colors.blueAccent : Colors.white.withValues(alpha: 0.1), width: 2),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 140,
                  width: 100,
                  child: GameBox3D(coverUrl: game.coverUrl, title: game.title),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(color: isSelected ? Colors.blueAccent : Colors.white54, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Title', game.title),
                _buildInfoRow('Format', game.format),
                if (game.purchasePrice != null && game.purchasePrice! > 0)
                  _buildInfoRow('Price', '\$${game.purchasePrice!.toStringAsFixed(2)}'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (isSelected) const Icon(Icons.check_circle, color: Colors.blueAccent, size: 24),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.white24, fontSize: 10)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 10), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

extension on Game {
  // Helper to keep UUID when updating
  Game copyWithLocalId(String localId) {
    return copyWith(id: localId);
  }
}
