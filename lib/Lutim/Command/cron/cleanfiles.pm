package Lutim::Command::cron::cleanfiles;
use Mojo::Base 'Mojolicious::Command';
use LutimModel;
use Lutim;
use Mojo::Util qw(slurp decode);
use FindBin qw($Bin);
use File::Spec qw(catfile);

has description => 'Delete expired files.';
has usage => sub { shift->extract_usage };

sub run {
    my $c = shift;
    my $l = Lutim->new;

    my $time = time();
    my @images = LutimModel::Lutim->select('WHERE enabled = 1 AND (delete_at_day * 86400) < (? - created_at) AND delete_at_day != 0', $time);

    for my $image (@images) {
        $l->app->delete_image($image);
    }

    my $config = $c->app->plugin('Config', {
        file => File::Spec->catfile($Bin, '..' ,'lutim.conf'),
    });

    if (defined($config->{delete_no_longer_viewed_files}) && $config->{delete_no_longer_viewed_files} > 0) {
        $time = time() - $config->{delete_no_longer_viewed_files} * 86400;
        @images = LutimModel::Lutim->select('WHERE enabled = 1 AND last_access_at < ?', $time);

        for my $image (@images) {
            $l->app->delete_image($image);
        }
    }
}

=encoding utf8

=head1 NAME

Lutim::Command::cron::cleanfiles - Delete expired files

=head1 SYNOPSIS

  Usage: script/lutim cron cleanfiles

=cut

1;
