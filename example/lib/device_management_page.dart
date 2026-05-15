import 'package:advert/advert.dart';
import 'package:flutter/material.dart';

class DeviceManagementPage extends StatefulWidget {
  const DeviceManagementPage({Key? key}) : super(key: key);

  @override
  State<DeviceManagementPage> createState() => _DeviceManagementPageState();
}

class _DeviceManagementPageState extends State<DeviceManagementPage> {
  final _advert = Advert();
  List<LinkedDevice> _devices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    setState(() => _isLoading = true);
    final devices = await _advert.deviceManager.getLinkedDevices();
    setState(() {
      _devices = devices;
      _isLoading = false;
    });
  }

  Future<void> _registerDevice() async {
    setState(() => _isLoading = true);
    final success = await _advert.deviceManager.registerCurrentDevice();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device registered successfully')),
      );
      _fetchDevices();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to register device')),
      );
    }
  }

  Future<void> _removeDevice(String deviceId) async {
    final success = await _advert.deviceManager.removeDevice(deviceId);
    if (success) {
      _fetchDevices();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove device')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDevices,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _devices.isEmpty
              ? const Center(child: Text('No linked devices found'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _devices.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    return ListTile(
                      leading: Icon(
                        device.platform == 'android' ? Icons.android : Icons.phone_iphone,
                        color: Colors.blueGrey,
                      ),
                      title: Text(device.model),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ID: ${device.deviceId}'),
                          Text('Registered: ${device.registeredAt.toLocal().toString().split('.')[0]}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeDevice(device.deviceId),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _registerDevice,
        label: const Text('Register This Device'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
