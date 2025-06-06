@echo off
echo ========================================
echo       SHA-1 Fingerprints للتطبيق
echo ========================================
echo.

echo 1. Debug SHA-1 Fingerprint:
echo ----------------------------------------
keytool -list -v -alias androiddebugkey -keystore "%USERPROFILE%\.android\debug.keystore" -storepass android -keypass android | findstr "SHA1:"
echo.

echo 2. Release SHA-1 Fingerprint:
echo ----------------------------------------
if exist "android\app\upload-keystore.jks" (
    keytool -list -v -keystore android\app\upload-keystore.jks -alias upload -storepass Okaeslam2020### -keypass Okaeslam2020### | findstr "SHA1:"
) else (
    echo ❌ ملف upload-keystore.jks غير موجود
)
echo.

echo ========================================
echo       معلومات إضافية
echo ========================================
echo Package Name: com.example.elsahm_app
echo.
echo لإضافة هذه الـ SHA-1 fingerprints إلى Firebase:
echo 1. اذهب إلى https://console.firebase.google.com/
echo 2. اختر مشروع elsahm-app
echo 3. Project Settings ^> General ^> Android App
echo 4. أضف SHA-1 fingerprints أعلاه
echo 5. حمّل google-services.json الجديد
echo.
pause
