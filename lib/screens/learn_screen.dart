import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/isro_data.dart';
import '../providers/isro_data_provider.dart';
import '../widgets/shimmer_loading.dart';

class LearnScreen extends ConsumerStatefulWidget {
  const LearnScreen({super.key});

  @override
  ConsumerState<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends ConsumerState<LearnScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn ISRO'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Spacecrafts', icon: Icon(Icons.rocket_launch)),
            Tab(text: 'Launchers', icon: Icon(Icons.rocket)),
            Tab(text: 'Satellites', icon: Icon(Icons.satellite)),
            Tab(text: 'Centres', icon: Icon(Icons.location_city)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surface,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search ISRO data...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SpacecraftsTab(searchQuery: _searchQuery),
                _LaunchersTab(searchQuery: _searchQuery),
                _SatellitesTab(searchQuery: _searchQuery),
                _CentresTab(searchQuery: _searchQuery),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Spacecrafts Tab
class _SpacecraftsTab extends ConsumerWidget {
  final String searchQuery;

  const _SpacecraftsTab({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacecraftsAsync = ref.watch(spacecraftsProvider);

    return spacecraftsAsync.when(
      data: (spacecrafts) {
        final filteredSpacecrafts = searchQuery.isEmpty
            ? spacecrafts
            : spacecrafts
                  .where(
                    (spacecraft) =>
                        spacecraft.name.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ||
                        (spacecraft.mission?.toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            ) ??
                            false) ||
                        (spacecraft.description?.toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            ) ??
                            false),
                  )
                  .toList();

        if (filteredSpacecrafts.isEmpty) {
          return const Center(child: Text('No spacecrafts found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredSpacecrafts.length,
          itemBuilder: (context, index) {
            final spacecraft = filteredSpacecrafts[index];
            return SpacecraftCard(spacecraft: spacecraft);
          },
        );
      },
      loading: () => const ShimmerLoading(),
      error: (error, stack) => ErrorWidget(error: error.toString()),
    );
  }
}

// Launchers Tab
class _LaunchersTab extends ConsumerWidget {
  final String searchQuery;

  const _LaunchersTab({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final launchersAsync = ref.watch(launchersProvider);

    return launchersAsync.when(
      data: (launchers) {
        final filteredLaunchers = searchQuery.isEmpty
            ? launchers
            : launchers
                  .where(
                    (launcher) =>
                        launcher.name.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ||
                        (launcher.type?.toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            ) ??
                            false) ||
                        (launcher.description?.toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            ) ??
                            false),
                  )
                  .toList();

        if (filteredLaunchers.isEmpty) {
          return const Center(child: Text('No launchers found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredLaunchers.length,
          itemBuilder: (context, index) {
            final launcher = filteredLaunchers[index];
            return LauncherCard(launcher: launcher);
          },
        );
      },
      loading: () => const ShimmerLoading(),
      error: (error, stack) => ErrorWidget(error: error.toString()),
    );
  }
}

// Satellites Tab
class _SatellitesTab extends ConsumerWidget {
  final String searchQuery;

  const _SatellitesTab({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final satellitesAsync = ref.watch(customerSatellitesProvider);

    return satellitesAsync.when(
      data: (satellites) {
        final filteredSatellites = searchQuery.isEmpty
            ? satellites
            : satellites
                  .where(
                    (satellite) =>
                        satellite.name.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ||
                        (satellite.application?.toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            ) ??
                            false) ||
                        (satellite.description?.toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            ) ??
                            false),
                  )
                  .toList();

        if (filteredSatellites.isEmpty) {
          return const Center(child: Text('No satellites found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredSatellites.length,
          itemBuilder: (context, index) {
            final satellite = filteredSatellites[index];
            return SatelliteCard(satellite: satellite);
          },
        );
      },
      loading: () => const ShimmerLoading(),
      error: (error, stack) => ErrorWidget(error: error.toString()),
    );
  }
}

// Centres Tab
class _CentresTab extends ConsumerWidget {
  final String searchQuery;

  const _CentresTab({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centresAsync = ref.watch(centresProvider);

    return centresAsync.when(
      data: (centres) {
        final filteredCentres = searchQuery.isEmpty
            ? centres
            : centres
                  .where(
                    (centre) =>
                        centre.name.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ||
                        (centre.location?.toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            ) ??
                            false) ||
                        (centre.description?.toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            ) ??
                            false),
                  )
                  .toList();

        if (filteredCentres.isEmpty) {
          return const Center(child: Text('No centres found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredCentres.length,
          itemBuilder: (context, index) {
            final centre = filteredCentres[index];
            return CentreCard(centre: centre);
          },
        );
      },
      loading: () => const ShimmerLoading(),
      error: (error, stack) => ErrorWidget(error: error.toString()),
    );
  }
}

// Spacecraft Card Widget
class SpacecraftCard extends StatelessWidget {
  final Spacecraft spacecraft;

  const SpacecraftCard({super.key, required this.spacecraft});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image (placeholder for now since API might not have images)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: spacecraft.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: spacecraft.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => _DefaultImage(
                      icon: Icons.rocket_launch,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : _DefaultImage(
                    icon: Icons.rocket_launch,
                    color: theme.colorScheme.primary,
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spacecraft.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (spacecraft.mission != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.flag,
                        size: 16,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Mission: ${spacecraft.mission}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                if (spacecraft.launchDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Launch Date: ${spacecraft.launchDate}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],

                if (spacecraft.status != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            spacecraft.status!,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          spacecraft.status!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getStatusColor(spacecraft.status!),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                if (spacecraft.description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    spacecraft.description!,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                if (spacecraft.objectives.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Objectives:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...spacecraft.objectives
                      .take(3)
                      .map(
                        (objective) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('• ', style: theme.textTheme.bodySmall),
                              Expanded(
                                child: Text(
                                  objective,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  if (spacecraft.objectives.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Text(
                        '... and ${spacecraft.objectives.length - 3} more',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'operational':
      case 'success':
        return Colors.green;
      case 'inactive':
      case 'failed':
        return Colors.red;
      case 'planned':
      case 'upcoming':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

// Launcher Card Widget
class LauncherCard extends StatelessWidget {
  final Launcher launcher;

  const LauncherCard({super.key, required this.launcher});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: launcher.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: launcher.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => _DefaultImage(
                      icon: Icons.rocket,
                      color: theme.colorScheme.secondary,
                    ),
                  )
                : _DefaultImage(
                    icon: Icons.rocket,
                    color: theme.colorScheme.secondary,
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  launcher.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (launcher.type != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      launcher.type!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                if (launcher.firstFlight != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.flight_takeoff,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'First Flight: ${launcher.firstFlight}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],

                if (launcher.height != null || launcher.mass != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (launcher.height != null) ...[
                        Icon(Icons.height, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Height: ${launcher.height}m',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        if (launcher.mass != null) const SizedBox(width: 16),
                      ],
                      if (launcher.mass != null) ...[
                        Icon(
                          Icons.monitor_weight,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Mass: ${launcher.mass}kg',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],

                if (launcher.description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    launcher.description!,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Satellite Card Widget
class SatelliteCard extends StatelessWidget {
  final Satellite satellite;

  const SatelliteCard({super.key, required this.satellite});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: satellite.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: satellite.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => _DefaultImage(
                      icon: Icons.satellite,
                      color: theme.colorScheme.tertiary,
                    ),
                  )
                : _DefaultImage(
                    icon: Icons.satellite,
                    color: theme.colorScheme.tertiary,
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  satellite.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (satellite.application != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      satellite.application!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                Row(
                  children: [
                    if (satellite.launchDate != null) ...[
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        satellite.launchDate!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    if (satellite.orbit != null) ...[
                      if (satellite.launchDate != null)
                        const SizedBox(width: 16),
                      Icon(
                        Icons.track_changes,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        satellite.orbit!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),

                if (satellite.description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    satellite.description!,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Centre Card Widget
class CentreCard extends StatelessWidget {
  final Centre centre;

  const CentreCard({super.key, required this.centre});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: centre.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: centre.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => _DefaultImage(
                      icon: Icons.location_city,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : _DefaultImage(
                    icon: Icons.location_city,
                    color: theme.colorScheme.primary,
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  centre.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (centre.location != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          centre.location!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                if (centre.established != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.foundation, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Established: ${centre.established}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],

                if (centre.description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    centre.description!,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                if (centre.facilities.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Facilities:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: centre.facilities
                        .take(3)
                        .map(
                          (facility) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              facility,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  if (centre.facilities.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '... and ${centre.facilities.length - 3} more facilities',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Default Image Widget
class _DefaultImage extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _DefaultImage({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(child: Icon(icon, size: 64, color: color.withOpacity(0.5)));
  }
}

// Error Widget
class ErrorWidget extends StatelessWidget {
  final String error;

  const ErrorWidget({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Refresh data - this could be implemented to retry the API call
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
