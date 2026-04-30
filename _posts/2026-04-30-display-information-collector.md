---
title: Windowsのディスプレイ情報をまとめて取得する単体C#ファイルを作った話
date: 2026-04-30 00:00:00 +0900
categories: [Windows, Tools]
tags: [Windows, CSharp, DotNet, WMI, EDID, DisplayConfig, MultiMonitor]
pin: false
---

# Windowsのディスプレイ情報をまとめて取得する単体C#ファイルを作った話

マルチディスプレイ環境を扱っていると、単に「画面が何枚あるか」だけでは足りません。

実際には、次のような情報をまとめて見たくなります。

- Windows が付けている `DISPLAY1` / `DISPLAY2` などの番号
- モニター名
- 画面の位置と解像度
- HDMI / DisplayPort / eDP などの接続方式
- どの GPU 側の出力か
- NVIDIA 系アダプタかどうか
- EDID や WMI シリアル番号
- 同じ型番のモニターが複数ある場合の区別材料

そこで、Windows のディスプレイ情報を取得するための単体 C# ファイルとして、
`DisplayInformationCollector.cs` を用意しました。

この記事では、このファイルで何が取れるのか、どう使うのか、そして Windows の表示番号と EDID をどう結び付けているのかを整理します。

---

## これは何か

`DisplayInformationCollector.cs` は、Windows のマルチディスプレイ情報を取得するための **単体 C# ファイル** です。

主な目的は、現在接続されているディスプレイについて、次の情報をまとめて取得することです。

- Windows 表示番号
- Windows API が返す source 名
- モニターの表示名
- 画面位置
- 解像度
- メインディスプレイかどうか
- 接続方式
- GPU / アダプタ情報
- MonitorDevicePath
- EDID manufacturer ID / product code ID
- WMI から取得したモニター名、メーカー名、シリアル番号
- 生 EDID
- EDID の SHA-256 ハッシュ
- 同一 EDID モニターの序列
- 識別用の `DisplayKey`

画面配置の変更や復元は行いません。
あくまで **情報取得専用** のファイルです。

---

## 配布ファイル

配布単位は次の 1 ファイルです。

```text
DisplayInformationCollector.cs
```

主な公開クラスは次の通りです。

```csharp
DisplayInformationCollector
DisplayInformationSnapshot
DisplayInformationItem
```

`DisplayInformationCollector.cs` には namespace を付けていません。
そのため、別プロジェクトにそのまま追加して使えます。

自分のプロジェクトで namespace を統一したい場合は、必要に応じて後から包んでください。

---

## 動作環境

前提は Windows です。

推奨環境は次の通りです。

- Windows 専用
- `.NET 8.0-windows` 推奨
- NuGet パッケージ `System.Management` が必要

`System.Management` は、C# から Windows の WMI 情報を読むために使います。
このファイルでは、WMI から次のような情報を取るために使用しています。

- 生 EDID
- モニター名
- メーカー名
- 製品コード
- シリアル番号

`.csproj` には次の参照を追加します。

```xml
<ItemGroup>
  <PackageReference Include="System.Management" Version="8.0.0" />
</ItemGroup>
```

Visual Studio を使っている場合は、NuGet パッケージ管理から `System.Management` を追加しても同じです。

---

## 基本的な使い方

通常は `DisplayInformationCollector.Capture()` だけを呼びます。

```csharp
DisplayInformationSnapshot snapshot = DisplayInformationCollector.Capture();

DisplayInformationItem[] allDisplays = snapshot.Displays.ToArray();
```

`snapshot.Displays` に、取得した各ディスプレイの情報が入ります。

アクティブなディスプレイだけを取得する場合は、引数なしで十分です。
非アクティブな display path も含めたい場合は、`activeOnly: false` を指定します。

```csharp
DisplayInformationSnapshot activeOnly = DisplayInformationCollector.Capture();
DisplayInformationSnapshot allPaths = DisplayInformationCollector.Capture(activeOnly: false);
```

---

## 取得した情報を配列に分ける例

取得結果は `DisplayInformationItem` のリストとして返ります。
用途に応じて、次のように配列へ分けると扱いやすくなります。

