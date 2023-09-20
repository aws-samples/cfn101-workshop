---
title: "ヘルパースクリプト"
weight: 400
---

_ラボ実施時間 : 15分程度_

---

### 概要

このラボでは、CloudFormation [ヘルパースクリプト](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/cfn-helper-scripts-reference.html) について学習します。前のラボで学んだことは素晴らしい出発点です。しかし、`UserData` から気づくかもしれませんが手続き型スクリプトは理想的ではありません。シンプルな PHP アプリケーションをデプロイしたが、ユーザーデータにより複雑なアプリを書こうとすることを想像してみてください。それは非常に難しいでしょう。

この問題を解決するために、CloudFormation はヘルパースクリプトを提供しています。これらのヘルパースクリプトは、CloudFormation を強化し、ユースケースに合わせて微調整できるようなテンプレートを可能とします。たとえば、インスタンスを作り直さずにアプリケーションを更新することが可能になります。

ヘルパースクリプトは Amazon Linux にあらかじめインストールされており、`yum install -y aws-cfn-bootstrap` を使用して定期的に更新します。

### カバーするトピック

このラボでは、次のことを学びます。

+ [cfn-init](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/cfn-init.html) によるリソースメタデータの取得と解釈、パッケージのインストール、ファイルの作成、サービスの開始を行う方法

+ [cfn-hup](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/cfn-hup.html) でメタデータの更新を確認し、変更が検出されたときにカスタムフックを実行する方法

+ [cfn-signal](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/cfn-signal.html) を使用してリソースまたはアプリケーションの準備が整ったときに CloudFormation にシグナルを送信する方法

### ラボの開始

1. `code/workspace` ディレクトリに移動します。
1. `helper-scripts.yaml` ファイルを開きます。
1. 以下のトピックを進めながら、コードをコピーしてください。

#### 1. _Metadata_ セクションの設定

Amazon EC2 インスタンスのためにメタデータを指定するには、`AWS::CloudFormation::Init` タイプを使用する必要があります。テンプレートが `cfn-init` スクリプトを実行すると、スクリプトはメタデータセクション内のリソースを検索します。テンプレートにメタデータを追加しましょう。

:::code{language=yaml showLineNumbers=false showCopyAction=true}
  WebServerInstance:
    Type: AWS::EC2::Instance
    Metadata:
      AWS::CloudFormation::Init:
:::

#### 2. cfn-init の設定

`cfn-init` の設定はいくつかのセクションに分かれています。設定セクションは packages、groups、users、sources、files、commands、services の順番に処理されます。

