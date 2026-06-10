# Jetta 🚛

Türkiye'nin dijital yük ve tır eşleştirme platformu — "yük taşımacılığında Uber" MVP prototipi.

Flutter ile geliştirilmiştir (iOS + Android). Şu an mock verilerle çalışan, backend'siz bir prototiptir.

## Özellikler

- **İki rol:** Yük veren (ilan açar, teklifleri karşılaştırır, aracı atar) ve şoför/nakliyeci (yük pazarını gezer, teklif verir, taşımayı yönetir)
- 3 adımlı yük ilanı sihirbazı (güzergâh → yük bilgisi → tarih & bütçe)
- Şehir/araç tipi filtreli yük pazarı, km başına kazanç hesabı
- Teklif karşılaştırma ("en iyi fiyat" rozeti) ve canlı taşıma durumu zaman çizelgesi
- "Gece Otoyolu" tasarım dili: plaka rozetleri, animasyonlu rota çizgileri, ikaz şeridi desenleri

## Geliştirme

```bash
flutter pub get
flutter run          # bağlı cihaz/emülatörde çalıştırır
flutter analyze      # statik analiz
flutter test         # widget testleri
```

## CI/CD (Codemagic)

Yapılandırma [codemagic.yaml](codemagic.yaml) dosyasındadır.

| Workflow | Tetikleyici | Çıktı |
|---|---|---|
| `android-apk` | `main` branch'ine push | Release APK (artifact) |
| `ios-testflight` | `main` branch'ine push | İmzalı IPA → TestFlight |

### İlk kurulum

1. [Codemagic](https://codemagic.io)'te bu GitHub deposunu uygulama olarak ekleyin.
2. **iOS imza:** *Teams → Integrations → App Store Connect* altında `jetta-asc-api-key` adlı API anahtarı tanımlı olmalı. Ayrıca uygulamanın *Environment variables* bölümünde `jetta_signing` grubuna `CERTIFICATE_PRIVATE_KEY` (secure) ekleyin — mevcut Apple Distribution sertifikasının private key'i (PEM).
3. **ASC Apple ID:** App Store Connect'te Jetta uygulamasını oluşturup numerik Apple ID'sini `codemagic.yaml` içindeki `APP_STORE_APPLE_ID` değişkenine yazın.
4. **Android için:** Ek kurulum gerekmez. Play Store'a çıkarken keystore oluşturup `android_signing` bloğunu açın.
