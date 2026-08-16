#!/bin/bash
set -e

echo "=== Vercel Flutter Web Build Start ==="

# Flutter SDK 설치 (캐시가 없으면 stable 브랜치 클론)
if [ ! -d "$HOME/flutter" ]; then
  echo "Cloning Flutter SDK (stable)..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 $HOME/flutter
fi

export PATH="$PATH:$HOME/flutter/bin"

echo "Flutter version:"
flutter --version

echo "Resolving dependencies..."
flutter pub get

# 환경 변수 기반 빌드
# Vercel Project Environment Variables에 설정된 값들을 --dart-define으로 주입
DART_DEFINES=""

if [ -n "$GEMINI_API_KEY" ]; then
  DART_DEFINES="$DART_DEFINES --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY"
fi

if [ -n "$SUPABASE_URL" ]; then
  DART_DEFINES="$DART_DEFINES --dart-define=SUPABASE_URL=$SUPABASE_URL"
fi

if [ -n "$SUPABASE_ANON_KEY" ]; then
  DART_DEFINES="$DART_DEFINES --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"
fi

# .env 파일이 존재하는 경우 추가
if [ -f ".env" ]; then
  DART_DEFINES="$DART_DEFINES --dart-define-from-file=.env"
fi

echo "Building Flutter Web with flags: $DART_DEFINES"
flutter build web --release $DART_DEFINES

echo "=== Vercel Flutter Web Build Complete ==="
