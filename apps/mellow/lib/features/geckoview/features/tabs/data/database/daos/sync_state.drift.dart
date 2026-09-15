// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart'
    as i1;

mixin $SyncStateDaoMixin on i0.DatabaseAccessor<i1.TabDatabase> {
  SyncStateDaoManager get managers => SyncStateDaoManager(this);
}

class SyncStateDaoManager {
  final $SyncStateDaoMixin _db;
  SyncStateDaoManager(this._db);
}