```csharp
DisplayInformationSnapshot snapshot = DisplayInformationCollector.Capture();

DisplayInformationItem[] allDisplays = snapshot.Displays.ToArray();

int totalDisplayCount = snapshot.DisplayCount;
int activeDisplayCount = snapshot.ActiveDisplayCount;
int nvidiaDisplayCount = snapshot.NvidiaDisplayCount;
int nonNvidiaDisplayCount = snapshot.NonNvidiaDisplayCount;

int?[] windowsDisplayNumbers = allDisplays
    .Select(display => display.WindowsDisplayNumber)
    .ToArray();

string[] windowsSourceNames = allDisplays
    .Select(display => display.SourceName)
    .ToArray();

string[] monitorNames = allDisplays
    .Select(display => display.MonitorFriendlyName)
    .ToArray();

(int X, int Y, int Width, int Height)[] displayBounds = allDisplays
    .Select(display => (display.PositionX, display.PositionY, display.Width, display.Height))
    .ToArray();

string[] outputTechnologies = allDisplays
    .Select(display => display.OutputTechnology)
    .ToArray();

bool[] nvidiaFlags = allDisplays
    .Select(display => display.IsNvidia)
    .ToArray();

string[] edidHashes = allDisplays
    .Select(display => display.EdidHashSha256)
    .ToArray();

string[] displayKeys = allDisplays
    .Select(display => display.DisplayKey)
    .ToArray();
```

---

## 代表的なプロパティ

よく使う項目は次の通りです。

| プロパティ | 内容 |
|---|---|
| `WindowsDisplayNumber` | Windows が付けている DISPLAY 番号です。`DISPLAY1` なら `1` です。 |
| `SourceName` | Windows API が返す画面名です。例: `\\.\DISPLAY1`。 |
| `MonitorFriendlyName` | モニターの表示名です。取れない環境では空文字になることがあります。 |
| `PositionX` / `PositionY` | 仮想デスクトップ上での左上座標です。 |
| `Width` / `Height` | 解像度です。 |
| `IsPrimary` | メインディスプレイなら `true` です。 |
| `OutputTechnology` | HDMI、DisplayPort、eDP、DVI などの接続方式です。 |
| `ConnectorInstance` | 同じ種類の端子が複数ある場合の区別番号です。 |
| `IsNvidia` | NVIDIA 系アダプタと判定された場合に `true` です。 |
| `AdapterDevicePath` | GPU アダプタのデバイスパスです。 |
| `MonitorDevicePath` | モニターのデバイスパスです。WMI 情報との照合に使います。 |
| `EdidManufactureId` | DisplayConfig API から取得した EDID manufacturer ID です。 |
| `EdidProductCodeId` | DisplayConfig API から取得した EDID product code ID です。 |
| `RawEdid` | WMI から取得した生 EDID の byte 配列です。 |
| `RawEdidHex` | 生 EDID を 16 進文字列にしたものです。 |
| `EdidHashSha256` | 生 EDID から作った SHA-256 ハッシュです。 |
| `WmiSerialNumber` | WMI から取得したモニターシリアル番号です。 |
| `DuplicateOrdinal` | 同じ EDID を持つモニター同士を区別するための序列番号です。 |
| `DisplayKey` | 識別用キーです。WMI シリアル、EDID、接続パスなどから作ります。 |

ここで重要なのは、`WindowsDisplayNumber` を **安定した個体識別子として扱わない** ことです。

Windows の `DISPLAY1` や `DISPLAY2` は、人間に見せる番号としては便利です。
しかし、再起動、接続変更、GPU構成変更などで変わることがあります。

物理モニターを識別したい場合は、EDID、WMI シリアル、接続パス、端子情報などを組み合わせて見る必要があります。

---

## 戻り値の構造

`Capture()` は `DisplayInformationSnapshot` を返します。

```csharp
DisplayInformationSnapshot snapshot = DisplayInformationCollector.Capture();
```

`DisplayInformationSnapshot` には、全体の概要とディスプレイ一覧が入ります。

| プロパティ | 内容 |
|---|---|
| `CapturedAt` | 取得日時 |
| `DisplayCount` | 取得できたディスプレイ数 |
| `ActiveDisplayCount` | アクティブなディスプレイ数 |
| `NvidiaDisplayCount` | NVIDIA と判定されたディスプレイ数 |
| `NonNvidiaDisplayCount` | NVIDIA 以外と判定されたディスプレイ数 |
| `VirtualBoundsX` / `VirtualBoundsY` | 仮想デスクトップ全体の左上位置 |
| `VirtualBoundsWidth` / `VirtualBoundsHeight` | 仮想デスクトップ全体のサイズ |
| `Displays` | 各ディスプレイの詳細リスト |

