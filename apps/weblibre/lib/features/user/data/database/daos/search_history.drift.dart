// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:weblibre/features/user/data/database/database.dart' as i1;

mixin $SearchHistoryDaoMixin on i0.DatabaseAccessor<i1.UserDatabase> {
  SearchHistoryDaoManager get managers => SearchHistoryDaoManager(this);
}

class SearchHistoryDaoManager {
  final $SearchHistoryDaoMixin _db;
  SearchHistoryDaoManager(this._db);
}
