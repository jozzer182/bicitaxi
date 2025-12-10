import 'package:flutter/material.dart';
import 'package:liquid_glass_ui_design/liquid_glass_ui.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_layout.dart';

/// Payment methods screen for the Bici Taxi client app.
/// Shows available payment options with "Efectivo" as default.
class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  String _selectedMethod = 'efectivo';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Métodos de pago',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: ResponsiveUtils.getHorizontalPadding(context),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveUtils.getContentMaxWidth(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                // Active payment method
                _buildPaymentOption(
                  icon: Icons.money_rounded,
                  title: 'Efectivo',
                  subtitle: 'Pago al finalizar el viaje',
                  value: 'efectivo',
                  isEnabled: true,
                  iconColor: AppColors.success,
                ),
                const SizedBox(height: 12),
                // Nequi option
                _buildPaymentOption(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Nequi',
                  subtitle: 'Paga con tu cuenta Nequi',
                  value: 'nequi',
                  isEnabled: false,
                  iconColor: const Color(0xFFE91E63), // Nequi pink
                ),
                const SizedBox(height: 12),
                // Card option
                _buildPaymentOption(
                  icon: Icons.credit_card_rounded,
                  title: 'Tarjeta débito/crédito',
                  subtitle: 'Visa, Mastercard, American Express',
                  value: 'card',
                  isEnabled: false,
                  iconColor: AppColors.electricBlue,
                ),
                const SizedBox(height: 12),
                // Daviplata option
                _buildPaymentOption(
                  icon: Icons.phone_android_rounded,
                  title: 'Daviplata',
                  subtitle: 'Paga con tu cuenta Daviplata',
                  value: 'daviplata',
                  isEnabled: false,
                  iconColor: const Color(0xFFED1C24), // Daviplata red
                ),
                const SizedBox(height: 24),
                // Coming soon message
                LiquidCard(
                  borderRadius: 16,
                  color: AppColors.electricBlue.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.electricBlue,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Los métodos de pago adicionales se habilitarán próximamente.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required bool isEnabled,
    required Color iconColor,
  }) {
    final isSelected = _selectedMethod == value && isEnabled;

    return GestureDetector(
      onTap: isEnabled ? () => setState(() => _selectedMethod = value) : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.6,
        child: LiquidCard(
          borderRadius: 14,
          color: isSelected
              ? AppColors.electricBlue.withValues(alpha: 0.15)
              : null,
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: isSelected
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.electricBlue, width: 2),
                  )
                : null,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: isEnabled
                                    ? Colors.black87
                                    : Colors.black54,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isEnabled) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Próximamente',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black45,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                if (isEnabled)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.electricBlue
                            : Colors.black38,
                        width: 2,
                      ),
                      color: isSelected ? AppColors.electricBlue : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: AppColors.white,
                          )
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
