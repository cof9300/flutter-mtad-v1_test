# 메디터치 Flutter App 개발 템플릿

Flutter 기반의 확장 가능한 모바일 애플리케이션 개발 템플릿입니다.

## 기술 스택

### 상태 관리

- **flutter_riverpod** (v2.6.1) - 강력한 타입 안정성과 테스트 용이성을 제공하는 반응형 캐싱 프레임워크
- **riverpod_annotation** (v2.6.1) - Riverpod Provider 선언을 위한 어노테이션

### 코드 생성

- **build_runner** (v2.4.13) - Dart 코드 생성 도구 실행기
- **freezed** (v2.5.7) - 불변 클래스 및 Union 타입 생성
- **json_serializable** (v6.8.0) - JSON 직렬화/역직렬화 코드 자동 생성
- **riverpod_generator** (v2.6.2) - Riverpod Provider 코드 생성
- **injectable_generator** (v2.6.2) - 의존성 주입 코드 생성
- **go_router_builder** (v2.7.1) - 타입 안전 라우팅 코드 생성

### 네트워킹 & 데이터

- **dio** (v5.7.0) - 강력한 HTTP 클라이언트
- **flutter_secure_storage** (v9.2.2) - 암호화된 로컬 저장소
- **shared_preferences** (v2.3.3) - 간단한 키-값 저장소
- **cached_network_image** (v3.4.1) - 네트워크 이미지 캐싱

### 라우팅

- **go_router** (v14.6.2) - 선언적 라우팅 라이브러리

### 다국어 지원

- **flutter_localizations** - Flutter 공식 다국어 지원
- **intl** (v0.19.0) - 국제화 및 지역화

### 의존성 주입

- **get_it** (v8.0.2) - 서비스 로케이터 패턴
- **injectable** (v2.5.0) - 어노테이션 기반 의존성 주입

### UI 라이브러리

- **flutter_svg** (v2.0.10) - SVG 이미지 렌더링
- **gap** (v3.0.1) - 간격 위젯

### 유틸리티

- **url_launcher** (v6.3.1) - URL 및 외부 앱 실행
- **package_info_plus** (v8.1.0) - 앱 패키지 정보 조회
- **path_provider** (v2.1.5) - 시스템 디렉토리 경로 조회

---

## 프로젝트 폴더 구조

```
lib/
├── auth/                    # 인증 관련 기능
├── config/                  # 앱 설정 및 환경 변수
├── core/                    # 공통 핵심 기능
│   ├── base/               # 기본 클래스 및 추상화
│   ├── extension/          # Dart/Flutter 확장 메서드
│   ├── theme/              # 앱 테마, 색상, 스타일 정의
│   ├── utils/              # 유틸리티 함수 및 헬퍼
│   └── widget/             # 재사용 가능한 공통 위젯
├── data/                    # 데이터 레이어
│   ├── database/           # 로컬 데이터베이스 (SQLite, Hive 등)
│   ├── model/              # 데이터 모델
│   │   ├── request/        # API 요청 모델
│   │   └── response/       # API 응답 모델
│   ├── network/            # 네트워크 통신
│   │   └── dio/            # Dio 설정 및 인터셉터
│   └── repository/         # 데이터 저장소 (데이터 소스 추상화)
├── features/               # 기능별 모듈 (Feature-first 구조)
├── l10n/                   # 다국어 리소스 파일 (.arb)
├── providers/              # Riverpod 상태 관리
│   ├── notifier/          # StateNotifier 및 비즈니스 로직
│   └── state/             # 상태 모델 클래스
└── router/                 # 라우팅 설정 및 네비게이션
```

### 폴더 상세 설명

#### `/lib/auth`

사용자 인증과 관련된 모든 기능을 관리합니다.

- 로그인/로그아웃 로직
- 토큰 관리
- 인증 상태 확인
- 세션 관리

#### `/lib/config`

앱 전체 설정을 관리합니다.

- API 엔드포인트 설정
- 환경 변수 (개발/스테이징/프로덕션)
- 의존성 주입 설정 (Injectable)
- 앱 초기화 설정

#### `/lib/core`

앱 전반에서 사용되는 공통 기능들을 포함합니다.

**`/lib/core/base`**

- 기본 페이지, 위젯, 상태의 추상 클래스
- 공통 비즈니스 로직 베이스 클래스
- 반복되는 패턴의 추상화

**`/lib/core/extension`**

- String, DateTime, BuildContext 등의 확장 메서드
- 코드 간결성과 가독성 향상
- 자주 사용하는 변환 로직

**`/lib/core/theme`**

- MaterialTheme 설정
- 색상 팔레트 (AppColors)
- 텍스트 스타일 (AppTextStyles)
- 앱 전체 디자인 시스템

**`/lib/core/utils`**

- 날짜/시간 포맷팅
- 문자열 처리
- 유효성 검증
- 로깅
- 기타 헬퍼 함수

**`/lib/core/widget`**

- 앱 전체에서 재사용되는 공통 위젯
- 커스텀 버튼, 입력 필드, 다이얼로그 등
- UI 일관성 유지

#### `/lib/data`

데이터 접근 및 관리 계층입니다.

**`/lib/data/database`**

- SQLite, Hive 등 로컬 데이터베이스
- 오프라인 데이터 저장
- 캐시 관리

**`/lib/data/model`**

- API 통신에 사용되는 데이터 구조
- Freezed로 불변 모델 생성
- JSON 직렬화/역직렬화

**`/lib/data/network`**

- Dio HTTP 클라이언트 설정
- 인터셉터 (로깅, 인증, 에러 처리)
- API 서비스 인터페이스

