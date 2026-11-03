import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../theme.dart';

/// Vending machine inventory management (separate from the app product catalog).
class AdminVending extends StatefulWidget {
  const AdminVending({super.key, required this.service, required this.admin});
  final AdminService service;
  final AdminUser admin;

  @override
  State<AdminVending> createState() => _AdminVendingState();
}

class _AdminVendingState extends State<AdminVending> {
  List<VendingMachine> _machines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _machines = await widget.service.loadMachines();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addMachine() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _MachineDialog(service: widget.service),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      floatingActionButton: widget.admin.canManageCatalog
          ? FloatingActionButton(
              backgroundColor: NYTheme.pink,
              onPressed: _addMachine,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: _machines.isEmpty
          ? const Center(child: Text('No vending machines', style: TextStyle(color: Colors.grey)))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                children: [
                  for (final m in _machines)
                    Card(
                      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: ListTile(
                        title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${m.campus} · ${m.slotCount} slots'),
                        trailing: m.needsRestockCount > 0
                            ? Chip(
                                label: Text('${m.needsRestockCount} low'),
                                backgroundColor: Colors.red.withOpacity(0.15),
                                labelStyle: const TextStyle(color: Colors.red, fontSize: 12),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: m.id == null
                            ? null
                            : () async {
                                await Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => _MachineDetail(
                                    service: widget.service,
                                    machineId: m.id!,
                                    canManage: widget.admin.canManageCatalog,
                                  ),
                                ));
                                _load();
                              },
                      ),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

class _MachineDetail extends StatefulWidget {
  const _MachineDetail({required this.service, required this.machineId, required this.canManage});
  final AdminService service;
  final String machineId;
  final bool canManage;

  @override
  State<_MachineDetail> createState() => _MachineDetailState();
}

class _MachineDetailState extends State<_MachineDetail> {
  VendingMachine? _machine;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _machine = await widget.service.machine(widget.machineId);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _editSlot([VendingSlot? slot]) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _SlotDialog(service: widget.service, machineId: widget.machineId, slot: slot),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final m = _machine;
    final slots = [...?m?.slots]..sort((a, b) => a.slotNumber.compareTo(b.slotNumber));
    return Scaffold(
      appBar: AppBar(title: Text(m?.name ?? 'Machine')),
      floatingActionButton: widget.canManage
          ? FloatingActionButton(
              backgroundColor: NYTheme.pink,
              onPressed: () => _editSlot(),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                children: [
                  if (m != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('${m.campus}${m.location != null ? " · ${m.location}" : ""}',
                          style: const TextStyle(color: Colors.grey)),
                    ),
                  for (final s in slots)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: s.needsRestock ? Colors.red.withOpacity(0.15) : NYTheme.pink.withOpacity(0.15),
                        child: Text('${s.slotNumber}',
                            style: TextStyle(color: s.needsRestock ? Colors.red : NYTheme.pink, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(s.productName),
                      subtitle: Text('On hand ${s.onHand} / hold ${s.hold}',
                          style: TextStyle(color: s.needsRestock ? Colors.red : Colors.grey)),
                      trailing: widget.canManage ? const Icon(Icons.edit, size: 18) : null,
                      onTap: widget.canManage ? () => _editSlot(s) : null,
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

class _MachineDialog extends StatefulWidget {
  const _MachineDialog({required this.service});
  final AdminService service;

  @override
  State<_MachineDialog> createState() => _MachineDialogState();
}

class _MachineDialogState extends State<_MachineDialog> {
  final _name = TextEditingController();
  final _campus = TextEditingController();
  final _location = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Machine'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: _campus, decoration: const InputDecoration(labelText: 'Campus')),
          TextField(controller: _location, decoration: const InputDecoration(labelText: 'Location (optional)')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving || _name.text.trim().isEmpty || _campus.text.trim().isEmpty
              ? null
              : () async {
                  setState(() => _saving = true);
                  try {
                    await widget.service.createMachine(_name.text.trim(), _campus.text.trim(), _location.text.trim());
                    if (context.mounted) Navigator.pop(context, true);
                  } catch (e) {
                    setState(() => _saving = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e is ApiException ? e.message : 'Could not create')));
                    }
                  }
                },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _SlotDialog extends StatefulWidget {
  const _SlotDialog({required this.service, required this.machineId, this.slot});
  final AdminService service;
  final String machineId;
  final VendingSlot? slot;

  @override
  State<_SlotDialog> createState() => _SlotDialogState();
}

class _SlotDialogState extends State<_SlotDialog> {
  late final TextEditingController _slotNumber;
  late final TextEditingController _product;
  late final TextEditingController _onHand;
  late final TextEditingController _hold;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.slot;
    _slotNumber = TextEditingController(text: s == null ? '' : '${s.slotNumber}');
    _product = TextEditingController(text: s?.productName ?? '');
    _onHand = TextEditingController(text: s == null ? '' : '${s.onHand}');
    _hold = TextEditingController(text: s == null ? '10' : '${s.hold}');
  }

  Future<void> _save() async {
    final slotNum = int.tryParse(_slotNumber.text);
    final onHand = int.tryParse(_onHand.text);
    final hold = int.tryParse(_hold.text);
    if (slotNum == null || onHand == null || hold == null || _product.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final body = {
        'slotNumber': slotNum,
        'productName': _product.text.trim(),
        'onHand': onHand,
        'hold': hold,
      };
      if (widget.slot?.id != null) {
        await widget.service.updateSlot(widget.slot!.id!, body);
      } else {
        await widget.service.createSlot(widget.machineId, body);
      }
      if (context.mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : 'Could not save')));
      }
    }
  }

  Future<void> _delete() async {
    if (widget.slot?.id == null) return;
    await widget.service.deleteSlot(widget.slot!.id!);
    if (context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.slot == null ? 'New Slot' : 'Edit Slot'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _slotNumber, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Slot #')),
          TextField(controller: _product, decoration: const InputDecoration(labelText: 'Product')),
          Row(children: [
            Expanded(child: TextField(controller: _onHand, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'On hand'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _hold, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Hold'))),
          ]),
        ],
      ),
      actions: [
        if (widget.slot != null)
          TextButton(onPressed: _saving ? null : _delete, child: const Text('Delete', style: TextStyle(color: Colors.red))),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _saving ? null : _save, child: const Text('Save')),
      ],
    );
  }
}
