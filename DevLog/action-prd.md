

### 产品需求文档 (PRD): RetroShare Headless Service GitHub Actions 自动化编译

---

### 1.0 项目背景与目标

#### 1.1 核心背景
*   **用户场景**：用户需要在Azure云上的一台**Debian 12 (Bookworm)** 虚拟机中，部署一个“headless”(无图形界面)的RetroShare节点。通过 `SSH -L` 本地端口转发，用户希望能在本地浏览器中，通过RetroShare服务提供的Web界面(Web UI)来远程访问它。
*   **当前痛点**：用户本地编译环境（1GB虚拟机WSL）资源不足，极易导致编译过程被操作系统因内存不足（Out-Of-Memory, OOM）而终止。因此，他需要一种可靠的云端编译方案。

#### 1.2 核心目标
*   **首要目标**：利用 **GitHub Actions** 平台，构建一套完全自动化的CI（持续集成）工作流。
*   **直接产出**：生成一个**预启用 JSON API 和 Web UI 的原生 Headless RetroShare 服务二进制文件**。
*   **最终结果**：将此编译产物部署到用户的 Debian 12 虚拟机上，通过 `retroshare-service` 命令行工具或 `systemd` 服务的形式运行，最终实现远程访问与管理。

---

### 2.0 技术方案与约束

#### 2.1 方案选择: 为什么是GitHub Actions？
我们最终决定采用在 `ubuntu-latest` 运行器上，通过 `debian:bookworm` **Docker容器执行编译**的方案。这能完美平衡环境纯净度、资源成本和配置简便性。

#### 2.2 技术约束与要求
*   **编译目标系统**: Debian 12 (Bookworm)
*   **目标架构**: `linux/amd64` (x86_64) (Azure VM标准架构)
*   **RetroShare特性要求**: 必须启用 `rs_jsonapi` 和 `rs_webui` 两个构建特性 (CONFIG)。
*   **代码来源**: 用户Fork的RetroShare主仓库，本地工作目录在 `D:\Personal\RetroshareAzure\RetroShare`。
*   **产物要求**: 最终提供的是 `retroshare-service` 可执行文件及其依赖的核心库。
*   **运行时环境约束**: 在目标机器上运行时，服务必须监听本地回环地址 (`127.0.0.1`)，以便配合SSH端口转发，这是最佳安全实践。

---

### 3.0 详细需求 (Functional Requirements)

本地有gh cli 可以直接运行

#### 3.1 需求 1: 构建与配置
*   **ID**: `REQ-BUILD-1`
*   **描述**: 工作流必须在指定的Debian 12容器内，顺序执行“安装依赖 -> 配置构建 -> 编译构建”的完整流程。
*   **详细流程**:
    1.  **环境准备**:
        *   配置 `debian:bookworm` 容器。
        *   更新APT软件源 (`apt-get update`)。
    2.  **依赖安装**: 安装RetroShare编译及运行所需的所有系统及第三方库。根据实际需求，大致应包含以下组件：
        ```bash
        apt-get install -y \
        build-essential qttools5-dev-tools qt5-qmake qtbase5-dev \
        libssl-dev libsqlcipher-dev libupnp-dev \
        libspeex-dev libspeexdsp-dev libxslt1-dev \
        libjson-c-dev rapidjson-dev libcurl4-openssl-dev \
        libmicrohttpd-dev
        ```
    3.  **源码操作**: 确保工作流能正确检出 (Checkout) `master` 或 `main` 分支。
    4.  **核心配置**: 运行 `qmake` 命令，并通过 `CONFIG` 参数启用 `release`(发布模式)、`rs_jsonapi`(启用JSON API) 和 `rs_webui`(启用Web UI) 三个核心特性。
        *   **引例**: 根据RetroShare构建系统的源码逻辑，`rs_webui` 依赖于 `rs_jsonapi`。
    5.  **执行编译**: 执行 `make -j$(nproc)` 命令。`$(nproc)` 参数会自动获取环境内可用的CPU核心数以进行并行编译，最大化构建速度。
    6.  **依赖与输出**:
        *   `retroshare-service` 可执行文件。
        *   `libretroshare.so` 这个核心动态库。

