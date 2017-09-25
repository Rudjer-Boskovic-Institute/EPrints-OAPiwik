# OpenAIRE Piwik tracker for EPrints.

* Record usage data for OpenAIRE usage statistics.
* Contact dpierrakos@gmail.com to request OpenAIRE Piwik Site ID and the Authentication Token.
* Copyleft 2017. Rudjer Boskovic Institute <http://www.irb.hr> and OpenAIRE <http://openaire.eu> Released to the public domain (or CC0 depending on your juristiction).
* USE OF THIS EXTENSION IS ENTIRELY AT YOUR OWN RISK.

##  Installation
1. Copy file from "lib/defaultfcg/cfg.d/" into your repository's cfg.d/ directory
2. Copy file from "lib/plugins/EPrints/Plugin/Event/" into your repository's local Plugin/Event directory
3. Edit config file and configure your OpenAIRE Piwik Site ID and the Authentication Token
4. Edit config file for IP Anonymization. Specify the number of bytes in the IP Address that would be set to 0. Values in {1,2,3}. Leave empty for no Anonymization.
5. Restart Apache.
6. Tip: for development purposes it's possible to symlink the two files (1. and 2.) from appropriate directories

##  Implementation
* Record to the configured Piwik server whenever an item is viewed or full-text object is requested from EPrints..
* The data transferred are:
  - eprint.eprintid: the eprint's internal identifier
  - eprint.datestamp: the datetime the access started
  - IP address: the user's IP address
  - User Agent: the user's browser user agent
  - OAI-PMH Identifier

##  Changes
* v1.0 Dimitris Pierrakos <dpierrakos@gmail.com>, Karlo Hrenovic <karlo.hrenovic@irb.hr>, Alen Vodopijevec <alen@irb.hr>
* Initial version based on "PIRUS/IRUS-UK PUSH Implementation" <http://files.eprints.org/971/>
