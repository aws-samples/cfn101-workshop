---
title: Python での実装例
weight: 320
---

### 概要

このラボでは、Python で記述されたサンプルプライベート拡張を AWS アカウントの AWS CloudFormation レジストリに登録する手順を実施します。また、リソースタイプのソースコード実装ロジックの例を確認して、リソースタイプ開発ワークフローの主要な概念を理解します。

### 対象トピック

このラボを修了すると、次のことができるようになります。

* リソースタイプを開発する際に活用すべき重要な概念を理解します。
* [CloudFormation Command Line Interface (CLI)](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/what-is-cloudformation-cli.html) を使用して新しいプロジェクトを作成し、コントラクトテストを実行し、リソースタイプをプライベート拡張として AWS アカウントの CloudFormation レジストリに登録します。
* [AWS SAM CLI](https://docs.aws.amazon.com/ja_jp/serverless-application-model/latest/developerguide/install-sam-cli.html) を使用してリソースタイプハンドラーを手動でテストする方法を理解します。

### ラボの開始

このラボでは、[リポジトリ](https://github.com/aws-cloudformation/aws-cloudformation-samples) にあるサンプルリソースタイプを使用します。

::alert[新しいプロジェクトを作成する方法については、[Walkthrough: Develop a resource type](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/resource-type-walkthrough.html) をご参照ください。]{type="info"}

#### リソースタイプウォークスルーのサンプル

例として、[AWSSamples::EC2::ImportKeyPair](https://github.com/aws-cloudformation/aws-cloudformation-samples/tree/main/resource-types/awssamples-ec2-importkeypair/python) サンプルリソースタイプを使用します。これは、CloudFormation でインポートされた [Amazon EC2 key pair](https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/UserGuide/ec2-key-pairs.html) をインポートし、管理する例を示しています。

さあ、始めましょう! 新しいディレクトリを作成し、この [リポジトリ](https://github.com/aws-cloudformation/aws-cloudformation-samples) をディレクトリにクローンします。また、[ZIP アーカイブをダウンロード](https://github.com/aws-cloudformation/aws-cloudformation-samples/archive/refs/heads/main.zip) しても実施できます。リポジトリをクローンするには、以下のコマンドを使用します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
git clone https://github.com/aws-cloudformation/aws-cloudformation-samples.git
:::

リポジトリには多数のサンプルが含まれています。ディレクトリをサンプルリソースタイプのディレクトリに変更します。

:::code{language=shell showLineNumbers=false showCopyAction=false}
cd aws-cloudformation-samples/
cd resource-types/awssamples-ec2-importkeypair/python/
:::

ディレクトリ内のいくつかの要素を見てみましょう。

* `docs/`: リソースタイプのプロパティ用に自動生成された構文情報が含まれます。リソーススキーマファイルを変更するたびに、このディレクトリ内のファイルを含む自動生成コードを `cfn generate` CloudFormation CLI [コマンド](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/resource-type-cli-generate.html) で更新する必要があります。
* `inputs/`: リソースタイプ入力プロパティのキー/値データを含むファイルが含まれています。リソースタイプ作成者は、コントラクトテストで使用する入力情報を指定します。 *これらのファイルに機密情報を追加しないでください。* 詳細については、[Specifying input data for use in contract tests](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/resource-type-test.html#resource-type-test-input-data) をご参照ください。
* `awssamples-ec2-importkeypair.json`: 選択したリソースタイプ名にちなんで名付けられた、**リソースのモデルの定義**に使用されるリソーススキーマファイルです。
* `src/`: リソースタイプ名にちなんで名付けられたディレクトリが含まれています。中には次のものがあります。
    - `models.py`: スキーマを変更すると、お客様に代わって CloudFormation CLI が管理します。
    - `handlers.py`: リソースタイプ開発者が CRUDL 実装ロジックのコードを追加する場所です。任意のテキストエディタで `src/handlers.py` ファイルを開き、`create_handler`、`update_handler`、`delete_handler`、`read_handler`、`list_handler` 関数で示されているように**ハンドラーの構造を認識してください**。
* `resource-role.yaml`: CloudFormation CLI によって管理されるファイルです。このロールには [AWS Identity and Access Management](https://aws.amazon.com/jp/iam/) (IAM) ロールが記述されており、そのロールの `PolicyDocument` には、リソースタイプ開発者がスキーマファイルの `handlers` セクションで示す権限が含まれています。CloudFormation は CRUDL オペレーションの一環として、ユーザーに代わってこのリソースタイプのリソースを管理する役割を引き受けます。
* `template.yml`: [AWS Serverless Application Model](https://aws.amazon.com/jp/serverless/sam/) (SAM) テンプレートはリソースタイプテストの一部として使用されます。

#### リソースモデリング

リソースタイプを作成する際の**最初のステップ**は、**リソースのプロパティを記述するスキーマ**を定義することと、**CloudFormationがユーザーに代わってリソースを管理**するために**必要な権限**を定義することです。

まず、このウォークスルーで使用しているサンプルリソースタイプでどのプロパティが必要かを判断することから始めましょう。作成するリソースタイプに関連する API リファレンスページにアクセスします。`AWSSamples::EC2::ImportKeyPair` リソースタイプの例については [Amazon EC2 API リファレンス](https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/APIReference/Welcome.html) を参照します。[AWS ドキュメンテーション](https://docs.aws.amazon.com/ja_jp/index.html) ページに移動し、**コンピューティングカテゴリ**から **Amazon EC2** を選択し、次のページで **API リファレンス**を選択します。

次に、[Action](https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/APIReference/API_Operations.html) から、キーペアに対してプログラムでアクションを実行できる操作を探します。`CreateKeyPair`、`DeleteKeyPair`、`DescribeKeyPairs`、`ImportKeyPair`を書き留めておきます。
`CreateKeyPair` はキーペアの作成に関係しますが、インポートには関係ないので、必要ありません。代わりに、他の 3 つのアクションが必要です。

[ImportKeyPair](https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/APIReference/API_ImportKeyPair.html) のドキュメントに移動します。*request parameters* と *response elements* を調べて、**スキーマに記述したいプロパティを決定**する必要があります。この場合、*request parameters* には以下を指定する必要があります。

* インポートするキーペアの `KeyName` (ドキュメントに *Required: Yes* と記載)
* `PublicKeyMaterial` コンテンツ (*Required: Yes*)
* オプションのタグ設定 (`TagSpecification.N` - *Required: No)*


次に、*レスポンス要素*を見てみましょう。リソースを作成すると、`keyFingerprint` を含む他の要素とともに `keyPairId` が返されます。[DeleteKeyPair](https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/APIReference/API_DeleteKeyPair.html) アクションは、`KeyName` を含むパラメータを受け取ります。一旦、以下にまとめてみましょう。

* `KeyName` と `PublicKeyMaterial` は必須の入力パラメータです。タグ (`TagSpecification.N`) はオプションです。
* `keyPairId` と `keyFingerprint` はリソースの作成後に使用可能になるため、ユーザーが指定することはできません。
* リソースのプライマリ識別子プロパティには `keyPairId` が適しています。

上記のプロパティは、CloudFormation がユーザーに代わってリソースを管理するために使用する *create*、*update*、*delete* ハンドラーでの使用に適しています。

他の 2 つのハンドラーには追加のプロパティが必要です。*read* (リソースの現在の状態情報が必要な場合に CloudFormation がスタック更新時に呼び出す) と *list* (特定のタイプの複数のリソースについて概要情報が必要な場合に呼び出される) です。この例では、`keySet` や `keyType` などの関連するプロパティを探すために、[`DescribeKeyPairs`](https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/APIReference/API_DescribeKeyPairs.html) が適しています。

では、上記の結果を `AWSSamples::EC2::ImportKeyPair` リソースタイプのスキーマの例と比較してみましょう。お好きなテキストエディターで `awssamples-ec2-importkeypair.json` ファイルを開くと、以下のことがわかります。

* モデルのプロパティと値の制約については、`properties` セクションで定義しています。
* `KeyName`, `PublicKeyMaterial` は `required` となっています。
* `KeyPairId`、`KeyFingerprint`、`KeyType` (リソース作成後に決定されるプロパティ) は `readOnlyProperties` として指定されます。
* `KeyPairId` は `primaryIdentifier` として設定されています。
* `PublicKeyMaterial` は `writeOnlyProperties` で指定されます。機密データ (パスワードなど) を含む値を記述するときには `writeOnlyProperties` がよく使われます。これらの値は *list* や *read* のリクエストでは返されません。`AWSSamples::EC2::ImportKeyPair` の例では、*list* や *read* ハンドラーで使用されている `DescribeKeyPairs` によって公開鍵情報は返されず、nullになるので、*list* または *read* ハンドラーに含めても意味がありません。そのため、この例では、プロパティを `writeOnlyProperties` と記述することが適切です。
* `KeyName`、`PublicKeyMaterial` は `createOnlyProperties` として設定されています。そのため、インポートされたキーペアの 2 つの値のいずれかを更新すると、新しい値を持つ新しいリソースが作成され、以前のリソースが削除されます。
* 必須ではない `Tags` は、スキーマ内の定義間で再利用できるようにするためのベストプラクティスの一環として [`definitions`](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/resource-type-schema.html#schema-properties-definitions) セクションで定義されています。サンプルスキーマでは、`Tags` は `properties` セクションの `$ref` ポインターで参照します。

スキーマの作成方法とスキーマ要素の詳細については、[Resource type schema](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/resource-type-schema.html) をご参照ください。

`awssamples-ec2-importkeypair.json` サンプルスキーマファイルには、ハンドラーがユーザーに代わってリソースタイプを管理するために必要な [AWS Identity and Access Management](https://aws.amazon.com/jp/iam/) (IAM) 権限も多数含まれています。サンプルスキーマファイルの `handlers` セクションを見ると、わかりやすい EC2 関連の権限がいくつか見つかります。例えば、*create* ハンドラーと *read* ハンドラーの場合、次のようになっているはずです。

:::code{language=json showLineNumbers=false showCopyAction=false}
    "handlers": {
        "create": {
            "permissions": [
                "ec2:ImportKeyPair",
                "ec2:CreateTags"
            ]
        },
        "read": {
            "permissions": [
                "ec2:DescribeKeyPairs"
            ]
        },
    }
:::

リソースタイプを作成するときに選択できる権限の詳細については、[AWS サービスのアクション、リソース、および条件キー](https://docs.aws.amazon.com/ja_jp/service-authorization/latest/reference/reference_policies_actions-resources-contextkeys.html)をご参照ください。このページで、必要な AWS サービスを選択します。今回の例だと、[Amazon EC2](https://docs.aws.amazon.com/ja_jp/service-authorization/latest/reference/list_amazonec2.html)）を選択し、次に [Amazon EC2 で定義されるアクション](https://docs.aws.amazon.com/ja_jp/service-authorization/latest/reference/list_amazonec2.html#amazonec2-actions-as-permissions) を選択します。

::alert[開発するリソースのスキーマファイルを変更するときは、リソースタイププロジェクトのルートディレクトリ内から `cfn generate` CloudFormation CLI コマンドを実行して、スキーマの変更を `docs/*`、`resource-role.yaml`、`src/[RESOURCE_TYPE_NAME]/models.py` などのプロジェクトファイルに反映します。]{type="info"}

#### ハンドラー

先ほどの例で示したようにリソーススキーマをモデル化したら、次のステップはハンドラーでコード実装を開始することです。考慮すべき点は以下のとおりです。

* 特定の CRUDL ハンドラー (*Create*、*Read*、*Update*、*Delete*、*List*) には、次のようなビジネスロジックを実装する必要があります。
    * 特定のサービス固有の API (*create* ハンドラーは `ImportKeyPair`、*delete* ハンドラーは `DeleteKeyPair`、など) を呼び出します。
* 特定のハンドラーで呼び出した特定の API から返されたデータを利用します。さらに、
    * すべてのハンドラーは常に `ProgressEvent` を返さなければなりません。その構造の詳細については、[ProgressEvent object schema](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/resource-type-test-progressevent.html) をご参照ください。
    * エラーがなければ、指定したハンドラーから `status=OperationStatus.SUCCESS` を含む `ProgressEvent` オブジェクトを返します。例: `return ProgressEvent(status=OperationStatus.SUCCESS)`。さらに、ハンドラーが *delete* または *list* でない場合は、リソースのハンドラーコード (API 呼び出しから) で収集したデータを含む、おなじみのオブジェクト (リソースのモデル) を返します。`ResourceModel` *list* ハンドラーでは、単一のモデルではなく、記述しているタイプのリソースごとにモデルのリストを返します。
    * 呼び出す API がエラーを返す場合、または別の例外が発生した場合は、`status=OperationStatus.FAILED` を使用して `ProgressEvent` オブジェクトを返します。その際に考慮すべき点は次のとおりです。
        * スタックトレースや、例外 (`botocore.exceptions.ClientError` やその他の例外等) から得られる特定のエラーメッセージテキストをキャプチャします。これにより、ハンドラーのコードに記述したログステートメントにスタックトレースを表示し、`ProgressEvent` オブジェクトでエラーメッセージの説明を返すことができます。これにより、この情報を CloudFormation イベントの一部として（例えば、CloudFormation コンソールのイベントペインで）利用できるようにして、エラーの原因をユーザーに説明できます。
        * API から発生するエラー (インポートキーペアの例では、[Amazon EC2 API のエラーコード](https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/APIReference/errors-overview.html)からのエラー) に応じて、[ハンドラーエラーコード](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/resource-type-test-contract-errors.html)のエラーにマッピングする必要があります。例えば、EC2 API が `InvalidKeyPair.NotFound` クライアントエラーを返す場合、`ProgressEvent` と共に、`HandlerErrorCode.NotFound` ハンドラーエラーを返す必要があります。
        * リソースタイプが安定するまでに時間がかかる場合 (例えば、リソースが完全に利用可能な状態に達するなど) は、*create*、*update*、*delete* の各ハンドラーで安定化メカニズムを使用します。ハンドラが最初に呼び出されたとき、`OperationStatus.IN_PROGRESS` と共に `ProgressEvent` を返し、その後、そのハンドラが希望の状態になるまで呼び出される場合は、*read* ハンドラを呼び出して進行状況を確認することで次のステップに進みます (例えば、特定のプロパティ値をチェックして作成が完了したか進行中かを判断します)。

上記のトピックの例は、`src/awssamples_ec2_importkeypair/handlers.py` サンプルリソースタイプで確認できます。各ハンドラーは特定の EC2 API を呼び出します。前述のように、スキーマには関連する権限セットが設定されています。

サンプルリソースタイプは上記の例外処理メカニズムを利用しますが、ダウンストリーム API エラーメッセージはキャプチャされ、特定の EC2 API にマップされたハンドラーエラーコードとともに返されます。以下は、サンプルリソースタイプの `read_handler` 関数からの抜粋です (サンプルリソースタイプコードの `_progress_event_failed` 関数を見ると、スタックトレース情報を記録し、`ProgressEvent` の失敗を返すことによって入力情報を利用しています)。

:::code{language=python showLineNumbers=false showCopyAction=false}
    except botocore.exceptions.ClientError as ce:
        return _progress_event_failed(
            handler_error_code=_get_handler_error_code(
                ce.response['Error']['Code'],
            ),
            error_message=str(ce),
            traceback_content=traceback.format_exc(),
        )
:::

キーペアインポートのユースケースで安定化プロセスが必ずしも必要ではない場合でも、サンプルリソースタイプは、*create*、*update*、*delete* ハンドラーで使用され、`_is_callback` サンプル関数によって駆動するコールバックメカニズムの例を示しています。

#### ユニットテストの実行

ソフトウェア開発のベストプラクティスの一環として、*unit tests* を作成して、コードが期待どおりに動作するという確信を高めます。[ノート](https://github.com/aws-cloudformation/aws-cloudformation-samples/tree/main/resource-types/awssamples-ec2-importkeypair/python#unit-tests) で説明されているように、`AWSSamples::EC2::ImportKeyPair` サンプルリソースタイプには `src/awssamples_ec2_importkeypair/tests` ディレクトリに単体テストが含まれています。そのディレクトリにある `test_handlers.py` ファイル (先ほど選択したリポジトリのクローン/ダウンロードによりマシン上に存在) を見ると、最初に説明したテストユーティリティ関数と、ファイルの途中あたりに定義されているテストユーティリティ関数が表示されます。このファイルの途中には、ユーティリティ関数を使用して、戻り値の検証や投げられた例外の検証等のテストを実行するユニットテストがあります。EC2 API 呼び出しなどの関数呼び出しを含むオブジェクトは、[unittest.mock](https://docs.python.org/3/library/unittest.mock.html) モックオブジェクトライブラリを利用して、モックオブジェクト呼び出しによるテストで置き換え/パッチされます。

ユニットテストを実行しましょう！`AWSSamples::EC2::ImportKeyPair` サンプルリソースタイプのルートレベルにあるディレクトリ (つまり `python` ディレクトリ内) にいることと、前トピックの前提条件に従っていることを確認してください。次に、以下のように単体テストを実行します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
pytest --cov src --cov-report term-missing
:::

ユニットテストの結果と、合計カバレッジ率の値を示す出力が得られるはずです。サンプルリソースタイプのユニットテストでは、プロジェクトのルートにある `.coveragerc` ファイルを使用します。このファイルには、必要なテストカバレッジ値を含む [設定](https://coverage.readthedocs.io/en/latest/config.html) の選択肢が含まれています。

#### コントラクトテストの実行

このラボの以降のステップでは、`AWSSamples::EC2::ImportKeyPair` サンプルリソースタイプをプライベート拡張としてローカルでテストし、アカウントの CloudFormation レジストリに登録します。

リソースタイプを構築するときや、開発プロセスの非常に早い段階でハンドラーのビジネスロジックを実装する際に順守すべき要件を説明する [Resource type handler contract](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/resource-type-test-contract.html) を必ず活用する必要があります。ハンドラーコントラクトの強制は、パブリックリソースタイプをレジストリに登録したときに行われますが、その場合はコントラクトテストに合格する必要があります。これは、リソースタイプを利用する外部の顧客に代わって高い品質基準を維持するために重要です。

::alert[パブリックリソースタイプを公開するにはコントラクトテストに合格する必要があり、プライベートリソースタイプを送信した場合は実行されません。ただし、ベスト・プラクティスの一環として、開発プロセスの非常に早い段階でコントラクト・テストの仕様を順守するようにしてください。]{type="info"}

サンプルリソースタイプのコントラクトテストを実行してみましょう！まず、[ノート](https://github.com/aws-cloudformation/aws-cloudformation-samples/tree/main/resource-types/awssamples-ec2-importkeypair/python#contract-tests) で説明されているように、サンプルリソースタイプ用のテストサポートインフラストラクチャをセットアップしましょう。サンプルリソースタイプのコントラクトテストでは、アカウント内のテスト専用キーペアリソースを作成、更新、削除します。名前やタグなどのキーペア情報はプロジェクトの `inputs` ディレクトリのファイルで提供され、公開鍵情報は作成した CloudFormation スタックのエクスポートされた値から使用されます。テストデータをコントラクトテストに渡す方法に関する詳細は、[Specifying input data for use in contract tests](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/resource-type-test.html#resource-type-test-input-data) をご参照ください。

::alert[コントラクトテストでは実際の API 呼び出しを行います。関連する環境認証情報または Boto3 認証情報チェーンからの関連する認証情報を使用するよう、テスト用 AWS アカウントを指す設定がされていることを確認します。]{type="info"}

まず、テストに使用する SSH キーペアを生成しましょう。マシンで新しいターミナルコンソールを開き、`AWSSamples::EC2::ImportKeyPair` プロジェクトディレクトリパスの外にある既存、または新しいディレクトリを選択します。準備ができたら、選択または作成したディレクトリに変更し、`ssh-keygen` コマンドで SSH キーペアを作成します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
ssh-keygen -t rsa -C "Example key pair for testing" -f example-key-pair-for-testing
:::

プロンプトに従い、キーペアの作成を完了します。これで、選択したディレクトリに `example-key-pair-for-testing` と `example-key-pair-for-testing.pub` の 2 つのファイルがあるはずです。前者は秘密鍵で、後者は公開鍵の部分です。次の手順では、必要に応じて公開鍵ファイルを開き、その内容をクリップボードにコピーしてコマンドラインに貼り付けて、内容を指定する必要があります。

次に、入力する公開鍵データを含む [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/systems-manager-parameter-store.html) リソースを作成する CloudFormation スタックを作成します。コントラクトテストでは、このスタックの `KeyPairPublicKeyForContractTests` [エクスポートされたスタック出力値](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-stack-exports.html) が使用されます。次に、サンプルリソースタイプの `inputs` ディレクトリにある入力ファイルには、スタックからエクスポートされた値への `{{KeyPairPublicKeyForContractTests}}` 参照が含まれています。

準備ができたら、サンプルリソースタイプをクローン、またはダウンロードしたターミナルに戻り、`aws-cloudformation-samples/resource-types/awssamples-ec2-importkeypair/python/` ディレクトリにいることを確認します。次のコマンドでは、`examples/example-template-contract-tests-input.yaml` サンプルテンプレートファイルを使用して新しいスタックを作成します。テンプレートでは `KeyPairPublicKey` 入力パラメーターを指定する必要があり、前述のようにコンテンツを指定する必要があります。テンプレートには `OrganizationName` と `OrganizationBusinessUnitName` も必要です。これらはそれぞれ `ExampleOrganization` と `ExampleBusinessUnit` というサンプルデフォルト値で設定されており、値を指定しない場合に使用されます。次に示すように、公開鍵ファイルのコンテンツ用のプレースホルダーを使用してスタックを作成します。このスタックには、公開鍵ファイルの内容をコピーして貼り付ける必要があります (この例では、AWS リージョンに `us-east-1` を使用していますが、必要に応じてこの値を変更してください)。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
    --region us-east-1 \
    --stack-name example-for-key-pair-contract-tests \
    --template-body file://examples/example-template-contract-tests-input.yaml \
    --parameters ParameterKey=KeyPairPublicKey,ParameterValue='PASTE_CONTENT_OF_example-key-pair-for-testing.pub'
:::

CloudFormation コンソールまたは AWS CLI の [stack-create-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-create-complete.html) 待機コマンドを使用して、`example-for-key-pair-contract-tests` スタックが作成されるまで待ってください (この例では、AWS リージョンに `us-east-1` を使用しています)。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-create-complete \
    --region us-east-1 \
    --stack-name example-for-key-pair-contract-tests
:::

次に、マシン上で 2 つのターミナルコンソールを開きます。それぞれで、`AWSSamples::EC2::ImportKeyPair` サンプルリソースタイププロジェクトのルートレベルにいることを確認してください。

* 最初のターミナルコンソールで、Docker がマシン上で実行されていることを確認し、`sam local start-lambda` を実行します
* 2 つ目のターミナルコンソールで、コントラクトテストを実行します: `cfn generate && cfn submit --dry-run && cfn test`

各ハンドラーのコントラクトテスト (`contract_create_create`、`contract_create_read` など) の詳細については、[Contract tests](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/contract-tests.html) をご参照ください。

このプロセスが終了すると、コントラクトテストの結果を示す出力が表示されます。次のステップに進みましょう！

#### リソースタイプをプライベート拡張として登録する

CloudFormation CLI を使用して CloudFormation アカウントのレジストリにリソースを登録してみましょう (この例では、AWS リージョンに `us-east-1` を使用しています)。

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn generate && cfn submit --set-default --region us-east-1
:::

登録が完了するまでお待ちください。その後、`AWSSamples::EC2::ImportKeyPair` サンプルリソースタイプがプライベート拡張としてアカウントに登録されているはずです。確認するには、CloudFormation コンソールで *Activated extensions* を選択し、次に *Privately registered* を選択します。

次に、サンプルリソースタイプをテストしてみましょう。サンプルテンプレートは、クローンまたはダウンロードしたリポジトリに `examples/example-template-import-keypair.yaml` として提供されています。任意のテキストエディターでファイルを開くと、サンプルリソースタイプが `Resources` セクションでどのように参照されているかがわかります。`KeyPairPublicKey` には、コントラクトテストに使用したのと同じ公開鍵の内容を指定します。テンプレートでは、ユーザーが独自の値を指定しない限り、`KeyPairName`、`OrganizationName`、`OrganizationBusinessUnitName` のデフォルト値が使用されます。スタックの作成を選択します (この例では、AWS リージョンに `us-east-1` を使用しています)。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
    --region us-east-1 \
    --stack-name example-key-pair-stack \
    --template-body file://examples/example-template-import-keypair.yaml \
    --parameters ParameterKey=KeyPairPublicKey,ParameterValue='PASTE_CONTENT_OF_example-key-pair-for-testing.pub'
:::

スタックの作成が完了するまで待ってください。その後、CloudFormation を使用してサンプルキーペアとサンプル `AWSSamples::EC2::ImportKeyPair` リソースタイプ (この例では AWS リージョンに `us-east-1` を使用しています) を正常にインポートできたはずです。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-create-complete \
    --region us-east-1 \
    --stack-name example-key-pair-stack
:::

### チャレンジ

##### コンテキスト

コントラクトテストの一環として、[`sam local invoke`](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/resource-type-test.html#manual-testing) コマンドを使用してハンドラーの呼び出しを発行する、[リソースタイプを手動でテストする](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/resource-type-test.html#manual-testing)オプションもあります。テストを手動で実行するには:

* このラボで先ほど行ったように、1 つのターミナルで (サンプルリソースタイプの `python` ディレクトリ内から) `sam local start-lambda` を実行します。
* 別のターミナルで、例えば、`sam local invoke TestEntrypoint --event sam-tests/YOUR_INPUT_FILE` を使用してハンドラーを呼び出します。ここで `YOUR_INPUT_FILE` は JSON 形式のファイルで、その構造は[こちら](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/resource-type-test.html#manual-testing)に記載されています。プロジェクトのルートレベルの `sam-tests` ディレクトリに保存します。

::alert[`sam-tests` ディレクトリで作成および編集するファイルには、認証情報が含まれている場合があります。`sam-tests/` の場所は、ソースコードリポジトリに追加されないように、`.gitignore` ファイル (このラボで使用したサンプルリソースタイプのプロジェクトのルートレベルにあるファイル) に追加する必要があります。セットアップによっては、`sam-tests` ディレクトリのファイルに認証情報を追加する必要がある場合と不要な場合があります。]{type="info"}

##### チャレンジ

`sam-tests/example-read.json` ファイルを作成して `AWSSamples::EC2::ImportKeyPair` サンプルリソースタイプの *read* ハンドラーをテストします。入力例として、先ほど `example-key-pair-stack` スタックで作成したキーペアを選択します。期待される出力は、サンプル リソース タイプの *read* ハンドラーが最初にフェッチし、返すモデルのプロパティを含むデータ構造です。

:::expand{header="ヒントが必要ですか?"}
* Python の [UUID](https://docs.python.org/3/library/uuid.html) モジュールを使用して `UUID4` 値を生成して `clientRequestToken` に渡します。
* Resource type handler contract に関する [ページ](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/resource-type-test-contract.html) の [Read handlers](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/resource-type-test-contract.html#resource-type-test-contract-read) セクションから、*Input assumptions* の内容を読んで、JSON 構造の `desiredResourceState` キーの下に、入力として渡すキーと値を決定します。
* リソースの論理識別子には、`MyExampleResource` などのサンプル値を使用します。
:::

:::expand{header="解決策を確認しますか?"}
* [ここに](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/resource-type-test.html#manual-testing)記載されている構造を使用し、`sam-tests/example-read.json` ファイルを作成します。
* Python コマンドラインインターフェイスから、次の例のように `UUID4` 値を生成します。

```shell
>>> import uuid
>>> uuid.uuid4()
UUID('OUTPUT EDITED: THIS WILL CONTAIN A UUID4 VALUE')
```

* 作成した `example-key-pair-stack` CloudFormation スタックの `Outputs` セクションから、`KeyPairId` の値を使用し、それを JSON ファイルの構造内の `desiredResourceState` キーの下に作成した新しい `KeyPairId` キーに渡します。
* 結果のファイル構造は、次の例のようになるはずです。

```json
{
  "credentials": {
    "accessKeyId": "",
    "secretAccessKey": "",
    "sessionToken": ""
  },
  "action": "READ",
  "request": {
    "clientRequestToken": "REPLACE_WITH_YOUR_UUID4_VALUE_HERE",
    "desiredResourceState": {
      "KeyPairId": "REPLACE_WITH_THE_KEYPAIR_ID"
    },
    "logicalResourceIdentifier": "MyExampleResource"
  },
    "callbackContext": {}
}
```

* `sam local invoke TestEntrypoint --event sam-tests/example-read.json` サンプルテストファイルを実行します。出力として、*read* ハンドラーから返されたリソースプロパティ値を含む `resourceModel` セクションが表示されます。
:::

### クリーンアップ

作成したリソースをクリーンアップする手順は、次の通りです (選択した AWS リージョンを `us-east-1` とします)。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack \
    --region us-east-1 \
    --stack-name example-key-pair-stack

aws cloudformation wait stack-delete-complete \
    --region us-east-1 \
    --stack-name example-key-pair-stack

aws cloudformation delete-stack \
    --region us-east-1 \
    --stack-name example-for-key-pair-contract-tests

aws cloudformation wait stack-delete-complete \
    --region us-east-1 \
    --stack-name example-for-key-pair-contract-tests

aws cloudformation deregister-type \
    --region us-east-1 \
    --type-name AWSSamples::EC2::ImportKeyPair \
    --type RESOURCE
:::

### まとめ

おめでとうございます! Python でのサンプルリソースタイプ実装を一通り実施し、リソースタイプを作成する際に留意すべき重要な概念、期待される事項、目的を学びました。
