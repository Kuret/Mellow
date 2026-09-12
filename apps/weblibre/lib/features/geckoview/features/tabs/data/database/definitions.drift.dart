// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:weblibre/features/geckoview/features/tabs/data/models/container_data.dart'
    as i1;
import 'package:weblibre/features/geckoview/features/tabs/data/database/definitions.drift.dart'
    as i2;
import 'package:weblibre/features/geckoview/features/tabs/data/models/container_local_data.dart'
    as i3;
import 'package:weblibre/features/geckoview/features/tabs/data/models/space_data.dart'
    as i4;
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_folder_data.dart'
    as i5;
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_split_data.dart'
    as i6;
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_source.dart'
    as i7;
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_shelf.dart'
    as i8;
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_mode.dart'
    as i9;
import 'package:weblibre/data/database/converters/uri.dart' as i10;
import 'package:drift/internal/modular.dart' as i11;
import 'package:weblibre/features/geckoview/features/tabs/data/models/history_query_result.dart'
    as i12;
import 'package:weblibre/features/geckoview/features/tabs/data/models/tab_query_result.dart'
    as i13;

typedef $ContainerCreateCompanionBuilder =
    i2.ContainerCompanion Function({
      required String id,
      i0.Value<String?> syncGuid,
      i0.Value<String> name,
      i0.Value<String> iconKey,
      i0.Value<String> colorKey,
      required String orderKey,
      i0.Value<bool> isPinned,
      i0.Value<int> rowid,
    });
typedef $ContainerUpdateCompanionBuilder =
    i2.ContainerCompanion Function({
      i0.Value<String> id,
      i0.Value<String?> syncGuid,
      i0.Value<String> name,
      i0.Value<String> iconKey,
      i0.Value<String> colorKey,
      i0.Value<String> orderKey,
      i0.Value<bool> isPinned,
      i0.Value<int> rowid,
    });

