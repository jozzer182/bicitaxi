import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/geo_cell_service.dart';
import '../../../core/theme/app_colors.dart';

/// Debug screen for testing GeoCellService cross-platform consistency.
/// Displays canonical strings and cell IDs for test vectors.
class GeoCellDebugScreen extends StatefulWidget {
  const GeoCellDebugScreen({super.key});

  @override
  State<GeoCellDebugScreen> createState() => _GeoCellDebugScreenState();
}

class _GeoCellDebugScreenState extends State<GeoCellDebugScreen> {
  final _latController = TextEditingController(text: '4.7410');
  final _lngController = TextEditingController(text: '-74.0721');
  
  String? _canonical;
  String? _cellId;
  List<String>? _neighborCanonicals;
  List<String>? _neighborCellIds;

  @override
  void initState() {
    super.initState();
    _computeCell();
  }

  void _computeCell() {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);
    
    if (lat == null || lng == null) {
      setState(() {
        _canonical = null;
        _cellId = null;
        _neighborCanonicals = null;
        _neighborCellIds = null;
      });
      return;
    }

    setState(() {
      _canonical = GeoCellService.computeCanonical(lat, lng);
      _cellId = GeoCellService.computeCellId(_canonical!);
      _neighborCanonicals = GeoCellService.computeNeighborCanonicals(lat, lng);
      _neighborCellIds = _neighborCanonicals!.map(GeoCellService.computeCellId).toList();
    });

    // Also print to console for easy comparison
    GeoCellService.debugPrint(lat, lng);
  }

  void _runAllTests() {
    print('\n${'=' * 60}');
    print('FLUTTER GEO CELL TEST VECTORS');
    print('${'=' * 60}\n');
    GeoCellTestVectors.runAllTests();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copiado: $text'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoCellService Debug'),
        backgroundColor: AppColors.electricBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow_rounded),
            onPressed: _runAllTests,
            tooltip: 'Run all test vectors',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Input Coordinates',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _latController,
                            decoration: const InputDecoration(
                              labelText: 'Latitude',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            onChanged: (_) => _computeCell(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _lngController,
                            decoration: const InputDecoration(
                              labelText: 'Longitude',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            onChanged: (_) => _computeCell(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Quick test buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuickButton('Suba', 4.7410, -74.0721),
                        _buildQuickButton('Equator', 0.5, 0.5),
                        _buildQuickButton('Buenos Aires', -34.6037, -58.3816),
                        _buildQuickButton('Madrid', 40.4168, -3.7038),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Results section
            if (_canonical != null) ...[
              Card(
                color: AppColors.electricBlue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Cell',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildResultRow('Canonical', _canonical!),
                      const SizedBox(height: 8),
                      _buildResultRow('Cell ID', _cellId!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Neighbors section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '8 Neighbor Cells',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (var i = 0; i < (_neighborCanonicals?.length ?? 0); i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Neighbor $i',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              _buildResultRow(
                                _neighborCanonicals![i],
                                _neighborCellIds![i],
                                compact: true,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Instructions
            Card(
              color: Colors.amber.withOpacity(0.1),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Cross-Platform Verification',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Run this screen on Flutter\n'
                      '2. Run GeoCellTestVectors.runAllTests() on iOS\n'
                      '3. Compare canonical strings and cell IDs\n'
                      '4. They must be IDENTICAL for each test vector',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickButton(String label, double lat, double lng) {
    return ElevatedButton(
      onPressed: () {
        _latController.text = lat.toString();
        _lngController.text = lng.toString();
        _computeCell();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.electricBlue.withOpacity(0.1),
        foregroundColor: AppColors.electricBlue,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildResultRow(String label, String value, {bool compact = false}) {
    return GestureDetector(
      onTap: () => _copyToClipboard(value),
      child: Container(
        padding: EdgeInsets.all(compact ? 8 : 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!compact)
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  Text(
                    compact ? label : value,
                    style: TextStyle(
                      fontSize: compact ? 11 : 13,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (compact)
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.copy_rounded,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }
}
