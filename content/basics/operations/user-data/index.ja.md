---
title: "ユーザーデータ"
weight: 300
---

_ラボ実施時間 : 10分程度_

---

### 概要

AWS CloudFormation を使用して、Amazon EC2 インスタンスにアプリケーションを自動的にインストール、設定、および起動できます。そうすることで、直接インスタンスに接続しなくても、デプロイメントの複製や既存のインストールの更新を簡単に行うことができます。時間と労力を大幅に節約できます。

### カバーするトピック
このラボでは、**[UserData](https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/UserGuide/user-data.html)** プロパティを使用して、簡単な PHP アプリケーションを含む Apache Web サーバーをデプロイします。

+ まず、EC2 インスタンスをブートストラップして、Web サーバーとコンテンツをインストールします。
+ 次に、EC2 **セキュリティグループ** を作成し、ポート 80 でインスタンスへのアクセスを許可します。
+ 最後に、Web サーバーによって提供されるコンテンツを表示します。

次の図は、実装するアーキテクチャの大まかな概要を示しています。

![user-data-png](/static/basics/operations/user-data/userdata.png)

### ラボの開始

1. `code/workspace` ディレクトリに移動します。
1. `user-data.yaml` ファイルを開きます。
1. 以下のトピックを進めながら、コードをコピーしてください。


#### 1. セキュリティグループの作成

まず、セキュリティグループを作成します。

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=75}
WebServerSecurityGroup:
  Type: AWS::EC2::SecurityGroup
  Properties:
    GroupDescription: 'Enable HTTP access via port 80'
:::

Apache Web サーバーはポート 80 でコンテンツを提供するので、セキュリティグループの `SecurityGroupIngress` 属性にインターネットからのアクセスを許可するイングレスルールを作成する必要があります。

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=79 highlightLines=83-87}
WebServerSecurityGroup:
  Type: AWS::EC2::SecurityGroup
  Properties:
    GroupDescription: 'Enable HTTP access via port 80'
    SecurityGroupIngress:
      - IpProtocol: tcp
        FromPort: 80
        ToPort: 80
        CidrIp: 0.0.0.0/0
:::

最後に、セキュリティグループを EC2 インスタンスに関連付けます。

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=63 highlightLines=69-70}
WebServerInstance:
  Type: AWS::EC2::Instance
  Properties:
    IamInstanceProfile: !Ref EC2InstanceProfile
    ImageId: !Ref AmiID
    InstanceType: !FindInMap [EnvironmentToInstanceType, !Ref EnvironmentType, InstanceType]
    SecurityGroupIds:
      - !Ref WebServerSecurityGroup
    Tags:
      - Key: Name
        Value: !Join [ '-', [ !Ref EnvironmentType, webserver ] ]
:::

:::alert{type="info"}
_セキュリティグループ_ プロパティを変更したため、CloudFormation スタックに存在している EC2 インスタンスが _置換_ されます。[こちら](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html?shortFooter=true#aws-properties-ec2-instance-properties)で EC2 インスタンスの更新時に[置換](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html#update-replacement)が必要になるプロパティを確認できます。
:::


#### 2. インスタンスに Apache Web サーバーをインストール

それでは、Apache と PHP アプリケーションをインストールするための bash スクリプトを書いてみましょう。

:::alert{type="info"}
ユーザーデータのスクリプトは **root** ユーザーとして実行されるため、スクリプトで `sudo` コマンドを使用する必要はありません。\
**UserData** は、CloudFormation から EC2 インスタンスに渡されるときに Base64 でエンコードされている必要があります。`Fn::Base64` 組み込み関数を使用して入力文字列をエンコードします。
:::

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=74}
UserData:
  Fn::Base64: |
    #!/bin/bash
    yum update -y
    yum install -y httpd php
    systemctl start httpd
    systemctl enable httpd
    usermod -a -G apache ec2-user
    chown -R ec2-user:apache /var/www
    chmod 2775 /var/www
    find /var/www -type d -exec chmod 2775 {} \;
    find /var/www -type f -exec chmod 0664 {} \;
    # PHP script to display Instance ID and Availability Zone
    cat << 'EOF' > /var/www/html/index.php
      <!DOCTYPE html>
      <html>
      <body>
        <center>
          <?php
          # Get the instance ID from meta-data and store it in the $instance_id variable
          $url = "http://169.254.169.254/latest/meta-data/instance-id";
          $instance_id = file_get_contents($url);
          # Get the instance's availability zone from metadata and store it in the $zone variable
          $url = "http://169.254.169.254/latest/meta-data/placement/availability-zone";
          $zone = file_get_contents($url);
          ?>
          <h2>EC2 Instance ID: <?php echo $instance_id ?></h2>
          <h2>Availability Zone: <?php echo $zone ?></h2>
        </center>
      </body>
      </html>
    EOF
