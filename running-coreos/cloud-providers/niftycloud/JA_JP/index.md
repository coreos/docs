---
layout: docs
category: running_coreos
sub_category: cloud_provider
supported: true
weight: 6
title: NIFTY Cloud
---

# ニフティクラウド上でのCoreOSの起動

事前に[ニフティクラウド CLI][cli-documentation]をインストールする必要があります。

[cli-documentation]: http://cloud.nifty.com/api/cli/

## Cloud-Config

CoreOSはcloud-configにより、マシンのパラメータを設定したり、起動時にsystemdのunitを立ち上げたりすることが可能です。サポートしている機能は[こちら]({{site.url}}/docs/cluster-management/setup/cloudinit-cloud-config)で確認してください。cloud-configは最小限で有用な状態にクラスターを立ち上げることを目的としており、複数のホストで共通ではない設定をするためには使うべきではありません。ニフティクラウド上では、cloud-configはサーバーの起動中に編集でき、次回起動時に反映されます。

[ニフティクラウドCLI][cli-documentation]を使ってcloud-configを設定することができます。

最も一般的なcloud-configは下記のようなものです。

```yaml
#cloud-config

coreos:
  etcd:
    # generate a new token for each unique cluster from https://discovery.etcd.io/new
    discovery: https://discovery.etcd.io/<token>
    # multi-region and multi-cloud deployments need to use $public_ipv4
    addr: $private_ipv4:4001
    peer-addr: $private_ipv4:7001
  units:
    - name: etcd.service
      command: start
    - name: fleet.service
      command: start
```

`$private_ipv4`と`$public_ipv4`という変数はニフティクラウド上のcloud-configでサポートされています。

## チャンネルの選択

CoreOSはチャンネル毎に別のスケジュールで[自動アップデート]({{site.url}}/using-coreos/updates)されるように設計されています。推奨はしませんが、この機能は[無効にする]({{site.url}}/docs/cluster-management/debugging/prevent-reboot-after-update)こともできます。各機能やバグフィックスについては[リリースノート]({{site.url}}/releases)を読んでください。

<div id="niftycloud-images">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable" data-toggle="tab">Stableチャンネル</a></li>
    <li><a href="#beta" data-toggle="tab">Betaチャンネル</a></li>
    <li><a href="#alpha" data-toggle="tab">Alphaチャンネル</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha">
      <p>AlphaチャンネルはMasterをぴったりと追っていて、頻繁にリリースされます。テストのために最新の<a href="{{site.url}}/using-coreos/docker">docker</a>、<a href="{{site.url}}/using-coreos/etcd">etcd</a>、<a href="{{site.url}}/using-coreos/clustering">fleet</a>の利用が可能です。現在のバージョンはCoreOS {{site.alpha-channel}}です。</p>
      <p><code>$ZONE</code>, <code>$TYPE</code>, <code>$FW_ID</code> and <code>$SSH_KEY_ID</code>を指定し、ニフティクラウドCLIで立ち上げます。</p>
      <pre>nifty-run-instances $(nifty-describe-images --delimiter ',' --image-name "CoreOS Alpha {{site.alpha-channel}}" | awk -F',' '{print $2}') --key $SSH_KEY_ID --availability-zone $ZONE --instance-type $TYPE -g $FW_ID -f cloud-config.yml</pre>
    </div>
    <div class="tab-pane" id="beta">
      <p>BetaチャンネルはAlphaリリースが昇格されたものです。現在のバージョンはCoreOS {{site.beta-channel}}です。</p>
      <p><code>$ZONE</code>, <code>$TYPE</code>, <code>$FW_ID</code> and <code>$SSH_KEY_ID</code>を指定し、ニフティクラウドCLIで立ち上げます。</p>
      <pre>nifty-run-instances $(nifty-describe-images --delimiter ',' --image-name "CoreOS Alpha {{site.beta-channel}}" | awk -F',' '{print $2}') --key $SSH_KEY_ID --availability-zone $ZONE --instance-type $TYPE -g $FW_ID -f cloud-config.yml</pre>
    </div>
    <div class="tab-pane active" id="stable">
      <p>プロダクションクラスターではStableチャンネルを使用すべきです。CoreOSの各バージョンは昇格されるまでにBetaとAlphaチャンネルで検証済みです。現在のバージョンはCoreOS {{site.stable-channel}}です。</p>
      <p><code>$ZONE</code>, <code>$TYPE</code>, <code>$FW_ID</code> and <code>$SSH_KEY_ID</code>を指定し、ニフティクラウドCLIで立ち上げます。</p>
      <pre>nifty-run-instances $(nifty-describe-images --delimiter ',' --image-name "CoreOS Alpha {{site.stable-channel}}" | awk -F',' '{print $2}') --key $SSH_KEY_ID --availability-zone $ZONE --instance-type $TYPE -g $FW_ID -f cloud-config.yml</pre>
    </div>
  </div>
</div>

### サーバーの追加

さらにクラスタにサーバーを追加するには、同じcloud-config、適当なファイアウォールグループで立ち上げるだけです。

## SSH

下記のコマンドでログインできます。

```sh
ssh core@<ip address> -i <path to keyfile>
```

## CoreOSの利用

起動済みのマシンを手に入れたら、遊ぶ時間です。
[CoreOSクイックスタート]({{site.url}}/docs/quickstart)を見るか、[各トピックス]({{site.url}}/docs)を掘り下げましょう。
