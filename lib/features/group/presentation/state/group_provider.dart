import 'package:flutter/material.dart';
import '../../../../core/models/models.dart';
import '../../../../core/models/mock_data.dart';

class GroupProvider extends ChangeNotifier {
  List<BuyingGroup> _groups = MockData.demoGroups;

  List<BuyingGroup> get groups => _groups;

  void setGroups(List<BuyingGroup> groups) {
    _groups = groups;
    notifyListeners();
  }

  BuyingGroup? getGroupById(String id) {
    try {
      return _groups.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  List<BuyingGroup> getMyGroups(String? currentUserId) {
    if (currentUserId == null) return [];
    return _groups.where((g) => g.members.any((m) => m.userId == currentUserId)).toList();
  }
}
