# Perl6 Dash docset generator
A script to parse the Perl 6 docset and index it for use in Dash.app

## Generating the docset
Install the following dependencies:
```bash
brew install rakudo-star # Install Perl 6
panda install URI::Encode
panda install HTML::Entity
```

Generate the docset:
```bash
./generate.sh
```
