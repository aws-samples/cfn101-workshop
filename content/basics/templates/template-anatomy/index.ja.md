---
title: "テンプレートの構造"
weight: 100
---

### テンプレート

**AWS CloudFormation テンプレート** は **スタック** を構成する AWS リソースの宣言です。テンプレートは JavaScript Object Notation (JSON) または YAML 形式のテキストファイルとして保存します。一般的なテキストファイルであるため、任意のテキストエディタでの作成や編集、他のソースコードと一緒にバージョン管理システムでの管理などが可能です。

:::alert{type="info"}
このワークショップでは、サンプルコードとして YAML 形式を使用します。JSON を使う場合には、[形式による差異](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/template-formats.html) があることにご注意ください。
:::

次の例では、AWS CloudFormation の YAML のテンプレートの構造と最上位のセクションを紹介します。

:::code{language=yaml showLineNumbers=false showCopyAction=false}
AWSTemplateFormatVersion: 'バージョン日付' (任意) # CloudFormation テンプレート形式のバージョン。 '2010-09-09' のみ指定可能

Description: '文字列' (任意) # Cloudformation テンプレートを説明するテキスト

Metadata: 'テンプレートメタデータ' (任意) # テンプレートに関する追加情報を提供するオブジェクト

Parameters: 'パラメータのセット' (任意) # テンプレートをカスタマイズするための入力値

Rules: 'ルールのセット' (任意) # デプロイ・更新時にパラメータまたはパラメータの組み合わせの検証ルール

Mappings: 'マッピングのセット' (任意) # キーとバリューのマッピング

Conditions: '条件のセット' (任意) # 特定のリソースの作成の有無を制御する条件

Transform: 'トランスフォームのセット' (任意) # サーバレスアプリケーション向けの宣言

Resources: 'リソースのセット' (必須) # インフラストラクチャのコンポーネント

Hooks: 'フックのセット' (任意) # ECS の Blue/Green デプロイに利用

Outputs: '出力のセット' (任意) # スタックのプロパティで確認できる出力値
:::

最上位のセクションで唯一必要なのは　**Resources** セクションだけで、少なくとも 1 つのリソースの宣言が必要です。これらのセクションの定義については、[テンプレートの分析](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/template-anatomy.html) のガイドで確認することができます。

### スタック

スタックは CloudFormation テンプレートをデプロイしたものになります。1 つの CloudFormation テンプレートから複数のスタックを作成できます。スタックは一連の AWS リソースの集合を含み、単一のユニットとして管理できます。スタック内のすべてのリソースは、スタックの AWS CloudFormation テンプレートで定義されています。

AWS CloudFormation は全体としてスタックの作成、更新、削除を行います。
  * 全体としてスタックが作成、または更新できない場合、AWS CloudFormation はロールバックを行い、その操作で作成されたリソースをすべて自動的に削除します。
  * リソースを削除できなかった場合、スタックの削除に成功するまでに、それらのリソースを保持します。

![cfn-stack](/static/basics/templates/template-anatomy/cfn-stack.png)
