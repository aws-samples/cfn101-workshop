---
title: "モジュール"
weight: 300
---

### はじめに

この章では、開発したモジュールを使用して [AWS CloudFormtaion](https://aws.amazon.com/jp/cloudformation/) の作成、プロビジョニング、管理に関する機能を拡張する方法に焦点を当てます。

これまでは、CloudFormation を使用して AWS が公開しているリソースタイプを使用してアプリケーションを構築する方法を見てきました。このラボでは、[AWS CloudFormation モジュール](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/modules.html)を活用し、同じ AWS アカウントとリージョンを利用するユーザーが何度も使用できる再利用可能なテンプレートスニペットを作成します。

CloudFormation モジュールの一般的な使用例は、企業内での利用の際、企業固有であったり、独自のロジックを含んだベストプラクティスや一般的な構成コンポーネントを体系化することです。

モジュールは CloudFormation の第一級オブジェクトです。CloudFormation では、あらゆる AWS リソースを管理するのと同様にモジュールを管理できます。モジュールのソフトウェア開発ライフサイクル (SDLC) プロセスは次のように要約できます。

1. モジュールの開発とテストの利用に必要なツールをインストールします。
2. モジュールの開発を開始します。
3. 準備ができたら、モジュールを [AWS CloudFormtaion レジストリ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/registry.html) に送信します。
4. CloudFormation を使用してモジュールを管理します。他の AWS リソースタイプと同様に、CloudFormation テンプレートにモジュールとそのプロパティを記述します。

::alert[モジュールを CloudFormation レジストリにプライベート拡張として登録するか、パブリック拡張として登録するかを選択できます。このラボでは、プライベート拡張の例を取り上げます。]{type="info"}

プライベート拡張を登録すると、AWS アカウントの AWS CloudFormation レジストリで利用できるようになります。プライベート拡張を使用すると、お客様が所有し、テストや実験に使用している AWS アカウントなどのサンドボックス環境でリソースタイプの動作をテストできます。

必要に応じて、モジュールを、他の [AWS CloudFormation StackSets を使用する AWS リージョン](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/publish-extension-stacksets.html)にデプロイすることができます。

プライベート拡張の詳細については、[CloudFormation でのプライベートエクステンションの使用](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/registry-private.html) をご参照ください。パブリック拡張については、[Publishing extensions to make them available for public use](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/publish-extension.html) をご参照ください。

::alert[モジュールの使用には追加料金はありません。お支払いいただくのは、モジュールがスタック内で作成するリソース分のみです。]{type="info"}

::alert[スタックで許可される最大リソース数やテンプレート本体の最大サイズなどの CloudFormation のクォータは、そのテンプレートに含まれるリソースがモジュールからのものであるかどうかにかかわらず、処理されたテンプレートに適用されます。]{type="info"}

### モジュールの構造

モジュールは次の 2 つの主要部分で構成されています。

* [テンプレートフラグメント](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/modules-structure.html#modules-template-fragment)。定義したモジュールパラメータを含め、モジュールを使用してプロビジョニングするリソースと関連情報を定義します。
* テンプレートフラグメントに基づいて生成される[モジュールスキーマ](https://docs.aws.amazon.com/ja_jp/cloudformation-cli/latest/userguide/modules-structure.html#modules-schema)。モジュールスキーマは、テンプレートフラグメントで定義したコントラクトを宣言し、CloudFormation レジストリ内のユーザーに表示します。
