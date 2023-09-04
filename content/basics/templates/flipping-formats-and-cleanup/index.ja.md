---
title: "フォーマット変換とクリーンアップ"
weight: 1000
---

### 概要
AWS CloudFormation [テンプレート](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/template-formats.html) は JSON 形式または YAML 形式で記述できます。好みに応じてどちらかを選択できます。詳細については、[AWS CloudFormation テンプレート形式](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/template-formats.html) を参照してください。

このラボでは、JSON 形式のテンプレートから YAML 形式への切り替えの例を見ていきます。このタスクを簡単に実行するため [cfn-flip](https://github.com/awslabs/aws-cfn-template-flip) というツールを使用できます。また、`cfn-flip` を使用して、サンプルテンプレートの独自のクリーンアップアクションを実行します。

### カバーするトピック
このラボを修了すると、`cfn-flip` を使用して以下のことができるようになります。

* JSON 形式から YAML 形式への切り替え、およびその逆も可能です。
* サンプルテンプレートに対して独自のクリーンアップアクションを実行できます。

### ラボの開始
`pip` で `cfn-flip` を [インストール](https://github.com/awslabs/aws-cfn-template-flip#installation)します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
pip install cfn-flip
:::

または、macOS では [Homebrew](https://brew.sh/) を使っている場合は以下の通りにインストールできます。

:::code{language=shell showLineNumbers=false showCopyAction=true}
brew install cfn-flip
:::

インストールが完了したら、以下のコマンドを実行して `cfn-flip` を実行できることを確認します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-flip --version
:::

それでは、JSON 形式のテンプレート例を YAML に変換してみましょう。以下の手順に沿って、このラボで使用するテンプレートを特定してください。
1. `code/workspace/flipping-formats-and-cleanup` ディレクトリに移動します。
1. お気に入りのテキストエディターで `example_parameter.json` CloudFormation テンプレートを開きます。
1. `example_parameter.json` ファイルの内容を確認します。このテンプレートは、[AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/systems-manager-parameter-store.html) パラメータの `AWS::SSM::Parameter` リソースタイプを記述しています。このサンプルテンプレートに対して以下の作業を行います。
   - [Ref](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-ref.html) 組み込み関数を使用して、テンプレートの `ParameterValue` 入力パラメータを参照することにより、Parameter Store パラメータに保存する値を指定します。このテンプレートからスタックを作成するときは、指定した値を `ParameterValue` への入力として渡します。
   - `Ref` を使用して、パラメータストアパラメータに割り当てたい名前を参照します。この名前は、テンプレートからスタックを作成するときに `ParameterName` テンプレートパラメータで指定できます。
   - Parameter Store パラメータに説明を追加します。今回は、[Fn::Join](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-join.html) 組込み関数を使用して文字列の断片を結合します。文字列の断片には、パラメータストアパラメータの名前への参照が含まれます。サンプルテンプレートでは、_delimiter_ に示されているように、`" "` 文字列の断片はスペースで区切られています。`Fn::Join` 関数の 1 つ目の[パラメータ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-join.html#intrinsic-function-reference-join-parameters)です。

::alert[`Fn::Sub` [組み込み関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-sub.html) でも文字列を結合することもできます。このラボの後半では、`cfn-flip` を使用して `Fn::Join` 関数の宣言を `Fn::Sub` に変換する方法を紹介します。]{type="info"}

次にサンプルテンプレートの抜粋で学習したポイントに焦点を当てて要約します。

:::code{language=json showLineNumbers=false showCopyAction=false}
[...]
    "Parameters": {
        "ParameterName": {
            "Description": "Name you wish to specify for your SSM Parameter.",
[...]
        },
        "ParameterValue": {
            "Description": "Value you wish to specify for your SSM Parameter.",
[...]
        }
    },
    "Resources": {
        "MyParameter": {
            "Type": "AWS::SSM::Parameter",
            "Properties": {
                "Name": {
                    "Ref": "ParameterName"
                },
                "Type": "String",
                "Value": {
                    "Ref": "ParameterValue"
                },
                "Description": {
                    "Fn::Join": [
                        " ",
                        [
                            "My",
                            {
                                "Ref": "ParameterName"
                            },
                            "example parameter"
                        ]
[...]
:::

次に、`cfn-flip` を使用してテンプレートを JSON 形式から YAML 形式に変換します。JSON 形式の `example_parameter.json` テンプレートが置かれているディレクトリから次のコマンドを実行します。

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-flip example_parameter.json example_parameter.yaml
:::

::alert[`cfn-flip` ツールは入力テンプレートのフォーマット (この場合は JSON) を自動的に検出し、それに応じて反対の出力フォーマット (この例では YAML) に変換します。`cfn-flip` に YAML または JSON に変換するように明示的に指示するには、それぞれ `-y` (または `--yaml`) オプションか `-j` (または `--json`) オプションを指定してください。`cfn-flip` は入力テンプレートの形式が逆の形式であることを仮定します。詳細については、コマンドラインから `cfn-flip --help` を実行してください。]{type="info"}

実行の結果として、同じディレクトリに `example_parameter.yaml` という名前の新しいテンプレートが作成されたはずです。お気に入りのテキストエディタでテンプレートを開きます。`cfn-flip` で YAML に変換した要素を確認できますか？

以下の例は `example_parameter.yaml` テンプレートからの抜粋です。JSON 形式のテンプレートで見た `Fn::Join` 組込み関数が、YAML の短縮形である `!Join` に変換されたとわかります。`cfn-flip` が可能な限り[短縮形式の関数宣言を使用する](https://github.com/awslabs/aws-cfn-template-flip#about)仕様だからです。

:::code{language=yaml showLineNumbers=false showCopyAction=false}
[...]
Parameters:
  ParameterName:
    Description: Name you wish to specify for your SSM Parameter.
[...]
  ParameterValue:
    Description: Value you wish to specify for your SSM Parameter.
[...]
Resources:
  MyParameter:
    Type: AWS::SSM::Parameter
    Properties:
      Name: !Ref 'ParameterName'
      Type: String
      Value: !Ref 'ParameterValue'
      Description: !Join
        - ' '
        - - My
          - !Ref 'ParameterName'
          - example parameter
:::

`cfn-flip` を使って、YAML から JSON に変換することもできます。詳細またはその他の `cfn-flip` の機能を確認するには、以下のコマンドを実行してください。

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-flip --help
:::

::alert[テンプレートを YAML 形式で記述する場合、行の先頭に `#` 文字を使用することにより、テンプレートにコメントを記述することができます。`cfn-flip` を使用して YAML から JSON に変換すると、YAML のコメントは JSON 形式の出力テンプレートに追加されません。JSON がコメントの記述をサポートしていないからです (詳細は、<https://json.org> をご参照ください)。]{type="info"}

おめでとうございます!これで、CloudFormation テンプレートを JSON 形式から YAML 形式に変換し、その他の `cfn-flip` 機能を見つける方法も学びました。

### チャレンジ
`cfn-flip` ツールを使うと、[Fn::Join](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-join.html) 組み込み関数から [Fn::Sub](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-sub.html) への変換など、テンプレートに対して独自のクリーンアップアクションを実行することもできます。このラボセクションでは、先ほど JSON 形式から変換した `example_parameter.yaml` テンプレートでこの機能を使用することとします。

このチャレンジは、`example_parameter.yaml` テンプレートに対して独自のクリーンアップアクションを実行し、クリーンアップしたテンプレートの出力をワークスペースの `example_parameter_updated.yaml` という新しいファイルに保存することに挑戦します。出力テンプレートを JSON に変換するのではなく、同じ YAML 形式を維持する必要があることに注目してください。

まず `cfn-flip` に渡す必要のあるオプションを見つけてから、入力テンプレートに対して `cfn-flip` を実行し、出力テンプレートが `Fn::Join` 組み込み関数の短縮形式ではなく `Fn::Sub`　組み込み関数の短縮形式を使用していることを確認します。

::expand[`cfn-flip --help` と入力して `cfn-flip` の使い方を表示すると、そのタスクに使いたい 2 つのオプションが分かります。この 2 つのオプションはどれですか？]{header="ヒントが必要ですか？"}

:::expand{header="解決策を確認しますか？"}
同じフォーマット (この場合は YAML) を維持したり、独自のクリーンアップアクションを実行したりするには、`cfn-flip` に `-n -c` (または `--no-flip --clean`) の 2 つのオプションを使用してください。ワークスペースで以下のコマンドを実行します。
::code[cfn-flip -n -c example_parameter.yaml example_parameter_updated.yaml]{language=shell showLineNumbers=false showCopyAction=true}

できあがった `example_parameter_updated.yaml` テンプレートをお気に入りのテキストエディタで開きます。次のテンプレートの抜粋に示されているように、`!Join` (短縮形式) の代わりに `!Sub` (短縮形式) が使用されていることがわかります。
::code[Description: !Sub 'My ${ParameterName} example parameter']{language=yaml showLineNumbers=false showCopyAction=true}
:::

---
### まとめ

素晴らしいです！`cfn-flip` を使用して JSON 形式の CloudFormation テンプレートを YAML 形式に変換する方法 (とその逆)、および特定のテンプレートに対して独自のクリーンアップアクションを実行する方法を学びました。
