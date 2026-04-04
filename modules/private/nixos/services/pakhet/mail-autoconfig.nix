{ lib, modules, ... }:

let
  network = modules.private.inventory.network { inherit lib; };

  autoconfigXml = builtins.replaceStrings [ "'" ] [ "\\'" ] ''<?xml version="1.0" encoding="UTF-8"?>
<clientConfig version="1.1">
  <emailProvider id="unixpimps.net">
    <domain>%EMAILDOMAIN%</domain>
    <displayName>UNIXPIMPS Mail</displayName>
    <incomingServer type="imap">
      <hostname>imap.unixpimps.net</hostname>
      <port>993</port>
      <socketType>SSL</socketType>
      <authentication>password-cleartext</authentication>
      <username>%EMAILADDRESS%</username>
    </incomingServer>
    <incomingServer type="pop3">
      <hostname>pop3.unixpimps.net</hostname>
      <port>995</port>
      <socketType>SSL</socketType>
      <authentication>password-cleartext</authentication>
      <username>%EMAILADDRESS%</username>
    </incomingServer>
    <outgoingServer type="smtp">
      <hostname>smtp.unixpimps.net</hostname>
      <port>465</port>
      <socketType>SSL</socketType>
      <authentication>password-cleartext</authentication>
      <username>%EMAILADDRESS%</username>
    </outgoingServer>
  </emailProvider>
</clientConfig>'';

  autodiscoverXml = builtins.replaceStrings [ "'" ] [ "\\'" ] ''<?xml version="1.0" encoding="utf-8"?>
<Autodiscover xmlns="http://schemas.microsoft.com/exchange/autodiscover/responseschema/2006">
  <Response xmlns="http://schemas.microsoft.com/exchange/autodiscover/outlook/responseschema/2006a">
    <Account>
      <AccountType>email</AccountType>
      <Action>settings</Action>
      <Protocol>
        <Type>IMAP</Type>
        <Server>imap.unixpimps.net</Server>
        <Port>993</Port>
        <SSL>on</SSL>
        <SPA>off</SPA>
        <AuthRequired>on</AuthRequired>
      </Protocol>
      <Protocol>
        <Type>POP3</Type>
        <Server>pop3.unixpimps.net</Server>
        <Port>995</Port>
        <SSL>on</SSL>
        <SPA>off</SPA>
        <AuthRequired>on</AuthRequired>
      </Protocol>
      <Protocol>
        <Type>SMTP</Type>
        <Server>smtp.unixpimps.net</Server>
        <Port>465</Port>
        <SSL>on</SSL>
        <SPA>off</SPA>
        <AuthRequired>on</AuthRequired>
      </Protocol>
    </Account>
  </Response>
</Autodiscover>'';

  mkAutoconfig = domain: {
    "autoconfig.${domain}" = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;
      locations."/mail/config-v1.1.xml".extraConfig = ''
        default_type application/xml;
        return 200 '${autoconfigXml}';
      '';
    };
    "autodiscover.${domain}" = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;
      locations."/autodiscover/autodiscover.xml".extraConfig = ''
        default_type application/xml;
        return 200 '${autodiscoverXml}';
      '';
      locations."/Autodiscover/Autodiscover.xml".extraConfig = ''
        default_type application/xml;
        return 200 '${autodiscoverXml}';
      '';
    };
  };

  allVhosts = lib.foldl' (acc: domain: acc // mkAutoconfig domain) { } network.mailDomains;
in
{
  services.nginx.virtualHosts = allVhosts;
}
