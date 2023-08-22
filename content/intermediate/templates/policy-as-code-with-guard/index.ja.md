---
title: "Policy-as-code with Guard"
weight: 700
---


### 概要

一般的な組織では、セキュリティチームが組織が必要とするセキュリティ、ガバナンス、およびポリシーコンプライアンスの要件を設定します。要件には、Infrastructure as Code (IaC) 設定の要件も含まれます。例えば、セキュリティチームが [Amazon Simple Storage Service](https://aws.amazon.com/jp/s3/) (Amazon S3) バケットをデフォルトでサーバー側の暗号化で設定し、バージョニングを有効にするというポリシーを規定します。

ベストプラクティスの一環として、policy-as-code プラクティスを採用して、ソフトウェア開発ライフサイクル（SDLC）のごく早い段階で、次のようなポリシー・コンプライアンスの問題をプログラムで検出します。

* 開発者のワークステーションで検出
* デリバリーパイプラインの継続的インテグレーション (CI) フェーズで検出

policy-as-code を採用すると、SDLC プロセスの早い段階で発見したポリシー・コンプライアンスの問題に対処する機会が得られるため、**SDLC のフィードバック・ループをスピードアップ**できます。

Policy-as-Codeをプログラムで活用するには、ポリシー要件を、Policy-as-Code ツールが理解できる言語で記述されたルールに変換する必要があります。このラボでは、[AWS CloudFormation Guard](https://github.com/aws-cloudformation/cloudformation-guard) (Guard) などのツールを使用して、作成したルールに対するポリシーコンプライアンスの検証方法を学びます。


### 取り上げるトピック

このラボを修了すると、次のことができるようになります。

* Guard が使用するドメイン固有言語 (DSL) の基本を理解
* 最初のガードルールを記述
* デフォルトのターゲット選択方法としてフィルターを使用
* ルール / ルール節をモジュール性と再利用性を考慮して記述
* 初めてのガードルールテストを記述
* ガードルールを書く際のプラクティスとしてテスト駆動開発 (TDD) を採用
* 詳細と高度な使用例については、Guard のドキュメントを参照


### ラボを開始

#### Guard をインストール
使用しているオペレーティングシステムに応じて、ワークステーションに [Guard](https://github.com/aws-cloudformation/cloudformation-guard#installation) をインストールします。マシンに [Rust と Cargo](https://doc.rust-lang.org/cargo/getting-started/installation.html) がインストールされている場合 (または Rust と Cargo をインストールする場合)、以下の方法で Guard を簡単にインストールすることができます。

:::code{language=shell showLineNumbers=false showCopyAction=true}
cargo install cfn-guard
:::

Guard をセットアップしたら、次のコマンドを正常に実行できることを確認します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-guard help
:::

#### 最初のガードルールを記述

このセクションでは、サンプルの CloudFormation テンプレートが [Amazon S3 バケット](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket.html) と必要な次のプロパティを記述していることを検証するためのガードルール節の例を記述します。

* AES256 アルゴリズムを例として使用し、[サーバー側の暗号化](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket-bucketencryption.html)
* [バージョニング](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket-versioningconfig.html) 有効化

さあ、始めましょう！ 次に示す手順に従って進めます。

1. `code/workspace/policy-as-code-with-guard` ディレクトリに移動します。
2. お好みのテキストエディタで `example_bucket.yaml` CloudFormation テンプレートを開きます。
3. テンプレートには `AWS::S3::Bucket` リソースタイプが記述されています。AES256 アルゴリズムを使用して [サーバー側の暗号化](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket-bucketencryption.html)と[バージョニング](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket-versioningconfig.html)有効化設定を含む `Properties` セクションを追加してテンプレートを更新します。次に表示される内容をコピーし、`example_bucket.yaml` ファイルにペーストします。

```yaml
Properties:
  BucketEncryption:
    ServerSideEncryptionConfiguration:
      - ServerSideEncryptionByDefault:
          SSEAlgorithm: AES256
  VersioningConfiguration:
    Status: Enabled
```

4. ガードルール節の例を作成して、両方のプロパティが期待どおりに記述されていることを確認します。前述と同じディレクトリにある `example_bucket.guard` ファイルを開き、**type ブロック**を作成して、テンプレートに記述した `AWS::S3::Bucket` タイプのリソースの設定を検証します。次に表示されるコンテンツをコピーし、`example_bucket.guard` ファイルにペーストします。

```json
AWS::S3::Bucket {
    Properties {
        BucketEncryption.ServerSideEncryptionConfiguration[*] {
            ServerSideEncryptionByDefault.SSEAlgorithm == 'AES256'
            <<BucketEncryption not configured with the AES256 algorithm>>
        }
        VersioningConfiguration.Status == 'Enabled'
        <<BucketEncryption not configured with versioning enabled>>
    }
}
```

::alert[ガードルールを書くときは、リソースタイプを選択するデフォルトモードとして **filters** を使用します。新しい概念について少しずつ学んでいくので、このセクションでは引き続き type ブロック (特定の型をマッチさせる場合に使うフィルターのためのブロック) を使います。フィルターについては次のセクションで学びます。]{type="info"}

5. 前述のルール節のサンプルセットを確認してください。次の点に注意してください。
    * 外側のブロックには `AWS::S3::Bucket` タイプが含まれています。このブロック内のルール条項は、入力データとして提供しているテンプレートで宣言した `AWS::S3::Bucket` タイプのすべてのリソースに適用されます。
    * ルール節は、ドット (`.`) 文字を使ってデータ階層を下ります (例えば、`VersioningConfiguration.Status` は `VersioningConfiguration` の下の `Status` プロパティを参照します)。
    * ワイルドカード (`*`) 文字は、特定のレベルのすべての配列インデックスを辿るために使われます (例えば、`ServerSideEncryptionConfiguration[*]`)。
    * ルール節には、`<<` と `>>` ブロックで区切られたオプションのセクションが含まれており、[カスタムメッセージ](https://docs.aws.amazon.com/ja_jp/cfn-guard/latest/ug/writing-rules.html#clauses-custom-messages) を指定できます。
    * 例で宣言されているルール節は検証に合格することが期待されます。Guardでは、[連言標準形](https://ja.wikipedia.org/wiki/%E9%80%A3%E8%A8%80%E6%A8%99%E6%BA%96%E5%BD%A2) (CNF) を使用し、複数の論理的な `AND` 節を、`OR` 節を交えて記述します。前述の例では、ルール節は `AND` 節として解釈されます (つまり、サーバー側の暗号化 *と* バージョン管理を検証し、データがルールに照らして検証に合格するには、*両方* が満たされる必要があります。）。例えば、ClauseA *または* ClauseB が満たされているかを検証したいユースケースがある場合は、ClauseA の行に `OR` を追加してこの動作を記述します。次の例において、ルールを合格するためには、`ExampleClause1` と `ExampleClause2` の両方の要件が満たされている必要があります。`ExampleClauseA` か `ExampleClauseB` のどちらかが満たされなければなりません:

:::code{language=shell showLineNumbers=false showCopyAction=false}
[...]
ExampleClause1
ExampleClause2
ExampleClauseA OR
ExampleClauseB
[...]
:::

6. ルール節の例を詳しく見てきたので、次に示すように、`-d` (または `—data`) フラグでテンプレートを指定し、`-r` (または `—rules`) でルールを指定して、`validate` Guard サブコマンドを実行します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-guard validate -d example_bucket.yaml -r example_bucket.guard
:::

7. テンプレートがルール節に対する検証に合格したことを示す次のような出力が得られるはずです。

:::code{language=shell showLineNumbers=false showCopyAction=false}
example_bucket.yaml Status = PASS
PASS rules
example_bucket.guard/default    PASS
---
Evaluation of rules example_bucket.guard against data example_bucket.yaml
--
Rule [example_bucket.guard/default] is compliant for template [example_bucket.yaml]
--
:::

::alert[前述の `example_bucket.guard/default` 出力部分に示されている `default` サフィックスは、ルール節が `default` という名前のルールに属していることを示しています。このラボの後半で、特定の名前 (**名前付きルール**) でルールを作成し、デフォルトルールの代わりに使用します。この作業を実施することで、モジュール化された再利用可能なルールを作成できます。]{type="info"}

おめでとうございます！ 最初のガードルールを作成し、それを使用して S3 バケット設定例を記述したサンプルテンプレートを検証しました。


#### フィルタリング

前の例では、type ブロックを使用して、入力テンプレートに記述した特定のタイプのターゲットリソースを選択しました。このセクションでは、ルールに照らして検証したいターゲットを柔軟に選択できる **filters** について学びます。例えば、テンプレートに記述した全ての [AWS::IAM::Policy](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-iam-policy.html) と [AWS::IAM::ManagedPolicy](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-iam-managedpolicy.html) リソースの `PolicyDocument` プロパティ (両方のリソースタイプに共通するプロパティ) を検証するには、次のような両方のタイプのリソースをクエリするフィルタを作成します。

:::code{language=json showLineNumbers=false showCopyAction=true}
Resources.*[
    Type in [ 'IAM::Policy', 'IAM::ManagedPolicy' ]
]
:::

先程使ったルール節の例をフィルターで書き直してみましょう！ この演習の一部として、`let` を使用して `my_buckets` サンプル変数を宣言し、次に示すように `%` 文字を使用したサンプルルールで、その変数を参照します。

```javascript
let my_buckets = Resources.*[ Type == 'AWS::S3::Bucket' ]


%my_buckets.Properties {
    BucketEncryption.ServerSideEncryptionConfiguration[*] {
        ServerSideEncryptionByDefault.SSEAlgorithm == 'AES256'
        <<BucketEncryption not configured with the AES256 algorithm>>
    }
    VersioningConfiguration.Status == 'Enabled'
    <<BucketEncryption not configured with versioning enabled>>
}
```

`example_bucket.guard` の既存のルール節を新しい内容に置き換えて、検証を再実行します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-guard validate -d example_bucket.yaml -r example_bucket.guard
:::

フィルターを使用しているルール節に対する検証が合格するはずです。

::alert[Guard は *file*、*rule*、*block* レベルで変数スコープをサポートしています。特定のスコープ内の変数の具体的な配置によって、ガードルールを含むファイルでの変数の可視性が決まります。前に示した `my_buckets` 変数のスコープはファイルレベルのスコープなので、`example_bucket.guard` ルールファイルに記述したルール / ルール節から `my_buckets` が見えるはずです。詳細については、[AWS CloudFormation Guard ルールにおける変数の割り当てと参照](https://docs.aws.amazon.com/ja_jp/cfn-guard/latest/ug/variables.html) をご参照ください。]{type="info"}

おめでとうございます！ テンプレート内の特定のタイプのリソースに一致するフィルターを作成し、ファイルレベルでスコープした変数も再利用しました。


#### モジュール性と再利用性を考慮してルールを書き直す

このセクションでは、ルール節を別々のルールに分解して、モジュール化して再利用できるようにします。**シンプルでモジュール化されたガードルールを作成すると、再利用の機会が得られるだけでなく、データを検証したときに失敗したルールを特定したり、必要に応じてルールをトラブルシューティングしたりするのが簡単になります。**

前に示したルール節の例を思い出してください。1 つの節では、バケットに設定したサーバー側の暗号化設定を検証し、もう 1 つの節ではバケットのバージョニング有効化設定を検証しました。このロジックを 2 つの [名前付きルール](https://docs.aws.amazon.com/ja_jp/cfn-guard/latest/ug/named-rule-block-composition.html) に書き換えてみましょう。これらは名前を割り当てたルールです。

`rule validate_bucket_sse_example` と `validate_bucket_versioning_example` の 2 つの名前付きルールを作成します。各ルール宣言ステートメントでは、入力データに選択ターゲット (この場合は `AWS::S3::Bucket` リソース) が存在する場合にのみ入力データに対して指定されたルールを実行することを目的として、`when` キーワードを使用します。

```javascript
let my_buckets = Resources.*[ Type == 'AWS::S3::Bucket' ]


rule validate_bucket_sse_example when %my_buckets !empty {
    %my_buckets.Properties {
        BucketEncryption.ServerSideEncryptionConfiguration[*] {
            ServerSideEncryptionByDefault.SSEAlgorithm == 'AES256'
            <<BucketEncryption not configured with the AES256 algorithm>>
        }
    }
}


rule validate_bucket_versioning_example when %my_buckets !empty {
    %my_buckets.Properties {
        VersioningConfiguration.Status == 'Enabled'
        <<BucketEncryption not configured versioning enabled>>
    }
}
```

`example_bucket.guard` 内の既存のルール節を置き換えます。上記、名前付きの 2 つのルールをコピーして貼り付けます。完了したら、検証を再実行します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-guard validate -d example_bucket.yaml -r example_bucket.guard
:::

すると、以下のような出力が得られるはずです。前に確認した `default` ルールの代わりに、`rule validate_bucket_sse_example` と `validate_bucket_versioning_example` ルールに割り当てた名前が表示されるはずです。

:::code{language=shell showLineNumbers=false showCopyAction=false}
example_bucket.yaml Status = PASS
PASS rules
example_bucket.guard/validate_bucket_sse_example           PASS
example_bucket.guard/validate_bucket_versioning_example    PASS
---
Evaluation of rules example_bucket.guard against data example_bucket.yaml
--
Rule [example_bucket.guard/validate_bucket_sse_example] is compliant for template [example_bucket.yaml]
Rule [example_bucket.guard/validate_bucket_versioning_example] is compliant for template [example_bucket.yaml]
--
:::

::alert[入力データにターゲットの選択が含まれていない場合 (前の例で、テンプレートに Amazon S3 バケットを記述しなかった場合): 前述の (`when %my_buckets !empty`) のように `when` キーワードを使用する場合、ルールの評価はスキップされ、結果の Guard 出力で `SKIP` とマークされます。もし、代わりに `when` キーワードと `%my_buckets !empty` の部分を省略すると、ルールは取得エラーにより失敗します。節、クエリ、演算子の詳細については、[AWS CloudFormation Guard ルールの作成](https://docs.aws.amazon.com/ja_jp/cfn-guard/latest/ug/writing-rules.html)をご参照ください。]{type="info"}

おめでとうございます！ 最初のルール節を 2 つの別々の名前付きルールに分離したので、モジュール性と再利用性が優先されます。 また、必要に応じてコードを書いたり、使用したり、トラブルシューティングしたりするための小規模のコードの例も用意しました。


#### ルールの相互関係

ユースケースやビジネスロジックの実装ニーズに応じて、別のルール内から名前付きルールを参照できます。前の例を思い出してみましょう。`example_bucket.guard` ファイルに、次の内容を追加します。

```json
rule correlation_example when %my_buckets !empty {
    validate_bucket_sse_example
    validate_bucket_versioning_example
}
```

`correlation_example` のサンプルルールは、同じファイルで前に説明した他の 2 つの名前付きルールを参照しています。`correlation_example` が合格するには、両方の名前付きルールが満たされている必要があります。検証を再実行します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-guard validate -d example_bucket.yaml -r example_bucket.guard
:::

次の抜粋のような出力が得られるはずです。

:::code{language=shell showLineNumbers=false showCopyAction=false}
example_bucket.yaml Status = PASS
PASS rules
example_bucket.guard/validate_bucket_sse_example           PASS
example_bucket.guard/validate_bucket_versioning_example    PASS
example_bucket.guard/correlation_example                   PASS
[...]
:::

`validate_bucket_sse_example` ルールや `validate_bucket_versioning_example` ルールが失敗した場合、`correlation_example` ルールも失敗します。

おめでとうございます！これで、名前付きルールを相互に関連付けて参照する方法がわかりました。


#### 初めてのガードルールテストの記述

Guard では、ルールのテストを作成して、ルールが期待どおりに機能することを検証できます。この側面は、ワークフローで [テスト駆動開発](https://ja.wikipedia.org/wiki/%E3%83%86%E3%82%B9%E3%83%88%E9%A7%86%E5%8B%95%E9%96%8B%E7%99%BA) (TDD) のプラクティスを活用する機会も開きます。最初にルールのテストを作成することから始め、次にルールのテストを作成して実行します。

さあ、始めましょう！ お好みのテキストエディタで `example_bucket_tests.yaml` ファイルを開き、以前に使用した名前付きルールのテストを含む次の内容を追加します。

```yaml
- input:
    Resources:
      MyExampleBucket:
        Type: AWS::S3::Bucket
        Properties:
          BucketEncryption:
            ServerSideEncryptionConfiguration:
              - ServerSideEncryptionByDefault:
                  SSEAlgorithm: AES256
  expectations:
    rules:
      validate_bucket_sse_example: PASS

- input:
    Resources:
      MyExampleBucket:
        Type: AWS::S3::Bucket
        Properties:
          VersioningConfiguration:
            Status: Suspended
  expectations:
    rules:
      validate_bucket_versioning_example: FAIL
```

先ほど示したテスト内容の例を見ると、テストには 2 つの `input` セクションがあり、この例では各テストケースに 1 つずつあることがわかります。
* 最初のテストケースでは、`validate_bucket_sse_example` ルール検証のサーバー側の暗号化検証ロジックが、期待されるテスト入力が提供されたときに合格することをテストします。この例では、`bucketEncryption` の下の `SSEAlgorithm` プロパティに `AES256` を使用しています。
* 2 つ目のテストケースでは、`VersioningConfiguration` の `Status` に、(`Enabled` ではなく) `Suspended` を提供すると、`validate_bucket_versioning_example` ルールの検証が失敗することが予想されます。

テストを実行しましょう！ `test` Guard サブコマンドを使用してテストファイルを指定し、その後に `-t` (または `—test-data`) を使用してテストファイルを指定し、`-r` (または `—rules-file`) を使用してテスト対象のルールを含むファイルを指定します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-guard test -t example_bucket_tests.yaml -r example_bucket.guard
:::

テストケースの例と期待する結果の両方を示した、次の例のような出力が得られるはずです。

:::code{language=shell showLineNumbers=false showCopyAction=false}
Test Case #1
  No Test expectation was set for Rule validate_bucket_versioning_example
  No Test expectation was set for Rule correlation_example
  PASS Rules:
    validate_bucket_sse_example: Expected = PASS, Evaluated = PASS

Test Case #2
  No Test expectation was set for Rule validate_bucket_sse_example
  No Test expectation was set for Rule correlation_example
  PASS Rules:
    validate_bucket_versioning_example: Expected = FAIL, Evaluated = FAIL
:::

おめでとうございます！ ガードルールの最初のテストを書いて実行しました！


### チャレンジ

[Amazon S3 バケット](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket.html) の `PublicAccessBlockConfiguration` の全ての[プロパティ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket.html#aws-properties-s3-bucket-properties) を `true` (Boolean) に設定します。

タスクは以下のとおりです。
1. `example_bucket_tests.yaml` ユニットテストファイルの内容に、`true` に設定されたすべての `publicAccessBlockConfiguration` プロパティを含むテスト入力データを提供するときに、これから作成する `validate_bucket_public_access_block_example` という新しいルールを検証するための新しい `input` セクションを追加します。
2. `example_bucket.guard` ファイルに `validate_bucket_public_access_block_example` ルールを実装します。ルールに記述する各節の後に、`PublicAccessBlockConfiguration` プロパティごとにカスタムメッセージを追加します。
3. テストを実行するには、`test` サブコマンドで Guard を実行します。ユニットテストの出力に Test Case #3 セクションがあり、新しいルールのユニットテストが成功したことを示す `validate_bucket_public_access_block_example: Expected = PASS, Evaluated = PASS` のような行があるはずです。
3. `example_bucket.yaml` テンプレートを更新し、関連する `PublicAccessBlockConfiguration` 設定を追加します。
4. `validate` サブコマンドを使用して Guard を実行し、`example_bucket.yaml` ファイルの内容を、`example_bucket.guard` ファイルに記述したルールと照らし合わせて検証します。結果の出力には、新しいルールに対する検証が成功したことを示す `example_bucket.guard/validate_bucket_public_access_block_example PASS` のような文字列が表示されるはずです。


:::expand{header= "ヒントが必要ですか？"}
* `PublicAccessBlockConfiguration` プロパティドキュメント [ページ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket-publicaccessblockconfiguration.html) に移動して、その下にあるプロパティの名前を調べます。
* `versioningConfiguration.Status` 節についても、同じルール構造に従います。`PublicAccessBlockConfiguration` [プロパティ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket-publicaccessblockconfiguration.html) のそれぞれについて記述するルール節については、文字列の代わりに ブール値 `true` を利用します。
:::


::::expand{header= "解決策を確認しますか？"}
注:次に示す内容は、`code/solutions/policy-as-code-with-guard` ディレクトリにある関連ファイルにもあります。

* 下記の内容を `example_bucket_tests.yaml` ユニットテストファイルに追加します。

```yaml
- input:
    Resources:
      MyExampleBucket:
        Type: AWS::S3::Bucket
        Properties:
          PublicAccessBlockConfiguration:
            BlockPublicAcls: true
            BlockPublicPolicy: true
            IgnorePublicAcls: true
            RestrictPublicBuckets: true
  expectations:
    rules:
      validate_bucket_public_access_block_example: PASS
```


* 下記の内容を `example_bucket.guard` ファイルに追加します。

```json
rule validate_bucket_public_access_block_example when %my_buckets !empty {
    %my_buckets.Properties {
        PublicAccessBlockConfiguration.BlockPublicAcls == true
        <<BlockPublicAcls not set to true in PublicAccessBlockConfiguration>>

        PublicAccessBlockConfiguration.BlockPublicPolicy == true
        <<BlockPublicPolicy not set to true in PublicAccessBlockConfiguration>>

        PublicAccessBlockConfiguration.IgnorePublicAcls == true
        <<IgnorePublicAcls not set to true in PublicAccessBlockConfiguration>>

        PublicAccessBlockConfiguration.RestrictPublicBuckets == true
        <<RestrictPublicBuckets not set to true in PublicAccessBlockConfiguration>>
    }
}
```


* ユニットテストを実行し、検証に合格することを確認します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-guard test -t example_bucket_tests.yaml -r example_bucket.guard
:::


* このコンテンツを `example_bucket.yaml` テンプレートに追加します。

```yaml
PublicAccessBlockConfiguration:
  BlockPublicAcls: true
  BlockPublicPolicy: true
  IgnorePublicAcls: true
  RestrictPublicBuckets: true
```


* テンプレートデータをルールに照らして検証し、すべてのルールが検証に合格することを確認します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-guard validate -d example_bucket.yaml -r example_bucket.guard
:::
::::


---
### まとめ

ガードルールの作成とテストの基礎を理解することができました！ Guard の詳細については、[ドキュメント](https://docs.aws.amazon.com/ja_jp/cfn-guard/latest/ug/what-is-guard.html) をご参照ください。また、よくある質問や例を含むコンテンツ [Guard リポジトリ](https://github.com/aws-cloudformation/cloudformation-guard)もご参照ください。
