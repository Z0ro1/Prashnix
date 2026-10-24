import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../profile/data/repositories/progress_repository.dart';
import '../../data/repositories/sync_service.dart';part 'skill_tree_provider.g.dart';

enum NodeStatus { locked, active, completed }
enum NodeType { standard, milestone }

class SkillNode {
  final String id;
  final String title;
  final String icon; // emoji or asset path
  final NodeStatus status;
  final NodeType type;
  final int completedLessons;
  final int totalLessons;

  SkillNode({
    required this.id,
    required this.title,
    required this.icon,
    required this.status,
    required this.type,
    this.completedLessons = 0,
    required this.totalLessons,
  });

  SkillNode copyWith({
    String? id,
    String? title,
    String? icon,
    NodeStatus? status,
    NodeType? type,
    int? completedLessons,
    int? totalLessons,
  }) {
    return SkillNode(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      status: status ?? this.status,
      type: type ?? this.type,
      completedLessons: completedLessons ?? this.completedLessons,
      totalLessons: totalLessons ?? this.totalLessons,
    );
  }
}

class SkillUnit {
  final String id;
  final int unitNumber;
  final int sectionNumber;
  final String title;
  final String colorHex;
  final List<SkillNode> nodes;

  SkillUnit({
    required this.id,
    required this.unitNumber,
    required this.sectionNumber,
    required this.title,
    required this.colorHex,
    required this.nodes,
  });

  SkillUnit copyWith({
    String? id,
    int? unitNumber,
    int? sectionNumber,
    String? title,
    String? colorHex,
    List<SkillNode>? nodes,
  }) {
    return SkillUnit(
      id: id ?? this.id,
      unitNumber: unitNumber ?? this.unitNumber,
      sectionNumber: sectionNumber ?? this.sectionNumber,
      title: title ?? this.title,
      colorHex: colorHex ?? this.colorHex,
      nodes: nodes ?? this.nodes,
    );
  }
}

@riverpod
class SkillTreeNotifier extends _$SkillTreeNotifier {
  final ProgressRepository _repo = ProgressRepository();
  late final SyncService _syncService = SyncService(progressRepo: _repo);

  @override
  FutureOr<List<SkillUnit>> build() async {
    return _fetchUnitsFromSupabase();
  }

  Future<List<SkillUnit>> _fetchUnitsFromSupabase() async {
    final unitsData = await Supabase.instance.client
        .from('units')
        .select()
        .order('order_index', ascending: true);
        
    final nodesData = await Supabase.instance.client
        .from('nodes')
        .select()
        .order('order_index', ascending: true);
        
    final lessonsData = await Supabase.instance.client
        .from('lessons')
        .select()
        .order('order_index', ascending: true);

    final units = <SkillUnit>[];
    
    // Group lessons by node_id to find total lessons per node
    final Map<String, int> nodeTotalLessons = {};
    for (final lesson in lessonsData) {
      final nodeId = lesson['node_id'] as String;
      nodeTotalLessons[nodeId] = (nodeTotalLessons[nodeId] ?? 0) + 1;
    }

    for (int u = 0; u < unitsData.length; u++) {
      final unitRow = unitsData[u];
      final unitId = unitRow['id'] as String;
      final unitNodesData = nodesData.where((n) => n['unit_id'] == unitId).toList();
      
      final nodes = <SkillNode>[];
      
      for (int i = 0; i < unitNodesData.length; i++) {
        final nodeRow = unitNodesData[i];
        final nodeId = nodeRow['id'] as String;
        final isMilestone = nodeRow['node_type'] == 'milestone';
        
        NodeStatus status;
        
        final totalLessons = nodeTotalLessons[nodeId] ?? 0;
        int completedLessons = 0;
        
        // Retrieve saved progress from SQLite using the real nodeId
        final savedLessonsStr = await _repo.getLocalState('progress_node_$nodeId') ?? 
            await _repo.getLocalState('progress_$nodeId');
        final savedStatusStr = await _repo.getLocalState('status_node_$nodeId') ?? 
            await _repo.getLocalState('status_$nodeId');

        if (savedLessonsStr != null) {
          completedLessons = int.parse(savedLessonsStr);
          if (savedStatusStr == '1') {
            status = NodeStatus.completed;
          } else if (completedLessons > 0) {
            status = NodeStatus.active;
          } else {
            status = NodeStatus.locked;
          }
        } else {
           status = NodeStatus.locked;
        }

        nodes.add(SkillNode(
          id: nodeId,
          title: nodeRow['title'] ?? (isMilestone ? 'Unit Review' : 'Level ${i + 1}'),
          icon: nodeRow['icon_name'] ?? 'star',
          status: status,
          type: isMilestone ? NodeType.milestone : NodeType.standard,
          totalLessons: totalLessons == 0 ? 1 : totalLessons,
          completedLessons: completedLessons,
        ));
      }
      
      units.add(SkillUnit(
        id: unitId,
        unitNumber: u + 1,
        sectionNumber: (u ~/ 5) + 1,
        title: unitRow['title'] ?? 'Unit ${u + 1}',
        colorHex: unitRow['theme_color'] ?? '#58CC02',
        nodes: nodes,
      ));
    }
    
    // Auto-unlock logic based on progress
    bool foundActive = false;
    for (int u = 0; u < units.length; u++) {
       for (int i = 0; i < units[u].nodes.length; i++) {
          if (units[u].nodes[i].status == NodeStatus.active || units[u].nodes[i].status == NodeStatus.completed) {
              foundActive = true;
          }
       }
    }
    
    // If nothing is active (e.g. brand new user), unlock the first node of the first unit
    if (!foundActive && units.isNotEmpty && units[0].nodes.isNotEmpty) {
       units[0].nodes[0] = units[0].nodes[0].copyWith(status: NodeStatus.active);
    } else {
       // Loop to unlock the next node of the last completed node
       for (int u = 0; u < units.length; u++) {
         for (int i = 0; i < units[u].nodes.length; i++) {
           if (units[u].nodes[i].status == NodeStatus.completed) {
              if (i + 1 < units[u].nodes.length) {
                 if (units[u].nodes[i+1].status == NodeStatus.locked) {
                    units[u].nodes[i+1] = units[u].nodes[i+1].copyWith(status: NodeStatus.active);
                 }
              } else if (u + 1 < units.length && units[u+1].nodes.isNotEmpty) {
                 if (units[u+1].nodes[0].status == NodeStatus.locked) {
                    units[u+1].nodes[0] = units[u+1].nodes[0].copyWith(status: NodeStatus.active);
                 }
              }
           }
         }
       }
    }

    return units;
  }

