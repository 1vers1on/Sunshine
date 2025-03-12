#!/bin/bash
# sudo pacman -Sy --noconfirm libdrm libevdev miniupnpc libnotify numactl opus openssl wayland xorg-server xcb-util xorg-xrandr xorg-xinput ninja npm udev wget xorg-server-xvfb boost libappindicator-gtk3

set -e
FFMPEG_PREPARED_BINARIES=/usr/bin/ffmpeg
# git submodule update --init --recursive
function run_install() {
  cmake_args=(
    "-B=build"
    "-G=Ninja"
    "-S=."
    "-DBUILD_WERROR=ON"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCMAKE_INSTALL_PREFIX=/usr"
    "-DSUNSHINE_ASSETS_DIR=share/sunshine"
    "-DSUNSHINE_EXECUTABLE_PATH=/usr/bin/sunshine"
    "-DSUNSHINE_ENABLE_WAYLAND=ON"
    "-DSUNSHINE_ENABLE_X11=ON"
    "-DSUNSHINE_ENABLE_DRM=ON"
  )

  if [ "$appimage_build" == 1 ]; then
    cmake_args+=("-DSUNSHINE_BUILD_APPIMAGE=ON")
  fi

  # Publisher metadata
  if [ -n "$publisher_name" ]; then
    cmake_args+=("-DSUNSHINE_PUBLISHER_NAME='${publisher_name}'")
  fi
  if [ -n "$publisher_website" ]; then
    cmake_args+=("-DSUNSHINE_PUBLISHER_WEBSITE='${publisher_website}'")
  fi
  if [ -n "$publisher_issue_url" ]; then
    cmake_args+=("-DSUNSHINE_PUBLISHER_ISSUE_URL='${publisher_issue_url}'")
  fi

#   # Update the package list
#   $package_update_command

#   if [ "$distro" == "debian" ]; then
#     add_debain_deps
#   elif [ "$distro" == "ubuntu" ]; then
#     add_ubuntu_deps
#   elif [ "$distro" == "fedora" ]; then
#     add_fedora_deps
#     ${sudo_cmd} dnf group install "Development Tools" -y
#   fi

#   # Install the dependencies
#   $package_install_command "${dependencies[@]}"

  # reload the environment
  # shellcheck source=/dev/null
  source ~/.bashrc

#   gcc_alternative_files=(
#     "gcc"
#     "g++"
#     "gcov"
#     "gcc-ar"
#     "gcc-ranlib"
#   )

#   # update alternatives for gcc and g++ if a debian based distro
#   if [ "$distro" == "debian" ] || [ "$distro" == "ubuntu" ]; then
#     for file in "${gcc_alternative_files[@]}"; do
#       file_path="/etc/alternatives/$file"
#       if [ -e "$file_path" ]; then
#         mv "$file_path" "$file_path.bak"
#       fi
#     done

#     ${sudo_cmd} update-alternatives --install \
#       /usr/bin/gcc gcc /usr/bin/gcc-${gcc_version} 100 \
#       --slave /usr/bin/g++ g++ /usr/bin/g++-${gcc_version} \
#       --slave /usr/bin/gcov gcov /usr/bin/gcov-${gcc_version} \
#       --slave /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-${gcc_version} \
#       --slave /usr/bin/gcc-ranlib gcc-ranlib /usr/bin/gcc-ranlib-${gcc_version}
#   fi

#   # compile cmake if the version is too low
#   cmake_min="3.25.0"
#   target_cmake_version="3.30.1"
#   if ! check_version "cmake" "$cmake_min"; then
#     cmake_prefix="https://github.com/Kitware/CMake/releases/download/v"
#     if [ "$architecture" == "x86_64" ]; then
#     elif [ "$architecture" == "aarch64" ]; then
#       cmake_arch="aarch64"
#     fi
#     url="${cmake_prefix}${target_cmake_version}/cmake-${target_cmake_version}-linux-${cmake_arch}.sh"
#     echo "cmake url: ${url}"
#     wget "$url" --progress=bar:force:noscroll -q --show-progress -O "${build_dir}/cmake.sh"
#     ${sudo_cmd} sh "${build_dir}/cmake.sh" --skip-license --prefix=/usr/local
#     echo "cmake installed, version:"
#     cmake --version
#   fi

#   # compile doxygen if version is too low
#   doxygen_min="1.10.0"
#   _doxygen_min="1_10_0"
#   if ! check_version "doxygen" "$doxygen_min"; then
#     if [ "${SUNSHINE_COMPILE_DOXYGEN}" == "true" ]; then
#       echo "Compiling doxygen"
#       doxygen_url="https://github.com/doxygen/doxygen/releases/download/Release_${_doxygen_min}/doxygen-${doxygen_min}.src.tar.gz"
#       echo "doxygen url: ${doxygen_url}"
#       wget "$doxygen_url" --progress=bar:force:noscroll -q --show-progress -O "${build_dir}/doxygen.tar.gz"
#       tar -xzf "${build_dir}/doxygen.tar.gz"
#       cd "doxygen-${doxygen_min}"
#       cmake -DCMAKE_BUILD_TYPE=Release -G="Ninja" -B="build" -S="."
#       ninja -C "build" -j"${num_processors}"
#       ninja -C "build" install
#     else
#       echo "Doxygen version too low, skipping docs"
#       cmake_args+=("-DBUILD_DOCS=OFF")
#     fi
#   fi

    cmake_args+=("-DBUILD_DOCS=OFF")

#   # install node from nvm
#   if [ "$nvm_node" == 1 ]; then
#     nvm_url="https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh"
#     echo "nvm url: ${nvm_url}"
#     wget -qO- ${nvm_url} | bash
#     source "$HOME/.nvm/nvm.sh"
#     nvm install node
#     nvm use node
#   fi

  # run the cuda install
  if [ -n "$cuda_version" ] && [ "$skip_cuda" == 0 ]; then
    cmake_args+=("-DSUNSHINE_ENABLE_CUDA=ON")
    cmake_args+=("-DCMAKE_CUDA_COMPILER:PATH=$(which nvcc)")
  fi

  # Cmake stuff here
  mkdir -p "build"
  echo "cmake args:"
  echo "${cmake_args[@]}"
  cmake "${cmake_args[@]}"
  ninja -C "build"

  if [ "$skip_cleanup" == 0 ]; then
    # restore the math-vector.h file
    if [ "$architecture" == "aarch64" ] && [ -n "$math_vector_file" ]; then
      ${sudo_cmd} mv -f "$math_vector_file.bak" "$math_vector_file"
    fi
  fi
}

# get directory of this script
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
build_dir="$script_dir/../build"
echo "Script Directory: $script_dir"
echo "Build Directory: $build_dir"
mkdir -p "$build_dir"

run_install
