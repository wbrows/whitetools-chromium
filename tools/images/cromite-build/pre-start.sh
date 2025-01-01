#!/bin/bash

RED='\033[0;31m'
NC='\033[0m' # No Color

WORKSPACE=/home/lg/working_dir
PATH=$WORKSPACE/chromium/src/third_party/llvm-build/Release+Asserts/bin:$WORKSPACE/depot_tools/:/usr/local/go/bin:$PATH

sudo apt-get install -y lsof libgoogle-glog-dev libprotobuf17 libgrpc++1 parallel golang-go nano

echo -e ${RED} -------- download bromite mtool ${NC}
git clone https://github.com/bromite/mtool
cd mtool
make
cd ..

echo -e ${RED} -------- download ninjatracing ${NC}
git clone https://github.com/nico/ninjatracing

mkdir $CIPD_CACHE_DIR
mkdir $VPYTHON_VIRTUALENV_ROOT

echo -e ${RED} -------- download goma client ${NC}
cd $WORKSPACE
cipd install infra/goma/client/linux-amd64 -root $WORKSPACE/goma

echo "nomatter" >$WORKSPACE/.debug_auth_file
sudo cp $WORKSPACE/goma_auth.py $WORKSPACE/goma/

echo -e ${RED} -------- prepare vpython virtual environment ${NC}
rm -rf /tmp/vpython*
cd $WORKSPACE/chromium/src
vpython3 -vpython-spec .vpython3 -vpython-root $VPYTHON_VIRTUALENV_ROOT -vpython-log-level debug -vpython-tool install

echo -e ${RED} -------- download pgo profiles ${NC}
python3 tools/update_pgo_profiles.py --target=android-arm64 update --gs-url-base=chromium-optimization-profiles/pgo_profiles
python3 tools/update_pgo_profiles.py --target=android-arm32 update --gs-url-base=chromium-optimization-profiles/pgo_profiles
python3 tools/update_pgo_profiles.py --target=win64 update --gs-url-base=chromium-optimization-profiles/pgo_profiles
python3 tools/update_pgo_profiles.py --target=linux update --gs-url-base=chromium-optimization-profiles/pgo_profiles

echo -e ${RED} -------- download x86_64 android image ${NC}
#echo -e "\$ParanoidMode CheckIntegrity\n\nchromium/third_party/android_sdk/public/avds/android-31/google_apis/x86_64 Ur_zl6_BRKRkf_9X3SMZ3eH2auoOyJ2kLslpTZZwi3gC" | .cipd_client ensure -ensure-file - -root $WORKSPACE/chromium/src/.android
#echo -e "\$ParanoidMode CheckIntegrity\n\nchromium/third_party/android_sdk/public/emulator gMHhUuoQRKfxr-MBn3fNNXZtkAVXtOwMwT7kfx8jkIgC\nchromium/third_party/android_sdk/public/system-images/android-31/google_apis/x86_64 R6Jh5_P21Euu-kdb11zcNjdJKN4vV1mdQTb8t4gph4IC" | .cipd_client ensure -ensure-file - -root $WORKSPACE/chromium/src/.emulator_sdk

echo -e ${RED} -------- download kythe resources ${NC}
wget https://chromium.googlesource.com/chromium/tools/build/+/main/recipes/recipe_modules/codesearch/resources/add_kythe_metadata.py?format=TEXT -O ~/add_kythe_metadata.py.base64
base64 -d ~/add_kythe_metadata.py.base64 >~/add_kythe_metadata.py
echo -e "infra/tools/package_index/linux-amd64 latest" | .cipd_client ensure -ensure-file - -root ~/package_index/latest

cd $WORKSPACE/
wget https://github.com/kythe/kythe/releases/download/v0.0.55/kythe-v0.0.55.tar.gz
tar xfz kythe-v0.0.55.tar.gz

# removed since fail download with
# https://commondatastorage.9oo91eapis.qjz9zk/chromium-browser-clang/Linux_x64/translation_unit-llvmorg-14-init-5759-g02895eed-1.tgz 
cd $WORKSPACE/chromium/src
python3 tools/clang/scripts/update.py --package=translation_unit

echo -e ${RED} -------- build modified ninja ${NC}
cd $WORKSPACE/
git clone https://github.com/ninja-build/ninja.git -b v1.8.2
cd ninja
git apply $WORKSPACE/cromite/tools/ninja-one-target-for-compdb.patch
CXX=clang++ ./configure.py --bootstrap

echo -e ${RED} -------- download clang indexer ${NC}
cd $WORKSPACE/
wget https://github.com/clangd/clangd/releases/download/17.0.3/clangd_indexing_tools-linux-17.0.3.zip
unzip clangd_indexing_tools-linux-17.0.3.zip
rm clangd_indexing_tools-linux-17.0.3.zip

echo -e ${RED} -------- download rc ${NC}
cd $WORKSPACE/chromium/src
python3 third_party/depot_tools/download_from_google_storage.py	\
    --no_resume  --no_auth \
    --bucket chromium-browser-clang/rc \
    -s build/toolchain/win/rc/linux64/rc.sha1

echo -e ${RED} -------- download clang prebuilds ${NC}
cd $WORKSPACE/chromium/src
python3 tools/clang/scripts/update.py --package=clang --host-os=win --no-clear=true
python3 tools/clang/scripts/update.py --package=clang --host-os=linux --no-clear=true
