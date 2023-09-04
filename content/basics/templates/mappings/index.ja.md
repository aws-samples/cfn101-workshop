---
title: "マッピング"
weight: 600
---

### 概要

このラボでは、**[マッピング](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/mappings-section-structure.html)** を紹介します。_マッピング_セクションは、CloudFormation テンプレートのトップレベルセクションで、テンプレートで参照できるキーと値のマップを定義します。

![マッピングセクションの構造図](/static/basics/templates/mappings/mapping.png)

マッピングセクションの簡単な例を以下に紹介します。`AnExampleMapping` という 1 つのマップが含まれています。\
`AnExampleMapping` には、`TopLevelKey01`、`TopLevelKey02` と `TopLevelKey03` という 3 つのトップレベルキーが含まれています。\
各トップレベルキーには、1 つ以上の `Key: Value` ペアが含まれています。

:::code{language=yaml showLineNumbers=false showCopyAction=false}
Mappings:
  AnExampleMap:
    TopLevelKey01:
      Key01: Value01
      Key02: Value02

    TopLevelKey02:
      AnotherKey: AnExampleValue

    TopLevelKey03:
      AFinalKey: ADifferentValue
:::

### カバーされるトピック
このラボでは、次のタスクを行います。

+ _Test_ や _Prod_ などの環境タイプのマッピングを作成します。各環境タイプは異なるインスタンスタイプにマップされます。
+ マッピングで必要な値を見つけ、EC2 リソースのプロパティセクションから参照します。

### ラボの開始

はじめに、自分のテンプレートに `Mappings` セクションを追加します。

:::alert{type="info"}
このラボのテンプレートは `code/workspace` にあります\
編集前のテンプレートは `/workspace/mappings.yaml` です\
最終的なテンプレートは `/solutions/mappings.yaml` です
:::

#### 1. _環境タイプ_ パラメータの追加から始めましょう

このセクションでは、`Test` と `Prod` の 2 つの環境を定義します。新しいパラメーター名には `EnvironmentType` を使用します。

テンプレートの _Parameters_ セクションで、`InstanceType` パラメータを以下のコードに置き換えてください。`InstanceType` パラメータはもう必要ありません。代わりにマッピングを使用します。

```yaml
Parameters:
  EnvironmentType:
    Description: 'Specify the Environment type of the stack.'
    Type: String
    Default: Test
    AllowedValues:
      - Test
      - Prod
    ConstraintDescription: 'Specify either Test or Prod.'
```

::alert[テンプレートの _ParameterGroups_ と _ParameterLabels_ セクションから `InstanceType` の削除も忘れないでください。]{type="info"}

#### 2. 次に、マッピングセクションに _EnvironmentToInstanceType_ を作成します

マップには、環境ごとに 1 つずつ、合計 2 つのトップレベルキーを含みます。各トップレベルキーには、`InstanceType` というセカンドレベルキーが 1 つ含まれています。

```yaml
Mappings:
  EnvironmentToInstanceType: # Map Name
    Test: # Top level key
      InstanceType: t2.micro # Second level key
    Prod:
      InstanceType: t2.small
```

#### 3. 次に、_InstanceType_ プロパティを変更します

組み込み関数 `Fn::FindInMap` を使用すると、CloudFormation は `EnvironmentToInstanceType` マップから値を探し、`InstanceType` プロパティにセットします。

```yaml
Resources:
  WebServerInstance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !Ref AmiID
      InstanceType: !FindInMap
        - EnvironmentToInstanceType # Map Name
        - !Ref EnvironmentType # Top Level Key
        - InstanceType # Second Level Key
```

#### 4. 次に、_Tags_ プロパティを更新します

`InstanceType` パラメータを削除したので、タグを更新する必要があります。タグプの値に `EnviromentType` を参照します。

```yaml
Tags:
  - Key: Name
    Value: !Join [ '-', [ !Ref EnvironmentType, webserver ] ]
```

#### 5. 最後に、ソリューションをデプロイします

テンプレートにマッピングセクションを追加したので、AWS コンソールに移動して CloudFormation スタックを更新します。

1. **[AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation)** を新しいタブで開き、必要に応じて AWS アカウントにログインします。
1. スタック名 (例: **cfn-workshop-ec2**) を選択します。
1. 画面右上の **更新** ボタンをクリックします。
1. **テンプレートの準備** で、**既存テンプレートを置き換える** を選択します。
1. **テンプレートの指定** で、 **テンプレートファイルのアップロード** を選びます。
1. **ファイルの選択** ボタンをクリックし、ワークショップのディレクトリに移動します。
1. `mappings.yaml` ファイルを指定し、**次へ** をクリックします。
1. **Amazon マシンイメージ ID** については、デフォルト値のままにしてください。
1. **EnvironmentType** には、ドロップダウンリストから環境を選択し (例:**Test**)、**次へ**をクリックします。
1. **スタックオプションの設定** はデフォルトの設定のままとし、**次へ** をクリックします。
1. **レビュー <スタック名>** のページで、ページの下部までスクロールし、**変更セットのプレビュー** の内容が表示されることをしばらく待ち、**送信** をクリックします。
1. ステータスが **UPDATE_COMPLETE** になるまで、**リフレッシュ** ボタンを数回クリックします。

### チャレンジ

テンプレートに `Dev` というもう一つの環境タイプを追加します。`Dev` キー名と `InstanceType: t2.nano` という名前と値のペアが含まれている必要があります。

`EnvironmentType` パラメータで許可される値のリストに `Dev` を追加することを忘れないでください。

:::expand{header="ヒントが必要ですか？"}
1. _Parameters_ セクションには
    * `Dev` を `EnvironmentType` の AllowedValues リストに追加
1. `Mappings` セクションには
    * `Dev` のトップレベルキーを追加
    * 名前と値のペア `InstanceType: t2.nano` を追加
:::

:::expand{header="解決策を確認しますか？"}
```yaml
Parameters:
  EnvironmentType:
    Description: 'Specify the Environment type of the stack.'
    Type: String
    Default: Test
    AllowedValues:
      - Dev
      - Test
      - Prod
    ConstraintDescription: 'Specify either Dev, Test or Prod.'

Mappings:
  EnvironmentToInstanceType: # Map Name
    Dev:
      InstanceType: t2.nano
    Test: # Top level key
      InstanceType: t2.micro # Second level key
    Prod:
      InstanceType: t2.small
```
完全なソリューションは、`code/solutions/mappings.yaml` ファイルにあります。
:::

ソリューションが機能することをテストするには、[5. 最後に、ソリューションをデプロイします](#5.) のステップで行ったようにスタックを更新し、`EnvironmentType` を **Dev** に変更してください。

::alert[タイプを変更する前に EC2 インスタンスを停止する必要があるため、インスタンスタイプを変更するとダウンタイムが発生します。]{type="info"}

---
### まとめ

素晴らしいです！これで、マッピングを使用してより柔軟な CloudFormation テンプレートを作成する方法を学習できました。
