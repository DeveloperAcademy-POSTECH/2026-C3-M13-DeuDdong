# App Store Connect App Privacy 입력 초안

기준 브랜치: `origin/develop` 931b20a  
검토일: 2026-07-05

## 결론

현재 코드 기준으로 앱 개발자가 서버로 수집하는 사용자 데이터는 없습니다. 따라서 App Store Connect의 App Privacy는 원칙적으로 **Data Not Collected**로 입력할 수 있습니다.

다만 Apple의 음성 인식 시스템을 사용하고, 리포트 이미지를 사진 앱에 추가 저장하는 권한 흐름이 포함되어 있습니다. 사진 앱 저장은 사용자의 기기에 생성물을 저장하는 동작이며, 앱 개발자 서버로 사진 데이터를 수집하는 것은 아닙니다. 향후 서버 저장/분석/외부 전송 기능이 추가되면 App Privacy 답변을 다시 수정해야 합니다.

## 데이터 흐름 판단

| 항목 | 현재 사용 | 저장/전송 판단 | App Privacy 반영 |
| --- | --- | --- | --- |
| 카메라 영상 | AR 공간 인식, 얼굴/입 움직임 감지 | 기기 내 처리, 서버 전송 없음 | 수집 안 함 |
| 얼굴 정보 | Vision 얼굴 랜드마크로 말하는 상대 추정 | 개인 식별/저장 없음 | 수집 안 함 |
| 마이크 음성 | 음성 인식 입력 | 음성 원본 저장/서버 전송 없음 | 수집 안 함 |
| 음성 인식 텍스트 | 긍정 표현 분류 입력 | 대화 전문 저장 없음 | 수집 안 함 |
| 감정 분류 결과 | 구슬 생성/리포트 표시 | 서버 저장 없음 | 수집 안 함 |
| 첫 실행 여부 | 온보딩 스킵 | 기기 내 `AppStorage` 값 | 수집 안 함 |
| 사진 추가 권한 | 수집 리포트 이미지를 사진 앱에 저장 | 기존 사진 보관함 읽기 없음, 개발자 서버 전송 없음 | 수집 안 함 |

## App Store Connect 입력 제안

1. App Privacy > Data Collection
2. "Do you or your third-party partners collect data from this app?"
3. 현재 코드 기준 답변: **No, we do not collect data from this app**

## Privacy Policy URL 입력 제안

GitHub Pages 공개 URL 후보:

`https://developeracademy-postech.github.io/2026-C3-M13-DeuDdong/privacy/`

이 URL은 `docs/privacy/index.html`이 기본 브랜치에 머지되고, GitHub Pages가 `docs/` 폴더를 배포하도록 설정된 뒤 사용할 수 있습니다.

## 심사 메모 초안

줍줍은 카메라, 마이크, 음성 인식 권한을 사용하지만 현재 앱 개발자 서버로 영상, 음성, 텍스트, 감정 결과를 전송하거나 저장하지 않습니다. 카메라는 AR 공간 인식 및 상대의 입 움직임 감지에 사용되고, 마이크와 음성 인식은 대화 중 긍정 표현을 감지하기 위해 사용됩니다. 감정 분류는 앱 내 Core ML 모델로 처리되며, 결과는 대화 종료 후 리포트 화면에 표시됩니다.

## 다시 검토해야 하는 변경

- 리포트 저장 기능이 사진 앱 저장을 넘어 서버 업로드/공유 기능으로 확장되는 경우
- 서버 동기화, 로그인, 계정 기능이 추가되는 경우
- Firebase, analytics, crash reporting SDK가 추가되는 경우
- 외부 LLM/API로 발화 텍스트를 보내는 경우
- 음성 원본 또는 텍스트 전문을 장기 저장하는 경우
