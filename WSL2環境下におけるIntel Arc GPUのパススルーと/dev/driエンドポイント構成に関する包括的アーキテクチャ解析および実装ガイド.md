WSL2環境下におけるIntel Arc GPUのパススルーと/dev/driエンドポイント構成に関する包括的アーキテクチャ解析および実装ガイド
序論と仮想化グラフィックスアーキテクチャのパラダイムシフト
現代のコンピューティング環境において、Windows Subsystem for Linux 2 (WSL2) を活用したクロスプラットフォーム開発およびデプロイメントは、システムアーキテクトやソフトウェアエンジニアにとって不可欠なインフラストラクチャとなっている。とりわけ、Intel Arcシリーズ（Alchemistアーキテクチャ等）のディスクリートGPU (dGPU) や、Intel Core Ultraプロセッサに内蔵される統合GPU (iGPU) の演算リソースを、Linuxゲスト環境へパススルーし、機械学習の推論、メディアエンコーディング、および科学技術計算に活用する需要が急増している。
しかしながら、標準的なベアメタルLinux環境とWSL2環境とでは、ハードウェアに対するアクセスアーキテクチャが根本的に異なるという事実を理解することが、システム設計の第一歩となる。ベアメタルLinuxにおいては、カーネル空間で動作するダイレクト・レンダリング・マネージャ (DRM) が i915 や xe といったネイティブなカーネルモジュールを介してGPUハードウェアを直接制御する 1。このプロセスにより、ユーザー空間には /dev/dri/renderD128 や /dev/dri/card0 といったデバイスノードが生成され、アプリケーションはこれらのノードを通じてハードウェア・アクセラレーションを享受する。
これに対し、WSL2はMicrosoftのHyper-Vテクノロジーを基盤としたパラバーチャライゼーション（準仮想化）アーキテクチャを採用している。WSL2環境において、Intel Arc GPUはPCIeデバイスとして直接ゲストOSにアタッチされるわけではない。Intel Arc AシリーズGPUは、シングルルートI/O仮想化 (SR-IOV) やIntel Graphics Virtualization Technology (GVT-g) といった、従来のハードウェアレベルでのGPU分割・パススルー技術をサポートしていないためである 2。その代わりとして、WSL2はWDDM (Windows Display Driver Model) の機能を利用し、ホストOS側で管理されているGPUリソースを、特殊な仮想デバイスノードである /dev/dxg (DirectX Graphics Kernel) を介してゲストLinuxへマッピングする手法をとっている 4。
このアーキテクチャの相違は、Linuxネイティブのマルチメディアアプリケーションやコンテナ環境（Dockerなど）を展開する際に重大な障害を引き起こす。FFmpeg、GStreamer、Jellyfin、Frigateなどの多くのアプリケーションは、ハードウェアの初期化パスとして /dev/dri ディレクトリ内のDRMノードの存在を前提（ハードコード）としているからである 5。本報告書は、この特異な仮想化アーキテクチャにおいて、システムに欠落している /dev/dri エンドポイントを如何にしてエミュレートし、Intel GPU向けのOpenCL/Level Zeroコンピュート環境、およびVA-API (Video Acceleration API) を用いたメディア処理環境を構築するかについて、網羅的かつ深淵な洞察を提供する。
WSL2におけるGPUマッピングの深層メカニズムと/dev/driの欠落
Dxgkrnlと仮想化グラフィックスの境界
WSL2のコンピュートおよびグラフィックス機能は、WindowsのDirectXコアをLinux側に投影する dxgkrnl (DirectX Graphics Kernel) ドライバによって提供されている。ホストOS側にインストールされたIntel Graphics Windows DCHドライバがWDDM 2.9以上の要件を満たしている場合、ゲストOSには /dev/dxg デバイスノードが自動的に生成され、これがハードウェアへのプライマリな通信経路となる 8。
ここで発生する根本的な問題は、ユーザー空間のアプリケーションがこの /dev/dxg を直接解釈できない点にある。従来のLinuxアプリケーションは、libdrmを介して /dev/dri/renderD128 にioctlコマンドを送信することでGPUと通信するよう設計されている。WSL2の標準状態では /dev/dri ディレクトリそのものが存在しないため、これらのアプリケーションはハードウェアの検出フェーズで失敗し、CPUによるソフトウェア処理へのフォールバックを余儀なくされるか、最悪の場合はセグメンテーションフォルトによってプロセスがクラッシュする 5。

コンポーネント
ベアメタルLinux環境
WSL2環境
アーキテクチャ上の差異と影響
カーネルドライバ
i915, xe
dxgkrnl
WSL2内ではLinuxネイティブなGPUドライバはロードされず、ホストのWDDMに依存する 1
デバイスノード
/dev/dri/renderD128
/dev/dxg
多くのアプリが依存する /dev/dri が標準で欠如しており、エミュレーションが必要となる 4
ビデオAPIバックエンド
iHD_drv_video.so
d3d12_drv_video.so
WSL2ではネイティブドライバが機能せず、MesaによるDirectX12変換レイヤーが必須となる 10
演算APIスタック
Level Zero, OpenCL
Level Zero, OpenCL
コンピュートタスクはWDDMを介してユーザーモードドライバを透過的に利用可能である 11

