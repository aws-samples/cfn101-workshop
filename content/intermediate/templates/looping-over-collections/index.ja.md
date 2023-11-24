---
title: "Fn::ForEach を使用してコレクションをループオーバする"
weight: 641
---

_ラボ実施時間 : 45分程度_

---

### 概要

インフラストラクチャをコードで記述する場合、記述するコードが同じ構成を共有するリソースや、変数などのメカニズムで管理できるいくつかの相違点を含むリソースを記述するケースがあります。このようなリソースや関連するプロパティの数が増えるにつれて、記述するコードも増えるため、長期にわたる保守が容易ではなくヒューマンエラーも発生しやすくなります。

[言語拡張](../language-extensions) ラボでは、`AWS::LanguageExtensions` [変換](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/transform-aws-languageextensions.html) を使用して [AWS CloudFormation](https://aws.amazon.com/cloudformation/) 言語を拡張するいくつかの関数を活用しました。このような関数は、CloudFormation チームが [RFC](https://github.com/aws-cloudformation/cfn-language-discussion) によって推進されるオープンディスカッションを通じてコミュニティから受け取ったフィードバックから生まれています。これらの関数の 1 つは、`Fn::ForEach` [組み込み関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-foreach.html)であり、このラボではその使用方法を学習します。この組み込み関数を使用すると、リソース構成をループ状の構造にマッピングするために使用する動的な反復処理を使用して、同じもしくは類似した構成を共有するリソースを記述できます。

### 取り上げるトピック

このラボを修了すると、次のことができるようになります。

* 同じもしくは類似した設定を共有するリソースについて、`Fn::ForEach` を使用して、静的に記述されたコードを簡略化および削除できるユースケースの例を特定できるようになります。
* `Fn::ForEach` を使用してコレクションをループさせて、リソースの状態をコードで記述できるようになります。
* 該当するユースケースについて、`Fn::ForEach` を使用してコードの行数を減らし、保守が容易でヒューマンエラーを起こしにくいコードを作成することができます。

### ラボを開始

### ラボパート 1: S3 バケットのコレクションの基本的なループ処理

ユースケースの例から始めましょう。多くの共通の設定プロパティを持つ 3 つの[Amazon Simple Storage Service (Amazon S3)](https://aws.amazon.com/s3/) バケットを定義する必要があります。例えば、[バケットの暗号化](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket-bucketencryption.html)が[AWS Key Management Service (AWS KMS)](https://aws.amazon.com/kms/)、[ライフサイクル設定](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket-lifecycleconfig.html)は 30 日後に `GLACIER` [ストレージクラス](https://aws.amazon.com/jp/s3/storage-classes/)に移行し、1 年後にオブジェクトの有効期限が切れるように設定し、`PublicAccessBlockConfiguration` [プロパティ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket-publicaccessblockconfiguration.html) を `true` に設定し、タグは `Name` タグキーの値として `aws-cloudformation-workshop` を使用するように設定します。

コードに記述する必要がある S3 バケットは、このユースケースでは同じプロパティを共有します。これら全てを 3 つの個別のコードブロックで記述することもできますが、このラボでは、`Fn::ForEach` を使用してコードサイズと相対的な複雑さを軽減し、3 つのバケット全てを 1 つの反復構造で一度に記述できます。よって、保守が容易なコードになるという利点もあり、ヒューマンエラーを減らすのにも有効です。

上記の 3 つのバケットを `Fn::ForEach` なしで記述すると、結果として下記のようなテンプレートとなります。例として次に示します。

:::code{language=yaml showLineNumbers=false showCopyAction=false}
AWSTemplateFormatVersion: "2010-09-09"

Description: AWS CloudFormation workshop lab - sample S3 buckets with the same configuration settings.

Resources:
  S3Bucket1:
    Type: AWS::S3::Bucket
    Properties:
      BucketEncryption:
        ServerSideEncryptionConfiguration:
          - ServerSideEncryptionByDefault:
              SSEAlgorithm: aws:kms
      LifecycleConfiguration:
        Rules:
          - ExpirationInDays: 365
            Id: Example Glacier Rule
            Status: Enabled
            Transitions:
              - StorageClass: GLACIER
                TransitionInDays: 30
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true
      Tags:
        - Key: Name
          Value: aws-cloudformation-workshop

  S3Bucket2:
    Type: AWS::S3::Bucket
    Properties:
      BucketEncryption:
        ServerSideEncryptionConfiguration:
          - ServerSideEncryptionByDefault:
              SSEAlgorithm: aws:kms
      LifecycleConfiguration:
        Rules:
          - ExpirationInDays: 365
            Id: Example Glacier Rule
            Status: Enabled
            Transitions:
              - StorageClass: GLACIER
                TransitionInDays: 30
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true
      Tags:
        - Key: Name
          Value: aws-cloudformation-workshop

  S3Bucket3:
    Type: AWS::S3::Bucket
    Properties:
      BucketEncryption:
        ServerSideEncryptionConfiguration:
          - ServerSideEncryptionByDefault:
              SSEAlgorithm: aws:kms
      LifecycleConfiguration:
        Rules:
          - ExpirationInDays: 365
            Id: Example Glacier Rule
            Status: Enabled
            Transitions:
              - StorageClass: GLACIER
                TransitionInDays: 30
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true
      Tags:
        - Key: Name
          Value: aws-cloudformation-workshop
:::

このラボでは、`Fn::ForEach` を使用してバケットのコレクションをループすることで S3 バケットの設定プロパティを一度だけ記述することになります。つまりこの場合、最初に使用するテンプレートのコード行数が少なくなるため、保守が容易になります。
`AWS::LanguageExtensions` トランスフォームによってテンプレートが処理され、その結果には `S3Bucket1`、`S3Bucket2`、`S3Bucket3` など、プロパティは同じで [論理 ID](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/resources-section-structure.html) が異なる 3 つのバケットリソースを含む上記のようなテンプレートが作成されます。

それでは、始めましょう! `code/workspace/looping-over-collections` ディレクトリに移動し、お好みのテキストエディタで `s3-buckets.yaml` ファイルを開きます。

::alert[先ほど開いた `s3-buckets.yaml` テンプレートですでに存在する `Transform::AWS::LanguageExtensions` 行を削除しないように注意してください。このトランスフォームは　[言語拡張](../language-extensions)　ラボで既に使用しています。この行は言語拡張 [変換](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/transform-aws-languageextensions.html) を有効にします。`Fn::ForEach` 組み込み関数を使うために *必須* です。]{type="warning"}

テキストエディタで `s3-buckets.yaml` ファイルを開いた状態で、コメントアウトされている TODO リマインダー行を削除し、以下のソースコードを `Resources` セクションに追加します。インデントは重要です。`Fn::ForEach::S3Buckets` 行の先頭の文字がエディターの列番号 `2` から始まることを確認してください。

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=8}
  Fn::ForEach::S3Buckets:
    - S3BucketLogicalId
    - [S3Bucket1, S3Bucket2, S3Bucket3]
    - ${S3BucketLogicalId}:
        Type: AWS::S3::Bucket
        Properties:
          BucketEncryption:
            ServerSideEncryptionConfiguration:
              - ServerSideEncryptionByDefault:
                  SSEAlgorithm: aws:kms
          LifecycleConfiguration:
            Rules:
              - Id: Example Glacier Rule
                ExpirationInDays: 365
                Status: Enabled
                Transitions:
                  - TransitionInDays: 30
                    StorageClass: GLACIER
          PublicAccessBlockConfiguration:
            BlockPublicAcls: true
            BlockPublicPolicy: true
            IgnorePublicAcls: true
            RestrictPublicBuckets: true
          Tags:
            - Key: Name
              Value: aws-cloudformation-workshop
:::

更新したファイルを保存します。貼り付けたコードを見ると、このラボの最初の例で見た `Type: AWS::S3::Bucket` 行から始める内容は、3 つの S3 バケット全てに共通するプロパティのセットであることがわかります。`Fn::ForEach` の仕組みを理解するために、`Type: AWS::S3::Bucket` の上にある行を見てみましょう!

この例では、3 つの S3 バケットで構成される 3 つの要素のコレクションを繰り返し処理する必要があります。このコレクションを `[S3Buckets1, S3Bucket2, S3Bucket3]` として作成し、コレクション自体の上に記述した `S3BucketLogicalId` 識別子で示される各要素を使用することを選択します。この例では、コレクションを配列として記述しましたが、`CommaDelimitedList` 型のテンプレート[パラメータ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html)への参照を使用することもできます。

貼り付けたコードの一番上にある`Fn::ForEach::S3Buckets` 行に注目してください。この行には、`Fn::ForEach` を使用してコレクションを反復処理する旨が記述されています。行の右端の `S3Buckets` は、ループに選択する名前を示しています。ループを作成するときは、必ずテンプレート内で一位の名前を指定してください。テンプレート内の別のループに使用している名前や、同じテンプレート内のリソースの論理 ID に使用した、または使用する予定の名前は選択しないでください。

`Type: AWS::S3::Bucket` のすぐ上の行、つまり `${S3BucketLogicalId}` は、変換されるテンプレートにある `OutputKey` コンテンツを示しています。この場合、`OutputKey` の値は 3 つの S3 バケットそれぞれの論理 ID になります。最初の反復ループでは `S3Bucket1`、2 番目の反復ループでは`S3Bucket2`、3 番目の反復ループでは `S3Bucket3` になります。

この例では、`Type: AWS::S3::Bucket` で始まる行とそれ以下の行は、処理されたテンプレート内の `OutputKey` ごとに複製される `OutputValue` を構成します。これらの行には、前の段落で記述した論理 ID を持つ 3 つの S3 バケットリソースに適用される共通の設定が含まれています。

::alert[CloudFormation では、処理されたテンプレートにサービスクォータを適用しす。CloudFormation サービスクォータの詳細については、CloudFormation ユーザガイドの [AWS CloudFormation のクォータ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/cloudformation-limits.html) を参照してください。]{type="warning"}

これで新しい CloudFormation スタックを作成し、上で記述したコレクションをループして 3 つの S3 バケットがどのようにプロビジョニングされるかを確認します。`us-east-1` リージョンに新しいスタックを作成します。

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
次の AWS CLI コマンドを実行します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
--stack-name looping-over-collections-s3-buckets \
--template-body file://s3-buckets.yaml \
--region us-east-1 \
--capabilities CAPABILITY_AUTO_EXPAND
:::

上記のコマンドは、作成しているスタック ID を返すはずです。[wait stack-create-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-create-complete.html) AWS CLI コマンドを作成して、スタックが `CREATE_COMPLETE` ステータスになるまで待ちます。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-create-complete \
--region us-east-1 \
--stack-name looping-over-collections-s3-buckets
:::

::::
::::tab{id="local" label="ローカル開発"}
手順

1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
2. **米国東部 (バージニア北部)** リージョンにいることを確認してください。
3. 左のナビゲーションパネルから、**スタック** を選択します。
4. ページの右側から、**スタックの作成**　を選択し、**新しいリソースを使用 (標準)** を選択します。
5. **前提条件 - テンプレートの準備** から、**テンプレートの準備完了** を選択します。
6. **テンプレートの指定** セクションで、**テンプレートソース** で、**テンプレートファイルのアップロード** を選択します。
7. **ファイルの選択** を選択し、更新した `s3-buckets.yaml` テンプレートを指定します。**次へ**　を選択します。
8. **スタックの詳細を指定** ページで、**スタック名** に `looping-over-collections-s3-buckets` と入力します。**次へ** を選択します。
9. **スタックオプションの設定** では、設定をそのままにしておきます。**次へ** を選択します。
10. **レビュー** ページで、ページの内容を確認します。ページの下部で、**機能と変換** セクションに表示されている機能をすべて承認するように選択してください。**送信** を選択します。
11. スタックが `CREATE_COMPLETE` ステータスになるまで、スタック作成ページを更新します。
::::
:::::

スタックの作成が完了したら、[AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動し、`looping-over-collections-s3-buckets` スタックを探します。スタックを選択し、次に **テンプレート** タブを選択します。次の点に確認してください。

* 指定した最初のテンプレートが表示されます。記述したバケットのコレクションに対してループを使用するものです。
* **処理されたテンプレートの表示** を選択します。展開されたテンプレートが表示され、処理の結果として、ループ構造の代わりに静的に記述された 3 つの S3 バケットが表示されます。処理された設定は JSON 形式で表示されることにご注意ください。
* **リソース** タブに移動し、論理 ID が `S3Bucket1`、`S3Bucket2`、`S3Bucket3` であるはずの 3 つの新しく作成された S3 バケットを確認できます。

おめでとうございます！このラボの最初の部分を終了し、`Fn::ForEach` の基本を学習しました。次のパートでは可動部分を増やした新しい例を見ていきます。

### ラボパート 2: VPC 関連リソースの内部ループ

ラボのこのパートでは、`Fn::ForEach` ループ構造をネストする方法を学びます。前回の `Fn::ForEach` の使い方を思い出してください。ユニークループの定義のすぐ下にある組み込み関数に以下のパラメータを渡します。

* `Identifier`
* `Collection`
* `OutputKey`

前の例では、作成したい各バケットの論理 ID の `OutputKey` として `${S3BucketLogicalID}:` を使用しました。今回の例では、`OutputKey` の代わりに別の `Fn::ForEach` ループを使用して、[Amazon Virtual Private Cloud (Amazon VPC)](https://aws.amazon.com/jp/vpc/) リソースに関連するリソースの作成のための内部ループロジックを駆動します。

それでは、始めましょう！`code/workspace/looping-over-collections` ディレクトリにいることを確認し、お好みのテキストエディタで `vpc.yaml` ファイルを開きます。コード内の `Transform: AWS::LanguageExtensions` 行に注意してください。この行は次に使用する `Fn::ForEach` 組み込み関数に *必須* です。テンプレートには既に `VPC` [リソース](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-vpc.html)、`InternetGateway` [リソース](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-internetgateway.html)、および `VpcGatewayAttachment` [リソース](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-vpc-gateway-attachment.html) が記述されていますが、`Fn::ForEach` は使用していません。なぜなら、このようなリソースはテンプレート内で一度しか定義していないからです。テンプレートには、次に使用する VPC と VPC 関連リソースの様々な設定が含まれている `Mappings` [セクション](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/mappings-section-structure.html) もあります。

開いたファイルの TODO リマインダー行を削除し、次のコードを追加して、パブリックサブネットとプライベートサブネットの記述を開始します。インデントのレベルが `VpcGatewayAttachment` リソース宣言と同じ(つまり、列 `2` から始まる) ことに注意してください。

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=63}
  Fn::ForEach::SubnetTypes:
    - SubnetType
    - [Public, Private]
    - Fn::ForEach::SubnetNumbers:
        - SubnetNumber
        - ["1", "2"]
        - ${SubnetType}Subnet${SubnetNumber}:
            Type: AWS::EC2::Subnet
            Properties:
              AvailabilityZone: !Select
                - !FindInMap
                  - SubnetAzIndexes
                  - !Ref SubnetType
                  - !Ref SubnetNumber
                - !GetAZs ""
              CidrBlock: !FindInMap
                - SubnetCidrs
                - !Ref SubnetType
                - !Ref SubnetNumber
              Tags:
                - Key: Name
                  Value: aws-cloudformation-workshop
              VpcId: !Ref Vpc
:::

上で追加したコードは、合計 4 つの `AWS::EC2::Subnet` リソースについて、2 つのパブリックサブネットと 2 つのプライベートサブネットを記述する意図を示しています。

最初の `Fn::ForEach::SubnetTypes` ループでは、サブネットタイプ (Public と Private) のコレクションを反復処理し、2 番目の内部ループ (ここでは `OutputKey` として使用している) では、特定のタイプの各サブネット (サブネット 1 とサブネット 2、コレクション内の文字列 `["1", "2"]`) を反復処理します。

::alert[`["1", "2"]` サンプルコレクションの要素である数値 `1` と `2` は、引用符で囲んで表現しています。コレクションは文字列のリストでなければならないからです。]{type="warning"}

内部ループ `${SubnetType}Subnet${SubnetNumber}` の `OutputKey` セクションで、各リソースの論理 ID の名前を作成します。各リソースの論理 ID の名前は、外部ループと内部ループの両方がコレクションを反復処理するため、それぞれのループで定義したコレクション (`[Public, Private]` と `["1", "2"]`) を繰り返し、リソースの論理 ID が `PublicSubnet1`、`PublicSubnet2`、`PrivateSubnet1`、`PrivateSubnet2` になります。

内部ループの各反復では、上記の 4 つの論理 ID の他に、`Fn::FindInMap` [組み込み関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-findinmap.html) を使って各リソースのプロパティが設定されます。`SubnetCIDRS` マッピングから CIDR アドレス情報を取得し、`Fn::GetAZs` [組み込み関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-getavailabilityzones.html) でサブネットのアベイラビリティーゾーンを選択するためのインデックスを取得します。`SubnetAZIndexes` マッピングのインデックスに使用される目的は、同じアベイラビリティゾーンに ID 1 のパブリックサブネットとプライベートサブネットを作成し、ID 2 のパブリックサブネットとプライベートサブネットを別のアベイラビリティゾーンに作成することです。この選択の理由は、アベイラビリティーゾーン内のトラフィックを最適化し、プライベートサブネットのリソースを NAT ゲートウェイと同じアベイラビリティーゾーンに配置し、関連するパブリックサブネットに合わせます。(例えば、`PrivateSubnet1` に `PublicSubnet1` に関連付けられた NAT ゲートウェイターゲットを使用させる場合などです。) 詳細については、Amazon VPC ユーザガイドの [NAT ゲートウェイ](https://docs.aws.amazon.com/ja_jp/vpc/latest/userguide/vpc-nat-gateway.html) を参照してください。

内部ループの繰り返しで複製されるサブネットのその他のプロパティには、`Tags` と `VpcId` があります。

他に必要なリソースを定義していきましょう。今回は、2 つのパブリックルートテーブルと 2 つのプライベートルートテーブルを定義し、そのルートテーブルを上記で定義したサブネットに関連付けます。既存の内部ループに次のコードを追加します。(インデントが正しいことに注意してください。`${SubnetType}routeTable${SubnetNumber}` の列は、上記の `${SubnetType}Subnet${SubnetNumber}` の列と同じく、`10` 列目とでなければなりません。)

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=86}
          ${SubnetType}RouteTable${SubnetNumber}:
            Type: AWS::EC2::RouteTable
            Properties:
              Tags:
                - Key: Name
                  Value: aws-cloudformation-workshop
              VpcId: !Ref Vpc
          ${SubnetType}SubnetRouteTableAssociation${SubnetNumber}:
            Type: AWS::EC2::SubnetRouteTableAssociation
            Properties:
              RouteTableId: !Ref
                Fn::Sub: ${SubnetType}RouteTable${SubnetNumber}
              SubnetId: !Ref
                Fn::Sub: ${SubnetType}Subnet${SubnetNumber}
:::

上記では、最初のブロックで 4 つのルートテーブル (2 つはパブリック、2 つはプライベート) を作成し、2 番目のブロックでは、同じ反復ループ内で定義しているサブネットに関連付けます。

これで、このラボのサンプルユースケースに必要なサブネットが用意され、各サブネットにルートテーブルが関連付けられました。次は、このサンプルユースケースの要件であると想定されるすべての IPv4 宛先 (`0.0.0.0/0`) へのデフォルトルートを追加します。これで、`0.0.0.0/0` CIDR はパブリックサブネットとプライベートサブネットの両方に割り当てるルートは同じですが、パブリックサブネットのルートには先に作成した `InternetGateway` がターゲットになり、プライベートサブネットのルートには代わりにネットワークアドレス変換 (NAT) の仕組みが必要になります。次に、パブリックルートとプライベートルートの 2 つの別々の新しいループイテレーションで記述し、それぞれのタイプに特化したビジネスロジックでパブリックルートとプライベートルートを分けます。

まずは、パブリックサブネット用のルートを作成し、先ほど定義したパブリックルートテーブルに追加します。ここでは、右に 2 列 (つまり、列番号 `2`) をインデントする新しいループを作成し、以下の内容を `vpc.yaml` ファイルに追加します。

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=101}
  Fn::ForEach::DefaultRoutesForPublicSubnets:
    - SubnetNumber
    - ["1", "2"]
    - DefaultRouteForPublicSubnet${SubnetNumber}:
        DependsOn: VpcGatewayAttachment
        Type: AWS::EC2::Route
        Properties:
          RouteTableId: !Ref
            Fn::Sub: PublicRouteTable${SubnetNumber}
          DestinationCidrBlock: 0.0.0.0/0
          GatewayId: !Ref InternetGateway
:::

上記の新しいループでは、パブリックサブネット用の 2 つの `AWS::EC2::Route` リソースについて記述しました。つまり、それぞれが `InternetGateway` (このラボで使用しているテンプレートですでに定義されています) をターゲットとするデフォルトルートとして設定されています。　

::alert[上記の `AWS::EC2::Route` リソースは `dependsOn` 属性を使用して VPC ゲートウェイアタッチメントへの明示的な依存関係を追加します。次に定義する `AWS::EC2::EIP` リソースについても同じです。現在のコンテキストでこれらのリソースに `DependsOn` が必要な理由について詳しくは、[DependsOn 属性が必須の場合](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-attribute-dependson.html#gatewayattachment) を参照してください]{type="warning"}

次に、プライベートサブネットのルートを設定する必要があります。そのためには、2 つの `AWS::EC2::EIP` [リソース](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-eip.html) を記述する新しいループを作成します。このループは、後でこの新しいループで定義する 2 つの `AWS::EC2::NATGateway` リソースに使用します。また、各 NAT ゲートウェイをそれぞれターゲットとするプライベートサブネットの 2 つのルートについても記述します。新しいループの次のコードをテンプレートに追加します。

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=113}
  Fn::ForEach::NatGateways:
    - SubnetNumber
    - ["1", "2"]
    - Eip${SubnetNumber}:
        DependsOn: VpcGatewayAttachment
        Type: AWS::EC2::EIP
        Properties:
          Domain: vpc
      NatGateway${SubnetNumber}:
        Type: AWS::EC2::NatGateway
        Properties:
          AllocationId: !GetAtt
            - !Sub Eip${SubnetNumber}
            - AllocationId
          SubnetId: !Ref
            Fn::Sub: PublicSubnet${SubnetNumber}
          Tags:
            - Key: Name
              Value: aws-cloudformation-workshop
      DefaultRouteForPrivateSubnet${SubnetNumber}:
        Type: AWS::EC2::Route
        Properties:
          RouteTableId: !Ref
            Fn::Sub: PrivateRouteTable${SubnetNumber}
          DestinationCidrBlock: 0.0.0.0/0
          NatGatewayId: !Ref
            Fn::Sub: NatGateway${SubnetNumber}
:::

上記のコードでは、作成している 2 つの elastic IP リソースの論理 ID (`Eip${SubnetNumber}`)、2 つの NAT ゲートウェイの論理 ID (`NATGateway${SubnetNumber}`)、およびプライベートサブネットの 2 つのルートの論理 ID (`defaultRouteForPrivateSubnet${SubnetNumber}`) をご確認ください。

さらに、NAT ゲートウェイリソースの `allocationId` [property](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-natgateway.html#cfn-ec2-natgateway-allocationid) にも注目してください。このプロパティを記述するときは、`Fn::GetAtt` [組み込み関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-getatt.html) を使用して、elastic IP リソースの論理 ID も渡すことにより、関連する elastic IP リソースの割り当て ID を使用します。上の例では、最初に `Fn::Sub` [組み込み関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-sub.html) を使用して、各 elastic IP リソース (`!Sub Eip${SubnetNumber}`) の論理 ID を作成します。次に `Ref` [組み込み関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-ref.html) を使用して、形成された論理 ID をテンプレートに記述されている関連リソースへの参照として渡します (この場合は、反復ループの一部として記述されます)。`AWS::EC2::Route` リソースの `RouteTableId` プロパティは、ルートテーブルの論理 ID を形成する際に同様のロジック (`Fn::Sub::PrivateRouteTable${SubnetNumber}`) を使用します。`AWS::EC2::NATGateway` リソースの `SubnetId` プロパティも同じです。

さて、コードで記述した VPC 関連リソースのインフラストラクチャをプロビジョニングしましょう！ラボのこの部分で行ってきたすべての変更を含む `vpc.yaml` ファイルを保存し、以下の手順に沿って `vpc.yaml` ファイルを使用して `looping-over-collections-vpc` という名前の新しいスタックを作成します。新しいスタックは `us-east-1` リージョンに作成します。

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
次の AWS CLI コマンドを実行します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
--stack-name looping-over-collections-vpc \
--template-body file://vpc.yaml \
--region us-east-1 \
--capabilities CAPABILITY_AUTO_EXPAND
:::

上記のコマンドは、作成しているスタックの ID を返すはずです。[wait stack-create-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-create-complete.html) AWS CLI コマンドを使用して、スタックが `CREATE_COMPLETE` ステータスになるまで待ちます。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-create-complete \
--region us-east-1 \
--stack-name looping-over-collections-vpc
:::

::::
::::tab{id="local" label="ローカル開発"}
手順

1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
2. **米国東部 (バージニア北部)** リージョンにいることを確認してください。
3. 左側のナビゲーションパネルから、**スタック** を選択します。
4. ページの右側から、**スタックの作成** を選択し、**新しいリソースを使用 (標準)** を選択します。
5. **前提条件 - テンプレートの準備** から、**テンプレートの準備完了** を選択します。
6. **テンプレートの指定** セクションで、**テンプレートソース** で **テンプレートファイルのアップロード** を選択します。
7. **ファイルの選択** を選択し、前に更新した `vpc.yaml` テンプレートを指定します。**次へ** を選択します。
8. **スタックの詳細を指定** ページで、**スタック名** を `looping-over-collections-vpc` と指定します。**次へ** を選択します。
9. **スタックオプションの設定** では、設定をそのままにしておきます。**次へ** を選択します。
10. **レビュー** ページで、ページの内容を確認します。ページの下部で、**機能と変換** セクションに表示されている機能をすべて承認するように選択してください。**送信** を選択します。
11. スタックが `CREATE_COMPLETE` ステータスになるまで、スタック作成ページを更新します。
::::
:::::

上記のどちらかの方法で新しいスタックを作成したら、引き続きラボのパート 1 で説明したと同様に、`looping-over-collections-vpc` スタックの **テンプレート** タブと **リソース** タブに移動します。送信したテンプレートを処理済みのテンプレートを比較し、コレクションをループする方法によってコードの保守性がどのように向上したかを確認します。

おめでとうございます！ラボのパート 2 を終了し、より複雑なユースケースが必要な時にインナーループを使用する方法を学びました。

### チャレンジ

このチャレンジでは、`Fn::ForEach` を使用して `vpc.yaml` ファイルの `Outputs` [セクション](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html) にパブリックサブネットとプライベートサブネットの ID を追加する必要があります。出力の要件は以下のとおりです。

* `vpc.yaml` テンプレートに `Outputs` セクションを追加してください。
* 出力をわかりやすくするために、各出力のコメントに以下のような説明を入れてください。
    * `The ID of PublicSubnet1.`
    * `The ID of PublicSubnet2.`
    * `The ID of PrivateSubnet1.`
    * `The ID of PrivateSubnet2.`
* 関連するサブネット ID への参照として、各出力に `Value` を追加します。
* 出力ごとに `Export` と [Name](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-stack-exports.html) を追加して、将来的に他のスタックから [インポート](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-importvalue.html) できるようにします。`YOUR_AWS_ACCOUNT_ID-SUBNET_TYPESubnetSUBNET_NUMBERId` のように各エクスポートの名前を作成します。例えば最初のサブネットが `111122223333-PublicSubnet1ID` のようになります。

:::expand{header="ヒントが必要ですか？"}
* 同じ外部 + 内部ループロジックを使用して 2 つのパブリックサブネットと 2 つのプライベートサブネットを作成したように、`Outputs` セクションに記述するコンテンツに再利用します。
* 出力のループロジックを構築するときは、出力の [構造](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html) の記述方法を思い出してください。
* 各出力の `Value` を記述するときは、サブネットの論理 ID を参照する必要がありますが、まず `Fn::Sub` を使用してサブネットの論理 ID を作成する必要があります。`AWS::EC2::Route` リソースの記述に使用した内部ループで `RouteTableId` の参照値を作成するために使用したサンプルパターン、または `AWS::EC2::NatGateway` リソースの `SubnetId` プロパティをご確認ください。
* 現在使用している AWS アカウントの ID を返すのに使用できる [擬似パラメータ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html) はありそうですか？
:::

::::::expand{header="解決策を確認しますか？"}
ソリューションの一式はこのファイルは `code/solutions/looping-over-collections` ディレクトリにある `vpc.yaml` ファイルにあります。

次の内容を `vpc.yaml` ファイルに追加します。

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=141}
Outputs:
  Fn::ForEach::SubnetIdsOutputs:
    - SubnetType
    - [Public, Private]
    - Fn::ForEach::SubnetNumbers:
        - SubnetNumber
        - ["1", "2"]
        - ${SubnetType}Subnet${SubnetNumber}:
            Description: !Sub 'The ID of ${SubnetType}Subnet${SubnetNumber}.'
            Export:
              Name: !Sub ${AWS::AccountId}-${SubnetType}Subnet${SubnetNumber}Id
            Value: !Ref
              Fn::Sub: ${SubnetType}Subnet${SubnetNumber}
:::

次に、既存の `looping-over-collections-vpc` スタックを以下の `Outputs` 情報を含むテンプレートで更新します。

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
次の AWS CLI コマンドを実行します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-stack \
--stack-name looping-over-collections-vpc \
--template-body file://vpc.yaml \
--region us-east-1 \
--capabilities CAPABILITY_AUTO_EXPAND
:::

[wait stack-update-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-update-complete.html) AWS CLI コマンドを使用して、スタックが `UPDATE_COMPLETE` ステータスになるまで待ちます。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-update-complete \
--region us-east-1 \
--stack-name looping-over-collections-vpc
:::

::::
::::tab{id="local" label="ローカル開発"}
手順

1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/) に移動します。
2. **米国東部 (バージニア北部)** リージョンにいることを確認してください。
3. 左側のナビゲーションパネルから、**スタック** を選択します。
4. スタックのリストから既存の `looping-over-collections-vpc` スタックを選択します。
5. ページの右側から、**更新** を選択します。
6. **前提条件 - テンプレートの準備** から、**既存テンプレートを置き換える** を選択します。
7. **テンプレートの指定** セクションで、**テンプレートソース** で、**テンプレートファイルのアップロード** を選択します。
8. **ファイルの選択** を選択し、更新した `vpc.yaml` テンプレートを指定します。**次へ** を選択します。
9. **スタックの詳細を指定** ページで、**次へ** を選択します。
10. **スタックオプションの設定** では、設定をそのままにしておきます。**次へ** を選択します。
11. **レビュー** ページで、ページの内容を確認します。ページの下部で、**機能と変換** セクションに表示されている機能をすべて承認するように選択してください。**送信** を選択します。
12. スタックが `UPDATE_COMPLETE` ステータスになるまで、スタック作成ページを更新します。
::::
:::::

スタックの更新が完了すると、CloudFormation コンソールのスタックの `出力` タブに出力が表示されるはずです。
::::::

### クリーンアップ

次に、このラボで作成したリソースを削除します。以下の手順を実行してください。

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
次の AWS CLI コマンドを実行して、`looping-over-collections-s3-buckets` スタックを削除します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack \
--region us-east-1 \
--stack-name looping-over-collections-s3-buckets
:::

[wait stack-delete-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-delete-complete.html) AWS CLI コマンドを使用して、`DELETE` 操作が完了するまでお待ちください。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-delete-complete \
--region us-east-1 \
--stack-name looping-over-collections-s3-buckets
:::

完了したら、上記の手順を繰り返して `looping-over-collections-vpc` スタックを削除します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack \
--region us-east-1 \
--stack-name looping-over-collections-vpc
:::

[wait stack-delete-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-delete-complete.html) AWS CLI コマンドを使用して、`DELETE` 操作が完了するまでお待ちください。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-delete-complete \
--region us-east-1 \
--stack-name looping-over-collections-vpc
:::

::::
::::tab{id="local" label="ローカル"}
手順

1. [AWS CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/)に移動します。
2. **米国東部 (バージニア北部)** リージョンにいることを確認してください。
3. **スタック** ページから、`looping-over-collections-s3-buckets` スタックを選択します。
4. スタックの詳細ペインで、**削除** を選択します。プロンプトが表示されたら、**削除** を選択します。
5. **スタック** ページから `looping-over-collections-vpc` スタックを選択します。
6. スタックの詳細ペインで、**削除** を選択します。プロンプトが表示されたら、**削除** を選択します
::::
:::::

### まとめ

`Fn::ForEach` 組み込み関数と `AWS::LanguageExtensions` トランスフォームを使ってコレクションをループさせる方法を学びました。詳細については、AWS CloudFormation ユーザガイドの [Fn::ForEach](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-foreach.html) と、[Exploring Fn::ForEach and Fn::FindInMap enhancements in AWS CloudFormation](https://aws.amazon.com/jp/blogs/devops/exploring-fnforeach-and-fnfindinmap-enhancements-in-aws-cloudformation/) を参照してください。[cfn-language-discussion](https://github.com/aws-cloudformation/cfn-language-discussion) GitHub リポジトリで RFC への貢献やフィードバックを歓迎します!
