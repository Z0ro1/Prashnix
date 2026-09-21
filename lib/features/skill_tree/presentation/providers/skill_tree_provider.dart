import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'skill_tree_provider.g.dart';

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
  @override
  List<SkillUnit> build() {
    return _generateMockUnits(1);
  }

  List<SkillUnit> _generateMockUnits(int count) {
    final units = <SkillUnit>[];
    
    // Duolingo-like vivid colors
    final colors = [
      '#58CC02', // Feather Green
      '#1CB0F6', // Sky Blue
      '#CE82FF', // Purple
      '#FF9600', // Fox Orange
      '#FF4B4B', // Red
    ];

    int globalNodeIndex = 0;
    // Hardcode an active node at a specific global index
    final activeGlobalIndex = 2; 

    for (int u = 0; u < count; u++) {
      final nodes = <SkillNode>[];
      final nodeCount = 6; // Nodes per unit
      
      for (int i = 0; i < nodeCount; i++) {
        final isMilestone = i == nodeCount - 1;
        NodeStatus status;
        
        if (globalNodeIndex < activeGlobalIndex) {
          status = NodeStatus.completed;
        } else if (globalNodeIndex == activeGlobalIndex) {
          status = NodeStatus.active;
        } else {
          status = NodeStatus.locked;
        }

        // We will resolve icons in UI, just keep simple types here
        String icon = 'star';
        if (i % 3 == 1) icon = 'dumbbell';
        if (isMilestone) icon = 'chest';

        final totalLessons = 4 + (globalNodeIndex % 3);
        int completedLessons = 0;
        
        if (status == NodeStatus.completed) {
          completedLessons = totalLessons;
        } else if (status == NodeStatus.active) {
          completedLessons = totalLessons ~/ 2; // Partially fill the progress ring
        }

        nodes.add(SkillNode(
          id: 'node_$globalNodeIndex',
          title: isMilestone ? 'Unit $u Review' : 'Level ${i + 1}',
          icon: icon,
          status: status,
          type: isMilestone ? NodeType.milestone : NodeType.standard,
          totalLessons: totalLessons,
          completedLessons: completedLessons,
        ));
        globalNodeIndex++;
      }

      units.add(SkillUnit(
        id: 'unit_$u',
        unitNumber: u + 1,
        sectionNumber: (u ~/ 5) + 1,
        title: 'Learn basic phrases and greetings',
        colorHex: colors[u % colors.length],
        nodes: nodes,
      ));
    }

    return units;
  }

  void completeLesson(String nodeId) {
    final updatedUnits = List<SkillUnit>.from(state);
    
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
        break;
      }
    }
    
    if (foundAndUpdated) {
      state = updatedUnits;
    }
  }

  void completeNode(String nodeId) {
    final updatedUnits = List<SkillUnit>.from(state);
    
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
        break;
      }
    }
    
    if (foundAndUpdated) {
      state = updatedUnits;
    }
  }
}