カーネル6.6アップデートとVirtual GEM (vgem) モジュール
この /dev/dri の欠落というギャップを解消し、システム上にダミーのDRMノードを生成するためのカーネルレベルのハックとして機能するのが、Virtual Graphics Execution Manager (vgem) モジュールである。vgem は本来、ソフトウェアバックエンドの仮想グラフィックスメモリマネージャとして設計されたものであるが、これをWSL2環境でロードすることにより、システム上に /dev/dri/card0 および /dev/dri/renderD128 が生成される 13。
歴史的な背景として、WSL2のLinuxカーネルバージョン5.15系までは、この vgem ドライバが CONFIG_DRM_VGEM=y としてカーネルにビルトイン（静的リンク）されていた。そのため、以前の環境ではユーザーが特別な操作を行わずとも /dev/dri が存在していた。しかしながら、WSL2カーネルのバージョン6.6系のリリースに伴い、Microsoftはこの設定を CONFIG_DRM_VGEM=m（ロード可能なカーネルモジュール）へと変更した 16。
このカーネル構成の変更は、WSLカーネルのフットプリントを削減し、モジュール化を推し進めるというアーキテクチャ上の最適化が目的であったと推測される。しかし、エンドユーザーやシステム管理者にとっては、OSをアップデートした途端に /dev/dri が消失し、これまで稼働していたハードウェア・アクセラレーションが突然機能しなくなるという深刻なリグレッションとして認識される結果となった 5。
この状況を打開するためには、システム管理者が明示的にカーネルモジュールをロードし、失われたエンドポイントを復元する必要がある。コマンドラインインターフェースから sudo modprobe vgem を実行することで、即座に /dev/dri 階層とその内部のデバイスノードが生成される 13。さらに、システムが再起動されるたびにこの揮発性の設定が失われるのを防ぐため、/etc/modules ファイルに vgem というエントリを追記し、ブートシーケンスの初期段階で自動的に仮想デバイスが確保されるよう永続化措置を講じることが、堅牢なシステム設計において強く推奨される 9。
これらの生成されたノードは、物理的なハードウェアへの直接的なコマンドパイプラインではない。あくまで、後述するMesaバックエンドやコンピュートライブラリが、Dxgkrnlへのルーティングを行うための「仮想的なエントリポイント」として機能する点に留意する必要がある。ユーザー空間のアプリケーションは、このダミーノードを本物のDRMデバイスと誤認して初期化プロセスを進行させ、最終的な演算命令はWSLのブリッジレイヤーを通じてWindows側のGPUへ到達するのである。
ホスト環境およびゲストOSの前提条件の確立
WSL2というハイブリッドな環境においてIntel Arc GPUを安全かつ高効率に稼働させるためには、WindowsホストとLinuxゲストの双方で、極めて厳密なバージョン要件とパーミッション管理を満たす必要がある。
Windowsホスト側のシステム要件
基盤となるWindowsオペレーティングシステムは、Windows 11 または Windows 10 (バージョン 21H2以降) であることが求められる。これは、WDDM (Windows Display Driver Model) バージョン 2.9以上によって導入されたGPUパラバーチャライゼーション機能に依存しているためである 8。
管理者権限のPowerShellから wsl --update を実行し、WSLカーネルおよびGUIアプリケーションをサポートするWSLgコンポーネントを最新のステートに同期させることが必須要件となる 7。
さらに、ホスト側にインストールされるIntel GPUドライバ（Intel Arc & Iris Xe Graphics Windows DCH Driver）のバージョン選定が極めて重要である。WSL2内でのハードウェア・エンコーディング（HEVC等）や高度なコンピュート機能を利用するためには、最低でもバージョン 31.0.101.4032 以上のドライバが必要であり、可能であれば最新のWHQL（Windows Hardware Quality Labs）認証済みドライバを適用すべきである 18。ここで頻発するアンチパターンとして、ユーザーが「Linux環境だから」と誤認し、WSL2のゲストOS内部にベアメタルLinux向けのカーネルモードドライバ（i915など）をインストールしようとするケースがある。WSL2のアーキテクチャにおいては、カーネルレベルのハードウェア制御は完全にWindowsホスト側のDCHドライバに委譲されるため、ゲストOS内にカーネルドライバを混在させることはシステムの不安定化を招く 1。
ゲストOSのプロキシおよびパーミッション設定
ゲストOSとしては、Ubuntu 24.04 LTS (Noble Numbat) または 22.04 LTS (Jammy Jellyfish) の採用がエンタープライズおよび開発環境において標準的である。
企業内ネットワーク等のプロキシ環境下で運用される場合、APTパッケージマネージャやコンテナエンジンが外部リポジトリへアクセスできるよう、厳格なネットワークルーティングの設定が要求される。環境変数 http_proxy および https_proxy の設定に加え、sudo 実行時にもこれらの環境変数が伝播するよう、visudo コマンドを用いて /etc/sudoers に Defaults env_keep = "http_proxy https_proxy" を明記する措置が必要となる 13。
また、先述の手順で vgem モジュールにより生成された /dev/dri/renderD128 ノードは、セキュリティ上の制約から特定のグループ（通常は render または video）に所属するユーザーのみがアクセス可能となっている。コンテナ環境のデーモンや、GPUリソースを利用するプロセスを実行するユーザーアカウントに対し、適切なアクセス権限を付与しなければならない。システム管理者は sudo gpasswd -a ${USER} render コマンドを発行し、セッションを更新することで、権限の不足による初期化エラー（"Permission denied"）を未然に防ぐことができる 11。
コンピュート（演算）ワークロードのアーキテクチャと実装
Intel Arc GPUを用いた機械学習モデルの推論（OpenVINO、TensorFlow、PyTorch等）や、科学技術計算（SYCL / DPC++）を実行するためのコンピュートスタックの構築プロセスについて詳解する。コンピュート領域におけるアーキテクチャは、後述するメディア処理領域とは異なり、DirectXのMesa変換レイヤーを介さず、Intelが提供するユーザー空間のコンピュートランタイムが直接Windowsホストと同期する設計となっている。
リポジトリ構成とディストリビューションごとの差異
コンピュート機能に必要なライブラリ群は、Ubuntuの公式リポジトリに完全に統合されているわけではないため、Intelが公式にホストするパッケージリポジトリをシステムに登録する必要がある。この手順は、使用するUbuntuのバージョンによって参照すべきURIとコンポーネントの構造が異なるため、正確なマッピングが要求される。
すべてのバージョンに共通する最初のステップとして、GPG (GNU Privacy Guard) エージェントを用いてIntelの公開鍵をダウンロードし、システムのキーリングに登録することで、パッケージの完全性と署名を検証できる状態にする 11。
Ubuntu 24.04 LTS (Noble) を対象とする場合、最新の統合リポジトリアーキテクチャが採用されている。管理者はAPTのソースリストとして https://repositories.intel.com/gpu/ubuntu noble unified を登録する 13。一方、Ubuntu 22.04 LTS (Jammy) を運用している環境では、Arc GPU向けの専用コンポーネントツリーが指定された https://repositories.intel.com/graphics/ubuntu jammy arc をリポジトリソースとして設定しなければならない 20。このディストリビューションとリポジトリのミスマッチは、依存関係の解決不能エラー（"Unmet dependencies"）を引き起こす主たる要因となる。
コンピュートスタックの導入とAPIの挙動
リポジトリのバインディングが完了した後、APTパッケージマネージャを通じてコンピュートに必要な一連のユーザー空間ドライバコンポーネントをインストールする。要求される主要なパッケージは、intel-opencl-icd（OpenCL Installable Client Driver）、intel-level-zero-gpu および level-zero（Intelの低レベル演算APIランタイム）である 11。さらに、C/C++ベースのSYCLコードをコンパイルおよび実行する環境においては、intel-basekit に含まれる DPC++ コンパイラ等の追加導入が推奨される 22。
このアーキテクチャの秀逸な点は、Linuxゲスト側にインストールされるこれらのパッケージが、カーネル空間のドライバを含まない純粋なユーザー空間ライブラリであることだ。intel-opencl-icd などのローダーは、WSL2の内部インターフェースを通じて、ホスト側Windowsに常駐するIntel Graphics CompilerやWDDMドライバスタックとシームレスに通信する。このプロセスにより、重い仮想化のオーバーヘッドをバイパスし、ベアメタル環境に肉薄する高いスループットでの行列演算やテンソル処理が可能となっている。
インストールプロセス完了後、システムがGPUを正しく認識しているかを検証するため、clinfo コマンドを用いてプラットフォーム情報をクエリする。プラットフォーム名として「Intel(R) OpenCL」が検出され、デバイス名に「Intel(R) Arc(TM) A770 Graphics」といった具体的なハードウェア型番がリストアップされていれば、コンピュートパイプラインの結合は成功していると判断できる 21。

