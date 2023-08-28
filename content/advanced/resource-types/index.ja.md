---
title: "リソースタイプ"
weight: 300
---

### はじめに

この章では、開発したリソースタイプを使用して [AWS CloudFormation](https://aws.amazon.com/jp/cloudformation/) の作成、プロビジョニング、管理に関する機能を拡張する方法に焦点を当てます。

リソースタイプは CloudFormation の第一級オブジェクトです。CloudFormation では、他の AWS リソースを管理するのと同様にリソースを管理できます。リソースタイプのソフトウェア開発ライフサイクル (SDLC) プロセスは次のように要約できます。

1. リソースタイプの開発とテストに使用する前提条件となるツールをインストールします。
2. リソースタイプの開発と必要なテストを実施します。
3. 準備ができたら、リソースタイプを [AWS CloudFormation レジストリ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/registry.html)に登録します。
4. CloudFormation を使用してリソースタイプを管理します。他の AWS リソースタイプと同様に、CloudFormation テンプレートにリソースタイプとプロパティを記述します。

::alert[CloudFormation レジストリでは、リソースタイプをプライベート拡張として登録するか、パブリック拡張として登録するかを選択できます。このラボでは、プライベート拡張の例を取り上げます。]{type="info"}

プライベート拡張を登録するとすると、AWS アカウント内の AWS CloudFormation レジストリで使用できるようになります。プライベート拡張を使用すると、テストや検証に使用している AWS アカウント等のサンドボックス環境でリソースタイプの動作をテストできます。プライベート拡張のもう1つの使用例は、企業内で使用されるプライベート/カスタムアプリケーションのコンポーネントをコード化する場合です。これらのコンポーネントは、企業固有のものであったり、独自のロジックを含んでいます。

必要に応じて、リソースタイプを、他の [AWS CloudFormation StackSets を使用する AWS リージョン](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/publish-extension-stacksets.html)にデプロイすることができます。

プライベート拡張の詳細については、[CloudFormationでのプライベートエクステンションの使用](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/registry-private.html)をご参照ください。パブリック拡張については、[Publishing extensions to make them available for public use](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/publish-extension.html) をご参照ください。

::alert[サードパーティの発行元が提供するプライベート拡張やアクティベートされたパブリック拡張を使用する場合のアカウントへの料金については、[AWS CloudFormation の料金](https://aws.amazon.com/jp/cloudformation/pricing/) をご参照ください。これらの料金は、作成したリソースに対して発生する料金に加算されます。]{type="info"}

### キーコンセプト

リソースタイプを開発する際のキーコンセプトは次のとおりです。

* [スキーマ](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/resource-type-schema.html): ユーザーが入力値を指定できるプロパティや、リソース作成後にのみ使用可能になる読み取り専用プロパティ (リソース ID 等) など、リソースの仕様を記述するドキュメントです。
* [ハンドラ](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/resource-type-develop.html#resource-type-develop-implement-handlers): リソースタイプを開発するときは、作成、参照、更新、削除、リスト (CRUDL) 操作に関するライフサイクルを、[サポートされた言語](https://github.com/aws-cloudformation/cloudformation-cli#supported-plugins)で実装します。コードには、上記の CRUDL ハンドラー (*create* ハンドラー、*update* ハンドラー等) のリソースタイプに必要な動作 (特定の操作を実行するために呼び出す AWS またはサードパーティ API など) を記述します。
