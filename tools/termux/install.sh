#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${LAYOUTLIB_URL:-https://veterans-realtor-argument-indication.trycloudflare.com}"
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
CUSTOM_DIR=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dir)
      CUSTOM_DIR="${2:-}"
      shift 2
      ;;
    --url)
      BASE_URL="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 2
      ;;
  esac
done

ARCH="$(uname -m)"
if [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "arm64" ]; then
  echo "[warn] Detected architecture '$ARCH'; these libraries target arm64-v8a / aarch64 Bionic (API 30+)."
fi

for cmd in curl sha256sum; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[error] Required tool '$cmd' not found. In Termux run: pkg install curl coreutils" >&2
    exit 1
  fi
done

TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "=== Downloading ARM64 Host-Bionic Layoutlib artifacts from $BASE_URL ==="
FILES=(
  "SHA256SUMS"
  "libandroid_runtime.so"
  "layoutlib_jni.so"
  "layoutlib_native_probe"
  "smoke-stubs.jar"
  "RenderXmlTest.jar"
  "RenderXmlTest.java"
  "test_layout.xml"
  "icudt78l.dat"
)

for f in "${FILES[@]}"; do
  echo "  -> fetching $f"
  curl -fsSL --retry 3 --retry-delay 2 "$BASE_URL/$f" -o "$TMP_DIR/$f"
done

echo "=== Verifying SHA256 checksums ==="
(cd "$TMP_DIR" && sha256sum -c SHA256SUMS)

install_pair() {
  local dest="$1"
  mkdir -p "$dest"
  for so in libandroid_runtime.so layoutlib_jni.so; do
    if [ -e "$dest/$so" ] && [ ! -e "$dest/${so}.bak" ]; then
      cp -f "$dest/$so" "$dest/${so}.bak"
      echo "  [backup] $dest/${so}.bak"
    fi
    install -m 0755 "$TMP_DIR/$so" "$dest/$so"
  done
  echo "  [installed] $dest/{libandroid_runtime.so,layoutlib_jni.so}"
}

echo "=== Installing to Termux standard paths ==="
install_pair "$PREFIX/lib"
install_pair "$PREFIX/lib/layoutlib"

if [ -n "$CUSTOM_DIR" ]; then
  install_pair "$CUSTOM_DIR"
fi

echo "=== Scanning for Android Studio / SDK layoutlib directories ==="
FOUND_TARGETS=()
SEARCH_ROOTS=()
for root in "${HOME:-}" "/data/data/com.termux/files/home" "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" "${ANDROID_STUDIO_HOME:-}" "$PREFIX/opt" "$PREFIX/share"; do
  [ -n "$root" ] && [ -d "$root" ] && SEARCH_ROOTS+=("$root")
done

if [ "${#SEARCH_ROOTS[@]}" -gt 0 ]; then
  while IFS= read -r hit; do
    d="$(dirname "$hit")"
    FOUND_TARGETS+=("$d")
  done < <(find "${SEARCH_ROOTS[@]}" -maxdepth 7 \( -name "layoutlib_jni.so" -o -name "libandroid_runtime.so" \) 2>/dev/null || true)

  while IFS= read -r ldir; do
    for sub in "data/linux/lib64" "data/linux/arm64" "data/linux"; do
      if [ -d "$ldir/$sub" ]; then
        FOUND_TARGETS+=("$ldir/$sub")
      fi
    done
    # If Android Studio uses data/linux/lib64 and it didn't exist yet under plugins/*/resources/layoutlib
    if [ -d "$ldir/data" ] && [ ! -d "$ldir/data/linux/lib64" ] && [ -d "$ldir/data/res" ]; then
      FOUND_TARGETS+=("$ldir/data/linux/lib64")
    fi
  done < <(find "${SEARCH_ROOTS[@]}" -maxdepth 6 -type d -name "layoutlib" 2>/dev/null || true)
fi

