FROM amazonlinux:2018.03
MAINTAINER R Marroquin <marenato@inf.ethz.ch>

# general packages
RUN touch /var/lib/rpm/* && \
    yum install -y gcc72 gcc72-c++ zlib-devel xz yum tar gzip unzip wget which && \
    yum -y clean all

# packages for aws 
RUN touch /var/lib/rpm/* && \
    yum install -y libcurl-devel openssl-devel && \
    yum -y clean all

RUN mkdir -p /src/cmake/ && \
    cd /src/cmake && \
    wget https://cmake.org/files/v3.13/cmake-3.13.4.tar.gz -O - | tar -xz --strip-components=1 && \
    ./configure --prefix=/usr --system-curl && make && make install && \
    rm -rf /src/cmake

RUN touch /var/lib/rpm/* && \
    yum install -y git && \
    yum -y clean all

RUN mkdir -p /src/ && cd /src && git clone https://github.com/aws/aws-sdk-cpp.git && \
    mkdir aws-sdk-cpp/build && cd aws-sdk-cpp/build && git checkout -b 1.7.117 tags/1.7.117 && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_ONLY='s3;lambda;sqs' -DENABLE_TESTING=OFF  -DCUSTOM_MEMORY_MANAGEMENT=ON -DBUILD_DEPS=ON && \
    make && make install && \
    rm -rf /src/aws-sdk-cpp

# packages for llvm 
RUN touch /var/lib/rpm/* && \
    yum install -y perl-core binutils-devel && \
    yum -y clean all

RUN wget http://releases.llvm.org/7.0.1/llvm-7.0.1.src.tar.xz -O - | tar -xJ && \
    wget http://releases.llvm.org/7.0.1/cfe-7.0.1.src.tar.xz -O - | tar -xJ && \
    wget https://releases.llvm.org/7.0.1/openmp-7.0.1.src.tar.xz -O - | tar -xJ && \
    mv openmp-7.0.1.src/ llvm-7.0.1.src/projects/openmp && \
    mv cfe-7.0.1.src/ llvm-7.0.1.src/tools/clang && \
    mkdir llvm-7.0.1.build && cd llvm-7.0.1.build && \
    cmake ../llvm-7.0.1.src/ -DLLVM_TOOL_LLDB_BUILD=ON -DLLVM_TARGETS_TO_BUILD=X86 -DCMAKE_BUILD_TYPE=Release -DLLVM_TOOL_OPENMP_BUILD=ON -DLLVM_BINUTILS_INCDIR=/usr/include && \
    make && make install && cd / && \
    rm -rf /src/llvm-7.0.1.src /src/llvm-7.0.1.build

RUN cd /tmp && \
    wget https://dl.bintray.com/boostorg/release/1.69.0/source/boost_1_69_0.tar.gz -O - | tar -xz && \
    cd boost_1_69_0/ && \
    ./bootstrap.sh --with-python-version=3.6 --with-libraries="regex,system,filesystem,program_options,serialization" variant=release toolchain=clang --prefix=/usr && \
    ./b2 && \
    ./b2 install && \
    cd / && rm -rf /tmp/boost_*

# packages for jitq
RUN touch /var/lib/rpm/* && \
    yum install -y python36.x86_64 python36-devel.x86_64 python36-pip.noarch && \
    yum -y clean all

RUN touch /var/lib/rpm/* && \
    yum install -y graphviz-devel pcre-devel.x86_64 python-devel && \
    yum -y clean all

RUN cd /tmp/ && \
    wget https://github.com/danmar/cppcheck/archive/1.81.zip && \
    unzip 1.81.zip && \
    cd /tmp/cppcheck-1.81 && \
    make SRCDIR=build CFGDIR=/opt/cppcheck-1.81/share/cfg HAVE_RULES=yes \
     CXXFLAGS="-O2 -DNDEBUG -Wall -Wno-sign-compare -Wno-unused-function" && \
    mkdir -p /opt/cppcheck-1.81/bin /opt/cppcheck-1.81/share && \
    cp -r cfg /opt/cppcheck-1.81/share && \
    cp cppcheck /opt/cppcheck-1.81/bin/cppcheck-1.81 && \
    for bin in /opt/cppcheck-1.81/bin/cppcheck-1.81; do     ln -s $bin /usr/bin/; done && \
    cd / && rm -rf /tmp/cppcheck*

#RUN cd /src && \
#    git clone https://gitlab.inf.ethz.ch/OU-SYSTEMS/jitq && \
#    cd jitq/ && git fetch --all && git checkout -b lambda_env remotes/origin/lambda_env && \
#    git submodule init && git submodule update && \
#    cd backend/build && \
#    CXX=clang++ CC=clang cmake ../src/ -DCMAKE_BUILD_TYPE=Relase && \
#    make && \
#    #echo -e "CC=clang\nCXX=clang++\nLIBOMPDIR=/src/llvm-7.0.1.src/lib" > ../src/code_gen/cpp/Makefile.local && \
#    cd /src/jitq && pip-3.6 install -r requirements.txt
#
#RUN export JITQPATH=/src/jitq && \
#    export PYTHONPATH=$JITQPATH/python:$JITQPATH/backend/build && \
#    export LD_LIBRARY_PATH=/usr/local/lib64:/usr/local/lib:/usr/lib
#    #:/src/llvm-7.0.1.build/lib