Ubuntuバージョン
必須パッケージ群
リポジトリのURI指定
想定される用途
24.04 (Noble)
intel-opencl-icd, intel-level-zero-gpu, libze1
noble unified 13
最新のOpenVINO推論、SYCLベースの機械学習
22.04 (Jammy)
intel-opencl-icd, intel-level-zero-gpu, level-zero
jammy arc 21
レガシーなTensorFlow/PyTorchワークロード

メディア・アクセラレーションにおけるVA-APIのパラダイムとMesaバックエンド
コンピュート処理が比較的ストレートな通信経路を持つのに対し、WSL2環境におけるビデオのエンコーディングおよびデコーディング（H.264、HEVC、AV1等）の構成は、アーキテクチャの階層が深く、最もトラブルシューティングが難航する領域である。ここでは、VA-API (Video Acceleration API) を機能させるためのバックエンド変換メカニズムを解析する。
iHDドライバの構造的限界
ベアメタルLinuxシステムにおいて、Intelの現行世代のGPU（Gen8以降）を用いてVA-APIによるハードウェアエンコードを行う場合、システム管理者は通常 intel-media-va-driver-non-free パッケージをインストールする 23。このパッケージに含まれる iHD_drv_video.so ドライバは、Intel Quick Sync Video (QSV) 回路へのネイティブかつ高効率なアクセスを提供する標準的なソリューションである。
しかしながら、このベストプラクティスをそのままWSL2環境に持ち込むと、致命的なエラーが発生する。ユーザー空間のアプリケーション（例えばFFmpeg）が vainfo を通じて iHD ドライバをロードし、初期化を試みると、vaInitialize failed with error code 18 (invalid parameter) や error code -1 (unknown libva error) といったシグナルを返し、プロセスが異常終了する 6。
この挙動の根源的な理由は、iHD_drv_video.so の設計思想にある。このドライバモジュールは、カーネル空間のDRM/KMS (Direct Rendering Manager / Kernel Mode Setting) サブシステム、特にLinuxネイティブの i915 や xe カーネルドライバと直接的にメモリバッファを共有し、通信することを前提としてコンパイルされている。前述の通り、WSL2環境にはこれらのネイティブカーネルドライバが存在せず、代わりにMicrosoftの dxgkrnl がすべてのグラフィックス要求を傍受するよう設計されているため、iHD ドライバは通信先のカーネルコンポーネントを見失い、初期化シーケンスが破綻するのである 14。
D3D12バックエンドを通じたコマンド変換
この「LinuxネイティブのメディアスタックとWindowsのWDDMスタックの断絶」という問題を解決するため、MicrosoftとオープンソースのMesaコミュニティは、全く新しい変換レイヤーを開発した。それが、Mesa Galliumフレームワークに基づくD3D12 (Direct3D 12) ビデオアクセラレーションバックエンドである 10。
このアーキテクチャにおいて、VA-APIの呼び出しはネイティブなIntel QSVコマンドとして直接処理されるのではなく、一旦Mesaのフロントエンドによって傍受される。傍受されたコマンドはGallium3Dステートトラッカーを通過し、Direct3D 12 APIのコマンドセットへと動的に翻訳される。その後、翻訳されたコマンドは dxgkrnl とWDDMを経由して、Windowsホスト側のメディアエンジン（Intel Arcのハードウェアエンコーダ）へと到達する。
この高度なトランスレーション・パイプラインを有効化するためには、iHD ドライバを破棄し、代わりにMesaが提供するVA-APIバックエンドドライバを導入しなければならない。システム管理者は sudo apt-get install -y mesa-va-drivers mesa-utils vainfo を実行し、必要なライブラリ群をデプロイする 9。
ただし、Ubuntuの公式リポジトリに収録されているMesaのバージョンが古い場合（例えばMesa 22.x以前など）、最新のIntel Arcアーキテクチャのフル機能（AV1エンコードなど）や、WSL2固有のD3D12最適化コードが実装されていない可能性がある。そのため、先進的な環境では、kisak-mesa PPA (Personal Package Archive) や oibaf PPAといったサードパーティのグラフィックスリポジトリを追加し、より新しいバージョンのMesaスタックへアップグレードする運用が一般的となっている 9。
環境変数によるルーティングの強制
Mesaライブラリを導入しただけでは、システムは依然としてレガシーなIntelドライバをロードしようと試みる可能性がある。D3D12バックエンドの変換パスをシステムに強制するためには、オペレーティングシステムの環境変数を厳密に制御する必要がある。具体的には、シェルセッションの初期化ファイル（.bashrc または /etc/profile.d/ 以下のカスタムスクリプト）に、以下の定義を追記する 9。

