import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A helper class to manage optimistic updates for Riverpod providers.
/// Enables "Zero Latency" UI by updating local state before the server responds.
mixin OptimisticMutation<T> on Notifier<T> {
  /// Perform an optimistic update.
  /// [future] is the actual network request.
  /// [onUpdate] is the function to update the state immediately.
  /// [onRollback] is the function to revert the state if the future fails.
  Future<void> performOptimistic({
    required Future<void> Function() future,
    required T Function(T current) onUpdate,
    required T Function(T current, Object error) onRollback,
  }) async {
    final previousState = state;
    
    // Apply update immediately
    state = onUpdate(state);
    
    try {
      await future();
    } catch (e) {
      // Rollback on error
      state = onRollback(previousState, e);
      rethrow;
    }
  }
}