if [ "${#FOUND_TARGETS[@]}" -gt 0 ]; then
  while IFS= read -r unique_dir; do
    [ -n "$unique_dir" ] && install_pair "$unique_dir"
  done < <(printf "%s\n" "${FOUND_TARGETS[@]}" | sort -u)
else
  echo "  [info] No existing Android Studio layoutlib folder auto-detected under HOME/ANDROID_HOME."
  echo "         You can re-run with '--dir /path/to/layoutlib/data/linux/lib64' later if needed."
fi

echo "=== Installing CLI test utilities ==="
mkdir -p "$PREFIX/bin" "$PREFIX/share/layoutlib-bionic"
install -m 0755 "$TMP_DIR/layoutlib_native_probe" "$PREFIX/bin/layoutlib-probe"
install -m 0644 "$TMP_DIR/smoke-stubs.jar" "$PREFIX/share/layoutlib-bionic/smoke-stubs.jar"
install -m 0644 "$TMP_DIR/RenderXmlTest.jar" "$PREFIX/share/layoutlib-bionic/RenderXmlTest.jar"
install -m 0644 "$TMP_DIR/RenderXmlTest.java" "$PREFIX/share/layoutlib-bionic/RenderXmlTest.java"
install -m 0644 "$TMP_DIR/test_layout.xml" "$PREFIX/share/layoutlib-bionic/test_layout.xml"
install -m 0644 "$TMP_DIR/icudt78l.dat" "$PREFIX/share/layoutlib-bionic/icudt78l.dat"

cat > "$PREFIX/bin/layoutlib-test" << 'TEST_WRAPPER_EOF'
#!/usr/bin/env bash
set -euo pipefail

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
LIB_DIR="${LAYOUTLIB_NATIVE_DIR:-$PREFIX/lib/layoutlib}"
SHARE_DIR="$PREFIX/share/layoutlib-bionic"
MODE="${1:-smoke}"
if [ "$#" -gt 0 ]; then
  shift
fi