Bash


export LIBVA_DRIVER_NAME=d3d12
export GALLIUM_DRIVER=d3d12
export LD_LIBRARY_PATH=/usr/lib/wsl/lib:$LD_LIBRARY_PATH


これらの変数は、以下の極めて重要な役割を果たす。
LIBVA_DRIVER_NAME=d3d12: VA-APIのランタイムローダー（libva）に対し、デフォルトの iHD_drv_video.so ではなく、Mesaが提供する d3d12_drv_video.so を優先してロードするよう指示を出す 10。
GALLIUM_DRIVER=d3d12: Mesaの内部ルーティングにおいて、レンダリングおよびメディア処理のターゲットパイプラインをDirect3D 12バックエンドに向ける。
LD_LIBRARY_PATH: WSL2は、Windows側からブリッジされるコアライブラリ（dxcore.so など）を /usr/lib/wsl/lib に動的にマウントする。この変数を設定することで、メディアフレームワークがこれらのクリティカルな共有ライブラリを正確に解決できるようにする 28。
これらの構成が完了した後、ターミナルから vainfo --display drm --device /dev/dri/renderD128 コマンドを実行することで、パイプラインの健全性を検証できる 29。出力結果に Driver version: Mesa Gallium driver 24.x.x for D3D12 と表示され、かつ VAProfileH264Main や VAProfileHEVCMain といったプロファイルに対して VAEntrypointEncSlice（エンコード機能）および VAEntrypointVLD（デコード機能）がアタッチされていれば、ハードウェア・アクセラレーションの論理的経路が確立した証拠となる。
マルチGPU環境におけるデバイス・アロケーション戦略
最新のコンピューティング・ハードウェアでは、システム内に複数のGPUリソースが混在する「マルチGPU」アーキテクチャが広く普及している。例えば、第12世代以降のIntel Coreプロセッサを搭載するラップトップにおいて、内蔵のIntel Iris Xe (iGPU) に加えて、強力な演算能力を持つIntel Arc A770M (dGPU) が同時に搭載されているケースや、Intel CPUとNVIDIA RTXシリーズが同居しているケースである。
このようなトポロジーにおいて、WSL2のD3D12バックエンドは、初期状態においてハードウェアへのアロケーションをシステムに委ねるため、Mesaの列挙プロセスで最初に見つかったGPU（多くの場合、低電力な統合GPU）を無作為に選択してしまう挙動を示す 31。これにより、「意図したIntel Arc GPUに重い推論タスクが割り当てられず、パフォーマンスが著しく低下する」あるいは「内蔵GPUとディスクリートGPUの間でコンテキストの競合が発生する」といった問題が頻発する 32。
MESA_D3D12_DEFAULT_ADAPTER_NAME による明示的制御
このマルチGPUのジレンマを解決し、ワークロードを特定のハードウェアへ正確にルーティングするためのメカニズムが、環境変数 MESA_D3D12_DEFAULT_ADAPTER_NAME である 33。
この変数は、D3D12のDXCoreインターフェースに対して、使用すべきグラフィックスアダプタの名前を文字列マッチングのアルゴリズムを用いて強制指定する機能を持つ 31。システム管理者は、利用したいIntel Arc GPUの名前を指定してルーティングをロックすることができる。

Bash


export MESA_D3D12_DEFAULT_ADAPTER_NAME="Intel"
# または、より厳密にArcアーキテクチャを指定する場合
export MESA_D3D12_DEFAULT_ADAPTER_NAME="Intel(R) Arc"


設定された文字列の解釈が正しくDXCoreに伝播しているかを確認するためには、mesa-utils に含まれる glxinfo コマンドを使用して、OpenGLのレンダラー情報をクエリする 33。

Bash


MESA_D3D12_DEFAULT_ADAPTER_NAME=Intel glxinfo -B | grep -oP '(?<=Device: )(.+)$'


