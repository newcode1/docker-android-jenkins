FROM       ubuntu:16.04

#ADD sources.list /opt/
#RUN ls -la /opt/
#RUN cp /etc/apt/sources.list /etc/apt/sources.list.bak
#RUN cp /opt/sources.list /etc/apt/sources.list

RUN apt-get update && apt-get install -y supervisor tzdata
RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV DEBIAN_FRONTEND noninteractive
ENV TZ 	Asia/Shanghai

RUN rm -rf /etc/localtime && \
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
dpkg-reconfigure -f noninteractive tzdata


RUN dpkg --add-architecture i386

RUN apt-get update

RUN apt-get install -y  dialog apt-utils software-properties-common openssh-server git curl wget zip 

RUN \
    apt-get install -y libncurses5:i386 libc6:i386 libstdc++6:i386 lib32gcc1 lib32ncurses5 lib32z1 zlib1g:i386

#RUN add-apt-repository -y universe && apt-get update


#jdk8

RUN \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get -y update && \
  apt-get install -y oracle-java8-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer

WORKDIR /data

# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle




#ssh
RUN mkdir /var/run/sshd

RUN echo 'root:root' |chpasswd

RUN sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config





# download and install Gradle
ENV GRADLE_VERSION 4.6
RUN cd /opt && \
    wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip && \
    unzip gradle*.zip && \
    ls -d */ | sed 's/\/*$//g' | xargs -I{} mv {} gradle && \
    rm gradle*.zip



# download and install Kotlin compiler
ENV KOTLIN_VERSION 1.2.40
RUN cd /opt && \
    wget -q https://github.com/JetBrains/kotlin/releases/download/v${KOTLIN_VERSION}/kotlin-compiler-${KOTLIN_VERSION}.zip && \
    unzip *kotlin*.zip && \
    rm *kotlin*.zip



#android sdk tools
ENV ANDROID_SDK_VERSION 3859397
RUN mkdir -p /opt/android-sdk && cd /opt/android-sdk && \
    wget -q https://dl.google.com/android/repository/sdk-tools-linux-${ANDROID_SDK_VERSION}.zip && \
    unzip *tools*linux*.zip && \
    rm *tools*linux*.zip



ENV GRADLE_HOME /opt/gradle
ENV KOTLIN_HOME /opt/kotlinc
ENV ANDROID_HOME /opt/android-sdk
ENV PATH ${PATH}:${GRADLE_HOME}/bin:${KOTLIN_HOME}/bin:${ANDROID_HOME}/emulator:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/tools/bin

ADD license_accepter.sh /opt/
RUN chmod +x /opt/license_accepter.sh
RUN /opt/license_accepter.sh $ANDROID_HOME

RUN echo y | $ANDROID_HOME/tools/bin/sdkmanager 'platform-tools'
RUN echo y | $ANDROID_HOME/tools/bin/sdkmanager 'build-tools;27.0.3'
RUN echo y | $ANDROID_HOME/tools/bin/sdkmanager 'platforms;android-27'


ENV JENKINS_HOME /opt/jenkins_home
RUN mkdir ${JENKINS_HOME}


#Jenkins
RUN mkdir -p /usr/share/jenkins
RUN mkdir -p /usr/share/jenkins/ref/init.groovy.d
ENV JENKINS_WAR /usr/share/jenkins/jenkins.war
ENV JENKINS_VERSION 2.107.2
ENV COPY_REFERENCE_FILE_LOG $JENKINS_HOME/copy_reference_file.log

ARG JENKINS_URL=https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/${JENKINS_VERSION}/jenkins-war-${JENKINS_VERSION}.war


RUN wget  ${JENKINS_URL} --no-check-certificate -O ${JENKINS_WAR}

COPY jenkins/init.groovy /usr/share/jenkins/ref/init.groovy.d/tcp-slave-agent-port.groovy
COPY jenkins/jenkins-support /usr/local/bin/jenkins-support
COPY jenkins/jenkins.sh /usr/local/bin/jenkins.sh



EXPOSE 22
EXPOSE 8080


CMD env | grep _ >> /etc/environment ; /usr/bin/supervisord

