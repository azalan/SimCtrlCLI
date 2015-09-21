#!/bin/bash

SCRIPT_NAME=$( basename "$0" )
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

show_project_build_settings() {
  local project="$1"; shift
  local target="$1"; shift
  local configuration="$1"
  xcodebuild -project "${project}" -target "${target}" -configuration "${configuration}" -sdk iphonesimulator -showBuildSettings 2>/dev/null
}

parse_env_var() {
  local env_var_name="$1"

  grep -e "\\s${env_var_name}" - | cut -d '=' -f 2- | xargs
}

log_msg() {
  local msg="$1"
  echo "[${SCRIPT_NAME}] ${msg}"
}


USE_CONFIGURATION="Debug"

IOS_APP_DIR="${SCRIPT_DIR}/build/iOS"
MAC_APP_DIR="${SCRIPT_DIR}/build/Mac"

mkdir -p "${IOS_APP_DIR}"
mkdir -p "${MAC_APP_DIR}"

log_msg "Building iOS app with tests..."
cd "${SCRIPT_DIR}/SingleViewApp"
xcodebuild -project "SingleViewApp.xcodeproj" -target "SingleViewApp" -configuration "${USE_CONFIGURATION}" -sdk "iphonesimulator" build CONFIGURATION_BUILD_DIR="${IOS_APP_DIR}"
xcodebuild -project "SingleViewApp.xcodeproj" -target "SingleViewAppTests" -configuration "${USE_CONFIGURATION}" -sdk "iphonesimulator" build CONFIGURATION_BUILD_DIR="${IOS_APP_DIR}"
SINGLE_VIEW_APP_BUILD_PATH=$( show_project_build_settings "SingleViewApp.xcodeproj" "SingleViewApp" "${USE_CONFIGURATION}" | parse_env_var "TARGET_BUILD_DIR" )
log_msg "iOS app build finished."

log_msg "Initializing FBSimulatorControl submodule..."
git submodule init
git submodule update
log_msg "FBSimulatorControl submodule initialized."

cd "${SCRIPT_DIR}/FBSimulatorControl"
log_msg "Installing CocoaPods dependencies..."
pod install

log_msg "Building the simulator driver..."
cd "${SCRIPT_DIR}/DriveSimulators"
rm -rf build
xcodebuild -project "DriveSimulators.xcodeproj" -target "DriveSimulators" -configuration "${USE_CONFIGURATION}" build CONFIGURATION_BUILD_DIR="${MAC_APP_DIR}"
log_msg "Simulator driver is built."

log_msg "Create a link to FBSimulatorControl into the users Frameworks folder..."
mkdir -p ~/Library/Frameworks
ln -Fs "${MAC_APP_DIR}/FBSimulatorControl.framework" ~/Library/Frameworks/FBSimulatorControl.framework

log_msg "Running simulator driver with the iOS app..."
for mode in {1..4}; do
  "${MAC_APP_DIR}/DriveSimulators" "${IOS_APP_DIR}" $mode
done
log_msg "Testing has been finished."
