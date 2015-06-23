#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use MF::Notify::Slack;
use DateTime;

my $dt     = DateTime->now(locale => 'ja', time_zone => 'local');
my $dt_str = $dt->strftime('%Y年 %m月%d日 (%a) %H時%M分');
my $dt_ymd = $dt->strftime('%Y年 %m月%d日 (%a)');
my $dt_hm  = $dt->strftime('%H時%M分');

my $member_file = "sample.json";

my $default_member = [
#    '@c-shiratake',
#    '@ichikawa',
#    '@isao',
#    '@kitamura',
#    '@morinaga',
#    '@shiokawa',
];

my $conf = {
    priv_members => {
#        asa_mtg  => $default_member,
#        yoru_mtg => $default_member,
    },
    post_data => {
        default => {
            channel    => '@miura',
            icon_emoji => ':clock3:',
            username   => 'MCお知らせ',
            text       => '',
        },

        asa_teiji  => {
            channel => '@miura',
            text    => "$dt_str 始業時刻です。今日も一日がんばろー",
        },

        asa_teiji_mon  => {
            channel => '@miura',
            text    => "$dt_str 始業時刻です。全体朝会がありますよ",
        },

        asa_teiji_fri => {
            channel => '@miura',
            text    => "$dt_str 始業時刻です。整理整頓運動にご協力下さい",
        },

        yoru_teiji => {
            channel => '@miura',
            text    => "$dt_hm 終業時刻です。今日も一日おつかれさまでしたー",
        },

        yoru_teiji_fri => {
            channel => '@miura',
            text    => "$dt_hm 終業時刻です。今週も一週間おつかれさまでしたー",
        },

        no_zan     => {
            channel => '@miura',
            text    => '今日はノー残業デーですよ。残業する人は申告して下さい！',
        },

        asa_mtg    => {
            channel => '@miura',
            text    => "$dt_hm です。朝会の予感！ <!group>",
        },

        yoru_mtg   => {
            channel => '@miura',
            text    => "$dt_hm です。夕会の予感！ <!group>",
        },

        asa_dakoku => {
            channel => '@miura',
            text    => "打刻忘れないようにね！<!group>",
        },

        test_msg => {
            channel => '@miura',
            text    => 'すみませんテストです 5 これでおわり<!group>',
        },
    },
};

# 引数に対応するデータがなければ何もせずに死ぬ
my $type = $ARGV[0];
die if !$type or !$conf->{post_data}->{$type};

# デフォルトデータを引数で指定されたデータで上書き
my %post_data = (%{$conf->{post_data}->{default}}, %{$conf->{post_data}->{$type}});

#warn Dumper \%post_data;
MF::Notify::Slack->new->post(%post_data);  # チャンネルへのpost
my $testValue = $conf->{post_data}->{test_msg}->{text};
print "$testValue\n";

=pod
# priv members
my @members =  @{$conf->{priv_members}->{$type}};
if (scalar @members) {
    map {MF::Notify::Slack->new->post(%post_data, channel => $_)} @members;
}
=cut

exit;
