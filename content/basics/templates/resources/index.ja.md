---
title: "リソース"
weight: 300
---

_ラボ実施時間 : 10分程度_

---

### 概要

このラボでは、CloudFormation の最上位の要素 (形式バージョン、説明、メタデータ、パラメータ、リソース) について学んでいきます。

### カバーされるトピック
このラボを完了すると、以下のことができるようになります。

+ CloudFormation テンプレートの構造といくつかのセクションについての理解。
+ CloudFormation で EC2 インスタンスのデプロイ。
+ SSM パラメータストアから最新の Linux AMI ID の取得。

### ラボの開始

::alert[各セクションに、サンプルコードが最後に記載されています。コードをご自身のテンプレートにコピーしてください。]{type="info"}

1. `code/workspace/` ディレクトリへ移動します。
1. `resources.yaml` ファイルを開きます。
1. 以下のトピックを進みながら、コードをコピーしていきます。

#### 形式バージョン
_AWSTemplateFormatVersion_ セクションは、テンプレートの機能を識別します。最新のテンプレートの形式バージョンは _2010-09-09_ であり、現時点で唯一の有効な値です。

:::code{language=yaml showLineNumbers=false showCopyAction=true}
AWSTemplateFormatVersion: "2010-09-09"
:::

#### 説明
_Description_ セクションには、テンプレートに関するコメントを含めることができます。

:::code{language=yaml showLineNumbers=false showCopyAction=true}
Description: AWS CloudFormation workshop - Resources (uksb-1q9p31idr) (tag:resources).
:::

#### メタデータ
[_Metadata_ セクション](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/metadata-section-structure.html)を使用して、任意の JSON または YAML オブジェクトを含めることができます。このセクションは、CloudFormation テンプレートと相互作用する他のツールへ情報を提供するのに役立ちます。例えば、AWS コンソールから CloudFormation テンプレートをデプロイするときに、パラメータのソート順やラベル、グループ化の方法を指定することでデプロイするユーザのユーザエクスペリエンスを向上することができます。この場合は [_AWS::CloudFormation::Interface_](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-cloudformation-interface.html) キーで実現できます。

```yaml
Metadata:
  AWS::CloudFormation::Interface:
    ParameterGroups:
      - Label:
          default: 'Amazon EC2 Configuration'
        Parameters:
          - InstanceType
    ParameterLabels:
      InstanceType:
        default: 'Type of EC2 Instance'
```

#### パラメータ
_Parameters_ セクションを使用すると、スタックを作成または更新する時にテンプレートにカスタム値を入力できます。

AWS CloudFormation は次のパラメータタイプをサポートします。

