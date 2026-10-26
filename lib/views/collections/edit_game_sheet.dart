import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/save_error.dart';
import '../../models/game.dart';
import '../../core/tokens.dart';
import '../../repositories/game_repository.dart';
import '../../widgets/comic.dart';
import '../../widgets/v_form.dart';

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
      text: widget.game.purchasePrice?.toString() ?? '',
    );
    _notesController = TextEditingController(text: widget.game.notes ?? '');
    _coverUrlController = TextEditingController(
      text: widget.game.coverUrl ?? '',
    );
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
        ref.invalidate(libraryStreamProvider);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(saveErrorText(e))));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    final priceText = _purchasePriceController.text.trim();
    final priceBad = priceText.isNotEmpty && double.tryParse(priceText) == null;
    final urlText = _coverUrlController.text.trim();
    final urlBad = urlText.isNotEmpty &&
        !(Uri.tryParse(urlText)?.hasAbsolutePath ?? false) &&
        !urlText.startsWith('http');

    return VSheetFrame(
      title: 'Edit game',
      eyebrow: widget.game.title,
      onClose: () => Navigator.pop(context),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.game.platform.isPhysical) ...[
                VConditionPicker(
                  value: _condition,
                  onChanged: (c) => setState(() => _condition = c),
                ),
                const SizedBox(height: 20),
              ],
              VField(
                label: 'What you paid',
                controller: _purchasePriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                prefixText: '\$ ',
                hint: '0.00',
                optional: true,
                helper: 'Used to work out your profit or loss.',
                errorText: priceBad ? 'Enter a number, like 49.99' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              VField(
                label: 'Cover image link',
                controller: _coverUrlController,
                hint: 'https://…',
                optional: true,
                helper: 'Leave empty to use the automatic cover.',
                errorText:
                    urlBad ? 'That doesn\u2019t look like a web link' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              VField(
                label: 'Notes',
                controller: _notesController,
                hint: 'Where you bought it, edition, etc.',
                maxLines: 3,
                optional: true,
              ),
              const SizedBox(height: 28),
              PressableBox(
                onTap: (_isSaving || priceBad || urlBad) ? null : _save,
                color: (priceBad || urlBad) ? t.soft : t.money,
                semanticLabel: 'Save changes',
                minHeight: 52,
                child: _isSaving
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: t.onMoney,
                        ),
                      )
                    : Text(
                        'Save changes',
                        style: VText.body(
                          15,
                          t.onMoney,
                          weight: FontWeight.w900,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
