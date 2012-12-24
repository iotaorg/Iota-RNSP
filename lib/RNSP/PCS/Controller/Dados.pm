
=head1 API

=head2 Descrição

Os dados da RNSP estao disponveis pelas seguintes URLs:

- baixar todos os dados:

http://rnsp.aware.com.br/movimento/dados.csv
http://rnsp.aware.com.br/movimento/dados.csv.checksum

movimento e prefeitura são aceitos.

- baixar apenas da cidade de belo hozionte:

http://rnsp.aware.com.br/movimento/br/MG/belo-horizonte/dados.xml
http://rnsp.aware.com.br/movimento/br/MG/belo-horizonte/dados.xml.checksum

movimento e prefeitura são aceitos.

=cut

package RNSP::PCS::Controller::Dados;
use Moose;
BEGIN { extends 'Catalyst::Controller' }
use utf8;
use JSON::XS;

# MOVIMENTO CSV
sub mov_dados_csv : Chained('/movimento') : PathPart('dados.csv') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'csv';
}

sub mov_dados_csv_check: Chained('/movimento') : PathPart('dados.csv.checksum') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'csv.check';
}

sub down_mov_dados_csv : Chained('mov_dados_csv') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub down_mov_dados_csv_check : Chained('mov_dados_csv_check') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

# MOVIMENTO XML
sub mov_dados_xml : Chained('/movimento') : PathPart('dados.xml') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xml';
}

sub mov_dados_xml_check: Chained('/movimento') : PathPart('dados.xml.checksum') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xml.check';
}

sub down_mov_dados_xml : Chained('mov_dados_xml') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub down_mov_dados_xml_check : Chained('mov_dados_xml_check') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

# MOVIMENTO JSON
sub mov_dados_json : Chained('/movimento') : PathPart('dados.json') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'json';
}

sub mov_dados_json_check: Chained('/movimento') : PathPart('dados.json.checksum') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'json.check';
}

sub down_mov_dados_json : Chained('mov_dados_json') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub down_mov_dados_json_check : Chained('mov_dados_json_check') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}


# prefeitura CSV
sub pref_dados_csv : Chained('/prefeitura') : PathPart('dados.csv') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'csv';
}

sub pref_dados_csv_check: Chained('/prefeitura') : PathPart('dados.csv.checksum') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'csv.check';
}

sub down_pref_dados_csv : Chained('pref_dados_csv') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub down_pref_dados_csv_check : Chained('pref_dados_csv_check') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

# prefeitura XML
sub pref_dados_xml : Chained('/prefeitura') : PathPart('dados.xml') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xml';
}

sub pref_dados_xml_check: Chained('/prefeitura') : PathPart('dados.xml.checksum') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xml.check';
}

sub down_pref_dados_xml : Chained('pref_dados_xml') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub down_pref_dados_xml_check : Chained('pref_dados_xml_check') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

# prefeitura JSON
sub pref_dados_json : Chained('/prefeitura') : PathPart('dados.json') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'json';
}

sub pref_dados_json_check: Chained('/prefeitura') : PathPart('dados.json.checksum') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'json.check';
}

sub down_pref_dados_json : Chained('pref_dados_json') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub down_pref_dados_json_check : Chained('pref_dados_json_check') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}


######## dados por cidades


# MOVIMENTO CSV
sub mov_dados_cidade_csv : Chained('/movimento_cidade') : PathPart('dados.csv') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'csv';
}

sub mov_dados_cidade_csv_check: Chained('/movimento_cidade') : PathPart('dados.csv.checksum') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'csv.check';
}

sub down_mov_dados_cidade_csv : Chained('mov_dados_cidade_csv') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub down_mov_dados_cidade_csv_check : Chained('mov_dados_cidade_csv_check') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

# MOVIMENTO XML
sub mov_dados_cidade_xml : Chained('/movimento_cidade') : PathPart('dados.xml') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xml';
}

sub mov_dados_cidade_xml_check: Chained('/movimento_cidade') : PathPart('dados.xml.checksum') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xml.check';
}

sub down_mov_dados_cidade_xml : Chained('mov_dados_cidade_xml') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub down_mov_dados_cidade_xml_check : Chained('mov_dados_cidade_xml_check') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

# MOVIMENTO JSON
sub mov_dados_cidade_json : Chained('/movimento_cidade') : PathPart('dados.json') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'json';
}

sub mov_dados_cidade_json_check: Chained('/movimento_cidade') : PathPart('dados.json.checksum') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'json.check';
}

sub down_mov_dados_cidade_json : Chained('mov_dados_cidade_json') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub down_mov_dados_cidade_json_check : Chained('mov_dados_cidade_json_check') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

#################

# prefeitura CSV
sub pref_dados_cidade_csv : Chained('/prefeitura_cidade') : PathPart('dados.csv') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'csv';
}

sub pref_dados_cidade_csv_check: Chained('/prefeitura_cidade') : PathPart('dados.csv.checksum') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'csv.check';
}

sub down_pref_dados_cidade_csv : Chained('pref_dados_cidade_csv') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub down_pref_dados_cidade_csv_check : Chained('pref_dados_cidade_csv_check') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

# prefeitura XML
sub pref_dados_cidade_xml : Chained('/prefeitura_cidade') : PathPart('dados.xml') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xml';
}

sub pref_dados_cidade_xml_check: Chained('/prefeitura_cidade') : PathPart('dados.xml.checksum') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'xml.check';
}

sub down_pref_dados_cidade_xml : Chained('pref_dados_cidade_xml') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub down_pref_dados_cidade_xml_check : Chained('pref_dados_cidade_xml_check') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

# prefeitura JSON
sub pref_dados_cidade_json : Chained('/prefeitura_cidade') : PathPart('dados.json') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'json';
}

sub pref_dados_cidade_json_check: Chained('/prefeitura_cidade') : PathPart('dados.json.checksum') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash->{type} = 'json.check';
}

sub down_pref_dados_cidade_json : Chained('pref_dados_cidade_json') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}

sub down_pref_dados_cidade_json_check : Chained('pref_dados_cidade_json_check') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    $self->_download($c);
}



# download de todos os endpoints caem aqui
sub _download {
    my ( $self, $c ) = @_;

}

1;