case "$MODE" in
  probe)
    exec "$PREFIX/bin/layoutlib-probe" "$LIB_DIR" "$@"
    ;;
  smoke)
    "$PREFIX/bin/layoutlib-probe" "$LIB_DIR"
    if ! command -v java >/dev/null 2>&1; then
      echo "[warn] 'java' not found. Native dlopen/symbol probe passed; install OpenJDK ('pkg install openjdk-17') to run JVM JNI test."
      exit 0
    fi
    exec java -cp "$SHARE_DIR/smoke-stubs.jar" android.layoutlib.test.SmokeTest "$LIB_DIR"
    ;;
  xml)
    XML_FILE="${1:-$SHARE_DIR/test_layout.xml}"
    OUT_PNG="${2:-${TMPDIR:-/tmp}/test_render.png}"
    if ! command -v java >/dev/null 2>&1; then
      echo "[error] 'java' not found. Install OpenJDK first." >&2
      exit 1
    fi
    SEARCH_LIST=()
    for r in "${ANDROID_STUDIO_HOME:-}" "${HOME:-}" "/data/data/com.termux/files" "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" "$PREFIX/opt" "$PREFIX/share" "/opt" "/usr/local" "/sdcard"; do
      [ -n "$r" ] && [ -d "$r" ] && SEARCH_LIST+=("$r")
    done

    # 1. Locate Android Studio / design-tools plugin root and layoutlib*.jar
    STUDIO_ROOT="${ANDROID_STUDIO_HOME:-}"
    if [ -z "$STUDIO_ROOT" ]; then
      for cand in \
        "${HOME:-}/android-studio-latest" \
        "/data/data/com.termux/files/home/android-studio-latest" \
        "${HOME:-}/android-studio" \
        "/data/data/com.termux/files/home/android-studio"; do
        if [ -d "$cand/plugins/design-tools" ] || [ -d "$cand/plugins/android" ]; then
          STUDIO_ROOT="$cand"
          break
        fi
      done
    fi
    if [ -z "$STUDIO_ROOT" ] && [ "${#SEARCH_LIST[@]}" -gt 0 ]; then
      DT_DIR="$(find "${SEARCH_LIST[@]}" -maxdepth 6 -type d -path "*/plugins/design-tools" 2>/dev/null | sort -V | tail -n 1 || true)"
      if [ -n "$DT_DIR" ]; then
        STUDIO_ROOT="$(cd "$DT_DIR/../.." && pwd)"
      fi
    fi

    LAYOUTLIB_JAR="${LAYOUTLIB_JAR:-}"
    if [ -z "$LAYOUTLIB_JAR" ] && [ -n "$STUDIO_ROOT" ]; then
      LAYOUTLIB_JAR="$(find "$STUDIO_ROOT" -maxdepth 6 -type f \( -name "layoutlib.jar" -o -name "layoutlib-jdk*.jar" -o -name "layoutlib-mvn.jar" -o -name "layoutlib-*.jar" \) 2>/dev/null | grep -v -E "layoutlib-api|layoutlib-loader" | head -n 1 || true)"
    fi
    if [ -z "$LAYOUTLIB_JAR" ] && [ "${#SEARCH_LIST[@]}" -gt 0 ]; then
      LAYOUTLIB_JAR="$(find "${SEARCH_LIST[@]}" -maxdepth 8 -type f \( -name "layoutlib.jar" -o -name "layoutlib-jdk*.jar" -o -name "layoutlib-mvn.jar" -o -name "layoutlib-*.jar" \) 2>/dev/null | grep -v -E "layoutlib-api|layoutlib-loader" | sort -V | tail -n 1 || true)"
    fi

    # 2. Locate data/res, fonts, and icudt78l.dat independently
    DATA_DIR="${LAYOUTLIB_DATA_DIR:-}"
    RES_DIR="${LAYOUTLIB_RES_DIR:-}"
    FONT_DIR="${LAYOUTLIB_FONT_DIR:-}"
    ICU_FILE="${LAYOUTLIB_ICU:-}"
    if [ -z "$DATA_DIR" ] && [ -n "$STUDIO_ROOT" ]; then
      for cand in \
        "$STUDIO_ROOT/plugins/design-tools/resources/layoutlib/data" \
        "$STUDIO_ROOT/plugins/android-design-tools/resources/layoutlib/data" \
        "$STUDIO_ROOT/plugins/android/lib/layoutlib/data"; do
        if [ -d "$cand" ]; then
          DATA_DIR="$cand"
          break
        fi
      done
    fi
    if [ -z "$DATA_DIR" ] && [ -n "$LAYOUTLIB_JAR" ]; then
      JDIR="$(dirname "$LAYOUTLIB_JAR")"
      [ -d "$JDIR/fonts" ] || [ -d "$JDIR/res" ] && DATA_DIR="$JDIR"
      [ -z "$DATA_DIR" ] && [ -d "$JDIR/../resources/layoutlib/data" ] && DATA_DIR="$(cd "$JDIR/../resources/layoutlib/data" && pwd)"
    fi
    if [ -z "$RES_DIR" ] && [ -n "$DATA_DIR" ] && [ -d "$DATA_DIR/res" ]; then
      RES_DIR="$DATA_DIR/res"
    fi
    if [ -z "$RES_DIR" ] && [ "${#SEARCH_LIST[@]}" -gt 0 ]; then
      RES_DIR="$(find "${SEARCH_LIST[@]}" -maxdepth 6 -type d -name "res" -path "*/platforms/android-*/data/res" 2>/dev/null | sort -V | tail -n 1 || true)"
      [ -z "$DATA_DIR" ] && [ -n "$RES_DIR" ] && DATA_DIR="$(dirname "$RES_DIR")"
    fi
    if [ -z "$FONT_DIR" ] && [ -n "$DATA_DIR" ] && [ -d "$DATA_DIR/fonts" ]; then
      FONT_DIR="$DATA_DIR/fonts"
    elif [ -z "$FONT_DIR" ] && [ -d "/system/fonts" ]; then
      FONT_DIR="/system/fonts"
    fi
    # Prefer AOSP 17 ICU 78 data matching our compiled libandroid_runtime.so
    if [ -z "$ICU_FILE" ] && [ -f "$SHARE_DIR/icudt78l.dat" ]; then
      ICU_FILE="$SHARE_DIR/icudt78l.dat"
    fi
    if [ -z "$ICU_FILE" ] && [ -n "$DATA_DIR" ] && [ -d "$DATA_DIR/icu" ]; then
      ICU_FILE="$(find "$DATA_DIR/icu" -maxdepth 1 -name "icudt*.dat" 2>/dev/null | sort -V | tail -n 1 || true)"
    fi
    if [ -z "$ICU_FILE" ] && [ -d "/apex/com.android.i18n/etc/icu" ]; then
      ICU_FILE="$(find /apex/com.android.i18n/etc/icu -maxdepth 1 -name "icudt*.dat" 2>/dev/null | head -n 1 || true)"
    fi

    # 3. Assemble Java classpath from Android Studio + SDK cmdline-tools
    if [ -n "${LAYOUTLIB_CP:-}" ]; then
      CP="$LAYOUTLIB_CP"
    else
      JARS=()
      [ -n "$LAYOUTLIB_JAR" ] && [ -f "$LAYOUTLIB_JAR" ] && JARS+=("$LAYOUTLIB_JAR")
      if [ -n "$STUDIO_ROOT" ]; then
        for jdir in \
          "$STUDIO_ROOT/plugins/design-tools/lib" \
          "$STUDIO_ROOT/plugins/design-tools/resources/layoutlib/data" \
          "$STUDIO_ROOT/plugins/android-design-tools/lib" \
          "$STUDIO_ROOT/plugins/android/lib" \
          "$STUDIO_ROOT/lib"; do
          if [ -d "$jdir" ]; then
            while IFS= read -r j; do JARS+=("$j"); done < <(find "$jdir" -maxdepth 2 -name "*.jar" 2>/dev/null || true)
          fi
        done
      fi
      # Also include SDK cmdline-tools jars (layoutlib-api, sdk-common, kxml2, guava) if installed
      if [ "${#SEARCH_LIST[@]}" -gt 0 ]; then
        while IFS= read -r j; do JARS+=("$j"); done < <(find "${SEARCH_LIST[@]}" -maxdepth 9 -type f -name "*.jar" -path "*/cmdline-tools/*/lib/*" 2>/dev/null || true)
      fi
      if [ "${#JARS[@]}" -gt 0 ]; then
        CP="$SHARE_DIR/RenderXmlTest.jar:$({ printf "%s\n" "${JARS[@]}" | grep -v -E '(/nio-fs[^/]*\.jar$|ijent)' || true; } | sort -u | tr '\n' ':' | sed 's/:$//')"
      else
        CP="$SHARE_DIR/RenderXmlTest.jar"
      fi
    fi

    # 4. Select best runnable java (skipping x86_64/non-executable JBRs, preferring ARM64 JDK 25+ if present)
    JAVA_BIN="${LAYOUTLIB_JAVA:-}"
    BEST_VER=0
    if [ -z "$JAVA_BIN" ]; then
      CAND_JAVAS=()
      [ -n "$STUDIO_ROOT" ] && [ -x "$STUDIO_ROOT/jbr/bin/java" ] && CAND_JAVAS+=("$STUDIO_ROOT/jbr/bin/java")
      for jcand in "${HOME:-}"/android-studio*/jbr/bin/java /data/data/com.termux/files/home/android-studio*/jbr/bin/java; do
        [ -x "$jcand" ] && CAND_JAVAS+=("$jcand")
      done
      [ -n "${JAVA_HOME:-}" ] && [ -x "$JAVA_HOME/bin/java" ] && CAND_JAVAS+=("$JAVA_HOME/bin/java")
      for jcand in "$PREFIX"/lib/jvm/*/bin/java "$PREFIX"/opt/openjdk*/bin/java "$(command -v java || true)"; do
        [ -n "$jcand" ] && [ -x "$jcand" ] && CAND_JAVAS+=("$jcand")
      done
      for jcand in "${CAND_JAVAS[@]}"; do
        if ! VER_OUT="$("$jcand" -version 2>&1)"; then
          continue
        fi
        VER_LINE="$(printf "%s\n" "$VER_OUT" | head -n 1)"
        MAJ="$(printf "%s" "$VER_LINE" | sed -n 's/.*"\([0-9]*\).*/\1/p')"
        if [ -n "$MAJ" ] && [ "$MAJ" -gt "$BEST_VER" ] 2>/dev/null; then
          BEST_VER="$MAJ"
          JAVA_BIN="$jcand"
        elif [ -z "$JAVA_BIN" ]; then
          JAVA_BIN="$jcand"
        fi
      done
    else
      VER_OUT="$("$JAVA_BIN" -version 2>&1 | head -n 1 || true)"
      BEST_VER="$(printf "%s" "$VER_OUT" | sed -n 's/.*"\([0-9]*\).*/\1/p')"
      BEST_VER="${BEST_VER:-0}"
    fi
    JAVA_BIN="${JAVA_BIN:-java}"

    echo "JAVA_BIN=$JAVA_BIN (major=${BEST_VER})"
    echo "LAYOUTLIB_JAR=$LAYOUTLIB_JAR"
    echo "STUDIO_ROOT=$STUDIO_ROOT"
    echo "LAYOUTLIB_DATA_DIR=$DATA_DIR"
    echo "LAYOUTLIB_RES_DIR=$RES_DIR"
    echo "LAYOUTLIB_FONT_DIR=$FONT_DIR"
    echo "LAYOUTLIB_ICU=$ICU_FILE"

    if ! printf "%s" "$CP" | grep -q "layoutlib"; then
      echo "[error] Could not locate Android Studio layoutlib.jar + IDE plugin JARs." >&2
      echo "Find your Android Studio folder in Termux and run:" >&2
      echo "  ANDROID_STUDIO_HOME=/path/to/android-studio layoutlib-test xml" >&2
      echo "Or run 'find ~ /opt /usr -name \"*layoutlib*.jar\" 2>/dev/null' to locate it." >&2
      exit 1
    fi

    JAVA_FLAGS=(-Djava.awt.headless=true)
    if [ "${BEST_VER:-0}" -ge 22 ] 2>/dev/null; then
      JAVA_FLAGS+=(--enable-native-access=ALL-UNNAMED)
    fi

    ARGS=(--data-dir "${DATA_DIR:-$RES_DIR/..}" --native-dir "$LIB_DIR" --xml "$XML_FILE" --out "$OUT_PNG")
    [ -n "$RES_DIR" ] && ARGS+=(--res-dir "$RES_DIR")
    [ -n "$FONT_DIR" ] && ARGS+=(--font-dir "$FONT_DIR")
    [ -n "$ICU_FILE" ] && ARGS+=(--icu "$ICU_FILE")
    exec "$JAVA_BIN" "${JAVA_FLAGS[@]}" -cp "$CP" RenderXmlTest "${ARGS[@]}"
    ;;
  *)
    echo "Usage: layoutlib-test [probe|smoke|xml [layout.xml] [out.png]]" >&2
    exit 2
    ;;
esac
TEST_WRAPPER_EOF
chmod 0755 "$PREFIX/bin/layoutlib-test"

echo ""
echo "=== Installation complete! ==="
echo "Quick tests:"
echo "  layoutlib-test smoke                     # Bionic dlopen + JVM JNI_OnLoad + HostProperties test"
echo "  layoutlib-test xml                       # Render sample test_layout.xml -> PNG using Android Studio layoutlib"
