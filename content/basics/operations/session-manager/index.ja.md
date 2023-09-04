---
title: "Session Manager"
weight: 200
---

### 概要

[Session Manager](https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/session-manager.html) はインタラクティブなワンクリックのブラウザベースのターミナルまたは AWS CLI を使用して Amazon EC2 インスタンスを管理できる AWS Systems Manager のフルマネージド機能です。

Session Manager には SSH を使用するよりいくつかの利点があります。

+ SSH キーを管理する必要はありません。
+ セキュリティグループのインバウンドポートを開く必要はありません。
+ IAM ポリシーとユーザーを使用して、インスタンスへのアクセスを制御できます。
+ コマンドとレスポンスは Amazon CloudWatch と S3 バケットに記録できます。

#### セッションマネージャーの仕組み

1. 管理者は IAM に対して認証を行います。
1. IAM は、適用可能な IAM ポリシーを評価して EC2 インスタンスでセッションを開始することを承認します。
1. 管理者は AWS マネジメントコンソールまたはターミナル (AWS CLI と追加のプラグインが必要) を使用して、Systems Manager からセッションを開始します。
1. EC2 インスタンスで実行されている Systems Manager Agent は、AWS Systems Manager に接続し、インスタンスでコマンドを実行します。
1. Session Manager は CloudWatch Logs または S3 に監査ログを送信します。

::alert[Session Manager が機能するには、EC2 インスタンスがインターネットにアクセスするか、VPC エンドポイントにアクセスする必要があります。]{type="info"}

![ssm](/static/basics/operations/session-manager/ssm-sm-1.png)

### カバーするトピック
このラボでは次のことを学びます。

+ AWS Systems Manager へのアクセスを許可する EC2 インスタンス用の IAM ロールを作成する方法。
+ IAM ロールを EC2 インスタンスにアタッチ。
+ SSM Session Manager を使用してインスタンスにログイン。

### ラボの開始

1. `code/workspace` ディレクトリに移動します。
1. `session-manager.yaml` ファイルを開きます。
1. 以下のトピックを進めながら、コードをコピーしてください。

#### 1. EC2 インスタンスに AWS Systems Manager Agent のインストール

SSM Agent は Amazon Linux AMI にあらかじめインストールされているので、次のステップに進むことができます。他のオペレーティングシステムの場合は、AWS ドキュメントの [SSM Agent の使用](https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/ssm-agent.html) を参照してください。

#### 2. EC2 インスタンスの IAM ロールの作成
`AmazonSSMManagedInstanceCore` というAWS 管理のポリシーでは、インスタンスが AWS Systems Manager サービスのコア機能の使用を許可しています。Systems Manager Session Manager を使用して EC2 インスタンスに接続できるように利用できます。

```yaml
SSMIAMRole:
  Type: AWS::IAM::Role
  Properties:
    AssumeRolePolicyDocument:
      Statement:
        - Effect: Allow
          Principal:
            Service:
              - ec2.amazonaws.com
          Action:
            - sts:AssumeRole
    ManagedPolicyArns:
      - arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
```

#### 3. IAM インスタンスプロファイルの作成

インスタンスプロファイルリソースを作成します。

```yaml
WebServerInstanceProfile:
  Type: AWS::IAM::InstanceProfile
  Properties:
    Path: /
    Roles:
      - !Ref SSMIAMRole
```

#### 4. IAM インスタンスプロファイルを Amazon EC2 インスタンスにアタッチ

`IAMInstanceProfile` プロパティを使用してロールをインスタンスにアタッチします。

```yaml
WebServerInstance:
  Type: AWS::EC2::Instance
  Properties:
    IamInstanceProfile: !Ref WebServerInstanceProfile
    ImageId: !Ref AmiID
    InstanceType: !FindInMap [EnvironmentToInstanceType, !Ref EnvironmentType, InstanceType]
    Tags:
      - Key: Name
        Value: !Join [ '-', [ !Ref EnvironmentType, webserver ] ]
```

::alert[インスタンスプロファイルは、新しい Amazon EC2 インスタンスの起動時にアタッチすることも、既存の Amazon EC2 インスタンスにアタッチすることもできます。]{type="info"}

#### 5. スタックの更新

AWS コンソールに移動し、新しいテンプレートでスタックを更新します。

1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** のリンクを新しいタブで開き、必要に応じて AWS アカウントにログインします。
1. スタック名 (例: **cfn-workshop-ec2**) をクリックします。
1. 画面右上の **更新** ボタンをクリックします。
1. **テンプレートの準備** で、**既存テンプレートを置き換える** を選択します。
1. **テンプレートの指定** で、 **テンプレートファイルのアップロード** を選びます。
1. **ファイルの選択** ボタンをクリックし、作業用ディレクトリに移動します。
1. ステップ1で作成した `session-manager.yaml` を指定し、**次へ** をクリックします。
1. **Amazon Machine Image ID** はそのままにしてください。
1. **EnvironmentType** には、リストされているものとは異なる環境を選択します。たとえば、**Dev** が選択されている場合は、**Test** を選択し、**次へ** をクリックします。
:::alert{type="info"}
System Manager が機能するには、インスタンスが次の条件を満たす必要があります。 \
 \- **インターネットまたは VPC エンドポイントへのアクセス。** \
 \- **ロールには正しい権限が付与されています。** \
環境を変更すると、インスタンスは停止し、再起動します。以前のラボではロールが割り当てられていなかったため、`ssm-agent` の起動するタイムアウトした可能性のあるので、再起動が役に立ちます。
:::
1. **スタックオプションの設定** はデフォルトの設定のままとし、**次へ** をクリックします。
1. **レビュー <スタック名>** ページで、一番下までスクロールし、**AWS CloudFormation によって IAM リソースが作成される場合があることを承認します。** チェックボックスをチェックし、**スタックの更新** をクリックします。
1. ステータスが **UPDATE_COMPLETE** になるまで、**リフレッシュ** ボタンを数回クリックします。

### チャレンジ

SSM Session Manager を使用してインスタンスにログインし、`curl` を使用してインスタンスメタデータから AMI ID を取得します。

::expand[ [インスタンスメタデータとユーザーデータ](https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/UserGuide/ec2-instance-metadata.html) に関する AWS ドキュメントを確認してください。]{header="ヒントが必要ですか？"}

:::expand{header="解決策を確認しますか？"}
次のコマンドをインスタンスターミナル内に貼り付けます。

::code[curl http://169.254.169.254/latest/meta-data/ami-id]{language=shell showLineNumbers=false showCopyAction=true}
:::

:::alert{type="warning"}
このワークショップ以外にも、SSM Session Manager へのアクセスを設定する際には、環境の保護のために追加の手順を実行する必要があります。詳細は以下の推薦事項のドキュメントのリンクをご参照ください。
:::

##### 推奨事項

+ IAM ポリシーを使用して、EC2 インスタンスでセッションを開始できる IAM ユーザーまたはロールを制限します。
+ ログを監査するように Amazon CloudWatch Logs または S3 バケットを設定します。
+ IAM ポリシーを使用して、IAM ユーザーが監査ログ設定を変更できないようにします。

[AWS Systems Manager のセットアップ](https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/systems-manager-setting-up.html) ドキュメントをご参照ください。

---
### まとめ

おめでとうございます！Session Manager の設定を完了し、EC2 インスタンスにリモートアクセスできるようになりました。
