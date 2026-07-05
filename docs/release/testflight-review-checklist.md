# TestFlight 및 App Review 제출 전 체크리스트

기준 브랜치: `origin/develop` 931b20a  
검토일: 2026-07-05

## 1. 브랜치 상태

- 원격 기본 브랜치: `develop`
- `origin/develop`은 `origin/main`보다 17커밋 앞서 있음
- 로컬 출시 준비 브랜치는 `origin/develop` 931b20a로 fast-forward 완료
- 출시 준비 작업 브랜치: `chore/release-privacy-prep`

## 2. 권한 문구

현재 출시 준비 브랜치에서 권한 문구를 다음 목적 중심 문구로 조정했습니다.

- 카메라: AR 공간 인식 및 상대 얼굴/입 움직임 감지
- 마이크: 대화 음성 인식 및 긍정 표현 감정 구슬 분류
- 음성 인식: 대화 음성을 텍스트로 변환해 온디바이스 감정 분류에 사용

사진 추가 권한은 리포트 저장 기능과 연결되어 있으므로 선택 권한으로 유지합니다. 목적은 수집 리포트 이미지를 사용자의 사진 앱에 저장하는 것입니다.

## 3. TestFlight 빌드 전 확인

- Xcode Scheme: `ZupZup`
- Build Configuration: `Release`
- Team: 출시할 Apple Developer Team
- Bundle Identifier: `com.deuddong.zupzup`
- Version: `1.0`
- Build: `3` 이상, 업로드마다 증가 필요
- Signing: Automatically manage signing
- DEBUG 전용 UI가 Release에서 노출되지 않는지 확인

검증 결과:

- Debug iOS Simulator 빌드 통과
- Release iOS Simulator 빌드 통과
- generic iOS Release build setting 기준 `PRODUCT_BUNDLE_IDENTIFIER = com.deuddong.zupzup`
- generic iOS Release build setting 기준 `MARKETING_VERSION = 1.0`
- generic iOS Release build setting 기준 `CURRENT_PROJECT_VERSION = 3`

## 4. 실제 심사용 플로우

심사자가 확인할 수 있어야 하는 최소 플로우입니다.

1. 앱 실행
2. 온보딩 확인
3. 카메라/마이크/음성 인식 권한 허용
4. 사진 추가 권한 허용
5. 공간 인식
6. 상대 인식
7. 대화 시작
8. 긍정 표현 발화
9. 감정 구슬 생성 확인
10. 대화 종료
11. 구슬 수집
12. 리포트 화면 확인

## 5. Review Notes 초안

앱은 후면 카메라를 사용해 AR 공간과 대화 상대의 입 움직임을 감지합니다. 마이크와 음성 인식은 대화 중 긍정 표현을 텍스트로 변환하고 온디바이스 Core ML 모델로 분류하기 위해 사용됩니다. 카메라 영상, 음성 원본, 음성 인식 텍스트는 앱 개발자 서버로 전송되거나 저장되지 않습니다.

테스트 시 카메라 권한, 마이크 권한, 음성 인식 권한, 사진 추가 권한을 허용한 뒤 밝은 환경에서 상대 얼굴을 화면 중앙에 두고 대화를 시작해주세요. "고마워", "정말 잘했어", "응원할게" 같은 긍정 표현을 말하면 감정 구슬이 생성됩니다.

## 6. 출시 전 남은 결정

- 공식 지원 URL
- 공식 개인정보 처리방침 URL: `https://developeracademy-postech.github.io/2026-C3-M13-DeuDdong/privacy/`
- 앱 설명 및 키워드
- 앱 스크린샷
- 연령 등급
- 수출 규정/암호화 답변
- 리포트 저장 버튼의 사진 권한 요청 및 저장 동작 실기기 확인

## 7. GitHub Pages 설정

개인정보 처리방침 페이지는 `docs/privacy/index.html`에 추가했습니다. PR 머지 후 GitHub 저장소에서 다음 설정이 필요합니다.

1. Repository Settings > Pages
2. Build and deployment > Source: Deploy from a branch
3. Branch: `develop` 또는 실제 배포 기준 브랜치
4. Folder: `/docs`
5. Save

배포가 완료되면 App Store Connect의 Privacy Policy URL에 `https://developeracademy-postech.github.io/2026-C3-M13-DeuDdong/privacy/`를 입력합니다.