| Type                                                                                                                                                          | Description                                                                           | Example                                             |
|---------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------|-----------------------------------------------------|
| _String_                                                                                                                                                      | リテラル文字列                                                                     | "MyUserName"                                        |
| _Number_                                                                                                                                                      | 整数または浮動小数点値                                                                  | "123"                                               |
| _List\<Number\>_                                                                                                                                              | カンマ区切りの整数または浮動小数点値の配列                                                       | "10,20,30"                                          |
| _CommaDelimitedList_                                                                                                                                          | カンマ区切りのリテラル文字列の配列                                                          | "test,dev,prod"                                     |
| [AWS 固有のパラメータタイプ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html#aws-specific-parameter-types) | VPC の ID などの AWS の値です                                                    | _AWS::EC2::VPC::Id_                                 |
| [SSM パラメータタイプ](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html#aws-ssm-parameter-types)               | Systems Manager パラメータストアに存在するパラメータを参照するパラメータ | _AWS::SSM::Parameter::Value\<AWS::EC2::Image::Id\>_ |

```yaml
Parameters:
  InstanceType:
    Type: String
    Default: t2.micro
    AllowedValues:
      - t2.micro
      - t2.small
    Description: 'Enter t2.micro or t2.small. Default is t2.micro.'
```

#### リソース
必須である _Resources_ セクションでは、スタックに含める AWS リソースを宣言します。ここで EC2 リソースをスタックに追加してみましょう。

```yaml
Resources:
  WebServerInstance:
    Type: 'AWS::EC2::Instance'
    Properties:
      InstanceType: !Ref InstanceType
      ImageId: <AMI ID ami-xxxxx に置き換えてください>
```

EC2 リソースタイプの唯一の必須プロパティは _ImageId_ です。 AWS コンソールから AMI ID を見つけてみましょう。

  1. **[AWS EC2 console](https://console.aws.amazon.com/ec2)** を開きます。
  2. **インスタンス** -> **インスタンスを起動** をクリックします。
  3. **Amazon Linux 2023 AMI** `ami-xxxxxxxxx` の ID をコピーします。
  ::alert[x86 と Arm アーキテクチャを選択できるリージョンの場合、必ず **64-bit (x86)** AMI ID を使うようにしてください。]{type="info"}
  4. AMI ID が見つかったら、コピーして **ImageId** プロパティに貼り付けます。

::alert[**米国東部 (バージニア北部) リージョン** の場合の解答を `code/solutions/resources.yaml` ファイルで見ることができます。]{type="info"}

これで EC2 テンプレートをデプロイする準備が整いました。[テンプレートとスタック](../template-and-stack) で実施した時と同様の方法でデプロイを行います。

:::alert{type="warning"}
これ以降のラボを実施するためには、CloudFormation をデプロイするリージョンに **デフォルト VPC** が必要です。もしデフォルト VPC を削除していた場合、**[デフォルトの VPC を作成する](https://docs.aws.amazon.com/ja_jp/vpc/latest/userguide/default-vpc.html#create-default-vpc)** の AWS ドキュメントに沿って新しいデフォルト VPC を作成できます。
:::

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. **Cloud9 のターミナル** で `code/workspace` に移動します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace
:::
1. AWS CLI でスタックを作成します。必要な `--stack-name`、`--template-body` パラメータがあらかじめ設定されています。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack --stack-name cfn-workshop-resources --template-body file://resources.yaml
:::
1. `create-stack` コマンドが正常に送信されたら、CloudFormation が `StackId` を返します。
:::code{language=shell showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-resources/62df5090-e747-11ed-a22a-0e39ed6c0e49"
:::
1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** のコンソールを新しいタブで開き、スタックが **CREATE_COMPLETE** ステータスになるまで待ちます。必要に応じて、リフレッシュボタンをクリックします。
::::

::::tab{id="local" label="ローカル開発"}
1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** のリンクを新しいタブで開き、必要に応じて AWS アカウントにログインします。
1. 画面右上の **スタックの作成** をクリックし、**新しいリソースを使用 (標準)** をクリックしてください。
1. **テンプレートの準備** では、**テンプレートの準備完了** を選びます。
1. **テンプレートの指定** では、**テンプレートファイルのアップロード** を選びます。
1. **ファイルの選択** をクリックして、作業ディレクトリに移動します。
1. `resources.yaml` ファイルを指定し、**次へ** をクリックします。
1. **スタックの名前** (例: `cfn-workshop-resources`) を入力します。
    + _スタックの名前_ はスタックを識別します。スタックの目的がわかるような名前を使ってください。
1. **Type of EC2 Instance** には、お好みのインスタンスサイズ (例: **t2.micro**) を選択し、**次へ** をクリックします。
1. **スタックオプションの設定** はデフォルトの設定のままとし、**次へ** をクリックします。
1. **レビュー <スタック名>** のページで、ページの下部までスクロールし、**送信** をクリックします。
    ::alert[これによりお使いのアカウントに EC2 インスタンスが作成されます。デプロイされたスタックのコストを確認するためには、レビューページの **予想コスト** をクリックして、ご確認ください。]{type="info"}
1. スタックが **CREATE_COMPLETE** ステータスになるまで待ちます。必要に応じて、リフレッシュボタンをクリックします。
::::
:::::

### チャレンジ

この練習問題では、AWS CLI を使って、AWS Systems Manager パラメータストアから最新の Amazon Linux AMI ID を取得します。

::alert[このチャレンジを完了するには、[AWS CLI](../../../prerequisites/local-development) が完了していることをご確認ください。Cloud9 環境には最初からインストールされています。]{type="info"}

::expand[[Amazon Web Services ブログ](https://aws.amazon.com/jp/blogs/news/query-for-the-latest-amazon-linux-ami-ids-using-aws-systems-manager-parameter-store/) を確認してみてください。]{header="ヒントが必要ですか？"}

::::expand{header="解決策を確認しますか？"}
ターミナルに以下のコードをコピーします。CloudFormation をデプロイするリージョンにあわせて `--region` フラグを変更するようにしてください。

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws ssm get-parameters \
    --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 \
    --query "Parameters[].Value" \
    --region us-east-1 \
    --output text
:::
::::

### クリーンアップ

以下の手順で作成したリソースの削除を行います。

1. **[CloudFormation コンソール](https://console.aws.amazon.com/cloudformation)** に移動します。
1. CloudFormation の **スタック** ページで `cfn-workshop-resources` を選択します。
1. スタックの詳細で **削除** を選択し、ポップアップ上で **削除** で確定します。
1. スタックが **DELETE_COMPLETE** ステータスになるまで待ちます。必要に応じて、リフレッシュボタンをクリックします。

---

### まとめ
おめでとうございます！これで無事に CloudFormation を使って EC2 インスタンスをデプロイする方法について学習できました。
