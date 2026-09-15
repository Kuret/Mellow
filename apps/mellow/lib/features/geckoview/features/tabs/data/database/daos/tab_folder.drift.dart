// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:mellow/features/geckoview/features/tabs/data/database/database.dart'
    as i1;

mixin $TabFolderDaoMixin on i0.DatabaseAccessor<i1.TabDatabase> {
  TabFolderDaoManager get managers => TabFolderDaoManager(this);
}

class TabFolderDaoManager {
  final $TabFolderDaoMixin _db;
  TabFolderDaoManager(this._db);
}