**`/lib/data/repository`**

- 데이터 소스를 추상화한 레이어
- 네트워크와 로컬 데이터베이스를 통합
- 비즈니스 로직에서 데이터 출처를 숨김

#### `/lib/features`

기능 단위로 모듈화된 코드를 관리합니다. (Feature-first Architecture)

- 각 기능은 독립적인 폴더로 구성
- 예: `features/home/`, `features/profile/`, `features/settings/`
- 각 기능 폴더 내부 구조:
  - `pages/` - 화면 UI
  - `widgets/` - 해당 기능 전용 위젯
  - 필요시 로컬 상태 관리

#### `/lib/l10n`

다국어 지원을 위한 리소스 파일들입니다.

- `.arb` 파일 (Application Resource Bundle)
- 각 언어별 번역 파일
- Flutter가 자동으로 코드 생성

#### `/lib/providers`

Riverpod 기반 상태 관리를 담당합니다.

**`/lib/providers/notifier`**

- StateNotifier 클래스
- 비즈니스 로직 구현
- 상태 변경 메서드

**`/lib/providers/state`**

- 상태를 나타내는 불변 모델 클래스
- Loading, Success, Error 등의 상태 표현
- Freezed로 구현

#### `/lib/router`

앱 내 화면 전환 및 네비게이션을 관리합니다.

- go_router 라우팅 설정
- 라우트 경로 정의
- Deep Link 처리
- 네비게이션 가드 (인증 체크 등)

---

## 다국어 지원 (Internationalization)

### 1. 다국어 리소스 파일 작성

`lib/l10n/` 폴더에 언어별 `.arb` 파일을 생성합니다.

**app_en.arb** (영어)

```json
{
  "@@locale": "en",
  "appTitle": "Flutter Template",
  "@appTitle": {
    "description": "The title of the application"
  },
  "welcomeMessage": "Welcome to MediTouch",
  "@welcomeMessage": {
    "description": "Welcome message shown to users"
  }
}
```

**app_ko.arb** (한국어)

```json
{
  "@@locale": "ko",
  "appTitle": "플러터 템플릿",
  "@appTitle": {
    "description": "The title of the application"
  },
  "welcomeMessage": "메디터치에 오신 것을 환영합니다",
  "@welcomeMessage": {
    "description": "Welcome message shown to users"
  }
}
```

### 2. 다국어 파일 생성

새로운 번역 키를 추가하거나 수정한 후 다음 명령어를 실행합니다:

```bash
flutter gen-l10n
```

또는

```bash
flutter pub get
```

이 명령어는 `.dart_tool/flutter_gen/gen_l10n/` 폴더에 다국어 코드를 자동 생성합니다.

### 3. 앱에 다국어 적용

**MaterialApp 설정**

```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [
    Locale('en'),
    Locale('ko'),
  ],
  // ...
)
```

### 4. 코드에서 다국어 텍스트 사용

**Widget에서 사용**

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Text(l10n.welcomeMessage);
  }
}
```

### 5. 동적 언어 변경 (Riverpod 사용)

**LocaleNotifier 생성**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('ko'));

  void changeLocale(Locale locale) {
    state = locale;
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});
```

**MaterialApp에 적용**

```dart
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      locale: locale,
      // ...
    );
  }
}
```

**언어 변경 버튼**

```dart
ElevatedButton(
  onPressed: () {
    ref.read(localeProvider.notifier).changeLocale(const Locale('en'));
  },
  child: Text('English'),
)
```

### 6. 파라미터가 있는 번역

**app_en.arb**

```json
{
  "greeting": "Hello, {name}!",
  "@greeting": {
    "description": "Greeting message with user name",
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  }
}
```

**사용**

```dart
Text(l10n.greeting('John'))
```

---

## 빌드 & 실행 명령어

### 개발 환경 실행

```bash
flutter run
```

### 특정 디바이스 실행

```bash
# 연결된 디바이스 확인
flutter devices

# Chrome 브라우저
flutter run -d chrome

# macOS 앱
flutter run -d macos

# 특정 디바이스 ID로 실행
flutter run -d [device-id]
```

### 릴리즈 모드 실행

```bash
flutter run --release
```

### 빌드

**Android APK**

```bash
flutter build apk --release
```

**Android App Bundle (Google Play)**

```bash
flutter build appbundle --release
```

**iOS**

```bash
flutter build ios --release
```

**macOS**

```bash
flutter build macos --release
```

**Web**

```bash
flutter build web --release
```

### 코드 생성

**Riverpod, Freezed, JSON 직렬화 코드 생성**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Watch 모드 (자동 생성)**

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 의존성 관리

**패키지 설치**

```bash
flutter pub get
```

**패키지 업데이트**

```bash
flutter pub upgrade
```

**오래된 패키지 확인**

```bash
flutter pub outdated
```

### 클린 빌드

```bash
flutter clean
flutter pub get
flutter run
```

### 분석 및 린트

**코드 분석**

```bash
flutter analyze
```

**코드 포맷팅**

```bash
dart format lib/
```

---

## 프로젝트 설정 파일

### l10n.yaml

다국어 설정 파일입니다.

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

### pubspec.yaml

프로젝트 의존성 및 리소스를 관리합니다.

```yaml
flutter:
  generate: true # 다국어 자동 생성 활성화
  assets:
    - assets/icons/
    - assets/images/
```

---

**프로젝트 버전**: 1.0.0  
**Flutter SDK**: ^3.6.1  
**최소 지원 버전**: iOS 12.0 / Android 5.0 (API 21)
