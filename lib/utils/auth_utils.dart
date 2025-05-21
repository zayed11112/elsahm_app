import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import 'package:lottie/lottie.dart';

class AuthUtils {
  // Método para mostrar diálogo cuando se requiere autenticación
  static void showAuthRequiredDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 10,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode 
                ? [const Color(0xFF2D3748), const Color(0xFF1A202C)]
                : [Colors.white, const Color(0xFFF7FAFC)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícono de alerta
              Lottie.asset(
                'assets/animations/warning.json',
                width: 100,
                height: 100,
              ),
              
              const SizedBox(height: 20),
              
              // Título
              Text(
                'تسجيل الدخول مطلوب',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 10),
              
              // Mensaje
              Text(
                'هذه الميزة متاحة فقط للمستخدمين المسجلين. يرجى تسجيل الدخول أو إنشاء حساب للاستمرار.',
                style: TextStyle(
                  fontSize: 15,
                  color: isDarkMode ? Colors.white70 : Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botón de cancelar
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        'إلغاء',
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Botón de inicio de sesión
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Cerrar el diálogo
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text(
                      'تسجيل الدخول',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 