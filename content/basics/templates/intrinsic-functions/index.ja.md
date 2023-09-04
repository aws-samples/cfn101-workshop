---
title: "組み込み関数"
weight: 400
---

### 概要

このラボではテンプレートで **[組み込み関数](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html)** の使い方を紹介します。

組み込み関数はスタックの管理を行いやすくする内蔵の関数です。組み込み関数が無いと、 **[テンプレートとスタック](../template-and-stack/)** で見た S3 テンプレートのような、とても基礎的なテンプレートのみに限定されてしまいます。

### カバーするトピック

このラボでは、以下の作業を行います。

+ **[Ref](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-ref.html)** 関数を使って、パラメータをリソースのプロパティに動的に設定
+ **[Fn::Join](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-join.html)** 関数を使ったインスタンスのタグ付け
+ **[Fn::Sub](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-sub.html)** 関数を使って、インスタンスにタグを追加

### ラボの開始

1. `code/workspace/` ディレクトリへ移動します。
1. `intrinsic-functions.yaml` ファイルを開きます。
1. 以下のトピックを進めながら、コードをコピーしていきます。

:::alert{type="info"}
組み込み関数はテンプレートの一部で使うことができます。組み込み関数が使えるのは、**リソースプロパティ、出力、メタデータ属性、および更新ポリシー属性** です。
:::

#### Ref

前のラボでは、AMI ID を EC2 のリソースプロパティに「ハードコード」しています。もっと柔軟性が高いようにテンプレートを改善します。`AmiID` を変数とし、実行時にリソースプロパティにわたすようにします。

1. まず、`AmiID` という新しいパラメータを作成し、テンプレート内の `Parameters` セクションに追加します。

    ```yaml
    AmiID:
      Type: AWS::EC2::Image::Id
      Description: 'The ID of the AMI.'
    ```

1. `Ref` 組み込み関数を使い、`AmiID` パラメータの入力値を EC2 リソースのプロパティに渡します。

    ```yaml
    Resources:
      WebServerInstance:
        Type: AWS::EC2::Instance
        Properties:
          # Use !Ref function in ImageId property
          ImageId: !Ref AmiID
          InstanceType: !Ref InstanceType
    ```

#### Fn::Join

AWS リソースの管理を容易にするため、任意にメタデータを **タグ** の形式で各リソースに付与することができます。タグとは、お客様が指定できる独自のキーと任意の値によって、目的、所有者、環境や他の目的にリソースを分類できるような単純なラベルです。ここではインスタンスに名前をつけるために、**Fn::Join** 組み込み関数を使いましょう。

1. `Tags` プロパティを `Properties` セクションに追加します。
1. Reference `InstanceType` パラメータを参照し、単語 _webserver_ をハイフン `-` で繋いだ文字列を `Tags` プロパティに追加します。

    ```yaml
    Resources:
      WebServerInstance:
        Type: AWS::EC2::Instance
        Properties:
          ImageId: !Ref AmiID
          InstanceType: !Ref InstanceType
          Tags:
            - Key: Name
              Value: !Join [ '-', [ !Ref InstanceType, webserver ] ]
    ```

#### EC2 スタックの更新

それでは、スタックを更新しましょう。AWS コンソールを開き、CloudFormation スタックを更新してください。

1. **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** のリンクを新しいタブで開き、必要に応じて AWS アカウントにログインします。
1. スタック名 (例：**cfn-workshop-ec2**) をクリックします。
1. 画面右上の **更新** ボタンをクリックします。
1. **テンプレートの準備** で、**既存テンプレートを置き換える** を選択します。
1. **テンプレートの指定** で、 **テンプレートファイルのアップロード** を選びます。
1. **ファイルの選択** ボタンをクリックし、作業用ディレクトリに移動します。
1. ステップ 1 で作成した `intrinsic-functions.yaml` を指定し、**次へ** をクリックします。
1. **Type of EC2 Instance** はデフォルトの値をそのまま使います。
1. **AmiID** では、`resources.yaml` ファイルにハードコードした AMI ID からコピーして貼り付けて、**次へ** をクリックします。
1. **スタックオプションの設定** はデフォルトの設定のままとし、**次へ** をクリックします。
1. **レビュー <スタック名>** のページで、ページの下部までスクロールし、**送信** をクリックします。
1. ステータスが **UPDATE_COMPLETE** になるまで、**リフレッシュ** ボタンを数回クリックします。

**スタックの更新結果の確認方法**

1. **[AWS EC2 console](https://console.aws.amazon.com/ec2)** のリンクをブラウザの新しいタブで開きます。
1. 左側のメニューで、**インスタンス** をクリックします。
1. **t2.micro-webserver** のインスタンス名を選択します。
1. **タグ** タブを開き `Name` キーと `t2.micro-webserver` の値が表示されるはずです。
   ![tags-png](/static/basics/templates/intrinsic-functions/tags.ja.png)

### チャレンジ
**Fn::Sub** 組み込み関数を使って、インスタンスタイプを `InstanceType` という名前のついたタグを追加してください。

短縮形は `!Sub` です。

::expand[**[Fn::Sub](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-sub.html)** 関数の AWS ドキュメントをご確認ください]{header="ヒントが必要ですか？"}

:::expand{header="解決策を確認しますか？"}
1. テンプレートに `InstanceType` タグを追加します。

    ```yaml
    Resources:
      WebServerInstance:
        Type: AWS::EC2::Instance
        Properties:
          ImageId: !Ref AmiID
          InstanceType: !Ref InstanceType
          Tags:
            - Key: Name
              Value: !Join [ '-', [ !Ref InstanceType, webserver ] ]
            - Key: InstanceType
              Value: !Sub ${InstanceType}
    ```

1. AWS コンソールを開き、CloudFormation スタックを更新します。
1. EC2 コンソールで、`InstanceType` タグが作られていることを確認します。
:::

---
### まとめ
おめでとうございます！これで無事にテンプレートで組み込み関数を使うことができました。
