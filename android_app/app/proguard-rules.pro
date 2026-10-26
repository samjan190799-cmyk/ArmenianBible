# Gson читает модели через рефлексию: всё из пакета data остаётся как есть
-keepattributes Signature, *Annotation*, InnerClasses, EnclosingMethod
-keep class com.example.armenianbible.data.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-dontwarn com.google.gson.**
# Имена не меняем: проще разбирать сбои, выигрыш даёт сжатие кода и ресурсов
-dontobfuscate