final class $ContainerReferences
    extends
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i2.Container,
          i1.ContainerData
        > {
  $ContainerReferences(super.$_db, super.$_table, super.$_typedResult);

  static i0.MultiTypedResultKey<i2.ContainerLocal, List<i3.ContainerLocalData>>
  _containerLocalRefsTable(i0.GeneratedDatabase db) =>
      i0.MultiTypedResultKey.fromTable(
        i11.ReadDatabaseContainer(
          db,
        ).resultSet<i2.ContainerLocal>('container_local'),
        aliasName: 'container__id__container_local__container_id',
      );

  i2.$ContainerLocalProcessedTableManager get containerLocalRefs {
    final manager = i2
        .$ContainerLocalTableManager(
          $_db,
          i11.ReadDatabaseContainer(
            $_db,
          ).resultSet<i2.ContainerLocal>('container_local'),
        )
        .filter((f) => f.containerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_containerLocalRefsTable($_db));
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static i0.MultiTypedResultKey<i2.Space, List<i4.SpaceData>> _spaceRefsTable(
    i0.GeneratedDatabase db,
  ) => i0.MultiTypedResultKey.fromTable(
    i11.ReadDatabaseContainer(db).resultSet<i2.Space>('space'),
    aliasName: 'container__id__space__container_id',
  );

  i2.$SpaceProcessedTableManager get spaceRefs {
    final manager = i2
        .$SpaceTableManager(
          $_db,
          i11.ReadDatabaseContainer($_db).resultSet<i2.Space>('space'),
        )
        .filter((f) => f.containerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_spaceRefsTable($_db));
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static i0.MultiTypedResultKey<i2.Tab, List<i2.TabData>> _tabRefsTable(
    i0.GeneratedDatabase db,
  ) => i0.MultiTypedResultKey.fromTable(
    i11.ReadDatabaseContainer(db).resultSet<i2.Tab>('tab'),
    aliasName: 'container__id__tab__container_id',
  );

  i2.$TabProcessedTableManager get tabRefs {
    final manager = i2
        .$TabTableManager(
          $_db,
          i11.ReadDatabaseContainer($_db).resultSet<i2.Tab>('tab'),
        )
        .filter((f) => f.containerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tabRefsTable($_db));
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static i0.MultiTypedResultKey<i2.VisitContainer, List<i2.VisitContainerData>>
  _visitContainerRefsTable(i0.GeneratedDatabase db) =>
      i0.MultiTypedResultKey.fromTable(
        i11.ReadDatabaseContainer(
          db,
        ).resultSet<i2.VisitContainer>('visit_container'),
        aliasName: 'container__id__visit_container__container_id',
      );

  i2.$VisitContainerProcessedTableManager get visitContainerRefs {
    final manager = i2
        .$VisitContainerTableManager(
          $_db,
          i11.ReadDatabaseContainer(
            $_db,
          ).resultSet<i2.VisitContainer>('visit_container'),
        )
        .filter((f) => f.containerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_visitContainerRefsTable($_db));
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $ContainerFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.Container> {
  $ContainerFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get syncGuid => $composableBuilder(
    column: $table.syncGuid,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get colorKey => $composableBuilder(
    column: $table.colorKey,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.Expression<bool> containerLocalRefs(
    i0.Expression<bool> Function(i2.$ContainerLocalFilterComposer f) f,
  ) {
    final i2.$ContainerLocalFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.ContainerLocal>('container_local'),
      getReferencedColumn: (t) => t.containerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$ContainerLocalFilterComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.ContainerLocal>('container_local'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  i0.Expression<bool> spaceRefs(
    i0.Expression<bool> Function(i2.$SpaceFilterComposer f) f,
  ) {
    final i2.$SpaceFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.Space>('space'),
      getReferencedColumn: (t) => t.containerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$SpaceFilterComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer($db).resultSet<i2.Space>('space'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  i0.Expression<bool> tabRefs(
    i0.Expression<bool> Function(i2.$TabFilterComposer f) f,
  ) {
    final i2.$TabFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i11.ReadDatabaseContainer($db).resultSet<i2.Tab>('tab'),
      getReferencedColumn: (t) => t.containerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabFilterComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer($db).resultSet<i2.Tab>('tab'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  i0.Expression<bool> visitContainerRefs(
    i0.Expression<bool> Function(i2.$VisitContainerFilterComposer f) f,
  ) {
    final i2.$VisitContainerFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.VisitContainer>('visit_container'),
      getReferencedColumn: (t) => t.containerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$VisitContainerFilterComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.VisitContainer>('visit_container'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ContainerOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.Container> {
  $ContainerOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get syncGuid => $composableBuilder(
    column: $table.syncGuid,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get colorKey => $composableBuilder(
    column: $table.colorKey,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $ContainerAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.Container> {
  $ContainerAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get syncGuid =>
      $composableBuilder(column: $table.syncGuid, builder: (column) => column);

  i0.GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  i0.GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  i0.GeneratedColumn<String> get colorKey =>
      $composableBuilder(column: $table.colorKey, builder: (column) => column);

  i0.GeneratedColumn<String> get orderKey =>
      $composableBuilder(column: $table.orderKey, builder: (column) => column);

  i0.GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  i0.Expression<T> containerLocalRefs<T extends Object>(
    i0.Expression<T> Function(i2.$ContainerLocalAnnotationComposer a) f,
  ) {
    final i2.$ContainerLocalAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.ContainerLocal>('container_local'),
      getReferencedColumn: (t) => t.containerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$ContainerLocalAnnotationComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.ContainerLocal>('container_local'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  i0.Expression<T> spaceRefs<T extends Object>(
    i0.Expression<T> Function(i2.$SpaceAnnotationComposer a) f,
  ) {
    final i2.$SpaceAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.Space>('space'),
      getReferencedColumn: (t) => t.containerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$SpaceAnnotationComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer($db).resultSet<i2.Space>('space'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  i0.Expression<T> tabRefs<T extends Object>(
    i0.Expression<T> Function(i2.$TabAnnotationComposer a) f,
  ) {
    final i2.$TabAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i11.ReadDatabaseContainer($db).resultSet<i2.Tab>('tab'),
      getReferencedColumn: (t) => t.containerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabAnnotationComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer($db).resultSet<i2.Tab>('tab'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  i0.Expression<T> visitContainerRefs<T extends Object>(
    i0.Expression<T> Function(i2.$VisitContainerAnnotationComposer a) f,
  ) {
    final i2.$VisitContainerAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.VisitContainer>('visit_container'),
      getReferencedColumn: (t) => t.containerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$VisitContainerAnnotationComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.VisitContainer>('visit_container'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ContainerTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i2.Container,
          i1.ContainerData,
          i2.$ContainerFilterComposer,
          i2.$ContainerOrderingComposer,
          i2.$ContainerAnnotationComposer,
          $ContainerCreateCompanionBuilder,
          $ContainerUpdateCompanionBuilder,
          (i1.ContainerData, i2.$ContainerReferences),
          i1.ContainerData,
          i0.PrefetchHooks Function({
            bool containerLocalRefs,
            bool spaceRefs,
            bool tabRefs,
            bool visitContainerRefs,
          })
        > {
  $ContainerTableManager(i0.GeneratedDatabase db, i2.Container table)
    : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i2.$ContainerFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i2.$ContainerOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i2.$ContainerAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> id = const i0.Value.absent(),
                i0.Value<String?> syncGuid = const i0.Value.absent(),
                i0.Value<String> name = const i0.Value.absent(),
                i0.Value<String> iconKey = const i0.Value.absent(),
                i0.Value<String> colorKey = const i0.Value.absent(),
                i0.Value<String> orderKey = const i0.Value.absent(),
                i0.Value<bool> isPinned = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.ContainerCompanion(
                id: id,
                syncGuid: syncGuid,
                name: name,
                iconKey: iconKey,
                colorKey: colorKey,
                orderKey: orderKey,
                isPinned: isPinned,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                i0.Value<String?> syncGuid = const i0.Value.absent(),
                i0.Value<String> name = const i0.Value.absent(),
                i0.Value<String> iconKey = const i0.Value.absent(),
                i0.Value<String> colorKey = const i0.Value.absent(),
                required String orderKey,
                i0.Value<bool> isPinned = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.ContainerCompanion.insert(
                id: id,
                syncGuid: syncGuid,
                name: name,
                iconKey: iconKey,
                colorKey: colorKey,
                orderKey: orderKey,
                isPinned: isPinned,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), i2.$ContainerReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                containerLocalRefs = false,
                spaceRefs = false,
                tabRefs = false,
                visitContainerRefs = false,
              }) {
                return i0.PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (containerLocalRefs)
                      i11.ReadDatabaseContainer(
                        db,
                      ).resultSet<i2.ContainerLocal>('container_local'),
                    if (spaceRefs)
                      i11.ReadDatabaseContainer(
                        db,
                      ).resultSet<i2.Space>('space'),
                    if (tabRefs)
                      i11.ReadDatabaseContainer(db).resultSet<i2.Tab>('tab'),
                    if (visitContainerRefs)
                      i11.ReadDatabaseContainer(
                        db,
                      ).resultSet<i2.VisitContainer>('visit_container'),
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (containerLocalRefs)
                        await i0.$_getPrefetchedData<
                          i1.ContainerData,
                          i2.Container,
                          i3.ContainerLocalData
                        >(
                          currentTable: table,
                          referencedTable: i2.$ContainerReferences
                              ._containerLocalRefsTable(db),
                          managerFromTypedResult: (p0) => i2
                              .$ContainerReferences(db, table, p0)
                              .containerLocalRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.containerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (spaceRefs)
                        await i0.$_getPrefetchedData<
                          i1.ContainerData,
                          i2.Container,
                          i4.SpaceData
                        >(
                          currentTable: table,
                          referencedTable: i2.$ContainerReferences
                              ._spaceRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              i2.$ContainerReferences(db, table, p0).spaceRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.containerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (tabRefs)
                        await i0.$_getPrefetchedData<
                          i1.ContainerData,
                          i2.Container,
                          i2.TabData
                        >(
                          currentTable: table,
                          referencedTable: i2.$ContainerReferences
                              ._tabRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              i2.$ContainerReferences(db, table, p0).tabRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.containerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (visitContainerRefs)
                        await i0.$_getPrefetchedData<
                          i1.ContainerData,
                          i2.Container,
                          i2.VisitContainerData
                        >(
                          currentTable: table,
                          referencedTable: i2.$ContainerReferences
                              ._visitContainerRefsTable(db),
                          managerFromTypedResult: (p0) => i2
                              .$ContainerReferences(db, table, p0)
                              .visitContainerRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.containerId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $ContainerProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i2.Container,
      i1.ContainerData,
      i2.$ContainerFilterComposer,
      i2.$ContainerOrderingComposer,
      i2.$ContainerAnnotationComposer,
      $ContainerCreateCompanionBuilder,
      $ContainerUpdateCompanionBuilder,
      (i1.ContainerData, i2.$ContainerReferences),
      i1.ContainerData,
      i0.PrefetchHooks Function({
        bool containerLocalRefs,
        bool spaceRefs,
        bool tabRefs,
        bool visitContainerRefs,
      })
    >;
typedef $ContainerLocalCreateCompanionBuilder =
    i2.ContainerLocalCompanion Function({
      required String containerId,
      i0.Value<bool> excludeFromIndex,
      i0.Value<bool> excludeFromHistory,
      i0.Value<bool> clearDataOnExit,
      i0.Value<String?> wallpaper,
      i0.Value<int> rowid,
    });
typedef $ContainerLocalUpdateCompanionBuilder =
    i2.ContainerLocalCompanion Function({
      i0.Value<String> containerId,
      i0.Value<bool> excludeFromIndex,
      i0.Value<bool> excludeFromHistory,
      i0.Value<bool> clearDataOnExit,
      i0.Value<String?> wallpaper,
      i0.Value<int> rowid,
    });

final class $ContainerLocalReferences
    extends
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i2.ContainerLocal,
          i3.ContainerLocalData
        > {
  $ContainerLocalReferences(super.$_db, super.$_table, super.$_typedResult);

  static i2.Container _containerIdTable(i0.GeneratedDatabase db) =>
      i11.ReadDatabaseContainer(db)
          .resultSet<i2.Container>('container')
          .createAlias('container_local__container_id__container__id');

  i2.$ContainerProcessedTableManager get containerId {
    final $_column = $_itemColumn<String>('container_id')!;

    final manager = i2
        .$ContainerTableManager(
          $_db,
          i11.ReadDatabaseContainer($_db).resultSet<i2.Container>('container'),
        )
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_containerIdTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $ContainerLocalFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.ContainerLocal> {
  $ContainerLocalFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<bool> get excludeFromIndex => $composableBuilder(
    column: $table.excludeFromIndex,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<bool> get excludeFromHistory => $composableBuilder(
    column: $table.excludeFromHistory,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<bool> get clearDataOnExit => $composableBuilder(
    column: $table.clearDataOnExit,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get wallpaper => $composableBuilder(
    column: $table.wallpaper,
    builder: (column) => i0.ColumnFilters(column),
  );

  i2.$ContainerFilterComposer get containerId {
    final i2.$ContainerFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.containerId,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.Container>('container'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$ContainerFilterComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.Container>('container'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ContainerLocalOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.ContainerLocal> {
  $ContainerLocalOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<bool> get excludeFromIndex => $composableBuilder(
    column: $table.excludeFromIndex,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<bool> get excludeFromHistory => $composableBuilder(
    column: $table.excludeFromHistory,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<bool> get clearDataOnExit => $composableBuilder(
    column: $table.clearDataOnExit,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get wallpaper => $composableBuilder(
    column: $table.wallpaper,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i2.$ContainerOrderingComposer get containerId {
    final i2.$ContainerOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.containerId,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.Container>('container'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$ContainerOrderingComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.Container>('container'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ContainerLocalAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.ContainerLocal> {
  $ContainerLocalAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<bool> get excludeFromIndex => $composableBuilder(
    column: $table.excludeFromIndex,
    builder: (column) => column,
  );

  i0.GeneratedColumn<bool> get excludeFromHistory => $composableBuilder(
    column: $table.excludeFromHistory,
    builder: (column) => column,
  );

  i0.GeneratedColumn<bool> get clearDataOnExit => $composableBuilder(
    column: $table.clearDataOnExit,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get wallpaper =>
      $composableBuilder(column: $table.wallpaper, builder: (column) => column);

  i2.$ContainerAnnotationComposer get containerId {
    final i2.$ContainerAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.containerId,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.Container>('container'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$ContainerAnnotationComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.Container>('container'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ContainerLocalTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i2.ContainerLocal,
          i3.ContainerLocalData,
          i2.$ContainerLocalFilterComposer,
          i2.$ContainerLocalOrderingComposer,
          i2.$ContainerLocalAnnotationComposer,
          $ContainerLocalCreateCompanionBuilder,
          $ContainerLocalUpdateCompanionBuilder,
          (i3.ContainerLocalData, i2.$ContainerLocalReferences),
          i3.ContainerLocalData,
          i0.PrefetchHooks Function({bool containerId})
        > {
  $ContainerLocalTableManager(i0.GeneratedDatabase db, i2.ContainerLocal table)
    : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i2.$ContainerLocalFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i2.$ContainerLocalOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i2.$ContainerLocalAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> containerId = const i0.Value.absent(),
                i0.Value<bool> excludeFromIndex = const i0.Value.absent(),
                i0.Value<bool> excludeFromHistory = const i0.Value.absent(),
                i0.Value<bool> clearDataOnExit = const i0.Value.absent(),
                i0.Value<String?> wallpaper = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.ContainerLocalCompanion(
                containerId: containerId,
                excludeFromIndex: excludeFromIndex,
                excludeFromHistory: excludeFromHistory,
                clearDataOnExit: clearDataOnExit,
                wallpaper: wallpaper,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String containerId,
                i0.Value<bool> excludeFromIndex = const i0.Value.absent(),
                i0.Value<bool> excludeFromHistory = const i0.Value.absent(),
                i0.Value<bool> clearDataOnExit = const i0.Value.absent(),
                i0.Value<String?> wallpaper = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.ContainerLocalCompanion.insert(
                containerId: containerId,
                excludeFromIndex: excludeFromIndex,
                excludeFromHistory: excludeFromHistory,
                clearDataOnExit: clearDataOnExit,
                wallpaper: wallpaper,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  i2.$ContainerLocalReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({containerId = false}) {
            return i0.PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends i0.TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (containerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.containerId,
                                referencedTable: i2.$ContainerLocalReferences
                                    ._containerIdTable(db),
                                referencedColumn: i2.$ContainerLocalReferences
                                    ._containerIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $ContainerLocalProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i2.ContainerLocal,
      i3.ContainerLocalData,
      i2.$ContainerLocalFilterComposer,
      i2.$ContainerLocalOrderingComposer,
      i2.$ContainerLocalAnnotationComposer,
      $ContainerLocalCreateCompanionBuilder,
      $ContainerLocalUpdateCompanionBuilder,
      (i3.ContainerLocalData, i2.$ContainerLocalReferences),
      i3.ContainerLocalData,
      i0.PrefetchHooks Function({bool containerId})
    >;
typedef $SpaceCreateCompanionBuilder =
    i2.SpaceCompanion Function({
      required String uuid,
      i0.Value<String> name,
      i0.Value<String?> icon,
      i0.Value<String?> theme,
      i0.Value<String?> containerId,
      required int orderIndex,
      i0.Value<int> rowid,
    });
typedef $SpaceUpdateCompanionBuilder =
    i2.SpaceCompanion Function({
      i0.Value<String> uuid,
      i0.Value<String> name,
      i0.Value<String?> icon,
      i0.Value<String?> theme,
      i0.Value<String?> containerId,
      i0.Value<int> orderIndex,
      i0.Value<int> rowid,
    });

final class $SpaceReferences
    extends i0.BaseReferences<i0.GeneratedDatabase, i2.Space, i4.SpaceData> {
  $SpaceReferences(super.$_db, super.$_table, super.$_typedResult);

  static i2.Container _containerIdTable(i0.GeneratedDatabase db) =>
      i11.ReadDatabaseContainer(db)
          .resultSet<i2.Container>('container')
          .createAlias('space__container_id__container__id');

  i2.$ContainerProcessedTableManager? get containerId {
    final $_column = $_itemColumn<String>('container_id');
    if ($_column == null) return null;
    final manager = i2
        .$ContainerTableManager(
          $_db,
          i11.ReadDatabaseContainer($_db).resultSet<i2.Container>('container'),
        )
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_containerIdTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static i0.MultiTypedResultKey<i2.TabFolder, List<i5.TabFolderData>>
  _tabFolderRefsTable(i0.GeneratedDatabase db) =>
      i0.MultiTypedResultKey.fromTable(
        i11.ReadDatabaseContainer(db).resultSet<i2.TabFolder>('tab_folder'),
        aliasName: 'space__uuid__tab_folder__space_uuid',
      );

  i2.$TabFolderProcessedTableManager get tabFolderRefs {
    final manager = i2
        .$TabFolderTableManager(
          $_db,
          i11.ReadDatabaseContainer($_db).resultSet<i2.TabFolder>('tab_folder'),
        )
        .filter(
          (f) => f.spaceUuid.uuid.sqlEquals($_itemColumn<String>('uuid')!),
        );

    final cache = $_typedResult.readTableOrNull(_tabFolderRefsTable($_db));
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static i0.MultiTypedResultKey<i2.TabSplit, List<i6.TabSplitData>>
  _tabSplitRefsTable(i0.GeneratedDatabase db) =>
      i0.MultiTypedResultKey.fromTable(
        i11.ReadDatabaseContainer(db).resultSet<i2.TabSplit>('tab_split'),
        aliasName: 'space__uuid__tab_split__space_uuid',
      );

  i2.$TabSplitProcessedTableManager get tabSplitRefs {
    final manager = i2
        .$TabSplitTableManager(
          $_db,
          i11.ReadDatabaseContainer($_db).resultSet<i2.TabSplit>('tab_split'),
        )
        .filter(
          (f) => f.spaceUuid.uuid.sqlEquals($_itemColumn<String>('uuid')!),
        );

    final cache = $_typedResult.readTableOrNull(_tabSplitRefsTable($_db));
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static i0.MultiTypedResultKey<i2.Tab, List<i2.TabData>> _tabRefsTable(
    i0.GeneratedDatabase db,
  ) => i0.MultiTypedResultKey.fromTable(
    i11.ReadDatabaseContainer(db).resultSet<i2.Tab>('tab'),
    aliasName: 'space__uuid__tab__space_uuid',
  );

  i2.$TabProcessedTableManager get tabRefs {
    final manager = i2
        .$TabTableManager(
          $_db,
          i11.ReadDatabaseContainer($_db).resultSet<i2.Tab>('tab'),
        )
        .filter(
          (f) => f.spaceUuid.uuid.sqlEquals($_itemColumn<String>('uuid')!),
        );

    final cache = $_typedResult.readTableOrNull(_tabRefsTable($_db));
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $SpaceFilterComposer extends i0.Composer<i0.GeneratedDatabase, i2.Space> {
  $SpaceFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => i0.ColumnFilters(column),
  );

  i2.$ContainerFilterComposer get containerId {
    final i2.$ContainerFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.containerId,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.Container>('container'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$ContainerFilterComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.Container>('container'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i0.Expression<bool> tabFolderRefs(
    i0.Expression<bool> Function(i2.$TabFolderFilterComposer f) f,
  ) {
    final i2.$TabFolderFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.TabFolder>('tab_folder'),
      getReferencedColumn: (t) => t.spaceUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabFolderFilterComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.TabFolder>('tab_folder'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  i0.Expression<bool> tabSplitRefs(
    i0.Expression<bool> Function(i2.$TabSplitFilterComposer f) f,
  ) {
    final i2.$TabSplitFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.TabSplit>('tab_split'),
      getReferencedColumn: (t) => t.spaceUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabSplitFilterComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.TabSplit>('tab_split'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  i0.Expression<bool> tabRefs(
    i0.Expression<bool> Function(i2.$TabFilterComposer f) f,
  ) {
    final i2.$TabFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: i11.ReadDatabaseContainer($db).resultSet<i2.Tab>('tab'),
      getReferencedColumn: (t) => t.spaceUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabFilterComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer($db).resultSet<i2.Tab>('tab'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $SpaceOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.Space> {
  $SpaceOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i2.$ContainerOrderingComposer get containerId {
    final i2.$ContainerOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.containerId,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.Container>('container'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$ContainerOrderingComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.Container>('container'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SpaceAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.Space> {
  $SpaceAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  i0.GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  i0.GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  i0.GeneratedColumn<String> get theme =>
      $composableBuilder(column: $table.theme, builder: (column) => column);

  i0.GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  i2.$ContainerAnnotationComposer get containerId {
    final i2.$ContainerAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.containerId,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.Container>('container'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$ContainerAnnotationComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.Container>('container'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i0.Expression<T> tabFolderRefs<T extends Object>(
    i0.Expression<T> Function(i2.$TabFolderAnnotationComposer a) f,
  ) {
    final i2.$TabFolderAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.TabFolder>('tab_folder'),
      getReferencedColumn: (t) => t.spaceUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabFolderAnnotationComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.TabFolder>('tab_folder'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  i0.Expression<T> tabSplitRefs<T extends Object>(
    i0.Expression<T> Function(i2.$TabSplitAnnotationComposer a) f,
  ) {
    final i2.$TabSplitAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.TabSplit>('tab_split'),
      getReferencedColumn: (t) => t.spaceUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabSplitAnnotationComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.TabSplit>('tab_split'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  i0.Expression<T> tabRefs<T extends Object>(
    i0.Expression<T> Function(i2.$TabAnnotationComposer a) f,
  ) {
    final i2.$TabAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: i11.ReadDatabaseContainer($db).resultSet<i2.Tab>('tab'),
      getReferencedColumn: (t) => t.spaceUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabAnnotationComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer($db).resultSet<i2.Tab>('tab'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $SpaceTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i2.Space,
          i4.SpaceData,
          i2.$SpaceFilterComposer,
          i2.$SpaceOrderingComposer,
          i2.$SpaceAnnotationComposer,
          $SpaceCreateCompanionBuilder,
          $SpaceUpdateCompanionBuilder,
          (i4.SpaceData, i2.$SpaceReferences),
          i4.SpaceData,
          i0.PrefetchHooks Function({
            bool containerId,
            bool tabFolderRefs,
            bool tabSplitRefs,
            bool tabRefs,
          })
        > {
  $SpaceTableManager(i0.GeneratedDatabase db, i2.Space table)
    : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i2.$SpaceFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i2.$SpaceOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i2.$SpaceAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> uuid = const i0.Value.absent(),
                i0.Value<String> name = const i0.Value.absent(),
                i0.Value<String?> icon = const i0.Value.absent(),
                i0.Value<String?> theme = const i0.Value.absent(),
                i0.Value<String?> containerId = const i0.Value.absent(),
                i0.Value<int> orderIndex = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.SpaceCompanion(
                uuid: uuid,
                name: name,
                icon: icon,
                theme: theme,
                containerId: containerId,
                orderIndex: orderIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuid,
                i0.Value<String> name = const i0.Value.absent(),
                i0.Value<String?> icon = const i0.Value.absent(),
                i0.Value<String?> theme = const i0.Value.absent(),
                i0.Value<String?> containerId = const i0.Value.absent(),
                required int orderIndex,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.SpaceCompanion.insert(
                uuid: uuid,
                name: name,
                icon: icon,
                theme: theme,
                containerId: containerId,
                orderIndex: orderIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (e.readTable(table), i2.$SpaceReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                containerId = false,
                tabFolderRefs = false,
                tabSplitRefs = false,
                tabRefs = false,
              }) {
                return i0.PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (tabFolderRefs)
                      i11.ReadDatabaseContainer(
                        db,
                      ).resultSet<i2.TabFolder>('tab_folder'),
                    if (tabSplitRefs)
                      i11.ReadDatabaseContainer(
                        db,
                      ).resultSet<i2.TabSplit>('tab_split'),
                    if (tabRefs)
                      i11.ReadDatabaseContainer(db).resultSet<i2.Tab>('tab'),
                  ],
                  addJoins:
                      <
                        T extends i0.TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (containerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.containerId,
                                    referencedTable: i2.$SpaceReferences
                                        ._containerIdTable(db),
                                    referencedColumn: i2.$SpaceReferences
                                        ._containerIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (tabFolderRefs)
                        await i0.$_getPrefetchedData<
                          i4.SpaceData,
                          i2.Space,
                          i5.TabFolderData
                        >(
                          currentTable: table,
                          referencedTable: i2.$SpaceReferences
                              ._tabFolderRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              i2.$SpaceReferences(db, table, p0).tabFolderRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.spaceUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                      if (tabSplitRefs)
                        await i0.$_getPrefetchedData<
                          i4.SpaceData,
                          i2.Space,
                          i6.TabSplitData
                        >(
                          currentTable: table,
                          referencedTable: i2.$SpaceReferences
                              ._tabSplitRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              i2.$SpaceReferences(db, table, p0).tabSplitRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.spaceUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                      if (tabRefs)
                        await i0.$_getPrefetchedData<
                          i4.SpaceData,
                          i2.Space,
                          i2.TabData
                        >(
                          currentTable: table,
                          referencedTable: i2.$SpaceReferences._tabRefsTable(
                            db,
                          ),
                          managerFromTypedResult: (p0) =>
                              i2.$SpaceReferences(db, table, p0).tabRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.spaceUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $SpaceProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i2.Space,
      i4.SpaceData,
      i2.$SpaceFilterComposer,
      i2.$SpaceOrderingComposer,
      i2.$SpaceAnnotationComposer,
      $SpaceCreateCompanionBuilder,
      $SpaceUpdateCompanionBuilder,
      (i4.SpaceData, i2.$SpaceReferences),
      i4.SpaceData,
      i0.PrefetchHooks Function({
        bool containerId,
        bool tabFolderRefs,
        bool tabSplitRefs,
        bool tabRefs,
      })
    >;
typedef $TabFolderCreateCompanionBuilder =
    i2.TabFolderCompanion Function({
      required String id,
      i0.Value<String> name,
      i0.Value<String?> icon,
      i0.Value<String?> spaceUuid,
      i0.Value<String?> parentFolderId,
      i0.Value<String?> live,
      i0.Value<bool> isCollapsed,
      required String orderKey,
      i0.Value<int> rowid,
    });
typedef $TabFolderUpdateCompanionBuilder =
    i2.TabFolderCompanion Function({
      i0.Value<String> id,
      i0.Value<String> name,
      i0.Value<String?> icon,
      i0.Value<String?> spaceUuid,
      i0.Value<String?> parentFolderId,
      i0.Value<String?> live,
      i0.Value<bool> isCollapsed,
      i0.Value<String> orderKey,
      i0.Value<int> rowid,
    });

final class $TabFolderReferences
    extends
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i2.TabFolder,
          i5.TabFolderData
        > {
  $TabFolderReferences(super.$_db, super.$_table, super.$_typedResult);

  static i2.Space _spaceUuidTable(i0.GeneratedDatabase db) =>
      i11.ReadDatabaseContainer(db)
          .resultSet<i2.Space>('space')
          .createAlias('tab_folder__space_uuid__space__uuid');

  i2.$SpaceProcessedTableManager? get spaceUuid {
    final $_column = $_itemColumn<String>('space_uuid');
    if ($_column == null) return null;
    final manager = i2
        .$SpaceTableManager(
          $_db,
          i11.ReadDatabaseContainer($_db).resultSet<i2.Space>('space'),
        )
        .filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_spaceUuidTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static i2.TabFolder _parentFolderIdTable(i0.GeneratedDatabase db) =>
      i11.ReadDatabaseContainer(db)
          .resultSet<i2.TabFolder>('tab_folder')
          .createAlias('tab_folder__parent_folder_id__tab_folder__id');

  i2.$TabFolderProcessedTableManager? get parentFolderId {
    final $_column = $_itemColumn<String>('parent_folder_id');
    if ($_column == null) return null;
    final manager = i2
        .$TabFolderTableManager(
          $_db,
          i11.ReadDatabaseContainer($_db).resultSet<i2.TabFolder>('tab_folder'),
        )
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentFolderIdTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static i0.MultiTypedResultKey<i2.TabSplit, List<i6.TabSplitData>>
  _tabSplitRefsTable(i0.GeneratedDatabase db) =>
      i0.MultiTypedResultKey.fromTable(
        i11.ReadDatabaseContainer(db).resultSet<i2.TabSplit>('tab_split'),
        aliasName: 'tab_folder__id__tab_split__folder_id',
      );

  i2.$TabSplitProcessedTableManager get tabSplitRefs {
    final manager = i2
        .$TabSplitTableManager(
          $_db,
          i11.ReadDatabaseContainer($_db).resultSet<i2.TabSplit>('tab_split'),
        )
        .filter((f) => f.folderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tabSplitRefsTable($_db));
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static i0.MultiTypedResultKey<i2.Tab, List<i2.TabData>> _tabRefsTable(
    i0.GeneratedDatabase db,
  ) => i0.MultiTypedResultKey.fromTable(
    i11.ReadDatabaseContainer(db).resultSet<i2.Tab>('tab'),
    aliasName: 'tab_folder__id__tab__folder_id',
  );

  i2.$TabProcessedTableManager get tabRefs {
    final manager = i2
        .$TabTableManager(
          $_db,
          i11.ReadDatabaseContainer($_db).resultSet<i2.Tab>('tab'),
        )
        .filter((f) => f.folderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tabRefsTable($_db));
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $TabFolderFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.TabFolder> {
  $TabFolderFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get live => $composableBuilder(
    column: $table.live,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<bool> get isCollapsed => $composableBuilder(
    column: $table.isCollapsed,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => i0.ColumnFilters(column),
  );

  i2.$SpaceFilterComposer get spaceUuid {
    final i2.$SpaceFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.spaceUuid,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.Space>('space'),
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$SpaceFilterComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer($db).resultSet<i2.Space>('space'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i2.$TabFolderFilterComposer get parentFolderId {
    final i2.$TabFolderFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentFolderId,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.TabFolder>('tab_folder'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabFolderFilterComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.TabFolder>('tab_folder'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i0.Expression<bool> tabSplitRefs(
    i0.Expression<bool> Function(i2.$TabSplitFilterComposer f) f,
  ) {
    final i2.$TabSplitFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.TabSplit>('tab_split'),
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabSplitFilterComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.TabSplit>('tab_split'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  i0.Expression<bool> tabRefs(
    i0.Expression<bool> Function(i2.$TabFilterComposer f) f,
  ) {
    final i2.$TabFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i11.ReadDatabaseContainer($db).resultSet<i2.Tab>('tab'),
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabFilterComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer($db).resultSet<i2.Tab>('tab'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $TabFolderOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.TabFolder> {
  $TabFolderOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get live => $composableBuilder(
    column: $table.live,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<bool> get isCollapsed => $composableBuilder(
    column: $table.isCollapsed,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i2.$SpaceOrderingComposer get spaceUuid {
    final i2.$SpaceOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.spaceUuid,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.Space>('space'),
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$SpaceOrderingComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer($db).resultSet<i2.Space>('space'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i2.$TabFolderOrderingComposer get parentFolderId {
    final i2.$TabFolderOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentFolderId,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.TabFolder>('tab_folder'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabFolderOrderingComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.TabFolder>('tab_folder'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TabFolderAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.TabFolder> {
  $TabFolderAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  i0.GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  i0.GeneratedColumn<String> get live =>
      $composableBuilder(column: $table.live, builder: (column) => column);

  i0.GeneratedColumn<bool> get isCollapsed => $composableBuilder(
    column: $table.isCollapsed,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get orderKey =>
      $composableBuilder(column: $table.orderKey, builder: (column) => column);

  i2.$SpaceAnnotationComposer get spaceUuid {
    final i2.$SpaceAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.spaceUuid,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.Space>('space'),
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$SpaceAnnotationComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer($db).resultSet<i2.Space>('space'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i2.$TabFolderAnnotationComposer get parentFolderId {
    final i2.$TabFolderAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentFolderId,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.TabFolder>('tab_folder'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabFolderAnnotationComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.TabFolder>('tab_folder'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i0.Expression<T> tabSplitRefs<T extends Object>(
    i0.Expression<T> Function(i2.$TabSplitAnnotationComposer a) f,
  ) {
    final i2.$TabSplitAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.TabSplit>('tab_split'),
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabSplitAnnotationComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.TabSplit>('tab_split'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  i0.Expression<T> tabRefs<T extends Object>(
    i0.Expression<T> Function(i2.$TabAnnotationComposer a) f,
  ) {
    final i2.$TabAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i11.ReadDatabaseContainer($db).resultSet<i2.Tab>('tab'),
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabAnnotationComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer($db).resultSet<i2.Tab>('tab'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $TabFolderTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i2.TabFolder,
          i5.TabFolderData,
          i2.$TabFolderFilterComposer,
          i2.$TabFolderOrderingComposer,
          i2.$TabFolderAnnotationComposer,
          $TabFolderCreateCompanionBuilder,
          $TabFolderUpdateCompanionBuilder,
          (i5.TabFolderData, i2.$TabFolderReferences),
          i5.TabFolderData,
          i0.PrefetchHooks Function({
            bool spaceUuid,
            bool parentFolderId,
            bool tabSplitRefs,
            bool tabRefs,
          })
        > {
  $TabFolderTableManager(i0.GeneratedDatabase db, i2.TabFolder table)
    : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i2.$TabFolderFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i2.$TabFolderOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i2.$TabFolderAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> id = const i0.Value.absent(),
                i0.Value<String> name = const i0.Value.absent(),
                i0.Value<String?> icon = const i0.Value.absent(),
                i0.Value<String?> spaceUuid = const i0.Value.absent(),
                i0.Value<String?> parentFolderId = const i0.Value.absent(),
                i0.Value<String?> live = const i0.Value.absent(),
                i0.Value<bool> isCollapsed = const i0.Value.absent(),
                i0.Value<String> orderKey = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.TabFolderCompanion(
                id: id,
                name: name,
                icon: icon,
                spaceUuid: spaceUuid,
                parentFolderId: parentFolderId,
                live: live,
                isCollapsed: isCollapsed,
                orderKey: orderKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                i0.Value<String> name = const i0.Value.absent(),
                i0.Value<String?> icon = const i0.Value.absent(),
                i0.Value<String?> spaceUuid = const i0.Value.absent(),
                i0.Value<String?> parentFolderId = const i0.Value.absent(),
                i0.Value<String?> live = const i0.Value.absent(),
                i0.Value<bool> isCollapsed = const i0.Value.absent(),
                required String orderKey,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.TabFolderCompanion.insert(
                id: id,
                name: name,
                icon: icon,
                spaceUuid: spaceUuid,
                parentFolderId: parentFolderId,
                live: live,
                isCollapsed: isCollapsed,
                orderKey: orderKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), i2.$TabFolderReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                spaceUuid = false,
                parentFolderId = false,
                tabSplitRefs = false,
                tabRefs = false,
              }) {
                return i0.PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (tabSplitRefs)
                      i11.ReadDatabaseContainer(
                        db,
                      ).resultSet<i2.TabSplit>('tab_split'),
                    if (tabRefs)
                      i11.ReadDatabaseContainer(db).resultSet<i2.Tab>('tab'),
                  ],
                  addJoins:
                      <
                        T extends i0.TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (spaceUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.spaceUuid,
                                    referencedTable: i2.$TabFolderReferences
                                        ._spaceUuidTable(db),
                                    referencedColumn: i2.$TabFolderReferences
                                        ._spaceUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }
                        if (parentFolderId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.parentFolderId,
                                    referencedTable: i2.$TabFolderReferences
                                        ._parentFolderIdTable(db),
                                    referencedColumn: i2.$TabFolderReferences
                                        ._parentFolderIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (tabSplitRefs)
                        await i0.$_getPrefetchedData<
                          i5.TabFolderData,
                          i2.TabFolder,
                          i6.TabSplitData
                        >(
                          currentTable: table,
                          referencedTable: i2.$TabFolderReferences
                              ._tabSplitRefsTable(db),
                          managerFromTypedResult: (p0) => i2
                              .$TabFolderReferences(db, table, p0)
                              .tabSplitRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.folderId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (tabRefs)
                        await i0.$_getPrefetchedData<
                          i5.TabFolderData,
                          i2.TabFolder,
                          i2.TabData
                        >(
                          currentTable: table,
                          referencedTable: i2.$TabFolderReferences
                              ._tabRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              i2.$TabFolderReferences(db, table, p0).tabRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.folderId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $TabFolderProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i2.TabFolder,
      i5.TabFolderData,
      i2.$TabFolderFilterComposer,
      i2.$TabFolderOrderingComposer,
      i2.$TabFolderAnnotationComposer,
      $TabFolderCreateCompanionBuilder,
      $TabFolderUpdateCompanionBuilder,
      (i5.TabFolderData, i2.$TabFolderReferences),
      i5.TabFolderData,
      i0.PrefetchHooks Function({
        bool spaceUuid,
        bool parentFolderId,
        bool tabSplitRefs,
        bool tabRefs,
      })
    >;
typedef $TabSplitCreateCompanionBuilder =
    i2.TabSplitCompanion Function({
      required String id,
      i0.Value<String> gridType,
      i0.Value<bool> isPinned,
      i0.Value<String?> spaceUuid,
      i0.Value<String?> folderId,
      required String orderKey,
      i0.Value<int> rowid,
    });
typedef $TabSplitUpdateCompanionBuilder =
    i2.TabSplitCompanion Function({
      i0.Value<String> id,
      i0.Value<String> gridType,
      i0.Value<bool> isPinned,
      i0.Value<String?> spaceUuid,
      i0.Value<String?> folderId,
      i0.Value<String> orderKey,
      i0.Value<int> rowid,
    });

final class $TabSplitReferences
    extends
        i0.BaseReferences<i0.GeneratedDatabase, i2.TabSplit, i6.TabSplitData> {
  $TabSplitReferences(super.$_db, super.$_table, super.$_typedResult);

  static i2.Space _spaceUuidTable(i0.GeneratedDatabase db) =>
      i11.ReadDatabaseContainer(db)
          .resultSet<i2.Space>('space')
          .createAlias('tab_split__space_uuid__space__uuid');

  i2.$SpaceProcessedTableManager? get spaceUuid {
    final $_column = $_itemColumn<String>('space_uuid');
    if ($_column == null) return null;
    final manager = i2
        .$SpaceTableManager(
          $_db,
          i11.ReadDatabaseContainer($_db).resultSet<i2.Space>('space'),
        )
        .filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_spaceUuidTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static i2.TabFolder _folderIdTable(i0.GeneratedDatabase db) =>
      i11.ReadDatabaseContainer(db)
          .resultSet<i2.TabFolder>('tab_folder')
          .createAlias('tab_split__folder_id__tab_folder__id');

  i2.$TabFolderProcessedTableManager? get folderId {
    final $_column = $_itemColumn<String>('folder_id');
    if ($_column == null) return null;
    final manager = i2
        .$TabFolderTableManager(
          $_db,
          i11.ReadDatabaseContainer($_db).resultSet<i2.TabFolder>('tab_folder'),
        )
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_folderIdTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static i0.MultiTypedResultKey<i2.Tab, List<i2.TabData>> _tabRefsTable(
    i0.GeneratedDatabase db,
  ) => i0.MultiTypedResultKey.fromTable(
    i11.ReadDatabaseContainer(db).resultSet<i2.Tab>('tab'),
    aliasName: 'tab_split__id__tab__split_id',
  );

  i2.$TabProcessedTableManager get tabRefs {
    final manager = i2
        .$TabTableManager(
          $_db,
          i11.ReadDatabaseContainer($_db).resultSet<i2.Tab>('tab'),
        )
        .filter((f) => f.splitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tabRefsTable($_db));
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $TabSplitFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.TabSplit> {
  $TabSplitFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get gridType => $composableBuilder(
    column: $table.gridType,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => i0.ColumnFilters(column),
  );

  i2.$SpaceFilterComposer get spaceUuid {
    final i2.$SpaceFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.spaceUuid,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.Space>('space'),
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$SpaceFilterComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer($db).resultSet<i2.Space>('space'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i2.$TabFolderFilterComposer get folderId {
    final i2.$TabFolderFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.TabFolder>('tab_folder'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabFolderFilterComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.TabFolder>('tab_folder'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i0.Expression<bool> tabRefs(
    i0.Expression<bool> Function(i2.$TabFilterComposer f) f,
  ) {
    final i2.$TabFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i11.ReadDatabaseContainer($db).resultSet<i2.Tab>('tab'),
      getReferencedColumn: (t) => t.splitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabFilterComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer($db).resultSet<i2.Tab>('tab'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $TabSplitOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.TabSplit> {
  $TabSplitOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get gridType => $composableBuilder(
    column: $table.gridType,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i2.$SpaceOrderingComposer get spaceUuid {
    final i2.$SpaceOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.spaceUuid,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.Space>('space'),
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$SpaceOrderingComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer($db).resultSet<i2.Space>('space'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i2.$TabFolderOrderingComposer get folderId {
    final i2.$TabFolderOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.TabFolder>('tab_folder'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabFolderOrderingComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.TabFolder>('tab_folder'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TabSplitAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.TabSplit> {
  $TabSplitAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get gridType =>
      $composableBuilder(column: $table.gridType, builder: (column) => column);

  i0.GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  i0.GeneratedColumn<String> get orderKey =>
      $composableBuilder(column: $table.orderKey, builder: (column) => column);

  i2.$SpaceAnnotationComposer get spaceUuid {
    final i2.$SpaceAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.spaceUuid,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.Space>('space'),
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$SpaceAnnotationComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer($db).resultSet<i2.Space>('space'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i2.$TabFolderAnnotationComposer get folderId {
    final i2.$TabFolderAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.TabFolder>('tab_folder'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabFolderAnnotationComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.TabFolder>('tab_folder'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i0.Expression<T> tabRefs<T extends Object>(
    i0.Expression<T> Function(i2.$TabAnnotationComposer a) f,
  ) {
    final i2.$TabAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i11.ReadDatabaseContainer($db).resultSet<i2.Tab>('tab'),
      getReferencedColumn: (t) => t.splitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabAnnotationComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer($db).resultSet<i2.Tab>('tab'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $TabSplitTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i2.TabSplit,
          i6.TabSplitData,
          i2.$TabSplitFilterComposer,
          i2.$TabSplitOrderingComposer,
          i2.$TabSplitAnnotationComposer,
          $TabSplitCreateCompanionBuilder,
          $TabSplitUpdateCompanionBuilder,
          (i6.TabSplitData, i2.$TabSplitReferences),
          i6.TabSplitData,
          i0.PrefetchHooks Function({
            bool spaceUuid,
            bool folderId,
            bool tabRefs,
          })
        > {
  $TabSplitTableManager(i0.GeneratedDatabase db, i2.TabSplit table)
    : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i2.$TabSplitFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i2.$TabSplitOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i2.$TabSplitAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> id = const i0.Value.absent(),
                i0.Value<String> gridType = const i0.Value.absent(),
                i0.Value<bool> isPinned = const i0.Value.absent(),
                i0.Value<String?> spaceUuid = const i0.Value.absent(),
                i0.Value<String?> folderId = const i0.Value.absent(),
                i0.Value<String> orderKey = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.TabSplitCompanion(
                id: id,
                gridType: gridType,
                isPinned: isPinned,
                spaceUuid: spaceUuid,
                folderId: folderId,
                orderKey: orderKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                i0.Value<String> gridType = const i0.Value.absent(),
                i0.Value<bool> isPinned = const i0.Value.absent(),
                i0.Value<String?> spaceUuid = const i0.Value.absent(),
                i0.Value<String?> folderId = const i0.Value.absent(),
                required String orderKey,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.TabSplitCompanion.insert(
                id: id,
                gridType: gridType,
                isPinned: isPinned,
                spaceUuid: spaceUuid,
                folderId: folderId,
                orderKey: orderKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), i2.$TabSplitReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({spaceUuid = false, folderId = false, tabRefs = false}) {
                return i0.PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (tabRefs)
                      i11.ReadDatabaseContainer(db).resultSet<i2.Tab>('tab'),
                  ],
                  addJoins:
                      <
                        T extends i0.TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (spaceUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.spaceUuid,
                                    referencedTable: i2.$TabSplitReferences
                                        ._spaceUuidTable(db),
                                    referencedColumn: i2.$TabSplitReferences
                                        ._spaceUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }
                        if (folderId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.folderId,
                                    referencedTable: i2.$TabSplitReferences
                                        ._folderIdTable(db),
                                    referencedColumn: i2.$TabSplitReferences
                                        ._folderIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (tabRefs)
                        await i0.$_getPrefetchedData<
                          i6.TabSplitData,
                          i2.TabSplit,
                          i2.TabData
                        >(
                          currentTable: table,
                          referencedTable: i2.$TabSplitReferences._tabRefsTable(
                            db,
                          ),
                          managerFromTypedResult: (p0) =>
                              i2.$TabSplitReferences(db, table, p0).tabRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.splitId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $TabSplitProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i2.TabSplit,
      i6.TabSplitData,
      i2.$TabSplitFilterComposer,
      i2.$TabSplitOrderingComposer,
      i2.$TabSplitAnnotationComposer,
      $TabSplitCreateCompanionBuilder,
      $TabSplitUpdateCompanionBuilder,
      (i6.TabSplitData, i2.$TabSplitReferences),
      i6.TabSplitData,
      i0.PrefetchHooks Function({bool spaceUuid, bool folderId, bool tabRefs})
    >;
typedef $TabCreateCompanionBuilder =
    i2.TabCompanion Function({
      required String id,
      i0.Value<String?> engineTabId,
      required i7.TabSource source,
      i0.Value<String?> parentId,
      i0.Value<String?> containerId,
      i0.Value<String?> spaceUuid,
      i0.Value<String?> folderId,
      i0.Value<String?> splitId,
      i0.Value<int?> splitIndex,
      i0.Value<i8.TabShelf> tabShelf,
      required String orderKey,
      i0.Value<Uri?> url,
      i0.Value<String?> title,
      i0.Value<String?> iconUrl,
      i0.Value<String?> staticLabel,
      i0.Value<bool> hasStaticIcon,
      i0.Value<bool> defaultContainer,
      i0.Value<i9.TabModeDbValue> tabMode,
      i0.Value<bool?> isProbablyReaderable,
      i0.Value<String?> extractedContentMarkdown,
      i0.Value<String?> extractedContentPlain,
      i0.Value<String?> fullContentMarkdown,
      i0.Value<String?> fullContentPlain,
      required DateTime timestamp,
      i0.Value<int> rowid,
    });
typedef $TabUpdateCompanionBuilder =
    i2.TabCompanion Function({
      i0.Value<String> id,
      i0.Value<String?> engineTabId,
      i0.Value<i7.TabSource> source,
      i0.Value<String?> parentId,
      i0.Value<String?> containerId,
      i0.Value<String?> spaceUuid,
      i0.Value<String?> folderId,
      i0.Value<String?> splitId,
      i0.Value<int?> splitIndex,
      i0.Value<i8.TabShelf> tabShelf,
      i0.Value<String> orderKey,
      i0.Value<Uri?> url,
      i0.Value<String?> title,
      i0.Value<String?> iconUrl,
      i0.Value<String?> staticLabel,
      i0.Value<bool> hasStaticIcon,
      i0.Value<bool> defaultContainer,
      i0.Value<i9.TabModeDbValue> tabMode,
      i0.Value<bool?> isProbablyReaderable,
      i0.Value<String?> extractedContentMarkdown,
      i0.Value<String?> extractedContentPlain,
      i0.Value<String?> fullContentMarkdown,
      i0.Value<String?> fullContentPlain,
      i0.Value<DateTime> timestamp,
      i0.Value<int> rowid,
    });

final class $TabReferences
    extends i0.BaseReferences<i0.GeneratedDatabase, i2.Tab, i2.TabData> {
  $TabReferences(super.$_db, super.$_table, super.$_typedResult);

  static i2.Tab _parentIdTable(i0.GeneratedDatabase db) =>
      i11.ReadDatabaseContainer(
        db,
      ).resultSet<i2.Tab>('tab').createAlias('tab__parent_id__tab__id');

  i2.$TabProcessedTableManager? get parentId {
    final $_column = $_itemColumn<String>('parent_id');
    if ($_column == null) return null;
    final manager = i2
        .$TabTableManager(
          $_db,
          i11.ReadDatabaseContainer($_db).resultSet<i2.Tab>('tab'),
        )
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static i2.Container _containerIdTable(i0.GeneratedDatabase db) =>
      i11.ReadDatabaseContainer(db)
          .resultSet<i2.Container>('container')
          .createAlias('tab__container_id__container__id');

  i2.$ContainerProcessedTableManager? get containerId {
    final $_column = $_itemColumn<String>('container_id');
    if ($_column == null) return null;
    final manager = i2
        .$ContainerTableManager(
          $_db,
          i11.ReadDatabaseContainer($_db).resultSet<i2.Container>('container'),
        )
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_containerIdTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static i2.Space _spaceUuidTable(i0.GeneratedDatabase db) =>
      i11.ReadDatabaseContainer(db)
          .resultSet<i2.Space>('space')
          .createAlias('tab__space_uuid__space__uuid');

  i2.$SpaceProcessedTableManager? get spaceUuid {
    final $_column = $_itemColumn<String>('space_uuid');
    if ($_column == null) return null;
    final manager = i2
        .$SpaceTableManager(
          $_db,
          i11.ReadDatabaseContainer($_db).resultSet<i2.Space>('space'),
        )
        .filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_spaceUuidTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static i2.TabFolder _folderIdTable(i0.GeneratedDatabase db) =>
      i11.ReadDatabaseContainer(db)
          .resultSet<i2.TabFolder>('tab_folder')
          .createAlias('tab__folder_id__tab_folder__id');

  i2.$TabFolderProcessedTableManager? get folderId {
    final $_column = $_itemColumn<String>('folder_id');
    if ($_column == null) return null;
    final manager = i2
        .$TabFolderTableManager(
          $_db,
          i11.ReadDatabaseContainer($_db).resultSet<i2.TabFolder>('tab_folder'),
        )
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_folderIdTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static i2.TabSplit _splitIdTable(i0.GeneratedDatabase db) =>
      i11.ReadDatabaseContainer(db)
          .resultSet<i2.TabSplit>('tab_split')
          .createAlias('tab__split_id__tab_split__id');

  i2.$TabSplitProcessedTableManager? get splitId {
    final $_column = $_itemColumn<String>('split_id');
    if ($_column == null) return null;
    final manager = i2
        .$TabSplitTableManager(
          $_db,
          i11.ReadDatabaseContainer($_db).resultSet<i2.TabSplit>('tab_split'),
        )
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_splitIdTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static i0.MultiTypedResultKey<i2.CaptureTab, List<i2.CaptureTabData>>
  _captureTabRefsTable(i0.GeneratedDatabase db) =>
      i0.MultiTypedResultKey.fromTable(
        i11.ReadDatabaseContainer(db).resultSet<i2.CaptureTab>('capture_tab'),
        aliasName: 'tab__id__capture_tab__tab_id',
      );

  i2.$CaptureTabProcessedTableManager get captureTabRefs {
    final manager = i2
        .$CaptureTabTableManager(
          $_db,
          i11.ReadDatabaseContainer(
            $_db,
          ).resultSet<i2.CaptureTab>('capture_tab'),
        )
        .filter((f) => f.tabId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_captureTabRefsTable($_db));
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $TabFilterComposer extends i0.Composer<i0.GeneratedDatabase, i2.Tab> {
  $TabFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get engineTabId => $composableBuilder(
    column: $table.engineTabId,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnWithTypeConverterFilters<i7.TabSource, i7.TabSource, int>
  get source => $composableBuilder(
    column: $table.source,
    builder: (column) => i0.ColumnWithTypeConverterFilters(column),
  );

  i0.ColumnFilters<int> get splitIndex => $composableBuilder(
    column: $table.splitIndex,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnWithTypeConverterFilters<i8.TabShelf, i8.TabShelf, int>
  get tabShelf => $composableBuilder(
    column: $table.tabShelf,
    builder: (column) => i0.ColumnWithTypeConverterFilters(column),
  );

  i0.ColumnFilters<String> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnWithTypeConverterFilters<Uri?, Uri, String> get url =>
      $composableBuilder(
        column: $table.url,
        builder: (column) => i0.ColumnWithTypeConverterFilters(column),
      );

  i0.ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get iconUrl => $composableBuilder(
    column: $table.iconUrl,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get staticLabel => $composableBuilder(
    column: $table.staticLabel,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<bool> get hasStaticIcon => $composableBuilder(
    column: $table.hasStaticIcon,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<bool> get defaultContainer => $composableBuilder(
    column: $table.defaultContainer,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnWithTypeConverterFilters<i9.TabModeDbValue, i9.TabModeDbValue, int>
  get tabMode => $composableBuilder(
    column: $table.tabMode,
    builder: (column) => i0.ColumnWithTypeConverterFilters(column),
  );

  i0.ColumnFilters<bool> get isProbablyReaderable => $composableBuilder(
    column: $table.isProbablyReaderable,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get extractedContentMarkdown => $composableBuilder(
    column: $table.extractedContentMarkdown,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get extractedContentPlain => $composableBuilder(
    column: $table.extractedContentPlain,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get fullContentMarkdown => $composableBuilder(
    column: $table.fullContentMarkdown,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get fullContentPlain => $composableBuilder(
    column: $table.fullContentPlain,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => i0.ColumnFilters(column),
  );

  i2.$TabFilterComposer get parentId {
    final i2.$TabFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: i11.ReadDatabaseContainer($db).resultSet<i2.Tab>('tab'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabFilterComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer($db).resultSet<i2.Tab>('tab'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i2.$ContainerFilterComposer get containerId {
    final i2.$ContainerFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.containerId,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.Container>('container'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$ContainerFilterComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.Container>('container'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i2.$SpaceFilterComposer get spaceUuid {
    final i2.$SpaceFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.spaceUuid,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.Space>('space'),
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$SpaceFilterComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer($db).resultSet<i2.Space>('space'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i2.$TabFolderFilterComposer get folderId {
    final i2.$TabFolderFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.TabFolder>('tab_folder'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabFolderFilterComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.TabFolder>('tab_folder'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i2.$TabSplitFilterComposer get splitId {
    final i2.$TabSplitFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.splitId,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.TabSplit>('tab_split'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabSplitFilterComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.TabSplit>('tab_split'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i0.Expression<bool> captureTabRefs(
    i0.Expression<bool> Function(i2.$CaptureTabFilterComposer f) f,
  ) {
    final i2.$CaptureTabFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.CaptureTab>('capture_tab'),
      getReferencedColumn: (t) => t.tabId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$CaptureTabFilterComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.CaptureTab>('capture_tab'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $TabOrderingComposer extends i0.Composer<i0.GeneratedDatabase, i2.Tab> {
  $TabOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get engineTabId => $composableBuilder(
    column: $table.engineTabId,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get splitIndex => $composableBuilder(
    column: $table.splitIndex,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get tabShelf => $composableBuilder(
    column: $table.tabShelf,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get iconUrl => $composableBuilder(
    column: $table.iconUrl,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get staticLabel => $composableBuilder(
    column: $table.staticLabel,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<bool> get hasStaticIcon => $composableBuilder(
    column: $table.hasStaticIcon,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<bool> get defaultContainer => $composableBuilder(
    column: $table.defaultContainer,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get tabMode => $composableBuilder(
    column: $table.tabMode,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<bool> get isProbablyReaderable => $composableBuilder(
    column: $table.isProbablyReaderable,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get extractedContentMarkdown => $composableBuilder(
    column: $table.extractedContentMarkdown,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get extractedContentPlain => $composableBuilder(
    column: $table.extractedContentPlain,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get fullContentMarkdown => $composableBuilder(
    column: $table.fullContentMarkdown,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get fullContentPlain => $composableBuilder(
    column: $table.fullContentPlain,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i2.$TabOrderingComposer get parentId {
    final i2.$TabOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: i11.ReadDatabaseContainer($db).resultSet<i2.Tab>('tab'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabOrderingComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer($db).resultSet<i2.Tab>('tab'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i2.$ContainerOrderingComposer get containerId {
    final i2.$ContainerOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.containerId,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.Container>('container'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$ContainerOrderingComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.Container>('container'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i2.$SpaceOrderingComposer get spaceUuid {
    final i2.$SpaceOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.spaceUuid,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.Space>('space'),
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$SpaceOrderingComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer($db).resultSet<i2.Space>('space'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i2.$TabFolderOrderingComposer get folderId {
    final i2.$TabFolderOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.TabFolder>('tab_folder'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabFolderOrderingComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.TabFolder>('tab_folder'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i2.$TabSplitOrderingComposer get splitId {
    final i2.$TabSplitOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.splitId,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.TabSplit>('tab_split'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabSplitOrderingComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.TabSplit>('tab_split'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TabAnnotationComposer extends i0.Composer<i0.GeneratedDatabase, i2.Tab> {
  $TabAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get engineTabId => $composableBuilder(
    column: $table.engineTabId,
    builder: (column) => column,
  );

  i0.GeneratedColumnWithTypeConverter<i7.TabSource, int> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  i0.GeneratedColumn<int> get splitIndex => $composableBuilder(
    column: $table.splitIndex,
    builder: (column) => column,
  );

  i0.GeneratedColumnWithTypeConverter<i8.TabShelf, int> get tabShelf =>
      $composableBuilder(column: $table.tabShelf, builder: (column) => column);

  i0.GeneratedColumn<String> get orderKey =>
      $composableBuilder(column: $table.orderKey, builder: (column) => column);

  i0.GeneratedColumnWithTypeConverter<Uri?, String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  i0.GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  i0.GeneratedColumn<String> get iconUrl =>
      $composableBuilder(column: $table.iconUrl, builder: (column) => column);

  i0.GeneratedColumn<String> get staticLabel => $composableBuilder(
    column: $table.staticLabel,
    builder: (column) => column,
  );

  i0.GeneratedColumn<bool> get hasStaticIcon => $composableBuilder(
    column: $table.hasStaticIcon,
    builder: (column) => column,
  );

  i0.GeneratedColumn<bool> get defaultContainer => $composableBuilder(
    column: $table.defaultContainer,
    builder: (column) => column,
  );

  i0.GeneratedColumnWithTypeConverter<i9.TabModeDbValue, int> get tabMode =>
      $composableBuilder(column: $table.tabMode, builder: (column) => column);

  i0.GeneratedColumn<bool> get isProbablyReaderable => $composableBuilder(
    column: $table.isProbablyReaderable,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get extractedContentMarkdown => $composableBuilder(
    column: $table.extractedContentMarkdown,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get extractedContentPlain => $composableBuilder(
    column: $table.extractedContentPlain,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get fullContentMarkdown => $composableBuilder(
    column: $table.fullContentMarkdown,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get fullContentPlain => $composableBuilder(
    column: $table.fullContentPlain,
    builder: (column) => column,
  );

  i0.GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  i0.GeneratedColumn<int> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  i2.$TabAnnotationComposer get parentId {
    final i2.$TabAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: i11.ReadDatabaseContainer($db).resultSet<i2.Tab>('tab'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabAnnotationComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer($db).resultSet<i2.Tab>('tab'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i2.$ContainerAnnotationComposer get containerId {
    final i2.$ContainerAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.containerId,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.Container>('container'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$ContainerAnnotationComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.Container>('container'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i2.$SpaceAnnotationComposer get spaceUuid {
    final i2.$SpaceAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.spaceUuid,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.Space>('space'),
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$SpaceAnnotationComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer($db).resultSet<i2.Space>('space'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i2.$TabFolderAnnotationComposer get folderId {
    final i2.$TabFolderAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.TabFolder>('tab_folder'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabFolderAnnotationComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.TabFolder>('tab_folder'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i2.$TabSplitAnnotationComposer get splitId {
    final i2.$TabSplitAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.splitId,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.TabSplit>('tab_split'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabSplitAnnotationComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.TabSplit>('tab_split'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i0.Expression<T> captureTabRefs<T extends Object>(
    i0.Expression<T> Function(i2.$CaptureTabAnnotationComposer a) f,
  ) {
    final i2.$CaptureTabAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.CaptureTab>('capture_tab'),
      getReferencedColumn: (t) => t.tabId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$CaptureTabAnnotationComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.CaptureTab>('capture_tab'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $TabTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i2.Tab,
          i2.TabData,
          i2.$TabFilterComposer,
          i2.$TabOrderingComposer,
          i2.$TabAnnotationComposer,
          $TabCreateCompanionBuilder,
          $TabUpdateCompanionBuilder,
          (i2.TabData, i2.$TabReferences),
          i2.TabData,
          i0.PrefetchHooks Function({
            bool parentId,
            bool containerId,
            bool spaceUuid,
            bool folderId,
            bool splitId,
            bool captureTabRefs,
          })
        > {
  $TabTableManager(i0.GeneratedDatabase db, i2.Tab table)
    : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i2.$TabFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i2.$TabOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i2.$TabAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> id = const i0.Value.absent(),
                i0.Value<String?> engineTabId = const i0.Value.absent(),
                i0.Value<i7.TabSource> source = const i0.Value.absent(),
                i0.Value<String?> parentId = const i0.Value.absent(),
                i0.Value<String?> containerId = const i0.Value.absent(),
                i0.Value<String?> spaceUuid = const i0.Value.absent(),
                i0.Value<String?> folderId = const i0.Value.absent(),
                i0.Value<String?> splitId = const i0.Value.absent(),
                i0.Value<int?> splitIndex = const i0.Value.absent(),
                i0.Value<i8.TabShelf> tabShelf = const i0.Value.absent(),
                i0.Value<String> orderKey = const i0.Value.absent(),
                i0.Value<Uri?> url = const i0.Value.absent(),
                i0.Value<String?> title = const i0.Value.absent(),
                i0.Value<String?> iconUrl = const i0.Value.absent(),
                i0.Value<String?> staticLabel = const i0.Value.absent(),
                i0.Value<bool> hasStaticIcon = const i0.Value.absent(),
                i0.Value<bool> defaultContainer = const i0.Value.absent(),
                i0.Value<i9.TabModeDbValue> tabMode = const i0.Value.absent(),
                i0.Value<bool?> isProbablyReaderable = const i0.Value.absent(),
                i0.Value<String?> extractedContentMarkdown =
                    const i0.Value.absent(),
                i0.Value<String?> extractedContentPlain =
                    const i0.Value.absent(),
                i0.Value<String?> fullContentMarkdown = const i0.Value.absent(),
                i0.Value<String?> fullContentPlain = const i0.Value.absent(),
                i0.Value<DateTime> timestamp = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.TabCompanion(
                id: id,
                engineTabId: engineTabId,
                source: source,
                parentId: parentId,
                containerId: containerId,
                spaceUuid: spaceUuid,
                folderId: folderId,
                splitId: splitId,
                splitIndex: splitIndex,
                tabShelf: tabShelf,
                orderKey: orderKey,
                url: url,
                title: title,
                iconUrl: iconUrl,
                staticLabel: staticLabel,
                hasStaticIcon: hasStaticIcon,
                defaultContainer: defaultContainer,
                tabMode: tabMode,
                isProbablyReaderable: isProbablyReaderable,
                extractedContentMarkdown: extractedContentMarkdown,
                extractedContentPlain: extractedContentPlain,
                fullContentMarkdown: fullContentMarkdown,
                fullContentPlain: fullContentPlain,
                timestamp: timestamp,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                i0.Value<String?> engineTabId = const i0.Value.absent(),
                required i7.TabSource source,
                i0.Value<String?> parentId = const i0.Value.absent(),
                i0.Value<String?> containerId = const i0.Value.absent(),
                i0.Value<String?> spaceUuid = const i0.Value.absent(),
                i0.Value<String?> folderId = const i0.Value.absent(),
                i0.Value<String?> splitId = const i0.Value.absent(),
                i0.Value<int?> splitIndex = const i0.Value.absent(),
                i0.Value<i8.TabShelf> tabShelf = const i0.Value.absent(),
                required String orderKey,
                i0.Value<Uri?> url = const i0.Value.absent(),
                i0.Value<String?> title = const i0.Value.absent(),
                i0.Value<String?> iconUrl = const i0.Value.absent(),
                i0.Value<String?> staticLabel = const i0.Value.absent(),
                i0.Value<bool> hasStaticIcon = const i0.Value.absent(),
                i0.Value<bool> defaultContainer = const i0.Value.absent(),
                i0.Value<i9.TabModeDbValue> tabMode = const i0.Value.absent(),
                i0.Value<bool?> isProbablyReaderable = const i0.Value.absent(),
                i0.Value<String?> extractedContentMarkdown =
                    const i0.Value.absent(),
                i0.Value<String?> extractedContentPlain =
                    const i0.Value.absent(),
                i0.Value<String?> fullContentMarkdown = const i0.Value.absent(),
                i0.Value<String?> fullContentPlain = const i0.Value.absent(),
                required DateTime timestamp,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.TabCompanion.insert(
                id: id,
                engineTabId: engineTabId,
                source: source,
                parentId: parentId,
                containerId: containerId,
                spaceUuid: spaceUuid,
                folderId: folderId,
                splitId: splitId,
                splitIndex: splitIndex,
                tabShelf: tabShelf,
                orderKey: orderKey,
                url: url,
                title: title,
                iconUrl: iconUrl,
                staticLabel: staticLabel,
                hasStaticIcon: hasStaticIcon,
                defaultContainer: defaultContainer,
                tabMode: tabMode,
                isProbablyReaderable: isProbablyReaderable,
                extractedContentMarkdown: extractedContentMarkdown,
                extractedContentPlain: extractedContentPlain,
                fullContentMarkdown: fullContentMarkdown,
                fullContentPlain: fullContentPlain,
                timestamp: timestamp,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i2.$TabReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback:
              ({
                parentId = false,
                containerId = false,
                spaceUuid = false,
                folderId = false,
                splitId = false,
                captureTabRefs = false,
              }) {
                return i0.PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (captureTabRefs)
                      i11.ReadDatabaseContainer(
                        db,
                      ).resultSet<i2.CaptureTab>('capture_tab'),
                  ],
                  addJoins:
                      <
                        T extends i0.TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (parentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.parentId,
                                    referencedTable: i2.$TabReferences
                                        ._parentIdTable(db),
                                    referencedColumn: i2.$TabReferences
                                        ._parentIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (containerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.containerId,
                                    referencedTable: i2.$TabReferences
                                        ._containerIdTable(db),
                                    referencedColumn: i2.$TabReferences
                                        ._containerIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (spaceUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.spaceUuid,
                                    referencedTable: i2.$TabReferences
                                        ._spaceUuidTable(db),
                                    referencedColumn: i2.$TabReferences
                                        ._spaceUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }
                        if (folderId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.folderId,
                                    referencedTable: i2.$TabReferences
                                        ._folderIdTable(db),
                                    referencedColumn: i2.$TabReferences
                                        ._folderIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (splitId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.splitId,
                                    referencedTable: i2.$TabReferences
                                        ._splitIdTable(db),
                                    referencedColumn: i2.$TabReferences
                                        ._splitIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (captureTabRefs)
                        await i0.$_getPrefetchedData<
                          i2.TabData,
                          i2.Tab,
                          i2.CaptureTabData
                        >(
                          currentTable: table,
                          referencedTable: i2.$TabReferences
                              ._captureTabRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              i2.$TabReferences(db, table, p0).captureTabRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tabId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $TabProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i2.Tab,
      i2.TabData,
      i2.$TabFilterComposer,
      i2.$TabOrderingComposer,
      i2.$TabAnnotationComposer,
      $TabCreateCompanionBuilder,
      $TabUpdateCompanionBuilder,
      (i2.TabData, i2.$TabReferences),
      i2.TabData,
      i0.PrefetchHooks Function({
        bool parentId,
        bool containerId,
        bool spaceUuid,
        bool folderId,
        bool splitId,
        bool captureTabRefs,
      })
    >;
typedef $ClosedTabTombstoneCreateCompanionBuilder =
    i2.ClosedTabTombstoneCompanion Function({
      required String tabId,
      required DateTime closedAt,
      i0.Value<int> rowid,
    });
typedef $ClosedTabTombstoneUpdateCompanionBuilder =
    i2.ClosedTabTombstoneCompanion Function({
      i0.Value<String> tabId,
      i0.Value<DateTime> closedAt,
      i0.Value<int> rowid,
    });

class $ClosedTabTombstoneFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.ClosedTabTombstone> {
  $ClosedTabTombstoneFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get tabId => $composableBuilder(
    column: $table.tabId,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $ClosedTabTombstoneOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.ClosedTabTombstone> {
  $ClosedTabTombstoneOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get tabId => $composableBuilder(
    column: $table.tabId,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $ClosedTabTombstoneAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.ClosedTabTombstone> {
  $ClosedTabTombstoneAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get tabId =>
      $composableBuilder(column: $table.tabId, builder: (column) => column);

  i0.GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);
}

class $ClosedTabTombstoneTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i2.ClosedTabTombstone,
          i2.ClosedTabTombstoneData,
          i2.$ClosedTabTombstoneFilterComposer,
          i2.$ClosedTabTombstoneOrderingComposer,
          i2.$ClosedTabTombstoneAnnotationComposer,
          $ClosedTabTombstoneCreateCompanionBuilder,
          $ClosedTabTombstoneUpdateCompanionBuilder,
          (
            i2.ClosedTabTombstoneData,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i2.ClosedTabTombstone,
              i2.ClosedTabTombstoneData
            >,
          ),
          i2.ClosedTabTombstoneData,
          i0.PrefetchHooks Function()
        > {
  $ClosedTabTombstoneTableManager(
    i0.GeneratedDatabase db,
    i2.ClosedTabTombstone table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i2.$ClosedTabTombstoneFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i2.$ClosedTabTombstoneOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i2.$ClosedTabTombstoneAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> tabId = const i0.Value.absent(),
                i0.Value<DateTime> closedAt = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.ClosedTabTombstoneCompanion(
                tabId: tabId,
                closedAt: closedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tabId,
                required DateTime closedAt,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.ClosedTabTombstoneCompanion.insert(
                tabId: tabId,
                closedAt: closedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $ClosedTabTombstoneProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i2.ClosedTabTombstone,
      i2.ClosedTabTombstoneData,
      i2.$ClosedTabTombstoneFilterComposer,
      i2.$ClosedTabTombstoneOrderingComposer,
      i2.$ClosedTabTombstoneAnnotationComposer,
      $ClosedTabTombstoneCreateCompanionBuilder,
      $ClosedTabTombstoneUpdateCompanionBuilder,
      (
        i2.ClosedTabTombstoneData,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i2.ClosedTabTombstone,
          i2.ClosedTabTombstoneData
        >,
      ),
      i2.ClosedTabTombstoneData,
      i0.PrefetchHooks Function()
    >;
typedef $CaptureTabCreateCompanionBuilder =
    i2.CaptureTabCompanion Function({
      required String tabId,
      required String captureId,
      required String sourceUrl,
      i0.Value<String> status,
      required DateTime createdAt,
      i0.Value<int> rowid,
    });
typedef $CaptureTabUpdateCompanionBuilder =
    i2.CaptureTabCompanion Function({
      i0.Value<String> tabId,
      i0.Value<String> captureId,
      i0.Value<String> sourceUrl,
      i0.Value<String> status,
      i0.Value<DateTime> createdAt,
      i0.Value<int> rowid,
    });

final class $CaptureTabReferences
    extends
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i2.CaptureTab,
          i2.CaptureTabData
        > {
  $CaptureTabReferences(super.$_db, super.$_table, super.$_typedResult);

  static i2.Tab _tabIdTable(i0.GeneratedDatabase db) =>
      i11.ReadDatabaseContainer(
        db,
      ).resultSet<i2.Tab>('tab').createAlias('capture_tab__tab_id__tab__id');

  i2.$TabProcessedTableManager get tabId {
    final $_column = $_itemColumn<String>('tab_id')!;

    final manager = i2
        .$TabTableManager(
          $_db,
          i11.ReadDatabaseContainer($_db).resultSet<i2.Tab>('tab'),
        )
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tabIdTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $CaptureTabFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.CaptureTab> {
  $CaptureTabFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get captureId => $composableBuilder(
    column: $table.captureId,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i2.$TabFilterComposer get tabId {
    final i2.$TabFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tabId,
      referencedTable: i11.ReadDatabaseContainer($db).resultSet<i2.Tab>('tab'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabFilterComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer($db).resultSet<i2.Tab>('tab'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CaptureTabOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.CaptureTab> {
  $CaptureTabOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get captureId => $composableBuilder(
    column: $table.captureId,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i2.$TabOrderingComposer get tabId {
    final i2.$TabOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tabId,
      referencedTable: i11.ReadDatabaseContainer($db).resultSet<i2.Tab>('tab'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabOrderingComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer($db).resultSet<i2.Tab>('tab'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CaptureTabAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.CaptureTab> {
  $CaptureTabAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get captureId =>
      $composableBuilder(column: $table.captureId, builder: (column) => column);

  i0.GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  i0.GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  i0.GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  i2.$TabAnnotationComposer get tabId {
    final i2.$TabAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tabId,
      referencedTable: i11.ReadDatabaseContainer($db).resultSet<i2.Tab>('tab'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$TabAnnotationComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer($db).resultSet<i2.Tab>('tab'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CaptureTabTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i2.CaptureTab,
          i2.CaptureTabData,
          i2.$CaptureTabFilterComposer,
          i2.$CaptureTabOrderingComposer,
          i2.$CaptureTabAnnotationComposer,
          $CaptureTabCreateCompanionBuilder,
          $CaptureTabUpdateCompanionBuilder,
          (i2.CaptureTabData, i2.$CaptureTabReferences),
          i2.CaptureTabData,
          i0.PrefetchHooks Function({bool tabId})
        > {
  $CaptureTabTableManager(i0.GeneratedDatabase db, i2.CaptureTab table)
    : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i2.$CaptureTabFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i2.$CaptureTabOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i2.$CaptureTabAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> tabId = const i0.Value.absent(),
                i0.Value<String> captureId = const i0.Value.absent(),
                i0.Value<String> sourceUrl = const i0.Value.absent(),
                i0.Value<String> status = const i0.Value.absent(),
                i0.Value<DateTime> createdAt = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.CaptureTabCompanion(
                tabId: tabId,
                captureId: captureId,
                sourceUrl: sourceUrl,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tabId,
                required String captureId,
                required String sourceUrl,
                i0.Value<String> status = const i0.Value.absent(),
                required DateTime createdAt,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.CaptureTabCompanion.insert(
                tabId: tabId,
                captureId: captureId,
                sourceUrl: sourceUrl,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  i2.$CaptureTabReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({tabId = false}) {
            return i0.PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends i0.TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (tabId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tabId,
                                referencedTable: i2.$CaptureTabReferences
                                    ._tabIdTable(db),
                                referencedColumn: i2.$CaptureTabReferences
                                    ._tabIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $CaptureTabProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i2.CaptureTab,
      i2.CaptureTabData,
      i2.$CaptureTabFilterComposer,
      i2.$CaptureTabOrderingComposer,
      i2.$CaptureTabAnnotationComposer,
      $CaptureTabCreateCompanionBuilder,
      $CaptureTabUpdateCompanionBuilder,
      (i2.CaptureTabData, i2.$CaptureTabReferences),
      i2.CaptureTabData,
      i0.PrefetchHooks Function({bool tabId})
    >;
typedef $TabFtsCreateCompanionBuilder =
    i2.TabFtsCompanion Function({
      required String title,
      required String url,
      required String extractedContentPlain,
      required String fullContentPlain,
      i0.Value<int> rowid,
    });
typedef $TabFtsUpdateCompanionBuilder =
    i2.TabFtsCompanion Function({
      i0.Value<String> title,
      i0.Value<String> url,
      i0.Value<String> extractedContentPlain,
      i0.Value<String> fullContentPlain,
      i0.Value<int> rowid,
    });

class $TabFtsFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.TabFts> {
  $TabFtsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get extractedContentPlain => $composableBuilder(
    column: $table.extractedContentPlain,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get fullContentPlain => $composableBuilder(
    column: $table.fullContentPlain,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $TabFtsOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.TabFts> {
  $TabFtsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get extractedContentPlain => $composableBuilder(
    column: $table.extractedContentPlain,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get fullContentPlain => $composableBuilder(
    column: $table.fullContentPlain,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $TabFtsAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.TabFts> {
  $TabFtsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  i0.GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  i0.GeneratedColumn<String> get extractedContentPlain => $composableBuilder(
    column: $table.extractedContentPlain,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get fullContentPlain => $composableBuilder(
    column: $table.fullContentPlain,
    builder: (column) => column,
  );
}

class $TabFtsTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i2.TabFts,
          i2.TabFt,
          i2.$TabFtsFilterComposer,
          i2.$TabFtsOrderingComposer,
          i2.$TabFtsAnnotationComposer,
          $TabFtsCreateCompanionBuilder,
          $TabFtsUpdateCompanionBuilder,
          (
            i2.TabFt,
            i0.BaseReferences<i0.GeneratedDatabase, i2.TabFts, i2.TabFt>,
          ),
          i2.TabFt,
          i0.PrefetchHooks Function()
        > {
  $TabFtsTableManager(i0.GeneratedDatabase db, i2.TabFts table)
    : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i2.$TabFtsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i2.$TabFtsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i2.$TabFtsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> title = const i0.Value.absent(),
                i0.Value<String> url = const i0.Value.absent(),
                i0.Value<String> extractedContentPlain =
                    const i0.Value.absent(),
                i0.Value<String> fullContentPlain = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.TabFtsCompanion(
                title: title,
                url: url,
                extractedContentPlain: extractedContentPlain,
                fullContentPlain: fullContentPlain,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String title,
                required String url,
                required String extractedContentPlain,
                required String fullContentPlain,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.TabFtsCompanion.insert(
                title: title,
                url: url,
                extractedContentPlain: extractedContentPlain,
                fullContentPlain: fullContentPlain,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $TabFtsProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i2.TabFts,
      i2.TabFt,
      i2.$TabFtsFilterComposer,
      i2.$TabFtsOrderingComposer,
      i2.$TabFtsAnnotationComposer,
      $TabFtsCreateCompanionBuilder,
      $TabFtsUpdateCompanionBuilder,
      (i2.TabFt, i0.BaseReferences<i0.GeneratedDatabase, i2.TabFts, i2.TabFt>),
      i2.TabFt,
      i0.PrefetchHooks Function()
    >;
typedef $LocalIndexSettingCreateCompanionBuilder =
    i2.LocalIndexSettingCompanion Function({
      required String key,
      required int value,
      i0.Value<int> rowid,
    });
typedef $LocalIndexSettingUpdateCompanionBuilder =
    i2.LocalIndexSettingCompanion Function({
      i0.Value<String> key,
      i0.Value<int> value,
      i0.Value<int> rowid,
    });

class $LocalIndexSettingFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.LocalIndexSetting> {
  $LocalIndexSettingFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $LocalIndexSettingOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.LocalIndexSetting> {
  $LocalIndexSettingOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $LocalIndexSettingAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.LocalIndexSetting> {
  $LocalIndexSettingAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  i0.GeneratedColumn<int> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $LocalIndexSettingTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i2.LocalIndexSetting,
          i2.LocalIndexSettingData,
          i2.$LocalIndexSettingFilterComposer,
          i2.$LocalIndexSettingOrderingComposer,
          i2.$LocalIndexSettingAnnotationComposer,
          $LocalIndexSettingCreateCompanionBuilder,
          $LocalIndexSettingUpdateCompanionBuilder,
          (
            i2.LocalIndexSettingData,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i2.LocalIndexSetting,
              i2.LocalIndexSettingData
            >,
          ),
          i2.LocalIndexSettingData,
          i0.PrefetchHooks Function()
        > {
  $LocalIndexSettingTableManager(
    i0.GeneratedDatabase db,
    i2.LocalIndexSetting table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i2.$LocalIndexSettingFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i2.$LocalIndexSettingOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i2.$LocalIndexSettingAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> key = const i0.Value.absent(),
                i0.Value<int> value = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.LocalIndexSettingCompanion(
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required int value,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.LocalIndexSettingCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $LocalIndexSettingProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i2.LocalIndexSetting,
      i2.LocalIndexSettingData,
      i2.$LocalIndexSettingFilterComposer,
      i2.$LocalIndexSettingOrderingComposer,
      i2.$LocalIndexSettingAnnotationComposer,
      $LocalIndexSettingCreateCompanionBuilder,
      $LocalIndexSettingUpdateCompanionBuilder,
      (
        i2.LocalIndexSettingData,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i2.LocalIndexSetting,
          i2.LocalIndexSettingData
        >,
      ),
      i2.LocalIndexSettingData,
      i0.PrefetchHooks Function()
    >;
typedef $HistoryCreateCompanionBuilder =
    i2.HistoryCompanion Function({
      required String urlCanonical,
      required String urlHost,
      i0.Value<String?> urlPath,
      i0.Value<String?> title,
      i0.Value<bool?> isProbablyReaderable,
      i0.Value<String?> extractedContentMarkdown,
      i0.Value<String?> extractedContentPlain,
      i0.Value<String?> fullContentMarkdown,
      i0.Value<String?> fullContentPlain,
      i0.Value<int?> contentHash,
      required DateTime observedAt,
      i0.Value<int> observedCount,
      i0.Value<int> rowid,
    });
typedef $HistoryUpdateCompanionBuilder =
    i2.HistoryCompanion Function({
      i0.Value<String> urlCanonical,
      i0.Value<String> urlHost,
      i0.Value<String?> urlPath,
      i0.Value<String?> title,
      i0.Value<bool?> isProbablyReaderable,
      i0.Value<String?> extractedContentMarkdown,
      i0.Value<String?> extractedContentPlain,
      i0.Value<String?> fullContentMarkdown,
      i0.Value<String?> fullContentPlain,
      i0.Value<int?> contentHash,
      i0.Value<DateTime> observedAt,
      i0.Value<int> observedCount,
      i0.Value<int> rowid,
    });

class $HistoryFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.History> {
  $HistoryFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get urlCanonical => $composableBuilder(
    column: $table.urlCanonical,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get urlHost => $composableBuilder(
    column: $table.urlHost,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get urlPath => $composableBuilder(
    column: $table.urlPath,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<bool> get isProbablyReaderable => $composableBuilder(
    column: $table.isProbablyReaderable,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get extractedContentMarkdown => $composableBuilder(
    column: $table.extractedContentMarkdown,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get extractedContentPlain => $composableBuilder(
    column: $table.extractedContentPlain,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get fullContentMarkdown => $composableBuilder(
    column: $table.fullContentMarkdown,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get fullContentPlain => $composableBuilder(
    column: $table.fullContentPlain,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<DateTime> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get observedCount => $composableBuilder(
    column: $table.observedCount,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $HistoryOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.History> {
  $HistoryOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get urlCanonical => $composableBuilder(
    column: $table.urlCanonical,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get urlHost => $composableBuilder(
    column: $table.urlHost,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get urlPath => $composableBuilder(
    column: $table.urlPath,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<bool> get isProbablyReaderable => $composableBuilder(
    column: $table.isProbablyReaderable,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get extractedContentMarkdown => $composableBuilder(
    column: $table.extractedContentMarkdown,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get extractedContentPlain => $composableBuilder(
    column: $table.extractedContentPlain,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get fullContentMarkdown => $composableBuilder(
    column: $table.fullContentMarkdown,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get fullContentPlain => $composableBuilder(
    column: $table.fullContentPlain,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<DateTime> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get observedCount => $composableBuilder(
    column: $table.observedCount,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $HistoryAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.History> {
  $HistoryAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get urlCanonical => $composableBuilder(
    column: $table.urlCanonical,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get urlHost =>
      $composableBuilder(column: $table.urlHost, builder: (column) => column);

  i0.GeneratedColumn<String> get urlPath =>
      $composableBuilder(column: $table.urlPath, builder: (column) => column);

  i0.GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  i0.GeneratedColumn<bool> get isProbablyReaderable => $composableBuilder(
    column: $table.isProbablyReaderable,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get extractedContentMarkdown => $composableBuilder(
    column: $table.extractedContentMarkdown,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get extractedContentPlain => $composableBuilder(
    column: $table.extractedContentPlain,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get fullContentMarkdown => $composableBuilder(
    column: $table.fullContentMarkdown,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get fullContentPlain => $composableBuilder(
    column: $table.fullContentPlain,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  i0.GeneratedColumn<DateTime> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get observedCount => $composableBuilder(
    column: $table.observedCount,
    builder: (column) => column,
  );
}

class $HistoryTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i2.History,
          i2.HistoryData,
          i2.$HistoryFilterComposer,
          i2.$HistoryOrderingComposer,
          i2.$HistoryAnnotationComposer,
          $HistoryCreateCompanionBuilder,
          $HistoryUpdateCompanionBuilder,
          (
            i2.HistoryData,
            i0.BaseReferences<i0.GeneratedDatabase, i2.History, i2.HistoryData>,
          ),
          i2.HistoryData,
          i0.PrefetchHooks Function()
        > {
  $HistoryTableManager(i0.GeneratedDatabase db, i2.History table)
    : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i2.$HistoryFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i2.$HistoryOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i2.$HistoryAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> urlCanonical = const i0.Value.absent(),
                i0.Value<String> urlHost = const i0.Value.absent(),
                i0.Value<String?> urlPath = const i0.Value.absent(),
                i0.Value<String?> title = const i0.Value.absent(),
                i0.Value<bool?> isProbablyReaderable = const i0.Value.absent(),
                i0.Value<String?> extractedContentMarkdown =
                    const i0.Value.absent(),
                i0.Value<String?> extractedContentPlain =
                    const i0.Value.absent(),
                i0.Value<String?> fullContentMarkdown = const i0.Value.absent(),
                i0.Value<String?> fullContentPlain = const i0.Value.absent(),
                i0.Value<int?> contentHash = const i0.Value.absent(),
                i0.Value<DateTime> observedAt = const i0.Value.absent(),
                i0.Value<int> observedCount = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.HistoryCompanion(
                urlCanonical: urlCanonical,
                urlHost: urlHost,
                urlPath: urlPath,
                title: title,
                isProbablyReaderable: isProbablyReaderable,
                extractedContentMarkdown: extractedContentMarkdown,
                extractedContentPlain: extractedContentPlain,
                fullContentMarkdown: fullContentMarkdown,
                fullContentPlain: fullContentPlain,
                contentHash: contentHash,
                observedAt: observedAt,
                observedCount: observedCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String urlCanonical,
                required String urlHost,
                i0.Value<String?> urlPath = const i0.Value.absent(),
                i0.Value<String?> title = const i0.Value.absent(),
                i0.Value<bool?> isProbablyReaderable = const i0.Value.absent(),
                i0.Value<String?> extractedContentMarkdown =
                    const i0.Value.absent(),
                i0.Value<String?> extractedContentPlain =
                    const i0.Value.absent(),
                i0.Value<String?> fullContentMarkdown = const i0.Value.absent(),
                i0.Value<String?> fullContentPlain = const i0.Value.absent(),
                i0.Value<int?> contentHash = const i0.Value.absent(),
                required DateTime observedAt,
                i0.Value<int> observedCount = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.HistoryCompanion.insert(
                urlCanonical: urlCanonical,
                urlHost: urlHost,
                urlPath: urlPath,
                title: title,
                isProbablyReaderable: isProbablyReaderable,
                extractedContentMarkdown: extractedContentMarkdown,
                extractedContentPlain: extractedContentPlain,
                fullContentMarkdown: fullContentMarkdown,
                fullContentPlain: fullContentPlain,
                contentHash: contentHash,
                observedAt: observedAt,
                observedCount: observedCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $HistoryProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i2.History,
      i2.HistoryData,
      i2.$HistoryFilterComposer,
      i2.$HistoryOrderingComposer,
      i2.$HistoryAnnotationComposer,
      $HistoryCreateCompanionBuilder,
      $HistoryUpdateCompanionBuilder,
      (
        i2.HistoryData,
        i0.BaseReferences<i0.GeneratedDatabase, i2.History, i2.HistoryData>,
      ),
      i2.HistoryData,
      i0.PrefetchHooks Function()
    >;
typedef $HistoryFtsCreateCompanionBuilder =
    i2.HistoryFtsCompanion Function({
      required String title,
      required String urlHost,
      required String urlPath,
      required String extractedContentPlain,
      required String fullContentPlain,
      i0.Value<int> rowid,
    });
typedef $HistoryFtsUpdateCompanionBuilder =
    i2.HistoryFtsCompanion Function({
      i0.Value<String> title,
      i0.Value<String> urlHost,
      i0.Value<String> urlPath,
      i0.Value<String> extractedContentPlain,
      i0.Value<String> fullContentPlain,
      i0.Value<int> rowid,
    });

class $HistoryFtsFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.HistoryFts> {
  $HistoryFtsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get urlHost => $composableBuilder(
    column: $table.urlHost,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get urlPath => $composableBuilder(
    column: $table.urlPath,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get extractedContentPlain => $composableBuilder(
    column: $table.extractedContentPlain,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get fullContentPlain => $composableBuilder(
    column: $table.fullContentPlain,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $HistoryFtsOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.HistoryFts> {
  $HistoryFtsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get urlHost => $composableBuilder(
    column: $table.urlHost,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get urlPath => $composableBuilder(
    column: $table.urlPath,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get extractedContentPlain => $composableBuilder(
    column: $table.extractedContentPlain,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get fullContentPlain => $composableBuilder(
    column: $table.fullContentPlain,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $HistoryFtsAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.HistoryFts> {
  $HistoryFtsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  i0.GeneratedColumn<String> get urlHost =>
      $composableBuilder(column: $table.urlHost, builder: (column) => column);

  i0.GeneratedColumn<String> get urlPath =>
      $composableBuilder(column: $table.urlPath, builder: (column) => column);

  i0.GeneratedColumn<String> get extractedContentPlain => $composableBuilder(
    column: $table.extractedContentPlain,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get fullContentPlain => $composableBuilder(
    column: $table.fullContentPlain,
    builder: (column) => column,
  );
}

class $HistoryFtsTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i2.HistoryFts,
          i2.HistoryFt,
          i2.$HistoryFtsFilterComposer,
          i2.$HistoryFtsOrderingComposer,
          i2.$HistoryFtsAnnotationComposer,
          $HistoryFtsCreateCompanionBuilder,
          $HistoryFtsUpdateCompanionBuilder,
          (
            i2.HistoryFt,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i2.HistoryFts,
              i2.HistoryFt
            >,
          ),
          i2.HistoryFt,
          i0.PrefetchHooks Function()
        > {
  $HistoryFtsTableManager(i0.GeneratedDatabase db, i2.HistoryFts table)
    : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i2.$HistoryFtsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i2.$HistoryFtsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i2.$HistoryFtsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> title = const i0.Value.absent(),
                i0.Value<String> urlHost = const i0.Value.absent(),
                i0.Value<String> urlPath = const i0.Value.absent(),
                i0.Value<String> extractedContentPlain =
                    const i0.Value.absent(),
                i0.Value<String> fullContentPlain = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.HistoryFtsCompanion(
                title: title,
                urlHost: urlHost,
                urlPath: urlPath,
                extractedContentPlain: extractedContentPlain,
                fullContentPlain: fullContentPlain,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String title,
                required String urlHost,
                required String urlPath,
                required String extractedContentPlain,
                required String fullContentPlain,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.HistoryFtsCompanion.insert(
                title: title,
                urlHost: urlHost,
                urlPath: urlPath,
                extractedContentPlain: extractedContentPlain,
                fullContentPlain: fullContentPlain,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $HistoryFtsProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i2.HistoryFts,
      i2.HistoryFt,
      i2.$HistoryFtsFilterComposer,
      i2.$HistoryFtsOrderingComposer,
      i2.$HistoryFtsAnnotationComposer,
      $HistoryFtsCreateCompanionBuilder,
      $HistoryFtsUpdateCompanionBuilder,
      (
        i2.HistoryFt,
        i0.BaseReferences<i0.GeneratedDatabase, i2.HistoryFts, i2.HistoryFt>,
      ),
      i2.HistoryFt,
      i0.PrefetchHooks Function()
    >;
typedef $VisitContainerCreateCompanionBuilder =
    i2.VisitContainerCompanion Function({
      i0.Value<int> id,
      required String rawUrl,
      required String urlCanonical,
      required int visitTime,
      required String containerId,
    });
typedef $VisitContainerUpdateCompanionBuilder =
    i2.VisitContainerCompanion Function({
      i0.Value<int> id,
      i0.Value<String> rawUrl,
      i0.Value<String> urlCanonical,
      i0.Value<int> visitTime,
      i0.Value<String> containerId,
    });

final class $VisitContainerReferences
    extends
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i2.VisitContainer,
          i2.VisitContainerData
        > {
  $VisitContainerReferences(super.$_db, super.$_table, super.$_typedResult);

  static i2.Container _containerIdTable(i0.GeneratedDatabase db) =>
      i11.ReadDatabaseContainer(db)
          .resultSet<i2.Container>('container')
          .createAlias('visit_container__container_id__container__id');

  i2.$ContainerProcessedTableManager get containerId {
    final $_column = $_itemColumn<String>('container_id')!;

    final manager = i2
        .$ContainerTableManager(
          $_db,
          i11.ReadDatabaseContainer($_db).resultSet<i2.Container>('container'),
        )
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_containerIdTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $VisitContainerFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.VisitContainer> {
  $VisitContainerFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get rawUrl => $composableBuilder(
    column: $table.rawUrl,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get urlCanonical => $composableBuilder(
    column: $table.urlCanonical,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get visitTime => $composableBuilder(
    column: $table.visitTime,
    builder: (column) => i0.ColumnFilters(column),
  );

  i2.$ContainerFilterComposer get containerId {
    final i2.$ContainerFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.containerId,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.Container>('container'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$ContainerFilterComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.Container>('container'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $VisitContainerOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.VisitContainer> {
  $VisitContainerOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get rawUrl => $composableBuilder(
    column: $table.rawUrl,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get urlCanonical => $composableBuilder(
    column: $table.urlCanonical,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get visitTime => $composableBuilder(
    column: $table.visitTime,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i2.$ContainerOrderingComposer get containerId {
    final i2.$ContainerOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.containerId,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.Container>('container'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$ContainerOrderingComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.Container>('container'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $VisitContainerAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.VisitContainer> {
  $VisitContainerAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get rawUrl =>
      $composableBuilder(column: $table.rawUrl, builder: (column) => column);

  i0.GeneratedColumn<String> get urlCanonical => $composableBuilder(
    column: $table.urlCanonical,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get visitTime =>
      $composableBuilder(column: $table.visitTime, builder: (column) => column);

  i2.$ContainerAnnotationComposer get containerId {
    final i2.$ContainerAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.containerId,
      referencedTable: i11.ReadDatabaseContainer(
        $db,
      ).resultSet<i2.Container>('container'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$ContainerAnnotationComposer(
            $db: $db,
            $table: i11.ReadDatabaseContainer(
              $db,
            ).resultSet<i2.Container>('container'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $VisitContainerTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i2.VisitContainer,
          i2.VisitContainerData,
          i2.$VisitContainerFilterComposer,
          i2.$VisitContainerOrderingComposer,
          i2.$VisitContainerAnnotationComposer,
          $VisitContainerCreateCompanionBuilder,
          $VisitContainerUpdateCompanionBuilder,
          (i2.VisitContainerData, i2.$VisitContainerReferences),
          i2.VisitContainerData,
          i0.PrefetchHooks Function({bool containerId})
        > {
  $VisitContainerTableManager(i0.GeneratedDatabase db, i2.VisitContainer table)
    : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i2.$VisitContainerFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i2.$VisitContainerOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i2.$VisitContainerAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                i0.Value<String> rawUrl = const i0.Value.absent(),
                i0.Value<String> urlCanonical = const i0.Value.absent(),
                i0.Value<int> visitTime = const i0.Value.absent(),
                i0.Value<String> containerId = const i0.Value.absent(),
              }) => i2.VisitContainerCompanion(
                id: id,
                rawUrl: rawUrl,
                urlCanonical: urlCanonical,
                visitTime: visitTime,
                containerId: containerId,
              ),
          createCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                required String rawUrl,
                required String urlCanonical,
                required int visitTime,
                required String containerId,
              }) => i2.VisitContainerCompanion.insert(
                id: id,
                rawUrl: rawUrl,
                urlCanonical: urlCanonical,
                visitTime: visitTime,
                containerId: containerId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  i2.$VisitContainerReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({containerId = false}) {
            return i0.PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends i0.TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (containerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.containerId,
                                referencedTable: i2.$VisitContainerReferences
                                    ._containerIdTable(db),
                                referencedColumn: i2.$VisitContainerReferences
                                    ._containerIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $VisitContainerProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i2.VisitContainer,
      i2.VisitContainerData,
      i2.$VisitContainerFilterComposer,
      i2.$VisitContainerOrderingComposer,
      i2.$VisitContainerAnnotationComposer,
      $VisitContainerCreateCompanionBuilder,
      $VisitContainerUpdateCompanionBuilder,
      (i2.VisitContainerData, i2.$VisitContainerReferences),
      i2.VisitContainerData,
      i0.PrefetchHooks Function({bool containerId})
    >;
typedef $ForeignRecordCreateCompanionBuilder =
    i2.ForeignRecordCompanion Function({
      required String id,
      required String kind,
      required String payload,
      required double modified,
      i0.Value<int> rowid,
    });
typedef $ForeignRecordUpdateCompanionBuilder =
    i2.ForeignRecordCompanion Function({
      i0.Value<String> id,
      i0.Value<String> kind,
      i0.Value<String> payload,
      i0.Value<double> modified,
      i0.Value<int> rowid,
    });

class $ForeignRecordFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.ForeignRecord> {
  $ForeignRecordFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<double> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $ForeignRecordOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.ForeignRecord> {
  $ForeignRecordOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<double> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $ForeignRecordAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.ForeignRecord> {
  $ForeignRecordAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  i0.GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  i0.GeneratedColumn<double> get modified =>
      $composableBuilder(column: $table.modified, builder: (column) => column);
}

class $ForeignRecordTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i2.ForeignRecord,
          i2.ForeignRecordData,
          i2.$ForeignRecordFilterComposer,
          i2.$ForeignRecordOrderingComposer,
          i2.$ForeignRecordAnnotationComposer,
          $ForeignRecordCreateCompanionBuilder,
          $ForeignRecordUpdateCompanionBuilder,
          (
            i2.ForeignRecordData,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i2.ForeignRecord,
              i2.ForeignRecordData
            >,
          ),
          i2.ForeignRecordData,
          i0.PrefetchHooks Function()
        > {
  $ForeignRecordTableManager(i0.GeneratedDatabase db, i2.ForeignRecord table)
    : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i2.$ForeignRecordFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i2.$ForeignRecordOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i2.$ForeignRecordAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> id = const i0.Value.absent(),
                i0.Value<String> kind = const i0.Value.absent(),
                i0.Value<String> payload = const i0.Value.absent(),
                i0.Value<double> modified = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.ForeignRecordCompanion(
                id: id,
                kind: kind,
                payload: payload,
                modified: modified,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required String payload,
                required double modified,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.ForeignRecordCompanion.insert(
                id: id,
                kind: kind,
                payload: payload,
                modified: modified,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $ForeignRecordProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i2.ForeignRecord,
      i2.ForeignRecordData,
      i2.$ForeignRecordFilterComposer,
      i2.$ForeignRecordOrderingComposer,
      i2.$ForeignRecordAnnotationComposer,
      $ForeignRecordCreateCompanionBuilder,
      $ForeignRecordUpdateCompanionBuilder,
      (
        i2.ForeignRecordData,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i2.ForeignRecord,
          i2.ForeignRecordData
        >,
      ),
      i2.ForeignRecordData,
      i0.PrefetchHooks Function()
    >;
typedef $SyncRecordStateCreateCompanionBuilder =
    i2.SyncRecordStateCompanion Function({
      required String recordId,
      required String kind,
      required String digest,
      i0.Value<int> rowid,
    });
typedef $SyncRecordStateUpdateCompanionBuilder =
    i2.SyncRecordStateCompanion Function({
      i0.Value<String> recordId,
      i0.Value<String> kind,
      i0.Value<String> digest,
      i0.Value<int> rowid,
    });

class $SyncRecordStateFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.SyncRecordState> {
  $SyncRecordStateFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get digest => $composableBuilder(
    column: $table.digest,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $SyncRecordStateOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.SyncRecordState> {
  $SyncRecordStateOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get digest => $composableBuilder(
    column: $table.digest,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $SyncRecordStateAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.SyncRecordState> {
  $SyncRecordStateAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  i0.GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  i0.GeneratedColumn<String> get digest =>
      $composableBuilder(column: $table.digest, builder: (column) => column);
}

class $SyncRecordStateTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i2.SyncRecordState,
          i2.SyncRecordStateData,
          i2.$SyncRecordStateFilterComposer,
          i2.$SyncRecordStateOrderingComposer,
          i2.$SyncRecordStateAnnotationComposer,
          $SyncRecordStateCreateCompanionBuilder,
          $SyncRecordStateUpdateCompanionBuilder,
          (
            i2.SyncRecordStateData,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i2.SyncRecordState,
              i2.SyncRecordStateData
            >,
          ),
          i2.SyncRecordStateData,
          i0.PrefetchHooks Function()
        > {
  $SyncRecordStateTableManager(
    i0.GeneratedDatabase db,
    i2.SyncRecordState table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i2.$SyncRecordStateFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i2.$SyncRecordStateOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i2.$SyncRecordStateAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> recordId = const i0.Value.absent(),
                i0.Value<String> kind = const i0.Value.absent(),
                i0.Value<String> digest = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.SyncRecordStateCompanion(
                recordId: recordId,
                kind: kind,
                digest: digest,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String recordId,
                required String kind,
                required String digest,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.SyncRecordStateCompanion.insert(
                recordId: recordId,
                kind: kind,
                digest: digest,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SyncRecordStateProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i2.SyncRecordState,
      i2.SyncRecordStateData,
      i2.$SyncRecordStateFilterComposer,
      i2.$SyncRecordStateOrderingComposer,
      i2.$SyncRecordStateAnnotationComposer,
      $SyncRecordStateCreateCompanionBuilder,
      $SyncRecordStateUpdateCompanionBuilder,
      (
        i2.SyncRecordStateData,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i2.SyncRecordState,
          i2.SyncRecordStateData
        >,
      ),
      i2.SyncRecordStateData,
      i0.PrefetchHooks Function()
    >;
typedef $DeletedRecordCreateCompanionBuilder =
    i2.DeletedRecordCompanion Function({
      required String id,
      required String kind,
      required DateTime deletedAt,
      i0.Value<int> rowid,
    });
typedef $DeletedRecordUpdateCompanionBuilder =
    i2.DeletedRecordCompanion Function({
      i0.Value<String> id,
      i0.Value<String> kind,
      i0.Value<DateTime> deletedAt,
      i0.Value<int> rowid,
    });

class $DeletedRecordFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.DeletedRecord> {
  $DeletedRecordFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $DeletedRecordOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.DeletedRecord> {
  $DeletedRecordOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $DeletedRecordAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.DeletedRecord> {
  $DeletedRecordAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  i0.GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $DeletedRecordTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i2.DeletedRecord,
          i2.DeletedRecordData,
          i2.$DeletedRecordFilterComposer,
          i2.$DeletedRecordOrderingComposer,
          i2.$DeletedRecordAnnotationComposer,
          $DeletedRecordCreateCompanionBuilder,
          $DeletedRecordUpdateCompanionBuilder,
          (
            i2.DeletedRecordData,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i2.DeletedRecord,
              i2.DeletedRecordData
            >,
          ),
          i2.DeletedRecordData,
          i0.PrefetchHooks Function()
        > {
  $DeletedRecordTableManager(i0.GeneratedDatabase db, i2.DeletedRecord table)
    : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i2.$DeletedRecordFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i2.$DeletedRecordOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i2.$DeletedRecordAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> id = const i0.Value.absent(),
                i0.Value<String> kind = const i0.Value.absent(),
                i0.Value<DateTime> deletedAt = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.DeletedRecordCompanion(
                id: id,
                kind: kind,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required DateTime deletedAt,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.DeletedRecordCompanion.insert(
                id: id,
                kind: kind,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $DeletedRecordProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i2.DeletedRecord,
      i2.DeletedRecordData,
      i2.$DeletedRecordFilterComposer,
      i2.$DeletedRecordOrderingComposer,
      i2.$DeletedRecordAnnotationComposer,
      $DeletedRecordCreateCompanionBuilder,
      $DeletedRecordUpdateCompanionBuilder,
      (
        i2.DeletedRecordData,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i2.DeletedRecord,
          i2.DeletedRecordData
        >,
      ),
      i2.DeletedRecordData,
      i0.PrefetchHooks Function()
    >;

class Container extends i0.Table
    with i0.TableInfo<Container, i1.ContainerData> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  Container(this.attachedDatabase, [this._alias]);
  late final i0.GeneratedColumn<String> id = i0.GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'PRIMARY KEY NOT NULL',
  );
  late final i0.GeneratedColumn<String> syncGuid = i0.GeneratedColumn<String>(
    'sync_guid',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'UNIQUE',
  );
  late final i0.GeneratedColumn<String> name = i0.GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const i0.CustomExpression('\'\''),
  );
  late final i0.GeneratedColumn<String> iconKey = i0.GeneratedColumn<String>(
    'icon_key',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'circle\'',
    defaultValue: const i0.CustomExpression('\'circle\''),
  );
  late final i0.GeneratedColumn<String> colorKey = i0.GeneratedColumn<String>(
    'color_key',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'blue\'',
    defaultValue: const i0.CustomExpression('\'blue\''),
  );
  late final i0.GeneratedColumn<String> orderKey = i0.GeneratedColumn<String>(
    'order_key',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final i0.GeneratedColumn<bool> isPinned = i0.GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: i0.DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const i0.CustomExpression('0'),
  );
  @override
  List<i0.GeneratedColumn> get $columns => [
    id,
    syncGuid,
    name,
    iconKey,
    colorKey,
    orderKey,
    isPinned,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'container';
  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i1.ContainerData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.ContainerData(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      syncGuid: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}sync_guid'],
      ),
      name: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      iconKey: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      )!,
      colorKey: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}color_key'],
      )!,
      orderKey: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}order_key'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
    );
  }

  @override
  Container createAlias(String alias) {
    return Container(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ContainerCompanion extends i0.UpdateCompanion<i1.ContainerData> {
  final i0.Value<String> id;
  final i0.Value<String?> syncGuid;
  final i0.Value<String> name;
  final i0.Value<String> iconKey;
  final i0.Value<String> colorKey;
  final i0.Value<String> orderKey;
  final i0.Value<bool> isPinned;
  final i0.Value<int> rowid;
  const ContainerCompanion({
    this.id = const i0.Value.absent(),
    this.syncGuid = const i0.Value.absent(),
    this.name = const i0.Value.absent(),
    this.iconKey = const i0.Value.absent(),
    this.colorKey = const i0.Value.absent(),
    this.orderKey = const i0.Value.absent(),
    this.isPinned = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  ContainerCompanion.insert({
    required String id,
    this.syncGuid = const i0.Value.absent(),
    this.name = const i0.Value.absent(),
    this.iconKey = const i0.Value.absent(),
    this.colorKey = const i0.Value.absent(),
    required String orderKey,
    this.isPinned = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  }) : id = i0.Value(id),
       orderKey = i0.Value(orderKey);
  static i0.Insertable<i1.ContainerData> custom({
    i0.Expression<String>? id,
    i0.Expression<String>? syncGuid,
    i0.Expression<String>? name,
    i0.Expression<String>? iconKey,
    i0.Expression<String>? colorKey,
    i0.Expression<String>? orderKey,
    i0.Expression<bool>? isPinned,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncGuid != null) 'sync_guid': syncGuid,
      if (name != null) 'name': name,
      if (iconKey != null) 'icon_key': iconKey,
      if (colorKey != null) 'color_key': colorKey,
      if (orderKey != null) 'order_key': orderKey,
      if (isPinned != null) 'is_pinned': isPinned,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i2.ContainerCompanion copyWith({
    i0.Value<String>? id,
    i0.Value<String?>? syncGuid,
    i0.Value<String>? name,
    i0.Value<String>? iconKey,
    i0.Value<String>? colorKey,
    i0.Value<String>? orderKey,
    i0.Value<bool>? isPinned,
    i0.Value<int>? rowid,
  }) {
    return i2.ContainerCompanion(
      id: id ?? this.id,
      syncGuid: syncGuid ?? this.syncGuid,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorKey: colorKey ?? this.colorKey,
      orderKey: orderKey ?? this.orderKey,
      isPinned: isPinned ?? this.isPinned,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<String>(id.value);
    }
    if (syncGuid.present) {
      map['sync_guid'] = i0.Variable<String>(syncGuid.value);
    }
    if (name.present) {
      map['name'] = i0.Variable<String>(name.value);
    }
    if (iconKey.present) {
      map['icon_key'] = i0.Variable<String>(iconKey.value);
    }
    if (colorKey.present) {
      map['color_key'] = i0.Variable<String>(colorKey.value);
    }
    if (orderKey.present) {
      map['order_key'] = i0.Variable<String>(orderKey.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = i0.Variable<bool>(isPinned.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContainerCompanion(')
          ..write('id: $id, ')
          ..write('syncGuid: $syncGuid, ')
          ..write('name: $name, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorKey: $colorKey, ')
          ..write('orderKey: $orderKey, ')
          ..write('isPinned: $isPinned, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ContainerLocal extends i0.Table
    with i0.TableInfo<ContainerLocal, i3.ContainerLocalData> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  ContainerLocal(this.attachedDatabase, [this._alias]);
  late final i0.GeneratedColumn<String> containerId =
      i0.GeneratedColumn<String>(
        'container_id',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints:
            'NOT NULL PRIMARY KEY REFERENCES container(id)ON DELETE CASCADE',
      );
  late final i0.GeneratedColumn<bool> excludeFromIndex =
      i0.GeneratedColumn<bool>(
        'exclude_from_index',
        aliasedName,
        false,
        type: i0.DriftSqlType.bool,
        requiredDuringInsert: false,
        $customConstraints: 'NOT NULL DEFAULT 0',
        defaultValue: const i0.CustomExpression('0'),
      );
  late final i0.GeneratedColumn<bool> excludeFromHistory =
      i0.GeneratedColumn<bool>(
        'exclude_from_history',
        aliasedName,
        false,
        type: i0.DriftSqlType.bool,
        requiredDuringInsert: false,
        $customConstraints: 'NOT NULL DEFAULT 0',
        defaultValue: const i0.CustomExpression('0'),
      );
  late final i0.GeneratedColumn<bool> clearDataOnExit =
      i0.GeneratedColumn<bool>(
        'clear_data_on_exit',
        aliasedName,
        false,
        type: i0.DriftSqlType.bool,
        requiredDuringInsert: false,
        $customConstraints: 'NOT NULL DEFAULT 0',
        defaultValue: const i0.CustomExpression('0'),
      );
  late final i0.GeneratedColumn<String> wallpaper = i0.GeneratedColumn<String>(
    'wallpaper',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<i0.GeneratedColumn> get $columns => [
    containerId,
    excludeFromIndex,
    excludeFromHistory,
    clearDataOnExit,
    wallpaper,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'container_local';
  @override
  Set<i0.GeneratedColumn> get $primaryKey => {containerId};
  @override
  i3.ContainerLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i3.ContainerLocalData(
      containerId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}container_id'],
      )!,
      excludeFromIndex: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.bool,
        data['${effectivePrefix}exclude_from_index'],
      )!,
      excludeFromHistory: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.bool,
        data['${effectivePrefix}exclude_from_history'],
      )!,
      clearDataOnExit: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.bool,
        data['${effectivePrefix}clear_data_on_exit'],
      )!,
      wallpaper: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}wallpaper'],
      ),
    );
  }

  @override
  ContainerLocal createAlias(String alias) {
    return ContainerLocal(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ContainerLocalCompanion
    extends i0.UpdateCompanion<i3.ContainerLocalData> {
  final i0.Value<String> containerId;
  final i0.Value<bool> excludeFromIndex;
  final i0.Value<bool> excludeFromHistory;
  final i0.Value<bool> clearDataOnExit;
  final i0.Value<String?> wallpaper;
  final i0.Value<int> rowid;
  const ContainerLocalCompanion({
    this.containerId = const i0.Value.absent(),
    this.excludeFromIndex = const i0.Value.absent(),
    this.excludeFromHistory = const i0.Value.absent(),
    this.clearDataOnExit = const i0.Value.absent(),
    this.wallpaper = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  ContainerLocalCompanion.insert({
    required String containerId,
    this.excludeFromIndex = const i0.Value.absent(),
    this.excludeFromHistory = const i0.Value.absent(),
    this.clearDataOnExit = const i0.Value.absent(),
    this.wallpaper = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  }) : containerId = i0.Value(containerId);
  static i0.Insertable<i3.ContainerLocalData> custom({
    i0.Expression<String>? containerId,
    i0.Expression<bool>? excludeFromIndex,
    i0.Expression<bool>? excludeFromHistory,
    i0.Expression<bool>? clearDataOnExit,
    i0.Expression<String>? wallpaper,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (containerId != null) 'container_id': containerId,
      if (excludeFromIndex != null) 'exclude_from_index': excludeFromIndex,
      if (excludeFromHistory != null)
        'exclude_from_history': excludeFromHistory,
      if (clearDataOnExit != null) 'clear_data_on_exit': clearDataOnExit,
      if (wallpaper != null) 'wallpaper': wallpaper,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i2.ContainerLocalCompanion copyWith({
    i0.Value<String>? containerId,
    i0.Value<bool>? excludeFromIndex,
    i0.Value<bool>? excludeFromHistory,
    i0.Value<bool>? clearDataOnExit,
    i0.Value<String?>? wallpaper,
    i0.Value<int>? rowid,
  }) {
    return i2.ContainerLocalCompanion(
      containerId: containerId ?? this.containerId,
      excludeFromIndex: excludeFromIndex ?? this.excludeFromIndex,
      excludeFromHistory: excludeFromHistory ?? this.excludeFromHistory,
      clearDataOnExit: clearDataOnExit ?? this.clearDataOnExit,
      wallpaper: wallpaper ?? this.wallpaper,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (containerId.present) {
      map['container_id'] = i0.Variable<String>(containerId.value);
    }
    if (excludeFromIndex.present) {
      map['exclude_from_index'] = i0.Variable<bool>(excludeFromIndex.value);
    }
    if (excludeFromHistory.present) {
      map['exclude_from_history'] = i0.Variable<bool>(excludeFromHistory.value);
    }
    if (clearDataOnExit.present) {
      map['clear_data_on_exit'] = i0.Variable<bool>(clearDataOnExit.value);
    }
    if (wallpaper.present) {
      map['wallpaper'] = i0.Variable<String>(wallpaper.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContainerLocalCompanion(')
          ..write('containerId: $containerId, ')
          ..write('excludeFromIndex: $excludeFromIndex, ')
          ..write('excludeFromHistory: $excludeFromHistory, ')
          ..write('clearDataOnExit: $clearDataOnExit, ')
          ..write('wallpaper: $wallpaper, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Space extends i0.Table with i0.TableInfo<Space, i4.SpaceData> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  Space(this.attachedDatabase, [this._alias]);
  late final i0.GeneratedColumn<String> uuid = i0.GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'PRIMARY KEY NOT NULL',
  );
  late final i0.GeneratedColumn<String> name = i0.GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const i0.CustomExpression('\'\''),
  );
  late final i0.GeneratedColumn<String> icon = i0.GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final i0.GeneratedColumn<String> theme = i0.GeneratedColumn<String>(
    'theme',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final i0.GeneratedColumn<String> containerId =
      i0.GeneratedColumn<String>(
        'container_id',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: 'REFERENCES container(id)ON DELETE SET NULL',
      );
  late final i0.GeneratedColumn<int> orderIndex = i0.GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<i0.GeneratedColumn> get $columns => [
    uuid,
    name,
    icon,
    theme,
    containerId,
    orderIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'space';
  @override
  Set<i0.GeneratedColumn> get $primaryKey => {uuid};
  @override
  i4.SpaceData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i4.SpaceData(
      uuid: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      name: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      theme: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}theme'],
      ),
      containerId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}container_id'],
      ),
      orderIndex: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
    );
  }

  @override
  Space createAlias(String alias) {
    return Space(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SpaceCompanion extends i0.UpdateCompanion<i4.SpaceData> {
  final i0.Value<String> uuid;
  final i0.Value<String> name;
  final i0.Value<String?> icon;
  final i0.Value<String?> theme;
  final i0.Value<String?> containerId;
  final i0.Value<int> orderIndex;
  final i0.Value<int> rowid;
  const SpaceCompanion({
    this.uuid = const i0.Value.absent(),
    this.name = const i0.Value.absent(),
    this.icon = const i0.Value.absent(),
    this.theme = const i0.Value.absent(),
    this.containerId = const i0.Value.absent(),
    this.orderIndex = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  SpaceCompanion.insert({
    required String uuid,
    this.name = const i0.Value.absent(),
    this.icon = const i0.Value.absent(),
    this.theme = const i0.Value.absent(),
    this.containerId = const i0.Value.absent(),
    required int orderIndex,
    this.rowid = const i0.Value.absent(),
  }) : uuid = i0.Value(uuid),
       orderIndex = i0.Value(orderIndex);
  static i0.Insertable<i4.SpaceData> custom({
    i0.Expression<String>? uuid,
    i0.Expression<String>? name,
    i0.Expression<String>? icon,
    i0.Expression<String>? theme,
    i0.Expression<String>? containerId,
    i0.Expression<int>? orderIndex,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (theme != null) 'theme': theme,
      if (containerId != null) 'container_id': containerId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i2.SpaceCompanion copyWith({
    i0.Value<String>? uuid,
    i0.Value<String>? name,
    i0.Value<String?>? icon,
    i0.Value<String?>? theme,
    i0.Value<String?>? containerId,
    i0.Value<int>? orderIndex,
    i0.Value<int>? rowid,
  }) {
    return i2.SpaceCompanion(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      theme: theme ?? this.theme,
      containerId: containerId ?? this.containerId,
      orderIndex: orderIndex ?? this.orderIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (uuid.present) {
      map['uuid'] = i0.Variable<String>(uuid.value);
    }
    if (name.present) {
      map['name'] = i0.Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = i0.Variable<String>(icon.value);
    }
    if (theme.present) {
      map['theme'] = i0.Variable<String>(theme.value);
    }
    if (containerId.present) {
      map['container_id'] = i0.Variable<String>(containerId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = i0.Variable<int>(orderIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SpaceCompanion(')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('theme: $theme, ')
          ..write('containerId: $containerId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class TabFolder extends i0.Table
    with i0.TableInfo<TabFolder, i5.TabFolderData> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  TabFolder(this.attachedDatabase, [this._alias]);
  late final i0.GeneratedColumn<String> id = i0.GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'PRIMARY KEY NOT NULL',
  );
  late final i0.GeneratedColumn<String> name = i0.GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const i0.CustomExpression('\'\''),
  );
  late final i0.GeneratedColumn<String> icon = i0.GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final i0.GeneratedColumn<String> spaceUuid = i0.GeneratedColumn<String>(
    'space_uuid',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES space(uuid)ON DELETE CASCADE',
  );
  late final i0.GeneratedColumn<String> parentFolderId =
      i0.GeneratedColumn<String>(
        'parent_folder_id',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: 'REFERENCES tab_folder(id)ON DELETE CASCADE',
      );
  late final i0.GeneratedColumn<String> live = i0.GeneratedColumn<String>(
    'live',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final i0.GeneratedColumn<bool> isCollapsed = i0.GeneratedColumn<bool>(
    'is_collapsed',
    aliasedName,
    false,
    type: i0.DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const i0.CustomExpression('0'),
  );
  late final i0.GeneratedColumn<String> orderKey = i0.GeneratedColumn<String>(
    'order_key',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<i0.GeneratedColumn> get $columns => [
    id,
    name,
    icon,
    spaceUuid,
    parentFolderId,
    live,
    isCollapsed,
    orderKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tab_folder';
  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i5.TabFolderData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i5.TabFolderData(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      spaceUuid: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}space_uuid'],
      ),
      parentFolderId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}parent_folder_id'],
      ),
      live: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}live'],
      ),
      isCollapsed: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.bool,
        data['${effectivePrefix}is_collapsed'],
      )!,
      orderKey: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}order_key'],
      )!,
    );
  }

  @override
  TabFolder createAlias(String alias) {
    return TabFolder(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class TabFolderCompanion extends i0.UpdateCompanion<i5.TabFolderData> {
  final i0.Value<String> id;
  final i0.Value<String> name;
  final i0.Value<String?> icon;
  final i0.Value<String?> spaceUuid;
  final i0.Value<String?> parentFolderId;
  final i0.Value<String?> live;
  final i0.Value<bool> isCollapsed;
  final i0.Value<String> orderKey;
  final i0.Value<int> rowid;
  const TabFolderCompanion({
    this.id = const i0.Value.absent(),
    this.name = const i0.Value.absent(),
    this.icon = const i0.Value.absent(),
    this.spaceUuid = const i0.Value.absent(),
    this.parentFolderId = const i0.Value.absent(),
    this.live = const i0.Value.absent(),
    this.isCollapsed = const i0.Value.absent(),
    this.orderKey = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  TabFolderCompanion.insert({
    required String id,
    this.name = const i0.Value.absent(),
    this.icon = const i0.Value.absent(),
    this.spaceUuid = const i0.Value.absent(),
    this.parentFolderId = const i0.Value.absent(),
    this.live = const i0.Value.absent(),
    this.isCollapsed = const i0.Value.absent(),
    required String orderKey,
    this.rowid = const i0.Value.absent(),
  }) : id = i0.Value(id),
       orderKey = i0.Value(orderKey);
  static i0.Insertable<i5.TabFolderData> custom({
    i0.Expression<String>? id,
    i0.Expression<String>? name,
    i0.Expression<String>? icon,
    i0.Expression<String>? spaceUuid,
    i0.Expression<String>? parentFolderId,
    i0.Expression<String>? live,
    i0.Expression<bool>? isCollapsed,
    i0.Expression<String>? orderKey,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (spaceUuid != null) 'space_uuid': spaceUuid,
      if (parentFolderId != null) 'parent_folder_id': parentFolderId,
      if (live != null) 'live': live,
      if (isCollapsed != null) 'is_collapsed': isCollapsed,
      if (orderKey != null) 'order_key': orderKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i2.TabFolderCompanion copyWith({
    i0.Value<String>? id,
    i0.Value<String>? name,
    i0.Value<String?>? icon,
    i0.Value<String?>? spaceUuid,
    i0.Value<String?>? parentFolderId,
    i0.Value<String?>? live,
    i0.Value<bool>? isCollapsed,
    i0.Value<String>? orderKey,
    i0.Value<int>? rowid,
  }) {
    return i2.TabFolderCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      spaceUuid: spaceUuid ?? this.spaceUuid,
      parentFolderId: parentFolderId ?? this.parentFolderId,
      live: live ?? this.live,
      isCollapsed: isCollapsed ?? this.isCollapsed,
      orderKey: orderKey ?? this.orderKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = i0.Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = i0.Variable<String>(icon.value);
    }
    if (spaceUuid.present) {
      map['space_uuid'] = i0.Variable<String>(spaceUuid.value);
    }
    if (parentFolderId.present) {
      map['parent_folder_id'] = i0.Variable<String>(parentFolderId.value);
    }
    if (live.present) {
      map['live'] = i0.Variable<String>(live.value);
    }
    if (isCollapsed.present) {
      map['is_collapsed'] = i0.Variable<bool>(isCollapsed.value);
    }
    if (orderKey.present) {
      map['order_key'] = i0.Variable<String>(orderKey.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TabFolderCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('spaceUuid: $spaceUuid, ')
          ..write('parentFolderId: $parentFolderId, ')
          ..write('live: $live, ')
          ..write('isCollapsed: $isCollapsed, ')
          ..write('orderKey: $orderKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class TabSplit extends i0.Table with i0.TableInfo<TabSplit, i6.TabSplitData> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  TabSplit(this.attachedDatabase, [this._alias]);
  late final i0.GeneratedColumn<String> id = i0.GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'PRIMARY KEY NOT NULL',
  );
  late final i0.GeneratedColumn<String> gridType = i0.GeneratedColumn<String>(
    'grid_type',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'grid\'',
    defaultValue: const i0.CustomExpression('\'grid\''),
  );
  late final i0.GeneratedColumn<bool> isPinned = i0.GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: i0.DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const i0.CustomExpression('0'),
  );
  late final i0.GeneratedColumn<String> spaceUuid = i0.GeneratedColumn<String>(
    'space_uuid',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES space(uuid)ON DELETE CASCADE',
  );
  late final i0.GeneratedColumn<String> folderId = i0.GeneratedColumn<String>(
    'folder_id',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES tab_folder(id)ON DELETE SET NULL',
  );
  late final i0.GeneratedColumn<String> orderKey = i0.GeneratedColumn<String>(
    'order_key',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<i0.GeneratedColumn> get $columns => [
    id,
    gridType,
    isPinned,
    spaceUuid,
    folderId,
    orderKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tab_split';
  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i6.TabSplitData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i6.TabSplitData(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      gridType: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}grid_type'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
      spaceUuid: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}space_uuid'],
      ),
      folderId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}folder_id'],
      ),
      orderKey: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}order_key'],
      )!,
    );
  }

  @override
  TabSplit createAlias(String alias) {
    return TabSplit(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class TabSplitCompanion extends i0.UpdateCompanion<i6.TabSplitData> {
  final i0.Value<String> id;
  final i0.Value<String> gridType;
  final i0.Value<bool> isPinned;
  final i0.Value<String?> spaceUuid;
  final i0.Value<String?> folderId;
  final i0.Value<String> orderKey;
  final i0.Value<int> rowid;
  const TabSplitCompanion({
    this.id = const i0.Value.absent(),
    this.gridType = const i0.Value.absent(),
    this.isPinned = const i0.Value.absent(),
    this.spaceUuid = const i0.Value.absent(),
    this.folderId = const i0.Value.absent(),
    this.orderKey = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  TabSplitCompanion.insert({
    required String id,
    this.gridType = const i0.Value.absent(),
    this.isPinned = const i0.Value.absent(),
    this.spaceUuid = const i0.Value.absent(),
    this.folderId = const i0.Value.absent(),
    required String orderKey,
    this.rowid = const i0.Value.absent(),
  }) : id = i0.Value(id),
       orderKey = i0.Value(orderKey);
  static i0.Insertable<i6.TabSplitData> custom({
    i0.Expression<String>? id,
    i0.Expression<String>? gridType,
    i0.Expression<bool>? isPinned,
    i0.Expression<String>? spaceUuid,
    i0.Expression<String>? folderId,
    i0.Expression<String>? orderKey,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (gridType != null) 'grid_type': gridType,
      if (isPinned != null) 'is_pinned': isPinned,
      if (spaceUuid != null) 'space_uuid': spaceUuid,
      if (folderId != null) 'folder_id': folderId,
      if (orderKey != null) 'order_key': orderKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i2.TabSplitCompanion copyWith({
    i0.Value<String>? id,
    i0.Value<String>? gridType,
    i0.Value<bool>? isPinned,
    i0.Value<String?>? spaceUuid,
    i0.Value<String?>? folderId,
    i0.Value<String>? orderKey,
    i0.Value<int>? rowid,
  }) {
    return i2.TabSplitCompanion(
      id: id ?? this.id,
      gridType: gridType ?? this.gridType,
      isPinned: isPinned ?? this.isPinned,
      spaceUuid: spaceUuid ?? this.spaceUuid,
      folderId: folderId ?? this.folderId,
      orderKey: orderKey ?? this.orderKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<String>(id.value);
    }
    if (gridType.present) {
      map['grid_type'] = i0.Variable<String>(gridType.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = i0.Variable<bool>(isPinned.value);
    }
    if (spaceUuid.present) {
      map['space_uuid'] = i0.Variable<String>(spaceUuid.value);
    }
    if (folderId.present) {
      map['folder_id'] = i0.Variable<String>(folderId.value);
    }
    if (orderKey.present) {
      map['order_key'] = i0.Variable<String>(orderKey.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TabSplitCompanion(')
          ..write('id: $id, ')
          ..write('gridType: $gridType, ')
          ..write('isPinned: $isPinned, ')
          ..write('spaceUuid: $spaceUuid, ')
          ..write('folderId: $folderId, ')
          ..write('orderKey: $orderKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Tab extends i0.Table with i0.TableInfo<Tab, i2.TabData> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  Tab(this.attachedDatabase, [this._alias]);
  late final i0.GeneratedColumn<String> id = i0.GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'PRIMARY KEY NOT NULL',
  );
  late final i0.GeneratedColumn<String> engineTabId =
      i0.GeneratedColumn<String>(
        'engine_tab_id',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: 'UNIQUE',
      );
  late final i0.GeneratedColumnWithTypeConverter<i7.TabSource, int> source =
      i0.GeneratedColumn<int>(
        'source',
        aliasedName,
        false,
        type: i0.DriftSqlType.int,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      ).withConverter<i7.TabSource>(i2.Tab.$convertersource);
  late final i0.GeneratedColumn<String> parentId = i0.GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES tab(id)ON DELETE SET NULL',
  );
  late final i0.GeneratedColumn<String> containerId =
      i0.GeneratedColumn<String>(
        'container_id',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: 'REFERENCES container(id)ON DELETE SET NULL',
      );
  late final i0.GeneratedColumn<String> spaceUuid = i0.GeneratedColumn<String>(
    'space_uuid',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES space(uuid)ON DELETE SET NULL',
  );
  late final i0.GeneratedColumn<String> folderId = i0.GeneratedColumn<String>(
    'folder_id',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES tab_folder(id)ON DELETE SET NULL',
  );
  late final i0.GeneratedColumn<String> splitId = i0.GeneratedColumn<String>(
    'split_id',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES tab_split(id)ON DELETE SET NULL',
  );
  late final i0.GeneratedColumn<int> splitIndex = i0.GeneratedColumn<int>(
    'split_index',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final i0.GeneratedColumnWithTypeConverter<i8.TabShelf, int> tabShelf =
      i0.GeneratedColumn<int>(
        'tab_shelf',
        aliasedName,
        false,
        type: i0.DriftSqlType.int,
        requiredDuringInsert: false,
        $customConstraints: 'NOT NULL DEFAULT 0',
        defaultValue: const i0.CustomExpression('0'),
      ).withConverter<i8.TabShelf>(i2.Tab.$convertertabShelf);
  late final i0.GeneratedColumn<String> orderKey = i0.GeneratedColumn<String>(
    'order_key',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final i0.GeneratedColumnWithTypeConverter<Uri?, String> url =
      i0.GeneratedColumn<String>(
        'url',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: '',
      ).withConverter<Uri?>(i2.Tab.$converterurl);
  late final i0.GeneratedColumn<String> title = i0.GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final i0.GeneratedColumn<String> iconUrl = i0.GeneratedColumn<String>(
    'icon_url',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final i0.GeneratedColumn<String> staticLabel =
      i0.GeneratedColumn<String>(
        'static_label',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  late final i0.GeneratedColumn<bool> hasStaticIcon = i0.GeneratedColumn<bool>(
    'has_static_icon',
    aliasedName,
    false,
    type: i0.DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const i0.CustomExpression('0'),
  );
  late final i0.GeneratedColumn<bool> defaultContainer =
      i0.GeneratedColumn<bool>(
        'default_container',
        aliasedName,
        false,
        type: i0.DriftSqlType.bool,
        requiredDuringInsert: false,
        $customConstraints: 'NOT NULL DEFAULT 0',
        defaultValue: const i0.CustomExpression('0'),
      );
  late final i0.GeneratedColumnWithTypeConverter<i9.TabModeDbValue, int>
  tabMode = i0.GeneratedColumn<int>(
    'tab_mode',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const i0.CustomExpression('0'),
  ).withConverter<i9.TabModeDbValue>(i2.Tab.$convertertabMode);
  late final i0.GeneratedColumn<bool> isProbablyReaderable =
      i0.GeneratedColumn<bool>(
        'is_probably_readerable',
        aliasedName,
        true,
        type: i0.DriftSqlType.bool,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  late final i0.GeneratedColumn<String> extractedContentMarkdown =
      i0.GeneratedColumn<String>(
        'extracted_content_markdown',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  late final i0.GeneratedColumn<String> extractedContentPlain =
      i0.GeneratedColumn<String>(
        'extracted_content_plain',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  late final i0.GeneratedColumn<String> fullContentMarkdown =
      i0.GeneratedColumn<String>(
        'full_content_markdown',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  late final i0.GeneratedColumn<String> fullContentPlain =
      i0.GeneratedColumn<String>(
        'full_content_plain',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  late final i0.GeneratedColumn<DateTime> timestamp =
      i0.GeneratedColumn<DateTime>(
        'timestamp',
        aliasedName,
        false,
        type: i0.DriftSqlType.dateTime,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  late final i0.GeneratedColumn<int> contentHash = i0.GeneratedColumn<int>(
    'content_hash',
    aliasedName,
    true,
    generatedAs: i0.GeneratedAs(
      const i0.CustomExpression(
        'generate_content_hash(title, extracted_content_plain, full_content_plain)',
      ),
      false,
    ),
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'GENERATED ALWAYS AS (generate_content_hash(title, extracted_content_plain, full_content_plain)) VIRTUAL',
  );
  @override
  List<i0.GeneratedColumn> get $columns => [
    id,
    engineTabId,
    source,
    parentId,
    containerId,
    spaceUuid,
    folderId,
    splitId,
    splitIndex,
    tabShelf,
    orderKey,
    url,
    title,
    iconUrl,
    staticLabel,
    hasStaticIcon,
    defaultContainer,
    tabMode,
    isProbablyReaderable,
    extractedContentMarkdown,
    extractedContentPlain,
    fullContentMarkdown,
    fullContentPlain,
    timestamp,
    contentHash,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tab';
  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i2.TabData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i2.TabData(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      engineTabId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}engine_tab_id'],
      ),
      source: i2.Tab.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          i0.DriftSqlType.int,
          data['${effectivePrefix}source'],
        )!,
      ),
      parentId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      containerId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}container_id'],
      ),
      spaceUuid: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}space_uuid'],
      ),
      folderId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}folder_id'],
      ),
      splitId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}split_id'],
      ),
      splitIndex: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}split_index'],
      ),
      tabShelf: i2.Tab.$convertertabShelf.fromSql(
        attachedDatabase.typeMapping.read(
          i0.DriftSqlType.int,
          data['${effectivePrefix}tab_shelf'],
        )!,
      ),
      orderKey: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}order_key'],
      )!,
      url: i2.Tab.$converterurl.fromSql(
        attachedDatabase.typeMapping.read(
          i0.DriftSqlType.string,
          data['${effectivePrefix}url'],
        ),
      ),
      title: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      iconUrl: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}icon_url'],
      ),
      staticLabel: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}static_label'],
      ),
      hasStaticIcon: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.bool,
        data['${effectivePrefix}has_static_icon'],
      )!,
      defaultContainer: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.bool,
        data['${effectivePrefix}default_container'],
      )!,
      tabMode: i2.Tab.$convertertabMode.fromSql(
        attachedDatabase.typeMapping.read(
          i0.DriftSqlType.int,
          data['${effectivePrefix}tab_mode'],
        )!,
      ),
      isProbablyReaderable: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.bool,
        data['${effectivePrefix}is_probably_readerable'],
      ),
      extractedContentMarkdown: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}extracted_content_markdown'],
      ),
      extractedContentPlain: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}extracted_content_plain'],
      ),
      fullContentMarkdown: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}full_content_markdown'],
      ),
      fullContentPlain: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}full_content_plain'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      contentHash: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}content_hash'],
      ),
    );
  }

  @override
  Tab createAlias(String alias) {
    return Tab(attachedDatabase, alias);
  }

  static i0.JsonTypeConverter2<i7.TabSource, int, int> $convertersource =
      const i0.EnumIndexConverter<i7.TabSource>(i7.TabSource.values);
  static i0.JsonTypeConverter2<i8.TabShelf, int, int> $convertertabShelf =
      const i0.EnumIndexConverter<i8.TabShelf>(i8.TabShelf.values);
  static i0.TypeConverter<Uri?, String?> $converterurl =
      const i10.UriConverterNullable();
  static i0.JsonTypeConverter2<i9.TabModeDbValue, int, int> $convertertabMode =
      const i0.EnumIndexConverter<i9.TabModeDbValue>(i9.TabModeDbValue.values);
  @override
  bool get dontWriteConstraints => true;
}

class TabData extends i0.DataClass implements i0.Insertable<i2.TabData> {
  final String id;

  /// NULL = cold tab: no live engine session (PLAN §7.4). Set when the engine
  /// creates a session for this tab, cleared again on demotion. Never reused
  /// across tabs while live, hence UNIQUE.
  final String? engineTabId;
  final i7.TabSource source;
  final String? parentId;

  /// ON DELETE SET NULL, not CASCADE: a cascade here would delete tabs behind
  /// the engine's back. Repositories close tabs before deleting a container.
  final String? containerId;

  /// ON DELETE SET NULL for the same reason as container_id above (PLAN §7.3):
  /// repositories close tabs before deleting a space or folder.
  final String? spaceUuid;
  final String? folderId;
  final String? splitId;
  final int? splitIndex;

  /// normal=0, pinned=1, essential=2 (TabShelf). Folded former `is_pinned`
  /// into this column; essential tabs are always pinned in Zen's model.
  final i8.TabShelf tabShelf;
  final String orderKey;
  final Uri? url;
  final String? title;
  final String? iconUrl;
  final String? staticLabel;
  final bool hasStaticIcon;
  final bool defaultContainer;
  final i9.TabModeDbValue tabMode;
  final bool? isProbablyReaderable;
  final String? extractedContentMarkdown;
  final String? extractedContentPlain;
  final String? fullContentMarkdown;
  final String? fullContentPlain;
  final DateTime timestamp;

  /// xxh3-64 over (title, extracted_content_plain, full_content_plain).
  /// Used by the FTS update trigger and the tab→history fan-out trigger to
  /// short-circuit when the row's UPDATE didn't actually change content.
  /// VIRTUAL (computed on read) to avoid recreating the table on migration;
  /// recomputation cost is negligible vs. the FTS rewrite it skips.
  final int? contentHash;
  const TabData({
    required this.id,
    this.engineTabId,
    required this.source,
    this.parentId,
    this.containerId,
    this.spaceUuid,
    this.folderId,
    this.splitId,
    this.splitIndex,
    required this.tabShelf,
    required this.orderKey,
    this.url,
    this.title,
    this.iconUrl,
    this.staticLabel,
    required this.hasStaticIcon,
    required this.defaultContainer,
    required this.tabMode,
    this.isProbablyReaderable,
    this.extractedContentMarkdown,
    this.extractedContentPlain,
    this.fullContentMarkdown,
    this.fullContentPlain,
    required this.timestamp,
    this.contentHash,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<String>(id);
    if (!nullToAbsent || engineTabId != null) {
      map['engine_tab_id'] = i0.Variable<String>(engineTabId);
    }
    {
      map['source'] = i0.Variable<int>(i2.Tab.$convertersource.toSql(source));
    }
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = i0.Variable<String>(parentId);
    }
    if (!nullToAbsent || containerId != null) {
      map['container_id'] = i0.Variable<String>(containerId);
    }
    if (!nullToAbsent || spaceUuid != null) {
      map['space_uuid'] = i0.Variable<String>(spaceUuid);
    }
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = i0.Variable<String>(folderId);
    }
    if (!nullToAbsent || splitId != null) {
      map['split_id'] = i0.Variable<String>(splitId);
    }
    if (!nullToAbsent || splitIndex != null) {
      map['split_index'] = i0.Variable<int>(splitIndex);
    }
    {
      map['tab_shelf'] = i0.Variable<int>(
        i2.Tab.$convertertabShelf.toSql(tabShelf),
      );
    }
    map['order_key'] = i0.Variable<String>(orderKey);
    if (!nullToAbsent || url != null) {
      map['url'] = i0.Variable<String>(i2.Tab.$converterurl.toSql(url));
    }
    if (!nullToAbsent || title != null) {
      map['title'] = i0.Variable<String>(title);
    }
    if (!nullToAbsent || iconUrl != null) {
      map['icon_url'] = i0.Variable<String>(iconUrl);
    }
    if (!nullToAbsent || staticLabel != null) {
      map['static_label'] = i0.Variable<String>(staticLabel);
    }
    map['has_static_icon'] = i0.Variable<bool>(hasStaticIcon);
    map['default_container'] = i0.Variable<bool>(defaultContainer);
    {
      map['tab_mode'] = i0.Variable<int>(
        i2.Tab.$convertertabMode.toSql(tabMode),
      );
    }
    if (!nullToAbsent || isProbablyReaderable != null) {
      map['is_probably_readerable'] = i0.Variable<bool>(isProbablyReaderable);
    }
    if (!nullToAbsent || extractedContentMarkdown != null) {
      map['extracted_content_markdown'] = i0.Variable<String>(
        extractedContentMarkdown,
      );
    }
    if (!nullToAbsent || extractedContentPlain != null) {
      map['extracted_content_plain'] = i0.Variable<String>(
        extractedContentPlain,
      );
    }
    if (!nullToAbsent || fullContentMarkdown != null) {
      map['full_content_markdown'] = i0.Variable<String>(fullContentMarkdown);
    }
    if (!nullToAbsent || fullContentPlain != null) {
      map['full_content_plain'] = i0.Variable<String>(fullContentPlain);
    }
    map['timestamp'] = i0.Variable<DateTime>(timestamp);
    return map;
  }

  factory TabData.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return TabData(
      id: serializer.fromJson<String>(json['id']),
      engineTabId: serializer.fromJson<String?>(json['engine_tab_id']),
      source: i2.Tab.$convertersource.fromJson(
        serializer.fromJson<int>(json['source']),
      ),
      parentId: serializer.fromJson<String?>(json['parent_id']),
      containerId: serializer.fromJson<String?>(json['container_id']),
      spaceUuid: serializer.fromJson<String?>(json['space_uuid']),
      folderId: serializer.fromJson<String?>(json['folder_id']),
      splitId: serializer.fromJson<String?>(json['split_id']),
      splitIndex: serializer.fromJson<int?>(json['split_index']),
      tabShelf: i2.Tab.$convertertabShelf.fromJson(
        serializer.fromJson<int>(json['tab_shelf']),
      ),
      orderKey: serializer.fromJson<String>(json['order_key']),
      url: serializer.fromJson<Uri?>(json['url']),
      title: serializer.fromJson<String?>(json['title']),
      iconUrl: serializer.fromJson<String?>(json['icon_url']),
      staticLabel: serializer.fromJson<String?>(json['static_label']),
      hasStaticIcon: serializer.fromJson<bool>(json['has_static_icon']),
      defaultContainer: serializer.fromJson<bool>(json['default_container']),
      tabMode: i2.Tab.$convertertabMode.fromJson(
        serializer.fromJson<int>(json['tab_mode']),
      ),
      isProbablyReaderable: serializer.fromJson<bool?>(
        json['is_probably_readerable'],
      ),
      extractedContentMarkdown: serializer.fromJson<String?>(
        json['extracted_content_markdown'],
      ),
      extractedContentPlain: serializer.fromJson<String?>(
        json['extracted_content_plain'],
      ),
      fullContentMarkdown: serializer.fromJson<String?>(
        json['full_content_markdown'],
      ),
      fullContentPlain: serializer.fromJson<String?>(
        json['full_content_plain'],
      ),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      contentHash: serializer.fromJson<int?>(json['content_hash']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'engine_tab_id': serializer.toJson<String?>(engineTabId),
      'source': serializer.toJson<int>(i2.Tab.$convertersource.toJson(source)),
      'parent_id': serializer.toJson<String?>(parentId),
      'container_id': serializer.toJson<String?>(containerId),
      'space_uuid': serializer.toJson<String?>(spaceUuid),
      'folder_id': serializer.toJson<String?>(folderId),
      'split_id': serializer.toJson<String?>(splitId),
      'split_index': serializer.toJson<int?>(splitIndex),
      'tab_shelf': serializer.toJson<int>(
        i2.Tab.$convertertabShelf.toJson(tabShelf),
      ),
      'order_key': serializer.toJson<String>(orderKey),
      'url': serializer.toJson<Uri?>(url),
      'title': serializer.toJson<String?>(title),
      'icon_url': serializer.toJson<String?>(iconUrl),
      'static_label': serializer.toJson<String?>(staticLabel),
      'has_static_icon': serializer.toJson<bool>(hasStaticIcon),
      'default_container': serializer.toJson<bool>(defaultContainer),
      'tab_mode': serializer.toJson<int>(
        i2.Tab.$convertertabMode.toJson(tabMode),
      ),
      'is_probably_readerable': serializer.toJson<bool?>(isProbablyReaderable),
      'extracted_content_markdown': serializer.toJson<String?>(
        extractedContentMarkdown,
      ),
      'extracted_content_plain': serializer.toJson<String?>(
        extractedContentPlain,
      ),
      'full_content_markdown': serializer.toJson<String?>(fullContentMarkdown),
      'full_content_plain': serializer.toJson<String?>(fullContentPlain),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'content_hash': serializer.toJson<int?>(contentHash),
    };
  }

  i2.TabData copyWith({
    String? id,
    i0.Value<String?> engineTabId = const i0.Value.absent(),
    i7.TabSource? source,
    i0.Value<String?> parentId = const i0.Value.absent(),
    i0.Value<String?> containerId = const i0.Value.absent(),
    i0.Value<String?> spaceUuid = const i0.Value.absent(),
    i0.Value<String?> folderId = const i0.Value.absent(),
    i0.Value<String?> splitId = const i0.Value.absent(),
    i0.Value<int?> splitIndex = const i0.Value.absent(),
    i8.TabShelf? tabShelf,
    String? orderKey,
    i0.Value<Uri?> url = const i0.Value.absent(),
    i0.Value<String?> title = const i0.Value.absent(),
    i0.Value<String?> iconUrl = const i0.Value.absent(),
    i0.Value<String?> staticLabel = const i0.Value.absent(),
    bool? hasStaticIcon,
    bool? defaultContainer,
    i9.TabModeDbValue? tabMode,
    i0.Value<bool?> isProbablyReaderable = const i0.Value.absent(),
    i0.Value<String?> extractedContentMarkdown = const i0.Value.absent(),
    i0.Value<String?> extractedContentPlain = const i0.Value.absent(),
    i0.Value<String?> fullContentMarkdown = const i0.Value.absent(),
    i0.Value<String?> fullContentPlain = const i0.Value.absent(),
    DateTime? timestamp,
    i0.Value<int?> contentHash = const i0.Value.absent(),
  }) => i2.TabData(
    id: id ?? this.id,
    engineTabId: engineTabId.present ? engineTabId.value : this.engineTabId,
    source: source ?? this.source,
    parentId: parentId.present ? parentId.value : this.parentId,
    containerId: containerId.present ? containerId.value : this.containerId,
    spaceUuid: spaceUuid.present ? spaceUuid.value : this.spaceUuid,
    folderId: folderId.present ? folderId.value : this.folderId,
    splitId: splitId.present ? splitId.value : this.splitId,
    splitIndex: splitIndex.present ? splitIndex.value : this.splitIndex,
    tabShelf: tabShelf ?? this.tabShelf,
    orderKey: orderKey ?? this.orderKey,
    url: url.present ? url.value : this.url,
    title: title.present ? title.value : this.title,
    iconUrl: iconUrl.present ? iconUrl.value : this.iconUrl,
    staticLabel: staticLabel.present ? staticLabel.value : this.staticLabel,
    hasStaticIcon: hasStaticIcon ?? this.hasStaticIcon,
    defaultContainer: defaultContainer ?? this.defaultContainer,
    tabMode: tabMode ?? this.tabMode,
    isProbablyReaderable: isProbablyReaderable.present
        ? isProbablyReaderable.value
        : this.isProbablyReaderable,
    extractedContentMarkdown: extractedContentMarkdown.present
        ? extractedContentMarkdown.value
        : this.extractedContentMarkdown,
    extractedContentPlain: extractedContentPlain.present
        ? extractedContentPlain.value
        : this.extractedContentPlain,
    fullContentMarkdown: fullContentMarkdown.present
        ? fullContentMarkdown.value
        : this.fullContentMarkdown,
    fullContentPlain: fullContentPlain.present
        ? fullContentPlain.value
        : this.fullContentPlain,
    timestamp: timestamp ?? this.timestamp,
    contentHash: contentHash.present ? contentHash.value : this.contentHash,
  );
  @override
  String toString() {
    return (StringBuffer('TabData(')
          ..write('id: $id, ')
          ..write('engineTabId: $engineTabId, ')
          ..write('source: $source, ')
          ..write('parentId: $parentId, ')
          ..write('containerId: $containerId, ')
          ..write('spaceUuid: $spaceUuid, ')
          ..write('folderId: $folderId, ')
          ..write('splitId: $splitId, ')
          ..write('splitIndex: $splitIndex, ')
          ..write('tabShelf: $tabShelf, ')
          ..write('orderKey: $orderKey, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('staticLabel: $staticLabel, ')
          ..write('hasStaticIcon: $hasStaticIcon, ')
          ..write('defaultContainer: $defaultContainer, ')
          ..write('tabMode: $tabMode, ')
          ..write('isProbablyReaderable: $isProbablyReaderable, ')
          ..write('extractedContentMarkdown: $extractedContentMarkdown, ')
          ..write('extractedContentPlain: $extractedContentPlain, ')
          ..write('fullContentMarkdown: $fullContentMarkdown, ')
          ..write('fullContentPlain: $fullContentPlain, ')
          ..write('timestamp: $timestamp, ')
          ..write('contentHash: $contentHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    engineTabId,
    source,
    parentId,
    containerId,
    spaceUuid,
    folderId,
    splitId,
    splitIndex,
    tabShelf,
    orderKey,
    url,
    title,
    iconUrl,
    staticLabel,
    hasStaticIcon,
    defaultContainer,
    tabMode,
    isProbablyReaderable,
    extractedContentMarkdown,
    extractedContentPlain,
    fullContentMarkdown,
    fullContentPlain,
    timestamp,
    contentHash,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i2.TabData &&
          other.id == this.id &&
          other.engineTabId == this.engineTabId &&
          other.source == this.source &&
          other.parentId == this.parentId &&
          other.containerId == this.containerId &&
          other.spaceUuid == this.spaceUuid &&
          other.folderId == this.folderId &&
          other.splitId == this.splitId &&
          other.splitIndex == this.splitIndex &&
          other.tabShelf == this.tabShelf &&
          other.orderKey == this.orderKey &&
          other.url == this.url &&
          other.title == this.title &&
          other.iconUrl == this.iconUrl &&
          other.staticLabel == this.staticLabel &&
          other.hasStaticIcon == this.hasStaticIcon &&
          other.defaultContainer == this.defaultContainer &&
          other.tabMode == this.tabMode &&
          other.isProbablyReaderable == this.isProbablyReaderable &&
          other.extractedContentMarkdown == this.extractedContentMarkdown &&
          other.extractedContentPlain == this.extractedContentPlain &&
          other.fullContentMarkdown == this.fullContentMarkdown &&
          other.fullContentPlain == this.fullContentPlain &&
          other.timestamp == this.timestamp &&
          other.contentHash == this.contentHash);
}

class TabCompanion extends i0.UpdateCompanion<i2.TabData> {
  final i0.Value<String> id;
  final i0.Value<String?> engineTabId;
  final i0.Value<i7.TabSource> source;
  final i0.Value<String?> parentId;
  final i0.Value<String?> containerId;
  final i0.Value<String?> spaceUuid;
  final i0.Value<String?> folderId;
  final i0.Value<String?> splitId;
  final i0.Value<int?> splitIndex;
  final i0.Value<i8.TabShelf> tabShelf;
  final i0.Value<String> orderKey;
  final i0.Value<Uri?> url;
  final i0.Value<String?> title;
  final i0.Value<String?> iconUrl;
  final i0.Value<String?> staticLabel;
  final i0.Value<bool> hasStaticIcon;
  final i0.Value<bool> defaultContainer;
  final i0.Value<i9.TabModeDbValue> tabMode;
  final i0.Value<bool?> isProbablyReaderable;
  final i0.Value<String?> extractedContentMarkdown;
  final i0.Value<String?> extractedContentPlain;
  final i0.Value<String?> fullContentMarkdown;
  final i0.Value<String?> fullContentPlain;
  final i0.Value<DateTime> timestamp;
  final i0.Value<int> rowid;
  const TabCompanion({
    this.id = const i0.Value.absent(),
    this.engineTabId = const i0.Value.absent(),
    this.source = const i0.Value.absent(),
    this.parentId = const i0.Value.absent(),
    this.containerId = const i0.Value.absent(),
    this.spaceUuid = const i0.Value.absent(),
    this.folderId = const i0.Value.absent(),
    this.splitId = const i0.Value.absent(),
    this.splitIndex = const i0.Value.absent(),
    this.tabShelf = const i0.Value.absent(),
    this.orderKey = const i0.Value.absent(),
    this.url = const i0.Value.absent(),
    this.title = const i0.Value.absent(),
    this.iconUrl = const i0.Value.absent(),
    this.staticLabel = const i0.Value.absent(),
    this.hasStaticIcon = const i0.Value.absent(),
    this.defaultContainer = const i0.Value.absent(),
    this.tabMode = const i0.Value.absent(),
    this.isProbablyReaderable = const i0.Value.absent(),
    this.extractedContentMarkdown = const i0.Value.absent(),
    this.extractedContentPlain = const i0.Value.absent(),
    this.fullContentMarkdown = const i0.Value.absent(),
    this.fullContentPlain = const i0.Value.absent(),
    this.timestamp = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  TabCompanion.insert({
    required String id,
    this.engineTabId = const i0.Value.absent(),
    required i7.TabSource source,
    this.parentId = const i0.Value.absent(),
    this.containerId = const i0.Value.absent(),
    this.spaceUuid = const i0.Value.absent(),
    this.folderId = const i0.Value.absent(),
    this.splitId = const i0.Value.absent(),
    this.splitIndex = const i0.Value.absent(),
    this.tabShelf = const i0.Value.absent(),
    required String orderKey,
    this.url = const i0.Value.absent(),
    this.title = const i0.Value.absent(),
    this.iconUrl = const i0.Value.absent(),
    this.staticLabel = const i0.Value.absent(),
    this.hasStaticIcon = const i0.Value.absent(),
    this.defaultContainer = const i0.Value.absent(),
    this.tabMode = const i0.Value.absent(),
    this.isProbablyReaderable = const i0.Value.absent(),
    this.extractedContentMarkdown = const i0.Value.absent(),
    this.extractedContentPlain = const i0.Value.absent(),
    this.fullContentMarkdown = const i0.Value.absent(),
    this.fullContentPlain = const i0.Value.absent(),
    required DateTime timestamp,
    this.rowid = const i0.Value.absent(),
  }) : id = i0.Value(id),
       source = i0.Value(source),
       orderKey = i0.Value(orderKey),
       timestamp = i0.Value(timestamp);
  static i0.Insertable<i2.TabData> custom({
    i0.Expression<String>? id,
    i0.Expression<String>? engineTabId,
    i0.Expression<int>? source,
    i0.Expression<String>? parentId,
    i0.Expression<String>? containerId,
    i0.Expression<String>? spaceUuid,
    i0.Expression<String>? folderId,
    i0.Expression<String>? splitId,
    i0.Expression<int>? splitIndex,
    i0.Expression<int>? tabShelf,
    i0.Expression<String>? orderKey,
    i0.Expression<String>? url,
    i0.Expression<String>? title,
    i0.Expression<String>? iconUrl,
    i0.Expression<String>? staticLabel,
    i0.Expression<bool>? hasStaticIcon,
    i0.Expression<bool>? defaultContainer,
    i0.Expression<int>? tabMode,
    i0.Expression<bool>? isProbablyReaderable,
    i0.Expression<String>? extractedContentMarkdown,
    i0.Expression<String>? extractedContentPlain,
    i0.Expression<String>? fullContentMarkdown,
    i0.Expression<String>? fullContentPlain,
    i0.Expression<DateTime>? timestamp,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (engineTabId != null) 'engine_tab_id': engineTabId,
      if (source != null) 'source': source,
      if (parentId != null) 'parent_id': parentId,
      if (containerId != null) 'container_id': containerId,
      if (spaceUuid != null) 'space_uuid': spaceUuid,
      if (folderId != null) 'folder_id': folderId,
      if (splitId != null) 'split_id': splitId,
      if (splitIndex != null) 'split_index': splitIndex,
      if (tabShelf != null) 'tab_shelf': tabShelf,
      if (orderKey != null) 'order_key': orderKey,
      if (url != null) 'url': url,
      if (title != null) 'title': title,
      if (iconUrl != null) 'icon_url': iconUrl,
      if (staticLabel != null) 'static_label': staticLabel,
      if (hasStaticIcon != null) 'has_static_icon': hasStaticIcon,
      if (defaultContainer != null) 'default_container': defaultContainer,
      if (tabMode != null) 'tab_mode': tabMode,
      if (isProbablyReaderable != null)
        'is_probably_readerable': isProbablyReaderable,
      if (extractedContentMarkdown != null)
        'extracted_content_markdown': extractedContentMarkdown,
      if (extractedContentPlain != null)
        'extracted_content_plain': extractedContentPlain,
      if (fullContentMarkdown != null)
        'full_content_markdown': fullContentMarkdown,
      if (fullContentPlain != null) 'full_content_plain': fullContentPlain,
      if (timestamp != null) 'timestamp': timestamp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i2.TabCompanion copyWith({
    i0.Value<String>? id,
    i0.Value<String?>? engineTabId,
    i0.Value<i7.TabSource>? source,
    i0.Value<String?>? parentId,
    i0.Value<String?>? containerId,
    i0.Value<String?>? spaceUuid,
    i0.Value<String?>? folderId,
    i0.Value<String?>? splitId,
    i0.Value<int?>? splitIndex,
    i0.Value<i8.TabShelf>? tabShelf,
    i0.Value<String>? orderKey,
    i0.Value<Uri?>? url,
    i0.Value<String?>? title,
    i0.Value<String?>? iconUrl,
    i0.Value<String?>? staticLabel,
    i0.Value<bool>? hasStaticIcon,
    i0.Value<bool>? defaultContainer,
    i0.Value<i9.TabModeDbValue>? tabMode,
    i0.Value<bool?>? isProbablyReaderable,
    i0.Value<String?>? extractedContentMarkdown,
    i0.Value<String?>? extractedContentPlain,
    i0.Value<String?>? fullContentMarkdown,
    i0.Value<String?>? fullContentPlain,
    i0.Value<DateTime>? timestamp,
    i0.Value<int>? rowid,
  }) {
    return i2.TabCompanion(
      id: id ?? this.id,
      engineTabId: engineTabId ?? this.engineTabId,
      source: source ?? this.source,
      parentId: parentId ?? this.parentId,
      containerId: containerId ?? this.containerId,
      spaceUuid: spaceUuid ?? this.spaceUuid,
      folderId: folderId ?? this.folderId,
      splitId: splitId ?? this.splitId,
      splitIndex: splitIndex ?? this.splitIndex,
      tabShelf: tabShelf ?? this.tabShelf,
      orderKey: orderKey ?? this.orderKey,
      url: url ?? this.url,
      title: title ?? this.title,
      iconUrl: iconUrl ?? this.iconUrl,
      staticLabel: staticLabel ?? this.staticLabel,
      hasStaticIcon: hasStaticIcon ?? this.hasStaticIcon,
      defaultContainer: defaultContainer ?? this.defaultContainer,
      tabMode: tabMode ?? this.tabMode,
      isProbablyReaderable: isProbablyReaderable ?? this.isProbablyReaderable,
      extractedContentMarkdown:
          extractedContentMarkdown ?? this.extractedContentMarkdown,
      extractedContentPlain:
          extractedContentPlain ?? this.extractedContentPlain,
      fullContentMarkdown: fullContentMarkdown ?? this.fullContentMarkdown,
      fullContentPlain: fullContentPlain ?? this.fullContentPlain,
      timestamp: timestamp ?? this.timestamp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<String>(id.value);
    }
    if (engineTabId.present) {
      map['engine_tab_id'] = i0.Variable<String>(engineTabId.value);
    }
    if (source.present) {
      map['source'] = i0.Variable<int>(
        i2.Tab.$convertersource.toSql(source.value),
      );
    }
    if (parentId.present) {
      map['parent_id'] = i0.Variable<String>(parentId.value);
    }
    if (containerId.present) {
      map['container_id'] = i0.Variable<String>(containerId.value);
    }
    if (spaceUuid.present) {
      map['space_uuid'] = i0.Variable<String>(spaceUuid.value);
    }
    if (folderId.present) {
      map['folder_id'] = i0.Variable<String>(folderId.value);
    }
    if (splitId.present) {
      map['split_id'] = i0.Variable<String>(splitId.value);
    }
    if (splitIndex.present) {
      map['split_index'] = i0.Variable<int>(splitIndex.value);
    }
    if (tabShelf.present) {
      map['tab_shelf'] = i0.Variable<int>(
        i2.Tab.$convertertabShelf.toSql(tabShelf.value),
      );
    }
    if (orderKey.present) {
      map['order_key'] = i0.Variable<String>(orderKey.value);
    }
    if (url.present) {
      map['url'] = i0.Variable<String>(i2.Tab.$converterurl.toSql(url.value));
    }
    if (title.present) {
      map['title'] = i0.Variable<String>(title.value);
    }
    if (iconUrl.present) {
      map['icon_url'] = i0.Variable<String>(iconUrl.value);
    }
    if (staticLabel.present) {
      map['static_label'] = i0.Variable<String>(staticLabel.value);
    }
    if (hasStaticIcon.present) {
      map['has_static_icon'] = i0.Variable<bool>(hasStaticIcon.value);
    }
    if (defaultContainer.present) {
      map['default_container'] = i0.Variable<bool>(defaultContainer.value);
    }
    if (tabMode.present) {
      map['tab_mode'] = i0.Variable<int>(
        i2.Tab.$convertertabMode.toSql(tabMode.value),
      );
    }
    if (isProbablyReaderable.present) {
      map['is_probably_readerable'] = i0.Variable<bool>(
        isProbablyReaderable.value,
      );
    }
    if (extractedContentMarkdown.present) {
      map['extracted_content_markdown'] = i0.Variable<String>(
        extractedContentMarkdown.value,
      );
    }
    if (extractedContentPlain.present) {
      map['extracted_content_plain'] = i0.Variable<String>(
        extractedContentPlain.value,
      );
    }
    if (fullContentMarkdown.present) {
      map['full_content_markdown'] = i0.Variable<String>(
        fullContentMarkdown.value,
      );
    }
    if (fullContentPlain.present) {
      map['full_content_plain'] = i0.Variable<String>(fullContentPlain.value);
    }
    if (timestamp.present) {
      map['timestamp'] = i0.Variable<DateTime>(timestamp.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TabCompanion(')
          ..write('id: $id, ')
          ..write('engineTabId: $engineTabId, ')
          ..write('source: $source, ')
          ..write('parentId: $parentId, ')
          ..write('containerId: $containerId, ')
          ..write('spaceUuid: $spaceUuid, ')
          ..write('folderId: $folderId, ')
          ..write('splitId: $splitId, ')
          ..write('splitIndex: $splitIndex, ')
          ..write('tabShelf: $tabShelf, ')
          ..write('orderKey: $orderKey, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('staticLabel: $staticLabel, ')
          ..write('hasStaticIcon: $hasStaticIcon, ')
          ..write('defaultContainer: $defaultContainer, ')
          ..write('tabMode: $tabMode, ')
          ..write('isProbablyReaderable: $isProbablyReaderable, ')
          ..write('extractedContentMarkdown: $extractedContentMarkdown, ')
          ..write('extractedContentPlain: $extractedContentPlain, ')
          ..write('fullContentMarkdown: $fullContentMarkdown, ')
          ..write('fullContentPlain: $fullContentPlain, ')
          ..write('timestamp: $timestamp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ClosedTabTombstone extends i0.Table
    with i0.TableInfo<ClosedTabTombstone, i2.ClosedTabTombstoneData> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  ClosedTabTombstone(this.attachedDatabase, [this._alias]);
  late final i0.GeneratedColumn<String> tabId = i0.GeneratedColumn<String>(
    'tab_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'PRIMARY KEY NOT NULL',
  );
  late final i0.GeneratedColumn<DateTime> closedAt =
      i0.GeneratedColumn<DateTime>(
        'closed_at',
        aliasedName,
        false,
        type: i0.DriftSqlType.dateTime,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  @override
  List<i0.GeneratedColumn> get $columns => [tabId, closedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'closed_tab_tombstone';
  @override
  Set<i0.GeneratedColumn> get $primaryKey => {tabId};
  @override
  i2.ClosedTabTombstoneData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i2.ClosedTabTombstoneData(
      tabId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}tab_id'],
      )!,
      closedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.dateTime,
        data['${effectivePrefix}closed_at'],
      )!,
    );
  }

  @override
  ClosedTabTombstone createAlias(String alias) {
    return ClosedTabTombstone(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ClosedTabTombstoneData extends i0.DataClass
    implements i0.Insertable<i2.ClosedTabTombstoneData> {
  final String tabId;
  final DateTime closedAt;
  const ClosedTabTombstoneData({required this.tabId, required this.closedAt});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['tab_id'] = i0.Variable<String>(tabId);
    map['closed_at'] = i0.Variable<DateTime>(closedAt);
    return map;
  }

  factory ClosedTabTombstoneData.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return ClosedTabTombstoneData(
      tabId: serializer.fromJson<String>(json['tab_id']),
      closedAt: serializer.fromJson<DateTime>(json['closed_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tab_id': serializer.toJson<String>(tabId),
      'closed_at': serializer.toJson<DateTime>(closedAt),
    };
  }

  i2.ClosedTabTombstoneData copyWith({String? tabId, DateTime? closedAt}) =>
      i2.ClosedTabTombstoneData(
        tabId: tabId ?? this.tabId,
        closedAt: closedAt ?? this.closedAt,
      );
  ClosedTabTombstoneData copyWithCompanion(
    i2.ClosedTabTombstoneCompanion data,
  ) {
    return ClosedTabTombstoneData(
      tabId: data.tabId.present ? data.tabId.value : this.tabId,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClosedTabTombstoneData(')
          ..write('tabId: $tabId, ')
          ..write('closedAt: $closedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tabId, closedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i2.ClosedTabTombstoneData &&
          other.tabId == this.tabId &&
          other.closedAt == this.closedAt);
}

class ClosedTabTombstoneCompanion
    extends i0.UpdateCompanion<i2.ClosedTabTombstoneData> {
  final i0.Value<String> tabId;
  final i0.Value<DateTime> closedAt;
  final i0.Value<int> rowid;
  const ClosedTabTombstoneCompanion({
    this.tabId = const i0.Value.absent(),
    this.closedAt = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  ClosedTabTombstoneCompanion.insert({
    required String tabId,
    required DateTime closedAt,
    this.rowid = const i0.Value.absent(),
  }) : tabId = i0.Value(tabId),
       closedAt = i0.Value(closedAt);
  static i0.Insertable<i2.ClosedTabTombstoneData> custom({
    i0.Expression<String>? tabId,
    i0.Expression<DateTime>? closedAt,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (tabId != null) 'tab_id': tabId,
      if (closedAt != null) 'closed_at': closedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i2.ClosedTabTombstoneCompanion copyWith({
    i0.Value<String>? tabId,
    i0.Value<DateTime>? closedAt,
    i0.Value<int>? rowid,
  }) {
    return i2.ClosedTabTombstoneCompanion(
      tabId: tabId ?? this.tabId,
      closedAt: closedAt ?? this.closedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (tabId.present) {
      map['tab_id'] = i0.Variable<String>(tabId.value);
    }
    if (closedAt.present) {
      map['closed_at'] = i0.Variable<DateTime>(closedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClosedTabTombstoneCompanion(')
          ..write('tabId: $tabId, ')
          ..write('closedAt: $closedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

i0.Index get idxTabScopeOrder => i0.Index(
  'idx_tab_scope_order',
  'CREATE INDEX idx_tab_scope_order ON tab (space_uuid, folder_id, tab_shelf, order_key)',
);
i0.Index get idxTabParentSpace => i0.Index(
  'idx_tab_parent_space',
  'CREATE INDEX idx_tab_parent_space ON tab (parent_id, space_uuid, folder_id)',
);
i0.Index get idxTabContainer => i0.Index(
  'idx_tab_container',
  'CREATE INDEX idx_tab_container ON tab (container_id)',
);
i0.Index get idxTabTimestamp => i0.Index(
  'idx_tab_timestamp',
  'CREATE INDEX idx_tab_timestamp ON tab (timestamp DESC, id DESC)',
);
i0.Index get idxTabFolderParent => i0.Index(
  'idx_tab_folder_parent',
  'CREATE INDEX idx_tab_folder_parent ON tab_folder (parent_folder_id, space_uuid, order_key)',
);
i0.Index get idxTabSplitScope => i0.Index(
  'idx_tab_split_scope',
  'CREATE INDEX idx_tab_split_scope ON tab_split (space_uuid, folder_id, order_key)',
);

class CaptureTab extends i0.Table
    with i0.TableInfo<CaptureTab, i2.CaptureTabData> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  CaptureTab(this.attachedDatabase, [this._alias]);
  late final i0.GeneratedColumn<String> tabId = i0.GeneratedColumn<String>(
    'tab_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL PRIMARY KEY REFERENCES tab(id)ON DELETE CASCADE',
  );
  late final i0.GeneratedColumn<String> captureId = i0.GeneratedColumn<String>(
    'capture_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final i0.GeneratedColumn<String> sourceUrl = i0.GeneratedColumn<String>(
    'source_url',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final i0.GeneratedColumn<String> status = i0.GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'pending\'',
    defaultValue: const i0.CustomExpression('\'pending\''),
  );
  late final i0.GeneratedColumn<DateTime> createdAt =
      i0.GeneratedColumn<DateTime>(
        'created_at',
        aliasedName,
        false,
        type: i0.DriftSqlType.dateTime,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  @override
  List<i0.GeneratedColumn> get $columns => [
    tabId,
    captureId,
    sourceUrl,
    status,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'capture_tab';
  @override
  Set<i0.GeneratedColumn> get $primaryKey => {tabId};
  @override
  i2.CaptureTabData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i2.CaptureTabData(
      tabId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}tab_id'],
      )!,
      captureId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}capture_id'],
      )!,
      sourceUrl: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      )!,
      status: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  CaptureTab createAlias(String alias) {
    return CaptureTab(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class CaptureTabData extends i0.DataClass
    implements i0.Insertable<i2.CaptureTabData> {
  final String tabId;
  final String captureId;
  final String sourceUrl;
  final String status;
  final DateTime createdAt;
  const CaptureTabData({
    required this.tabId,
    required this.captureId,
    required this.sourceUrl,
    required this.status,
    required this.createdAt,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['tab_id'] = i0.Variable<String>(tabId);
    map['capture_id'] = i0.Variable<String>(captureId);
    map['source_url'] = i0.Variable<String>(sourceUrl);
    map['status'] = i0.Variable<String>(status);
    map['created_at'] = i0.Variable<DateTime>(createdAt);
    return map;
  }

  factory CaptureTabData.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return CaptureTabData(
      tabId: serializer.fromJson<String>(json['tab_id']),
      captureId: serializer.fromJson<String>(json['capture_id']),
      sourceUrl: serializer.fromJson<String>(json['source_url']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tab_id': serializer.toJson<String>(tabId),
      'capture_id': serializer.toJson<String>(captureId),
      'source_url': serializer.toJson<String>(sourceUrl),
      'status': serializer.toJson<String>(status),
      'created_at': serializer.toJson<DateTime>(createdAt),
    };
  }

  i2.CaptureTabData copyWith({
    String? tabId,
    String? captureId,
    String? sourceUrl,
    String? status,
    DateTime? createdAt,
  }) => i2.CaptureTabData(
    tabId: tabId ?? this.tabId,
    captureId: captureId ?? this.captureId,
    sourceUrl: sourceUrl ?? this.sourceUrl,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
  CaptureTabData copyWithCompanion(i2.CaptureTabCompanion data) {
    return CaptureTabData(
      tabId: data.tabId.present ? data.tabId.value : this.tabId,
      captureId: data.captureId.present ? data.captureId.value : this.captureId,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CaptureTabData(')
          ..write('tabId: $tabId, ')
          ..write('captureId: $captureId, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(tabId, captureId, sourceUrl, status, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i2.CaptureTabData &&
          other.tabId == this.tabId &&
          other.captureId == this.captureId &&
          other.sourceUrl == this.sourceUrl &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class CaptureTabCompanion extends i0.UpdateCompanion<i2.CaptureTabData> {
  final i0.Value<String> tabId;
  final i0.Value<String> captureId;
  final i0.Value<String> sourceUrl;
  final i0.Value<String> status;
  final i0.Value<DateTime> createdAt;
  final i0.Value<int> rowid;
  const CaptureTabCompanion({
    this.tabId = const i0.Value.absent(),
    this.captureId = const i0.Value.absent(),
    this.sourceUrl = const i0.Value.absent(),
    this.status = const i0.Value.absent(),
    this.createdAt = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  CaptureTabCompanion.insert({
    required String tabId,
    required String captureId,
    required String sourceUrl,
    this.status = const i0.Value.absent(),
    required DateTime createdAt,
    this.rowid = const i0.Value.absent(),
  }) : tabId = i0.Value(tabId),
       captureId = i0.Value(captureId),
       sourceUrl = i0.Value(sourceUrl),
       createdAt = i0.Value(createdAt);
  static i0.Insertable<i2.CaptureTabData> custom({
    i0.Expression<String>? tabId,
    i0.Expression<String>? captureId,
    i0.Expression<String>? sourceUrl,
    i0.Expression<String>? status,
    i0.Expression<DateTime>? createdAt,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (tabId != null) 'tab_id': tabId,
      if (captureId != null) 'capture_id': captureId,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i2.CaptureTabCompanion copyWith({
    i0.Value<String>? tabId,
    i0.Value<String>? captureId,
    i0.Value<String>? sourceUrl,
    i0.Value<String>? status,
    i0.Value<DateTime>? createdAt,
    i0.Value<int>? rowid,
  }) {
    return i2.CaptureTabCompanion(
      tabId: tabId ?? this.tabId,
      captureId: captureId ?? this.captureId,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (tabId.present) {
      map['tab_id'] = i0.Variable<String>(tabId.value);
    }
    if (captureId.present) {
      map['capture_id'] = i0.Variable<String>(captureId.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = i0.Variable<String>(sourceUrl.value);
    }
    if (status.present) {
      map['status'] = i0.Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = i0.Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CaptureTabCompanion(')
          ..write('tabId: $tabId, ')
          ..write('captureId: $captureId, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

i0.Index get idxCaptureTabCaptureId => i0.Index(
  'idx_capture_tab_capture_id',
  'CREATE INDEX idx_capture_tab_capture_id ON capture_tab (capture_id)',
);

class TabFts extends i0.Table
    with i0.TableInfo<TabFts, i2.TabFt>, i0.VirtualTableInfo<TabFts, i2.TabFt> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  TabFts(this.attachedDatabase, [this._alias]);
  late final i0.GeneratedColumn<String> title = i0.GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  late final i0.GeneratedColumn<String> url = i0.GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  late final i0.GeneratedColumn<String> extractedContentPlain =
      i0.GeneratedColumn<String>(
        'extracted_content_plain',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: '',
      );
  late final i0.GeneratedColumn<String> fullContentPlain =
      i0.GeneratedColumn<String>(
        'full_content_plain',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: '',
      );
  @override
  List<i0.GeneratedColumn> get $columns => [
    title,
    url,
    extractedContentPlain,
    fullContentPlain,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tab_fts';
  @override
  Set<i0.GeneratedColumn> get $primaryKey => const {};
  @override
  i2.TabFt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i2.TabFt(
      title: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      url: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      extractedContentPlain: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}extracted_content_plain'],
      )!,
      fullContentPlain: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}full_content_plain'],
      )!,
    );
  }

  @override
  TabFts createAlias(String alias) {
    return TabFts(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs =>
      'fts5(title, url, extracted_content_plain, full_content_plain, content=tab, tokenize="trigram")';
}

class TabFt extends i0.DataClass implements i0.Insertable<i2.TabFt> {
  final String title;
  final String url;
  final String extractedContentPlain;
  final String fullContentPlain;
  const TabFt({
    required this.title,
    required this.url,
    required this.extractedContentPlain,
    required this.fullContentPlain,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['title'] = i0.Variable<String>(title);
    map['url'] = i0.Variable<String>(url);
    map['extracted_content_plain'] = i0.Variable<String>(extractedContentPlain);
    map['full_content_plain'] = i0.Variable<String>(fullContentPlain);
    return map;
  }

  factory TabFt.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return TabFt(
      title: serializer.fromJson<String>(json['title']),
      url: serializer.fromJson<String>(json['url']),
      extractedContentPlain: serializer.fromJson<String>(
        json['extracted_content_plain'],
      ),
      fullContentPlain: serializer.fromJson<String>(json['full_content_plain']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'title': serializer.toJson<String>(title),
      'url': serializer.toJson<String>(url),
      'extracted_content_plain': serializer.toJson<String>(
        extractedContentPlain,
      ),
      'full_content_plain': serializer.toJson<String>(fullContentPlain),
    };
  }

  i2.TabFt copyWith({
    String? title,
    String? url,
    String? extractedContentPlain,
    String? fullContentPlain,
  }) => i2.TabFt(
    title: title ?? this.title,
    url: url ?? this.url,
    extractedContentPlain: extractedContentPlain ?? this.extractedContentPlain,
    fullContentPlain: fullContentPlain ?? this.fullContentPlain,
  );
  TabFt copyWithCompanion(i2.TabFtsCompanion data) {
    return TabFt(
      title: data.title.present ? data.title.value : this.title,
      url: data.url.present ? data.url.value : this.url,
      extractedContentPlain: data.extractedContentPlain.present
          ? data.extractedContentPlain.value
          : this.extractedContentPlain,
      fullContentPlain: data.fullContentPlain.present
          ? data.fullContentPlain.value
          : this.fullContentPlain,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TabFt(')
          ..write('title: $title, ')
          ..write('url: $url, ')
          ..write('extractedContentPlain: $extractedContentPlain, ')
          ..write('fullContentPlain: $fullContentPlain')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(title, url, extractedContentPlain, fullContentPlain);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i2.TabFt &&
          other.title == this.title &&
          other.url == this.url &&
          other.extractedContentPlain == this.extractedContentPlain &&
          other.fullContentPlain == this.fullContentPlain);
}

class TabFtsCompanion extends i0.UpdateCompanion<i2.TabFt> {
  final i0.Value<String> title;
  final i0.Value<String> url;
  final i0.Value<String> extractedContentPlain;
  final i0.Value<String> fullContentPlain;
  final i0.Value<int> rowid;
  const TabFtsCompanion({
    this.title = const i0.Value.absent(),
    this.url = const i0.Value.absent(),
    this.extractedContentPlain = const i0.Value.absent(),
    this.fullContentPlain = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  TabFtsCompanion.insert({
    required String title,
    required String url,
    required String extractedContentPlain,
    required String fullContentPlain,
    this.rowid = const i0.Value.absent(),
  }) : title = i0.Value(title),
       url = i0.Value(url),
       extractedContentPlain = i0.Value(extractedContentPlain),
       fullContentPlain = i0.Value(fullContentPlain);
  static i0.Insertable<i2.TabFt> custom({
    i0.Expression<String>? title,
    i0.Expression<String>? url,
    i0.Expression<String>? extractedContentPlain,
    i0.Expression<String>? fullContentPlain,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (title != null) 'title': title,
      if (url != null) 'url': url,
      if (extractedContentPlain != null)
        'extracted_content_plain': extractedContentPlain,
      if (fullContentPlain != null) 'full_content_plain': fullContentPlain,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i2.TabFtsCompanion copyWith({
    i0.Value<String>? title,
    i0.Value<String>? url,
    i0.Value<String>? extractedContentPlain,
    i0.Value<String>? fullContentPlain,
    i0.Value<int>? rowid,
  }) {
    return i2.TabFtsCompanion(
      title: title ?? this.title,
      url: url ?? this.url,
      extractedContentPlain:
          extractedContentPlain ?? this.extractedContentPlain,
      fullContentPlain: fullContentPlain ?? this.fullContentPlain,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (title.present) {
      map['title'] = i0.Variable<String>(title.value);
    }
    if (url.present) {
      map['url'] = i0.Variable<String>(url.value);
    }
    if (extractedContentPlain.present) {
      map['extracted_content_plain'] = i0.Variable<String>(
        extractedContentPlain.value,
      );
    }
    if (fullContentPlain.present) {
      map['full_content_plain'] = i0.Variable<String>(fullContentPlain.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TabFtsCompanion(')
          ..write('title: $title, ')
          ..write('url: $url, ')
          ..write('extractedContentPlain: $extractedContentPlain, ')
          ..write('fullContentPlain: $fullContentPlain, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

i0.Trigger get tabMaintainParentChainOnDelete => i0.Trigger(
  'CREATE TRIGGER tab_maintain_parent_chain_on_delete BEFORE DELETE ON tab BEGIN UPDATE tab SET parent_id = CASE WHEN OLD.parent_id IS NOT NULL AND EXISTS (SELECT 1 FROM tab WHERE id = OLD.parent_id) THEN OLD.parent_id ELSE NULL END WHERE parent_id = OLD.id;END',
  'tab_maintain_parent_chain_on_delete',
);
i0.Trigger get tabChildFollowsParentScope => i0.Trigger(
  'CREATE TRIGGER tab_child_follows_parent_scope AFTER UPDATE OF space_uuid, folder_id ON tab BEGIN UPDATE tab SET space_uuid = NEW.space_uuid, folder_id = NEW.folder_id WHERE parent_id = NEW.id AND(space_uuid IS NOT NEW.space_uuid OR folder_id IS NOT NEW.folder_id);END',
  'tab_child_follows_parent_scope',
);
i0.Trigger get tabAfterInsert => i0.Trigger(
  'CREATE TRIGGER tab_after_insert AFTER INSERT ON tab BEGIN INSERT INTO tab_fts ("rowid", title, url, extracted_content_plain, full_content_plain) VALUES (new."rowid", new.title, new.url, new.extracted_content_plain, new.full_content_plain);END',
  'tab_after_insert',
);
i0.Trigger get tabAfterDelete => i0.Trigger(
  'CREATE TRIGGER tab_after_delete AFTER DELETE ON tab BEGIN INSERT INTO tab_fts (tab_fts, "rowid", title, url, extracted_content_plain, full_content_plain) VALUES (\'delete\', old."rowid", old.title, old.url, old.extracted_content_plain, old.full_content_plain);END',
  'tab_after_delete',
);
i0.Trigger get tabAfterUpdate => i0.Trigger(
  'CREATE TRIGGER tab_after_update AFTER UPDATE OF title, url, extracted_content_plain, full_content_plain ON tab WHEN OLD.content_hash IS NOT NEW.content_hash OR OLD.url IS NOT NEW.url BEGIN INSERT INTO tab_fts (tab_fts, "rowid", title, url, extracted_content_plain, full_content_plain) VALUES (\'delete\', old."rowid", old.title, old.url, old.extracted_content_plain, old.full_content_plain);INSERT INTO tab_fts ("rowid", title, url, extracted_content_plain, full_content_plain) VALUES (new."rowid", new.title, new.url, new.extracted_content_plain, new.full_content_plain);END',
  'tab_after_update',
);

class LocalIndexSetting extends i0.Table
    with i0.TableInfo<LocalIndexSetting, i2.LocalIndexSettingData> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  LocalIndexSetting(this.attachedDatabase, [this._alias]);
  late final i0.GeneratedColumn<String> key = i0.GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'PRIMARY KEY NOT NULL',
  );
  late final i0.GeneratedColumn<int> value = i0.GeneratedColumn<int>(
    'value',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<i0.GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_index_setting';
  @override
  Set<i0.GeneratedColumn> get $primaryKey => {key};
  @override
  i2.LocalIndexSettingData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i2.LocalIndexSettingData(
      key: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  LocalIndexSetting createAlias(String alias) {
    return LocalIndexSetting(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  bool get dontWriteConstraints => true;
}

class LocalIndexSettingData extends i0.DataClass
    implements i0.Insertable<i2.LocalIndexSettingData> {
  final String key;
  final int value;
  const LocalIndexSettingData({required this.key, required this.value});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['key'] = i0.Variable<String>(key);
    map['value'] = i0.Variable<int>(value);
    return map;
  }

  factory LocalIndexSettingData.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return LocalIndexSettingData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<int>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<int>(value),
    };
  }

  i2.LocalIndexSettingData copyWith({String? key, int? value}) =>
      i2.LocalIndexSettingData(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  LocalIndexSettingData copyWithCompanion(i2.LocalIndexSettingCompanion data) {
    return LocalIndexSettingData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalIndexSettingData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i2.LocalIndexSettingData &&
          other.key == this.key &&
          other.value == this.value);
}

class LocalIndexSettingCompanion
    extends i0.UpdateCompanion<i2.LocalIndexSettingData> {
  final i0.Value<String> key;
  final i0.Value<int> value;
  final i0.Value<int> rowid;
  const LocalIndexSettingCompanion({
    this.key = const i0.Value.absent(),
    this.value = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  LocalIndexSettingCompanion.insert({
    required String key,
    required int value,
    this.rowid = const i0.Value.absent(),
  }) : key = i0.Value(key),
       value = i0.Value(value);
  static i0.Insertable<i2.LocalIndexSettingData> custom({
    i0.Expression<String>? key,
    i0.Expression<int>? value,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i2.LocalIndexSettingCompanion copyWith({
    i0.Value<String>? key,
    i0.Value<int>? value,
    i0.Value<int>? rowid,
  }) {
    return i2.LocalIndexSettingCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (key.present) {
      map['key'] = i0.Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = i0.Variable<int>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalIndexSettingCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class History extends i0.Table with i0.TableInfo<History, i2.HistoryData> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  History(this.attachedDatabase, [this._alias]);
  late final i0.GeneratedColumn<String> urlCanonical =
      i0.GeneratedColumn<String>(
        'url_canonical',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: 'PRIMARY KEY NOT NULL',
      );
  late final i0.GeneratedColumn<String> urlHost = i0.GeneratedColumn<String>(
    'url_host',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final i0.GeneratedColumn<String> urlPath = i0.GeneratedColumn<String>(
    'url_path',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final i0.GeneratedColumn<String> title = i0.GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final i0.GeneratedColumn<bool> isProbablyReaderable =
      i0.GeneratedColumn<bool>(
        'is_probably_readerable',
        aliasedName,
        true,
        type: i0.DriftSqlType.bool,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  late final i0.GeneratedColumn<String> extractedContentMarkdown =
      i0.GeneratedColumn<String>(
        'extracted_content_markdown',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  late final i0.GeneratedColumn<String> extractedContentPlain =
      i0.GeneratedColumn<String>(
        'extracted_content_plain',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  late final i0.GeneratedColumn<String> fullContentMarkdown =
      i0.GeneratedColumn<String>(
        'full_content_markdown',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  late final i0.GeneratedColumn<String> fullContentPlain =
      i0.GeneratedColumn<String>(
        'full_content_plain',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  late final i0.GeneratedColumn<int> contentHash = i0.GeneratedColumn<int>(
    'content_hash',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final i0.GeneratedColumn<DateTime> observedAt =
      i0.GeneratedColumn<DateTime>(
        'observed_at',
        aliasedName,
        false,
        type: i0.DriftSqlType.dateTime,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  late final i0.GeneratedColumn<int> observedCount = i0.GeneratedColumn<int>(
    'observed_count',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1',
    defaultValue: const i0.CustomExpression('1'),
  );
  @override
  List<i0.GeneratedColumn> get $columns => [
    urlCanonical,
    urlHost,
    urlPath,
    title,
    isProbablyReaderable,
    extractedContentMarkdown,
    extractedContentPlain,
    fullContentMarkdown,
    fullContentPlain,
    contentHash,
    observedAt,
    observedCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history';
  @override
  Set<i0.GeneratedColumn> get $primaryKey => {urlCanonical};
  @override
  i2.HistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i2.HistoryData(
      urlCanonical: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}url_canonical'],
      )!,
      urlHost: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}url_host'],
      )!,
      urlPath: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}url_path'],
      ),
      title: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      isProbablyReaderable: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.bool,
        data['${effectivePrefix}is_probably_readerable'],
      ),
      extractedContentMarkdown: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}extracted_content_markdown'],
      ),
      extractedContentPlain: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}extracted_content_plain'],
      ),
      fullContentMarkdown: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}full_content_markdown'],
      ),
      fullContentPlain: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}full_content_plain'],
      ),
      contentHash: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}content_hash'],
      ),
      observedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.dateTime,
        data['${effectivePrefix}observed_at'],
      )!,
      observedCount: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}observed_count'],
      )!,
    );
  }

  @override
  History createAlias(String alias) {
    return History(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class HistoryData extends i0.DataClass
    implements i0.Insertable<i2.HistoryData> {
  final String urlCanonical;
  final String urlHost;
  final String? urlPath;
  final String? title;
  final bool? isProbablyReaderable;
  final String? extractedContentMarkdown;
  final String? extractedContentPlain;
  final String? fullContentMarkdown;
  final String? fullContentPlain;
  final int? contentHash;
  final DateTime observedAt;
  final int observedCount;
  const HistoryData({
    required this.urlCanonical,
    required this.urlHost,
    this.urlPath,
    this.title,
    this.isProbablyReaderable,
    this.extractedContentMarkdown,
    this.extractedContentPlain,
    this.fullContentMarkdown,
    this.fullContentPlain,
    this.contentHash,
    required this.observedAt,
    required this.observedCount,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['url_canonical'] = i0.Variable<String>(urlCanonical);
    map['url_host'] = i0.Variable<String>(urlHost);
    if (!nullToAbsent || urlPath != null) {
      map['url_path'] = i0.Variable<String>(urlPath);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = i0.Variable<String>(title);
    }
    if (!nullToAbsent || isProbablyReaderable != null) {
      map['is_probably_readerable'] = i0.Variable<bool>(isProbablyReaderable);
    }
    if (!nullToAbsent || extractedContentMarkdown != null) {
      map['extracted_content_markdown'] = i0.Variable<String>(
        extractedContentMarkdown,
      );
    }
    if (!nullToAbsent || extractedContentPlain != null) {
      map['extracted_content_plain'] = i0.Variable<String>(
        extractedContentPlain,
      );
    }
    if (!nullToAbsent || fullContentMarkdown != null) {
      map['full_content_markdown'] = i0.Variable<String>(fullContentMarkdown);
    }
    if (!nullToAbsent || fullContentPlain != null) {
      map['full_content_plain'] = i0.Variable<String>(fullContentPlain);
    }
    if (!nullToAbsent || contentHash != null) {
      map['content_hash'] = i0.Variable<int>(contentHash);
    }
    map['observed_at'] = i0.Variable<DateTime>(observedAt);
    map['observed_count'] = i0.Variable<int>(observedCount);
    return map;
  }

  factory HistoryData.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return HistoryData(
      urlCanonical: serializer.fromJson<String>(json['url_canonical']),
      urlHost: serializer.fromJson<String>(json['url_host']),
      urlPath: serializer.fromJson<String?>(json['url_path']),
      title: serializer.fromJson<String?>(json['title']),
      isProbablyReaderable: serializer.fromJson<bool?>(
        json['is_probably_readerable'],
      ),
      extractedContentMarkdown: serializer.fromJson<String?>(
        json['extracted_content_markdown'],
      ),
      extractedContentPlain: serializer.fromJson<String?>(
        json['extracted_content_plain'],
      ),
      fullContentMarkdown: serializer.fromJson<String?>(
        json['full_content_markdown'],
      ),
      fullContentPlain: serializer.fromJson<String?>(
        json['full_content_plain'],
      ),
      contentHash: serializer.fromJson<int?>(json['content_hash']),
      observedAt: serializer.fromJson<DateTime>(json['observed_at']),
      observedCount: serializer.fromJson<int>(json['observed_count']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'url_canonical': serializer.toJson<String>(urlCanonical),
      'url_host': serializer.toJson<String>(urlHost),
      'url_path': serializer.toJson<String?>(urlPath),
      'title': serializer.toJson<String?>(title),
      'is_probably_readerable': serializer.toJson<bool?>(isProbablyReaderable),
      'extracted_content_markdown': serializer.toJson<String?>(
        extractedContentMarkdown,
      ),
      'extracted_content_plain': serializer.toJson<String?>(
        extractedContentPlain,
      ),
      'full_content_markdown': serializer.toJson<String?>(fullContentMarkdown),
      'full_content_plain': serializer.toJson<String?>(fullContentPlain),
      'content_hash': serializer.toJson<int?>(contentHash),
      'observed_at': serializer.toJson<DateTime>(observedAt),
      'observed_count': serializer.toJson<int>(observedCount),
    };
  }

  i2.HistoryData copyWith({
    String? urlCanonical,
    String? urlHost,
    i0.Value<String?> urlPath = const i0.Value.absent(),
    i0.Value<String?> title = const i0.Value.absent(),
    i0.Value<bool?> isProbablyReaderable = const i0.Value.absent(),
    i0.Value<String?> extractedContentMarkdown = const i0.Value.absent(),
    i0.Value<String?> extractedContentPlain = const i0.Value.absent(),
    i0.Value<String?> fullContentMarkdown = const i0.Value.absent(),
    i0.Value<String?> fullContentPlain = const i0.Value.absent(),
    i0.Value<int?> contentHash = const i0.Value.absent(),
    DateTime? observedAt,
    int? observedCount,
  }) => i2.HistoryData(
    urlCanonical: urlCanonical ?? this.urlCanonical,
    urlHost: urlHost ?? this.urlHost,
    urlPath: urlPath.present ? urlPath.value : this.urlPath,
    title: title.present ? title.value : this.title,
    isProbablyReaderable: isProbablyReaderable.present
        ? isProbablyReaderable.value
        : this.isProbablyReaderable,
    extractedContentMarkdown: extractedContentMarkdown.present
        ? extractedContentMarkdown.value
        : this.extractedContentMarkdown,
    extractedContentPlain: extractedContentPlain.present
        ? extractedContentPlain.value
        : this.extractedContentPlain,
    fullContentMarkdown: fullContentMarkdown.present
        ? fullContentMarkdown.value
        : this.fullContentMarkdown,
    fullContentPlain: fullContentPlain.present
        ? fullContentPlain.value
        : this.fullContentPlain,
    contentHash: contentHash.present ? contentHash.value : this.contentHash,
    observedAt: observedAt ?? this.observedAt,
    observedCount: observedCount ?? this.observedCount,
  );
  HistoryData copyWithCompanion(i2.HistoryCompanion data) {
    return HistoryData(
      urlCanonical: data.urlCanonical.present
          ? data.urlCanonical.value
          : this.urlCanonical,
      urlHost: data.urlHost.present ? data.urlHost.value : this.urlHost,
      urlPath: data.urlPath.present ? data.urlPath.value : this.urlPath,
      title: data.title.present ? data.title.value : this.title,
      isProbablyReaderable: data.isProbablyReaderable.present
          ? data.isProbablyReaderable.value
          : this.isProbablyReaderable,
      extractedContentMarkdown: data.extractedContentMarkdown.present
          ? data.extractedContentMarkdown.value
          : this.extractedContentMarkdown,
      extractedContentPlain: data.extractedContentPlain.present
          ? data.extractedContentPlain.value
          : this.extractedContentPlain,
      fullContentMarkdown: data.fullContentMarkdown.present
          ? data.fullContentMarkdown.value
          : this.fullContentMarkdown,
      fullContentPlain: data.fullContentPlain.present
          ? data.fullContentPlain.value
          : this.fullContentPlain,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      observedAt: data.observedAt.present
          ? data.observedAt.value
          : this.observedAt,
      observedCount: data.observedCount.present
          ? data.observedCount.value
          : this.observedCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoryData(')
          ..write('urlCanonical: $urlCanonical, ')
          ..write('urlHost: $urlHost, ')
          ..write('urlPath: $urlPath, ')
          ..write('title: $title, ')
          ..write('isProbablyReaderable: $isProbablyReaderable, ')
          ..write('extractedContentMarkdown: $extractedContentMarkdown, ')
          ..write('extractedContentPlain: $extractedContentPlain, ')
          ..write('fullContentMarkdown: $fullContentMarkdown, ')
          ..write('fullContentPlain: $fullContentPlain, ')
          ..write('contentHash: $contentHash, ')
          ..write('observedAt: $observedAt, ')
          ..write('observedCount: $observedCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    urlCanonical,
    urlHost,
    urlPath,
    title,
    isProbablyReaderable,
    extractedContentMarkdown,
    extractedContentPlain,
    fullContentMarkdown,
    fullContentPlain,
    contentHash,
    observedAt,
    observedCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i2.HistoryData &&
          other.urlCanonical == this.urlCanonical &&
          other.urlHost == this.urlHost &&
          other.urlPath == this.urlPath &&
          other.title == this.title &&
          other.isProbablyReaderable == this.isProbablyReaderable &&
          other.extractedContentMarkdown == this.extractedContentMarkdown &&
          other.extractedContentPlain == this.extractedContentPlain &&
          other.fullContentMarkdown == this.fullContentMarkdown &&
          other.fullContentPlain == this.fullContentPlain &&
          other.contentHash == this.contentHash &&
          other.observedAt == this.observedAt &&
          other.observedCount == this.observedCount);
}

class HistoryCompanion extends i0.UpdateCompanion<i2.HistoryData> {
  final i0.Value<String> urlCanonical;
  final i0.Value<String> urlHost;
  final i0.Value<String?> urlPath;
  final i0.Value<String?> title;
  final i0.Value<bool?> isProbablyReaderable;
  final i0.Value<String?> extractedContentMarkdown;
  final i0.Value<String?> extractedContentPlain;
  final i0.Value<String?> fullContentMarkdown;
  final i0.Value<String?> fullContentPlain;
  final i0.Value<int?> contentHash;
  final i0.Value<DateTime> observedAt;
  final i0.Value<int> observedCount;
  final i0.Value<int> rowid;
  const HistoryCompanion({
    this.urlCanonical = const i0.Value.absent(),
    this.urlHost = const i0.Value.absent(),
    this.urlPath = const i0.Value.absent(),
    this.title = const i0.Value.absent(),
    this.isProbablyReaderable = const i0.Value.absent(),
    this.extractedContentMarkdown = const i0.Value.absent(),
    this.extractedContentPlain = const i0.Value.absent(),
    this.fullContentMarkdown = const i0.Value.absent(),
    this.fullContentPlain = const i0.Value.absent(),
    this.contentHash = const i0.Value.absent(),
    this.observedAt = const i0.Value.absent(),
    this.observedCount = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  HistoryCompanion.insert({
    required String urlCanonical,
    required String urlHost,
    this.urlPath = const i0.Value.absent(),
    this.title = const i0.Value.absent(),
    this.isProbablyReaderable = const i0.Value.absent(),
    this.extractedContentMarkdown = const i0.Value.absent(),
    this.extractedContentPlain = const i0.Value.absent(),
    this.fullContentMarkdown = const i0.Value.absent(),
    this.fullContentPlain = const i0.Value.absent(),
    this.contentHash = const i0.Value.absent(),
    required DateTime observedAt,
    this.observedCount = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  }) : urlCanonical = i0.Value(urlCanonical),
       urlHost = i0.Value(urlHost),
       observedAt = i0.Value(observedAt);
  static i0.Insertable<i2.HistoryData> custom({
    i0.Expression<String>? urlCanonical,
    i0.Expression<String>? urlHost,
    i0.Expression<String>? urlPath,
    i0.Expression<String>? title,
    i0.Expression<bool>? isProbablyReaderable,
    i0.Expression<String>? extractedContentMarkdown,
    i0.Expression<String>? extractedContentPlain,
    i0.Expression<String>? fullContentMarkdown,
    i0.Expression<String>? fullContentPlain,
    i0.Expression<int>? contentHash,
    i0.Expression<DateTime>? observedAt,
    i0.Expression<int>? observedCount,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (urlCanonical != null) 'url_canonical': urlCanonical,
      if (urlHost != null) 'url_host': urlHost,
      if (urlPath != null) 'url_path': urlPath,
      if (title != null) 'title': title,
      if (isProbablyReaderable != null)
        'is_probably_readerable': isProbablyReaderable,
      if (extractedContentMarkdown != null)
        'extracted_content_markdown': extractedContentMarkdown,
      if (extractedContentPlain != null)
        'extracted_content_plain': extractedContentPlain,
      if (fullContentMarkdown != null)
        'full_content_markdown': fullContentMarkdown,
      if (fullContentPlain != null) 'full_content_plain': fullContentPlain,
      if (contentHash != null) 'content_hash': contentHash,
      if (observedAt != null) 'observed_at': observedAt,
      if (observedCount != null) 'observed_count': observedCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i2.HistoryCompanion copyWith({
    i0.Value<String>? urlCanonical,
    i0.Value<String>? urlHost,
    i0.Value<String?>? urlPath,
    i0.Value<String?>? title,
    i0.Value<bool?>? isProbablyReaderable,
    i0.Value<String?>? extractedContentMarkdown,
    i0.Value<String?>? extractedContentPlain,
    i0.Value<String?>? fullContentMarkdown,
    i0.Value<String?>? fullContentPlain,
    i0.Value<int?>? contentHash,
    i0.Value<DateTime>? observedAt,
    i0.Value<int>? observedCount,
    i0.Value<int>? rowid,
  }) {
    return i2.HistoryCompanion(
      urlCanonical: urlCanonical ?? this.urlCanonical,
      urlHost: urlHost ?? this.urlHost,
      urlPath: urlPath ?? this.urlPath,
      title: title ?? this.title,
      isProbablyReaderable: isProbablyReaderable ?? this.isProbablyReaderable,
      extractedContentMarkdown:
          extractedContentMarkdown ?? this.extractedContentMarkdown,
      extractedContentPlain:
          extractedContentPlain ?? this.extractedContentPlain,
      fullContentMarkdown: fullContentMarkdown ?? this.fullContentMarkdown,
      fullContentPlain: fullContentPlain ?? this.fullContentPlain,
      contentHash: contentHash ?? this.contentHash,
      observedAt: observedAt ?? this.observedAt,
      observedCount: observedCount ?? this.observedCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (urlCanonical.present) {
      map['url_canonical'] = i0.Variable<String>(urlCanonical.value);
    }
    if (urlHost.present) {
      map['url_host'] = i0.Variable<String>(urlHost.value);
    }
    if (urlPath.present) {
      map['url_path'] = i0.Variable<String>(urlPath.value);
    }
    if (title.present) {
      map['title'] = i0.Variable<String>(title.value);
    }
    if (isProbablyReaderable.present) {
      map['is_probably_readerable'] = i0.Variable<bool>(
        isProbablyReaderable.value,
      );
    }
    if (extractedContentMarkdown.present) {
      map['extracted_content_markdown'] = i0.Variable<String>(
        extractedContentMarkdown.value,
      );
    }
    if (extractedContentPlain.present) {
      map['extracted_content_plain'] = i0.Variable<String>(
        extractedContentPlain.value,
      );
    }
    if (fullContentMarkdown.present) {
      map['full_content_markdown'] = i0.Variable<String>(
        fullContentMarkdown.value,
      );
    }
    if (fullContentPlain.present) {
      map['full_content_plain'] = i0.Variable<String>(fullContentPlain.value);
    }
    if (contentHash.present) {
      map['content_hash'] = i0.Variable<int>(contentHash.value);
    }
    if (observedAt.present) {
      map['observed_at'] = i0.Variable<DateTime>(observedAt.value);
    }
    if (observedCount.present) {
      map['observed_count'] = i0.Variable<int>(observedCount.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoryCompanion(')
          ..write('urlCanonical: $urlCanonical, ')
          ..write('urlHost: $urlHost, ')
          ..write('urlPath: $urlPath, ')
          ..write('title: $title, ')
          ..write('isProbablyReaderable: $isProbablyReaderable, ')
          ..write('extractedContentMarkdown: $extractedContentMarkdown, ')
          ..write('extractedContentPlain: $extractedContentPlain, ')
          ..write('fullContentMarkdown: $fullContentMarkdown, ')
          ..write('fullContentPlain: $fullContentPlain, ')
          ..write('contentHash: $contentHash, ')
          ..write('observedAt: $observedAt, ')
          ..write('observedCount: $observedCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

i0.Index get idxHistoryHost => i0.Index(
  'idx_history_host',
  'CREATE INDEX idx_history_host ON history (url_host)',
);
i0.Index get idxHistoryObserved => i0.Index(
  'idx_history_observed',
  'CREATE INDEX idx_history_observed ON history (observed_at DESC)',
);

class HistoryFts extends i0.Table
    with
        i0.TableInfo<HistoryFts, i2.HistoryFt>,
        i0.VirtualTableInfo<HistoryFts, i2.HistoryFt> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  HistoryFts(this.attachedDatabase, [this._alias]);
  late final i0.GeneratedColumn<String> title = i0.GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  late final i0.GeneratedColumn<String> urlHost = i0.GeneratedColumn<String>(
    'url_host',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  late final i0.GeneratedColumn<String> urlPath = i0.GeneratedColumn<String>(
    'url_path',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  late final i0.GeneratedColumn<String> extractedContentPlain =
      i0.GeneratedColumn<String>(
        'extracted_content_plain',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: '',
      );
  late final i0.GeneratedColumn<String> fullContentPlain =
      i0.GeneratedColumn<String>(
        'full_content_plain',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: '',
      );
  @override
  List<i0.GeneratedColumn> get $columns => [
    title,
    urlHost,
    urlPath,
    extractedContentPlain,
    fullContentPlain,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history_fts';
  @override
  Set<i0.GeneratedColumn> get $primaryKey => const {};
  @override
  i2.HistoryFt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i2.HistoryFt(
      title: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      urlHost: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}url_host'],
      )!,
      urlPath: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}url_path'],
      )!,
      extractedContentPlain: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}extracted_content_plain'],
      )!,
      fullContentPlain: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}full_content_plain'],
      )!,
    );
  }

  @override
  HistoryFts createAlias(String alias) {
    return HistoryFts(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs =>
      'fts5(title, url_host, url_path, extracted_content_plain, full_content_plain, content=history, tokenize="trigram")';
}

class HistoryFt extends i0.DataClass implements i0.Insertable<i2.HistoryFt> {
  final String title;
  final String urlHost;
  final String urlPath;
  final String extractedContentPlain;
  final String fullContentPlain;
  const HistoryFt({
    required this.title,
    required this.urlHost,
    required this.urlPath,
    required this.extractedContentPlain,
    required this.fullContentPlain,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['title'] = i0.Variable<String>(title);
    map['url_host'] = i0.Variable<String>(urlHost);
    map['url_path'] = i0.Variable<String>(urlPath);
    map['extracted_content_plain'] = i0.Variable<String>(extractedContentPlain);
    map['full_content_plain'] = i0.Variable<String>(fullContentPlain);
    return map;
  }

  factory HistoryFt.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return HistoryFt(
      title: serializer.fromJson<String>(json['title']),
      urlHost: serializer.fromJson<String>(json['url_host']),
      urlPath: serializer.fromJson<String>(json['url_path']),
      extractedContentPlain: serializer.fromJson<String>(
        json['extracted_content_plain'],
      ),
      fullContentPlain: serializer.fromJson<String>(json['full_content_plain']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'title': serializer.toJson<String>(title),
      'url_host': serializer.toJson<String>(urlHost),
      'url_path': serializer.toJson<String>(urlPath),
      'extracted_content_plain': serializer.toJson<String>(
        extractedContentPlain,
      ),
      'full_content_plain': serializer.toJson<String>(fullContentPlain),
    };
  }

  i2.HistoryFt copyWith({
    String? title,
    String? urlHost,
    String? urlPath,
    String? extractedContentPlain,
    String? fullContentPlain,
  }) => i2.HistoryFt(
    title: title ?? this.title,
    urlHost: urlHost ?? this.urlHost,
    urlPath: urlPath ?? this.urlPath,
    extractedContentPlain: extractedContentPlain ?? this.extractedContentPlain,
    fullContentPlain: fullContentPlain ?? this.fullContentPlain,
  );
  HistoryFt copyWithCompanion(i2.HistoryFtsCompanion data) {
    return HistoryFt(
      title: data.title.present ? data.title.value : this.title,
      urlHost: data.urlHost.present ? data.urlHost.value : this.urlHost,
      urlPath: data.urlPath.present ? data.urlPath.value : this.urlPath,
      extractedContentPlain: data.extractedContentPlain.present
          ? data.extractedContentPlain.value
          : this.extractedContentPlain,
      fullContentPlain: data.fullContentPlain.present
          ? data.fullContentPlain.value
          : this.fullContentPlain,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoryFt(')
          ..write('title: $title, ')
          ..write('urlHost: $urlHost, ')
          ..write('urlPath: $urlPath, ')
          ..write('extractedContentPlain: $extractedContentPlain, ')
          ..write('fullContentPlain: $fullContentPlain')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    title,
    urlHost,
    urlPath,
    extractedContentPlain,
    fullContentPlain,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i2.HistoryFt &&
          other.title == this.title &&
          other.urlHost == this.urlHost &&
          other.urlPath == this.urlPath &&
          other.extractedContentPlain == this.extractedContentPlain &&
          other.fullContentPlain == this.fullContentPlain);
}

class HistoryFtsCompanion extends i0.UpdateCompanion<i2.HistoryFt> {
  final i0.Value<String> title;
  final i0.Value<String> urlHost;
  final i0.Value<String> urlPath;
  final i0.Value<String> extractedContentPlain;
  final i0.Value<String> fullContentPlain;
  final i0.Value<int> rowid;
  const HistoryFtsCompanion({
    this.title = const i0.Value.absent(),
    this.urlHost = const i0.Value.absent(),
    this.urlPath = const i0.Value.absent(),
    this.extractedContentPlain = const i0.Value.absent(),
    this.fullContentPlain = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  HistoryFtsCompanion.insert({
    required String title,
    required String urlHost,
    required String urlPath,
    required String extractedContentPlain,
    required String fullContentPlain,
    this.rowid = const i0.Value.absent(),
  }) : title = i0.Value(title),
       urlHost = i0.Value(urlHost),
       urlPath = i0.Value(urlPath),
       extractedContentPlain = i0.Value(extractedContentPlain),
       fullContentPlain = i0.Value(fullContentPlain);
  static i0.Insertable<i2.HistoryFt> custom({
    i0.Expression<String>? title,
    i0.Expression<String>? urlHost,
    i0.Expression<String>? urlPath,
    i0.Expression<String>? extractedContentPlain,
    i0.Expression<String>? fullContentPlain,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (title != null) 'title': title,
      if (urlHost != null) 'url_host': urlHost,
      if (urlPath != null) 'url_path': urlPath,
      if (extractedContentPlain != null)
        'extracted_content_plain': extractedContentPlain,
      if (fullContentPlain != null) 'full_content_plain': fullContentPlain,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i2.HistoryFtsCompanion copyWith({
    i0.Value<String>? title,
    i0.Value<String>? urlHost,
    i0.Value<String>? urlPath,
    i0.Value<String>? extractedContentPlain,
    i0.Value<String>? fullContentPlain,
    i0.Value<int>? rowid,
  }) {
    return i2.HistoryFtsCompanion(
      title: title ?? this.title,
      urlHost: urlHost ?? this.urlHost,
      urlPath: urlPath ?? this.urlPath,
      extractedContentPlain:
          extractedContentPlain ?? this.extractedContentPlain,
      fullContentPlain: fullContentPlain ?? this.fullContentPlain,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (title.present) {
      map['title'] = i0.Variable<String>(title.value);
    }
    if (urlHost.present) {
      map['url_host'] = i0.Variable<String>(urlHost.value);
    }
    if (urlPath.present) {
      map['url_path'] = i0.Variable<String>(urlPath.value);
    }
    if (extractedContentPlain.present) {
      map['extracted_content_plain'] = i0.Variable<String>(
        extractedContentPlain.value,
      );
    }
    if (fullContentPlain.present) {
      map['full_content_plain'] = i0.Variable<String>(fullContentPlain.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoryFtsCompanion(')
          ..write('title: $title, ')
          ..write('urlHost: $urlHost, ')
          ..write('urlPath: $urlPath, ')
          ..write('extractedContentPlain: $extractedContentPlain, ')
          ..write('fullContentPlain: $fullContentPlain, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

i0.Trigger get historyAfterInsert => i0.Trigger(
  'CREATE TRIGGER history_after_insert AFTER INSERT ON history BEGIN INSERT INTO history_fts ("rowid", title, url_host, url_path, extracted_content_plain, full_content_plain) VALUES (new."rowid", new.title, new.url_host, new.url_path, new.extracted_content_plain, new.full_content_plain);END',
  'history_after_insert',
);
i0.Trigger get historyAfterDelete => i0.Trigger(
  'CREATE TRIGGER history_after_delete AFTER DELETE ON history BEGIN INSERT INTO history_fts (history_fts, "rowid", title, url_host, url_path, extracted_content_plain, full_content_plain) VALUES (\'delete\', old."rowid", old.title, old.url_host, old.url_path, old.extracted_content_plain, old.full_content_plain);END',
  'history_after_delete',
);
i0.Trigger get historyAfterUpdate => i0.Trigger(
  'CREATE TRIGGER history_after_update AFTER UPDATE OF title, url_host, url_path, extracted_content_plain, full_content_plain ON history BEGIN INSERT INTO history_fts (history_fts, "rowid", title, url_host, url_path, extracted_content_plain, full_content_plain) VALUES (\'delete\', old."rowid", old.title, old.url_host, old.url_path, old.extracted_content_plain, old.full_content_plain);INSERT INTO history_fts ("rowid", title, url_host, url_path, extracted_content_plain, full_content_plain) VALUES (new."rowid", new.title, new.url_host, new.url_path, new.extracted_content_plain, new.full_content_plain);END',
  'history_after_update',
);
i0.Trigger get tabToHistoryOnInsert => i0.Trigger(
  'CREATE TRIGGER tab_to_history_on_insert AFTER INSERT ON tab WHEN NEW.url IS NOT NULL AND url_indexable(CAST(NEW.url AS TEXT)) = 1 AND (SELECT value FROM local_index_setting WHERE "key" = \'enabled\') = 1 AND(NEW.tab_mode != 1 OR (SELECT value FROM local_index_setting WHERE "key" = \'index_private\') = 1)AND NOT EXISTS (SELECT 1 FROM container_local AS cl WHERE cl.container_id = NEW.container_id AND(cl.exclude_from_index = 1 OR cl.exclude_from_history = 1)) BEGIN INSERT INTO history (url_canonical, url_host, url_path, title, is_probably_readerable, extracted_content_markdown, extracted_content_plain, full_content_markdown, full_content_plain, content_hash, observed_at, observed_count) VALUES (url_canonical(CAST(NEW.url AS TEXT)), url_host(CAST(NEW.url AS TEXT)), url_path(CAST(NEW.url AS TEXT)), NEW.title, NEW.is_probably_readerable, NEW.extracted_content_markdown, NEW.extracted_content_plain, NEW.full_content_markdown, NEW.full_content_plain, NEW.content_hash, strftime(\'%s\', \'now\') * 1000, 1) ON CONFLICT (url_canonical) DO UPDATE SET title = COALESCE(excluded.title, history.title), is_probably_readerable = excluded.is_probably_readerable, extracted_content_markdown = excluded.extracted_content_markdown, extracted_content_plain = excluded.extracted_content_plain, full_content_markdown = excluded.full_content_markdown, full_content_plain = excluded.full_content_plain, content_hash = excluded.content_hash, observed_at = excluded.observed_at, observed_count = history.observed_count + 1 WHERE history.content_hash IS NOT excluded.content_hash;END',
  'tab_to_history_on_insert',
);
i0.Trigger get tabToHistoryOnUpdate => i0.Trigger(
  'CREATE TRIGGER tab_to_history_on_update AFTER UPDATE OF title, url, extracted_content_plain, extracted_content_markdown, full_content_plain, full_content_markdown, is_probably_readerable ON tab WHEN NEW.url IS NOT NULL AND url_indexable(CAST(NEW.url AS TEXT)) = 1 AND(OLD.content_hash IS NOT NEW.content_hash OR OLD.url IS NOT NEW.url)AND (SELECT value FROM local_index_setting WHERE "key" = \'enabled\') = 1 AND(NEW.tab_mode != 1 OR (SELECT value FROM local_index_setting WHERE "key" = \'index_private\') = 1)AND NOT EXISTS (SELECT 1 FROM container_local AS cl WHERE cl.container_id = NEW.container_id AND(cl.exclude_from_index = 1 OR cl.exclude_from_history = 1)) BEGIN INSERT INTO history (url_canonical, url_host, url_path, title, is_probably_readerable, extracted_content_markdown, extracted_content_plain, full_content_markdown, full_content_plain, content_hash, observed_at, observed_count) VALUES (url_canonical(CAST(NEW.url AS TEXT)), url_host(CAST(NEW.url AS TEXT)), url_path(CAST(NEW.url AS TEXT)), NEW.title, NEW.is_probably_readerable, NEW.extracted_content_markdown, NEW.extracted_content_plain, NEW.full_content_markdown, NEW.full_content_plain, NEW.content_hash, strftime(\'%s\', \'now\') * 1000, 1) ON CONFLICT (url_canonical) DO UPDATE SET title = COALESCE(excluded.title, history.title), is_probably_readerable = excluded.is_probably_readerable, extracted_content_markdown = excluded.extracted_content_markdown, extracted_content_plain = excluded.extracted_content_plain, full_content_markdown = excluded.full_content_markdown, full_content_plain = excluded.full_content_plain, content_hash = excluded.content_hash, observed_at = excluded.observed_at, observed_count = history.observed_count + 1 WHERE history.content_hash IS NOT excluded.content_hash;END',
  'tab_to_history_on_update',
);
i0.Trigger get tabToHistoryOnContainerUpdate => i0.Trigger(
  'CREATE TRIGGER tab_to_history_on_container_update AFTER UPDATE OF container_id ON tab WHEN NEW.url IS NOT NULL AND url_indexable(CAST(NEW.url AS TEXT)) = 1 AND (SELECT value FROM local_index_setting WHERE "key" = \'enabled\') = 1 BEGIN DELETE FROM history WHERE url_canonical = url_canonical(CAST(NEW.url AS TEXT)) AND NOT EXISTS (SELECT 1 FROM tab AS candidate WHERE candidate.url IS NOT NULL AND url_indexable(CAST(candidate.url AS TEXT)) = 1 AND url_canonical(CAST(candidate.url AS TEXT)) = history.url_canonical AND(candidate.tab_mode != 1 OR (SELECT value FROM local_index_setting WHERE "key" = \'index_private\') = 1)AND NOT EXISTS (SELECT 1 FROM container_local AS cl WHERE cl.container_id = candidate.container_id AND(cl.exclude_from_index = 1 OR cl.exclude_from_history = 1)));INSERT INTO history (url_canonical, url_host, url_path, title, is_probably_readerable, extracted_content_markdown, extracted_content_plain, full_content_markdown, full_content_plain, content_hash, observed_at, observed_count) SELECT url_canonical(CAST(candidate.url AS TEXT)), url_host(CAST(candidate.url AS TEXT)), url_path(CAST(candidate.url AS TEXT)), candidate.title, candidate.is_probably_readerable, candidate.extracted_content_markdown, candidate.extracted_content_plain, candidate.full_content_markdown, candidate.full_content_plain, candidate.content_hash, strftime(\'%s\', \'now\') * 1000, 1 FROM tab AS candidate WHERE candidate.url IS NOT NULL AND url_indexable(CAST(candidate.url AS TEXT)) = 1 AND url_canonical(CAST(candidate.url AS TEXT)) = url_canonical(CAST(NEW.url AS TEXT)) AND(candidate.tab_mode != 1 OR (SELECT value FROM local_index_setting WHERE "key" = \'index_private\') = 1)AND NOT EXISTS (SELECT 1 FROM container_local AS cl WHERE cl.container_id = candidate.container_id AND(cl.exclude_from_index = 1 OR cl.exclude_from_history = 1)) ORDER BY candidate.timestamp DESC, candidate."rowid" DESC LIMIT 1 ON CONFLICT (url_canonical) DO UPDATE SET title = COALESCE(excluded.title, history.title), is_probably_readerable = excluded.is_probably_readerable, extracted_content_markdown = excluded.extracted_content_markdown, extracted_content_plain = excluded.extracted_content_plain, full_content_markdown = excluded.full_content_markdown, full_content_plain = excluded.full_content_plain, content_hash = excluded.content_hash, observed_at = excluded.observed_at, observed_count = history.observed_count + 1;END',
  'tab_to_history_on_container_update',
);
i0.Trigger get containerLocalToHistoryOnInsert => i0.Trigger(
  'CREATE TRIGGER container_local_to_history_on_insert AFTER INSERT ON container_local WHEN(NEW.exclude_from_index = 1 OR NEW.exclude_from_history = 1)AND (SELECT value FROM local_index_setting WHERE "key" = \'enabled\') = 1 BEGIN DELETE FROM history WHERE url_canonical IN (SELECT DISTINCT url_canonical(CAST(affected.url AS TEXT)) FROM tab AS affected WHERE affected.container_id = NEW.container_id AND affected.url IS NOT NULL AND url_indexable(CAST(affected.url AS TEXT)) = 1) AND NOT EXISTS (SELECT 1 FROM tab AS candidate WHERE candidate.url IS NOT NULL AND url_indexable(CAST(candidate.url AS TEXT)) = 1 AND url_canonical(CAST(candidate.url AS TEXT)) = history.url_canonical AND(candidate.tab_mode != 1 OR (SELECT value FROM local_index_setting WHERE "key" = \'index_private\') = 1)AND NOT EXISTS (SELECT 1 FROM container_local AS cl WHERE cl.container_id = candidate.container_id AND(cl.exclude_from_index = 1 OR cl.exclude_from_history = 1)));INSERT INTO history (url_canonical, url_host, url_path, title, is_probably_readerable, extracted_content_markdown, extracted_content_plain, full_content_markdown, full_content_plain, content_hash, observed_at, observed_count) SELECT url_canonical(CAST(candidate.url AS TEXT)), url_host(CAST(candidate.url AS TEXT)), url_path(CAST(candidate.url AS TEXT)), candidate.title, candidate.is_probably_readerable, candidate.extracted_content_markdown, candidate.extracted_content_plain, candidate.full_content_markdown, candidate.full_content_plain, candidate.content_hash, strftime(\'%s\', \'now\') * 1000, 1 FROM tab AS candidate WHERE candidate.url IS NOT NULL AND url_indexable(CAST(candidate.url AS TEXT)) = 1 AND url_canonical(CAST(candidate.url AS TEXT)) IN (SELECT DISTINCT url_canonical(CAST(affected.url AS TEXT)) FROM tab AS affected WHERE affected.container_id = NEW.container_id AND affected.url IS NOT NULL AND url_indexable(CAST(affected.url AS TEXT)) = 1) AND(candidate.tab_mode != 1 OR (SELECT value FROM local_index_setting WHERE "key" = \'index_private\') = 1)AND NOT EXISTS (SELECT 1 FROM container_local AS cl WHERE cl.container_id = candidate.container_id AND(cl.exclude_from_index = 1 OR cl.exclude_from_history = 1)) AND NOT EXISTS (SELECT 1 FROM tab AS newer WHERE newer.url IS NOT NULL AND url_indexable(CAST(newer.url AS TEXT)) = 1 AND url_canonical(CAST(newer.url AS TEXT)) = url_canonical(CAST(candidate.url AS TEXT)) AND(newer.tab_mode != 1 OR (SELECT value FROM local_index_setting WHERE "key" = \'index_private\') = 1)AND NOT EXISTS (SELECT 1 FROM container_local AS cl2 WHERE cl2.container_id = newer.container_id AND(cl2.exclude_from_index = 1 OR cl2.exclude_from_history = 1)) AND(newer.timestamp > candidate.timestamp OR(newer.timestamp = candidate.timestamp AND newer."rowid" > candidate."rowid"))) ON CONFLICT (url_canonical) DO UPDATE SET title = COALESCE(excluded.title, history.title), is_probably_readerable = excluded.is_probably_readerable, extracted_content_markdown = excluded.extracted_content_markdown, extracted_content_plain = excluded.extracted_content_plain, full_content_markdown = excluded.full_content_markdown, full_content_plain = excluded.full_content_plain, content_hash = excluded.content_hash, observed_at = excluded.observed_at, observed_count = history.observed_count + 1;END',
  'container_local_to_history_on_insert',
);
i0.Trigger get containerLocalToHistoryOnUpdate => i0.Trigger(
  'CREATE TRIGGER container_local_to_history_on_update AFTER UPDATE OF exclude_from_index, exclude_from_history ON container_local WHEN(OLD.exclude_from_index = 1 OR OLD.exclude_from_history = 1)!=(NEW.exclude_from_index = 1 OR NEW.exclude_from_history = 1)AND (SELECT value FROM local_index_setting WHERE "key" = \'enabled\') = 1 BEGIN DELETE FROM history WHERE url_canonical IN (SELECT DISTINCT url_canonical(CAST(affected.url AS TEXT)) FROM tab AS affected WHERE affected.container_id = NEW.container_id AND affected.url IS NOT NULL AND url_indexable(CAST(affected.url AS TEXT)) = 1) AND NOT EXISTS (SELECT 1 FROM tab AS candidate WHERE candidate.url IS NOT NULL AND url_indexable(CAST(candidate.url AS TEXT)) = 1 AND url_canonical(CAST(candidate.url AS TEXT)) = history.url_canonical AND(candidate.tab_mode != 1 OR (SELECT value FROM local_index_setting WHERE "key" = \'index_private\') = 1)AND NOT EXISTS (SELECT 1 FROM container_local AS cl WHERE cl.container_id = candidate.container_id AND(cl.exclude_from_index = 1 OR cl.exclude_from_history = 1)));INSERT INTO history (url_canonical, url_host, url_path, title, is_probably_readerable, extracted_content_markdown, extracted_content_plain, full_content_markdown, full_content_plain, content_hash, observed_at, observed_count) SELECT url_canonical(CAST(candidate.url AS TEXT)), url_host(CAST(candidate.url AS TEXT)), url_path(CAST(candidate.url AS TEXT)), candidate.title, candidate.is_probably_readerable, candidate.extracted_content_markdown, candidate.extracted_content_plain, candidate.full_content_markdown, candidate.full_content_plain, candidate.content_hash, strftime(\'%s\', \'now\') * 1000, 1 FROM tab AS candidate WHERE candidate.url IS NOT NULL AND url_indexable(CAST(candidate.url AS TEXT)) = 1 AND url_canonical(CAST(candidate.url AS TEXT)) IN (SELECT DISTINCT url_canonical(CAST(affected.url AS TEXT)) FROM tab AS affected WHERE affected.container_id = NEW.container_id AND affected.url IS NOT NULL AND url_indexable(CAST(affected.url AS TEXT)) = 1) AND(candidate.tab_mode != 1 OR (SELECT value FROM local_index_setting WHERE "key" = \'index_private\') = 1)AND NOT EXISTS (SELECT 1 FROM container_local AS cl WHERE cl.container_id = candidate.container_id AND(cl.exclude_from_index = 1 OR cl.exclude_from_history = 1)) AND NOT EXISTS (SELECT 1 FROM tab AS newer WHERE newer.url IS NOT NULL AND url_indexable(CAST(newer.url AS TEXT)) = 1 AND url_canonical(CAST(newer.url AS TEXT)) = url_canonical(CAST(candidate.url AS TEXT)) AND(newer.tab_mode != 1 OR (SELECT value FROM local_index_setting WHERE "key" = \'index_private\') = 1)AND NOT EXISTS (SELECT 1 FROM container_local AS cl2 WHERE cl2.container_id = newer.container_id AND(cl2.exclude_from_index = 1 OR cl2.exclude_from_history = 1)) AND(newer.timestamp > candidate.timestamp OR(newer.timestamp = candidate.timestamp AND newer."rowid" > candidate."rowid"))) ON CONFLICT (url_canonical) DO UPDATE SET title = COALESCE(excluded.title, history.title), is_probably_readerable = excluded.is_probably_readerable, extracted_content_markdown = excluded.extracted_content_markdown, extracted_content_plain = excluded.extracted_content_plain, full_content_markdown = excluded.full_content_markdown, full_content_plain = excluded.full_content_plain, content_hash = excluded.content_hash, observed_at = excluded.observed_at, observed_count = history.observed_count + 1;END',
  'container_local_to_history_on_update',
);

class VisitContainer extends i0.Table
    with i0.TableInfo<VisitContainer, i2.VisitContainerData> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  VisitContainer(this.attachedDatabase, [this._alias]);
  late final i0.GeneratedColumn<int> id = i0.GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT',
  );
  late final i0.GeneratedColumn<String> rawUrl = i0.GeneratedColumn<String>(
    'raw_url',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final i0.GeneratedColumn<String> urlCanonical =
      i0.GeneratedColumn<String>(
        'url_canonical',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  late final i0.GeneratedColumn<int> visitTime = i0.GeneratedColumn<int>(
    'visit_time',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final i0.GeneratedColumn<String> containerId =
      i0.GeneratedColumn<String>(
        'container_id',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints:
            'NOT NULL REFERENCES container(id)ON DELETE CASCADE',
      );
  @override
  List<i0.GeneratedColumn> get $columns => [
    id,
    rawUrl,
    urlCanonical,
    visitTime,
    containerId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visit_container';
  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i2.VisitContainerData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i2.VisitContainerData(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      rawUrl: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}raw_url'],
      )!,
      urlCanonical: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}url_canonical'],
      )!,
      visitTime: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}visit_time'],
      )!,
      containerId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}container_id'],
      )!,
    );
  }

  @override
  VisitContainer createAlias(String alias) {
    return VisitContainer(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class VisitContainerData extends i0.DataClass
    implements i0.Insertable<i2.VisitContainerData> {
  final int id;

  /// Original visited URL; used to open the page and as the key for the Places
  /// delete mirror (Places keys visits by URL + time).
  final String rawUrl;

  /// Structural canonical form; the join key to Places visits (computed in Dart
  /// via canonicalizeUrl so it matches the local index's canonicalization).
  final String urlCanonical;

  /// Epoch MILLISECONDS (plain INTEGER, not a drift DATETIME which stores
  /// seconds). Matches Places `VisitInfo.visitTime`.
  final int visitTime;
  final String containerId;
  const VisitContainerData({
    required this.id,
    required this.rawUrl,
    required this.urlCanonical,
    required this.visitTime,
    required this.containerId,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['raw_url'] = i0.Variable<String>(rawUrl);
    map['url_canonical'] = i0.Variable<String>(urlCanonical);
    map['visit_time'] = i0.Variable<int>(visitTime);
    map['container_id'] = i0.Variable<String>(containerId);
    return map;
  }

  factory VisitContainerData.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return VisitContainerData(
      id: serializer.fromJson<int>(json['id']),
      rawUrl: serializer.fromJson<String>(json['raw_url']),
      urlCanonical: serializer.fromJson<String>(json['url_canonical']),
      visitTime: serializer.fromJson<int>(json['visit_time']),
      containerId: serializer.fromJson<String>(json['container_id']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'raw_url': serializer.toJson<String>(rawUrl),
      'url_canonical': serializer.toJson<String>(urlCanonical),
      'visit_time': serializer.toJson<int>(visitTime),
      'container_id': serializer.toJson<String>(containerId),
    };
  }

  i2.VisitContainerData copyWith({
    int? id,
    String? rawUrl,
    String? urlCanonical,
    int? visitTime,
    String? containerId,
  }) => i2.VisitContainerData(
    id: id ?? this.id,
    rawUrl: rawUrl ?? this.rawUrl,
    urlCanonical: urlCanonical ?? this.urlCanonical,
    visitTime: visitTime ?? this.visitTime,
    containerId: containerId ?? this.containerId,
  );
  VisitContainerData copyWithCompanion(i2.VisitContainerCompanion data) {
    return VisitContainerData(
      id: data.id.present ? data.id.value : this.id,
      rawUrl: data.rawUrl.present ? data.rawUrl.value : this.rawUrl,
      urlCanonical: data.urlCanonical.present
          ? data.urlCanonical.value
          : this.urlCanonical,
      visitTime: data.visitTime.present ? data.visitTime.value : this.visitTime,
      containerId: data.containerId.present
          ? data.containerId.value
          : this.containerId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VisitContainerData(')
          ..write('id: $id, ')
          ..write('rawUrl: $rawUrl, ')
          ..write('urlCanonical: $urlCanonical, ')
          ..write('visitTime: $visitTime, ')
          ..write('containerId: $containerId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, rawUrl, urlCanonical, visitTime, containerId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i2.VisitContainerData &&
          other.id == this.id &&
          other.rawUrl == this.rawUrl &&
          other.urlCanonical == this.urlCanonical &&
          other.visitTime == this.visitTime &&
          other.containerId == this.containerId);
}

class VisitContainerCompanion
    extends i0.UpdateCompanion<i2.VisitContainerData> {
  final i0.Value<int> id;
  final i0.Value<String> rawUrl;
  final i0.Value<String> urlCanonical;
  final i0.Value<int> visitTime;
  final i0.Value<String> containerId;
  const VisitContainerCompanion({
    this.id = const i0.Value.absent(),
    this.rawUrl = const i0.Value.absent(),
    this.urlCanonical = const i0.Value.absent(),
    this.visitTime = const i0.Value.absent(),
    this.containerId = const i0.Value.absent(),
  });
  VisitContainerCompanion.insert({
    this.id = const i0.Value.absent(),
    required String rawUrl,
    required String urlCanonical,
    required int visitTime,
    required String containerId,
  }) : rawUrl = i0.Value(rawUrl),
       urlCanonical = i0.Value(urlCanonical),
       visitTime = i0.Value(visitTime),
       containerId = i0.Value(containerId);
  static i0.Insertable<i2.VisitContainerData> custom({
    i0.Expression<int>? id,
    i0.Expression<String>? rawUrl,
    i0.Expression<String>? urlCanonical,
    i0.Expression<int>? visitTime,
    i0.Expression<String>? containerId,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (rawUrl != null) 'raw_url': rawUrl,
      if (urlCanonical != null) 'url_canonical': urlCanonical,
      if (visitTime != null) 'visit_time': visitTime,
      if (containerId != null) 'container_id': containerId,
    });
  }

  i2.VisitContainerCompanion copyWith({
    i0.Value<int>? id,
    i0.Value<String>? rawUrl,
    i0.Value<String>? urlCanonical,
    i0.Value<int>? visitTime,
    i0.Value<String>? containerId,
  }) {
    return i2.VisitContainerCompanion(
      id: id ?? this.id,
      rawUrl: rawUrl ?? this.rawUrl,
      urlCanonical: urlCanonical ?? this.urlCanonical,
      visitTime: visitTime ?? this.visitTime,
      containerId: containerId ?? this.containerId,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value);
    }
    if (rawUrl.present) {
      map['raw_url'] = i0.Variable<String>(rawUrl.value);
    }
    if (urlCanonical.present) {
      map['url_canonical'] = i0.Variable<String>(urlCanonical.value);
    }
    if (visitTime.present) {
      map['visit_time'] = i0.Variable<int>(visitTime.value);
    }
    if (containerId.present) {
      map['container_id'] = i0.Variable<String>(containerId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitContainerCompanion(')
          ..write('id: $id, ')
          ..write('rawUrl: $rawUrl, ')
          ..write('urlCanonical: $urlCanonical, ')
          ..write('visitTime: $visitTime, ')
          ..write('containerId: $containerId')
          ..write(')'))
        .toString();
  }
}

i0.Index get idxVcCanonical => i0.Index(
  'idx_vc_canonical',
  'CREATE INDEX idx_vc_canonical ON visit_container (url_canonical, visit_time)',
);
i0.Index get idxVcContainer => i0.Index(
  'idx_vc_container',
  'CREATE INDEX idx_vc_container ON visit_container (container_id, visit_time DESC)',
);

class ForeignRecord extends i0.Table
    with i0.TableInfo<ForeignRecord, i2.ForeignRecordData> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  ForeignRecord(this.attachedDatabase, [this._alias]);
  late final i0.GeneratedColumn<String> id = i0.GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  late final i0.GeneratedColumn<String> kind = i0.GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final i0.GeneratedColumn<String> payload = i0.GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final i0.GeneratedColumn<double> modified = i0.GeneratedColumn<double>(
    'modified',
    aliasedName,
    false,
    type: i0.DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<i0.GeneratedColumn> get $columns => [id, kind, payload, modified];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'foreign_record';
  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i2.ForeignRecordData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i2.ForeignRecordData(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      modified: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.double,
        data['${effectivePrefix}modified'],
      )!,
    );
  }

  @override
  ForeignRecord createAlias(String alias) {
    return ForeignRecord(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ForeignRecordData extends i0.DataClass
    implements i0.Insertable<i2.ForeignRecordData> {
  final String id;
  final String kind;
  final String payload;
  final double modified;
  const ForeignRecordData({
    required this.id,
    required this.kind,
    required this.payload,
    required this.modified,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<String>(id);
    map['kind'] = i0.Variable<String>(kind);
    map['payload'] = i0.Variable<String>(payload);
    map['modified'] = i0.Variable<double>(modified);
    return map;
  }

  factory ForeignRecordData.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return ForeignRecordData(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      payload: serializer.fromJson<String>(json['payload']),
      modified: serializer.fromJson<double>(json['modified']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'payload': serializer.toJson<String>(payload),
      'modified': serializer.toJson<double>(modified),
    };
  }

  i2.ForeignRecordData copyWith({
    String? id,
    String? kind,
    String? payload,
    double? modified,
  }) => i2.ForeignRecordData(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    payload: payload ?? this.payload,
    modified: modified ?? this.modified,
  );
  ForeignRecordData copyWithCompanion(i2.ForeignRecordCompanion data) {
    return ForeignRecordData(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      payload: data.payload.present ? data.payload.value : this.payload,
      modified: data.modified.present ? data.modified.value : this.modified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ForeignRecordData(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('payload: $payload, ')
          ..write('modified: $modified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kind, payload, modified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i2.ForeignRecordData &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.payload == this.payload &&
          other.modified == this.modified);
}

class ForeignRecordCompanion extends i0.UpdateCompanion<i2.ForeignRecordData> {
  final i0.Value<String> id;
  final i0.Value<String> kind;
  final i0.Value<String> payload;
  final i0.Value<double> modified;
  final i0.Value<int> rowid;
  const ForeignRecordCompanion({
    this.id = const i0.Value.absent(),
    this.kind = const i0.Value.absent(),
    this.payload = const i0.Value.absent(),
    this.modified = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  ForeignRecordCompanion.insert({
    required String id,
    required String kind,
    required String payload,
    required double modified,
    this.rowid = const i0.Value.absent(),
  }) : id = i0.Value(id),
       kind = i0.Value(kind),
       payload = i0.Value(payload),
       modified = i0.Value(modified);
  static i0.Insertable<i2.ForeignRecordData> custom({
    i0.Expression<String>? id,
    i0.Expression<String>? kind,
    i0.Expression<String>? payload,
    i0.Expression<double>? modified,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (payload != null) 'payload': payload,
      if (modified != null) 'modified': modified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i2.ForeignRecordCompanion copyWith({
    i0.Value<String>? id,
    i0.Value<String>? kind,
    i0.Value<String>? payload,
    i0.Value<double>? modified,
    i0.Value<int>? rowid,
  }) {
    return i2.ForeignRecordCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      payload: payload ?? this.payload,
      modified: modified ?? this.modified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = i0.Variable<String>(kind.value);
    }
    if (payload.present) {
      map['payload'] = i0.Variable<String>(payload.value);
    }
    if (modified.present) {
      map['modified'] = i0.Variable<double>(modified.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ForeignRecordCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('payload: $payload, ')
          ..write('modified: $modified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SyncRecordState extends i0.Table
    with i0.TableInfo<SyncRecordState, i2.SyncRecordStateData> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  SyncRecordState(this.attachedDatabase, [this._alias]);
  late final i0.GeneratedColumn<String> recordId = i0.GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  late final i0.GeneratedColumn<String> kind = i0.GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final i0.GeneratedColumn<String> digest = i0.GeneratedColumn<String>(
    'digest',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<i0.GeneratedColumn> get $columns => [recordId, kind, digest];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_record_state';
  @override
  Set<i0.GeneratedColumn> get $primaryKey => {recordId};
  @override
  i2.SyncRecordStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i2.SyncRecordStateData(
      recordId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      digest: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}digest'],
      )!,
    );
  }

  @override
  SyncRecordState createAlias(String alias) {
    return SyncRecordState(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SyncRecordStateData extends i0.DataClass
    implements i0.Insertable<i2.SyncRecordStateData> {
  final String recordId;
  final String kind;
  final String digest;
  const SyncRecordStateData({
    required this.recordId,
    required this.kind,
    required this.digest,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['record_id'] = i0.Variable<String>(recordId);
    map['kind'] = i0.Variable<String>(kind);
    map['digest'] = i0.Variable<String>(digest);
    return map;
  }

  factory SyncRecordStateData.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return SyncRecordStateData(
      recordId: serializer.fromJson<String>(json['record_id']),
      kind: serializer.fromJson<String>(json['kind']),
      digest: serializer.fromJson<String>(json['digest']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'record_id': serializer.toJson<String>(recordId),
      'kind': serializer.toJson<String>(kind),
      'digest': serializer.toJson<String>(digest),
    };
  }

  i2.SyncRecordStateData copyWith({
    String? recordId,
    String? kind,
    String? digest,
  }) => i2.SyncRecordStateData(
    recordId: recordId ?? this.recordId,
    kind: kind ?? this.kind,
    digest: digest ?? this.digest,
  );
  SyncRecordStateData copyWithCompanion(i2.SyncRecordStateCompanion data) {
    return SyncRecordStateData(
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      kind: data.kind.present ? data.kind.value : this.kind,
      digest: data.digest.present ? data.digest.value : this.digest,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncRecordStateData(')
          ..write('recordId: $recordId, ')
          ..write('kind: $kind, ')
          ..write('digest: $digest')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(recordId, kind, digest);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i2.SyncRecordStateData &&
          other.recordId == this.recordId &&
          other.kind == this.kind &&
          other.digest == this.digest);
}

class SyncRecordStateCompanion
    extends i0.UpdateCompanion<i2.SyncRecordStateData> {
  final i0.Value<String> recordId;
  final i0.Value<String> kind;
  final i0.Value<String> digest;
  final i0.Value<int> rowid;
  const SyncRecordStateCompanion({
    this.recordId = const i0.Value.absent(),
    this.kind = const i0.Value.absent(),
    this.digest = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  SyncRecordStateCompanion.insert({
    required String recordId,
    required String kind,
    required String digest,
    this.rowid = const i0.Value.absent(),
  }) : recordId = i0.Value(recordId),
       kind = i0.Value(kind),
       digest = i0.Value(digest);
  static i0.Insertable<i2.SyncRecordStateData> custom({
    i0.Expression<String>? recordId,
    i0.Expression<String>? kind,
    i0.Expression<String>? digest,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (recordId != null) 'record_id': recordId,
      if (kind != null) 'kind': kind,
      if (digest != null) 'digest': digest,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i2.SyncRecordStateCompanion copyWith({
    i0.Value<String>? recordId,
    i0.Value<String>? kind,
    i0.Value<String>? digest,
    i0.Value<int>? rowid,
  }) {
    return i2.SyncRecordStateCompanion(
      recordId: recordId ?? this.recordId,
      kind: kind ?? this.kind,
      digest: digest ?? this.digest,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (recordId.present) {
      map['record_id'] = i0.Variable<String>(recordId.value);
    }
    if (kind.present) {
      map['kind'] = i0.Variable<String>(kind.value);
    }
    if (digest.present) {
      map['digest'] = i0.Variable<String>(digest.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncRecordStateCompanion(')
          ..write('recordId: $recordId, ')
          ..write('kind: $kind, ')
          ..write('digest: $digest, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DeletedRecord extends i0.Table
    with i0.TableInfo<DeletedRecord, i2.DeletedRecordData> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  DeletedRecord(this.attachedDatabase, [this._alias]);
  late final i0.GeneratedColumn<String> id = i0.GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  late final i0.GeneratedColumn<String> kind = i0.GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final i0.GeneratedColumn<DateTime> deletedAt =
      i0.GeneratedColumn<DateTime>(
        'deleted_at',
        aliasedName,
        false,
        type: i0.DriftSqlType.dateTime,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  @override
  List<i0.GeneratedColumn> get $columns => [id, kind, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deleted_record';
  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i2.DeletedRecordData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i2.DeletedRecordData(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      )!,
    );
  }

  @override
  DeletedRecord createAlias(String alias) {
    return DeletedRecord(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class DeletedRecordData extends i0.DataClass
    implements i0.Insertable<i2.DeletedRecordData> {
  final String id;
  final String kind;
  final DateTime deletedAt;
  const DeletedRecordData({
    required this.id,
    required this.kind,
    required this.deletedAt,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<String>(id);
    map['kind'] = i0.Variable<String>(kind);
    map['deleted_at'] = i0.Variable<DateTime>(deletedAt);
    return map;
  }

  factory DeletedRecordData.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return DeletedRecordData(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      deletedAt: serializer.fromJson<DateTime>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'deleted_at': serializer.toJson<DateTime>(deletedAt),
    };
  }

  i2.DeletedRecordData copyWith({
    String? id,
    String? kind,
    DateTime? deletedAt,
  }) => i2.DeletedRecordData(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    deletedAt: deletedAt ?? this.deletedAt,
  );
  DeletedRecordData copyWithCompanion(i2.DeletedRecordCompanion data) {
    return DeletedRecordData(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeletedRecordData(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kind, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i2.DeletedRecordData &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.deletedAt == this.deletedAt);
}

class DeletedRecordCompanion extends i0.UpdateCompanion<i2.DeletedRecordData> {
  final i0.Value<String> id;
  final i0.Value<String> kind;
  final i0.Value<DateTime> deletedAt;
  final i0.Value<int> rowid;
  const DeletedRecordCompanion({
    this.id = const i0.Value.absent(),
    this.kind = const i0.Value.absent(),
    this.deletedAt = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  DeletedRecordCompanion.insert({
    required String id,
    required String kind,
    required DateTime deletedAt,
    this.rowid = const i0.Value.absent(),
  }) : id = i0.Value(id),
       kind = i0.Value(kind),
       deletedAt = i0.Value(deletedAt);
  static i0.Insertable<i2.DeletedRecordData> custom({
    i0.Expression<String>? id,
    i0.Expression<String>? kind,
    i0.Expression<DateTime>? deletedAt,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i2.DeletedRecordCompanion copyWith({
    i0.Value<String>? id,
    i0.Value<String>? kind,
    i0.Value<DateTime>? deletedAt,
    i0.Value<int>? rowid,
  }) {
    return i2.DeletedRecordCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = i0.Variable<String>(kind.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = i0.Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeletedRecordCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DefinitionsDrift extends i11.ModularAccessor {
  DefinitionsDrift(i0.GeneratedDatabase db) : super(db);
  Future<int> optimizeFtsIndex() {
    return customInsert(
      'INSERT INTO tab_fts (tab_fts) VALUES (\'optimize\')',
      variables: [],
      updates: {tabFts},
    );
  }

  Future<int> optimizeHistoryFtsIndex() {
    return customInsert(
      'INSERT INTO history_fts (history_fts) VALUES (\'optimize\')',
      variables: [],
      updates: {historyFts},
    );
  }

  i0.Selectable<i12.HistoryQueryResult> queryHistoryFullContent({
    required String beforeMatch,
    required String afterMatch,
    required String ellipsis,
    required int snippetLength,
    required String query,
    required int limit,
  }) {
    return customSelect(
      'WITH weights AS (SELECT 10.0 AS title_weight, 8.0 AS host_weight, 2.0 AS path_weight, 3.0 AS extracted_weight, 1.0 AS full_weight) SELECT h.url_canonical, h.url_host, h.url_path, highlight(history_fts, 0, ?1, ?2) AS title, snippet(history_fts, 3, ?1, ?2, ?3, ?4) AS extracted_content, snippet(history_fts, 4, ?1, ?2, ?3, ?4) AS full_content, h.observed_at, bm25(history_fts, weights.title_weight, weights.host_weight, weights.path_weight, weights.extracted_weight, weights.full_weight) AS weighted_rank FROM history_fts(?5)AS fts INNER JOIN history AS h ON h."rowid" = fts."rowid" CROSS JOIN weights ORDER BY weighted_rank ASC, h.observed_at DESC LIMIT ?6',
      variables: [
        i0.Variable<String>(beforeMatch),
        i0.Variable<String>(afterMatch),
        i0.Variable<String>(ellipsis),
        i0.Variable<int>(snippetLength),
        i0.Variable<String>(query),
        i0.Variable<int>(limit),
      ],
      readsFrom: {history, historyFts},
    ).map(
      (i0.QueryRow row) => i12.HistoryQueryResult(
        urlCanonical: row.read<String>('url_canonical'),
        urlHost: row.read<String>('url_host'),
        urlPath: row.readNullable<String>('url_path'),
        title: row.readNullable<String>('title'),
        extractedContent: row.readNullable<String>('extracted_content'),
        fullContent: row.readNullable<String>('full_content'),
        weightedRank: row.read<double>('weighted_rank'),
        observedAt: row.read<DateTime>('observed_at'),
      ),
    );
  }

  i0.Selectable<i12.HistoryQueryResult> queryHistoryByHostPrefix({
    required String hostPrefix,
    required int limit,
  }) {
    return customSelect(
      'SELECT h.url_canonical, h.url_host, h.url_path, h.title, NULL AS extracted_content, NULL AS full_content, h.observed_at, 0.0 AS weighted_rank FROM history AS h WHERE h.url_host LIKE ?1 ORDER BY h.observed_at DESC LIMIT ?2',
      variables: [i0.Variable<String>(hostPrefix), i0.Variable<int>(limit)],
      readsFrom: {history},
    ).map(
      (i0.QueryRow row) => i12.HistoryQueryResult(
        urlCanonical: row.read<String>('url_canonical'),
        urlHost: row.read<String>('url_host'),
        urlPath: row.readNullable<String>('url_path'),
        title: row.readNullable<String>('title'),
        extractedContent: row.readNullable<String>('extracted_content'),
        fullContent: row.readNullable<String>('full_content'),
        weightedRank: row.read<double>('weighted_rank'),
        observedAt: row.read<DateTime>('observed_at'),
      ),
    );
  }

  i0.Selectable<i12.HistoryQueryResult> historyByCanonicalUrls({
    required List<String> canonicalUrls,
  }) {
    var $arrayStartIndex = 1;
    final expandedcanonicalUrls = $expandVar(
      $arrayStartIndex,
      canonicalUrls.length,
    );
    $arrayStartIndex += canonicalUrls.length;
    return customSelect(
      'SELECT h.url_canonical, h.url_host, h.url_path, h.title, NULL AS extracted_content, NULL AS full_content, h.observed_at, 0.0 AS weighted_rank FROM history AS h WHERE h.url_canonical IN ($expandedcanonicalUrls)',
      variables: [for (var $ in canonicalUrls) i0.Variable<String>($)],
      readsFrom: {history},
    ).map(
      (i0.QueryRow row) => i12.HistoryQueryResult(
        urlCanonical: row.read<String>('url_canonical'),
        urlHost: row.read<String>('url_host'),
        urlPath: row.readNullable<String>('url_path'),
        title: row.readNullable<String>('title'),
        extractedContent: row.readNullable<String>('extracted_content'),
        fullContent: row.readNullable<String>('full_content'),
        weightedRank: row.read<double>('weighted_rank'),
        observedAt: row.read<DateTime>('observed_at'),
      ),
    );
  }

  Future<int> upsertLocalIndexSetting({
    required String key,
    required int value,
  }) {
    return customInsert(
      'INSERT INTO local_index_setting ("key", value) VALUES (?1, ?2) ON CONFLICT ("key") DO UPDATE SET value = excluded.value',
      variables: [i0.Variable<String>(key), i0.Variable<int>(value)],
      updates: {localIndexSetting},
    );
  }

  i0.Selectable<int> countHistoryRows() {
    return customSelect(
      'SELECT COUNT(*) AS count FROM history',
      variables: [],
      readsFrom: {history},
    ).map((i0.QueryRow row) => row.read<int>('count'));
  }

  Future<int> clearHistory() {
    return customUpdate(
      'DELETE FROM history',
      variables: [],
      updates: {history},
      updateKind: i0.UpdateKind.delete,
    );
  }

  i0.Selectable<String> historyUrlsPage({
    required int limit,
    required int offset,
  }) {
    return customSelect(
      'SELECT url_canonical FROM history ORDER BY observed_at ASC, url_canonical ASC LIMIT ?1 OFFSET ?2',
      variables: [i0.Variable<int>(limit), i0.Variable<int>(offset)],
      readsFrom: {history},
    ).map((i0.QueryRow row) => row.read<String>('url_canonical'));
  }

  Future<int> deleteHistoryByCanonicalUrls({
    required List<String> canonicalUrls,
  }) {
    var $arrayStartIndex = 1;
    final expandedcanonicalUrls = $expandVar(
      $arrayStartIndex,
      canonicalUrls.length,
    );
    $arrayStartIndex += canonicalUrls.length;
    return customUpdate(
      'DELETE FROM history WHERE url_canonical IN ($expandedcanonicalUrls)',
      variables: [for (var $ in canonicalUrls) i0.Variable<String>($)],
      updates: {history},
      updateKind: i0.UpdateKind.delete,
    );
  }

  Future<int> evictExcludedHistoryPages() {
    return customUpdate(
      'DELETE FROM history WHERE url_canonical IN (SELECT DISTINCT url_canonical(CAST(affected.url AS TEXT)) FROM tab AS affected LEFT JOIN container_local AS cl ON cl.container_id = affected.container_id WHERE COALESCE(cl.exclude_from_history, 0) = 1 AND affected.url IS NOT NULL AND url_indexable(CAST(affected.url AS TEXT)) = 1) AND NOT EXISTS (SELECT 1 FROM tab AS candidate WHERE candidate.url IS NOT NULL AND url_indexable(CAST(candidate.url AS TEXT)) = 1 AND url_canonical(CAST(candidate.url AS TEXT)) = history.url_canonical AND(candidate.tab_mode != 1 OR (SELECT value FROM local_index_setting WHERE "key" = \'index_private\') = 1)AND NOT EXISTS (SELECT 1 FROM container_local AS cl2 WHERE cl2.container_id = candidate.container_id AND(cl2.exclude_from_index = 1 OR cl2.exclude_from_history = 1)))',
      variables: [],
      updates: {history},
      updateKind: i0.UpdateKind.delete,
    );
  }

  Future<int> reindexAfterExcludedHistoryEviction() {
    return customInsert(
      'INSERT INTO history (url_canonical, url_host, url_path, title, is_probably_readerable, extracted_content_markdown, extracted_content_plain, full_content_markdown, full_content_plain, content_hash, observed_at, observed_count) SELECT url_canonical(CAST(candidate.url AS TEXT)), url_host(CAST(candidate.url AS TEXT)), url_path(CAST(candidate.url AS TEXT)), candidate.title, candidate.is_probably_readerable, candidate.extracted_content_markdown, candidate.extracted_content_plain, candidate.full_content_markdown, candidate.full_content_plain, candidate.content_hash, strftime(\'%s\', \'now\') * 1000, 1 FROM tab AS candidate WHERE (SELECT value FROM local_index_setting WHERE "key" = \'enabled\') = 1 AND candidate.url IS NOT NULL AND url_indexable(CAST(candidate.url AS TEXT)) = 1 AND url_canonical(CAST(candidate.url AS TEXT)) IN (SELECT DISTINCT url_canonical(CAST(affected.url AS TEXT)) FROM tab AS affected LEFT JOIN container_local AS cl ON cl.container_id = affected.container_id WHERE COALESCE(cl.exclude_from_history, 0) = 1 AND affected.url IS NOT NULL AND url_indexable(CAST(affected.url AS TEXT)) = 1) AND(candidate.tab_mode != 1 OR (SELECT value FROM local_index_setting WHERE "key" = \'index_private\') = 1)AND NOT EXISTS (SELECT 1 FROM container_local AS cl2 WHERE cl2.container_id = candidate.container_id AND(cl2.exclude_from_index = 1 OR cl2.exclude_from_history = 1)) AND NOT EXISTS (SELECT 1 FROM tab AS newer WHERE newer.url IS NOT NULL AND url_indexable(CAST(newer.url AS TEXT)) = 1 AND url_canonical(CAST(newer.url AS TEXT)) = url_canonical(CAST(candidate.url AS TEXT)) AND(newer.tab_mode != 1 OR (SELECT value FROM local_index_setting WHERE "key" = \'index_private\') = 1)AND NOT EXISTS (SELECT 1 FROM container_local AS cl3 WHERE cl3.container_id = newer.container_id AND(cl3.exclude_from_index = 1 OR cl3.exclude_from_history = 1)) AND(newer.timestamp > candidate.timestamp OR(newer.timestamp = candidate.timestamp AND newer."rowid" > candidate."rowid"))) ON CONFLICT (url_canonical) DO UPDATE SET title = COALESCE(excluded.title, history.title), is_probably_readerable = excluded.is_probably_readerable, extracted_content_markdown = excluded.extracted_content_markdown, extracted_content_plain = excluded.extracted_content_plain, full_content_markdown = excluded.full_content_markdown, full_content_plain = excluded.full_content_plain, content_hash = excluded.content_hash, observed_at = excluded.observed_at, observed_count = history.observed_count + 1',
      variables: [],
      updates: {history},
    );
  }

  i0.Selectable<i1.ContainerDataWithCount> containersWithCount() {
    return customSelect(
      'SELECT container.*, tab_agg.tab_count FROM container LEFT JOIN (SELECT container_id, COUNT(*) AS tab_count, MAX(timestamp) AS last_updated FROM tab GROUP BY container_id) AS tab_agg ON container.id = tab_agg.container_id ORDER BY container.is_pinned DESC, container.order_key ASC',
      variables: [],
      readsFrom: {container, tab},
    ).map(
      (i0.QueryRow row) => i1.ContainerDataWithCount(
        id: row.read<String>('id'),
        syncGuid: row.readNullable<String>('sync_guid'),
        name: row.read<String>('name'),
        iconKey: row.read<String>('icon_key'),
        colorKey: row.read<String>('color_key'),
        orderKey: row.read<String>('order_key'),
        isPinned: row.read<bool>('is_pinned'),
        tabCount: row.readNullable<int>('tab_count'),
      ),
    );
  }

  i0.Selectable<String> containerIdsByLastUpdated() {
    return customSelect(
      'SELECT container.id FROM container LEFT JOIN (SELECT container_id, MAX(timestamp) AS last_updated FROM tab GROUP BY container_id) AS tab_agg ON container.id = tab_agg.container_id ORDER BY tab_agg.last_updated DESC NULLS LAST, container."rowid" ASC',
      variables: [],
      readsFrom: {container, tab},
    ).map((i0.QueryRow row) => row.read<String>('id'));
  }

  i0.Selectable<String> leadingContainerOrderKey({
    required int bucket,
    required bool isPinned,
  }) {
    return customSelect(
      'SELECT lexo_rank_previous(?1, (SELECT order_key FROM container WHERE is_pinned = ?2 ORDER BY order_key LIMIT 1)) AS _c0',
      variables: [i0.Variable<int>(bucket), i0.Variable<bool>(isPinned)],
      readsFrom: {container},
    ).map((i0.QueryRow row) => row.read<String>('_c0'));
  }

  i0.Selectable<String> trailingContainerOrderKey({
    required int bucket,
    required bool isPinned,
  }) {
    return customSelect(
      'SELECT lexo_rank_next(?1, (SELECT order_key FROM container WHERE is_pinned = ?2 ORDER BY order_key DESC LIMIT 1)) AS _c0',
      variables: [i0.Variable<int>(bucket), i0.Variable<bool>(isPinned)],
      readsFrom: {container},
    ).map((i0.QueryRow row) => row.read<String>('_c0'));
  }

  i0.Selectable<String> containerOrderKeyAfter({
    required bool isPinned,
    required String containerId,
  }) {
    return customSelect(
      'WITH ordered_table AS (SELECT id, order_key, LEAD(order_key)OVER (ORDER BY order_key RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW EXCLUDE NO OTHERS) AS next_order_key FROM container WHERE is_pinned = ?1) SELECT lexo_rank_reorder_after(order_key, next_order_key) AS _c0 FROM ordered_table WHERE id = ?2',
      variables: [
        i0.Variable<bool>(isPinned),
        i0.Variable<String>(containerId),
      ],
      readsFrom: {container},
    ).map((i0.QueryRow row) => row.read<String>('_c0'));
  }

  i0.Selectable<String> containerOrderKeyBefore({
    required bool isPinned,
    required String containerId,
  }) {
    return customSelect(
      'WITH ordered_table AS (SELECT id, order_key, LAG(order_key)OVER (ORDER BY order_key RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW EXCLUDE NO OTHERS) AS prev_order_key FROM container WHERE is_pinned = ?1) SELECT lexo_rank_reorder_before(order_key, prev_order_key) AS _c0 FROM ordered_table WHERE id = ?2',
      variables: [
        i0.Variable<bool>(isPinned),
        i0.Variable<String>(containerId),
      ],
      readsFrom: {container},
    ).map((i0.QueryRow row) => row.read<String>('_c0'));
  }

  i0.Selectable<String> leadingOrderKey({
    required int bucket,
    required String? spaceUuid,
    required String? folderId,
    required int tabShelf,
    required String? scopeContainerId,
  }) {
    return customSelect(
      'SELECT lexo_rank_previous(?1, (SELECT order_key FROM tab WHERE space_uuid IS ?2 AND folder_id IS ?3 AND tab_shelf = ?4 AND(?4 != 2 OR container_id IS ?5)ORDER BY order_key LIMIT 1)) AS _c0',
      variables: [
        i0.Variable<int>(bucket),
        i0.Variable<String>(spaceUuid),
        i0.Variable<String>(folderId),
        i0.Variable<int>(tabShelf),
        i0.Variable<String>(scopeContainerId),
      ],
      readsFrom: {tab},
    ).map((i0.QueryRow row) => row.read<String>('_c0'));
  }

  i0.Selectable<String> trailingOrderKey({
    required int bucket,
    required String? spaceUuid,
    required String? folderId,
    required int tabShelf,
    required String? scopeContainerId,
  }) {
    return customSelect(
      'SELECT lexo_rank_next(?1, (SELECT order_key FROM tab WHERE space_uuid IS ?2 AND folder_id IS ?3 AND tab_shelf = ?4 AND(?4 != 2 OR container_id IS ?5)ORDER BY order_key DESC LIMIT 1)) AS _c0',
      variables: [
        i0.Variable<int>(bucket),
        i0.Variable<String>(spaceUuid),
        i0.Variable<String>(folderId),
        i0.Variable<int>(tabShelf),
        i0.Variable<String>(scopeContainerId),
      ],
      readsFrom: {tab},
    ).map((i0.QueryRow row) => row.read<String>('_c0'));
  }

  i0.Selectable<String> lastChildTabId({
    required String parentId,
    required String? spaceUuid,
    required String? folderId,
    required int tabShelf,
    required String? scopeContainerId,
  }) {
    return customSelect(
      'SELECT id FROM tab WHERE parent_id = ?1 AND space_uuid IS ?2 AND folder_id IS ?3 AND tab_shelf = ?4 AND(?4 != 2 OR container_id IS ?5)ORDER BY order_key DESC LIMIT 1',
      variables: [
        i0.Variable<String>(parentId),
        i0.Variable<String>(spaceUuid),
        i0.Variable<String>(folderId),
        i0.Variable<int>(tabShelf),
        i0.Variable<String>(scopeContainerId),
      ],
      readsFrom: {tab},
    ).map((i0.QueryRow row) => row.read<String>('id'));
  }

  i0.Selectable<String> orderKeyAfterTab({
    required String? spaceUuid,
    required String? folderId,
    required int tabShelf,
    required String? scopeContainerId,
    required String tabId,
  }) {
    return customSelect(
      'WITH ordered_table AS (SELECT id, order_key, LEAD(order_key)OVER (ORDER BY order_key RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW EXCLUDE NO OTHERS) AS next_order_key FROM tab WHERE space_uuid IS ?1 AND folder_id IS ?2 AND tab_shelf = ?3 AND(?3 != 2 OR container_id IS ?4)) SELECT lexo_rank_reorder_after(order_key, next_order_key) AS _c0 FROM ordered_table WHERE id = ?5',
      variables: [
        i0.Variable<String>(spaceUuid),
        i0.Variable<String>(folderId),
        i0.Variable<int>(tabShelf),
        i0.Variable<String>(scopeContainerId),
        i0.Variable<String>(tabId),
      ],
      readsFrom: {tab},
    ).map((i0.QueryRow row) => row.read<String>('_c0'));
  }

  i0.Selectable<String> orderKeyBeforeTab({
    required String? spaceUuid,
    required String? folderId,
    required int tabShelf,
    required String? scopeContainerId,
    required String tabId,
  }) {
    return customSelect(
      'WITH ordered_table AS (SELECT id, order_key, LAG(order_key)OVER (ORDER BY order_key RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW EXCLUDE NO OTHERS) AS prev_order_key FROM tab WHERE space_uuid IS ?1 AND folder_id IS ?2 AND tab_shelf = ?3 AND(?3 != 2 OR container_id IS ?4)) SELECT lexo_rank_reorder_before(order_key, prev_order_key) AS _c0 FROM ordered_table WHERE id = ?5',
      variables: [
        i0.Variable<String>(spaceUuid),
        i0.Variable<String>(folderId),
        i0.Variable<int>(tabShelf),
        i0.Variable<String>(scopeContainerId),
        i0.Variable<String>(tabId),
      ],
      readsFrom: {tab},
    ).map((i0.QueryRow row) => row.read<String>('_c0'));
  }

  i0.Selectable<i13.TabQueryResult> queryTabsBasic({
    required String query,
    required int limit,
  }) {
    return customSelect(
      'WITH weights AS (SELECT 10.0 AS title_weight, 5.0 AS url_weight) SELECT t.id, t.container_id, t.tab_mode, t.title, CAST(t.url AS TEXT) AS url, t.url AS clean_url, bm25(tab_fts, weights.title_weight, weights.url_weight) AS weighted_rank FROM tab_fts AS fts INNER JOIN tab AS t ON t."rowid" = fts."rowid" CROSS JOIN weights WHERE fts.title LIKE ?1 OR fts.url LIKE ?1 ORDER BY weighted_rank ASC, t.timestamp DESC LIMIT ?2',
      variables: [i0.Variable<String>(query), i0.Variable<int>(limit)],
      readsFrom: {tab, tabFts},
    ).map(
      (i0.QueryRow row) => i13.TabQueryResult(
        id: row.read<String>('id'),
        containerId: row.readNullable<String>('container_id'),
        tabMode: i2.Tab.$convertertabMode.fromSql(row.read<int>('tab_mode')),
        title: row.readNullable<String>('title'),
        url: row.readNullable<String>('url'),
        cleanUrl: i2.Tab.$converterurl.fromSql(
          row.readNullable<String>('clean_url'),
        ),
        weightedRank: row.read<double>('weighted_rank'),
      ),
    );
  }

  i0.Selectable<i13.TabQueryResult> queryTabsFullContent({
    required String beforeMatch,
    required String afterMatch,
    required String ellipsis,
    required int snippetLength,
    required String query,
    required int limit,
  }) {
    return customSelect(
      'WITH weights AS (SELECT 10.0 AS title_weight, 5.0 AS url_weight, 3.0 AS extracted_weight, 1.0 AS full_weight) SELECT t.id, t.container_id, t.tab_mode, highlight(tab_fts, 0, ?1, ?2) AS title, highlight(tab_fts, 1, ?1, ?2) AS url, snippet(tab_fts, 2, ?1, ?2, ?3, ?4) AS extracted_content, snippet(tab_fts, 3, ?1, ?2, ?3, ?4) AS full_content, t.url AS clean_url,(bm25(tab_fts, weights.title_weight, weights.url_weight, weights.extracted_weight, weights.full_weight))AS weighted_rank FROM tab_fts(?5)AS fts INNER JOIN tab AS t ON t."rowid" = fts."rowid" CROSS JOIN weights ORDER BY weighted_rank ASC, t.timestamp DESC LIMIT ?6',
      variables: [
        i0.Variable<String>(beforeMatch),
        i0.Variable<String>(afterMatch),
        i0.Variable<String>(ellipsis),
        i0.Variable<int>(snippetLength),
        i0.Variable<String>(query),
        i0.Variable<int>(limit),
      ],
      readsFrom: {tab, tabFts},
    ).map(
      (i0.QueryRow row) => i13.TabQueryResult(
        id: row.read<String>('id'),
        containerId: row.readNullable<String>('container_id'),
        tabMode: i2.Tab.$convertertabMode.fromSql(row.read<int>('tab_mode')),
        title: row.readNullable<String>('title'),
        url: row.readNullable<String>('url'),
        cleanUrl: i2.Tab.$converterurl.fromSql(
          row.readNullable<String>('clean_url'),
        ),
        extractedContent: row.readNullable<String>('extracted_content'),
        fullContent: row.readNullable<String>('full_content'),
        weightedRank: row.read<double>('weighted_rank'),
      ),
    );
  }

  i0.Selectable<TabTreesResult> tabTrees({
    required bool skipSpaceCheck,
    required String? spaceUuid,
  }) {
    return customSelect(
      'WITH RECURSIVE descendants AS (SELECT t.id, t.parent_id, t.timestamp, t.id AS root_id FROM tab AS t WHERE(?1 OR t.space_uuid IS ?2)AND(t.parent_id IS NULL OR NOT EXISTS (SELECT 1 AS _c0 FROM tab AS p WHERE p.id = t.parent_id AND(?1 OR p.space_uuid IS ?2)))UNION ALL SELECT t.id, t.parent_id, t.timestamp, d.root_id FROM tab AS t JOIN descendants AS d ON t.parent_id = d.id WHERE ?1 OR t.space_uuid IS ?2), root_stats AS (SELECT root_id, MAX(timestamp) AS max_timestamp, COUNT(*) AS total_children FROM descendants GROUP BY root_id) SELECT d.root_id AS root_tab_id, d.id AS latest_tab_id, d.timestamp AS latest_timestamp, rs.total_children AS total_tabs FROM descendants AS d JOIN root_stats AS rs ON d.root_id = rs.root_id AND d.timestamp = rs.max_timestamp ORDER BY d.timestamp DESC',
      variables: [
        i0.Variable<bool>(skipSpaceCheck),
        i0.Variable<String>(spaceUuid),
      ],
      readsFrom: {tab},
    ).map(
      (i0.QueryRow row) => TabTreesResult(
        rootTabId: row.read<String>('root_tab_id'),
        latestTabId: row.read<String>('latest_tab_id'),
        latestTimestamp: row.read<DateTime>('latest_timestamp'),
        totalTabs: row.read<int>('total_tabs'),
      ),
    );
  }

  i0.Selectable<TabsWithRootAndDepthResult> tabsWithRootAndDepth({
    required String? spaceUuid,
  }) {
    return customSelect(
      'WITH RECURSIVE walk (id, parent_id, order_key, root_id, depth) AS (SELECT t.id, t.parent_id, t.order_key, t.id AS root_id, 0 AS depth FROM tab AS t WHERE t.space_uuid IS ?1 AND(t.parent_id IS NULL OR NOT EXISTS (SELECT 1 FROM tab AS p WHERE p.id = t.parent_id AND p.space_uuid IS ?1))UNION ALL SELECT t.id, t.parent_id, t.order_key, w.root_id, w.depth + 1 FROM tab AS t INNER JOIN walk AS w ON t.parent_id = w.id WHERE t.space_uuid IS ?1) SELECT id, parent_id, order_key, root_id, depth FROM walk',
      variables: [i0.Variable<String>(spaceUuid)],
      readsFrom: {tab},
    ).map(
      (i0.QueryRow row) => TabsWithRootAndDepthResult(
        id: row.read<String>('id'),
        parentId: row.readNullable<String>('parent_id'),
        orderKey: row.read<String>('order_key'),
        rootId: row.read<String>('root_id'),
        depth: row.read<int>('depth'),
      ),
    );
  }

  i0.Selectable<String> lastSubtreeTabIdByOrderKey({
    required String tabId,
    required String? spaceUuid,
    required String? folderId,
    required int tabShelf,
    required String? scopeContainerId,
  }) {
    return customSelect(
      'WITH RECURSIVE subtree AS (SELECT id, order_key FROM tab WHERE id = ?1 AND space_uuid IS ?2 AND folder_id IS ?3 AND tab_shelf = ?4 AND(?4 != 2 OR container_id IS ?5)UNION ALL SELECT t.id, t.order_key FROM tab AS t INNER JOIN subtree AS s ON t.parent_id = s.id WHERE t.space_uuid IS ?2 AND t.folder_id IS ?3 AND t.tab_shelf = ?4 AND(?4 != 2 OR t.container_id IS ?5)) SELECT id FROM subtree ORDER BY order_key DESC LIMIT 1',
      variables: [
        i0.Variable<String>(tabId),
        i0.Variable<String>(spaceUuid),
        i0.Variable<String>(folderId),
        i0.Variable<int>(tabShelf),
        i0.Variable<String>(scopeContainerId),
      ],
      readsFrom: {tab},
    ).map((i0.QueryRow row) => row.read<String>('id'));
  }

  i0.Selectable<ScopeSiblingsResult> scopeSiblings({
    required String? spaceUuid,
    required String? folderId,
    required int tabShelf,
    required String? scopeContainerId,
    required String? parentId,
  }) {
    return customSelect(
      'SELECT t.id, t.order_key FROM tab AS t WHERE t.space_uuid IS ?1 AND t.folder_id IS ?2 AND t.tab_shelf = ?3 AND(?3 != 2 OR t.container_id IS ?4)AND(CASE WHEN EXISTS (SELECT 1 AS _c0 FROM tab AS p WHERE p.id = t.parent_id AND p.space_uuid IS t.space_uuid AND p.folder_id IS t.folder_id) THEN t.parent_id ELSE NULL END)IS ?5 ORDER BY t.order_key ASC',
      variables: [
        i0.Variable<String>(spaceUuid),
        i0.Variable<String>(folderId),
        i0.Variable<int>(tabShelf),
        i0.Variable<String>(scopeContainerId),
        i0.Variable<String>(parentId),
      ],
      readsFrom: {tab},
    ).map(
      (i0.QueryRow row) => ScopeSiblingsResult(
        id: row.read<String>('id'),
        orderKey: row.read<String>('order_key'),
      ),
    );
  }

  i0.Selectable<UnorderedTabDescendantsResult> unorderedTabDescendants({
    required String tabId,
  }) {
    return customSelect(
      'WITH RECURSIVE descendants AS (SELECT id, parent_id FROM tab WHERE id = ?1 UNION ALL SELECT t.id, t.parent_id FROM tab AS t JOIN descendants AS d ON t.parent_id = d.id) SELECT id, parent_id FROM descendants',
      variables: [i0.Variable<String>(tabId)],
      readsFrom: {tab},
    ).map(
      (i0.QueryRow row) => UnorderedTabDescendantsResult(
        id: row.read<String>('id'),
        parentId: row.readNullable<String>('parent_id'),
      ),
    );
  }

  i0.Selectable<UnorderedScopeTabDescendantsResult>
  unorderedScopeTabDescendants({required String tabId}) {
    return customSelect(
      'WITH RECURSIVE descendants AS (SELECT id, parent_id, space_uuid, folder_id FROM tab WHERE id = ?1 UNION ALL SELECT t.id, t.parent_id, t.space_uuid, t.folder_id FROM tab AS t JOIN descendants AS d ON t.parent_id = d.id WHERE t.space_uuid IS d.space_uuid AND t.folder_id IS d.folder_id) SELECT id, parent_id FROM descendants',
      variables: [i0.Variable<String>(tabId)],
      readsFrom: {tab},
    ).map(
      (i0.QueryRow row) => UnorderedScopeTabDescendantsResult(
        id: row.read<String>('id'),
        parentId: row.readNullable<String>('parent_id'),
      ),
    );
  }

  i0.Selectable<String?> previousTabByTimestamp({required String tabId}) {
    return customSelect(
      'WITH ranked_tabs AS (SELECT id, timestamp, LAG(id)OVER (ORDER BY timestamp RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW EXCLUDE NO OTHERS) AS prev_tab_id FROM tab) SELECT prev_tab_id FROM ranked_tabs WHERE id = ?1',
      variables: [i0.Variable<String>(tabId)],
      readsFrom: {tab},
    ).map((i0.QueryRow row) => row.readNullable<String>('prev_tab_id'));
  }

  i0.Selectable<String?> previousTabByOrderKey({
    required bool skipScopeCheck,
    required String? spaceUuid,
    required String? folderId,
    required int tabShelf,
    required String? scopeContainerId,
    required String tabId,
  }) {
    return customSelect(
      'WITH ranked_tabs AS (SELECT id, order_key, LAG(id)OVER (ORDER BY order_key RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW EXCLUDE NO OTHERS) AS prev_tab_id FROM tab WHERE ?1 OR(space_uuid IS ?2 AND folder_id IS ?3 AND tab_shelf = ?4 AND(?4 != 2 OR container_id IS ?5))) SELECT prev_tab_id FROM ranked_tabs WHERE id = ?6',
      variables: [
        i0.Variable<bool>(skipScopeCheck),
        i0.Variable<String>(spaceUuid),
        i0.Variable<String>(folderId),
        i0.Variable<int>(tabShelf),
        i0.Variable<String>(scopeContainerId),
        i0.Variable<String>(tabId),
      ],
      readsFrom: {tab},
    ).map((i0.QueryRow row) => row.readNullable<String>('prev_tab_id'));
  }

  i0.Selectable<String?> nextTabByOrderKey({
    required bool skipScopeCheck,
    required String? spaceUuid,
    required String? folderId,
    required int tabShelf,
    required String? scopeContainerId,
    required String tabId,
  }) {
    return customSelect(
      'WITH ranked_tabs AS (SELECT id, order_key, LEAD(id)OVER (ORDER BY order_key RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW EXCLUDE NO OTHERS) AS next_tab_id FROM tab WHERE ?1 OR(space_uuid IS ?2 AND folder_id IS ?3 AND tab_shelf = ?4 AND(?4 != 2 OR container_id IS ?5))) SELECT next_tab_id FROM ranked_tabs WHERE id = ?6',
      variables: [
        i0.Variable<bool>(skipScopeCheck),
        i0.Variable<String>(spaceUuid),
        i0.Variable<String>(folderId),
        i0.Variable<int>(tabShelf),
        i0.Variable<String>(scopeContainerId),
        i0.Variable<String>(tabId),
      ],
      readsFrom: {tab},
    ).map((i0.QueryRow row) => row.readNullable<String>('next_tab_id'));
  }

  i0.Selectable<String> containersToClearOnExit() {
    return customSelect(
      'SELECT cl.container_id AS contextual_identity FROM container_local AS cl WHERE cl.clear_data_on_exit = 1',
      variables: [],
      readsFrom: {containerLocal},
    ).map((i0.QueryRow row) => row.read<String>('contextual_identity'));
  }

  i0.Selectable<HistoryExclusionTabsResult> historyExclusionTabs() {
    return customSelect(
      'SELECT tab.engine_tab_id AS tab_id, tab.container_id AS container_id, COALESCE(cl.exclude_from_history, 0) AS excluded FROM tab LEFT JOIN container_local AS cl ON cl.container_id = tab.container_id WHERE tab.engine_tab_id IS NOT NULL',
      variables: [],
      readsFrom: {tab, containerLocal},
    ).map(
      (i0.QueryRow row) => HistoryExclusionTabsResult(
        tabId: row.readNullable<String>('tab_id'),
        containerId: row.readNullable<String>('container_id'),
        excluded: row.read<bool>('excluded'),
      ),
    );
  }

  i0.Selectable<String> excludedHistoryContextIds() {
    return customSelect(
      'SELECT container_id AS context_id FROM container_local WHERE exclude_from_history = 1',
      variables: [],
      readsFrom: {containerLocal},
    ).map((i0.QueryRow row) => row.read<String>('context_id'));
  }

  i0.Selectable<i5.TabFolderData> folderChildren({
    required String? spaceUuid,
    required String? parentFolderId,
  }) {
    return customSelect(
      'SELECT * FROM tab_folder WHERE space_uuid IS ?1 AND parent_folder_id IS ?2 ORDER BY order_key',
      variables: [
        i0.Variable<String>(spaceUuid),
        i0.Variable<String>(parentFolderId),
      ],
      readsFrom: {tabFolder},
    ).asyncMap(tabFolder.mapFromRow);
  }

  i0.Selectable<String> folderSubtreeIds({required String folderId}) {
    return customSelect(
      'WITH RECURSIVE sub (id) AS (SELECT id FROM tab_folder WHERE id = ?1 UNION ALL SELECT f.id FROM tab_folder AS f JOIN sub ON f.parent_folder_id = sub.id) SELECT id FROM sub',
      variables: [i0.Variable<String>(folderId)],
      readsFrom: {tabFolder},
    ).map((i0.QueryRow row) => row.read<String>('id'));
  }

  i0.Selectable<i6.TabSplitData> splitsInScope({
    required String? spaceUuid,
    required String? folderId,
  }) {
    return customSelect(
      'SELECT * FROM tab_split WHERE space_uuid IS ?1 AND folder_id IS ?2 ORDER BY order_key',
      variables: [
        i0.Variable<String>(spaceUuid),
        i0.Variable<String>(folderId),
      ],
      readsFrom: {tabSplit},
    ).asyncMap(tabSplit.mapFromRow);
  }

  i0.Selectable<SplitMembersResult> splitMembers({String? splitId}) {
    return customSelect(
      'SELECT id, split_index FROM tab WHERE split_id = ?1 ORDER BY split_index',
      variables: [i0.Variable<String>(splitId)],
      readsFrom: {tab},
    ).map(
      (i0.QueryRow row) => SplitMembersResult(
        id: row.read<String>('id'),
        splitIndex: row.readNullable<int>('split_index'),
      ),
    );
  }

  i0.Selectable<String> essentialTabIds({required String? containerId}) {
    return customSelect(
      'SELECT id FROM tab WHERE tab_shelf = 2 AND container_id IS ?1 ORDER BY order_key',
      variables: [i0.Variable<String>(containerId)],
      readsFrom: {tab},
    ).map((i0.QueryRow row) => row.read<String>('id'));
  }

  i0.Selectable<ScopeSlotTabsResult> scopeSlotTabs({
    required String? spaceUuid,
    required String? folderId,
  }) {
    return customSelect(
      'SELECT id, order_key, tab_shelf AS shelf FROM tab WHERE space_uuid IS ?1 AND folder_id IS ?2 AND split_id IS NULL AND tab_shelf IN (0, 1) AND tab_mode = 0 ORDER BY tab_shelf DESC, order_key ASC',
      variables: [
        i0.Variable<String>(spaceUuid),
        i0.Variable<String>(folderId),
      ],
      readsFrom: {tab},
    ).map(
      (i0.QueryRow row) => ScopeSlotTabsResult(
        id: row.read<String>('id'),
        orderKey: row.read<String>('order_key'),
        shelf: i2.Tab.$convertertabShelf.fromSql(row.read<int>('shelf')),
      ),
    );
  }

  i0.Selectable<ScopeSlotFoldersResult> scopeSlotFolders({
    required String? spaceUuid,
    required String? folderId,
  }) {
    return customSelect(
      'SELECT id, order_key FROM tab_folder WHERE space_uuid IS ?1 AND parent_folder_id IS ?2 ORDER BY order_key ASC',
      variables: [
        i0.Variable<String>(spaceUuid),
        i0.Variable<String>(folderId),
      ],
      readsFrom: {tabFolder},
    ).map(
      (i0.QueryRow row) => ScopeSlotFoldersResult(
        id: row.read<String>('id'),
        orderKey: row.read<String>('order_key'),
      ),
    );
  }

  i0.Selectable<ScopeSlotSplitsResult> scopeSlotSplits({
    required String? spaceUuid,
    required String? folderId,
  }) {
    return customSelect(
      'SELECT id, order_key, is_pinned FROM tab_split WHERE space_uuid IS ?1 AND folder_id IS ?2 ORDER BY is_pinned DESC, order_key ASC',
      variables: [
        i0.Variable<String>(spaceUuid),
        i0.Variable<String>(folderId),
      ],
      readsFrom: {tabSplit},
    ).map(
      (i0.QueryRow row) => ScopeSlotSplitsResult(
        id: row.read<String>('id'),
        orderKey: row.read<String>('order_key'),
        isPinned: row.read<bool>('is_pinned'),
      ),
    );
  }

  i0.Selectable<String> scopeLeadingSlotKey({
    required int bucket,
    required String? spaceUuid,
    required String? folderId,
    required int tabShelf,
  }) {
    return customSelect(
      'SELECT lexo_rank_previous(?1, (SELECT MIN(order_key) FROM (SELECT order_key FROM tab WHERE space_uuid IS ?2 AND folder_id IS ?3 AND tab_shelf = ?4 UNION ALL SELECT order_key FROM tab_folder WHERE space_uuid IS ?2 AND parent_folder_id IS ?3 AND ?4 = 0 UNION ALL SELECT order_key FROM tab_split WHERE space_uuid IS ?2 AND folder_id IS ?3 AND is_pinned =(?4 = 1)))) AS _c0',
      variables: [
        i0.Variable<int>(bucket),
        i0.Variable<String>(spaceUuid),
        i0.Variable<String>(folderId),
        i0.Variable<int>(tabShelf),
      ],
      readsFrom: {tab, tabFolder, tabSplit},
    ).map((i0.QueryRow row) => row.read<String>('_c0'));
  }

  i0.Selectable<String> scopeTrailingSlotKey({
    required int bucket,
    required String? spaceUuid,
    required String? folderId,
    required int tabShelf,
  }) {
    return customSelect(
      'SELECT lexo_rank_next(?1, (SELECT MAX(order_key) FROM (SELECT order_key FROM tab WHERE space_uuid IS ?2 AND folder_id IS ?3 AND tab_shelf = ?4 UNION ALL SELECT order_key FROM tab_folder WHERE space_uuid IS ?2 AND parent_folder_id IS ?3 AND ?4 = 0 UNION ALL SELECT order_key FROM tab_split WHERE space_uuid IS ?2 AND folder_id IS ?3 AND is_pinned =(?4 = 1)))) AS _c0',
      variables: [
        i0.Variable<int>(bucket),
        i0.Variable<String>(spaceUuid),
        i0.Variable<String>(folderId),
        i0.Variable<int>(tabShelf),
      ],
      readsFrom: {tab, tabFolder, tabSplit},
    ).map((i0.QueryRow row) => row.read<String>('_c0'));
  }

  i0.Selectable<i2.TabData> tabByEngineId({String? engineTabId}) {
    return customSelect(
      'SELECT * FROM tab WHERE engine_tab_id = ?1',
      variables: [i0.Variable<String>(engineTabId)],
      readsFrom: {tab},
    ).asyncMap(tab.mapFromRow);
  }

  i0.Selectable<String> coldTabIds() {
    return customSelect(
      'SELECT id FROM tab WHERE engine_tab_id IS NULL AND tab_mode = 0',
      variables: [],
      readsFrom: {tab},
    ).map((i0.QueryRow row) => row.read<String>('id'));
  }

  i0.Selectable<int> liveTabCount() {
    return customSelect(
      'SELECT COUNT(*) AS count FROM tab WHERE engine_tab_id IS NOT NULL',
      variables: [],
      readsFrom: {tab},
    ).map((i0.QueryRow row) => row.read<int>('count'));
  }

  i0.Selectable<i2.TabData> tabsInSpace({required String? spaceUuid}) {
    return customSelect(
      'SELECT * FROM tab WHERE space_uuid IS ?1 ORDER BY tab_shelf DESC, order_key',
      variables: [i0.Variable<String>(spaceUuid)],
      readsFrom: {tab},
    ).asyncMap(tab.mapFromRow);
  }

  i0.Selectable<i2.TabData> tabsInContainer({String? containerId}) {
    return customSelect(
      'SELECT * FROM tab WHERE container_id IS ?1 ORDER BY order_key',
      variables: [i0.Variable<String>(containerId)],
      readsFrom: {tab},
    ).asyncMap(tab.mapFromRow);
  }

  i2.TabFts get tabFts => i11.ReadDatabaseContainer(
    attachedDatabase,
  ).resultSet<i2.TabFts>('tab_fts');
  i2.HistoryFts get historyFts => i11.ReadDatabaseContainer(
    attachedDatabase,
  ).resultSet<i2.HistoryFts>('history_fts');
  i2.History get history => i11.ReadDatabaseContainer(
    attachedDatabase,
  ).resultSet<i2.History>('history');
  i2.LocalIndexSetting get localIndexSetting => i11.ReadDatabaseContainer(
    attachedDatabase,
  ).resultSet<i2.LocalIndexSetting>('local_index_setting');
  i2.Tab get tab =>
      i11.ReadDatabaseContainer(attachedDatabase).resultSet<i2.Tab>('tab');
  i2.ContainerLocal get containerLocal => i11.ReadDatabaseContainer(
    attachedDatabase,
  ).resultSet<i2.ContainerLocal>('container_local');
  i2.Container get container => i11.ReadDatabaseContainer(
    attachedDatabase,
  ).resultSet<i2.Container>('container');
  i2.TabFolder get tabFolder => i11.ReadDatabaseContainer(
    attachedDatabase,
  ).resultSet<i2.TabFolder>('tab_folder');
  i2.TabSplit get tabSplit => i11.ReadDatabaseContainer(
    attachedDatabase,
  ).resultSet<i2.TabSplit>('tab_split');
}

class TabTreesResult {
  final String rootTabId;
  final String latestTabId;
  final DateTime latestTimestamp;
  final int totalTabs;
  TabTreesResult({
    required this.rootTabId,
    required this.latestTabId,
    required this.latestTimestamp,
    required this.totalTabs,
  });
}

class TabsWithRootAndDepthResult {
  final String id;
  final String? parentId;
  final String orderKey;
  final String rootId;
  final int depth;
  TabsWithRootAndDepthResult({
    required this.id,
    this.parentId,
    required this.orderKey,
    required this.rootId,
    required this.depth,
  });
}

class ScopeSiblingsResult {
  final String id;
  final String orderKey;
  ScopeSiblingsResult({required this.id, required this.orderKey});
}

class UnorderedTabDescendantsResult {
  final String id;
  final String? parentId;
  UnorderedTabDescendantsResult({required this.id, this.parentId});
}

class UnorderedScopeTabDescendantsResult {
  final String id;
  final String? parentId;
  UnorderedScopeTabDescendantsResult({required this.id, this.parentId});
}

class HistoryExclusionTabsResult {
  final String? tabId;
  final String? containerId;
  final bool excluded;
  HistoryExclusionTabsResult({
    this.tabId,
    this.containerId,
    required this.excluded,
  });
}

class SplitMembersResult {
  final String id;
  final int? splitIndex;
  SplitMembersResult({required this.id, this.splitIndex});
}

class ScopeSlotTabsResult {
  final String id;
  final String orderKey;
  final i8.TabShelf shelf;
  ScopeSlotTabsResult({
    required this.id,
    required this.orderKey,
    required this.shelf,
  });
}

class ScopeSlotFoldersResult {
  final String id;
  final String orderKey;
  ScopeSlotFoldersResult({required this.id, required this.orderKey});
}

class ScopeSlotSplitsResult {
  final String id;
  final String orderKey;
  final bool isPinned;
  ScopeSlotSplitsResult({
    required this.id,
    required this.orderKey,
    required this.isPinned,
  });
}
