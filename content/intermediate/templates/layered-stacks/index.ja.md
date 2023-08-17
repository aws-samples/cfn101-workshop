---
title: "階層化されたスタック"
weight: 500
---

### 概要
前のラボでは、`Outputs` セクションと `Fn::GetAtt` 関数を使って子スタックから親スタックへ値を渡す方法について学びました。そして、再利用可能なテンプレートを作成することができるようになりました。例えば、ネストされたスタックを利用すると、VPC と IAM ロール専用のテンプレートを用意することができます。
しかし、**スタック** を再利用したい場合はどうでしょうか？

例えば、多数のテンプレートを使用して多数のワークロードをデプロイする計画があったとします。すべての EC2 インスタンスが Systems Manager Session Manager によるすべての EC2 インスタンスへのアクセスを有効にする必要があります。
同様に、1 つのスタックで VPC をデプロイし、それを将来、複数のスタックやワークロードで使用したい場合があります。
このような一対多の関係は、ネストされたスタックのシナリオでは実現できません。
ここで階層化されたスタックの出番です。


私たちは [Export](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-stack-exports.html) を使用し、任意の CloudFormation スタックに [Import](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-importvalue.html) できるグローバル変数を作成します。

### 取り上げるトピック
このラボでは、以下を作成します。

1. **VPC スタック**: 前のラボで使用したものと同じシンプルな VPC テンプレートが含まれていますが、出力に Export が追加されています。
2. **IAM インスタンスロールスタック**: 前のラボで使用したのと同じ IAM インスタンスロールが含まれていますが、出力に Export が追加されています。
3. **EC2 スタック**: 前のラボで定義した EC2 インスタンスが含まれていますが、ここでは Fn::ImportValue 関数を使用します。

> 階層化されたスタックの階層を示す図

![layered-stack-hierarchy.png](/static/intermediate/templates/layered-stacks/layered-stack-hierarchy.ja.png)

> 導入されるインフラストラクチャの概要

![layered-stack-hierarchy.png](/static/intermediate/templates/layered-stacks/ls-architecture.png)

### ラボを開始

作業ファイルは `code/workspace/layered-stacks` にあります。このラボの残りの部分では、テンプレートにコードを追加する必要があります。なお、解決策は `code/solutions/layered-stacks` フォルダにありますので、こちらを参照することも可能です。

#### VPC スタックの作成
VPC テンプレートは既に作成されており、タイトルは `vpc.yaml` です。このテンプレートは、2 つのパブリックサブネット、1 つのインターネットゲートウェイ、および、ルートテーブルを含む VPC スタックを作成することができます。

##### 1. VPC テンプレートの準備

::alert[このラボで参照されているファイルはすべて `code/workspace/layered-stacks` 内にあります。]{type="info"}

`vpc.yaml` ファイルを見ると、テンプレートの **Outputs** セクションにいくつかの出力があることがわかります。次に、Export を追加して、他の CloudFormation スタックから使用できるようにします。

以下の [4-5、9-10、14-15] 行目をテンプレートファイルに追加します。

```yaml {hl_lines=[4,5,9,10,14,15]}
Outputs:
  VpcId:
    Value: !Ref VPC
    Export:
      Name: cfn-workshop-VpcId

  PublicSubnet1:
    Value: !Ref VPCPublicSubnet1
    Export:
      Name: cfn-workshop-PublicSubnet1

  PublicSubnet2:
    Value: !Ref VPCPublicSubnet2
    Export:
      Name: cfn-workshop-PublicSubnet2
```

##### 2. VPC スタックのデプロイ

1. コンソールで CloudFormation に移動し、**新しいリソースを使用 (標準)** をクリックします。
2. **テンプレートの準備**セクションで、**テンプレート準備完了**を選択します。
3. **テンプレートの指定**セクションで、**テンプレートファイルのアップロード**を選択します。
4. `vpc.yaml` ファイルを選択します。
5. **スタック名**を入力します。例えば、`cfn-workshop-vpc` と入力します。
6. **AvaliabilityZone** パラメータには、**2 つの AZ** を選択します。
7. 残りのパラメータは**デフォルト**のままとします。
8. すべてデフォルトのままウィザード内を移動します。
9. レビューページで一番下までスクロールし、**送信**をクリックします。

#### IAM スタックの作成

##### 1. IAM ロールテンプレートの準備

1. `iam.yaml` ファイルを開きます。
2. 以下の [4～5] 行目をテンプレートの **Outputs** セクションにコピーします。
    ```yaml {hl_lines=[4,5]}
    Outputs:
      WebServerInstanceProfile:
        Value: !Ref WebServerInstanceProfile
        Export:
          Name: cfn-workshop-WebServerInstanceProfile
    ```

##### 2. IAM スタックのデプロイ

1. コンソールで CloudFormation に移動し、**新しいリソースを使用 (標準)** をクリックします。
2. **テンプレートの準備**セクションで、**テンプレート準備完了**を選択します。
3. **テンプレートの指定**セクションで、**テンプレートファイルのアップロード**を選択します。
4. `iam.yaml` ファイルを選択します。
5. **スタック名**を入力します。例えば、`cfn-workshop-iam` と入力します。
6. **次へ**をクリックします。
7. すべてデフォルトのままウィザード内を移動します。
8. **Acknowledge IAM capabilities** をクリックし、**送信**をクリックします。

#### EC2 階層化されたスタックの作成