:::

#### 3. CloudFormation の _Outputs_ に **WebsiteURL** を追加

以下のコードをコピーして、CloudFormation テンプレートの _Outputs_ セクションに貼り付けます。

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=132}
WebsiteURL:
  Value: !Sub http://${WebServerEIP}
  Description: Application URL
:::

#### 4. スタックの更新

前のラボと同様に、更新されたテンプレートでスタックを作成します。CloudFormation がスタックの作成を完了すると、スクリプトが EC2 インスタンスに Web サーバーをセットアップしたことを確認できます。

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. **Cloud9 のターミナル** で `code/workspace` に移動します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace
:::
1. AWS CLI でスタックを作成します。必要な `--stack-name`、`--template-body`、`--capabilities` パラメータがあらかじめ設定されています。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
--stack-name cfn-workshop-user-data \
--template-body file://user-data.yaml \
--capabilities CAPABILITY_IAM
:::
1. `create-stack` コマンドが正常に送信されたら、CloudFormation が `StackId` を返します。
:::code{language=json showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-user-data/96d87030-e809-11ed-a82c-0eb19aaeb30f"
:::
1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** のコンソールを新しいタブで開き、スタックが **CREATE_COMPLETE** ステータスになるまで待ちます。必要に応じて、リフレッシュボタンをクリックします。
::::
::::tab{id="local" label="ローカル開発"}
1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** のリンクを新しいタブで開き、必要に応じて AWS アカウントにログインします。
1. 画面右上の **スタックの作成** をクリックし、**新しいリソースを使用 (標準)** をクリックしてください。
1. **テンプレートの準備** では、**テンプレートの準備完了** を選びます。
1. **テンプレートの指定** では、**テンプレートファイルのアップロード** を選びます。
1. **ファイルの選択** をクリックして、作業ディレクトリに移動します。
1. `user-data.yaml` ファイルを指定し、**次へ** をクリックします。
1. **スタックの名前** (例: `cfn-workshop-user-data`) を入力し、**次へ** をクリックします。
1. **Amazon Machine Image ID** はそのままにします。
1. **EnvironmentType** は選択されている値をそのままにして、**次へ** をクリックします。
1. **スタックオプションの設定** はデフォルトの設定のままとし、**次へ** をクリックします。
1. **レビュー <スタック名>** のページで、ページの下部までスクロールし、**AWS CloudFormation によって IAM リソースが作成される場合があることを承認します。** の文言のチェックボックスにチェックを入れます。**送信** をクリックします。
1. スタックが **CREATE_COMPLETE** ステータスになるまで待ちます。必要に応じて、リフレッシュボタンをクリックします。
::::
:::::

Web ブラウザで `WebsiteURL` を入力します (WebsiteURL は CloudFormation コンソールの _Outputs_ タブから取得できます)。

![outputs](/static/basics/operations/user-data/outputs-1.ja.png)

下の図のようなページが表示されるはずです。

![php-page](/static/basics/operations/user-data/php.png)

### クリーンアップ

以下の手順の通りに、作成したリソースのクリーンアップを実施してください。

1. **[CloudFormation コンソール](https://console.aws.amazon.com/cloudformation)** に移動します。
1. CloudFormation の **スタック** ページで `cfn-workshop-user-data` を選択します。
1. スタックの詳細で **削除** を選択し、ポップアップ上で **削除** で確定します。
1. スタックが **DELETE_COMPLETE** ステータスになるまで待ちます。必要に応じて、リフレッシュボタンをクリックします。

---
### まとめ

おめでとうございます！ EC2 インスタンスのブートストラップに成功しました。次のセクションでは、CloudFormation _ヘルパースクリプト_ という手法で Amazon EC2 にソフトウェアをインストールしてサービスを開始する方法を学びます。
