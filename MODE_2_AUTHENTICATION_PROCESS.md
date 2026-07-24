# Mode 2 (게스트 모드) 인증 판단 프로세스 분석

## 개요
`mode == 2` (게스트 모드)일 때, 혈압 측정 결과 화면에서 사용자가 적합한 인증을 거쳐서 측정했는지, 인증 없이 무단으로 측정했는지, 아니면 측정 후 인증을 해야 하는지를 판단하는 프로세스입니다.

---

## 1. 측정 결과 저장 프로세스 (`_saveMeasurementResult`)

### 1.1. 실행 시점
- 측정 결과 화면 진입 시 `initState`에서 자동 호출

### 1.2. 판단 로직

```dart
// mode == 2일 때만 실행되는 로직
if (kioskOption.mode == 2) {
  // 1. measureId 결정 우선순위
  final targetMeasureId = 
      userAuth?.measureid != null && userAuth!.measureid!.isNotEmpty
          ? userAuth.measureid!  // 우선순위 1: userAuth의 measureid
          : (measureId ?? '');    // 우선순위 2: measureId provider

  // 2. 인증 여부 판단
  final isAuthenticated = 
      userAuth?.measureid != null && userAuth!.measureid!.isNotEmpty;

  // 3. serviceforce 결정
  final serviceforce = isAuthenticated ? 'false' : 'true';
  // - 인증됨: 'false' (정상 저장)
  // - 인증 안됨: 'true' (비회원 강제 저장)

  // 4. API 호출: setResult
  await authRepository.setResult(
    token: token,
    measureid: targetMeasureId,
    device: 'BP',
    result: result,
    serviceforce: serviceforce,
  );

  // 5. 응답에서 measureId 업데이트
  final finalMeasureId = setResultResponse.measureid ?? targetMeasureId;
  if (finalMeasureId.isNotEmpty) {
    ref.read(measureIdProvider.notifier).setMeasureId(finalMeasureId);
  }
}
```

### 1.3. 판단 기준

| 조건 | 값 | 의미 |
|------|-----|------|
| `userAuth?.measureid` 존재 | 있음 | **인증 완료 상태** - 측정 전에 인증을 완료함 |
| `userAuth?.measureid` 존재 | 없음 | **인증 미완료 상태** - 인증 없이 측정함 |

### 1.4. 저장 방식

- **인증 완료 (`isAuthenticated == true`)**:
  - `serviceforce: 'false'` - 정상 저장
  - `measureid`: `userAuth.measureid` 사용

- **인증 미완료 (`isAuthenticated == false`)**:
  - `serviceforce: 'true'` - 비회원 강제 저장
  - `measureid`: `measureId` provider 값 또는 빈 문자열

---

## 2. 문자 전송 프로세스 (`_handleSendMessage`)

### 2.1. 실행 시점
- 사용자가 "문자 전송" 버튼을 눌렀을 때

### 2.2. 판단 로직

```dart
// mode == 2일 때만 실행되는 로직
if (!isServiceMode) {  // kioskOption.mode != 1
  // 1. 인증 정보 수집
  final hasUserAuthMeasureId = 
      userAuth?.measureid != null && userAuth!.measureid!.isNotEmpty;
  final hasUserAuthPhone = 
      userAuth?.phonenumber != null && userAuth!.phonenumber!.isNotEmpty;
  final hasVerifiedPhone = 
      verifiedPhone != null && verifiedPhone.isNotEmpty;
  final hasMeasureId = 
      measureId != null && measureId.isNotEmpty;

  // 2. 전화번호 존재 여부 확인
  final hasPhone = hasVerifiedPhone || hasUserAuthPhone;
  
  // 3. measureId 존재 여부 확인
  final hasAuthId = hasUserAuthMeasureId || hasMeasureId;
  
  // 4. 인증 완료 여부 최종 판단
  final isAuthenticated = hasPhone && hasAuthId;
  // 둘 다 있어야 인증 완료로 판단

  // 5. 분기 처리
  if (isAuthenticated) {
    // 인증 완료: SMS 바로 전송
    final phoneNumber = hasVerifiedPhone ? verifiedPhone : userAuth!.phonenumber;
    await authRepository.sendSms(
      type: 'RESULT_GUEST',
      phonenumber: phoneNumber,
      ...
    );
  } else {
    // 인증 미완료: 게스트 폰 입력 화면으로 이동
    Navigator.push(GuestPhoneInputScreen(...));
  }
}
```

