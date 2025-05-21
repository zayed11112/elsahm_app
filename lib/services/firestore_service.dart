import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart'; // Import the UserProfile model
import '../models/apartment.dart'; // Import the Apartment model
import 'dart:async';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Logger _logger = Logger('FirestoreService');

  // Reference to the users collection
  CollectionReference<UserProfile> get usersCollection => _db
      .collection('users')
      .withConverter<UserProfile>(
        fromFirestore: (snapshot, _) => UserProfile.fromFirestore(snapshot),
        toFirestore: (userProfile, _) => userProfile.toFirestore(),
      );

  // Reference to the apartments collection
  CollectionReference<Apartment> get apartmentsCollection => _db
      .collection('apartments')
      .withConverter<Apartment>(
        fromFirestore: (snapshot, _) => Apartment.fromFirestore(snapshot),
        toFirestore: (apartment, _) => apartment.toFirestore(),
      );

  // Get a user's profile stream
  Stream<UserProfile?> getUserProfileStream(String uid) {
    return usersCollection.doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data();
      }
      return null; // Return null if profile doesn't exist yet
    });
  }

  // Get a user's profile once
  Future<UserProfile?> getUserProfile(String uid) async {
    final snapshot = await usersCollection.doc(uid).get();
    if (snapshot.exists) {
      return snapshot.data();
    }
    return null;
  }

  // Create or update a user's profile
  // Creates the document if it doesn't exist, updates if it does.
  Future<void> setUserProfile(UserProfile userProfile) async {
    try {
      await usersCollection
          .doc(userProfile.uid)
          .set(userProfile, SetOptions(merge: true));
      if (kDebugMode) {
        _logger.info("User profile set/updated for ${userProfile.uid}");
      }
    } catch (e) {
      _logger.severe("Error setting user profile: $e");
      // Optionally re-throw or handle the error
      rethrow;
    }
  }

  // Update specific fields in a user's profile
  Future<void> updateUserProfileField(
    String uid,
    Map<String, dynamic> data,
  ) async {
    try {
      await usersCollection.doc(uid).update(data);
      if (kDebugMode) {
        _logger.info("User profile field(s) updated for $uid");
      }
    } catch (e) {
      _logger.severe("Error updating user profile field: $e");
      rethrow;
    }
  }

  // Helper to create initial profile if one doesn't exist on signup/first login
  Future<bool> createInitialUserProfile(String uid, String email) async {
    final profile = await getUserProfile(uid);
    if (profile == null) {
      if (kDebugMode) {
        _logger.info("Creating initial profile for $uid");
      }
      
      // Initialize with empty fcmTokens array for notifications
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'fcmTokens': [], // Initialize empty array for tokens
        'role': 'user', // Default role
      });
      
      return true; // A new profile was created
    }
    return false; // Profile already existed
  }

  // Get the latest apartments
  Future<List<Apartment>> getLatestApartments({int limit = 10}) async {
    try {
      if (kDebugMode) {
        _logger.info('Fetching latest apartments...');
      }

      // جلب الشقق مع تحديد الحد الأقصى وترتيبها حسب تاريخ الإنشاء
      final snapshot =
          await _db
              .collection('apartments')
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

      // تحويل البيانات إلى قائمة من الشقق
      final apartments =
          snapshot.docs.map((doc) {
            final apartment = Apartment.fromFirestore(doc);

            // التحقق من صحة روابط الصور
            _validateImageUrls(apartment);

            return apartment;
          }).toList();

      if (kDebugMode) {
        _logger.info('Fetched ${apartments.length} apartments successfully');
      }
      return apartments;
    } catch (e) {
      _logger.severe('Error in getLatestApartments: $e');
      return [];
    }
  }

  // تحديث قائمة الشقق باستمرار
  Stream<List<Apartment>> getLatestApartmentsStream({int limit = 10}) {
    return _db
        .collection('apartments')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final apartments =
              snapshot.docs.map((doc) {
                final apartment = Apartment.fromFirestore(doc);
                // التحقق من صحة روابط الصور هنا أيضًا
                _validateImageUrls(apartment);
                return apartment;
              }).toList();

          if (kDebugMode) {
            _logger.info('Stream updated with ${apartments.length} apartments');
          }
          return apartments;
        });
  }

  // Get apartments by category
  Future<List<Apartment>> getApartmentsByCategory(
    String category, {
    int limit = 10,
  }) async {
    try {
      if (kDebugMode) {
        _logger.info('Fetching apartments by category: $category');
      }

      // البحث عن الشقق التي تنتمي للفئة المحددة
      final snapshot =
          await _db
              .collection('apartments')
              .where('category', isEqualTo: category)
              .limit(limit)
              .get();

      // تحويل البيانات إلى قائمة من الشقق
      final apartments =
          snapshot.docs.map((doc) {
            final apartment = Apartment.fromFirestore(doc);

            // التحقق من صحة روابط الصور
            _validateImageUrls(apartment);

            return apartment;
          }).toList();

      if (kDebugMode) {
        _logger.info(
          'Fetched ${apartments.length} apartments for category $category',
        );
      }
      return apartments;
    } catch (e) {
      _logger.severe('Error in getApartmentsByCategory: $e');
      return [];
    }
  }

  // Get all categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      // Try to fetch categories from Firestore
      final categoriesCollection = _db.collection('categories');
      final query = await categoriesCollection.orderBy('order').get();

      if (query.docs.isEmpty) {
        // إذا لم توجد أقسام، استخدم القيم الافتراضية
        if (kDebugMode) {
          _logger.info('No categories found, using default values');
        }
        return [
          {'id': '1', 'label': 'سكن الطلاب', 'icon': 'meeting_room'},
          {'id': '2', 'label': 'سكن الطالبات', 'icon': 'meeting_room'},
          {'id': '3', 'label': 'شقق عائلية', 'icon': 'apartment'},
          {'id': '4', 'label': 'استوديو', 'icon': 'single_bed'},
          {'id': '5', 'label': 'فيلا', 'icon': 'home'},
          {'id': '6', 'label': 'شقة مفروشة', 'icon': 'chair'},
          {'id': '7', 'label': 'شقة غير مفروشة', 'icon': 'apartment'},
          {'id': '8', 'label': 'أخرى', 'icon': 'category'},
        ];
      }

      // تحويل بيانات Firestore إلى الصيغة المتوقعة
      final categories =
          query.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'label': data['name'] ?? 'غير معروف',
              'icon': data['icon'] ?? 'category',
            };
          }).toList();

      if (kDebugMode) {
        _logger.info('Fetched ${categories.length} categories from Firestore');
      }
      return categories;
    } catch (e) {
      _logger.severe("Error fetching categories: $e");
      // إعادة القيم الافتراضية في حالة الخطأ
      return [
        {'id': '1', 'label': 'سكن الطلاب', 'icon': 'meeting_room'},
        {'id': '2', 'label': 'سكن الطالبات', 'icon': 'meeting_room'},
        {'id': '3', 'label': 'شقق عائلية', 'icon': 'apartment'},
        {'id': '4', 'label': 'استوديو', 'icon': 'single_bed'},
        {'id': '5', 'label': 'فيلا', 'icon': 'home'},
        {'id': '6', 'label': 'شقة مفروشة', 'icon': 'chair'},
        {'id': '7', 'label': 'شقة غير مفروشة', 'icon': 'apartment'},
        {'id': '8', 'label': 'أخرى', 'icon': 'category'},
      ];
    }
  }

  // دالة جديدة للتحقق من صحة روابط الصور
  void _validateImageUrls(Apartment apartment) {
    // التحقق من وجود روابط صور
    if (apartment.imageUrls.isEmpty && apartment.images.isNotEmpty) {
      // استخدام حقل images إذا كان imageUrls فارغاً
      if (kDebugMode) {
        _logger.info(
          'Using images field instead of imageUrls for apartment: ${apartment.id}',
        );
      }
      apartment.imageUrls.addAll(apartment.images);
    }

    // التحقق من صحة روابط الصور
    List<String> validUrls =
        apartment.imageUrls
            .where(
              (url) =>
                  url.isNotEmpty &&
                  (url.startsWith('http') || url.startsWith('https')),
            )
            .toList();

    // إذا لم تكن هناك روابط صالحة، أضف روابط افتراضية
    if (validUrls.isEmpty) {
      if (kDebugMode) {
        _logger.warning(
          'No valid image URLs found for apartment: ${apartment.id}, using default images',
        );
      }

      // إضافة صور افتراضية حسب فئة الشقة
      switch (apartment.category.toLowerCase()) {
        case 'شقة':
          apartment.imageUrls.add(
            'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267',
          );
          break;
        case 'غرفة':
          apartment.imageUrls.add(
            'https://images.unsplash.com/photo-1540518614846-7eded433c457',
          );
          break;
        case 'سكن طلاب':
          apartment.imageUrls.add(
            'https://images.unsplash.com/photo-1555854877-bab0e564b8d5',
          );
          break;
        default:
          apartment.imageUrls.add(
            'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2',
          );
      }
    }
  }

  // إضافة طلب شحن المحفظة إلى جدول "الحجوزات"
  Future<String> addWalletChargeRequest(
    Map<String, dynamic> requestData,
  ) async {
    try {
      // إضافة البيانات إلى مجموعة "الحجوزات" في Firestore
      final DocumentReference docRef = await _db
          .collection('الحجوزات')
          .add(requestData);
      if (kDebugMode) {
        _logger.info(
          "Wallet charge request added successfully with ID: ${docRef.id}",
        );
      }
      return docRef.id; // إرجاع معرف المستند
    } catch (e) {
      _logger.severe("Error adding wallet charge request: $e");
      rethrow;
    }
  }

  // جلب طلبات شحن المحفظة للمستخدم حسب الحالة - طريقة بديلة أكثر ثباتًا
  Stream<List<Map<String, dynamic>>> getUserPaymentRequestsAlternative(
    String userId,
    String status,
  ) {
    try {
      if (kDebugMode) {
        _logger.info('Using alternative method to fetch payment requests');
      }

      // إنشاء مولّد تدفق يدوي
      final controller =
          StreamController<List<Map<String, dynamic>>>.broadcast();

      // وظيفة لجلب البيانات وإضافتها إلى التدفق
      void fetchData() async {
        try {
          final snapshot = await _db.collection('الحجوزات').get();

          final requests =
              snapshot.docs
                  .map((doc) {
                    final data = doc.data();
                    data['id'] = doc.id;
                    return data;
                  })
                  // تصفية البيانات في الكود بدلاً من الاستعلام
                  .where(
                    (data) =>
                        data['userId'] == userId && data['status'] == status,
                  )
                  // ترتيب البيانات يدويًا
                  .toList()
                ..sort((a, b) {
                  final aDate = a['createdAt'] as String? ?? '';
                  final bDate = b['createdAt'] as String? ?? '';
                  return bDate.compareTo(aDate); // ترتيب تنازلي
                });

          if (kDebugMode) {
            _logger.info(
              'Fetched ${requests.length} payment requests (alternative) with status: $status for user: $userId',
            );
          }

          // إضافة البيانات إلى التدفق
          if (!controller.isClosed) {
            controller.add(requests);
          }
        } catch (e) {
          _logger.warning('Error in fetchData: $e');
          if (!controller.isClosed) {
            controller.add([]); // إضافة قائمة فارغة في حالة الخطأ
          }
        }
      }

      // جلب البيانات فورًا
      fetchData();

      // إعداد مؤقت لتحديث البيانات كل 10 ثوانٍ
      final timer = Timer.periodic(const Duration(seconds: 10), (_) {
        fetchData();
      });

      // إغلاق المولّد والمؤقت عند إغلاق التدفق
      controller.onCancel = () {
        timer.cancel();
        controller.close();
      };

      return controller.stream;
    } catch (e) {
      _logger.severe('Error in alternative payment requests method: $e');
      return Stream.value([]);
    }
  }

  // جلب طلبات شحن المحفظة للمستخدم حسب الحالة
  Stream<List<Map<String, dynamic>>> getUserPaymentRequestsStream(
    String userId,
    String status,
  ) {
    try {
      if (kDebugMode) {
        _logger.info(
          'Fetching payment requests for user: $userId, status: $status',
        );
      }

      // حاول استخدام الطريقة الأساسية مع معالجة خاصة للخطأ
      final streamController =
          StreamController<List<Map<String, dynamic>>>.broadcast();
      late StreamSubscription<QuerySnapshot<Map<String, dynamic>>> subscription;

      // إنشاء استعلام Firestore
      final query = _db
          .collection('الحجوزات')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true);

      // الاشتراك بالاستعلام
      subscription = query.snapshots().listen(
        (snapshot) {
          final requests =
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList();

          if (kDebugMode) {
            _logger.info(
              'Successfully fetched ${requests.length} payment requests with status: $status',
            );
          }
          streamController.add(requests);
        },
        onError: (error) {
          _logger.warning(
            'Error in primary query: $error - switching to alternative method',
          );

          // في حالة الخطأ، التبديل إلى الطريقة البديلة
          final alternativeStream = getUserPaymentRequestsAlternative(
            userId,
            status,
          );

          // تمرير بيانات التدفق البديل إلى المولّد الرئيسي
          final altSubscription = alternativeStream.listen(
            (data) => streamController.add(data),
            onError: (e) => streamController.addError(e),
            onDone: () {
              if (!streamController.isClosed) {
                streamController.close();
              }
            },
          );

          // إلغاء الاشتراك الأصلي
          subscription.cancel();

          // تحديث إغلاق المولّد لإلغاء الاشتراك البديل أيضًا
          final oldOnCancel = streamController.onCancel;
          streamController.onCancel = () {
            altSubscription.cancel();
            if (oldOnCancel != null) {
              oldOnCancel();
            }
          };
        },
        onDone: () {
          if (!streamController.isClosed) {
            streamController.close();
          }
        },
      );

      // إلغاء الاشتراك عند إغلاق المولّد
      streamController.onCancel = () {
        subscription.cancel();
      };

      return streamController.stream;
    } catch (e) {
      _logger.severe('Error setting up payment requests stream: $e');
      return getUserPaymentRequestsAlternative(userId, status);
    }
  }

  // دالة لإعادة تحميل بيانات المستخدم من قاعدة البيانات
  Future<UserProfile?> refreshUserData(String uid) async {
    try {
      if (kDebugMode) {
        _logger.info('تحديث بيانات المستخدم: $uid');
      }
      
      // إجبار قاعدة البيانات على تحديث البيانات بدون استخدام التخزين المؤقت
      final DocumentSnapshot<UserProfile> snapshot = await usersCollection
          .doc(uid)
          .get(const GetOptions(source: Source.server));
      
      if (snapshot.exists) {
        final userProfile = snapshot.data();
        if (kDebugMode) {
          _logger.info('تم تحديث بيانات المستخدم بنجاح، الرصيد الحالي: ${userProfile?.balance}');
        }
        return userProfile;
      } else {
        _logger.warning('لم يتم العثور على ملف المستخدم: $uid');
        return null;
      }
    } catch (e) {
      _logger.severe('خطأ في تحديث بيانات المستخدم: $e');
      return null;
    }
  }
}
