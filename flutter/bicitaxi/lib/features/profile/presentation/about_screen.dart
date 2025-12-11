import 'package:flutter/material.dart';
import 'package:liquid_glass_ui_design/liquid_glass_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

/// About screen displaying app information and developer credits.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _developerName = 'JOSE ZARABANDA';
  static const String _contactUrl = 'https://zarabanda-dev.web.app';

  Future<void> _launchContactUrl(BuildContext context) async {
    final uri = Uri.parse(_contactUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al abrir el enlace. Reinicia la app.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Acerca de',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.8),
              Colors.white.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // App Icon
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.electricBlue.withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Image.asset(
                        'icons/Android/Icon-512.png',
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // App Name
                  Text(
                    'Bici Taxi',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Versión 1.0.0',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 48),
                  // Developer Info Card
                  LiquidCard(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.code_rounded,
                          color: AppColors.electricBlue,
                          size: 40,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Desarrollado por',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _developerName,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                        ),
                        const SizedBox(height: 24),
                        // Contact Button
                        LiquidButton(
                          borderRadius: 16,
                          onTap: () => _launchContactUrl(context),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.language_rounded,
                                color: AppColors.electricBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'zarabanda-dev.web.app',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.electricBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Footer
                  Text(
                    '© 2024 Bici Taxi',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.black38),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