### 2.3. 인증 정보 출처

#### 2.3.1. 전화번호 (Phone Number)
1. **`verifiedPhone`** (우선순위 1)
   - 출처: `ServiceLocator().verifiedUserStorage.getAllData()['phoneNumber']`
   - 저장 시점: `AuthScreenWithBirthdayGender`에서 인증 완료 시
   - 의미: 생년월일/성별 인증을 완료한 사용자의 전화번호

2. **`userAuth?.phonenumber`** (우선순위 2)
   - 출처: `ref.read(userAuthProvider)?.phonenumber`
   - 저장 시점: `AuthScreen`에서 인증 완료 시 (`userAuth` API 응답)
   - 의미: 일반 전화번호 인증을 완료한 사용자의 전화번호

#### 2.3.2. 측정 세션 ID (Measure ID)
1. **`userAuth?.measureid`** (우선순위 1)
   - 출처: `ref.read(userAuthProvider)?.measureid`
   - 저장 시점: `userAuth` API 응답에서 받은 값
   - 의미: 인증 완료 후 서버에서 발급한 측정 세션 ID

2. **`measureId` Provider** (우선순위 2)
   - 출처: `ref.read(measureIdProvider)`
   - 저장 시점: `setResult` API 응답 또는 이전 측정에서 저장된 값
   - 의미: 측정 결과 저장 시 서버에서 발급한 측정 세션 ID

### 2.4. 인증 완료 판단 기준

| 조건 | 값 | 결과 |
|------|-----|------|
| `hasPhone` | `true` | 전화번호가 있음 (verifiedPhone 또는 userAuth.phonenumber) |
| `hasAuthId` | `true` | measureId가 있음 (userAuth.measureid 또는 measureId provider) |
| `isAuthenticated` | `hasPhone && hasAuthId` | **둘 다 있어야 인증 완료** |

### 2.5. 분기 처리

#### 케이스 1: 인증 완료 (`isAuthenticated == true`)
- **동작**: SMS 바로 전송
- **전화번호 선택**: `verifiedPhone` 우선, 없으면 `userAuth.phonenumber`
- **SMS 타입**: `RESULT_GUEST`
- **결과**: 성공 모달 표시 후 스탠바이 화면으로 이동

#### 케이스 2: 인증 미완료 (`isAuthenticated == false`)
- **동작**: `GuestPhoneInputScreen`으로 이동
- **이유**: 전화번호 또는 measureId가 없어서 인증이 필요함
- **다음 단계**: 사용자가 전화번호를 입력하고 인증을 완료해야 함

---

## 3. 전체 프로세스 플로우

```
[측정 결과 화면 진입]
         │
         ├─→ _saveMeasurementResult() 실행
         │         │
         │         ├─→ measureId 확인
         │         │   ├─ userAuth?.measureid (우선)
         │         │   └─ measureId provider (차선)
         │         │
         │         ├─→ 인증 여부 판단
         │         │   └─ userAuth?.measureid 존재 여부
         │         │
         │         ├─→ serviceforce 결정
         │         │   ├─ 인증됨: 'false'
         │         │   └─ 인증 안됨: 'true'
         │         │
         │         └─→ setResult API 호출
         │
         └─→ [문자 전송 버튼 클릭]
                   │
                   └─→ _handleSendMessage() 실행
                             │
                             ├─→ 인증 정보 수집
                             │   ├─ hasUserAuthMeasureId
                             │   ├─ hasUserAuthPhone
                             │   ├─ hasVerifiedPhone
                             │   └─ hasMeasureId
                             │
                             ├─→ 인증 완료 여부 판단
                             │   ├─ hasPhone = hasVerifiedPhone || hasUserAuthPhone
                             │   ├─ hasAuthId = hasUserAuthMeasureId || hasMeasureId
                             │   └─ isAuthenticated = hasPhone && hasAuthId
                             │
                             └─→ 분기 처리
                                 ├─ 인증 완료 → SMS 전송
                                 └─ 인증 미완료 → GuestPhoneInputScreen 이동
```

