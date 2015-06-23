---
layout: docs
category: running_coreos
sub_category: cloud_provider
weight: 6
title: NIFTY Cloud
---

# ニフティクラウド上でのCoreOSの起動

事前に[ニフティクラウド CLI][cli-documentation]をインストールする必要があります。These instructions are also [available in English](../).

[cli-documentation]: http://cloud.nifty.com/api/cli/

## Cloud-Config

CoreOSはcloud-configにより、マシンのパラメータを設定したり、起動時にsystemdのunitを立ち上げたりすることが可能です。サポートしている機能は[こちら]({{site.baseurl}}/docs/cluster-management/setup/cloudinit-cloud-config)で確認してください。cloud-configは最小限で有用な状態にクラスターを立ち上げることを目的としており、複数のホストで共通ではない設定をするためには使うべきではありません。ニフティクラウド上では、cloud-configはサーバーの起動中に編集でき、次回起動時に反映されます。

[ニフティクラウドCLI][cli-documentation]を使ってcloud-configを設定することができます。

最も一般的なcloud-configは下記のようなものです。

```yaml
#cloud-config

coreos:
  etcd2:
    # generate a new token for each unique cluster from https://discovery.etcd.io/new?size=3
    # specify the initial size of your cluster with ?size=X
    discovery: https://discovery.etcd.io/<token>
    # multi-region and multi-cloud deployments need to use $public_ipv4
    advertise-client-urls: http://$private_ipv4:2379,http://$private_ipv4:4001
    initial-advertise-peer-urls: http://$private_ipv4:2380
    # listen on both the official ports and the legacy ports
    # legacy ports can be omitted if your application doesn't depend on them
    listen-client-urls: http://0.0.0.0:2379,http://0.0.0.0:4001
    listen-peer-urls: http://$private_ipv4:2380
  units:
    - name: etcd.service
      command: start
    - name: fleet.service
      command: start
```

`$private_ipv4`と`$public_ipv4`という変数はニフティクラウド上のcloud-configでサポートされています。

## チャンネルの選択

CoreOSはチャンネル毎に別のスケジュールで[自動アップデート]({{site.baseurl}}/using-coreos/updates)されるように設計されています。推奨はしませんが、この機能は[無効にする]({{site.baseurl}}/docs/cluster-management/debugging/prevent-reboot-after-update)こともできます。各機能やバグフィックスについては[リリースノート]({{site.baseurl}}/releases)を読んでください。

<div id="niftycloud-images">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable" data-toggle="tab">Stableチャンネル</a></li>
    <li><a href="#beta" data-toggle="tab">Betaチャンネル</a></li>
    <li><a href="#alpha" data-toggle="tab">Alphaチャンネル</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha">
      <p>AlphaチャンネルはMasterをぴったりと追っていて、頻繁にリリースされます。テストのために最新の<a href="{{site.baseurl}}/using-coreos/docker">docker</a>、<a href="{{site.baseurl}}/using-coreos/etcd">etcd</a>、<a href="{{site.baseurl}}/using-coreos/clustering">fleet</a>の利用が可能です。現在のバージョンはCoreOS {{site.alpha-channel}}です。</p>
      <p><code>$ZONE</code>, <code>$TYPE</code>, <code>$FW_ID</code> and <code>$SSH_KEY_ID</code>を指定し、ニフティクラウドCLIで立ち上げます。</p>
      <pre>nifty-run-instances $(nifty-describe-images --delimiter ',' --image-name "CoreOS Alpha {{site.alpha-channel}}" | awk -F',' '{print $2}') --key $SSH_KEY_ID --availability-zone $ZONE --instance-type $TYPE -g $FW_ID -f cloud-config.yml -q POST</pre>
    </div>
    <div class="tab-pane" id="beta">
      <p>BetaチャンネルはAlphaリリースが昇格されたものです。現在のバージョンはCoreOS {{site.beta-channel}}です。</p>
      <p><code>$ZONE</code>, <code>$TYPE</code>, <code>$FW_ID</code> and <code>$SSH_KEY_ID</code>を指定し、ニフティクラウドCLIで立ち上げます。</p>
      <pre>nifty-run-instances $(nifty-describe-images --delimiter ',' --image-name "CoreOS Beta {{site.beta-channel}}" | awk -F',' '{print $2}') --key $SSH_KEY_ID --availability-zone $ZONE --instance-type $TYPE -g $FW_ID -f cloud-config.yml -q POST</pre>
    </div>
    <div class="tab-pane active" id="stable">
      <p>プロダクションクラスターではStableチャンネルを使用すべきです。CoreOSの各バージョンは昇格されるまでにBetaとAlphaチャンネルで検証済みです。現在のバージョンはCoreOS {{site.stable-channel}}です。</p>
      <p><code>$ZONE</code>, <code>$TYPE</code>, <code>$FW_ID</code> and <code>$SSH_KEY_ID</code>を指定し、ニフティクラウドCLIで立ち上げます。</p>
      <pre>nifty-run-instances $(nifty-describe-images --delimiter ',' --image-name "CoreOS Stable {{site.stable-channel}}" | awk -F',' '{print $2}') --key $SSH_KEY_ID --availability-zone $ZONE --instance-type $TYPE -g $FW_ID -f cloud-config.yml -q POST</pre>
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
[CoreOSクイックスタート]({{site.baseurl}}/docs/quickstart)を見るか、[各トピックス]({{site.baseurl}}/docs)を掘り下げましょう。
