
########################################################################
########################################################################
#
#       Faustservice (remote Faust compiler) in a docker
#                 (L. Champenois & Y. Orlarey)
#
########################################################################
########################################################################

FROM ubuntu:16.04
RUN apt-get update

########################################################################
# We first install all the dependencies but Android
########################################################################

# We first install all the ubuntu packages
RUN DEBIAN_FRONTEND='noninteractive' apt-get install -y --no-install-recommends \
build-essential pkg-config git cmake libmicrohttpd-dev llvm-3.8 llvm-3.8-dev libssl-dev \
software-properties-common zip unzip wget ncurses-dev libsndfile-dev libedit-dev libcurl4-openssl-dev vim-common \
libasound2-dev libjack-jackd2-dev libgtk2.0-dev libqt4-dev \
ladspa-sdk dssi-dev lv2-dev libboost-dev libcsound64-dev supercollider-dev puredata-dev \
inkscape graphviz qtbase5-dev qt5-qmake libqt5x11extras5-dev texlive-full \
libarchive-dev libboost-all-dev \
php libapache2-mod-php qrencode highlight apache2 ruby ruby-dev nodejs \
openjdk-8-jdk g++-mingw-w64 g++-multilib  \
 && apt-get clean \
 && rm /var/lib/apt/lists/*_*

# Then additional packages from ppa repositories
RUN add-apt-repository -y "ppa:dr-graef/pure-lang.xenial"; \
add-apt-repository -y "ppa:certbot/certbot"; \
apt-get update; \
apt-get install -y faust2pd faust2pd-extra python-certbot-apache

# We install the MAX SDK
RUN wget https://cycling74.com/download/max-sdk-7.1.0.zip; \
unzip max-sdk-7.1.0.zip; \
cp -r max-sdk-7.1.0/source/c74support /usr/local/include/

# We install the Puredata dll for windows
RUN wget https://github.com/grame-cncm/faustinstaller/raw/master/rsrc/pd.dll; \
install -d /usr/lib/i686-w64-mingw32/pd/; \
cp pd.dll /usr/lib/i686-w64-mingw32/pd/

# We install the VST SDK
RUN wget http://www.steinberg.net/sdk_downloads/vstsdk365_12_11_2015_build_67.zip; \
unzip vstsdk365_12_11_2015_build_67.zip -d /usr/local/include/; \
mv /usr/local/include/VST3\ SDK /usr/local/include/vstsdk2.4

# Fix execution QT5 targets
RUN ln -s /usr/lib/x86_64-linux-gnu/qt5/bin/qmake /usr/bin/qmake-qt5


########################################################################
# Then we install Android
########################################################################

RUN wget https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip; \
mkdir android; \
unzip sdk-tools-linux-3859397.zip -d android; \
install -d /root/.android/; \
touch /root/.android/repositories.cfg

## sign licenses
RUN	yes | android/tools/bin/sdkmanager --licenses

## Android tools
RUN android/tools/bin/sdkmanager "build-tools;25.0.3"  "cmake;3.6.4111459" \
"emulator"  "extras;android;m2repository" "ndk-bundle" "patcher;v4" \
"platform-tools" "platforms;android-25"  "platforms;android-27" "tools" 

## Creates expected environment for faust2android and faust2smarkeyb
ENV ANDROID_HOME=/android ANDROID_NDK_HOME=/android/ndk-bundle
RUN install -d /opt/android; \
ln -s /android /opt/android/sdk; \
ln -s /android/ndk-bundle /opt/android/ndk

########################################################################
# Now we can clone and compile all the Faust related git repositories
########################################################################

# faustservice first as it changes less often
RUN git clone https://github.com/ludoch/faustservice.git; \
git -C faustservice checkout server; \
make -C faustservice

# then the faust compiler itself
RUN git clone https://github.com/grame-cncm/faust.git; \
git -C faust checkout faust-server; \
make -C faust; \
make -C faust httpd; \
make -C faust install

########################################################################
# And starts Faustservice
########################################################################

EXPOSE 8080
WORKDIR /faustservice
CMD ./faustweb --port 8080

