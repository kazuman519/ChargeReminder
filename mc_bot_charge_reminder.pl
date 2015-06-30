#! /usr/bin/env perl

use strict;
use warnings;
use utf8;
use Encode;
use MF::Notify::Slack;
use DateTime;
use DBI;
use Data::Dumper;

my $database_name = 'chargeMember';
my $table_name = 'charge';

my $work_name = $ARGV[0];
my $charger   = '';
my $channel   = '';
my $text      = '';


# ポストするデータを取得する関数
sub createPostData {

  my($charger ,$channel, $text) = @_;
  print "charger -> $charger\n";

  # エンコード&文字置き換え
  $text = Encode::decode('utf-8', $text);
  $text =~s/_NAME_/$charger/g;
  $text =~s/_BR_/\n/g;

  my $conf = {
    post_data => {
      default => {
        channel    => '@miura',
        icon_emoji => ':clock3:',
        username   => 'MCお知らせ',
        text       => '',
      },
      custom => {
        channel    => $channel,
        text       => "$text",
      },
    },
  };

  # デフォルトデータを引数で指定されたデータで上書き
  my %return_data = (%{$conf->{post_data}->{default}}, %{$conf->{post_data}->{custom}});

  return %return_data;
}


# DB接続 XXX:この辺りの情報は外だししといたほうがよさげ
my $dbh;
$dbh = DBI->connect(
  "DBI:mysql:database=$database_name;host=localhost;port=3306;",
  "root",
  ""
);
$dbh->do("set names utf8");

## プリペアードステートメント
my $sth;
my $ref;

## 発表者の取得
my $next_charger_number = 1;
my @member = '';

$sth = $dbh->prepare("select * from $table_name where work_name = ?");
$sth->execute($work_name);
while($ref = $sth->fetchrow_hashref()){
  # メンバーと次発表する人の番号を取得
  my $member_string    = $ref->{'member'};
  $next_charger_number = $ref->{'next_charger_number'};
  $channel             = $ref->{'channel'};
  $text                = $ref->{'text'};

  if(index($member_string,",") != -1){
    @member = split(/,/,$member_string);
    if ($next_charger_number <= @member) {
      $charger = $member[$next_charger_number-1];
    }
  } else {
    $charger = $member_string;
  }
}
$sth->finish();

# 引数に対応するworkがないか、引数がなければ何もせずに死ぬ
die if !$work_name or $charger eq '';

## 発言者番号のインクリメント
$next_charger_number++;
if ($next_charger_number > @member ) {
  # メンバー数以上の番号になっていたら最初に戻す
  $next_charger_number = 1;
}

## 発言者番号をDBに保存
$sth = $dbh->prepare("update charge set next_charger_number = $next_charger_number where work_name = ?");
$sth->execute($work_name);
$sth->finish();

# DB切断
$dbh->disconnect();

# slackに通知
my %postData = &createPostData($charger, $channel, $text);
MF::Notify::Slack->new->post(%postData);

exit;
