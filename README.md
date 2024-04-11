# vfox-java

[中文](README_CN.md) | [English](README.md)

> Java plugin for [vfox](https://github.com/version-fox/vfox)

Support for multiple JDK distributions, such as: Oracle, Graalvm, Eclipse & more.


# Usage

**Parameter Format**:  x.y.z-distribution

```shell
# add plugin for vfox
vfox add java

# add runtime 
vfox install java@x.y.z  # Use openjdk as default distribution.
vfox install java@x.y.z-graal # Use graalvm as distribution.

# view all available versions
vfox search java all # view all java sdks
vfox search java # view all for openjdk
vfox search java graal # view all for graalvm
```

# Supported JDK Distributions

> Thanks [SDKMAN](https://sdkman.io/jdks)!

## Bisheng (Huawei)
BiSheng JDK, an open-source adaptation of Huawei JDK derived from OpenJDK, is utilized across 500+ Huawei products, benefitting from the R&D team's extensive experience in addressing service-related challenges. As a downstream product of OpenJDK, it serves as a high-performance distribution for production environments, specifically addressing performance and stability issues in Huawei applications. BiSheng JDK excels in optimizing ARM architecture performance and stability, delivering enhanced results in big data scenarios. Its primary goal is to offer Java developers a stable, high-performance JDK, particularly excelling on the ARM architecture.

```shell
$ vfox install java x.y.z-bsg
$ vfox search java bsg
```

## Corretto (Amazon)
Amazon Corretto is a no-cost, multiplatform, production-ready distribution of the Open Java Development Kit (OpenJDK). Corretto comes with long-term support that will include performance enhancements and security fixes. Amazon runs Corretto internally on thousands of production services and Corretto is certified as compatible with the Java SE standard. With Corretto, you can develop and run Java applications on popular operating systems, including Linux, Windows, and macOS.

```shell
$ vfox install java x.y.z-amzn
$ vfox search java amzn
```

## Dragonwell (Alibaba)
Dragonwell, as a downstream version of OpenJDK, is the in-house OpenJDK implementation at Alibaba. It is optimized for online e-commerce, financial and logistics applications running on 100,000+ servers. Alibaba Dragonwell is the engine that runs these distributed Java applications in extreme scaling.

```shell
$ vfox install java x.y.z-albba
$ vfox search java albba
```

## GraalVM (Oracle)
Oracle GraalVM is the free GraalVM distribution from Oracle, based on Oracle JDK, and includes the high-performance Graal JIT compiler. GraalVM can compile Java applications ahead of time into standalone binaries that start instantly, scale fast, and use fewer compute resources. Oracle GraalVM Native Image provides advanced features including G1 GC, SBOM, as well as performance and size optimizations. It also makes it possible to embed Python, JavaScript, Ruby, and other languages into Java applications.

```shell
$ vfox install java x.y.z-graal
$ vfox search java graal
```

## GraalVM (GraalVM Community)
GraalVM CE is the open source distribution of GraalVM, based on OpenJDK, and includes the high-performance Graal JIT compiler. GraalVM can compile Java applications ahead of time into standalone binaries that start instantly, scale fast, and use fewer compute resources. It also makes it possible to embed Python, JavaScript, Ruby, and other languages into Java applications.

```shell
$ vfox install java x.y.z-graalce
$ vfox search java graalce
```

## Java SE Development Kit (Oracle)
This proprietary Java Development Kit is an implementation of the Java Platform, Standard Edition released by Oracle Corporation in the form of a binary product aimed at Java developers on Linux, macOS or Windows. The JDK includes a private JVM and a few other resources to finish the development of a Java application. It is distributed under the Oracle No-Fee Terms and Conditions License


```shell
$ vfox install java x.y.z-oracle
$ vfox search java oracle
```

## Kona (Tencent)
Tencent Kona is a free, multi-platform, and production-ready distribution of OpenJDK, featuring Long-Term Support (LTS) releases. It serves as the default JDK within Tencent for cloud computing, big data, and numerous other Java applications.

```shell
$ vfox install java x.y.z-kona
$ vfox search java kona
```

## Liberica (Bellsoft)
Liberica is a 100% open-source Java implementation. It is built from OpenJDK which BellSoft contributes to, is thoroughly tested and passed the JCK provided under the license from OpenJDK. All supported versions of Liberica also contain JavaFX.


```shell
$ vfox install java x.y.z-librca
$ vfox search java librca
```

## Liberica NIK (Bellsoft)
Liberica Native Image Kit is a utility that converts your JVM-based application into a fully compiled native executable ahead-of-time under the closed-world assumption with an almost instant startup time. Being compatible with various platforms, including lightweight musl-based Alpine Linux, it optimizes resource consumption and minimizes the static footprint.


```shell
$ vfox install java x.y.z-nik
$ vfox search java nik
```

## Mandrel (Red Hat)
Mandrel focuses on GraalVM's native-image component in order to provide an easy way for Quarkus users to generate native images for their applications. Developers using Quarkus should be able to go all the way from Java source code to lean, native, platform-dependent applications running on Linux. This capability is vital for deploying to containers in a cloud-native application development model.


```shell
$ vfox install java x.y.z-mandrel
$ vfox search java mandrel
```


## OpenJDK (jdk.java.net)
OpenJDK (Open Java Development Kit) is a free and open-source implementation of the Java Platform, Standard Edition (Java SE). It is the result of an effort Sun Microsystems began in 2006. The implementation is licensed under the GNU General Public License (GNU GPL) version 2 with a linking exception. Were it not for the GPL linking exception, components that linked to the Java class library would be subject to the terms of the GPL license. OpenJDK is the official reference implementation of Java SE since version 7.

```shell
$ vfox install java x.y.z-open
$ vfox search java open
```

## OpenJDK (Microsoft)
The Microsoft Build of OpenJDK is a no-cost distribution of OpenJDK that's open source and available for free for anyone to deploy anywhere. It includes Long-Term Support (LTS) binaries for Java 11 on x64 server and desktop environments on macOS, Linux, and Windows, and AArch64/ARM64 on Linux and Windows. Microsoft also publishes Java 16 binaries for all three major Operating Systems and both x64 and AArch64 (M1/ARM64) architectures.

```shell
$ vfox install java x.y.z-ms
$ vfox search java ms
```
## SapMachine (SAP)
SapMachine is a downstream version of the OpenJDK project. It is used to build and maintain a SAP supported version of OpenJDK for SAP customers and partners who wish to use OpenJDK to run their applications. SAP is committed to ensuring the continued success of the Java platform.


```shell
$ vfox install java x.y.z-sapmchn
$ vfox search java sapmchn
```

## Semeru (IBM)
Semeru Runtimes use the class libraries from OpenJDK, along with the Eclipse OpenJ9 Java Virtual Machine to enable developers to build and deploy Java applications that will start quickly, deliver great performance, all while using less memory.

```shell
$ vfox install java x.y.z-sem
$ vfox search java sem
```

## Temurin (Eclipse)
Formerly AdoptOpenJDK, the Eclipse Adoptium Temurin™ project provides code and processes that support the building of runtime binaries and associated technologies that are high performance, enterprise-caliber, cross-platform, open-source licensed, and Java SE TCK-tested for general use across the Java ecosystem.

```shell
$ vfox install java x.y.z-tem
$ vfox search java tem
```

## Trava (Trava)
TravaOpenJDK is OpenJDK for developers. It is based on dcevm and uses an integrated HotswapAgent, so allowing advanced hotswapping of classes by method and field addition or updates at runtime.

```shell
$ vfox install java x.y.z-trava
$ vfox search java trava
```

## Zulu (Azul Systems)
Azul Zulu Builds of OpenJDK are no-cost, production-ready open-source, TCK-tested, and certified OpenJDK distributions. They are available for a wide range of hardware platforms and operating systems and are compatible with special requirements, such as stripped-down JREs and builds, including OpenJFX and Coordinated Restore at Checkpoint (CRaC). They are supported as part of Azul Platform Core, which provides stabilized security updates for rapid, assured deployment into production and solution-oriented engineering assistance.

```shell
$ vfox install java x.y.z-zulu
$ vfox search java zulu
```

## Jetbrains

```shell
$ vfox install java x.y.z-jb
$ vfox search java jb
```


# Thanks

- [SDKMAN](https://github.com/sdkman/)
- [foojayio](https://github.com/foojayio/discoapi)