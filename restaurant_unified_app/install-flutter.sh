#!/bin/bash

# 1. Download Flutter stable
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# 2. Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Pre-cache artifacts and disable analytics
flutter config --no-analytics
flutter doctor

# 4. Build the web app
echo "Building Flutter Web..."
flutter build web --release

echo "Build complete!"