複数 GPU 構成や NVIDIA / 非 NVIDIA 混在構成では、`NvidiaDisplayCount` と `NonNvidiaDisplayCount` を見ることで、取得結果の大まかな分類を確認できます。

---

## Windows 表示番号と EDID をどう結び付けるか

このファイルで特に重要なのは、Windows の `DISPLAY1` と EDID を **直接比較しているわけではない** という点です。

Windows の `QueryDisplayConfig` が返す display path には、source 側と target 側の情報が一緒に入っています。

```text
source 側: \\.\DISPLAY1 のような Windows 表示名
target 側: モニター名、接続方式、端子情報、EDID ID、monitor device path
```

つまり、同じ display path から source 情報と target 情報を取り出すことで、

```text
この Windows 表示番号の画面は、このモニター情報に対応する
```

と判断しています。

さらに、`MonitorDevicePath` を正規化し、WMI の `InstanceName` と照合します。
照合できた場合は、生 EDID や `EdidHashSha256` を同じ `DisplayInformationItem` に入れます。

使う側では、次のように Windows 番号と EDID 系情報の対応を確認できます。

```csharp
var windowsNumberAndEdidPairs = snapshot.Displays
    .Select(display => new
    {
        WindowsNumber = display.WindowsDisplayNumber,
        WindowsSourceName = display.SourceName,
        MonitorName = display.MonitorFriendlyName,
        MonitorDevicePath = display.MonitorDevicePath,
        EdidManufacturerId = display.EdidManufactureId,
        EdidProductCodeId = display.EdidProductCodeId,
        EdidHash = display.EdidHashSha256,
        WmiSerialNumber = display.WmiSerialNumber,
        DisplayKey = display.DisplayKey
    })
    .ToArray();
```

この考え方にしておくと、Windows の表示番号だけに依存せず、より現実のモニター構成に近い情報を扱えます。

---

## 同じ EDID のモニターが複数ある場合

同じ型番のモニターを複数台接続していると、生 EDID や EDID ハッシュが同じになることがあります。

この場合、EDID だけでは「どちらの画面か」を区別できません。

そこで `DisplayInformationCollector.cs` では、同じ EDID 情報を持つ画面をグループ化し、グループ内で `DuplicateOrdinal` を付けています。

序列は次の優先順で決めます。

1. `AdapterLuidHighPart`
2. `AdapterLuidLowPart`
3. `ConnectorInstance`
4. `PositionY`
5. `PositionX`
6. `TargetId`
7. `SourceName`

確認用のコード例は次の通りです。

```csharp
var sameEdidOrder = snapshot.Displays
    .Where(display => !string.IsNullOrWhiteSpace(display.EdidHashSha256))
    .GroupBy(display => display.EdidHashSha256)
    .Select(group => group
        .OrderBy(display => display.AdapterLuidHighPart)
        .ThenBy(display => display.AdapterLuidLowPart)
        .ThenBy(display => display.ConnectorInstance)
        .ThenBy(display => display.PositionY)
        .ThenBy(display => display.PositionX)
        .ThenBy(display => display.TargetId)
        .ThenBy(display => display.SourceName)
        .Select(display => new
        {
            display.SourceName,
            display.MonitorFriendlyName,
            display.ConnectorInstance,
            display.PositionX,
            display.PositionY,
            display.TargetId,
            display.DuplicateOrdinal
        })
        .ToArray())
    .ToArray();
```

ただし、これは物理ポートの刻印を完全に読む仕組みではありません。

`ConnectorInstance == 1` が、GPU 本体に印字されている「DisplayPort 1」と必ず一致するとは限りません。
GPU ドライバや接続構成が変わると、`ConnectorInstance` や `TargetId` が変わる場合もあります。

実運用では、初回だけ実機のポート配置と照らし合わせて、対応表を作っておくのが確実です。

---

## 接続方式とポート情報を見る

DisplayPort、HDMI、eDP などの接続方式は `OutputTechnology` に入ります。

たとえば DisplayPort 接続の画面だけを見たい場合は、次のようにできます。

```csharp
var displayPortDisplays = snapshot.Displays
    .Where(display => display.OutputTechnology == "DisplayPort")
    .Select(display => new
    {
        display.SourceName,
        display.MonitorFriendlyName,
        display.ConnectorInstance,
        display.TargetId,
        display.AdapterLuidHighPart,
        display.AdapterLuidLowPart,
        display.MonitorDevicePath
    })
    .ToArray();
```

