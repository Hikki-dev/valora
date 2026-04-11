import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/game.dart';
import '../../repositories/game_repository.dart';

class EditGameSheet extends ConsumerStatefulWidget {
  final Game game;
  const EditGameSheet({super.key, required this.game});

  @override
  ConsumerState<EditGameSheet> createState() => _EditGameSheetState();
}

class _EditGameSheetState extends ConsumerState<EditGameSheet> {
  late GameCondition _condition;
  late TextEditingController _purchasePriceController;
  late TextEditingController _notesController;
  late TextEditingController _coverUrlController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _condition = widget.game.condition;
    _purchasePriceController = TextEditingController(
        text: widget.game.purchasePrice?.toString() ?? '');
    _notesController = TextEditingController(text: widget.game.notes ?? '');
    _coverUrlController =
        TextEditingController(text: widget.game.coverUrl ?? '');
  }

  @override
  void dispose() {
    _purchasePriceController.dispose();
    _notesController.dispose();
    _coverUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final double? pPrice = double.tryParse(_purchasePriceController.text);
      final updatedGame = widget.game.copyWith(
        condition: _condition,
        purchasePrice: pPrice,
        notes: _notesController.text.trim(),
        coverUrl: _coverUrlController.text.trim(),
      );

      // We need to implement an updateGame method in the repository
      // For now, we'll use a direct supabase call or update the repo
      await ref.read(gameRepositoryProvider).updateGame(updatedGame);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Game updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating game: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor =
        isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05);

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 32,
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'EDIT GAME',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close,
                      color: textColor.withValues(alpha: 0.5)),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Condition Chips
            Text('CONDITION',
                style: TextStyle(
                    color: textColor.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: GameCondition.values.map((c) {
                final isSelected = _condition == c;
                return ChoiceChip(
                  label: Text(c.label),
                  selected: isSelected,
                  onSelected: (val) => setState(() => _condition = c),
                  selectedColor: Colors.orangeAccent.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.orangeAccent : textColor,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color:
                          isSelected ? Colors.orangeAccent : Colors.transparent,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Purchase Price
            _buildTextField(
              label: 'PURCHASE PRICE',
              controller: _purchasePriceController,
              keyboardType: TextInputType.number,
              hint: '0.00',
              prefix: const Icon(Icons.attach_money,
                  color: Colors.greenAccent, size: 20),
              textColor: textColor,
              cardColor: cardColor,
            ),

            const SizedBox(height: 24),

            // Cover URL
            _buildTextField(
              label: 'CUSTOM COVER URL',
              controller: _coverUrlController,
              hint: 'https://...',
              prefix: const Icon(Icons.image_outlined,
                  color: Colors.cyanAccent, size: 20),
              textColor: textColor,
              cardColor: cardColor,
            ),

            const SizedBox(height: 24),

            // Notes
            _buildTextField(
              label: 'NOTES',
              controller: _notesController,
              hint: 'Where you bought it or general notes...',
              maxLines: 3,
              prefix:
                  const Icon(Icons.notes, color: Colors.blueAccent, size: 20),
              textColor: textColor,
              cardColor: cardColor,
            ),

            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.black),
                        ),
                      )
                    : const Text(
                        'SAVE CHANGES',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    Widget? prefix,
    int maxLines = 1,
    TextInputType? keyboardType,
    required Color textColor,
    required Color cardColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: textColor.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: textColor.withValues(alpha: 0.2)),
              prefixIcon: prefix != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: prefix,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
