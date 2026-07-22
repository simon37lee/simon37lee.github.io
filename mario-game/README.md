# 우리 아이 마리오 (Kid-Face Mario-style Game)

브라우저에서 바로 실행되는 슈퍼마리오 스타일의 초간단 사이드 스크롤 플랫포머입니다.
Phaser 3로 만들었고, 빌드 과정 없이 정적 파일만으로 동작해서 GitHub Pages에 그대로 올릴 수 있습니다.

## 실행 방법

### 로컬에서 확인
정적 파일 서버로 열어야 이미지 로딩이 정상 동작합니다 (파일을 더블클릭해서 여는 `file://` 방식은 안 됨).

```bash
cd mario-game
python3 -m http.server 8000
# 브라우저에서 http://localhost:8000 접속
```

### GitHub Pages로 배포
이 저장소가 이미 GitHub Pages(`simon37lee.github.io`)로 서비스 중이므로, 이 브랜치를 `main`에 머지하면
`https://simon37lee.github.io/mario-game/` 에서 바로 플레이할 수 있습니다.

## 아이 얼굴 사진 교체하기

`assets/child-face.png` 파일이 캐릭터 얼굴로 사용됩니다. 지금은 실제 사진이 없어서 임시로
간단한 만화 얼굴 이미지를 넣어뒀습니다.

**교체 방법:** 아이 얼굴이 정면으로 나온 정사각형(또는 정사각형에 가까운) 사진을 준비해서
같은 파일명(`assets/child-face.png`)으로 덮어쓰기만 하면 됩니다. 코드 수정은 필요 없습니다.
- 권장 크기: 200~500px 정사각형
- 배경이 단순하고 얼굴이 중앙에 크게 나온 사진일수록 게임 캐릭터 얼굴로 잘 보입니다
- 원형으로 잘려서 캐릭터 머리에 합성되므로, 얼굴이 사진 중앙에 있어야 합니다

## 조작법

- **PC**: 방향키(← →)로 이동, ↑ 또는 스페이스바로 점프
- **모바일**: 화면 하단의 터치 버튼(◀ ▶ 점프)

## 게임 내용

- 코인을 모으면 점수가 올라갑니다
- 굼바(적) 위에서 밟으면 처치, 옆에서 부딪히면 게임 오버
- 함정(구멍)에 빠져도 게임 오버
- 맨 끝의 깃발에 도달하면 클리어
- 게임 오버/클리어 후 화면을 탭하면 재시작

## 파일 구조

```
mario-game/
├── index.html          # 게임 페이지 (터치 컨트롤 UI 포함)
├── game.js             # 게임 로직 (Phaser 3)
├── lib/phaser.min.js   # Phaser 3.70.0 (CDN 의존성 없이 로컬 포함)
└── assets/
    └── child-face.png  # 캐릭터 얼굴 (교체 대상)
```

## 실제 안드로이드 앱(APK)으로 만들고 싶다면

지금은 웹 게임(HTML5)이라 안드로이드 폰 브라우저에서 바로 실행되고,
"홈 화면에 추가"로 앱처럼 아이콘을 만들 수도 있습니다.

설치형 APK가 필요해지면, 이 폴더를 그대로 [Capacitor](https://capacitorjs.com/)로 감싸서
빌드할 수 있습니다(안드로이드 스튜디오 및 SDK가 있는 로컬 PC에서 진행 필요):

```bash
npm init -y
npm install @capacitor/core @capacitor/cli @capacitor/android
npx cap init "우리 아이 마리오" "com.example.kidmario" --web-dir=mario-game
npx cap add android
npx cap open android
```
