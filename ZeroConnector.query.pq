// Use this file to write queries to test your data connector
let
    source = ZeroConnector.Contents(),
    org = source{0}[tenantId],
    Contacts = ZeroConnector.Contents("https://api.xero.com/api.xro/2.0/Contacts", org),
    Conts = List.Count(Contacts[Contacts])
in Conts
