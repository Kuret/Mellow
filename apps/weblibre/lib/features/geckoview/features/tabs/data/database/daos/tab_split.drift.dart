// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:weblibre/features/geckoview/features/tabs/data/database/database.dart'
    as i1;

mixin $TabSplitDaoMixin on i0.DatabaseAccessor<i1.TabDatabase> {
  TabSplitDaoManager get managers => TabSplitDaoManager(this);
}

class TabSplitDaoManager {
  final $TabSplitDaoMixin _db;
  TabSplitDaoManager(this._db);
}