ここでも、`ConnectorInstance` は Windows / ドライバが返す端子識別情報として扱います。
物理ポートの刻印と完全一致する前提にはしないほうが安全です。

---

## 内部で使っている主な Windows API

内部では、DisplayConfig API、DEVMODE、WMI を組み合わせています。

| API / 機能 | 役割 |
|---|---|
| `GetDisplayConfigBufferSizes` | DisplayConfig 情報を取得するために必要な配列サイズを調べます。 |
| `QueryDisplayConfig` | 現在の display path と表示モードを取得します。 |
| `DisplayConfigGetDeviceInfo` | モニター名、デバイスパス、EDID ID、接続方式などを取得します。 |
| `EnumDisplaySettingsEx` | 現在の解像度、位置、リフレッシュレートなどを取得します。 |
| `EnumDisplayDevices` | アダプタ名やレジストリキーを取得します。 |
| WMI `WmiMonitorID` | メーカー名、製品コード、シリアル番号、表示名、製造年を取得します。 |
| WMI `WmiMonitorRawEEdidV1Block` | 生 EDID ブロックを取得します。 |

1つの API だけでは必要な情報が揃わないため、複数の情報源を突き合わせています。

---

## 公開関数

### `DisplayInformationCollector.Capture`

```csharp
public static DisplayInformationSnapshot Capture(bool activeOnly = true)
```

ディスプレイ情報取得の入口です。
通常はこの関数だけを使います。

`activeOnly` を `true` にすると、現在アクティブなディスプレイだけを取得します。
非アクティブな path も含めたい場合は `false` を指定します。

```csharp
DisplayInformationSnapshot activeOnly = DisplayInformationCollector.Capture();
DisplayInformationSnapshot allPaths = DisplayInformationCollector.Capture(activeOnly: false);
```

### `DisplayInformationCollector.NormalizeMonitorKey`

```csharp
public static string NormalizeMonitorKey(string? input)
```

DisplayConfig の `MonitorDevicePath` と WMI の `InstanceName` を照合しやすい形に整える関数です。

```csharp
string[] normalizedMonitorKeys = snapshot.Displays
    .Select(display => DisplayInformationCollector.NormalizeMonitorKey(display.MonitorDevicePath))
    .ToArray();
```

通常の利用では、`Capture()` の内部で自動的に使われます。

---

## 使うときの注意点

注意点は次の通りです。

- Windows 専用です。
- `System.Management` 参照が必要です。
- `DISPLAY1` などの Windows 番号は安定識別子ではありません。
- EDID は同一型番の複数モニターで同じになる場合があります。
- 生 EDID が取れない環境でも、DisplayConfig や DEVMODE の情報は可能な範囲で返します。
- 画面配置の変更、復元、ロールバックは行いません。

つまり、このファイルは「取得」に責務を絞っています。
画面配置を変更するツールではなく、現在の構成を正しく観察するための部品です。

---

## 何に使えるか

主な用途は次の通りです。

- 接続中ディスプレイ一覧の取得
- モニター名、解像度、位置の取得
- HDMI / DisplayPort などの接続方式確認
- NVIDIA / 非 NVIDIA の分類
- EDID ハッシュや WMI シリアルによるモニター識別補助
- 同一 EDID モニターの序列付け
- マルチディスプレイ管理ツールの調査用ログ出力
- 画面構成トラブルの切り分け

特に、複数 GPU、NVIDIA / 非 NVIDIA 混在、同一型番モニター多数、DP / HDMI 変換アダプタ混在のような環境では、情報を一覧化できるだけでも原因切り分けがしやすくなります。

---

## まとめ

`DisplayInformationCollector.cs` は、Windows のマルチディスプレイ情報をまとめて取得するための単体 C# ファイルです。

ポイントは次の3つです。

1. Windows の `DISPLAY1` などの番号だけを信用しない
2. DisplayConfig、WMI、EDID、DEVMODE を組み合わせて見る
3. 同一 EDID モニターでは `DuplicateOrdinal` を併用する

Windows の表示番号は、人間に見せるラベルとしては便利です。
しかし、物理モニターの識別には弱いです。

そのため、実際のディスプレイ識別では、EDID、WMI シリアル、monitor device path、adapter / target / connector 情報を組み合わせて見るのが安全です。

このファイルは、そのための情報をまとめて取得するための土台として使えます。

---

## 関連記事

- [非NVIDIA出力1枚 + NVIDIA出力8枚を、使いやすく整列するソフトを作った話]({% post_url 2026-04-23-display-alignment-tool %})