このコマンドの実行結果が、ハードウェア・アクセラレーションの成否を如実に物語る。 正しくマッチングが行われ、WDDMドライバを通じてハードウェアリソースが確保された場合、出力は D3D12 (Intel(R) Arc(TM) Graphics) (0xffffffff) といった形で、D3D12バックエンドと実際のデバイス名が結合された文字列となる 27。
一方で、指定した文字列に誤りがある場合や、対象のGPUドライバがWDDM 2.9以上の要件を満たさずに初期化に失敗した場合、Mesaのフォールバック・メカニズムが自動的に作動する。この際、Zink（Vulkan上のOpenGL実装）の初期化エラーなどが連鎖し、最終的に純粋なCPUベースのソフトウェアレンダラーである llvmpipe (LLVM 17.0.x, 256 bits) へと後退してしまう 32。llvmpipe が表示された場合は、環境変数の綴り、Windows側のドライババージョン、およびデバイスの有効状態を根底から見直す必要がある。
リソース解放不全というアーキテクチャの副作用
マルチGPU環境の運用において観察される特筆すべき副次的問題として、GPUリソースの解放不全（いわゆる「ゾンビ・セッション」問題）がある。WSLgを介してGUIアプリケーションを起動したり、重いコンピュートタスクを実行したりした際、Windowsのタスクマネージャー上でディスクリートGPUの使用状況を監視すると、「System」という名称のプロセスがGPUのVRAMや計算ユニットを占有し続ける現象が報告されている 34。
これは、Linuxゲスト側でプロセスが終了した後でも、Hyper-VのVMBusを経由したDxgkrnlのセッション状態が維持され、ハイパーバイザが将来の再利用に備えてハードウェアコンテキストを解放しないために発生する。この挙動は、特にバッテリー駆動のラップトップ環境において、ディスクリートGPUがスリープ状態（D3/D4ステート）に移行することを妨げ、電力消費を増大させる原因となる。現在のところ、このリソースを完全にパージしハードウェアを休止させるための最も確実な手段は、コマンドプロンプトから wsl --shutdown を発行し、仮想マシンインスタンスを完全にコールドブート状態へとリセットすることである。
コンテナ化されたワークロード（Docker）へのGPUパススルー戦略
システムアーキテクトがIntel Arc GPUをWSL2上で構成する主たるモチベーションの多くは、Dockerコンテナ内で稼働するメディアストリーミングサーバー（Jellyfin, Plex, Emby）、AIベースの画像生成ツール（Stable Diffusion, ComfyUI）、あるいはリアルタイム推論を伴うNVR（Network Video Recorder）監視システム（Frigate）などを、分離された環境で高効率に実行することにある 4。
しかし、Dockerコンテナは本質的にホスト（この場合はWSL2のLinuxゲスト）のファイルシステムや環境変数から隔離されている。そのため、ベアメタルLinux上で構築した d3d12 ベースのアクセラレーション環境を、コンテナ内部へシームレスに貫通させるためには、コンテナの起動パラメータにおいて特殊なデバイスマウントとボリュームバインディングの設計が不可欠となる。
Docker構成における必須パラメータの解剖
コンテナ内部のプロセスに対して、Dxgkrnlを介したWindowsホストのGPUリソースへのアクセス権を与えるためには、docker run または docker-compose.yml において以下の要素群を正確に定義しなければならない。
デバイスノードのマウント (devices): WSL2のグラフィックス通信の根幹をなす /dev/dxg をコンテナに露出させることは絶対条件である。さらに、メディアアプリケーション（FFmpeg等）がハードウェアの存在を確認するためのダミーエンドポイントとして、vgem モジュールによって生成された /dev/dri 階層も同時にパススルーする必要がある 4。
システムライブラリのバインディング (volumes): コンテナイメージ内には、WSL2がDxgkrnlと対話するための特殊な共有ライブラリ（dxcore.so など）が含まれていない。これらはWSLインスタンスの /usr/lib/wsl 内に動的にマウントされるため、このディレクトリをコンテナ内部へ読み取り専用 (ro) のボリュームとしてバインド・マウントしなければ、コンテナ内部のMesaスタックはWindows側への通信経路を構築できない 28。
環境変数の伝播 (environment): 親環境（WSL2のシェル）で設定した LIBVA_DRIVER_NAME などの変数はコンテナ内に自動的には引き継がれないため、明示的に定義する。また、バインドしたWSLライブラリを動的リンカが発見できるよう、LD_LIBRARY_PATH に /usr/lib/wsl/lib を追加指定することが極めて重要である 28。
最適化された docker-compose.yml のリファレンス実装:

YAML


services:
  media_workload:
    image: lscr.io/linuxserver/jellyfin:latest
    environment:
      # VA-APIバックエンドをD3D12に強制
      - LIBVA_DRIVER_NAME=d3d12
      # MesaのレンダリングをD3D12にルーティング
      - GALLIUM_DRIVER=d3d12
      # 使用するGPUアダプタの明示的指定
      - MESA_D3D12_DEFAULT_ADAPTER_NAME=Intel
      # WSL2のコアライブラリ群へのパスを通す
      - LD_LIBRARY_PATH=/usr/lib/wsl/lib:$LD_LIBRARY_PATH
      # ソフトウェアフォールバックの抑止
      - LIBGL_ALWAYS_SOFTWARE=0
    devices:
      # Dxgkrnlの通信パス
      - /dev/dxg:/dev/dxg
      # アプリケーションの初期化要件を満たすダミーノード
      - /dev/dri:/dev/dri
    volumes:
      # ホスト側のWSLライブラリ群をコンテナへ供給
      - /usr/lib/wsl:/usr/lib/wsl:ro


この構成のもとでコンテナが起動すると、内部で稼働するアプリケーションは /dev/dri の存在を検知してハードウェアモードでの初期化フローに突入する。その後、内部環境変数 LIBVA_DRIVER_NAME=d3d12 の指示に従い、コンテナ内にインストールされた（あるいはMesaから提供される）D3D12バックエンドを選択する。最終的に、ライブラリパス /usr/lib/wsl/lib を参照して dxcore コンポーネントを経由し、マウントされた /dev/dxg デバイスノードに対してコマンドを発行することで、ホスト側のIntel Arcハードウェアへアクセスを完遂するという壮大な連鎖が実現する。
実証実験とワークロードの検証手法
アーキテクチャの構成が完了した後は、実際の演算およびメディア処理ワークロードを投入し、ハードウェア・アクセラレーションが期待通りに機能しているかを定量的に検証するプロセスが必要である。
VA-APIを通じたトランスコーディングの実証
メディア処理のデファクトスタンダードであるFFmpegを用いて、VA-APIによるハードウェアエンコーディングの検証を行う。以下のコマンドは、入力ビデオをH.264形式へハードウェアを用いてトランスコードするリファレンスコマンドである 10。