##### 1. EC2 テンプレートの準備
**階層化された Stack** のコンセプトは、**Paramaters** を使用する代わりに、組み込み関数を使用して、以前にエクスポートされた値をインポートすることです。
従って、`ec2.yaml` に最初に加えるべき変更は、今後使用されなくなる `SubnetId`、`VpcID`、`WebServerInstanceProfile` のパラメータを削除することです。


##### 2. Parameters セクションの更新

次の例のような形で、**Parameters** セクションを更新します。
つまり、**Parameters** セクションから、`VpcId`、`SubnetId`、`WebServerInstanceProfile` の項目を削除します。

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

  AmiID:
    Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
    Description: 'The ID of the AMI.'
    Default: /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2
```

##### 3. WebServerInstance リソースの更新

次に、テンプレートの `Ref` を更新して、以前に作成した VPC と IAM スタックからエクスポートされた値をインポートする必要があります。
このインポートは [Fn::ImportValue](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-importvalue.html) 組み込み関数を使用して実行します。

`ec2.yaml` テンプレートのリソースセクションにある WebServerInstance リソースを更新します。

```yaml
WebServerInstance:
  Type: AWS::EC2::Instance
  {...}
  Properties:
    SubnetId: !ImportValue cfn-workshop-PublicSubnet1
    IamInstanceProfile: !ImportValue cfn-workshop-WebServerInstanceProfile
    ImageId: !Ref AmiID
    InstanceType: !FindInMap [EnvironmentToInstanceType, !Ref EnvironmentType, InstanceType]
  {...}
```

##### 4. セキュリティグループの更新
最後に、セキュリティグループリソースを更新します。`ec2.yaml` テンプレートの **Resources** セクション `WebServerSecurityGroup` リソース [19] 行目を更新します。

```yaml {hl_lines=[19]}
WebServerSecurityGroup:
  Type: AWS::EC2::SecurityGroup
  Properties:
    GroupDescription: Enable HTTP and HTTPS access
    SecurityGroupIngress:
      - IpProtocol: tcp
        FromPort: 80
        ToPort: 80
        CidrIp: 0.0.0.0/0
    SecurityGroupEgress:
      - IpProtocol: tcp
        FromPort: 80
        ToPort: 80
        CidrIp: 0.0.0.0/0
      - IpProtocol: tcp
        FromPort: 443
        ToPort: 443
        CidrIp: 0.0.0.0/0
    VpcId: !ImportValue cfn-workshop-VpcId
```

##### 5. EC2 スタックのデプロイ

1. コンソールで CloudFormation に移動し、**新しいリソースを使用 (標準)** をクリックします。
2. **テンプレートの準備**セクションで、**テンプレート準備完了**を選択します。
3. **テンプレートの指定**セクションで、**テンプレートファイルのアップロード**を選択します。
4. `ec2.yaml` ファイルを選択します。
5. **スタック名**を入力します。例えば、`cfn-workshop-ec2`と入力します。
6. 残りのパラメータは **デフォルト** のままとします。
7. すべてデフォルトのままウィザード内を移動します。
8. **レビュー**ページで一番下までスクロールし、**送信**をクリックします。

#### 7. デプロイメントのテスト

##### 1.アプリケーションが正常にデプロイされたことを確認

プライベートモードで新しいブラウザウィンドウを開き、`websiteURL` を入力します (WebsiteURL は CloudFormation コンソールの EC2 スタックの**出力**タブから取得できます)。
下の図のような、いくつかのインスタンスメタデータが表示されます。

![ami-id](/static/intermediate/templates/layered-stacks/ami-id-1.ja.png)

##### 2.SSM Session Manager を使用してインスタンスにログイン

Session Manager を使用してインスタンスにログインできることを確認します。

やり方がわからない場合は、[Session Manager](/basics/operations/session-manager#challenge) ラボをご参照ください。

### クリーンアップ

::alert[スタックが出力値をインポートした後は、出力値をエクスポートしているスタックを削除したり、エクスポートされた出力値を変更したりすることはできません。エクスポートするスタックを削除したり、出力値を変更したりする前に、すべてのインポートを削除する必要があります。]{type="info"}

例えば、**EC2 スタック**を削除する前に **VPC スタック**を削除することはできません。次のエラーメッセージが表示されます。

![delete-export-before-import.png](/static/intermediate/templates/layered-stacks/delete-export-before-import.ja.png)

1. [CloudFormation コンソール](https://console.aws.amazon.com/cloudformation) で、**EC2 スタック** を選択します (例: `cfn-workshop-ec2`)。
2. 右上の**削除**をクリックします。
3. ポップアップウィンドウで、**スタックの削除**をクリックします。
4. **DELETE_COMPLETE** のステータスが表示されるまで、**更新**ボタンを数回クリックします。
5. 依存関係がなくなったため、**IAM** と **VPC** スタックが削除できます。

---
### まとめ
**階層化されたスタック**では、複数のスタックで繰り返し使用できるリソースを作成できます。利用する全てのスタックで、**Export** で指定した名前を知る必要があります。この機能を利用することで、役割と責任を分けることができます。例えば、ネットワークチームは、承認された VPC デザインをテンプレートとして作成して提供できます。必要に応じて、VPCスタックの Export を参照すれば良いです。同様に、セキュリティチームは IAM ロールや EC2 セキュリティグループについても同じ操作を行うことができます。
