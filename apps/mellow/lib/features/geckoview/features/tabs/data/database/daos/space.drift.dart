// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:mellow/features/geckoview/features/tabs/data/database/database.dart'
    as i1;

mixin $SpaceDaoMixin on i0.DatabaseAccessor<i1.TabDatabase> {
  SpaceDaoManager get managers => SpaceDaoManager(this);
}

class SpaceDaoManager {
  final $SpaceDaoMixin _db;
  SpaceDaoManager(this._db);
}