Bash


ffmpeg -hwaccel vaapi \
       -hwaccel_output_format vaapi \
       -hwaccel_device /dev/dri/card0 \
       -i input.mp4 \
       -c:v h264_vaapi \
       output_hw.mp4


このコマンドを発行した際、システムアーキテクトは以下の2点を注視して検証を行う必要がある。 第一に、コンソール出力において vaInitialize に関するセグメンテーションフォルトやエラーメッセージ（例：Failed to open the given device）が表示されず、エンコードのフレームレートがCPU処理（ソフトウェアエンコード）と比較して劇的に向上していることである。 第二に、Windowsホスト側のタスクマネージャを開き、「パフォーマンス」タブにおけるIntel Arc GPUのステータスを確認する。トランスコード処理の進行中、「Video Decode」および「Video Encode」エンジンの使用率グラフが明確に上昇（スパイク）していれば、WSL2からWDDMを介したハードウェアへのアクセスが完璧に疎通していることの確定的な証明となる 18。
既知の制約と高度なトラブルシューティング
WSL2とMesa D3D12アーキテクチャを組み合わせたIntel Arc GPUのパススルー構成は、オペレーティングシステムのカーネル、仮想化レイヤー、そしてグラフィックスAPIという3つの複雑なスタックが交差する領域であるため、特有の障害が発生しやすい。以下に、現場で遭遇する可能性の高いクリティカルな事象とその背後にあるメカニズム、および解決策を整理する。
1. vaInitialize呼び出し時のセグメンテーションフォルト (SIGSEGV)
事象: vainfo を実行した際、あるいはFFmpegやFrigateなどのコンテナがビデオ処理を開始しようとした瞬間に、プロセスがSIGSEGVで強制終了する 5。 深層メカニズム: この現象は、WSLgが提供するWayland/X11のディスプレイ・バックエンドと、ロードされたMesaドライバのバージョンの不整合、またはD3D12バックエンドによるホストメモリ空間のバッファマッピング（DRI3インターフェースの初期化）の失敗に起因する。特に新しいLinuxカーネルや更新されたMesaスタックにおいて、メモリ管理のプロトコルが衝突した際に発生する。 解決へのアプローチ: 最も効果的な回避策は、環境変数 LIBVA_DRI3_DISABLE=1 を設定し、VA-APIに対してDirect Rendering Infrastructure 3 (DRI3) プロトコルの使用を強制的に無効化することである 26。これにより、複雑なバッファ共有メカニズムをバイパスし、安定した通信経路を確保できるケースが多い。また、sudo modprobe vgem によって確実に対応するノードが生成されており、かつ実行ユーザーが render グループに所属していること（権限不足によるフォールバッククラッシュの防止）を再確認する。
2. デバイスオープン失敗 ("Failed to open the given device" / "No VA display found")
事象: アプリケーションが「指定されたデバイス（/dev/dri/renderD128）を開けない」、あるいは「VAディスプレイが見つからない」と報告し、初期化を中止する 23。 深層メカニズム: 対象のデバイスノード自体のパーミッションは正常であるにもかかわらずこのエラーが出る場合、システムのライブラリローダーが誤ったドライバ（ネイティブ環境用の iHD_drv_video.so）をロードしようと試み、WSL2環境下での通信要件を満たせずにフェイルしている可能性が極めて高い。 解決へのアプローチ: システムレベル、ユーザープロファイルレベル、およびコンテナの起動パラメータのすべての層において、LIBVA_DRIVER_NAME=d3d12 が確実にエクスポートされているかを監査する。Docker環境においては、ホスト側（WSLのシェル）で環境変数を設定しても、それがコンテナ内部に透過的に伝播することはないため、docker-compose.yml 内で明示的に定義するプロセスを怠ってはならない 6。
3. コンピュートタスクにおけるデバイス認識の欠落
事象: メディア処理（VA-API）は機能するものの、sycl-ls コマンドやOpenVINOの推論デバイスリストを出力した際、[CPU] のみが表示され、Intel Arc GPUがリストアップされない 28。 深層メカニズム: 仮想化環境におけるメディア処理パイプライン（Mesaベース）と、コンピュート処理パイプライン（Level Zero / OpenCLベース）は完全に独立したスタックとして実装されているためである。メディア関連のパッケージ (mesa-va-drivers) を導入しただけでは、コンピュートタスクはGPUを認識できない。 解決へのアプローチ: コンピュートスタックの基盤となる intel-opencl-icd、intel-level-zero-gpu、および level-zero パッケージ群が正しくインストールされているかを検証する 13。また、Windows側のホストドライバが古い場合、Level ZeroのWDDM要件を満たさずに初期化に失敗するケースがある。ホスト側のドライバを最新のWHQL版へアップデートすることが急務となる 11。

現象・エラーメッセージ
推定されるアーキテクチャ上の原因
推奨されるアクションと解決策
ls /dev/dri が「No such file」を返す
カーネル6.6のアップデートによる vgem のモジュール化
コマンド sudo modprobe vgem の実行および /etc/modules への追記 16
vainfo 実行時のエラー（コード18 または -1）
ネイティブの iHD ドライバが dxgkrnl との通信に失敗
環境変数 export LIBVA_DRIVER_NAME=d3d12 を設定しバックエンドを切り替える 10
OpenGL レンダラが llvmpipe と表示される
アダプタの文字列指定ミス、または該当GPUの要件未達
MESA_D3D12_DEFAULT_ADAPTER_NAME="Intel(R) Arc" のように正確な文字列を指定する 32
Dockerコンテナ内でハードウェアが見えない
/dev/dxg などのパススルー欠落、WSLライブラリのパス不達
devices に /dev/dxg を追加し、LD_LIBRARY_PATH=/usr/lib/wsl/lib を定義する 28

