# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.** { *; }
-keep public class com.google.gson.reflect.TypeToken
-keep public class * extends com.google.gson.reflect.TypeToken
-keep public class * implements com.google.gson.TypeAdapterFactory
-keep class com.google.crypto.tink.** { *; }

# Timezone data preservation
-keep class com.timezone.** { *; }
-keep class net.wolverinebeach.flutter_timezone.** { *; }

# Keep notification receivers and boot receiver
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.NotificationService { *; }
-keep class com.dexterous.flutterlocalnotifications.RepeatInterval { *; }