:::alert{type="info"}
別の順序が必要な場合は、セクションを異なる設定キーに分けてから、[configset](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-init.html?shortFooter=true#aws-resource-init-configsets) で設定キーの順序を指定します。
:::

:::alert{type="info"}
以下のコードサンプルのように、インデントを守ることが重要です。`code/solutions/helper-scripts.yaml` のソリューションコードによって、テンプレートをクロスリファレンスもできます。
:::

##### 1. HTTPD と PHP のパッケージのインストール

インスタンスは Amazon Linux 2 を実行しているので、`yum` パッケージマネージャを使用してパッケージをインストールします。

`packages` キーのコードをテンプレートに追加します。

:::code{language=yaml showLineNumbers=false showCopyAction=true}
WebServerInstance:
  Type: AWS::EC2::Instance
  Metadata:
    AWS::CloudFormation::Init:
      config:
        packages:
          yum:
            httpd: []
:::

##### 2. `index.php` ファイルの作成

`files` キーを使用して EC2 インスタンスにファイルを作成します。コンテンツは、テンプレート内のインラインの指定か、インスタンスが取得できる URL として指定します。

`files` キーのコードをテンプレートに追加します。

:::code{language=yaml showLineNumbers=false showCopyAction=true}
WebServerInstance:
  Type: AWS::EC2::Instance
  Metadata:
    AWS::CloudFormation::Init:
      config:
        packages: \
          {...}
        files:
          /var/www/html/index.php:
            content: |
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
            mode: 000644
            owner: apache
            group: apache
:::

##### 3. Apache Web サーバーを有効にして起動する

`services` キーを使用して、インスタンスの起動時にどのサービスを有効または無効にするかを定義できます。Linux システムの場合は、このキーは `sysvinit` キーを使用することでサポートされます。

`services` キーのコードをテンプレートに追加します。

:::code{language=yaml showLineNumbers=false showCopyAction=true}
WebServerInstance:
  Type: AWS::EC2::Instance
  Metadata:
    AWS::CloudFormation::Init:
      config:
        packages:
          {...}
        files:
          {...}
        services:
          sysvinit:
            httpd:
              enabled: true
              ensureRunning: true
:::

##### 4. `cfn-init` スクリプトの実行

メタデータにあるスクリプトはデフォルトでは実行されません。実行するには、UserData セクションで `cfn-init` ヘルパースクリプトを呼び出す必要があります。

以下のコードでは、CloudFormation は最初に `aws-cfn-bootstrap` パッケージを更新して、最新バージョンのヘルパースクリプトを取得します。次に、メタデータからファイルとパッケージをインストールします。

`UserData` プロパティのコードをテンプレートに追加します。

:::code{language=yaml showLineNumbers=false showCopyAction=true}
UserData:
  Fn::Base64:
    !Sub |
      #!/bin/bash -xe
      # Update aws-cfn-bootstrap to the latest
      yum install -y aws-cfn-bootstrap
      # Call cfn-init script to install files and packages
      /opt/aws/bin/cfn-init -v --stack ${AWS::StackName} --resource WebServerInstance --region ${AWS::Region}
:::

::alert[`!Sub` 組み込み関数は `${AWS::StackName}` と `${AWS::Region}` 変数の値を動的に置き換えます。]{type="info"}

#### 3. cfn-hup の設定

`cfn-hup` ヘルパースクリプトをインストールすると、既存の EC2 インスタンスがテンプレートの _UserData_ の変更を適用できるようになります。たとえば、テンプレート内のサンプル PHP アプリケーションを変更し、既存のスタックを更新することで、アプリケーションをデプロイできます。`cfn-hup` を利用しない場合は、EC2 インスタンスを置き換えるか、手動または外部の仕組みで EC2 インスタンスの更新を適用する必要があります。(実際の動作を確認するには、このラボのチャレンジセクションを参照してください)。

1. `AWS::CloudFormation::Init` の `files` セクションに以下の 2 つのファイルを追加します。

    + /etc/cfn/cfn-hup.conf
    + /etc/cfn/hooks.d/cfn-auto-reloader.conf

1. 両方のファイルのコードをテンプレートにコピーします。

   :::code{language=yaml showLineNumbers=false showCopyAction=true}
   WebServerInstance:
     Type: AWS::EC2::Instance
     Metadata:
       AWS::CloudFormation::Init:
         config:
           packages:
             {...}
           files:
             /var/www/html/index.php:
               {...}
             /etc/cfn/cfn-hup.conf:
               content: !Sub |
                 [main]
                 stack=${AWS::StackId}
                 region=${AWS::Region}
                 interval=1
               mode: 000400
               owner: root
               group: root
             /etc/cfn/hooks.d/cfn-auto-reloader.conf:
               content: !Sub |
                 [cfn-auto-reloader-hook]
                 triggers=post.update
                 path=Resources.WebServerInstance.Metadata.AWS::CloudFormation::Init
                 action=/opt/aws/bin/cfn-init --stack ${AWS::StackName} --resource WebServerInstance --region ${AWS::Region}
                 runas=root
           services:
             {...}
   :::

1. テンプレートの `services` セクションで `cfn-hup` を有効にして起動します。

   `services` キーのコードをテンプレートに追加します。

   :::code{language=yaml showLineNumbers=false showCopyAction=true}
   WebServerInstance:
     Type: AWS::EC2::Instance
     Metadata:
       AWS::CloudFormation::Init:
         config:
           packages:
             {...}
           files:
             /var/www/html/index.php:
               {...}
             /etc/cfn/cfn-hup.conf:
                 {...}
             /etc/cfn/hooks.d/cfn-auto-reloader.conf:
                 {...}
           services:
             sysvinit:
               httpd:
                 enabled: true
                 ensureRunning: true
               cfn-hup:
                 enabled: true
                 ensureRunning: true
                 files:
                   - /etc/cfn/cfn-hup.conf
                   - /etc/cfn/hooks.d/cfn-auto-reloader.conf
   :::

#### 4. cfn-signal　の設定と CreationPolicy 属性の追加

最後に、全てのサービス (Apache や cfn-hup など) が起動し終えたことを CloudFormation に伝える仕組みが必要です。スタックのリソースの作成完了だけでは、完了ではありません。

別の言い方をすると、AWS CloudFormation はスタックの全てのリソースを作成したら、スタックのステータスを _CREATE\_COMPLETE_ にします。すなわち、インスタンスの中のサービスが失敗しても、 _CREATE\_COMPLETE_ になります。

これを防ぐにはインスタンスに [CreationPolicy](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-attribute-creationpolicy.html) 属性を追加できます。
作成ポリシーと併せて、`cfn-signal` ヘルパースクリプトを実行して、すべてのアプリケーションがインストールされ設定されると、AWS CloudFormation に通知します。

1. `WebServerInstance` リソースに `CreationPolicy` プロパティを追加します。

   :::code{language=yaml showLineNumbers=false showCopyAction=true}
   CreationPolicy:
     ResourceSignal:
       Count: 1
       Timeout: PT10M
   :::

1. `cfn-signal` を UserData パラメータに追加します。

   :::code{language=yaml showLineNumbers=false showCopyAction=true}
   UserData:
    Fn::Base64:
      !Sub |
        #!/bin/bash -xe
        # Update aws-cfn-bootstrap to the latest
        yum install -y aws-cfn-bootstrap
        # Call cfn-init script to install files and packages
        /opt/aws/bin/cfn-init -v --stack ${AWS::StackName} --resource WebServerInstance --region ${AWS::Region}
        # Call cfn-signal script to send a signal with exit code
        /opt/aws/bin/cfn-signal --exit-code $? --stack ${AWS::StackName} --resource WebServerInstance --region ${AWS::Region}
   :::

#### 5. スタックの作成
スタックを更新して `UserData` プロパティで行った変更を適用するには、EC2 インスタンスを置き換える必要があります。
[こちら](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html?shortFooter=true#aws-properties-ec2-instance-properties)で EC2 インスタンスの置き換えをトリガーする属性を確認できます。

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. **Cloud9 のターミナル** で `code/workspace` に移動します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace
:::
1. AWS CLI でスタックを作成します。必要な `--stack-name`、`--template-body`、`--capabilities` パラメータがあらかじめ設定されています。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack --stack-name cfn-workshop-helper-scripts \
--template-body file://helper-scripts.yaml \
--capabilities CAPABILITY_IAM
:::
1. `create-stack` コマンドが正常に送信されたら、CloudFormation が `StackId` を返します。
:::code{language=shell showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-helper-scripts/96d87030-e809-11ed-a82c-0eb19aaeb30f"
:::
1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** のコンソールを新しいタブで開き、スタックが **CREATE_COMPLETE** ステータスになるまで待ちます。必要に応じて、リフレッシュボタンをクリックします。
1. インスタンスが正常に作成されたことを確認するために、Web ブラウザで `WebsiteURL` を入力します (WebsiteURL は CloudFormation コンソールの _Outputs_ タブから取得できます)。
::::
::::tab{id="local" label="ローカル開発"}
1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** のリンクを新しいタブで開き、必要に応じて AWS アカウントにログインします。
1. 画面右上の **スタックの作成** をクリックし、**新しいリソースを使用 (標準)** をクリックしてください。
1. **テンプレートの準備** では、**テンプレートの準備完了** を選びます。
1. **テンプレートの指定** では、**テンプレートファイルのアップロード** を選びます。
1. `helper-scripts.yaml` ファイルを指定し、**次へ** をクリックします。
1. **スタックの名前** (例: `cfn-workshop-helper-scripts`) を入力し、**次へ** をクリックします。
1. **Amazon Machine Image ID** はそのままにしてください。
1. **EnvironmentType** にはドロップダウンから環境の種類を選択します。例えば **Test** を選択して、**次へ** をクリックします。
1. **スタックオプションの設定** はデフォルトの設定のままとし、**次へ** をクリックします。
1. **レビュー <スタック名>** のページで、ページの下部までスクロールし、**AWS CloudFormation によって IAM リソースが作成される場合があることを承認します。** の文言のチェックボックスにチェックを入れます。**送信** をクリックします。
1. スタックが **CREATE_COMPLETE** ステータスになるまで待ちます。必要に応じて、リフレッシュボタンをクリックします。
1. インスタンスが正常に作成されたことを確認するために、Web ブラウザで `WebsiteURL` を入力します (WebsiteURL は CloudFormation コンソールの _Outputs_ タブから取得できます)。
::::
:::::

#### チャレンジ

このチャレンジでは、スタックを更新したときに `cfn-hup` がアプリケーションを更新する方法を証明します。AMI ID を表示するように `index.php` ファイルを更新します。

##### 1. `index.php` ファイルの変更

EC2 メタデータの _files_ セクションにある `/var/www/html/index.php` を探してください。

以下のコードを `<\?php {...} ?>` ブロックに追加します。

:::code{language=php showLineNumbers=false showCopyAction=true}
# Get the instance AMI ID and store it in the $ami_id variable
$url = "http://169.254.169.254/latest/meta-data/ami-id";
$ami_id = file_get_contents($url);
:::

以下のコードを html `<h2>` タグに追加してください。

:::code{language=html showLineNumbers=false showCopyAction=true}
<h2>AMI ID: <?php echo $ami_id ?></h2>
:::

##### 2. 新しいテンプレートでスタックを更新

`cfn-hup` はメタデータセクションの変更を検出し、新しいバージョンを自動的にデプロイし、既存のインスタンスを更新します。

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. **Cloud9 のターミナル** で `code/workspace` に移動します。
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace
:::
1. AWS CLI でスタックを更新します。必要な `--stack-name`、`--template-body`、`--capabilities` パラメータがあらかじめ設定されています。
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-stack --stack-name cfn-workshop-helper-scripts \
--template-body file://helper-scripts.yaml \
--capabilities CAPABILITY_IAM
:::
1. `update-stack` コマンドが正常に送信されたら、CloudFormation が `StackId` を返します。
:::code{language=shell showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-helper-scripts/96d87030-e809-11ed-a82c-0eb19aaeb30f"
:::
1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** のコンソールを新しいタブで開き、スタックが **CREATE_COMPLETE** ステータスになるまで待ちます。必要に応じて、リフレッシュボタンをクリックします。新しい EC2 インスタンスが作成されないので、すぐ終わるはずです。
:::code{language=shell showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-helper-scripts/96d87030-e809-11ed-a82c-0eb19aaeb30f"
:::
::::
::::tab{id="local" label="ローカル開発"}
1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** のリンクを新しいタブで開き、必要に応じて AWS アカウントにログインします。
1. スタック名 (例: `cfn-workshop-helper-scripts`) をクリックします。
1. 画面右上の **更新** ボタンをクリックします。
1. **テンプレートの準備** で、**既存テンプレートを置き換える** を選択します。
1. **テンプレートの指定** で、 **テンプレートファイルのアップロード** を選びます。
1. **ファイルの選択** ボタンをクリックし、作業用ディレクトリに移動します。
1. `helper-scripts.yaml` ファイルを指定し、**次へ** をクリックします。
1. **Amazon Machine Image ID** はそのままにしてください。
1. **EnvironmentType** は選択されている環境のままにします。
1. **スタックオプションの設定** はデフォルトの設定のままとし、**次へ** をクリックします。
1. **レビュー <スタック名>** ページで、一番下までスクロールし、**AWS CloudFormation によって IAM リソースが作成される場合があることを承認します。** チェックボックスをチェックし、**送信** をクリックします。
1. ステータスが **UPDATE_COMPLETE** ステータスになるまで待ちます。必要に応じて、リフレッシュボタンをクリックします。
::::
:::::

##### 3. 変更が正常に展開されたことを確認

プライベートモードで新しいブラウザウィンドウを開き、`WebsiteURL` を入力します (WebsiteURL は CloudFormation コンソールの _Outputs_ タブから取得できます)。下の図のように、AMI ID がページに追加されているはずです。

![ami-id](/static/basics/operations/helper-scripts/ami-id-1.png)

### クリーンアップ

作成したリソースをクリーンアップするには、次の手順を実施します。

1. **[CloudFormation コンソール](https://console.aws.amazon.com/cloudformation)** で、このラボで作成したスタックを選択します (例: `cfn-workshop-helper-scripts`)。
1. 右上の **削除** をクリックします。
1. ポップアップウィンドウで、**削除** をクリックします。
1. **DELETE_COMPLETE** ステータスになるまで待ちます。必要に応じて、リフレッシュボタンをクリックします。
---
### まとめ

おめでとうございます！ CloudFormation ヘルパースクリプトを使用して EC2 インスタンスを正常にブートストラップしました。