総括と将来展望
WSL2環境におけるIntel Arc GPUのパススルー、およびアプリケーションが依存する /dev/dri エンドポイントの構築プロセスは、従来のベアメタルLinuxアーキテクチャにおけるGPU制御とは全く次元の異なるアプローチを要求する。SR-IOVのようなハードウェアレベルでの分割・パススルー機能を持たないディスクリートGPUを、WindowsのWDDMとHyper-VベースのDxgkrnlという厚い抽象化レイヤーを介してゲストOSに提供するというMicrosoftの設計思想は、ホストの安定性を損なうことなく高度な演算リソースを仮想環境へ注入できる、極めて野心的かつ汎用性の高いアプローチである。
しかしながら、その複雑な抽象化の代償として、長年にわたり進化を遂げてきたレガシーなLinuxのメディア・コンピュートフレームワークとの互換性を維持するための「ブリッジ」が不可欠となった。カーネル6.6以降での vgem モジュールの手動ロードによる仮想デバイスノードの生成、Mesa D3D12バックエンドによるAPI呼び出しの動的変換、そして MESA_D3D12_DEFAULT_ADAPTER_NAME によるマルチGPU環境での精密なルーティング制御など、幾重にも連なるソフトウェアコンポーネントが完璧に噛み合うことで、初めて高度なハードウェア・アクセラレーションが成立する。
本報告書の分析を通じて得られた最も重要な指針は、システム構築において「ホスト（Windows）とゲスト（Linux）の責任分界点」を厳格に認識することである。ハードウェアの直接的なドライバ制御は完全にホスト側のWindowsドライバ（DCH）に委ね、ゲストOS側はMesaによるAPI変換レイヤーや、Level ZeroのICDローダーを通じた「ホストへの通信層」の整備に徹するというアプローチが、唯一の最適解である。ゲスト側にネイティブカーネルドライバを混在させようとする試みは、システムを破綻させるだけである。
将来的に、WSLカーネルのさらなるアップデートやMesaコミュニティの持続的な開発努力により、これらの設定プロセスの自動化や、vgem の介入を必要としないより洗練されたDRMエミュレーションの実装が提供される可能性は高い。しかし現時点のアーキテクチャにおいては、本報告書で詳解した環境変数の制御、カーネルモジュールのロード管理、およびパッケージ・リポジトリの適正な構成こそが、WSL2という仮想化の壁を越えてIntel Arc GPUの潜在能力を最大限に引き出すための、最も確実なエンジニアリング手法である。

