#!/bin/bash

# 1. Clone the Flutter SDK on the Vercel build agent
echo "=== Cloning Flutter SDK ==="
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# 2. Add Flutter to the path of the current session
export PATH="$PATH:$(pwd)/flutter/bin"

# 3. Print current flutter version info
flutter --version

# 4. Run production compilation
echo "=== Compiling Flutter Web Release ==="
flutter build web --release

# 5. Inject SPA deep-link routing rules into build directory
cp vercel.json build/web/
echo "=== Build Complete ==="
