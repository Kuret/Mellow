part of 'routes.dart';

@TypedGoRoute<SpaceListRoute>(name: 'SpaceListRoute', path: '/spaces')
class SpaceListRoute extends GoRouteData with $SpaceListRoute {
  const SpaceListRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SpaceListScreen();
  }
}

@TypedGoRoute<SpaceCreateRoute>(name: 'SpaceCreateRoute', path: '/space/new')
class SpaceCreateRoute extends GoRouteData with $SpaceCreateRoute {
  const SpaceCreateRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SpaceEditScreen.create();
  }
}

@TypedGoRoute<SpaceEditRoute>(name: 'SpaceEditRoute', path: '/space/:uuid/edit')
class SpaceEditRoute extends GoRouteData with $SpaceEditRoute {
  final String uuid;

  const SpaceEditRoute({required this.uuid});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SpaceEditScreen.edit(uuid: uuid);
  }
}