  void completeLesson(String nodeId) {
    if (state.value == null) return;
    final updatedUnits = List<SkillUnit>.from(state.value!);
    
    bool foundAndUpdated = false;
    
    for (int u = 0; u < updatedUnits.length; u++) {
      final unit = updatedUnits[u];
      final nodeIndex = unit.nodes.indexWhere((n) => n.id == nodeId);
      
      if (nodeIndex != -1) {
        final updatedNodes = List<SkillNode>.from(unit.nodes);
        
        // Mark current lesson as completed
        final currentNode = updatedNodes[nodeIndex];
        final newCompletedLessons = currentNode.completedLessons + 1;
        
        if (newCompletedLessons >= currentNode.totalLessons) {
          // Node fully completed
          updatedNodes[nodeIndex] = currentNode.copyWith(
            completedLessons: newCompletedLessons,
            status: NodeStatus.completed
          );
          
          // Unlock next node
          if (nodeIndex + 1 < updatedNodes.length) {
            updatedNodes[nodeIndex + 1] = updatedNodes[nodeIndex + 1].copyWith(status: NodeStatus.active);
          } else if (u + 1 < updatedUnits.length) {
            // Next node is in the next unit
            final nextUnitNodes = List<SkillNode>.from(updatedUnits[u + 1].nodes);
            if (nextUnitNodes.isNotEmpty) {
              nextUnitNodes[0] = nextUnitNodes[0].copyWith(status: NodeStatus.active);
              updatedUnits[u + 1] = updatedUnits[u + 1].copyWith(nodes: nextUnitNodes);
            }
          }
        } else {
          // Fractional progress
          updatedNodes[nodeIndex] = currentNode.copyWith(completedLessons: newCompletedLessons);
        }
        
        updatedUnits[u] = unit.copyWith(nodes: updatedNodes);
        foundAndUpdated = true;
        
        // Sync to SQLite and Supabase
        _syncService.pushNodeProgress(
          nodeId, 
          updatedNodes[nodeIndex].completedLessons, 
          updatedNodes[nodeIndex].status == NodeStatus.completed
        );
        break;
      }
    }
    
    if (foundAndUpdated) {
      state = AsyncData(updatedUnits);
    }
  }

  void completeNode(String nodeId) {
    if (state.value == null) return;
    final updatedUnits = List<SkillUnit>.from(state.value!);
    
    bool foundAndUpdated = false;
    
    for (int u = 0; u < updatedUnits.length; u++) {
      final unit = updatedUnits[u];
      final nodeIndex = unit.nodes.indexWhere((n) => n.id == nodeId);
      
      if (nodeIndex != -1) {
        final updatedNodes = List<SkillNode>.from(unit.nodes);
        final currentNode = updatedNodes[nodeIndex];
        
        updatedNodes[nodeIndex] = currentNode.copyWith(
          completedLessons: currentNode.totalLessons,
          status: NodeStatus.completed
        );
        
        // Unlock next node
        if (nodeIndex + 1 < updatedNodes.length) {
          updatedNodes[nodeIndex + 1] = updatedNodes[nodeIndex + 1].copyWith(status: NodeStatus.active);
        } else if (u + 1 < updatedUnits.length) {
          final nextUnitNodes = List<SkillNode>.from(updatedUnits[u + 1].nodes);
          if (nextUnitNodes.isNotEmpty) {
            nextUnitNodes[0] = nextUnitNodes[0].copyWith(status: NodeStatus.active);
            updatedUnits[u + 1] = updatedUnits[u + 1].copyWith(nodes: nextUnitNodes);
          }
        }
        
        updatedUnits[u] = unit.copyWith(nodes: updatedNodes);
        foundAndUpdated = true;
        
        // Sync to SQLite and Supabase
        _syncService.pushNodeProgress(
          nodeId, 
          updatedNodes[nodeIndex].completedLessons, 
          updatedNodes[nodeIndex].status == NodeStatus.completed
        );
        break;
      }
    }
    
    if (foundAndUpdated) {
      state = AsyncData(updatedUnits);
    }
  }
}
