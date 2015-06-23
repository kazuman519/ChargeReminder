#! /usr/bin/env perl

use strict;
use warnings;
use utf8;
use MF::Notify::Slack;
use DateTime;
use DBI;
use Data::Dumper;

my $database_name = 'chargeMember';
my $table_name = 'charge';

my $charger = '';
my $work_name = $ARGV[0];


# ポストするデータを取得する関数
sub getPostData {

  my($work_name, $charger) = @_;
  print "charger -> $charger\n";

  my $br = "\r\n";
  my $conf = {
    priv_members => {
    },
    post_data => {
      default => {
        channel    => '@miura',
        icon_emoji => ':clock3:',
        username   => 'MCお知らせ',
        text       => '',
      },
      test_msg => {
        channel => '@miura',
        text    => 'すみませんテストです$charger  これでおわり<!group>',
      },
      mf_mtg_morning => {
        channel => '@miura',
        text    => '本日の朝会の発表者は'.$charger.'さんです！'.$br.'よろしくお願いします！<!group>',
      },
      mc_mtg_frontend => {
        channel => '@miura',
        text    => '本日のMCフロントエンドMTGの司会&Wiki準備する人は'.$charger.'さんです！'.$br.'http://wiki.mf.local/tag/MC-FRONTEND-MTG'.$br.'よろしくお願いします！<!group>',
      },
      mc_mtg_develop => {
        channel => '@miura',
        text    => '本日のMC開発MTGの司会&Wiki準備する人は'.$charger.'さんです！'.$br.'http://wiki.mf.local/tag/MC-ENGINEER-MTG'.$br.'よろしくお願いします！<!group>',
      },
    },
  };

  # 引数に対応するデータがなければ何もせずに死ぬ
  die if !$work_name or !$conf->{post_data}->{$work_name};

  # デフォルトデータを引数で指定されたデータで上書き
  my %return_data = (%{$conf->{post_data}->{default}}, %{$conf->{post_data}->{$work_name}});

  return %return_data;
}


# DB接続
my $dbh;
$dbh = DBI->connect(
  "DBI:mysql:database=$database_name;host=localhost;port=3306;",
  "root",
  ""
);

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
  my $member_string = $ref->{'member'};
  $next_charger_number = $ref->{'next_charger_number'};

  if(index($member_string,",") != -1){
    @member = split(/,/,$member_string);
    if ($next_charger_number <= @member) {
      $charger = $member[$next_charger_number-1];
    }
  }
}
$sth->finish();

## 発言者番号のインクリメント
$next_charger_number++;
if ($next_charger_number > @member ) {
  $next_charger_number = 1;
}

## 発言者番号をDBに保存
$sth = $dbh->prepare("update charge set next_charger_number = $next_charger_number where work_name = ?");
$sth->execute($work_name);
$sth->finish();

# DB切断
$dbh->disconnect();

# slackに通知
MF::Notify::Slack->new->post(&getPostData($work_name, $charger));

exit;