#### 3.2 需求 2: 集成与通知
*   **ID**: `REQ-BUILD-2`
*   **描述**: 优化工作流的可用性，将产物自动化地进行版本化并归档。
*   **详细流程**:
    1.  **触发条件**:
        *   支持 `on: workflow_dispatch:`，即支持用户在GitHub网页上手动点击触发构建，这提供了极高的灵活性。
    2.  **产物归档**:
        *   使用 `actions/upload-artifact` 动作。
        *   将 `retroshare-service` 和 `libretroshare.so` 压缩打包。

---

### 4.0 交付成果 (Deliverables)

1.  **GitHub Actions 工作流文件**: 一个名为 `build-debian12-service.yml` 的YAML文件，需要精确无误。我将提供完整的代码块。
2.  **使用与部署说明书**: 提供清晰的步骤，指导用户如何在Azure VM上下载构建好的 (`*.zip`) 并部署运行。
3.  **服务管理脚本（可选但推荐）**: 提供一个可以直接复制使用的 `retroshare.service` systemd 单元文件，让用户的retroshare进程能够开机自启，并在后台优雅运行。

---

### 5.0 验收标准 (Acceptance Criteria)

1.  **构建成功**: 在GitHub仓库的“Actions”标签页中，工作流能成功运行并变绿。
2.  **产物完整**: 在成功运行的工作流详情页，“Artifacts”(构建产物) 区域可见一个名为 `retroshare-debian12-service` 的可下载文件。
3.  **产物可执行**: 下载的压缩包内容可在用户的 Debian 12 服务器上直接解压。
4.  **SSH转发可行**: 用户能通过 `ssh -L` 命令将云服务器的Web端口映射到本地，并在本地浏览器中访问到RetroShare的Web管理界面。

---

### 附录 A: 构建依赖（Dependencies）

| 类别 | 关键软件包 | 说明 |
|:---|:---|:---|
| 编译工具链 | `build-essential`, `qt5-qmake`, `qttools5-dev-tools` | 基础编译器和Qt5的构建工具链。 |
| Qt 5 核心 | `qtbase5-dev`, `qtmultimedia5-dev` | Qt5的基础开发库。 |
| 安全加密库 | `libssl-dev`, `libsqlcipher-dev` | RetroShare安全功能的基石。 |
| 网络与解析 | `libupnp-dev` (UPnP端口转发), `libxslt1-dev` (XML处理), `libjson-c-dev`/`rapidjson-dev`(JSON支持), `libcurl4-openssl-dev` (HTTP通信) | 处理网络I/O和数据解析。 |
| 媒体处理 | `libspeex-dev`, `libspeexdsp-dev` | 音频编码和处理。 |

> **可行性验证**: 根据官方文档，这是经推荐的主流构建方式。`debian:bookworm` 容器为构建提供了绝对纯净、无干扰的系统环境，这不依赖于任何特定的第三方构建动作。

---

### 附录 B: 部署与运行指南

获得构建产物后，在Debian 12服务器上推荐按以下步骤部署。
1.  **解压与安装**:
    ```bash
    unzip retroshare-debian12-service.zip -d ~/retroshare-build
    ```
2.  **复制并创建软链接**:
    ```bash
    # 将动态库链接至系统库目录
    sudo cp ~/retroshare-build/libretroshare.so /usr/local/lib/
    sudo ldconfig

    # 将可执行文件放入系统路径
    sudo cp ~/retroshare-build/retroshare-service /usr/local/bin/
    ```
3.  **服务化与注册**:
    ```
4.  **启动与验证**:
    `
    服务将以手动运行，
这份PRD涵盖了从编译到部署的全流程，希望能帮助你顺利完成需求。