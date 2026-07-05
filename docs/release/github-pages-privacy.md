# GitHub Pages 개인정보 처리방침 배포 메모

공개 페이지 파일:

- `docs/index.html`
- `docs/privacy/index.html`
- `docs/.nojekyll`

예상 공개 URL:

`https://developeracademy-postech.github.io/2026-C3-M13-DeuDdong/privacy/`

## 설정 순서

1. 개인정보 처리방침 파일이 포함된 PR을 배포 기준 브랜치에 머지합니다.
2. GitHub 저장소의 Settings > Pages로 이동합니다.
3. Build and deployment의 Source를 `Deploy from a branch`로 선택합니다.
4. Branch는 배포 기준 브랜치, Folder는 `/docs`로 선택합니다.
5. Save 후 배포 상태가 초록색으로 바뀌는지 확인합니다.
6. 위 URL을 열어 개인정보 처리방침 페이지가 보이는지 확인합니다.
7. App Store Connect > App Information 또는 App Privacy 항목에 Privacy Policy URL로 입력합니다.

## 주의

- GitHub Pages 설정은 저장소 관리자 권한이 필요할 수 있습니다.
- `docs/release` 문서는 내부 제출 준비용입니다. App Store Connect에는 `/privacy/` URL만 입력합니다.
- 앱에 서버 저장, 분석 SDK, 외부 API 전송이 추가되면 개인정보 처리방침과 App Privacy 답변을 다시 갱신해야 합니다.
