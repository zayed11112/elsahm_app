import 'dart:convert';
import 'dart:io'; // For File type
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'package:http/http.dart' as http; // Import http
import 'package:cached_network_image/cached_network_image.dart'; // For network image avatar

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/firestore_service.dart'; // Import FirestoreService
import '../models/user_profile.dart'; // Import UserProfile model
import 'edit_profile_screen.dart'; // Import the actual EditProfileScreen

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();
  final String _imgbbApiKey = 'e5ca1f47577dd78e2b024ada3ecb6dd9'; // Your ImgBB API Key

  bool _isUploading = false; // To show loading indicator during upload

  // --- Image Picking and Uploading Logic ---
  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image == null) return; // User cancelled picker

    setState(() {
      _isUploading = true;
    });

    try {
      final String? imageUrl = await _uploadToImgBB(File(image.path));
      if (imageUrl != null && mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.user != null) {
          await _firestoreService.updateUserProfileField(
            authProvider.user!.uid,
            {'avatarUrl': imageUrl},
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث صورة الملف الشخصي بنجاح!')), // Profile picture updated successfully!
          );
        }
      } else if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('فشل تحميل الصورة.'), backgroundColor: Colors.red), // Failed to upload image.
         );
      }
    } catch (e) {
       print("Image Upload Error: $e");
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('حدث خطأ أثناء تحميل الصورة: $e'), backgroundColor: Colors.red), // Error uploading image
         );
       }
    } finally {
       if (mounted) {
         setState(() {
           _isUploading = false;
         });
       }
    }
  }

  Future<String?> _uploadToImgBB(File imageFile) async {
    final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey');
    final request = http.MultipartRequest('POST', uri);

    // Attach the file
    request.files.add(await http.MultipartFile.fromPath(
      'image', // API parameter name for the file
      imageFile.path,
    ));

    print("Uploading image to ImgBB...");
    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final decodedResponse = jsonDecode(responseBody);
      print("ImgBB Response: $decodedResponse");
      if (decodedResponse['success'] == true && decodedResponse['data'] != null && decodedResponse['data']['url'] != null) {
        return decodedResponse['data']['url']; // Return the image URL
      } else {
         print("ImgBB upload failed: ${decodedResponse['error']?['message'] ?? 'Unknown error'}");
         return null;
      }
    } else {
      print("ImgBB upload failed with status: ${response.statusCode}");
      print("Response body: ${await response.stream.bytesToString()}");
      return null;
    }
  }


  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context); // listen: true to react to logout

    // Use StreamBuilder to listen for user profile updates
    return StreamBuilder<UserProfile?>(
      stream: authProvider.user != null
          ? _firestoreService.getUserProfileStream(authProvider.user!.uid)
          : Stream.value(null), // Provide null stream if user is null
      builder: (context, snapshot) {
        final userProfile = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting || _isUploading;

        // Handle loading and error states
        if (authProvider.status == AuthStatus.authenticating || isLoading && userProfile == null) {
          // Show loading indicator only if profile is not yet loaded or uploading
          return Scaffold(appBar: _buildAppBar(context, theme, authProvider), body: const Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
           return Scaffold(appBar: _buildAppBar(context, theme, authProvider), body: Center(child: Text('خطأ في تحميل الملف الشخصي: ${snapshot.error}'))); // Error loading profile
        }
        if (!snapshot.hasData || userProfile == null) {
          // This case might happen briefly after login before Firestore stream updates
          // Or if the initial profile creation failed.
           return Scaffold(appBar: _buildAppBar(context, theme, authProvider), body: const Center(child: Text('لم يتم العثور على الملف الشخصي.'))); // Profile not found.
        }

        // --- Main Scaffold when data is loaded ---
        return Scaffold(
          appBar: _buildAppBar(context, theme, authProvider),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            children: [
              _buildUserProfileSection(context, theme, userProfile, isLoading),
              const SizedBox(height: 24.0),
              Divider(color: Colors.grey[700]),
              const SizedBox(height: 16.0),
              _buildCompanyInfoSection(context, theme),
              const SizedBox(height: 24.0),
              Divider(color: Colors.grey[700]),
              const SizedBox(height: 16.0),
              _buildWhatsAppGroupsSection(context, theme),
              const SizedBox(height: 24.0),
              Divider(color: Colors.grey[700]),
              const SizedBox(height: 16.0),
              _buildTelegramGroupsSection(context, theme),
              const SizedBox(height: 24.0),
            ],
          ),
        );
      },
    );
  }

  // --- AppBar Widget ---
  AppBar _buildAppBar(BuildContext context, ThemeData theme, AuthProvider authProvider) {
     return AppBar(
        title: const Text('حسابي'), // My Account
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return IconButton(
                icon: Icon(
                  themeProvider.themeMode == ThemeMode.dark
                      ? Icons.light_mode_outlined
                      : themeProvider.themeMode == ThemeMode.light
                          ? Icons.dark_mode_outlined
                          : Icons.brightness_auto_outlined,
                ),
                tooltip: 'تغيير السمة',
                onPressed: () {
                  Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                },
              );
            }
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              await authProvider.signOut();
            },
          ),
        ],
      );
  }

  // --- User Profile Section Widget ---
  Widget _buildUserProfileSection(BuildContext context, ThemeData theme, UserProfile userProfile, bool isUploading) {
     final textTheme = theme.textTheme;
     final colorScheme = theme.colorScheme;
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 55,
              backgroundColor: Colors.grey[700],
              child: isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : userProfile.avatarUrl.isEmpty
                      ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                      : ClipOval( // Clip the image to be circular
                          child: CachedNetworkImage(
                            imageUrl: userProfile.avatarUrl,
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => Icon(Icons.error, color: Colors.red[300]),
                            width: 110, // Double the radius
                            height: 110,
                            fit: BoxFit.cover,
                          ),
                        ),
            ),
            // Edit Avatar Button
            if (!isUploading) // Hide button while uploading
              CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primary,
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, size: 18, color: Colors.black),
                  onPressed: _pickAndUploadImage, // Call the upload function
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12.0),
        Text(userProfile.name.isNotEmpty ? userProfile.name : 'اسم المستخدم', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)), // Username or placeholder
        Text(userProfile.status, style: textTheme.bodyMedium?.copyWith(color: Colors.grey[400])),
        const SizedBox(height: 20.0),
        OutlinedButton.icon(
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('تعديل البيانات'),
          onPressed: () {
            // TODO: Navigate to EditProfileScreen, passing userProfile
             print('Edit profile tapped');
             Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(userProfile: userProfile)));
          },
          style: OutlinedButton.styleFrom(
             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          ),
        ),
        const SizedBox(height: 24.0),
        Card(
           color: theme.cardColor,
           elevation: 0,
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
           child: Padding(
             padding: const EdgeInsets.all(16.0),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text('معلومات الطالب', style: textTheme.titleLarge),
                 const SizedBox(height: 16),
                 _buildInfoRow(Icons.person_outline, 'الاسم الكامل:', userProfile.name.isNotEmpty ? userProfile.name : '-', theme),
                 _buildInfoRow(Icons.school_outlined, 'الكلية:', userProfile.faculty.isNotEmpty ? userProfile.faculty : '-', theme), // Display only Arabic faculty
                 _buildInfoRow(Icons.location_city_outlined, 'الفرع:', userProfile.branch.isNotEmpty ? userProfile.branch : '-', theme), // Display Branch
                 _buildInfoRow(Icons.calendar_today_outlined, 'الدفعة:', userProfile.batch.isNotEmpty ? userProfile.batch : '-', theme),
                 _buildInfoRow(Icons.badge_outlined, 'الرقم الجامعي:', userProfile.studentId.isNotEmpty ? userProfile.studentId : '-', theme), // Display Student ID
               ],
             ),
           ),
        ),
      ],
    );
  }

  // --- Company Info Section Widget ---
   Widget _buildCompanyInfoSection(BuildContext context, ThemeData theme) {
     final textTheme = theme.textTheme;
     // Static data for now
     const String companyEmail = 'elsahm.arish@gmail.com';
     const String companyPhone1 = '01093130120';
     const String companyPhone2 = '01003193622';
     const String companyFacebook = 'facebook.com/elsahm.arish';

     return Card(
       color: theme.cardColor,
       elevation: 0,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
       child: Padding(
         padding: const EdgeInsets.all(16.0),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text('معلومات عن شركة السهم', style: textTheme.titleLarge),
             const SizedBox(height: 16),
             _buildInfoRow(Icons.email_outlined, 'البريد:', companyEmail, theme, isSelectable: true),
             _buildInfoRow(Icons.phone_outlined, 'الهاتف:', '$companyPhone1\n$companyPhone2', theme, isSelectable: true),
             _buildInfoRow(Icons.facebook, 'فيسبوك:', companyFacebook, theme, isSelectable: true, isUrl: true),
           ],
         ),
       ),
     );
   }

  // --- WhatsApp Groups Section Widget ---
  Widget _buildWhatsAppGroupsSection(BuildContext context, ThemeData theme) {
     final textTheme = theme.textTheme;
     final colorScheme = theme.colorScheme;
     // Placeholder data
     final housingGroups = [
      {'name': 'جروب تسكين 1', 'icon': Icons.home_work_outlined, 'link': 'YOUR_WHATSAPP_HOUSING_LINK_1'},
      {'name': 'جروب تسكين 2', 'icon': Icons.home_work_outlined, 'link': 'YOUR_WHATSAPP_HOUSING_LINK_2'},
    ];
    final facultyGroups = [
      {'name': 'جروب حاسبات ومعلومات', 'icon': Icons.computer, 'link': 'YOUR_WHATSAPP_CS_LINK'},
      {'name': 'جروب هندسة', 'icon': Icons.engineering, 'link': 'YOUR_WHATSAPP_ENG_LINK'},
      {'name': 'جروب صيدلة', 'icon': Icons.local_pharmacy_outlined, 'link': 'YOUR_WHATSAPP_PHARM_LINK'},
      {'name': 'جروب أسنان', 'icon': Icons.local_hospital_outlined, 'link': 'YOUR_WHATSAPP_DENT_LINK'},
      {'name': 'جروب استفسار وتقديم', 'icon': Icons.help_outline, 'link': 'YOUR_WHATSAPP_INQUIRY_LINK'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.chat_bubble, color: colorScheme.primary, size: 24),
            const SizedBox(width: 8),
            Text('جروبات واتساب', style: textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 16),
        Text('', style: textTheme.titleMedium?.copyWith(color: Colors.white70)),
        const SizedBox(height: 8),
        Center(child: CircleAvatar(radius: 40, backgroundColor: Colors.grey[800], child: Icon(Icons.groups, size: 40, color: Colors.grey[500]))),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: housingGroups.length,
          itemBuilder: (context, index) => _buildGroupLinkItem(
            context, theme, housingGroups[index]['icon']! as IconData, housingGroups[index]['name']! as String, Icons.chat, () {
              print('Tapped WhatsApp Housing Group: ${housingGroups[index]['name']}');
              // TODO: Launch URL: housingGroups[index]['link']! as String
            }
          ),
          separatorBuilder: (context, index) => const SizedBox(height: 8),
        ),
        const SizedBox(height: 20),
        Text('', style: textTheme.titleMedium?.copyWith(color: Colors.white70)),
        const SizedBox(height: 8),
        Center(child: CircleAvatar(radius: 40, backgroundColor: Colors.grey[800], child: Icon(Icons.school, size: 40, color: Colors.grey[500]))),
        const SizedBox(height: 12),
         ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: facultyGroups.length,
          itemBuilder: (context, index) => _buildGroupLinkItem(
            context, theme, facultyGroups[index]['icon']! as IconData, facultyGroups[index]['name']! as String, Icons.chat, () {
              print('Tapped WhatsApp Faculty Group: ${facultyGroups[index]['name']}');
              // TODO: Launch URL: facultyGroups[index]['link']! as String
            }
          ),
          separatorBuilder: (context, index) => const SizedBox(height: 8),
        ),
      ],
    );
  }

  // --- Telegram Groups Section Widget ---
  Widget _buildTelegramGroupsSection(BuildContext context, ThemeData theme) {
     final textTheme = theme.textTheme;
     final colorScheme = theme.colorScheme;
     // Placeholder data
    final telegramGroups = [
      {'name': 'سكن استديو (ولاد وبنات)', 'icon': Icons.home_outlined, 'link': 'YOUR_TELEGRAM_STUDIO_LINK'},
      {'name': 'سكن أولاد (أوضة/سرير)', 'icon': Icons.boy, 'link': 'YOUR_TELEGRAM_BOYS_LINK'},
      {'name': 'سكن بنات (أوضة/سرير)', 'icon': Icons.girl, 'link': 'YOUR_TELEGRAM_GIRLS_LINK'},
      {'name': 'شقق غرفتين', 'icon': Icons.apartment, 'link': 'YOUR_TELEGRAM_APT2_LINK'},
      {'name': 'شقق 3 غرف', 'icon': Icons.holiday_village, 'link': 'YOUR_TELEGRAM_APT3_LINK'},
      {'name': 'شقق 4 غرف', 'icon': Icons.maps_home_work_outlined, 'link': 'YOUR_TELEGRAM_APT4_LINK'},
      {'name': 'قرية سما العريش', 'icon': Icons.location_on_outlined, 'link': 'YOUR_TELEGRAM_SAMA_LINK'},
    ];

     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.send, color: colorScheme.primary, size: 24),
            const SizedBox(width: 8),
            Text('جروبات تليجرام', style: textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 16),
        Center(child: CircleAvatar(radius: 40, backgroundColor: colorScheme.primary.withOpacity(0.8), child: Icon(Icons.send, size: 40, color: Colors.white))),
        const SizedBox(height: 12),
         ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: telegramGroups.length,
          itemBuilder: (context, index) => _buildGroupLinkItem(
            context, theme, telegramGroups[index]['icon']! as IconData, telegramGroups[index]['name']! as String, Icons.send, () {
              print('Tapped Telegram Group: ${telegramGroups[index]['name']}');
              // TODO: Launch URL: telegramGroups[index]['link']! as String
            }
          ),
          separatorBuilder: (context, index) => const SizedBox(height: 8),
        ),
      ],
    );
  }

  // --- Helper Widgets ---
  Widget _buildInfoRow(IconData icon, String label, String value, ThemeData theme, {bool isSelectable = false, bool isUrl = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: isSelectable
              ? SelectableText(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isUrl ? Colors.blue[300] : Colors.white,
                    decoration: isUrl ? TextDecoration.underline : TextDecoration.none,
                  ),
                  onTap: isUrl ? () {
                    // TODO: Implement URL launching
                    print('Tapped URL: $value');
                  } : null,
                )
              : Text(
                  value,
                  style: theme.textTheme.bodyMedium,
                  softWrap: true,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupLinkItem(BuildContext context, ThemeData theme, IconData leadingIcon, String title, IconData trailingIcon, VoidCallback onTap) {
    return Card(
      color: theme.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[800]!, width: 0.5),
      ),
      child: ListTile(
        leading: Icon(leadingIcon, color: theme.colorScheme.primary),
        title: Text(title, style: theme.textTheme.bodyLarge),
        trailing: Icon(trailingIcon, color: Colors.grey[500], size: 20),
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      ),
    );
  }
}

// Removed placeholder EditProfileScreen class definition
