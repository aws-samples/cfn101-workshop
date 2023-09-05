---
title: "ユーザーデータ"
weight: 300
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

```yaml
WebServerSecurityGroup:
  Type: AWS::EC2::SecurityGroup
  Properties:
    GroupDescription: 'Enable HTTP access via port 80'
```

Apache Web サーバーはポート 80 でコンテンツを提供するので、セキュリティグループの `SecurityGroupIngress` 属性にインターネットからのアクセスを許可するイングレスルールを作成する必要があります。

```yaml
WebServerSecurityGroup:
  Type: AWS::EC2::SecurityGroup
  Properties:
    GroupDescription: 'Enable HTTP access via port 80'
    SecurityGroupIngress:
      - IpProtocol: tcp
        FromPort: 80
        ToPort: 80
        CidrIp: 0.0.0.0/0
```

最後に、セキュリティグループを EC2 インスタンスに関連付けます。

```yaml
WebServerInstance:
  Type: AWS::EC2::Instance
  Properties:
    IamInstanceProfile: !Ref EC2InstanceProfile
    ImageId: !Ref AmiID
    InstanceType: !FindInMap [Environment, InstanceType, !Ref EnvType]
    SecurityGroupIds:
      - !Ref WebServerSecurityGroup
    Tags:
      - Key: Name
        Value: !Join [ '-', [ !Ref EnvironmentType, webserver ] ]
```

:::alert{type="info"}
_セキュリティグループ_ プロパティを変更したため、CloudFormation スタックに存在している EC2 インスタンスが _置換_ されます。[こちら](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html?shortFooter=true#aws-properties-ec2-instance-properties)で EC2 インスタンスの更新時に[置換](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html#update-replacement)が必要になるプロパティを確認できます。
:::


#### 2. インスタンスに Apache Web サーバーをインストール

それでは、Apache と PHP アプリケーションをインストールするための bash スクリプトを書いてみましょう。

:::alert{type="info"}
ユーザーデータのスクリプトは **root** ユーザーとして実行されるため、スクリプトで `sudo` コマンドを使用する必要はありません。\
**UserData** は、CloudFormation から EC2 インスタンスに渡されるときに Base64 でエンコードされている必要があります。`Fn::Base64` 組み込み関数を使用して入力文字列をエンコードします。
:::

```yaml
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
```

#### 3. CloudFormation の _Outputs_ に **WebsiteURL** を追加

以下のコードをコピーして、CloudFormation テンプレートの _Outputs_ セクションに貼り付けます。

```yaml
WebsiteURL:
  Value: !Sub http://${WebServerEIP}
  Description: Application URL
```

#### 4. スタックの更新

前のラボと同様に、更新されたテンプレートでスタックを更新します。CloudFormation がスタックの更新を完了すると、スクリプトが EC2 インスタンスに Web サーバーをセットアップしたことを確認できます。

1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** のリンクを新しいタブで開き、必要に応じて AWS アカウントにログインします。
1. スタック名 (例: **cfn-workshop-ec2**) をクリックします。
1. 画面右上の **更新** ボタンをクリックします。
1. **テンプレートの準備** で、**既存テンプレートを置き換える** を選択します。
1. **テンプレートの指定** で、 **テンプレートファイルのアップロード** を選びます。
1. **ファイルの選択** ボタンをクリックし、作業用ディレクトリに移動します。
1. ステップ1で作成した `user-data.yaml` を指定し、**次へ** をクリックします。
1. **Amazon Machine Image ID** はそのままにしてください。
1. **EnvironmentType** は選択されている環境のままにします。
1. **スタックオプションの設定** はデフォルトの設定のままとし、**次へ** をクリックします。
1. **レビュー <スタック名>** ページで、一番下までスクロールし、**AWS CloudFormation によって IAM リソースが作成される場合があることを承認します。** チェックボックスをチェックし、**スタックの更新** をクリックします。
1. ステータスが **UPDATE_COMPLETE** になるまで、**リフレッシュ** ボタンを数回クリックします。

Web ブラウザで `WebsiteURL` を入力します (WebsiteURL は CloudFormation コンソールの _Outputs_ タブから取得できます)。

![outputs](/static/basics/operations/user-data/outputs-1.ja.png)

下の図のようなページが表示されるはずです。

![php-page](/static/basics/operations/user-data/php.png)

---
### まとめ

おめでとうございます！ EC2 インスタンスのブートストラップに成功しました。次のセクションでは、CloudFormation _ヘルパースクリプト_ という手法で Amazon EC2 にソフトウェアをインストールしてサービスを開始する方法を学びます。
