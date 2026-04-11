import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

final BaseCacheManager? gameCoverCacheManager = kIsWeb
    ? null
    : CacheManager(
        Config(
          'valora_game_covers',
          stalePeriod: const Duration(days: 30),
          maxNrOfCacheObjects: 500,
          repo: JsonCacheInfoRepository(databaseName: 'valora_covers'),
          fileService: HttpFileService(),
        ),
      );
