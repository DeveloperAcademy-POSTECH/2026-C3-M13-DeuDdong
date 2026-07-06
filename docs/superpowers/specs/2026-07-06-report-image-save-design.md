# 리포트 이미지 저장 설계

## 배경

`ReportView`에는 저장 버튼이 있지만 현재는 사진 라이브러리 권한 확인만 하고 실제 캡처/저장 로직은 비어 있다 (`4e97a1d`에서 `ImageRenderer` 기반 구현을 제거).

`ImageRenderer`를 걷어낸 이유: `ReportContentView` 안의 `ReportGravityBowlView`는 SpriteKit(`SpriteView`/`SKView`)으로 그려지는 물리 시뮬레이션 화면이다. `ImageRenderer`는 뷰를 실제 윈도우에 붙이지 않고 오프스크린으로 재렌더링하므로, `SKView`의 Metal 렌더 루프(`CADisplayLink`)가 한 번도 돌지 않아 구슬이 통째로 비어 보이는 문제가 있었다. 또한 오프스크린 렌더링은 물리 시뮬레이션을 새로 인스턴스화하므로, 캡처 시점에 사용자가 실제로 보고 있는 구슬 배치와 다른 결과가 나올 수 있다.

## 목표

저장 버튼을 누르면 사용자가 화면에서 실제로 보고 있는 `ReportContentView`(제목, 중력 그릇의 구슬 배치, 통계 카드)를 그대로 이미지로 캡처해 사진 라이브러리에 저장한다.

## 범위

- 캡처 대상: `ReportContentView`만 (제목 ~ 감정별 통계 카드). 저장/홈 버튼(`ReportActionButtons`)은 포함하지 않는다.
- `ReportContentView`는 `ScrollView` 안에 있어 화면보다 길 수 있다. 스크롤 위치와 무관하게 컨텐츠 전체(가려진 부분 포함)를 캡처한다.
- 감정 종류/개수에 따라 구슬 구성이 달라지는 것(`ReportSummary` → `reportItems(from:)`)은 이미 구현되어 있으며 이번 작업 범위에 포함되지 않는다. 라이브 캡처 방식을 쓰면 화면에 그려진 그대로 캡처되므로 별도 처리가 필요 없다.

## 접근 방식: UIView 실캡처 (`drawHierarchy` 기반 라이브 캡처)

### 구성 요소

1. **`ReportContentViewCapture`** (신규, `UIViewRepresentable`)
   - `ReportContentView`의 `.background()`로 부착되는 투명한 마커 뷰.
   - `makeUIView`에서 자신의 `superview`(= `ReportContentView`를 감싸는 실제 컨텐츠 뷰, 배경+본문을 합친 크기)에 대한 약한 참조를 바깥의 `Binding<UIView?>`에 전달한다.
   - 뷰가 사라질 때(`dismantleUIView` 또는 `updateUIView`에서 nil 체크) 참조를 정리한다.

2. **`ReportImageSaver`** (기존 파일 확장)
   - `static func captureImage(of view: UIView) -> UIImage?`
     - `view.bounds.size`(스크롤에 잘리지 않은 실제 컨텐츠 전체 크기)를 기준으로 `UIGraphicsImageRenderer` 생성.
     - `view.drawHierarchy(in: CGRect(origin: .zero, size: view.bounds.size), afterScreenUpdates: true)`로 래스터화.
   - `static func save(_ image: UIImage) async -> Bool`
     - `PHPhotoLibrary.shared().performChanges { PHAssetChangeRequest.creationRequestForAsset(from: image) }`를 `withCheckedContinuation`으로 async 래핑, 성공 여부 반환.

3. **`ReportView`**
   - `@State private var capturedContentView: UIView?` 추가.
   - `ReportContentView(summary: summary)`에 `.background(ReportContentViewCapture(view: $capturedContentView))` 부착.
   - `handleSave()`:
     1. 권한 확인 (기존 로직 유지).
     2. 거부 시 기존처럼 설정 유도 알럿.
     3. 허용 시 `capturedContentView`가 있으면 `ReportImageSaver.captureImage(of:)` → `ReportImageSaver.save(_:)` 호출.
     4. 저장 성공/실패에 따라 결과 알럿 또는 토스트 표시 (성공: "사진 앱에 저장됐어요", 실패: "저장에 실패했어요. 다시 시도해주세요").

### 에러 처리

- `capturedContentView`가 `nil`인 경우(뷰가 아직 레이아웃되지 않은 극히 드문 타이밍) — 저장 실패로 처리하고 실패 알럿 표시.
- `PHPhotoLibrary` 저장 자체가 실패하는 경우(저장 공간 부족 등) — 실패 알럿 표시.
- 권한 거부는 기존 `showSettingsAlert` 흐름 그대로 사용.

### 폴백 (이번 범위 아님, 리스크로만 기록)

실기기 검증 중 특정 OS/기기 조합에서 `drawHierarchy`가 `SKView`(Metal 백킹) 레이어를 캡처하지 못하는 경우가 발견되면, 정적 파트는 `ImageRenderer`로 · 구슬 파트는 `SKView.texture(from:)`로 각각 렌더링해 합성하는 방식으로 전환한다. 별도 스펙으로 다룬다.

## 테스트 / 검증

- SpriteKit 렌더링은 스냅샷/유닛 테스트로 검증하기 어려우므로, 실기기에서 수동 확인을 주 검증 수단으로 한다:
  - 구슬이 0개(빈 상태), 1종류, 5종류 모두 있는 케이스 각각에서 저장된 사진과 화면이 일치하는지 확인.
  - 컨텐츠가 화면보다 길어 스크롤이 필요한 케이스에서 저장된 이미지가 잘리지 않는지 확인.
  - 사진 권한 거부 상태에서 설정 유도 알럿이 뜨는지 확인(기존 동작, 회귀 확인만).
- 가능하면 `captureImage(of:)`에 대해 더미 `UIView`(고정 크기, 배경색)를 넣고 반환된 `UIImage`의 크기가 기대한 크기와 일치하는지 확인하는 경량 유닛 테스트를 추가한다.
