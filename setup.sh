#! /bin/bash

if [[ -d "llvm-source-39" ]]; then
    echo "Hello there! We just upgraded AirSim to Unreal Engine 4.18."
    echo "Here are few easy steps for upgrade so everything is new and shiny :)"
    echo "https://github.com/Microsoft/AirSim/blob/master/docs/unreal_upgrade.md"
    exit 1
fi

set -x
# set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" >/dev/null

downloadHighPolySuv=true
gccBuild=false
MIN_CMAKE_VERSION=3.10.0
MIN_GCC_VERSION=6.0.0
MIN_EIGEN_VERSION=3.3.5
function version_less_than_equal_to() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" = "$1"; }

# Parse command line arguments
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --no-full-poly-car)
    downloadHighPolySuv=false
    shift # past value
    ;;
    --gcc)
    gccBuild=true
    shift # past argument
    ;;
esac
done

# Update the package repository
if [ "$(uname)" == "Darwin" ]; then # osx
    brew update
else # linux
    sudo add-apt-repository ppa:ubuntu-toolchain-r/test
    wget -O - http://apt.llvm.org/llvm-snapshot.gpg.key|sudo apt-key add -
    sudo apt-get -y update
fi

# Config gcc toolchain
if $gccBuild; then # gcc toolchain
    gcc_ver=$(gcc -dumpfullversion)
    gcc_path=$(which cmake)
    if [[ "$gcc_path" == "" ]] ; then
        gcc_ver=0
    fi
    if version_less_than_equal_to $gcc_ver $MIN_GCC_VERSION; then
        if [ "$(uname)" == "Darwin" ]; then # osx
            brew install gcc-6 g++-6
        else # linux
            sudo apt-get install -y gcc-6 g++-6
        fi
    else
        echo "Already have good version of gcc: $gcc_ver"
    fi
else # llvm/clang toolchain
    clang_path=$(which /usr/local/opt/llvm@5/bin/clang)
    if [[ "$clang_path" == "" ]] ; then
        if [ "$(uname)" == "Darwin" ]; then # osx
            brew install llvm@5
        else # linux
            sudo apt-get install -y clang-5.0 clang++-5.0
        fi
    else
        echo "Already have good version of llvm/clang: 5.0"
    fi
fi

# Give user perms to access USB port - this is not needed if not using PX4 HIL
# TODO: figure out how to do below in travis
if [ "$(uname)" == "Darwin" ]; then # osx
    if [[ ! -z "${whoami}" ]]; then # this happens when running in travis
        sudo dseditgroup -o edit -a `whoami` -t user dialout
    fi
else # linux
    if [[ ! -z "${whoami}" ]]; then # this happens when running in travis
        sudo /usr/sbin/useradd -G dialout $USER
        sudo usermod -a -G dialout $USER
    fi
fi

# Install additional tools for obtaining and building the dependencies
if [ "$(uname)" == "Darwin" ]; then # osx
    brew install wget
    brew install coreutils
    # unzip is a built-in tool in mac
else # linux
    sudo apt-get install -y build-essential
    sudo apt-get install -y unzip
    # wget is a built-in tool in Ubuntu 16.04
fi

# Get CMake ready
cmake_ver=$(cmake --version 2>&1 | head -n1 | cut -d ' ' -f3 | awk '{print $NF}')
cmake_path=$(which cmake)
if [[ "$cmake_path" == "" ]] ; then
    cmake_ver=0
fi
if version_less_than_equal_to $cmake_ver $MIN_CMAKE_VERSION; then
    if [[ ! -d "cmake_build/bin" ]]; then
        echo "Downloading cmake..."
        wget https://github.com/Kitware/CMake/releases/download/v${MIN_CMAKE_VERSION}/cmake-${MIN_CMAKE_VERSION}-$(uname)-x86_64.tar.gz -O cmake.tar.gz
        rm -rf ./cmake_build
        mkdir ./cmake_build
        tar -xzf cmake.tar.gz -C cmake_build --strip-components 1
        rm cmake.tar.gz
    fi
    if [ "$(uname)" == "Darwin" ]; then # osx
        CMAKE="$(pwd)/cmake_build/CMake.app/Contents/bin/cmake"
    else # linux
        CMAKE="$(pwd)/cmake_build/bin/cmake"
    fi
else
    echo "Already have good version of cmake: $cmake_ver"
    CMAKE=$(which cmake)
fi

# Download rpclib
if [ ! -d "external/rpclib/rpclib-2.2.1" ]; then
    echo "*********************************************************************************************"
    echo "Downloading rpclib..."
    echo "*********************************************************************************************"

    wget  https://github.com/rpclib/rpclib/archive/v2.2.1.zip

    # remove previous versions
    rm -rf "external/rpclib"

    mkdir -p "external/rpclib"
    unzip v2.2.1.zip -d external/rpclib
    rm v2.2.1.zip
fi

# Download high-polycount SUV model
if $downloadHighPolySuv; then
    if [ ! -d "Unreal/Plugins/AirSim/Content/VehicleAdv" ]; then
        mkdir -p "Unreal/Plugins/AirSim/Content/VehicleAdv"
    fi
    if [ ! -d "Unreal/Plugins/AirSim/Content/VehicleAdv/SUV/v1.2.0" ]; then
            echo "*********************************************************************************************"
            echo "Downloading high-poly car assets.... The download is ~37MB and can take some time."
            echo "To install without this assets, re-run setup.sh with the argument --no-full-poly-car"
            echo "*********************************************************************************************"

            if [ -d "suv_download_tmp" ]; then
                rm -rf "suv_download_tmp"
            fi
            mkdir -p "suv_download_tmp"
            cd suv_download_tmp
            wget  https://github.com/Microsoft/AirSim/releases/download/v1.2.0/car_assets.zip
            if [ -d "../Unreal/Plugins/AirSim/Content/VehicleAdv/SUV" ]; then
                rm -rf "../Unreal/Plugins/AirSim/Content/VehicleAdv/SUV"
            fi
            unzip car_assets.zip -d ../Unreal/Plugins/AirSim/Content/VehicleAdv
            cd ..
            rm -rf "suv_download_tmp"
    fi
else
    echo "### Not downloading high-poly car asset (--no-full-poly-car). The default unreal vehicle will be used."
fi

# Download Eigen3
echo "Installing EIGEN library..."
if [ "$(uname)" == "Darwin" ]; then
    rm -rf ./AirLib/deps/eigen3/Eigen
else
    sudo rm -rf ./AirLib/deps/eigen3/Eigen
fi
echo "downloading eigen..."
wget http://bitbucket.org/eigen/eigen/get/${MIN_EIGEN_VERSION}.zip
unzip eigen-${MIN_EIGEN_VERSION}.zip -d temp_eigen
mkdir -p AirLib/deps/eigen3
mv temp_eigen/eigen*/Eigen AirLib/deps/eigen3
rm -rf temp_eigen
rm eigen-${MIN_EIGEN_VERSION}.zip

popd >/dev/null

set +x
echo ""
echo "************************************"
echo "AirSim setup completed successfully!"
echo "************************************"