---

## 4. 주요 데이터 소스

### 4.1. `userAuth` (UserAuthProvider)
- **저장 위치**: Riverpod Provider
- **저장 시점**: `AuthScreen` 또는 `AuthScreenWithBirthdayGender`에서 인증 완료 시
- **포함 정보**:
  - `measureid`: 측정 세션 ID
  - `phonenumber`: 전화번호

### 4.2. `verifiedUserStorage`
- **저장 위치**: 로컬 저장소 (SharedPreferences)
- **저장 시점**: `AuthScreenWithBirthdayGender`에서 생년월일/성별 인증 완료 시
- **포함 정보**:
  - `phoneNumber`: 전화번호
  - `birthday`: 생년월일
  - `gender`: 성별

### 4.3. `measureIdProvider`
- **저장 위치**: Riverpod Provider
- **저장 시점**: 
  - `setResult` API 응답에서 받은 값
  - 이전 측정에서 저장된 값
- **포함 정보**: 측정 세션 ID

---

## 5. 인증 상태별 시나리오

### 시나리오 1: 측정 전 인증 완료
- **상황**: 사용자가 측정 전에 인증을 완료한 경우
- **`userAuth?.measureid`**: 존재
- **`userAuth?.phonenumber`**: 존재
- **`verifiedPhone`**: 존재 (생년월일/성별 인증 시)
- **결과 저장**: `serviceforce: 'false'` (정상 저장)
- **문자 전송**: 바로 전송 가능

### 시나리오 2: 인증 없이 측정
- **상황**: 사용자가 인증 없이 바로 측정한 경우
- **`userAuth?.measureid`**: 없음
- **`userAuth?.phonenumber`**: 없음
- **`verifiedPhone`**: 없음
- **`measureId`**: `setResult` API 응답에서 받은 값
- **결과 저장**: `serviceforce: 'true'` (비회원 강제 저장)
- **문자 전송**: `GuestPhoneInputScreen`으로 이동하여 인증 필요

### 시나리오 3: 측정 후 인증
- **상황**: 측정 후 문자 전송 버튼을 눌러 인증하는 경우
- **초기 상태**: 시나리오 2와 동일
- **인증 완료 후**: 
  - `verifiedPhone` 또는 `userAuth.phonenumber` 저장됨
  - `measureId`는 이미 존재 (측정 시 저장됨)
  - `isAuthenticated == true`가 되어 SMS 전송 가능

---

## 6. 핵심 판단 로직 요약

### 6.1. 결과 저장 시 (`_saveMeasurementResult`)
- **판단 기준**: `userAuth?.measureid` 존재 여부
- **결과**: 
  - 있음 → `serviceforce: 'false'` (정상 저장)
  - 없음 → `serviceforce: 'true'` (비회원 강제 저장)

### 6.2. 문자 전송 시 (`_handleSendMessage`)
- **판단 기준**: 
  - 전화번호 존재 여부 (`hasPhone`)
  - measureId 존재 여부 (`hasAuthId`)
  - **둘 다 있어야** 인증 완료로 판단
- **결과**:
  - 둘 다 있음 → SMS 바로 전송
  - 하나라도 없음 → `GuestPhoneInputScreen`으로 이동

---

## 7. 주의사항

1. **`verifiedPhone`과 `userAuth.phonenumber`의 차이**:
   - `verifiedPhone`: 생년월일/성별 인증 완료 시 저장
   - `userAuth.phonenumber`: 일반 전화번호 인증 완료 시 저장
   - 문자 전송 시 `verifiedPhone`을 우선 사용

2. **`userAuth.measureid`와 `measureId` provider의 차이**:
   - `userAuth.measureid`: 인증 완료 시 서버에서 발급
   - `measureId` provider: 측정 결과 저장 시 서버에서 발급
   - 둘 중 하나라도 있으면 인증 완료로 판단 가능

3. **인증 완료 판단의 엄격성**:
   - 결과 저장 시: `userAuth.measureid`만 확인 (단일 조건)
   - 문자 전송 시: 전화번호와 measureId 둘 다 확인 (복합 조건)