引用文献
CUDA on WSL User Guide - NVIDIA Documentation, 4月 6, 2026にアクセス、 https://docs.nvidia.com/cuda/wsl-user-guide/index.html
Solved: Arc a770 & WSL2 - Intel Community, 4月 6, 2026にアクセス、 https://community.intel.com/t5/Intel-Arc-Discrete-Graphics/Arc-a770-amp-WSL2/m-p/1453439
Intel® Arc™ Graphics Are Not Detected under WSL2, 4月 6, 2026にアクセス、 https://www.intel.com/content/www/us/en/support/articles/000094038/graphics.html
Cannot get /dev/dri to appear in WSL 2 for Intel Iris Xe (12th Gen i5), 4月 6, 2026にアクセス、 https://community.intel.com/t5/Graphics/Cannot-get-dev-dri-to-appear-in-WSL-2-for-Intel-Iris-Xe-12th-Gen/td-p/1724203
I failed to have Intel GPU to do the video encoding in Docker Windows. : r/immich - Reddit, 4月 6, 2026にアクセス、 https://www.reddit.com/r/immich/comments/1l5k14s/i_failed_to_have_intel_gpu_to_do_the_video/
No HW Accel Support under windows->wsl2 · blakeblackshear frigate · Discussion #11133 - GitHub, 4月 6, 2026にアクセス、 https://github.com/blakeblackshear/frigate/discussions/11133
Can't get Intel QSV to work in WSL 2 (no /dev/dri). Lagging Jellyfin is killing me. - Reddit, 4月 6, 2026にアクセス、 https://www.reddit.com/r/WindowsHelp/comments/1ok2puq/cant_get_intel_qsv_to_work_in_wsl_2_no_devdri/
How to turn on gpu acceleration in wsl? - Super User, 4月 6, 2026にアクセス、 https://superuser.com/questions/1754504/how-to-turn-on-gpu-acceleration-in-wsl
2.5.1 breaks /dev/dri detection - Hardware acceleration is dead · Issue #12702 · microsoft/WSL - GitHub, 4月 6, 2026にアクセス、 https://github.com/microsoft/WSL/issues/12702
D3D12 GPU Video acceleration in the Windows Subsystem for Linux now available!, 4月 6, 2026にアクセス、 https://devblogs.microsoft.com/commandline/d3d12-gpu-video-acceleration-in-the-windows-subsystem-for-linux-now-available/
Configure WSL 2 for GPU Workflows - Intel, 4月 6, 2026にアクセス、 https://www.intel.com/content/www/us/en/docs/oneapi/installation-guide-linux/2023-0/configure-wsl-2-for-gpu-workflows.html
Configure WSL 2 for GPU Workflows - Intel, 4月 6, 2026にアクセス、 https://www.intel.com/content/www/us/en/docs/oneapi/installation-guide-linux/2025-0/configure-wsl-2-for-gpu-workflows.html
Install Guide Ubuntu 24.04 on WSL2 - Open Edge Platform, 4月 6, 2026にアクセス、 https://docs.openedgeplatform.intel.com/dev/edge-ai-libraries/dlstreamer/get_started/install/install_guide_ubuntu_wsl2.html
[Bug]: VAAPI in Container with WSL2 Windows not working · Issue #1809 · intel/media-driver, 4月 6, 2026にアクセス、 https://github.com/intel/media-driver/issues/1809
No /dev/dri device on my host system with intel CPU - Proxmox Support Forum, 4月 6, 2026にアクセス、 https://forum.proxmox.com/threads/no-dev-dri-device-on-my-host-system-with-intel-cpu.99775/
Building new WSL2 Linux Kernel 6.6 disables /dev/dri (and VA-API) · Issue #11837 · microsoft/WSL - GitHub, 4月 6, 2026にアクセス、 https://github.com/microsoft/WSL/issues/11837
GPU accelerated ML training in WSL | Microsoft Learn, 4月 6, 2026にアクセス、 https://learn.microsoft.com/en-us/windows/wsl/tutorials/gpu-compute
[Unsolved] running WSL2 video acceleration on Intel 10th gen CPU (Ice lake), 4月 6, 2026にアクセス、 https://learn.microsoft.com/en-us/answers/questions/3906384/(unsolved)-running-wsl2-video-acceleration-on-inte
How to Install Intel ARC A380 Drivers on Ubuntu 24.04, 4月 6, 2026にアクセス、 https://askubuntu.com/questions/1543079/how-to-install-intel-arc-a380-drivers-on-ubuntu-24-04
Configure WSL 2 for GPU Workflows - Intel, 4月 6, 2026にアクセス、 https://www.intel.com/content/www/us/en/docs/oneapi/installation-guide-linux/2025-1/configure-wsl-2-for-gpu.html
Configure WSL 2 for GPU Workflows - Intel, 4月 6, 2026にアクセス、 https://www.intel.com/content/www/us/en/docs/oneapi/installation-guide-linux/2025-2/configure-wsl-2-for-gpu.html
Windows GPU Setup Guide | Kamiwaza Docs, 4月 6, 2026にアクセス、 https://docs.kamiwaza.ai/installation/gpu_setup_guide
iHD_drv_video.so init failed on host (HW transcoding implementation help) : r/Ubuntu - Reddit, 4月 6, 2026にアクセス、 https://www.reddit.com/r/Ubuntu/comments/1n3xe4h/ihd_drv_videoso_init_failed_on_host_hw/
Package "intel-media-va-driver-non-free" (noble 24.04) - UbuntuUpdates, 4月 6, 2026にアクセス、 https://www.ubuntuupdates.org/package/core/noble/multiverse/base/intel-media-va-driver-non-free
Linux noob: Intel iGPU HWA: intel-non-free vs mesa : r/frigate_nvr - Reddit, 4月 6, 2026にアクセス、 https://www.reddit.com/r/frigate_nvr/comments/1mu4085/linux_noob_intel_igpu_hwa_intelnonfree_vs_mesa/
VA-API's Libva 2.18 Released With Windows WSL D3D12 Support, Optional Disabling DRI3, 4月 6, 2026にアクセス、 https://www.phoronix.com/news/VA-API-libva-2.18
Re: Intel integrated arc igpu in Core Ultra 7 not working properly with WLS2, 4月 6, 2026にアクセス、 https://community.intel.com/t5/Graphics/Intel-integrated-arc-igpu-in-Core-Ultra-7-not-working-properly/m-p/1578303
Using Arc GPUs w/ WSL2 - Reddit, 4月 6, 2026にアクセス、 https://www.reddit.com/r/wsl2/comments/1o3mflh/using_arc_gpus_w_wsl2/
VA-API does not work in Ubuntu 24.04 · Issue #11838 · microsoft/WSL - GitHub, 4月 6, 2026にアクセス、 https://github.com/microsoft/WSL/issues/11838
h264 Intel hardware acceleration · Issue #9523 · microsoft/WSL - GitHub, 4月 6, 2026にアクセス、 https://github.com/microsoft/WSL/issues/9523
GPU selection in WSLg - GitHub, 4月 6, 2026にアクセス、 https://github.com/microsoft/wslg/wiki/GPU-selection-in-WSLg
Switching MESA_D3D12_DEFAULT_ADAPTER_NAME to NVIDIA defaults to llvmpipe rendering · Issue #12412 · microsoft/WSL - GitHub, 4月 6, 2026にアクセス、 https://github.com/microsoft/WSL/issues/12412
Intel graphics acceleration architecturally broken for non-Ubuntu systems · Issue #996 · microsoft/wslg - GitHub, 4月 6, 2026にアクセス、 https://github.com/microsoft/wslg/issues/996
WSLG doesn't release unused GPUs and doesnt autoshutdown #492 - GitHub, 4月 6, 2026にアクセス、 https://github.com/microsoft/wslg/discussions/492
Intel integrated arc igpu in Core Ultra 7 not working properly with WLS2, 4月 6, 2026にアクセス、 https://community.intel.com/t5/Graphics/Intel-integrated-arc-igpu-in-Core-Ultra-7-not-working-properly/m-p/1578596
[Issue]: WSL2/Intel Arc OpenCL Error -6 but lots of VRAM available #1474 - GitHub, 4月 6, 2026にアクセス、 https://github.com/vladmandic/sdnext/issues/1474
FFMPEG Hardware acceleration : r/bashonubuntuonwindows - Reddit, 4月 6, 2026にアクセス、 https://www.reddit.com/r/bashonubuntuonwindows/comments/10h6gzj/ffmpeg_hardware_acceleration/
[WSL2 6.6.87.2] VA-API initialization segfaults in `vaInitialize` with AMD 680M (Radeon 24.9.1 driver) · Issue #13946 · microsoft/WSL - GitHub, 4月 6, 2026にアクセス、 https://github.com/microsoft/WSL/issues/13946
